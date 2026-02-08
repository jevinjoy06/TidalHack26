import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/message.dart';
import '../models/connection_status.dart';
import '../models/chat_history.dart';
import '../services/featherless_service.dart';
import '../services/agent_orchestrator.dart';
import '../services/adk_service.dart';
import '../services/local_bridge_server.dart';
import '../services/tools/tool_registry.dart';

class ChatProvider extends ChangeNotifier {
  FeatherlessService _service = FeatherlessService();
  String? _currentApiKey;
  String? _currentModel;
  String? _currentBaseUrl;
  bool _useAdkBackend = true;
  String _adkBackendUrl = 'http://localhost:8000';
  final List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  String? _connectionError;
  String? _currentChatId;
  /// Raw conversation for the agent orchestrator (multi-turn).
  List<Map<String, dynamic>> _agentMessages = [];
  /// Status text: "Thinking...", "Running: shopping_search", etc.
  String? _agentStatus;

  final LocalBridgeServer _bridgeServer = LocalBridgeServer(port: 8765);
  String? _adkSessionId;
  
  /// Token to track current message send. Incremented when clearMessages is called.
  int _sendToken = 0;
  
  /// Reference to chat history provider for auto-saving
  dynamic _chatHistoryProvider;

  void setAdkSettings(bool useAdk, String url) {
    _useAdkBackend = useAdk;
    _adkBackendUrl = url;
  }

  List<Message> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get agentStatus => _agentStatus;
  bool get isConnected => _connectionStatus == ConnectionStatus.connected;
  ConnectionStatus get connectionStatus => _connectionStatus;
  String? get connectionError => _connectionError;
  String? get currentChatId => _currentChatId;

  ChatProvider() {
    _checkConnection();
  }
  
  void setChatHistoryProvider(dynamic chatHistoryProvider) {
    _chatHistoryProvider = chatHistoryProvider;
  }
  
  void updateApiKey(String apiKey) {
    _currentApiKey = apiKey;
    _service = FeatherlessService(
      apiKey: apiKey,
      baseUrl: _currentBaseUrl,
      model: _currentModel,
    );
    _checkConnection();
  }

  void updateModel(String model) {
    _currentModel = model;
    _service = FeatherlessService(
      apiKey: _currentApiKey,
      baseUrl: _currentBaseUrl,
      model: model,
    );
    _checkConnection();
  }

