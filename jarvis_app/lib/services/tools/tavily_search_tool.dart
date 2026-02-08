import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/secrets.dart';
import 'tool_registry.dart';

const tavilySearchSchema = {
  'type': 'function',
  'function': {
    'name': 'tavily_search',
    'description': 'Search the web for research, trends, factual information. Use for essays, party ideas, general knowledge. NOT for product shopping (use shopping_search instead).',
    'parameters': {
      'type': 'object',
      'properties': {
        'query': {'type': 'string', 'description': 'Search query'},
      },
      'required': ['query'],
    },
  },
};

Future<String> tavilySearchExecutor(Map<String, dynamic> args) async {
  final apiKey = Secrets.tavilyApiKey;
  if (apiKey.isEmpty) return 'Error: TAVILY_API_KEY not configured. Add it to .env';

  final query = args['query']?.toString() ?? '';
  if (query.isEmpty) return 'Error: query is required';

  try {
    final response = await http.post(
      Uri.parse('https://api.tavily.com/search'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'query': query,
        'max_results': 10,
        'include_answer': true,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      return 'Error: Tavily API returned ${response.statusCode}';
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final answer = data['answer'] as String? ?? '';
    final results = data['results'] as List? ?? [];

    final sb = StringBuffer();
    if (answer.isNotEmpty) sb.writeln('Summary: $answer\n');
    for (var i = 0; i < results.length && i < 8; i++) {
      final r = results[i] as Map<String, dynamic>;
      final title = r['title'] ?? '';
      final url = r['url'] ?? '';
      final content = (r['content'] ?? '').toString();
      sb.writeln('${i + 1}. $title ($url)');
      if (content.isNotEmpty && content.length < 300) sb.writeln('   $content');
    }
    return sb.toString().trim();
  } catch (e) {
    return 'Error: $e';
  }
}

void registerTavilySearchTool(ToolRegistry registry) {
  registry.register('tavily_search', tavilySearchSchema, tavilySearchExecutor);
}
