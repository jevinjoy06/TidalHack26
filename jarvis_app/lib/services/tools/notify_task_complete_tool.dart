import 'tool_registry.dart';

const notifyTaskCompleteSchema = {
  'type': 'function',
  'function': {
    'name': 'notify_task_complete',
    'description': 'Notify the user that a task is done. Call this when you have completed a multi-step task (shopping, essay, email, etc.) to confirm completion.',
    'parameters': {
      'type': 'object',
      'properties': {
        'summary': {'type': 'string', 'description': 'Brief summary of what was done'},
        'details': {'type': 'string', 'description': 'Optional additional details'},
      },
      'required': ['summary'],
    },
  },
};

/// Callback to show in-app notification. Set by ChatProvider or UI.
void Function(String summary, String? details)? onTaskCompleteNotify;

Future<String> notifyTaskCompleteExecutor(Map<String, dynamic> args) async {
  final summary = args['summary']?.toString() ?? 'Task completed';
  final details = args['details']?.toString();

  onTaskCompleteNotify?.call(summary, details);
  return 'User notified: $summary';
}

void registerNotifyTaskCompleteTool(ToolRegistry registry) {
  registry.register('notify_task_complete', notifyTaskCompleteSchema, notifyTaskCompleteExecutor);
}
