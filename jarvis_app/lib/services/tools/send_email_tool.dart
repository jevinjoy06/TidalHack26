import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/secrets.dart';
import 'tool_registry.dart';

const sendEmailSchema = {
  'type': 'function',
  'function': {
    'name': 'send_email',
    'description': 'Send email via SMTP using configured credentials. If credentials not set, opens default mail client with pre-filled draft.',
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

  final email = Secrets.emailAddress;
  final password = Secrets.emailPassword;

  if (email.isNotEmpty && password.isNotEmpty) {
    try {
      final smtpServer = gmail(email, password);
      final message = Message()
        ..from = Address(email, 'JARVIS')
        ..recipients.add(to)
        ..subject = subject
        ..text = body;

      await send(message, smtpServer);
      return 'Sent email to $to.';
    } catch (e) {
      return 'Error sending email: $e';
    }
  }

  // Fallback: open default mail client
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
    return 'Error: No email credentials in .env (EMAIL_ADDRESS, EMAIL_APP_PASSWORD) and cannot open mail client.';
  } catch (e) {
    return 'Error: $e';
  }
}

void registerSendEmailTool(ToolRegistry registry) {
  registry.register('send_email', sendEmailSchema, sendEmailExecutor);
}
