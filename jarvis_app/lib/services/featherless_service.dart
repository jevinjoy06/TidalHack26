import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/secrets.dart';
import '../models/message.dart';
import '../models/connection_status.dart';

class FeatherlessService {
  final http.Client _client;
  final String _apiKey;
  final String _baseUrl;
  final String _model;
  List<Map<String, dynamic>> _conversationHistory = [];

  FeatherlessService({
    String? apiKey,
    String? baseUrl,
    String? model,
  })  : _client = http.Client(),
        _apiKey = apiKey ?? Secrets.apiKey,
        _baseUrl = baseUrl ?? Secrets.baseUrl,
        _model = model ?? Secrets.model;

  /// Send a chat message to Featherless.ai
  Future<Message> sendMessage(String content, {bool stream = false}) async {
    if (_apiKey.isEmpty) {
      throw Exception('Featherless.ai API key not configured. Please set FEATHERLESS_API_KEY environment variable.');
    }

    // Add user message to conversation history
    _conversationHistory.add({
      'role': 'user',
      'content': content,
    });

    try {
      // Base URL already includes /v1, so we just append the endpoint
      final endpoint = _baseUrl.endsWith('/v1') 
          ? '$_baseUrl/chat/completions' 
          : '$_baseUrl/v1/chat/completions';
      final response = await _client.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': _conversationHistory,
          'stream': stream,
          'temperature': 0.7,
          'max_tokens': 2000,
        }),
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assistantMessage = data['choices'][0]['message']['content'] ?? '';
        
        // Add assistant response to conversation history
        _conversationHistory.add({
          'role': 'assistant',
          'content': assistantMessage,
        });

        return Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: assistantMessage,
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
          status: MessageStatus.sent,
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Featherless.ai API error: ${errorData['error']?['message'] ?? response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      throw Exception('Failed to connect to Featherless.ai: $e');
    }
  }

  /// Verify connection to Featherless.ai API
  /// Returns connection status and error message if failed
  Future<Map<String, dynamic>> verifyConnection() async {
    if (_apiKey.isEmpty) {
      return {
        'status': ConnectionStatus.disconnected,
        'error': 'API key is not configured',
      };
    }

    try {
      // Use /models endpoint for lightweight connection test
      final endpoint = _baseUrl.endsWith('/v1') 
          ? '$_baseUrl/models' 
          : '$_baseUrl/v1/models';
      
      final response = await _client.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return {
          'status': ConnectionStatus.connected,
          'error': null,
        };
      } else if (response.statusCode == 401) {
        return {
          'status': ConnectionStatus.invalidKey,
          'error': 'Invalid or expired API key',
        };
      } else if (response.statusCode == 403) {
        return {
          'status': ConnectionStatus.forbidden,
          'error': 'Access forbidden. Check your subscription status.',
        };
      } else {
        return {
          'status': ConnectionStatus.networkError,
          'error': 'API returned status code: ${response.statusCode}',
        };
      }
    } on TimeoutException {
      return {
        'status': ConnectionStatus.networkError,
        'error': 'Connection timeout. Check your internet connection.',
      };
    } on http.ClientException catch (e) {
      return {
        'status': ConnectionStatus.networkError,
        'error': 'Network error: ${e.message}',
      };
    } catch (e) {
      return {
        'status': ConnectionStatus.networkError,
        'error': 'Failed to connect: $e',
      };
    }
  }

  /// Generate an image using vision capabilities (if supported)
  Future<String?> generateImage(String prompt) async {
    // Note: Featherless.ai may not support image generation directly
    // This would need to be implemented based on their actual API capabilities
    // For now, we'll return null and handle it in the UI
    throw UnimplementedError('Image generation not yet implemented for Featherless.ai');
  }

  /// Get list of available models from Featherless.ai
  Future<List<String>> getAvailableModels() async {
    if (_apiKey.isEmpty) {
      return [];
    }

    try {
      // Base URL already includes /v1, so we just append the endpoint
      final endpoint = _baseUrl.endsWith('/v1') 
          ? '$_baseUrl/models' 
          : '$_baseUrl/v1/models';
      final response = await _client.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['data'] as List?;
        if (models != null) {
          return models.map((m) => m['id'] as String).toList();
        }
      }
    } catch (e) {
      // If we can't fetch models, return common defaults
    }
    
    // Return common Featherless.ai models as fallback
    return [
      'Qwen/Qwen2.5-14B-Instruct',
      'Qwen/Qwen2.5-7B-Instruct',
      'meta-llama/Llama-3.1-8B-Instruct',
      'meta-llama/Llama-3.1-70B-Instruct',
      'mistralai/Mistral-7B-Instruct-v0.3',
      'deepseek-ai/DeepSeek-V2-Chat-0628',
      'deepseek-ai/deepseek-coder-33b-instruct',
    ];
  }

  /// Clear conversation history
  void clearHistory() {
    _conversationHistory.clear();
  }

  /// Get conversation history
  List<Map<String, dynamic>> getHistory() {
    return List.unmodifiable(_conversationHistory);
  }

  void dispose() {
    _client.close();
  }
}
