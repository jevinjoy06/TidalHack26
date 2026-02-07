# Tool Registry – Adding Your Own Tools

## How to Add a Tool

1. **Create your tool file** (e.g. `lib/services/tools/my_tool.dart`):

```dart
import 'tool_registry.dart';

const myToolSchema = {
  'type': 'function',
  'function': {
    'name': 'my_tool',
    'description': 'What your tool does',
    'parameters': {
      'type': 'object',
      'properties': {
        'arg1': {'type': 'string', 'description': 'Description'},
      },
      'required': ['arg1'],
    },
  },
};

Future<String> myToolExecutor(Map<String, dynamic> args) async {
  final arg1 = args['arg1']?.toString() ?? '';
  // Your logic here
  return 'Result for LLM';
}

void registerMyTool(ToolRegistry registry) {
  registry.register('my_tool', myToolSchema, myToolExecutor);
}
```

2. **Register it** in `tool_setup.dart`:

```dart
import 'my_tool.dart';

void registerAllTools() {
  // ...existing...
  registerMyTool(ToolRegistry.global);
}
```

3. Done. The orchestrator will pick it up automatically.
