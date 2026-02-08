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

Future<String> createGoogleDocExecutor(Map<String, dynamic> args) async {
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

  try {
    final docsService = await _getDocsService();
    if (docsService == null) {
      return 'Error: Please sign in with Google first (Settings > Sign in with Google).';
    }

    final createResponse = await docsService.documents.create(docs.Document(
      title: title,
    ));
    final documentId = createResponse.documentId;
    if (documentId == null) return 'Error: Failed to create document';

    if (content.isNotEmpty) {
      await docsService.documents.batchUpdate(
        docs.BatchUpdateDocumentRequest(requests: [
          docs.Request(insertText: docs.InsertTextRequest(
            text: content,
            location: docs.Location(index: 1),
          )),
        ]),
        documentId,
      );
    }

    final docUrl = 'https://docs.google.com/document/d/$documentId/edit';
    return 'Created Google Doc "$title". Call open_url with $docUrl so the user can view it.';
  } catch (e) {
    return 'Error: $e';
  }
}

GoogleSignIn? _googleSignIn;
docs.DocsApi? _cachedDocsApi;

Future<docs.DocsApi?> _getDocsService() async {
  if (_googleSignIn == null) {
    _googleSignIn = GoogleSignIn(
      scopes: ['https://www.googleapis.com/auth/documents'],
      clientId: Secrets.googleClientId,
      serverClientId: Secrets.googleClientId,
    );
  }
  var account = await _googleSignIn!.signInSilently();
  if (account == null) return null;
  final client = await _googleSignIn!.authenticatedClient();
  if (client == null) return null;
  _cachedDocsApi ??= docs.DocsApi(client);
  return _cachedDocsApi;
}

/// Call this from Settings to sign in. Returns true if successful.
Future<bool> signInWithGoogle() async {
  if (_googleSignIn == null) {
    _googleSignIn = GoogleSignIn(
      scopes: ['https://www.googleapis.com/auth/documents'],
      clientId: Secrets.googleClientId,
      serverClientId: Secrets.googleClientId,
    );
  }
  final account = await _googleSignIn!.signIn();
  return account != null;
}

void registerCreateGoogleDocTool(ToolRegistry registry) {
  registry.register('create_google_doc', createGoogleDocSchema, createGoogleDocExecutor);
}
