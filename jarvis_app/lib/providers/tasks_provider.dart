import 'package:flutter/foundation.dart';
import '../models/task.dart';

class TasksProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  String _filter = 'pending'; // pending, completed, all
  bool _isLoading = false;

  List<Task> get tasks => _tasks;
  String get filter => _filter;
  bool get isLoading => _isLoading;

  List<Task> get todayTasks => _tasks.where((t) => t.isDueToday && t.status == TaskStatus.pending).toList();
  List<Task> get overdueTasks => _tasks.where((t) => t.isOverdue).toList();

  Future<void> loadTasks({String? filter}) async {
    if (filter != null) _filter = filter;
    _isLoading = true;
    notifyListeners();

    // Tasks are now managed locally
    // Can be extended to use local storage or Featherless.ai for task management
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createTask(String title, {String? description, String? priority, String? dueDate}) async {
    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      description: description,
      priority: _parsePriority(priority),
      dueDate: dueDate != null ? DateTime.tryParse(dueDate) : null,
      createdAt: DateTime.now(),
      status: TaskStatus.pending,
    );
    _tasks.add(newTask);
    notifyListeners();
    return true;
  }

  TaskPriority _parsePriority(String? priority) {
    if (priority == null) return TaskPriority.medium;
    final str = priority.toLowerCase();
    if (str == 'high') return TaskPriority.high;
    if (str == 'low') return TaskPriority.low;
    return TaskPriority.medium;
  }

  Future<bool> completeTask(int taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final index = _tasks.indexOf(task);
    _tasks[index] = Task(
      id: task.id,
      title: task.title,
      description: task.description,
      priority: task.priority,
      dueDate: task.dueDate,
      createdAt: task.createdAt,
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
    );
    notifyListeners();
    return true;
  }

  Future<bool> deleteTask(int taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
    return true;
  }

  void setFilter(String filter) {
    _filter = filter;
    loadTasks();
  }
}
