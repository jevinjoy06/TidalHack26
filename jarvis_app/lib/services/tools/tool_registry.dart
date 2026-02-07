import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Signature for a tool executor: takes parsed args, returns result string for the LLM.
typedef ToolExecutorFn = Future<String> Function(Map<String, dynamic> args);

/// Single tool entry: schema for LLM + executor function.
class ToolEntry {
  final Map<String, dynamic> schema;
  final ToolExecutorFn executor;

  ToolEntry({required this.schema, required this.executor});
}

/// Registry of tools. Add tools with [register], get schemas with [getToolsForLLM],
/// and create an executor with [createExecutor].
///
/// To add a new tool:
/// 1. Implement your executor: `Future<String> myTool(Map<String, dynamic> args) async { ... }`
/// 2. Call `ToolRegistry.global.register('my_tool', schema, myTool)`
/// 3. Add the schema to the tools list in your agent setup
class ToolRegistry {
  final Map<String, ToolEntry> _tools = {};

  static final ToolRegistry global = ToolRegistry._();
  ToolRegistry._();

  /// Register a tool. [schema] must be OpenAI format: {type: "function", function: {name, description, parameters}}.
  void register(String name, Map<String, dynamic> schema, ToolExecutorFn executor) {
    _tools[name] = ToolEntry(schema: schema, executor: executor);
  }

  /// Unregister a tool (for testing).
  void unregister(String name) {
    _tools.remove(name);
  }

  /// Get the list of tool schemas for the LLM API.
  List<Map<String, dynamic>> getToolsForLLM() {
    return _tools.values.map((e) => e.schema).toList();
  }

  /// Create a ToolExecutor that looks up tools by name and runs them.
  /// Pass this to AgentOrchestrator.
  Future<String> execute(String toolName, String argumentsJson) async {
    final entry = _tools[toolName];
    if (entry == null) {
      return 'Error: Unknown tool "$toolName"';
    }

    Map<String, dynamic> args = {};
    try {
      final decoded = argumentsJson.trim();
      if (decoded.isNotEmpty && decoded.startsWith('{')) {
        args = Map<String, dynamic>.from(
          jsonDecode(decoded) as Map,
        );
      }
    } catch (_) {
      return 'Error: Invalid JSON arguments';
    }

    try {
      return await entry.executor(args);
    } catch (e, st) {
      debugPrint('Tool $toolName error: $e\n$st');
      return 'Error: $e';
    }
  }
}
