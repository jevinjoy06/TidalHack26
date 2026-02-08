import 'package:googleapis/gmail/v1.dart' as gmail;

import 'google_docs_tool.dart';
import 'tool_registry.dart';

const readEmailsSchema = {
  'type': 'function',
  'function': {
    'name': 'read_emails',
    'description':
        "Fetch the user's latest emails from Gmail and return sender, subject, and snippet. Use to summarize inbox or answer who sent what.",
    'parameters': {
      'type': 'object',
      'properties': {
        'max_results': {
          'type': 'integer',
          'description': 'Maximum number of emails to return (default 15, max 25)',
        },
        'unread_only': {
          'type': 'boolean',
          'description': 'If true, return only unread emails',
        },
      },
      'required': [],
    },
  },
};

const int _maxResultsCap = 25;
const int _defaultMaxResults = 15;
const int _snippetMaxLength = 200;

String _headerValue(gmail.Message msg, String name) {
  final headers = msg.payload?.headers;
  if (headers == null) return '';
  for (final h in headers) {
    if (h.name?.toLowerCase() == name.toLowerCase()) return h.value ?? '';
  }
  return '';
}

Future<String> readEmailsExecutor(Map<String, dynamic> args) async {
  final client = await getAuthenticatedClient();
  if (client == null) {
    return 'Error: Please sign in with Google first (Settings > Sign in with Google).';
  }

  var maxResults = args['max_results'];
  if (maxResults != null) {
    if (maxResults is int) {
      maxResults = maxResults.clamp(1, _maxResultsCap);
    } else {
      final n = int.tryParse(maxResults.toString());
      maxResults = n != null ? n.clamp(1, _maxResultsCap) : _defaultMaxResults;
    }
  } else {
    maxResults = _defaultMaxResults;
  }
  final unreadOnly = args['unread_only'] == true;

  try {
    final gmailApi = gmail.GmailApi(client);
    final listResponse = await gmailApi.users.messages.list(
      'me',
      maxResults: maxResults,
      q: unreadOnly ? 'is:unread' : null,
      labelIds: ['INBOX'],
    );

    final messages = listResponse.messages;
    if (messages == null || messages.isEmpty) {
      return unreadOnly
          ? 'No unread emails in inbox.'
          : 'No emails found in inbox.';
    }

    final fullMessages = <gmail.Message>[];
    for (final ref in messages) {
      final id = ref.id;
      if (id == null) continue;
      try {
        final msg = await gmailApi.users.messages.get(
          'me',
          id,
          format: 'metadata',
          metadataHeaders: ['From', 'Subject', 'Date'],
        );
        fullMessages.add(msg);
      } catch (_) {
        // Skip single message on error
      }
    }

    fullMessages.sort((a, b) {
      final aUnread = a.labelIds?.contains('UNREAD') ?? false;
      final bUnread = b.labelIds?.contains('UNREAD') ?? false;
      if (aUnread != bUnread) return aUnread ? -1 : 1;
      final aDate = int.tryParse(a.internalDate ?? '0') ?? 0;
      final bDate = int.tryParse(b.internalDate ?? '0') ?? 0;
      return bDate.compareTo(aDate);
    });

    final sb = StringBuffer();
    for (var i = 0; i < fullMessages.length; i++) {
      final msg = fullMessages[i];
      final from = _headerValue(msg, 'From');
      final subject = _headerValue(msg, 'Subject');
      final date = _headerValue(msg, 'Date');
      var snippet = msg.snippet ?? '';
      if (snippet.length > _snippetMaxLength) {
        snippet = '${snippet.substring(0, _snippetMaxLength)}...';
      }
      sb.writeln(
          '${i + 1}. From: $from | Subject: $subject | Date: $date | Snippet: $snippet');
    }
    return sb.toString().trim();
  } catch (e) {
    return 'Error fetching emails: $e';
  }
}

void registerReadEmailsTool(ToolRegistry registry) {
  registry.register('read_emails', readEmailsSchema, readEmailsExecutor);
}
