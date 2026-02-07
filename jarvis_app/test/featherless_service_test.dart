import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis_app/models/completion_result.dart';

void main() {
  group('ToolCall', () {
    test('parses JSON correctly', () {
      final json = {
        'id': 'call_abc123',
        'type': 'function',
        'function': {
          'name': 'get_weather',
          'arguments': '{"location": "Boston"}',
        },
      };
      final toolCall = ToolCall.fromJson(json);
      expect(toolCall.id, 'call_abc123');
      expect(toolCall.name, 'get_weather');
      expect(toolCall.arguments, '{"location": "Boston"}');
    });

    test('handles missing fields gracefully', () {
      final toolCall = ToolCall.fromJson({});
      expect(toolCall.id, '');
      expect(toolCall.name, '');
      expect(toolCall.arguments, '{}');
    });
  });

  group('CompletionResult', () {
    test('hasToolCalls returns true when toolCalls exist', () {
      final result = CompletionResult(
        toolCalls: [ToolCall(id: '1', name: 'foo', arguments: '{}')],
      );
      expect(result.hasToolCalls, true);
      expect(result.hasContent, false);
    });

    test('hasContent returns true when content exists', () {
      final result = CompletionResult(content: 'Hello');
      expect(result.hasContent, true);
      expect(result.hasToolCalls, false);
    });
  });
}
