import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/secrets.dart';
import '../models/connection_status.dart';
import '../services/featherless_service.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _apiKey = '';
  String _selectedApiKeyName = '';
  Map<String, String> _apiKeyMap = {};
  String _featherlessBaseUrl = 'https://api.featherless.ai/v1'; // Must include /v1
  String _model = 'Qwen/Qwen2.5-14B-Instruct'; // Updated to match Featherless.ai format
  bool _voiceEnabled = true;
  bool _soundEnabled = true;
  bool _useAdkBackend = true;
  String _adkBackendUrl = 'http://localhost:8000';
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  String? _connectionError;
  Function(String)? _onApiKeyChanged;
  Function(String)? _onModelChanged;
  Function(String)? _onBaseUrlChanged;
  void Function(bool useAdk, String url)? _onAdkSettingsChanged;

  bool get isDarkMode => _isDarkMode;
  bool get useAdkBackend => _useAdkBackend;
  String get adkBackendUrl => _adkBackendUrl;
  String get apiKey => _apiKey;
  String get selectedApiKeyName => _selectedApiKeyName;
  Map<String, String> get apiKeyMap => Map.unmodifiable(_apiKeyMap);
  List<String> get availableApiKeyNames => _apiKeyMap.keys.toList();
  String get featherlessBaseUrl => _featherlessBaseUrl;
  String get model => _model;
  bool get voiceEnabled => _voiceEnabled;
  bool get soundEnabled => _soundEnabled;
  ConnectionStatus get connectionStatus => _connectionStatus;
  String? get connectionError => _connectionError;
  
  void setApiKeyCallback(Function(String) callback) {
    _onApiKeyChanged = callback;
  }

  void setModelCallback(Function(String) callback) {
    _onModelChanged = callback;
  }

  void setBaseUrlCallback(Function(String) callback) {
    _onBaseUrlChanged = callback;
  }

  void setAdkSettingsCallback(void Function(bool useAdk, String url) callback) {
    _onAdkSettingsChanged = callback;
  }

  SettingsProvider();

  /// Must be called after callbacks are registered to avoid race conditions.
  Future<void> initialize() async {
    await _loadSettings();
    if (_apiKey.isNotEmpty) {
      testConnection();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('darkMode') ?? false;
    
    // Load API keys from .env file
    _apiKeyMap = Secrets.getAvailableApiKeys();
    
    // Load selected API key name from preferences
    _selectedApiKeyName = prefs.getString('selectedApiKeyName') ?? '';
    
    // If we have keys from .env, use the selected one or first one
    if (_apiKeyMap.isNotEmpty) {
      if (_selectedApiKeyName.isNotEmpty && _apiKeyMap.containsKey(_selectedApiKeyName)) {
        _apiKey = _apiKeyMap[_selectedApiKeyName]!;
      } else {
        // Use first available key
        _selectedApiKeyName = _apiKeyMap.keys.first;
        _apiKey = _apiKeyMap[_selectedApiKeyName]!;
      }
    } else {
      // Fallback to SharedPreferences (for backward compatibility)
      _apiKey = prefs.getString('apiKey') ?? '';
    }
    
    _featherlessBaseUrl = prefs.getString('featherlessBaseUrl') ?? Secrets.baseUrl;
    _model = prefs.getString('model') ?? Secrets.model;
    _voiceEnabled = prefs.getBool('voiceEnabled') ?? true;
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    _useAdkBackend = prefs.getBool('useAdkBackend') ?? true;
    _adkBackendUrl = prefs.getString('adkBackendUrl') ?? 'http://localhost:8000';
    
    // Initialize connection status
    _connectionStatus = _apiKey.isEmpty
        ? ConnectionStatus.disconnected
        : ConnectionStatus.disconnected;

    // Propagate loaded settings to ChatProvider via callbacks
    if (_apiKey.isNotEmpty && _onApiKeyChanged != null) {
      _onApiKeyChanged!(_apiKey);
    }
    if (_onModelChanged != null) {
      _onModelChanged!(_model);
    }
    if (_onBaseUrlChanged != null) {
      _onBaseUrlChanged!(_featherlessBaseUrl);
    }
    if (_onAdkSettingsChanged != null) {
      _onAdkSettingsChanged!(_useAdkBackend, _adkBackendUrl);
    }

    notifyListeners();
  }

  Future<void> setUseAdkBackend(bool value) async {
    _useAdkBackend = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useAdkBackend', value);
    _onAdkSettingsChanged?.call(_useAdkBackend, _adkBackendUrl);
    notifyListeners();
  }

  Future<void> setAdkBackendUrl(String value) async {
    _adkBackendUrl = value.trim().isEmpty ? 'http://localhost:8000' : value.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('adkBackendUrl', _adkBackendUrl);
    _onAdkSettingsChanged?.call(_useAdkBackend, _adkBackendUrl);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    notifyListeners();
  }

  Future<void> setApiKey(String value) async {
    _apiKey = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apiKey', value);
    if (_onApiKeyChanged != null) {
      _onApiKeyChanged!(value);
    }
    notifyListeners();
  }

  /// Set selected API key by name (from dropdown)
  Future<void> setSelectedApiKey(String keyName) async {
    if (_apiKeyMap.containsKey(keyName)) {
      _selectedApiKeyName = keyName;
      _apiKey = _apiKeyMap[keyName]!;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedApiKeyName', keyName);
      await prefs.setString('apiKey', _apiKey);
      
      if (_onApiKeyChanged != null) {
        _onApiKeyChanged!(_apiKey);
      }
      
      // Trigger connection test
      await testConnection();
      
      notifyListeners();
    }
  }

  /// Add a new API key manually (saves to SharedPreferences as fallback)
  Future<void> addApiKey(String keyName, String keyValue) async {
    _apiKeyMap[keyName] = keyValue;
    final prefs = await SharedPreferences.getInstance();
    
    // Save to SharedPreferences as fallback
    await prefs.setString('apiKey', keyValue);
    await prefs.setString('selectedApiKeyName', keyName);
    
    _selectedApiKeyName = keyName;
    _apiKey = keyValue;
    
    if (_onApiKeyChanged != null) {
      _onApiKeyChanged!(_apiKey);
    }
    
    // Trigger connection test
    await testConnection();
    
    notifyListeners();
  }

  /// Test connection to Featherless.ai API
  Future<void> testConnection() async {
    if (_apiKey.isEmpty) {
      _connectionStatus = ConnectionStatus.disconnected;
      _connectionError = 'No API key configured';
      notifyListeners();
      return;
    }

    _connectionStatus = ConnectionStatus.connecting;
    _connectionError = null;
    notifyListeners();

    try {
      // Import FeatherlessService to test connection
      final service = FeatherlessService(
        apiKey: _apiKey,
        baseUrl: _featherlessBaseUrl,
        model: _model,
      );
      
      final result = await service.verifyConnection();
      _connectionStatus = result['status'] as ConnectionStatus;
      _connectionError = result['error'] as String?;
    } catch (e) {
      _connectionStatus = ConnectionStatus.networkError;
      _connectionError = 'Failed to test connection: $e';
    } finally {
      notifyListeners();
    }
  }

  /// Refresh API keys from .env file
  void refreshApiKeys() {
    _apiKeyMap = Secrets.getAvailableApiKeys();
    
    // If current selected key still exists, keep it
    // Otherwise, use first available or clear selection
    if (_selectedApiKeyName.isNotEmpty && _apiKeyMap.containsKey(_selectedApiKeyName)) {
      _apiKey = _apiKeyMap[_selectedApiKeyName]!;
    } else if (_apiKeyMap.isNotEmpty) {
      _selectedApiKeyName = _apiKeyMap.keys.first;
      _apiKey = _apiKeyMap[_selectedApiKeyName]!;
    } else {
      _selectedApiKeyName = '';
      _apiKey = '';
    }
    
    notifyListeners();
  }

  Future<void> setFeatherlessBaseUrl(String value) async {
    _featherlessBaseUrl = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('featherlessBaseUrl', value);
    if (_onBaseUrlChanged != null) {
      _onBaseUrlChanged!(value);
    }
    notifyListeners();
  }

  Future<void> setModel(String value) async {
    _model = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('model', value);
    if (_onModelChanged != null) {
      _onModelChanged!(value);
    }
    notifyListeners();
  }

  Future<void> setVoiceEnabled(bool value) async {
    _voiceEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voiceEnabled', value);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', value);
    notifyListeners();
  }
}


