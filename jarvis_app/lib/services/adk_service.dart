import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Client for the ADK API server (http://localhost:8000).
class AdkService {
  AdkService({required this.baseUrl});

  final String baseUrl;
  static const String appName = 'jarvis_agent';

  /// Create a session. POST /apps/{app}/users/{userId}/sessions/{sessionId}
  Future<Map<String, dynamic>> createSession({
    required String userId,
    required String sessionId,
    Map<String, dynamic>? state,
  }) async {
    final uri = Uri.parse('$baseUrl/apps/$appName/users/${Uri.encodeComponent(userId)}/sessions/${Uri.encodeComponent(sessionId)}');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: state != null ? jsonEncode(state) : '{}',
    );
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('ADK createSession failed: ${resp.statusCode} ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Run agent (non-streaming). POST /run
  Future<List<Map<String, dynamic>>> run({
    required String userId,
    required String sessionId,
    required String message,
  }) async {
    final uri = Uri.parse('$baseUrl/run');
    final body = jsonEncode({
      'appName': appName,
      'userId': userId,
      'sessionId': sessionId,
      'newMessage': {
        'role': 'user',
        'parts': [
          {'text': message}
        ],
      },
    });
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (resp.statusCode != 200) {
      throw Exception('ADK run failed: ${resp.statusCode} ${resp.body}');
    }
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  /// Run agent with SSE. POST /run_sse
  Stream<Map<String, dynamic>> runStreaming({
    required String userId,
    required String sessionId,
    required String message,
    bool streaming = false,
  }) async* {
    final uri = Uri.parse('$baseUrl/run_sse');
    final body = jsonEncode({
      'appName': appName,
      'userId': userId,
      'sessionId': sessionId,
      'newMessage': {
        'role': 'user',
        'parts': [
          {'text': message}
        ],
      },
      'streaming': streaming,
    });
    final req = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = body;

    final client = http.Client();
    final resp = await client.send(req);
    if (resp.statusCode != 200) {
      client.close();
      throw Exception('ADK run_sse failed: ${resp.statusCode}');
    }

    String buffer = '';
    await for (final chunk in resp.stream.transform(utf8.decoder)) {
      buffer += chunk;
      final lines = buffer.split('\n');
      buffer = lines.removeLast();
      for (final line in lines) {
        if (line.startsWith('data:')) {
          final data = line.substring(4).trim();
          if (data == '[DONE]' || data.isEmpty) continue;
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            yield json;
          } catch (_) {}
        }
      }
    }
    client.close();
  }

  /// Test connection: GET /list-apps and check for jarvis_agent
  Future<bool> testConnection() async {
    try {
      final uri = Uri.parse('$baseUrl/list-apps');
      final resp = await http.get(uri).timeout(const Duration(seconds: 5));
      if (resp.statusCode != 200) return false;
      final list = jsonDecode(resp.body) as List<dynamic>;
      return list.any((e) => e == appName);
    } catch (_) {
      return false;
    }
  }

  /// Extract text from a single ADK event (for streaming).
  static String? getTextFromEvent(Map<String, dynamic> event) {
    final content = event['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    if (parts == null) return null;
    for (final p in parts) {
      if (p is Map && p['text'] != null) {
        return p['text'] as String?;
      }
    }
    return null;
  }

  /// Extract tool name from a single event (for agentStatus).
  static String? getToolNameFromEvent(Map<String, dynamic> event) {
    final content = event['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    if (parts == null) return null;
    for (final p in parts) {
      if (p is Map && p['functionCall'] != null) {
        final fc = p['functionCall'] as Map<String, dynamic>?;
        return fc?['name'] as String?;
      }
    }
    return null;
  }

  /// Extract final assistant text from ADK events.
  /// Skips text that is only tool_call tags (LLM sometimes outputs these as literal text).
  static String? getFinalTextFromEvents(List<Map<String, dynamic>> events) {
    String? lastMeaningfulText;
    for (final e in events) {
      final content = e['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null) continue;
      for (final p in parts) {
        if (p is Map && p['text'] != null) {
          final t = (p['text'] as String?)?.trim() ?? '';
          if (t.isEmpty) continue;
          // Skip text that is only tool_call tags (strips to nothing)
          final lower = t.toLowerCase();
          if (lower.contains('tool_call')) {
            final stripped = t.replaceAll(RegExp(r'<{1,2}/?tool_call[^>]*>', caseSensitive: false), '').trim();
            if (stripped.isEmpty) continue; // Skip this garbage, keep previous meaningful text
          }
          lastMeaningfulText = p['text'] as String?;
        }
      }
    }
    return lastMeaningfulText;
  }

  /// Extract all tool names that were called from events.
  static Set<String> getToolsCalledFromEvents(List<Map<String, dynamic>> events) {
    final names = <String>{};
    for (final e in events) {
      final n = getToolNameFromEvent(e);
      if (n != null) names.add(n);
    }
    return names;
  }

  /// Extract current tool name from events (for agentStatus).
  static String? getCurrentToolFromEvents(List<Map<String, dynamic>> events) {
    for (var i = events.length - 1; i >= 0; i--) {
      final content = events[i]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null) continue;
      for (final p in parts) {
        if (p is Map && p['functionCall'] != null) {
          final fc = p['functionCall'] as Map<String, dynamic>?;
          return fc?['name'] as String?;
        }
      }
    }
    return null;
  }
}