  void updateBaseUrl(String baseUrl) {
    _currentBaseUrl = baseUrl;
    _service = FeatherlessService(
      apiKey: _currentApiKey,
      baseUrl: baseUrl,
      model: _currentModel,
    );
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    // Check if API key is configured
    if (_currentApiKey == null || _currentApiKey!.isEmpty) {
      _connectionStatus = ConnectionStatus.disconnected;
      _connectionError = 'No API key configured';
      notifyListeners();
      return;
    }

    _connectionStatus = ConnectionStatus.connecting;
    _connectionError = null;
    notifyListeners();

    try {
      final result = await _service.verifyConnection();
      _connectionStatus = result['status'] as ConnectionStatus;
      _connectionError = result['error'] as String?;
    } catch (e) {
      _connectionStatus = ConnectionStatus.networkError;
      _connectionError = 'Failed to verify connection: $e';
    }
    
    notifyListeners();
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Capture current token at start of send
    final currentToken = _sendToken;

    // Generate chat ID if this is a new chat
    if (_currentChatId == null) {
      _currentChatId = _generateChatId();
    }

    final today = DateTime.now().toIso8601String().split('T')[0];
    final contentWithDate = '[Current date: $today.] $content';

    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
    _messages.add(userMessage);
    _agentMessages.add({'role': 'user', 'content': contentWithDate});
    _isLoading = true;
    _error = null;
    _agentStatus = null;
    notifyListeners();
    
    // Set loading state and save chat with user message
    if (_chatHistoryProvider != null && _currentChatId != null) {
      _chatHistoryProvider.setLoadingState(_currentChatId!, true);
      await _chatHistoryProvider.saveChat(_currentChatId!, _messages, isLoading: true);
    }

    try {
      if (_useAdkBackend && _adkBackendUrl.isNotEmpty) {
        try {
          await _sendMessageViaAdk(contentWithDate, currentToken);
        } on Exception catch (e) {
          // Check if cancelled during exception handling
          if (currentToken != _sendToken) return;
          
          // If ADK backend is unreachable, fall back to orchestrator
          if (e.toString().contains('SocketException') ||
              e.toString().contains('Connection refused') ||
              e.toString().contains('refused the network connection')) {
            _agentStatus = 'ADK unavailable, using local agent...';
            notifyListeners();
            await _sendMessageViaOrchestrator(currentToken);
          } else {
            rethrow;
          }
        }
      } else {
        await _sendMessageViaOrchestrator(currentToken);
      }
      
      // Check if this send was cancelled while processing
      if (currentToken != _sendToken) return;
      
      _connectionStatus = ConnectionStatus.connected;
      _connectionError = null;
    } catch (e) {
      // Check if cancelled during error
      if (currentToken != _sendToken) return;
      
      _error = e.toString();
      _agentStatus = null;
      _connectionStatus = ConnectionStatus.networkError;
      _connectionError = e.toString();

      _messages.add(Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Sorry, I encountered an error: ${e.toString()}',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        status: MessageStatus.error,
        error: e.toString(),
      ));
    } finally {
      // Only clear loading if this is still the current send
      if (currentToken == _sendToken) {
        _isLoading = false;
        _agentStatus = null;
        notifyListeners();
        
        // Clear loading state and save final chat
        if (_chatHistoryProvider != null && _currentChatId != null) {
          _chatHistoryProvider.setLoadingState(_currentChatId!, false);
          await _chatHistoryProvider.saveChat(_currentChatId!, _messages, isLoading: false);
        }
      }
    }
  }
  
  String _generateChatId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return '${timestamp}_$random';
  }

  Future<void> _sendMessageViaAdk(String content, int token) async {
    if (!_bridgeServer.isRunning) {
      await _bridgeServer.start();
    }

    const userId = 'default_user';
    final isNewSession = _adkSessionId == null;
    _adkSessionId ??= DateTime.now().millisecondsSinceEpoch.toString();

    final adk = AdkService(baseUrl: _adkBackendUrl);

    if (isNewSession) {
      try {
        await adk.createSession(userId: userId, sessionId: _adkSessionId!);
      } catch (_) {
        // Check if cancelled during session creation
        if (token != _sendToken) return;
        _adkSessionId = DateTime.now().millisecondsSinceEpoch.toString();
        await adk.createSession(userId: userId, sessionId: _adkSessionId!);
      }
    }

    // Check if cancelled before starting main work
    if (token != _sendToken) return;

    _agentStatus = 'Thinking...';
    notifyListeners();

    final events = await adk.run(
      userId: userId,
      sessionId: _adkSessionId!,
      message: content,
    );


    // Check if cancelled after ADK call
    if (token != _sendToken) return;
    // #region agent log
    final toolsCalled = AdkService.getToolsCalledFromEvents(events).toList();
    final rawTextBeforeFallback = AdkService.getFinalTextFromEvents(events);
    try {
      final payload = {
        'location': 'chat_provider.dart:_sendMessageViaAdk',
        'message': 'ADK run result',
        'data': {
          'eventCount': events.length,
          'messageLength': content.length,
          'toolsCalled': toolsCalled,
          'rawTextIsNull': rawTextBeforeFallback == null,
          'rawTextPreview': rawTextBeforeFallback != null ? (rawTextBeforeFallback.length > 80 ? rawTextBeforeFallback.substring(0, 80) : rawTextBeforeFallback) : null,
          'usedFallback': rawTextBeforeFallback == null,
          'eventSummary': events.map((e) {
        final content = e['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        return {'author': e['author'], 'partsCount': parts?.length ?? 0};
      }).toList(),
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'hypothesisId': 'H1_H2_H4',
      };
      File('/Users/allenthomas/TidalHack26/.cursor/debug.log').writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
    } catch (_) {}
    // #endregion

    final toolName = AdkService.getCurrentToolFromEvents(events);
    if (toolName != null) {
      _agentStatus = 'Running: $toolName';
      notifyListeners();
    }

    final rawText = AdkService.getFinalTextFromEvents(events);
    final fallback = _buildFallbackForNoResponse(events);
    final textToSanitize = rawText ?? fallback;
    final responseText = _sanitizeToolCallGarbage(textToSanitize);

    // Final check before adding messages
    if (token != _sendToken) return;

    _agentMessages.add({'role': 'assistant', 'content': responseText});
    _messages.add(Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: responseText,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    ));
    // Reset session when open_url was called so next turn gets a fresh context (avoids context bloat after opening docs/links).
    if (toolsCalled.contains('open_url')) {
      _adkSessionId = null;
    }
    _agentStatus = null;
  }

  Future<void> _sendMessageViaOrchestrator(int token) async {
    final registry = ToolRegistry.global;
    final orchestrator = AgentOrchestrator(
      service: _service,
      tools: registry.getToolsForLLM(),
      executeTool: (name, args) => registry.execute(name, args),
      onStatus: (status) {
        // Only update status if not cancelled
        if (token == _sendToken) {
          _agentStatus = status;
          notifyListeners();
        }
      },
      systemPrompt: _jarvisSystemPrompt,
    );
    final (responseText, updatedMessages) = await orchestrator.run(_agentMessages);
    
    // Check if cancelled after orchestrator run
    if (token != _sendToken) return;
    
    _agentMessages = updatedMessages;

    _messages.add(Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: responseText,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    ));
  }

  /// Build a contextual fallback when the agent returns no meaningful text.
  static String _buildFallbackForNoResponse(List<Map<String, dynamic>> events) {
    final tools = AdkService.getToolsCalledFromEvents(events);
    if (tools.contains('create_google_doc')) {
      return 'I ran your request. If you asked for a document, check your Google Docs—it may have been created. You can also try rephrasing.';
    }
    if (tools.contains('open_url')) {
      return 'I ran your request. A link may have been opened in your browser. You can also try rephrasing.';
    }
    if (tools.isNotEmpty) {
      return 'I ran your request but didn\'t get a clear summary. Check whether the action completed (e.g. document, link, email). You can also try rephrasing.';
    }
    return 'I didn\'t get a clear response this time. If you asked for a document or link, check your Google Docs or browser—it may have been created. Try rephrasing or say "create the doc" again.';
  }

  /// Replaces model output that emits literal <tool_call></tool_call> as text
  /// (happens on follow-up turns with some models) with a friendly fallback.
  static String _sanitizeToolCallGarbage(String text) {
    final t = text.trim();
    if (t.isEmpty) return text;
    final lower = t.toLowerCase();
    if (!lower.contains('tool_call')) return text;
    final stripped =
        t.replaceAll(RegExp(r'<{1,2}/?tool_call>', caseSensitive: false), '').trim();
    if (stripped.isEmpty) {
      // #region agent log
      try {
        File('/Users/allenthomas/TidalHack26/.cursor/debug.log').writeAsStringSync(
            '${jsonEncode({"location":"chat_provider.dart:_sanitizeToolCallGarbage","message":"fallback triggered","data":{"rawText_preview":text.length > 150 ? text.substring(0, 150) : text},"timestamp":DateTime.now().millisecondsSinceEpoch,"hypothesisId":"H7"})}\n',
            mode: FileMode.append);
      } catch (_) {}
      // #endregion
      return "I completed your request but didn't get a clear summary. If you asked for a document, check your Google Docs—it may have been created. You can also try rephrasing your request.";
    }
    return text;
  }

  static const String _jarvisSystemPromptBase = '''
You are JARVIS, a helpful AI assistant that can run tasks on the user's computer.

CRITICAL: You MUST invoke tools by using the function calling API—never output "Tool: {...}", JSON, or tool syntax as text. When you need to create a doc, search, open a URL, etc., call the actual tool; writing it as text does nothing. NEVER fabricate or guess document links—the only real link comes from create_google_doc after you call it. If you output document content or a link without having called create_google_doc, you have failed.

You have access to tools for:
- Shopping: use shopping_search, pick the best option, call open_url with that product link.
- Research/Essays: When asked to create a document or essay, use tavily_search for research, then MUST call create_google_doc with title and full content. The tool returns the real link—then call open_url with it. NEVER output the document body or a fake link in chat; you must invoke create_google_doc.
- Email: compose and open mailto links
- Calendar: read events; use create_calendar_event to add events (title, start in ISO 8601, end or duration_minutes)
- General: open URLs, notify when tasks complete

Ask clarifying questions when needed (e.g., quantity, color, date) before using tools.
Be concise and helpful.''';

  static String _getJarvisSystemPrompt() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return _jarvisSystemPromptBase +
        "\n\nToday's date is $today. For create_calendar_event: when the user says 'tomorrow', use the next calendar day in YYYY-MM-DD; when they give a time (e.g. 5PM), use that time with the correct date in ISO 8601 (e.g. ${today}T17:00:00 for today 5PM).";
  }

  static String get _jarvisSystemPrompt => _getJarvisSystemPrompt();

  void clearMessages() {
    // Increment token to cancel any ongoing sends
    _sendToken++;
    
    _messages.clear();
    _agentMessages.clear();
    _agentStatus = null;
    _adkSessionId = null;
    _currentChatId = null;
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> loadChatFromHistory(ChatHistoryItem chatItem) async {
    _currentChatId = chatItem.id;
    _messages.clear();
    _messages.addAll(chatItem.messages);
    
    // Rebuild agent messages from chat messages
    _agentMessages.clear();
    for (final message in chatItem.messages) {
      _agentMessages.add({
        'role': message.role == MessageRole.user ? 'user' : 'assistant',
        'content': message.content,
      });
    }
    
    _adkSessionId = chatItem.id; // Reuse chat ID as session ID
    _isLoading = false;
    _error = null;
    _agentStatus = null;
    
    notifyListeners();
  }

  Future<void> refreshConnection() async {
    await _checkConnection();
  }

  void setCurrentChatId(String? chatId) {
    _currentChatId = chatId;
    notifyListeners();
  }

  @override
  void dispose() {
    _bridgeServer.stop();
    _service.dispose();
    super.dispose();
  }
}


