import 'dart:convert';
import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/docs/v1.dart' as docs;

import '../../config/secrets.dart';
import 'tool_registry.dart';

const createGoogleDocSchema = {
  'type': 'function',
  'function': {
    'name': 'create_google_doc',
    'description': 'Create a new Google Doc with the given title and content. You MUST invoke this tool (do not write "Tool: {...}" as text). The content must be the actual document body—plain text only. Use \\n for paragraph breaks. Call this after researching; pass the full synthesized content.',
    'parameters': {
      'type': 'object',
      'properties': {
        'title': {'type': 'string', 'description': 'Document title (e.g. "Essay on Empire State Building")'},
        'content': {'type': 'string', 'description': 'The full document content as plain text. Use \\n for new lines between paragraphs.'},
      },
      'required': ['title', 'content'],
    },
  },
};

void _debugLog(String location, String message, Map<String, dynamic> data) {
  // #region agent log
  try {
    final payload = {
      'location': location,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'hypothesisId': 'H1',
    };
    File('/Users/allenthomas/TidalHack26/.cursor/debug.log')
        .writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
  } catch (_) {}
  // #endregion
}

Future<String> createGoogleDocExecutor(Map<String, dynamic> args) async {
  _debugLog('google_docs_tool.dart:createGoogleDocExecutor', 'entry', {'tool': 'create_google_doc'});
  final clientId = Secrets.googleClientId;
  final clientSecret = Secrets.googleClientSecret;
  if (clientId.isEmpty || clientSecret.isEmpty) {
    return 'Error: GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET not configured. Add to .env';
  }

  final title = args['title']?.toString().trim() ?? 'Untitled';
  var content = args['content']?.toString() ?? '';
  // Convert literal \n to real newlines and strip markdown/code blocks
  content = content
      .replaceAll(r'\n', '\n')
      .replaceAll(RegExp(r'```[\w]*\n?'), '')
      .replaceAll('```', '')
      .trim();
  // Sanitize: remove NUL and control chars that break Google Docs API
  content = content.replaceAll(RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]'), '');

  try {
    final docsService = await _getDocsService();
    _debugLog('google_docs_tool.dart:createGoogleDocExecutor', 'after _getDocsService', {'docsService_null': docsService == null});
    if (docsService == null) {
      return 'Error: Please sign in with Google first (Settings > Sign in with Google).';
    }

    final createResponse = await docsService.documents.create(docs.Document(
      title: title,
    ));
    final documentId = createResponse.documentId;
    if (documentId == null) return 'Error: Failed to create document';

    if (content.isNotEmpty) {
      _debugLog('google_docs_tool.dart:createGoogleDocExecutor', 'before batchUpdate', {
        'content_length': content.length,
        'content_preview': content.length > 100 ? content.substring(0, 100) : content,
        'hypothesisId': 'H8',
      });
      try {
        await docsService.documents.batchUpdate(
          docs.BatchUpdateDocumentRequest(requests: [
            docs.Request(insertText: docs.InsertTextRequest(
              text: content,
              location: docs.Location(index: 1),
            )),
          ]),
          documentId,
        );
        _debugLog('google_docs_tool.dart:createGoogleDocExecutor', 'batchUpdate success', {'hypothesisId': 'H8'});
      } catch (batchErr) {
        _debugLog('google_docs_tool.dart:createGoogleDocExecutor', 'batchUpdate exception', {
          'error': batchErr.toString(),
          'hypothesisId': 'H8',
        });
        rethrow;
      }
    }

    final docUrl = 'https://docs.google.com/document/d/$documentId/edit';
    final result = 'Created Google Doc "$title". Call open_url with $docUrl so the user can view it.';
    _debugLog('google_docs_tool.dart:createGoogleDocExecutor', 'success', {'result_preview': result.substring(0, result.length > 80 ? 80 : result.length)});
    return result;
  } catch (e) {
    _debugLog('google_docs_tool.dart:createGoogleDocExecutor', 'exception', {'error': e.toString(), 'hypothesisId': 'H6'});
    return 'Error: $e';
  }
}

const List<String> _googleScopes = [
  'https://www.googleapis.com/auth/documents',
  'https://www.googleapis.com/auth/gmail.send',
  'https://www.googleapis.com/auth/gmail.readonly',
  'https://www.googleapis.com/auth/calendar.readonly',
  'https://www.googleapis.com/auth/calendar.events',
];

GoogleSignIn? _googleSignIn;
docs.DocsApi? _cachedDocsApi;

void _ensureGoogleSignIn() {
  if (_googleSignIn == null) {
    _googleSignIn = GoogleSignIn(
      scopes: _googleScopes,
      clientId: Secrets.googleClientId,
      serverClientId: Secrets.googleClientId,
    );
  }
}

Future<docs.DocsApi?> _getDocsService() async {
  _ensureGoogleSignIn();
  var account = await _googleSignIn!.signInSilently();
  _debugLog('google_docs_tool.dart:_getDocsService', 'signInSilently result', {
    'account_null': account == null,
    'account_email': account?.email ?? 'N/A',
    'hypothesisId': 'H1',
  });
  if (account == null) return null;
  final client = await _googleSignIn!.authenticatedClient();
  _debugLog('google_docs_tool.dart:_getDocsService', 'authenticatedClient result', {
    'client_null': client == null,
    'hypothesisId': 'H2',
  });
  if (client == null) return null;
  _cachedDocsApi ??= docs.DocsApi(client);
  return _cachedDocsApi;
}

/// Returns the authenticated HTTP client when signed in, for Gmail API etc.
Future<dynamic> getAuthenticatedClient() async {
  _ensureGoogleSignIn();
  final account = await _googleSignIn!.signInSilently();
  if (account == null) return null;
  return _googleSignIn!.authenticatedClient();
}

/// Whether the user is signed in with Google.
Future<bool> isSignedInWithGoogle() async {
  _ensureGoogleSignIn();
  final account = await _googleSignIn!.signInSilently();
  _debugLog('google_docs_tool.dart:isSignedInWithGoogle', 'result', {
    'account_null': account == null,
    'account_email': account?.email ?? 'N/A',
    'hypothesisId': 'H5',
  });
  return account != null;
}

/// Returns the signed-in user's email, or null if not signed in.
Future<String?> getSignedInEmail() async {
  _ensureGoogleSignIn();
  final account = await _googleSignIn!.signInSilently();
  return account?.email;
}

/// Sign in with Google. Call from Settings. Returns true if successful.
Future<bool> signInWithGoogle() async {
  _ensureGoogleSignIn();
  final account = await _googleSignIn!.signIn();
  _debugLog('google_docs_tool.dart:signInWithGoogle', 'signIn result', {
    'account_null': account == null,
    'account_email': account?.email ?? 'N/A',
    'hypothesisId': 'H3',
  });
  if (account != null) {
    _cachedDocsApi = null; // Force refresh on next use
    return true;
  }
  return false;
}

/// Sign out from Google.
Future<void> signOutFromGoogle() async {
  if (_googleSignIn != null) {
    await _googleSignIn!.signOut();
    _cachedDocsApi = null;
  }
}

void registerCreateGoogleDocTool(ToolRegistry registry) {
  registry.register('create_google_doc', createGoogleDocSchema, createGoogleDocExecutor);
}
