import 'package:flutter_dotenv/flutter_dotenv.dart';

class Secrets {
  // Featherless.ai API configuration
  // Try .env first, then environment variables, then default
  static String get featherlessApiKey {
    // Try .env file first
    final envKey = dotenv.env['FEATHERLESS_API_KEY_1'] ?? 
                   dotenv.env['FEATHERLESS_API_KEY'] ?? '';
    if (envKey.isNotEmpty) return envKey;
    
    // Fallback to environment variable
    const envVarKey = String.fromEnvironment('FEATHERLESS_API_KEY', defaultValue: '');
    return envVarKey;
  }
  
  static String get featherlessBaseUrl {
    // Try .env file first
    final envUrl = dotenv.env['FEATHERLESS_BASE_URL'] ?? '';
    if (envUrl.isNotEmpty) return envUrl;
    
    // Fallback to environment variable
    const envVarUrl = String.fromEnvironment(
      'FEATHERLESS_BASE_URL',
      defaultValue: 'https://api.featherless.ai/v1',
    );
    return envVarUrl;
  }
  
  // Model selection (Qwen, Llama, Mistral, DeepSeek, etc.)
  static String get defaultModel {
    // Try .env file first
    final envModel = dotenv.env['FEATHERLESS_DEFAULT_MODEL'] ?? 
                     dotenv.env['FEATHERLESS_MODEL'] ?? '';
    if (envModel.isNotEmpty) return envModel;
    
    // Fallback to environment variable
    const envVarModel = String.fromEnvironment(
      'FEATHERLESS_MODEL',
      defaultValue: 'Qwen/Qwen2.5-14B-Instruct',
    );
    return envVarModel;
  }
  
  // Get all numbered API keys from .env file
  static Map<String, String> getAvailableApiKeys() {
    final keys = <String, String>{};
    
    // Check for numbered keys (FEATHERLESS_API_KEY_1, FEATHERLESS_API_KEY_2, etc.)
    int index = 1;
    while (true) {
      final keyName = 'FEATHERLESS_API_KEY_$index';
      final keyValue = dotenv.env[keyName];
      
      if (keyValue == null || keyValue.isEmpty) {
        break;
      }
      
      keys['API Key $index'] = keyValue;
      index++;
    }
    
    // Also check for single FEATHERLESS_API_KEY (for backward compatibility)
    final singleKey = dotenv.env['FEATHERLESS_API_KEY'];
    if (singleKey != null && singleKey.isNotEmpty && keys.isEmpty) {
      keys['API Key'] = singleKey;
    }
    
    return keys;
  }
  
  // Get list of API key names (for dropdown)
  static List<String> getApiKeyNames() {
    return getAvailableApiKeys().keys.toList();
  }
  
  // Get API key by name
  static String? getApiKeyByName(String name) {
    return getAvailableApiKeys()[name];
  }
  
  // Get API key from environment or return empty (user must set it)
  static String get apiKey => featherlessApiKey;
  
  static String get baseUrl => featherlessBaseUrl;
  
  static String get model => defaultModel;

  static String get serpApiKey => dotenv.env['SERPAPI_KEY'] ?? '';
  static String get tavilyApiKey => dotenv.env['TAVILY_API_KEY'] ?? '';
  static String get googleClientId => dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
  static String get googleClientSecret => dotenv.env['GOOGLE_CLIENT_SECRET'] ?? '';
}
