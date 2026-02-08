import 'featherless_service.dart';

/// Callback to execute a tool. Returns the result string for the LLM.
typedef ToolExecutor = Future<String> Function(String toolName, String argumentsJson);

/// Callback for status updates (e.g., "Thinking...", "Running: get_weather").
typedef StatusCallback = void Function(String status);

/// ReAct-style agent orchestrator: LLM → tool calls → execute → feed back → repeat.
class AgentOrchestrator {
  final FeatherlessService _service;
  final List<Map<String, dynamic>> _tools;
  final ToolExecutor _executeTool;
  final StatusCallback? _onStatus;
  final int _maxIterations;
  final String? _systemPrompt;

  AgentOrchestrator({
    required FeatherlessService service,
    required List<Map<String, dynamic>> tools,
    required ToolExecutor executeTool,
    StatusCallback? onStatus,
    int maxIterations = 10,
    String? systemPrompt,
  })  : _service = service,
        _tools = tools,
        _executeTool = executeTool,
        _onStatus = onStatus,
        _maxIterations = maxIterations,
        _systemPrompt = systemPrompt;

  /// Run the agent loop. [messages] is the conversation so far (for multi-turn).
  /// For first turn, pass [{role: 'user', content: userMessage}].
  /// Returns (final assistant content, updated messages for next turn).
  Future<(String, List<Map<String, dynamic>>)> run(List<Map<String, dynamic>> messages) async {
    final mutableMessages = List<Map<String, dynamic>>.from(messages);
    final prompt = _systemPrompt?.trim();
    if (prompt != null && prompt.isNotEmpty) {
      final hasSystem = mutableMessages.isNotEmpty &&
          mutableMessages.first['role'] == 'system';
      if (!hasSystem) {
        mutableMessages.insert(0, {'role': 'system', 'content': prompt});
      }
    }

    for (var i = 0; i < _maxIterations; i++) {
      _onStatus?.call('Thinking...');

      final result = await _service.sendMessageWithTools(mutableMessages, _tools);

      if (result.hasToolCalls) {
        final assistantMsg = <String, dynamic>{
          'role': 'assistant',
          'content': result.content ?? '',
          'tool_calls': result.toolCalls!.map((tc) {
            return {
              'id': tc.id,
              'type': 'function',
              'function': {'name': tc.name, 'arguments': tc.arguments},
            };
          }).toList(),
        };
        mutableMessages.add(assistantMsg);

        for (final tc in result.toolCalls!) {
          _onStatus?.call('Running: ${tc.name}');
          String toolResult;
          try {
            toolResult = await _executeTool(tc.name, tc.arguments);
          } catch (e) {
            toolResult = 'Error: $e';
          }
          mutableMessages.add({
            'role': 'tool',
            'tool_call_id': tc.id,
            'content': toolResult,
          });
        }
        continue;
      }

      // No tool calls – we have the final answer; strip <think> blocks and append
      final rawContent = result.content?.trim() ?? '';
      final content = _stripThinkBlocks(rawContent);
      mutableMessages.add({'role': 'assistant', 'content': content});
      return (content, mutableMessages);
    }

    throw Exception('Agent exceeded max iterations ($_maxIterations)');
  }

  /// Removes <think>...</think> blocks from model output (some models emit these as visible text).
  static String _stripThinkBlocks(String text) {
    return text.replaceAll(RegExp(r'<think>[\s\S]*?</think>', dotAll: true), '').trim();
  }
}
