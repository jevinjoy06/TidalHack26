enum TaskStatus {
  pending,
  completed,
  cancelled,
}

enum TaskPriority {
  low,
  medium,
  high,
}

class Task {
  final int id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? completedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.priority = TaskPriority.medium,
    this.dueDate,
    required this.createdAt,
    this.completedAt,
  });

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  bool get isOverdue {
    if (dueDate == null || status == TaskStatus.completed) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      status: _parseStatus(json['status']),
      priority: _parsePriority(json['priority']),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  static TaskStatus _parseStatus(dynamic status) {
    if (status == null) return TaskStatus.pending;
    final str = status.toString().toLowerCase();
    if (str == 'completed' || str == 'done') return TaskStatus.completed;
    if (str == 'cancelled' || str == 'canceled') return TaskStatus.cancelled;
    return TaskStatus.pending;
  }

  static TaskPriority _parsePriority(dynamic priority) {
    if (priority == null) return TaskPriority.medium;
    final str = priority.toString().toLowerCase();
    if (str == 'high') return TaskPriority.high;
    if (str == 'low') return TaskPriority.low;
    return TaskPriority.medium;
  }
}
