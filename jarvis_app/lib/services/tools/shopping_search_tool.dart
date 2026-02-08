import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../config/secrets.dart';
import 'tool_registry.dart';

// #region agent log
void _log(String loc, String msg, Map<String, dynamic> data) {
  try {
    final p = {
      'location': loc,
      'message': msg,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'hypothesisId': 'H1',
    };
    File('/Users/allenthomas/TidalHack26/.cursor/debug.log')
        .writeAsStringSync('${jsonEncode(p)}\n', mode: FileMode.append);
  } catch (_) {}
}
// #endregion

const shoppingSearchSchema = {
  'type': 'function',
  'function': {
    'name': 'shopping_search',
    'description': 'Search for products on Google Shopping. Returns titles, prices, ratings, reviews, and links. The top result link is opened automatically in the browser.',
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
  // #region agent log
  _log('shopping_search_tool.dart:entry', 'Flutter shopping_search executor called', {'query': args['query']?.toString() ?? ''});
  // #endregion
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
    final result = sb.toString().trim();

    // Auto-open the top result so the user can add to cart immediately
    final firstR = results[0] as Map<String, dynamic>;
    final firstLink = (firstR['product_link'] ?? firstR['link'] ?? '') as String;
    // #region agent log
    _log('shopping_search_tool.dart:first_link', 'extracted first_link', {'first_link': firstLink.length > 80 ? '${firstLink.substring(0, 80)}...' : firstLink});
    // #endregion
    if (firstLink.isNotEmpty) {
      try {
        final uri = Uri.parse(firstLink);
        final canLaunch = await canLaunchUrl(uri);
        // #region agent log
        _log('shopping_search_tool.dart:canLaunch', 'canLaunchUrl', {'canLaunch': canLaunch});
        // #endregion
        if (canLaunch) {
          unawaited(launchUrl(uri));
        }
      } catch (e) {
        // #region agent log
        _log('shopping_search_tool.dart:launch_err', 'launch error', {'error': e.toString()});
        // #endregion
        // Ignore; still return results
      }
    }
    return result;
  } catch (e) {
    return 'Error: $e';
  }
}

void registerShoppingSearchTool(ToolRegistry registry) {
  registry.register('shopping_search', shoppingSearchSchema, shoppingSearchExecutor);
}
