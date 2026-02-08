import 'message.dart';

class ChatHistoryItem {
  final String id;
  final String summary;
  final DateTime lastUpdated;
  final List<Message> messages;
  final bool isLoading;

  ChatHistoryItem({
    required this.id,
    required this.summary,
    required this.lastUpdated,
    required this.messages,
    this.isLoading = false,
  });

  ChatHistoryItem copyWith({
    String? id,
    String? summary,
    DateTime? lastUpdated,
    List<Message>? messages,
    bool? isLoading,
  }) {
    return ChatHistoryItem(
      id: id ?? this.id,
      summary: summary ?? this.summary,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'summary': summary,
      'lastUpdated': lastUpdated.toIso8601String(),
      'messages': messages.map((m) => _messageToJson(m)).toList(),
      'isLoading': isLoading,
    };
  }

  static ChatHistoryItem fromJson(Map<String, dynamic> json) {
    return ChatHistoryItem(
      id: json['id'] as String,
      summary: json['summary'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      messages: (json['messages'] as List<dynamic>)
          .map((m) => _messageFromJson(m as Map<String, dynamic>))
          .toList(),
      isLoading: json['isLoading'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> _messageToJson(Message message) {
    return {
      'id': message.id,
      'content': message.content,
      'role': message.role.name,
      'timestamp': message.timestamp.toIso8601String(),
      'status': message.status.name,
      'error': message.error,
      'cardType': message.cardType,
      'richData': message.richData,
      'taskId': message.taskId,
    };
  }

  static Message _messageFromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      content: json['content'] as String,
      role: MessageRole.values.firstWhere((e) => e.name == json['role']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: MessageStatus.values.firstWhere((e) => e.name == json['status']),
      error: json['error'] as String?,
      cardType: json['cardType'] as String?,
      richData: json['richData'] as Map<String, dynamic>?,
      taskId: json['taskId'] as String?,
    );
  }
}
