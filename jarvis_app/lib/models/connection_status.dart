import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  invalidKey,
  networkError,
  forbidden,
}

extension ConnectionStatusExtension on ConnectionStatus {
  String get displayName {
    switch (this) {
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.invalidKey:
        return 'Invalid API Key';
      case ConnectionStatus.networkError:
        return 'Network Error';
      case ConnectionStatus.forbidden:
        return 'Access Forbidden';
    }
  }

  String get errorMessage {
    switch (this) {
      case ConnectionStatus.disconnected:
        return 'No API key configured';
      case ConnectionStatus.connecting:
        return 'Testing connection...';
      case ConnectionStatus.connected:
        return 'Featherless.ai API is ready';
      case ConnectionStatus.invalidKey:
        return 'API key is invalid or expired. Please check your key.';
      case ConnectionStatus.networkError:
        return 'Cannot reach Featherless.ai. Check your internet connection.';
      case ConnectionStatus.forbidden:
        return 'Access forbidden. Please check your subscription status.';
    }
  }

  Color get statusColor {
    switch (this) {
      case ConnectionStatus.connected:
        return AppTheme.success;
      case ConnectionStatus.invalidKey:
      case ConnectionStatus.networkError:
      case ConnectionStatus.forbidden:
        return AppTheme.error;
      case ConnectionStatus.connecting:
        return AppTheme.warning;
      case ConnectionStatus.disconnected:
        return AppTheme.textTertiary;
    }
  }

  IconData get statusIcon {
    switch (this) {
      case ConnectionStatus.connected:
        return CupertinoIcons.checkmark_circle_fill;
      case ConnectionStatus.invalidKey:
      case ConnectionStatus.networkError:
      case ConnectionStatus.forbidden:
        return CupertinoIcons.xmark_circle;
      case ConnectionStatus.connecting:
        return CupertinoIcons.arrow_clockwise;
      case ConnectionStatus.disconnected:
        return CupertinoIcons.circle;
    }
  }

  bool get isConnected => this == ConnectionStatus.connected;
  bool get isError => this == ConnectionStatus.invalidKey || 
                      this == ConnectionStatus.networkError || 
                      this == ConnectionStatus.forbidden;
}
