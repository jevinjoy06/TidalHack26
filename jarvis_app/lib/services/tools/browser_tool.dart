import 'dart:convert';
import 'package:http/http.dart' as http;
import 'tool_registry.dart';

/// Browser automation tool - controls managed Chrome/Chromium via browser_api (port 8002)
void registerBrowserTool(ToolRegistry registry) {
  registry.register('browser', _browserSchema(), browserExecutor);
}

Map<String, dynamic> _browserSchema() {
  return {
    'name': 'browser',
    'description': '''Control a managed Chrome/Chromium instance for web automation.

Actions:
- start: Launch browser (params: profile, headless)
- stop: Close browser (params: profile)
- status: Get browser status (params: profile)
- navigate: Go to URL (params: url, profile, wait_until)
- snapshot: Get page structure with refs (params: profile, interactive, max_chars)
- screenshot: Capture screenshot (params: profile, full_page, save_path)
- click: Click element by ref (params: ref, profile)
- type: Type into element (params: ref, text, submit, profile)
- cookies: Get cookies (params: profile)
- set_cookie: Set cookie (params: name, value, url, profile)
- tabs: List open tabs (params: profile)

Always use snapshot first to get refs, then use refs for click/type actions.
Refs are not stable across navigations - re-run snapshot after page changes.''',
    'parameters': {
      'type': 'object',
      'properties': {
        'action': {
          'type': 'string',
          'enum': [
            'start',
            'stop',
            'status',
            'navigate',
            'snapshot',
            'screenshot',
            'click',
            'type',
            'cookies',
            'set_cookie',
            'tabs'
          ],
          'description': 'Browser action to perform',
        },
        'profile': {
          'type': 'string',
          'description': 'Browser profile name (default: jarvis)',
          'default': 'jarvis',
        },
        'headless': {
          'type': 'boolean',
          'description': 'Run browser in headless mode (default: false)',
          'default': false,
        },
        'url': {
          'type': 'string',
          'description': 'URL to navigate to (for navigate action)',
        },
        'wait_until': {
          'type': 'string',
          'description': 'Wait condition: load, domcontentloaded, networkidle',
          'default': 'load',
        },
        'interactive': {
          'type': 'boolean',
          'description': 'Include refs in snapshot (for snapshot action)',
          'default': false,
        },
        'max_chars': {
          'type': 'integer',
          'description': 'Max snapshot size (for snapshot action)',
          'default': 50000,
        },
        'full_page': {
          'type': 'boolean',
          'description': 'Capture full page (for screenshot action)',
          'default': true,
        },
        'save_path': {
          'type': 'string',
          'description': 'Screenshot save path (for screenshot action)',
        },
        'ref': {
          'type': ['integer', 'string'],
          'description': 'Element ref from snapshot (for click/type actions)',
        },
        'text': {
          'type': 'string',
          'description': 'Text to type (for type action)',
        },
        'submit': {
          'type': 'boolean',
          'description': 'Press Enter after typing (for type action)',
          'default': false,
        },
        'name': {
          'type': 'string',
          'description': 'Cookie name (for set_cookie action)',
        },
        'value': {
          'type': 'string',
          'description': 'Cookie value (for set_cookie action)',
        },
      },
      'required': ['action'],
    },
  };
}

Future<String> browserExecutor(Map<String, dynamic> args) async {
  final action = args['action'] as String?;
  if (action == null) {
    return jsonEncode({'error': 'Missing required parameter: action'});
  }

  final profile = args['profile'] as String? ?? 'jarvis';
  const baseUrl = 'http://127.0.0.1:8002/browser';

  try {
    http.Response response;

    switch (action) {
      case 'start':
        final headless = args['headless'] as bool? ?? false;
        response = await http.post(
          Uri.parse('$baseUrl/start?profile=$profile&headless=$headless'),
        );
        break;

      case 'stop':
        response = await http.post(
          Uri.parse('$baseUrl/stop?profile=$profile'),
        );
        break;

      case 'status':
        response = await http.get(
          Uri.parse('$baseUrl/status?profile=$profile'),
        );
        break;

      case 'navigate':
        final url = args['url'] as String?;
        if (url == null) {
          return jsonEncode({'error': 'Missing required parameter: url'});
        }
        final waitUntil = args['wait_until'] as String? ?? 'load';
        response = await http.post(
          Uri.parse('$baseUrl/navigate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'url': url,
            'profile': profile,
            'wait_until': waitUntil,
          }),
        );
        break;

      case 'snapshot':
        final interactive = args['interactive'] as bool? ?? false;
        final maxChars = args['max_chars'] as int? ?? 50000;
        response = await http.post(
          Uri.parse('$baseUrl/snapshot'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'profile': profile,
            'interactive': interactive,
            'max_chars': maxChars,
          }),
        );
        break;

      case 'screenshot':
        final fullPage = args['full_page'] as bool? ?? true;
        final savePath = args['save_path'] as String?;
        response = await http.post(
          Uri.parse('$baseUrl/screenshot'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'profile': profile,
            'full_page': fullPage,
            'save_path': savePath,
          }),
        );
        break;

      case 'click':
        final ref = args['ref'];
        if (ref == null) {
          return jsonEncode({'error': 'Missing required parameter: ref'});
        }
        response = await http.post(
          Uri.parse('$baseUrl/click'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'ref': ref,
            'profile': profile,
          }),
        );
        break;

      case 'type':
        final ref = args['ref'];
        final text = args['text'] as String?;
        if (ref == null || text == null) {
          return jsonEncode(
              {'error': 'Missing required parameters: ref, text'});
        }
        final submit = args['submit'] as bool? ?? false;
        response = await http.post(
          Uri.parse('$baseUrl/type'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'ref': ref,
            'text': text,
            'submit': submit,
            'profile': profile,
          }),
        );
        break;

      case 'cookies':
        response = await http.get(
          Uri.parse('$baseUrl/cookies?profile=$profile'),
        );
        break;

      case 'set_cookie':
        final name = args['name'] as String?;
        final value = args['value'] as String?;
        final url = args['url'] as String?;
        if (name == null || value == null || url == null) {
          return jsonEncode(
              {'error': 'Missing required parameters: name, value, url'});
        }
        response = await http.post(
          Uri.parse('$baseUrl/set-cookie'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'value': value,
            'url': url,
            'profile': profile,
          }),
        );
        break;

      case 'tabs':
        response = await http.get(
          Uri.parse('$baseUrl/tabs?profile=$profile'),
        );
        break;

      default:
        return jsonEncode({'error': 'Unknown action: $action'});
    }

    if (response.statusCode == 200) {
      return response.body;
    } else {
      return jsonEncode({
        'error': 'API error: ${response.statusCode} - ${response.body}'
      });
    }
  } catch (e) {
    return jsonEncode({'error': 'Browser tool failed: $e'});
  }
}
