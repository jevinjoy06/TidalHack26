import 'package:url_launcher/url_launcher.dart';

import 'tool_registry.dart';

const sendEmailSchema = {
  'type': 'function',
  'function': {
    'name': 'send_email',
    'description': 'Open the default mail client with a pre-filled email. The LLM generates subject and body from the user\'s brief request. User reviews and clicks Send.',
    'parameters': {
      'type': 'object',
      'properties': {
        'to': {'type': 'string', 'description': 'Recipient email address'},
        'subject': {'type': 'string', 'description': 'Email subject line'},
        'body': {'type': 'string', 'description': 'Email body content'},
      },
      'required': ['to', 'subject', 'body'],
    },
  },
};

Future<String> sendEmailExecutor(Map<String, dynamic> args) async {
  final to = args['to']?.toString() ?? '';
  final subject = args['subject']?.toString() ?? '';
  final body = args['body']?.toString() ?? '';

  if (to.isEmpty) return 'Error: "to" is required';

  try {
    final uri = Uri.parse(
      'mailto:${Uri.encodeComponent(to)}'
      '?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return 'Opened email client with draft to $to. User can review and send.';
    }
    return 'Error: Cannot open mail client. Is a default mail app set?';
  } catch (e) {
    return 'Error: $e';
  }
}

void registerSendEmailTool(ToolRegistry registry) {
  registry.register('send_email', sendEmailSchema, sendEmailExecutor);
}
