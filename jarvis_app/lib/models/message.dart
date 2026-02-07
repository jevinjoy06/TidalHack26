enum MessageRole {
  user,
  assistant,
}

enum MessageStatus {
  sending,
  sent,
  error,
}

class Message {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final MessageStatus status;
  final String? error;
  final String? cardType;
  final Map<String, dynamic>? richData;
  final String? taskId;

  Message({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    required this.status,
    this.error,
    this.cardType,
    this.richData,
    this.taskId,
  });

  bool get hasRichCard => cardType != null && richData != null;
}
