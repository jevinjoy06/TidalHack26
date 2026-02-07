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

  AgentOrchestrator({
    required FeatherlessService service,
    required List<Map<String, dynamic>> tools,
    required ToolExecutor executeTool,
    StatusCallback? onStatus,
    int maxIterations = 10,
  })  : _service = service,
        _tools = tools,
        _executeTool = executeTool,
        _onStatus = onStatus,
        _maxIterations = maxIterations;

  /// Run the agent loop. Returns the final assistant message content.
  /// Throws on error or if max iterations exceeded.
  Future<String> run(String userMessage) async {
    final messages = <Map<String, dynamic>>[
      {'role': 'user', 'content': userMessage},
    ];

    for (var i = 0; i < _maxIterations; i++) {
      _onStatus?.call('Thinking...');

      final result = await _service.sendMessageWithTools(messages, _tools);

      if (result.hasToolCalls) {
        // Append assistant message with tool_calls
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
        messages.add(assistantMsg);

        // Execute each tool call and append results
        for (final tc in result.toolCalls!) {
          _onStatus?.call('Running: ${tc.name}');
          String toolResult;
          try {
            toolResult = await _executeTool(tc.name, tc.arguments);
          } catch (e) {
            toolResult = 'Error: $e';
          }
          messages.add({
            'role': 'tool',
            'tool_call_id': tc.id,
            'content': toolResult,
          });
        }
        continue;
      }

      // No tool calls – we have the final answer
      return result.content?.trim() ?? '';
    }

    throw Exception('Agent exceeded max iterations ($_maxIterations)');
  }
}
