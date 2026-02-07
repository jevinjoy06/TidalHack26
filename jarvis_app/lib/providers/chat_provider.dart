import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/message.dart';
import '../models/connection_status.dart';
import '../services/featherless_service.dart';

class ChatProvider extends ChangeNotifier {
  FeatherlessService _service = FeatherlessService();
  String? _currentApiKey;
  String? _currentModel;
  String? _currentBaseUrl;
  final List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  String? _connectionError;
  String? _currentChatId;

  List<Message> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConnected => _connectionStatus == ConnectionStatus.connected;
  ConnectionStatus get connectionStatus => _connectionStatus;
  String? get connectionError => _connectionError;
  String? get currentChatId => _currentChatId;

  ChatProvider() {
    _checkConnection();
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

    // Add user message
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
    _messages.add(userMessage);
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.sendMessage(content);
      _messages.add(response);
      _connectionStatus = ConnectionStatus.connected;
      _connectionError = null;
    } catch (e) {
      _error = e.toString();
      _connectionStatus = ConnectionStatus.networkError;
      _connectionError = e.toString();

      // Add error message
      _messages.add(Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Sorry, I encountered an error: ${e.toString()}',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        status: MessageStatus.error,
        error: e.toString(),
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages.clear();
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
    _service.dispose();
    super.dispose();
  }
}


