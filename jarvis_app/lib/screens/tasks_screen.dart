import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/tasks_provider.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import '../widgets/shimmer_loading.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int _selectedSegment = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksProvider>().loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? AppTheme.bgDarkSecondary : AppTheme.bgLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
            width: 1,
          ),
        ),
        middle: Text(
          'Tasks',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.textPrimary : AppTheme.textDark,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 0,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              CupertinoIcons.add,
              color: CupertinoColors.white,
              size: 20,
            ),
          ),
          onPressed: () => _showAddTaskDialog(context),
        ),
      ),
      child: SafeArea(
        child: Consumer<TasksProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                // Filter segmented control
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: AppTheme.cardDecoration(isDark),
                    child: CupertinoSlidingSegmentedControl<int>(
                      groupValue: _selectedSegment,
                      backgroundColor: Colors.transparent,
                      thumbColor: isDark ? AppTheme.bgDarkTertiary : AppTheme.bgLight,
                      children: {
                        0: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            'Pending',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _selectedSegment == 0 
                                  ? (isDark ? AppTheme.textPrimary : AppTheme.textDark)
                                  : (isDark ? AppTheme.textTertiary : AppTheme.textDarkSecondary),
                            ),
                          ),
                        ),
                        1: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _selectedSegment == 1 
                                  ? (isDark ? AppTheme.textPrimary : AppTheme.textDark)
                                  : (isDark ? AppTheme.textTertiary : AppTheme.textDarkSecondary),
                            ),
                          ),
                        ),
                        2: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            'All',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _selectedSegment == 2 
                                  ? (isDark ? AppTheme.textPrimary : AppTheme.textDark)
                                  : (isDark ? AppTheme.textTertiary : AppTheme.textDarkSecondary),
                            ),
                          ),
                        ),
                      },
                      onValueChanged: (value) {
                        setState(() => _selectedSegment = value ?? 0);
                        final filters = ['pending', 'completed', 'all'];
                        provider.setFilter(filters[value ?? 0]);
                      },
                    ),
                  ),
                ),

                // Task list
                Expanded(
                  child: provider.isLoading && provider.tasks.isEmpty
                      ? _buildSkeletonLoading()
                      : provider.tasks.isEmpty
                          ? _buildEmptyState(isDark)
                          : _buildTaskList(provider, isDark),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: List.generate(5, (i) => SkeletonCard(lines: 2)),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryMaroon.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
            ),
            child: const Icon(
              CupertinoIcons.checkmark_circle,
              size: 40,
              color: CupertinoColors.white,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, curve: Curves.easeOut)
              .scaleXY(begin: 0.6, end: 1.0, duration: 500.ms, curve: Curves.easeOut),
          const SizedBox(height: 24),
          Text(
            'No tasks yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.textPrimary : AppTheme.textDark,
              letterSpacing: -0.5,
            ),
          )
              .animate(delay: 150.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.1, end: 0, duration: 350.ms),
          const SizedBox(height: 8),
          Text(
            'Create your first task to get started',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppTheme.textSecondary : AppTheme.textDarkSecondary,
            ),
          )
              .animate(delay: 250.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.1, end: 0, duration: 350.ms),
          const SizedBox(height: 8),
          Text(
            'Create tasks via chat or tap + above',
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.systemGrey,
            ),
          )
              .animate(delay: 350.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.1, end: 0, duration: 350.ms),
        ],
      ),
    );
  }

  Widget _buildTaskList(TasksProvider provider, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: provider.tasks.length,
      itemBuilder: (context, index) {
        return _buildTaskCard(provider.tasks[index], provider, isDark)
            .animate(delay: Duration(milliseconds: index * 50))
            .fadeIn(duration: 350.ms, curve: Curves.easeOut)
            .slideY(
              begin: 0.05,
              end: 0,
              duration: 350.ms,
              curve: const Cubic(0.4, 0, 0.2, 1),
            );
      },
    );
  }

  Widget _buildTaskCard(Task task, TasksProvider provider, bool isDark) {
    final priorityColor = _getPriorityColor(task.priority);
    final isCompleted = task.status == TaskStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecoration(isDark),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          GestureDetector(
            onTap: isCompleted ? null : () => provider.completeTask(task.id),
            child: Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? AppTheme.success : Colors.transparent,
                border: Border.all(
                  color: isCompleted ? AppTheme.success : CupertinoColors.systemGrey3,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(CupertinoIcons.checkmark, size: 14, color: CupertinoColors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: isCompleted
                        ? CupertinoColors.systemGrey
                        : (isDark ? CupertinoColors.white : CupertinoColors.black),
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (task.description != null && task.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Priority dot
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: priorityColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      task.priority.name,
                      style: TextStyle(fontSize: 12, color: priorityColor),
                    ),
                    if (task.dueDate != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        CupertinoIcons.calendar,
                        size: 12,
                        color: task.isOverdue ? AppTheme.error : CupertinoColors.systemGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(task.dueDate!),
                        style: TextStyle(
                          fontSize: 12,
                          color: task.isOverdue
                              ? AppTheme.error
                              : task.isDueToday
                                  ? AppTheme.warning
                                  : CupertinoColors.systemGrey,
                          fontWeight: task.isOverdue ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Delete button
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: () => _confirmDelete(task, provider),
            child: Icon(
              CupertinoIcons.delete,
              size: 18,
              color: CupertinoColors.systemGrey3,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high: return AppTheme.error;
      case TaskPriority.medium: return AppTheme.warning;
      case TaskPriority.low: return CupertinoColors.systemGrey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Tomorrow';
    }
    return '${date.month}/${date.day}';
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('New Task'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: titleController,
            placeholder: 'Task title',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Add'),
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                context.read<TasksProvider>().createTask(titleController.text.trim());
                Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Task task, TasksProvider provider) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Task'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text('Delete "${task.title}"?'),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              provider.deleteTask(task.id);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}

// Needed for Color reference in BoxDecoration border
class Colors {
  static const transparent = Color(0x00000000);
}
