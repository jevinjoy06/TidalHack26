import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'tools/tool_registry.dart';
import 'tools/tool_setup.dart';

/// Minimal HTTP server for ADK local tools. Binds to 127.0.0.1:8765.
/// Handles POST /execute with {"tool": string, "args": map}.
/// Returns {"result": string}.
class LocalBridgeServer {
  LocalBridgeServer({int port = 8765}) : _port = port;

  final int _port;
  HttpServer? _server;
  bool _toolsRegistered = false;

  static const String _host = '127.0.0.1';

  /// Port the server is bound to. Valid after [start].
  int get port => _port;

  /// Whether the server is running.
  bool get isRunning => _server != null;

  /// Start the server. Idempotent.
  Future<void> start() async {
    if (_server != null) return;

    if (!_toolsRegistered) {
      registerAllTools();
      _toolsRegistered = true;
    }

    final handler = const shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addHandler(_handleRequest);

    try {
      _server = await shelf_io.serve(handler, _host, _port);
      debugPrint('LocalBridgeServer listening on http://$_host:$_port');
    } catch (e, st) {
      debugPrint('LocalBridgeServer failed to start: $e\n$st');
      rethrow;
    }
  }

  /// Stop the server.
  Future<void> stop() async {
    final s = _server;
    _server = null;
    if (s != null) {
      await s.close(force: true);
      debugPrint('LocalBridgeServer stopped');
    }
  }

  Future<shelf.Response> _handleRequest(shelf.Request request) async {
    if (request.method != 'POST') {
      return shelf.Response(
        HttpStatus.methodNotAllowed,
        body: 'Method Not Allowed',
      );
    }

    final path = request.url.path.replaceFirst(RegExp(r'^/'), '');
    if (path != 'execute' && path != 'execute/') {
      return shelf.Response(
        HttpStatus.notFound,
        body: 'Not Found',
      );
    }

    String bodyStr;
    try {
      bodyStr = await request.readAsString();
    } catch (e) {
      return shelf.Response(
        HttpStatus.badRequest,
        body: jsonEncode({'result': 'Error: Failed to read request body'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    Map<String, dynamic>? data;
    try {
      data = jsonDecode(bodyStr) as Map<String, dynamic>?;
    } catch (_) {
      return shelf.Response(
        HttpStatus.badRequest,
        body: jsonEncode({'result': 'Error: Invalid JSON'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final toolName = data?['tool']?.toString();
    final args = data?['args'];

    // #region agent log
    if (toolName == 'create_google_doc' || toolName == 'open_url') {
      try {
        final payload = {
          'location': 'local_bridge_server.dart:_handleRequest',
          'message': 'bridge received $toolName',
          'data': {'tool': toolName, 'args_keys': args is Map ? (args as Map).keys.toList() : null},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'hypothesisId': 'H4',
        };
        File('/Users/allenthomas/TidalHack26/.cursor/debug.log')
            .writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
      } catch (_) {}
    }
    // #endregion

    if (toolName == null || toolName.isEmpty) {
      return shelf.Response(
        HttpStatus.badRequest,
        body: jsonEncode({'result': 'Error: Missing "tool" field'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final argsMap = args is Map ? Map<String, dynamic>.from(args as Map) : <String, dynamic>{};
    final argsJson = jsonEncode(argsMap);

    try {
      final result = await ToolRegistry.global.execute(toolName, argsJson);
      // #region agent log
      if (toolName == 'create_google_doc' || toolName == 'open_url') {
        try {
          final payload = {
            'location': 'local_bridge_server.dart:execute_result',
            'message': '$toolName result',
            'data': {'result_preview': result.length > 100 ? '${result.substring(0, 100)}...' : result},
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'hypothesisId': 'H4',
          };
          File('/Users/allenthomas/TidalHack26/.cursor/debug.log')
              .writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
        } catch (_) {}
      }
      // #endregion
      return shelf.Response.ok(
        jsonEncode({'result': result}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, st) {
      debugPrint('LocalBridgeServer tool $toolName error: $e\n$st');
      return shelf.Response.ok(
        jsonEncode({'result': 'Error: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
