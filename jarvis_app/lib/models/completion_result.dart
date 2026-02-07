/// Represents a single tool call from the LLM.
class ToolCall {
  final String id;
  final String name;
  final String arguments;

  ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    final function = json['function'] as Map<String, dynamic>? ?? {};
    return ToolCall(
      id: json['id'] as String? ?? '',
      name: function['name'] as String? ?? '',
      arguments: function['arguments'] as String? ?? '{}',
    );
  }
}

/// Result of a chat completion with optional tool calls.
/// Either [content] is set (text response) or [toolCalls] is set (tool call response).
class CompletionResult {
  final String? content;
  final List<ToolCall>? toolCalls;
  final String finishReason;

  CompletionResult({
    this.content,
    this.toolCalls,
    this.finishReason = 'stop',
  });

  bool get hasToolCalls => toolCalls != null && toolCalls!.isNotEmpty;
  bool get hasContent => content != null && content!.trim().isNotEmpty;
}
