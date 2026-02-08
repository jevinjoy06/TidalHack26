import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_history.dart';
import '../models/message.dart';
import 'chat_provider.dart';

class ChatHistoryProvider extends ChangeNotifier {
  static const String _storageKey = 'chat_history';
  static const int _maxHistoryItems = 50;

  List<ChatHistoryItem> _history = [];
  ChatProvider? _chatProvider;

  List<ChatHistoryItem> get history => List.unmodifiable(_history);
  String? get currentActiveChatId => _chatProvider?.currentChatId;

  void setChatProvider(ChatProvider chatProvider) {
    _chatProvider = chatProvider;
  }

  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _history = jsonList
            .map((item) => ChatHistoryItem.fromJson(item as Map<String, dynamic>))
            .toList();

        // Reset any stale loading states (from app restart)
        _resetStaleLoadingStates();
        
        // Sort by most recent first
        _sortHistory();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      _history = [];
    }
  }

  void _resetStaleLoadingStates() {
    final now = DateTime.now();
    bool updated = false;

    for (int i = 0; i < _history.length; i++) {
      final item = _history[i];
      if (item.isLoading) {
        final timeSinceUpdate = now.difference(item.lastUpdated);
        // Reset loading state if more than 5 minutes old
        if (timeSinceUpdate.inMinutes > 5) {
          _history[i] = item.copyWith(isLoading: false);
          updated = true;
        }
      }
    }

    if (updated) {
      _saveToStorage();
    }
  }

  Future<void> saveChat(String id, List<Message> messages, {bool isLoading = false}) async {
    if (messages.isEmpty) return;

    // Don't save if only user message and no response
    if (messages.length == 1 && !isLoading) return;

    // Get summary from first user message
    final firstUserMessage = messages.firstWhere(
      (m) => m.role == MessageRole.user,
      orElse: () => messages.first,
    );
    String summary = firstUserMessage.content;
    if (summary.length > 40) {
      summary = '${summary.substring(0, 40)}...';
    }

    final existingIndex = _history.indexWhere((item) => item.id == id);
    final chatItem = ChatHistoryItem(
      id: id,
      summary: summary,
      lastUpdated: DateTime.now(),
      messages: messages,
      isLoading: isLoading,
    );

    if (existingIndex >= 0) {
      _history[existingIndex] = chatItem;
    } else {
      _history.insert(0, chatItem);
    }

    // Enforce max limit
    if (_history.length > _maxHistoryItems) {
      _history = _history.sublist(0, _maxHistoryItems);
    }

    _sortHistory();
    await _saveToStorage();
    notifyListeners();
  }

  void setLoadingState(String id, bool isLoading) {
    final index = _history.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _history[index] = _history[index].copyWith(
        isLoading: isLoading,
        lastUpdated: DateTime.now(),
      );
      notifyListeners();
      // Save asynchronously without blocking
      _saveToStorage();
    }
  }

  Future<void> loadChatById(String id) async {
    final chatItem = _history.firstWhere(
      (item) => item.id == id,
      orElse: () => throw Exception('Chat not found'),
    );

    if (_chatProvider != null) {
      await _chatProvider!.loadChatFromHistory(chatItem);
    }
  }

  Future<void> deleteChat(String id) async {
    _history.removeWhere((item) => item.id == id);
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> renameChat(String id, String newSummary) async {
    final index = _history.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _history[index] = _history[index].copyWith(summary: newSummary);
      await _saveToStorage();
      notifyListeners();
    }
  }

  void _sortHistory() {
    _history.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _history.map((item) => item.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }
}
