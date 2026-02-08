import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/tasks_provider.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/section_header.dart';

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

    return Consumer<TasksProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.tasks.isEmpty) {
          return _buildSkeletonLoading();
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1152),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar: title, subtitle, Filter + New task (Figma)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tasks',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.figmaForeground : AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage and track your work',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppTheme.figmaMutedForeground : AppTheme.textDarkSecondary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            onPressed: () => _showFilterSheet(context, isDark, provider),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isDark ? AppTheme.figmaBorder : AppTheme.borderLight,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.slider_horizontal_3,
                                    size: 16,
                                    color: isDark ? AppTheme.figmaForeground : AppTheme.textDark,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Filter',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? AppTheme.figmaForeground : AppTheme.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => _showAddTaskDialog(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.figmaAccent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.figmaAccent.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(CupertinoIcons.add, size: 16, color: CupertinoColors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    'New task',
                                    style: TextStyle(
                                      color: CupertinoColors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Filter pills (Pending / Completed / All)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.figmaCard.withOpacity(0.4) : AppTheme.bgLightTertiary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? AppTheme.figmaBorder : AppTheme.borderLight,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          _filterChip(context, 0, 'Pending', isDark, provider),
                          _filterChip(context, 1, 'Completed', isDark, provider),
                          _filterChip(context, 2, 'All', isDark, provider),
                        ],
                      ),
                    ),
                  ),
                  // Two columns: main content + suggestions panel
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final useColumn = constraints.maxWidth > 900;
                      if (useColumn) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildMainTasksSection(provider, isDark),
                            ),
                            const SizedBox(width: 24),
                            SizedBox(
                              width: 320,
                              child: _buildSuggestionsPanel(isDark),
                            ),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildMainTasksSection(provider, isDark),
                          const SizedBox(height: 24),
                          _buildSuggestionsPanel(isDark),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _filterChip(
    BuildContext context,
    int index,
    String label,
    bool isDark,
    TasksProvider provider,
  ) {
    final active = _selectedSegment == index;
    return Expanded(
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 8),
        onPressed: () {
          setState(() => _selectedSegment = index);
          final filters = ['pending', 'completed', 'all'];
          provider.setFilter(filters[index]);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? (isDark ? AppTheme.bgDarkTertiary : AppTheme.bgLight)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: active
                  ? (isDark ? AppTheme.figmaForeground : AppTheme.textDark)
                  : (isDark ? AppTheme.figmaMutedForeground : AppTheme.textDarkSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainTasksSection(TasksProvider provider, bool isDark) {
    final todayTasks = provider.tasks.where((t) => t.isDueToday && t.status != TaskStatus.completed).toList();
    final completedToday = provider.tasks.where((t) => t.isDueToday && t.status == TaskStatus.completed).toList();
    final upcoming = provider.tasks
        .where((t) => t.dueDate != null && !t.isDueToday && t.status != TaskStatus.completed)
        .toList();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowTasks = upcoming.where((t) {
      final d = t.dueDate!;
      return d.year == tomorrow.year && d.month == tomorrow.month && d.day == tomorrow.day;
    }).toList();
    final weekTasks = upcoming.where((t) {
      final d = t.dueDate!;
      final now = DateTime.now();
      return d.isAfter(tomorrow) && d.difference(now).inDays <= 7;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Today section (Figma)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.figmaCard.withOpacity(0.4) : AppTheme.bgLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppTheme.figmaBorder : AppTheme.borderLight,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Today',
                badge: 'SYNC OK',
                action: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _smallChip('${todayTasks.length} due today', AppTheme.figmaAccent, isDark),
                    const SizedBox(width: 8),
                    _smallChip('${completedToday.length} completed', AppTheme.success, isDark),
                  ],
                ),
              ),
              if (todayTasks.isEmpty && completedToday.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'No tasks due today',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppTheme.figmaMutedForeground : AppTheme.textDarkSecondary,
                    ),
                  ),
                )
              else
                ...todayTasks.map((t) => _buildTaskTile(t, provider, isDark)),
                ...completedToday.map((t) => _buildTaskTile(t, provider, isDark)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Upcoming section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.figmaCard.withOpacity(0.4) : AppTheme.bgLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppTheme.figmaBorder : AppTheme.borderLight,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Upcoming', badge: 'LOCAL CACHE'),
              if (tomorrowTasks.isNotEmpty) ...[
                _periodLabel('Tomorrow', isDark),
                const SizedBox(height: 8),
                ...tomorrowTasks.map((t) => _buildTaskTile(t, provider, isDark)),
                const SizedBox(height: 16),
              ],
              if (weekTasks.isNotEmpty) ...[
                _periodLabel('This Week', isDark),
                const SizedBox(height: 8),
                ...weekTasks.map((t) => _buildTaskTile(t, provider, isDark)),
              ],
              if (tomorrowTasks.isEmpty && weekTasks.isEmpty)
                Text(
                  'No upcoming tasks',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppTheme.figmaMutedForeground : AppTheme.textDarkSecondary,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Quick actions (Figma)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.figmaCard.withOpacity(0.4) : AppTheme.bgLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppTheme.figmaBorder : AppTheme.borderLight,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Quick actions'),
              const SizedBox(height: 8),
              Row(
                children: [
                  _quickActionButton('From conversation', isDark),
                  const SizedBox(width: 8),
                  _quickActionButton('From email', isDark),
                  const SizedBox(width: 8),
                  _quickActionButton('From notes', isDark),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _smallChip(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color),
      ),
    );
  }

  Widget _periodLabel(String label, bool isDark) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: isDark ? AppTheme.figmaMutedForeground : AppTheme.textDarkSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _quickActionButton(String label, bool isDark) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onPressed: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? AppTheme.figmaBorder : AppTheme.borderLight,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.sparkles,
              size: 16,
              color: isDark ? AppTheme.figmaSecondary : const Color(0xFF0369A1),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.figmaForeground : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsPanel(bool isDark) {
    final suggestions = [
      ('Schedule follow-up for client demo', 'Based on your calendar'),
      ('Review pending code reviews', '3 PRs awaiting review'),
      ('Update team on Q1 metrics', 'Deadline tomorrow'),
    ];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.figmaCard.withOpacity(0.4) : AppTheme.bgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.figmaSecondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.sparkles, size: 16, color: AppTheme.figmaSecondary),
              const SizedBox(width: 8),
              Text(
                'Suggested next actions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.figmaForeground : AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...suggestions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.bgDark.withOpacity(0.5) : AppTheme.bgLightSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (isDark ? AppTheme.figmaBorder : AppTheme.borderLight).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.$1,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppTheme.figmaForeground : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.$2,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.figmaMutedForeground : AppTheme.textDarkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 10),
              onPressed: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.figmaSecondary.withOpacity(0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Apply suggestions',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.figmaSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: (isDark ? AppTheme.figmaBorder : AppTheme.borderLight).withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LAST UPDATE: 2m ago',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: (isDark ? AppTheme.figmaMutedForeground : AppTheme.textDarkSecondary).withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI: ACTIVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: (isDark ? AppTheme.figmaMutedForeground : AppTheme.textDarkSecondary).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(Task task, TasksProvider provider, bool isDark) {
    final priorityColor = _getPriorityColor(task.priority);
    final isCompleted = task.status == TaskStatus.completed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgDark.withOpacity(0.5) : AppTheme.bgLightSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: (isDark ? AppTheme.figmaBorder : AppTheme.borderLight).withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: isCompleted ? null : () => provider.completeTask(task.id),
              child: Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? AppTheme.success : Colors.transparent,
                  border: Border.all(
                    color: isCompleted ? AppTheme.success : (isDark ? AppTheme.figmaMutedForeground : CupertinoColors.systemGrey3),
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(CupertinoIcons.checkmark, size: 12, color: CupertinoColors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isCompleted
                          ? (isDark ? AppTheme.figmaMutedForeground : AppTheme.textDarkSecondary)
                          : (isDark ? AppTheme.figmaForeground : AppTheme.textDark),
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
                        fontSize: 12,
                        color: isDark ? AppTheme.figmaMutedForeground : AppTheme.textDarkSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (task.dueDate != null) ...[
                        Text(
                          _formatDate(task.dueDate!),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.figmaMutedForeground : AppTheme.textDarkSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: priorityColor.withOpacity(0.3), width: 1),
                        ),
                        child: Text(
                          task.priority.name,
                          style: TextStyle(fontSize: 11, color: priorityColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              onPressed: () => _confirmDelete(task, provider),
              child: Icon(
                CupertinoIcons.ellipsis_vertical,
                size: 16,
                color: isDark ? AppTheme.figmaMutedForeground : AppTheme.textDarkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                  color: AppTheme.figmaAccent.withOpacity(0.3),
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
              color: isDark ? AppTheme.figmaForeground : AppTheme.textDark,
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
              color: isDark ? AppTheme.figmaMutedForeground : AppTheme.textDarkSecondary,
            ),
          )
              .animate(delay: 250.ms)
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.1, end: 0, duration: 350.ms),
        ],
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppTheme.error;
      case TaskPriority.medium:
        return AppTheme.warning;
      case TaskPriority.low:
        return AppTheme.figmaSecondary;
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

  void _showFilterSheet(BuildContext context, bool isDark, TasksProvider provider) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Filter tasks'),
        message: const Text('Show tasks by status'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedSegment = 0);
              provider.setFilter('pending');
              Navigator.pop(ctx);
            },
            child: const Text('Pending'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedSegment = 1);
              provider.setFilter('completed');
              Navigator.pop(ctx);
            },
            child: const Text('Completed'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedSegment = 2);
              provider.setFilter('all');
              Navigator.pop(ctx);
            },
            child: const Text('All'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
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
