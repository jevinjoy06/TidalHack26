import 'dart:convert';
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

import 'tool_registry.dart';

// #region agent log
void _log(String loc, String msg, Map<String, dynamic> data) {
  try {
    final p = {
      'location': loc,
      'message': msg,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'hypothesisId': 'H4',
    };
    File('/Users/allenthomas/TidalHack26/.cursor/debug.log')
        .writeAsStringSync('${jsonEncode(p)}\n', mode: FileMode.append);
  } catch (_) {}
}
// #endregion

const openUrlSchema = {
  'type': 'function',
  'function': {
    'name': 'open_url',
    'description': 'Open a URL in the default browser. Use for product pages, search results, documents, etc.',
    'parameters': {
      'type': 'object',
      'properties': {
        'url': {'type': 'string', 'description': 'The full URL to open (e.g. https://example.com)'},
      },
      'required': ['url'],
    },
  },
};

Future<String> openUrlExecutor(Map<String, dynamic> args) async {
  final urlStr = args['url']?.toString() ?? '';
  // #region agent log
  _log('open_url_tool.dart:entry', 'openUrlExecutor called', {
    'url_preview': urlStr.length > 80 ? '${urlStr.substring(0, 80)}...' : urlStr,
    'url_full': urlStr,
    'url_length': urlStr.length,
    'hypothesisId': 'H7',
  });
  // #endregion
  if (urlStr.isEmpty) return 'Error: url is required';

  try {
    final uri = Uri.parse(urlStr);
    final canLaunch = await canLaunchUrl(uri);
    // #region agent log
    _log('open_url_tool.dart:canLaunch', 'canLaunchUrl result', {'canLaunch': canLaunch});
    // #endregion
    if (canLaunch) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      // #region agent log
      _log('open_url_tool.dart:launched', 'launchUrl succeeded', {});
      // #endregion
      return 'Opened $urlStr in browser.';
    }
    // #region agent log
    _log('open_url_tool.dart:cannot_launch', 'canLaunchUrl false', {});
    // #endregion
    return 'Error: Cannot launch URL $urlStr';
  } catch (e) {
    // #region agent log
    _log('open_url_tool.dart:exception', 'launchUrl error', {'error': e.toString()});
    // #endregion
    return 'Error: $e';
  }
}

void registerOpenUrlTool(ToolRegistry registry) {
  registry.register('open_url', openUrlSchema, openUrlExecutor);
}
