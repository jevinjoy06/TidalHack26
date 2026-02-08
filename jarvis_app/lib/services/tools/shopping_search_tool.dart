import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/secrets.dart';
import 'tool_registry.dart';

const shoppingSearchSchema = {
  'type': 'function',
  'function': {
    'name': 'shopping_search',
    'description': 'Search for products on Google Shopping. Returns titles, prices, ratings, reviews, and links. After getting results, pick the best option (best value, good ratings) and call open_url with that product link so the user can add to cart.',
    'parameters': {
      'type': 'object',
      'properties': {
        'query': {'type': 'string', 'description': 'Search query, e.g. "white tablecloth 6ft"'},
      },
      'required': ['query'],
    },
  },
};

Future<String> shoppingSearchExecutor(Map<String, dynamic> args) async {
  final apiKey = Secrets.serpApiKey;
  if (apiKey.isEmpty) return 'Error: SERPAPI_KEY not configured. Add it to .env';

  final query = args['query']?.toString() ?? '';
  if (query.isEmpty) return 'Error: query is required';

  try {
    final uri = Uri.parse(
      'https://serpapi.com/search.json?engine=google_shopping&q=${Uri.encodeComponent(query)}&api_key=$apiKey',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      return 'Error: SerpAPI returned ${response.statusCode}';
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['shopping_results'] as List? ?? [];
    if (results.isEmpty) return 'No products found for "$query"';

    final sb = StringBuffer();
    for (var i = 0; i < results.length && i < 10; i++) {
      final r = results[i] as Map<String, dynamic>;
      final title = r['title'] ?? '';
      final price = r['price'] ?? r['extracted_price']?.toString() ?? 'N/A';
      final link = r['product_link'] ?? r['link'] ?? '';
      final source = r['source'] ?? '';
      final rating = r['rating'];
      final reviews = r['reviews'] ?? r['reviews_count'];
      final ratingStr = (rating != null || reviews != null)
          ? ' | ${rating ?? '?'} stars, ${reviews ?? '?'} reviews'
          : '';
      sb.writeln('${i + 1}. $title – $price (from $source)$ratingStr – $link');
    }
    return sb.toString().trim();
  } catch (e) {
    return 'Error: $e';
  }
}

void registerShoppingSearchTool(ToolRegistry registry) {
  registry.register('shopping_search', shoppingSearchSchema, shoppingSearchExecutor);
}
