import 'package:url_launcher/url_launcher.dart';

import 'tool_registry.dart';

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
  if (urlStr.isEmpty) return 'Error: url is required';

  try {
    final uri = Uri.parse(urlStr);
    final canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return 'Opened $urlStr in browser.';
    }
    return 'Error: Cannot launch URL $urlStr';
  } catch (e) {
    return 'Error: $e';
  }
}

void registerOpenUrlTool(ToolRegistry registry) {
  registry.register('open_url', openUrlSchema, openUrlExecutor);
}
