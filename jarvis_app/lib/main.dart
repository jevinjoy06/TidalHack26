import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'providers/chat_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/tasks_provider.dart';
import 'services/tools/tool_setup.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env file not found - that's okay, user can configure in app settings
    // or use environment variables
    debugPrint('Warning: .env file not found. Using defaults or app settings.');
  }

  registerAllTools();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
    ),
  );
  
  runApp(const JarvisApp());
}

void _setupProviders(ChatProvider chatProvider, SettingsProvider settingsProvider) {
  // Connect settings to chat provider for API key, model, and base URL updates
  settingsProvider.setApiKeyCallback((apiKey) {
    chatProvider.updateApiKey(apiKey);
  });
  settingsProvider.setModelCallback((model) {
    chatProvider.updateModel(model);
  });
  settingsProvider.setBaseUrlCallback((baseUrl) {
    chatProvider.updateBaseUrl(baseUrl);
  });
  settingsProvider.setAdkSettingsCallback((useAdk, url) {
    chatProvider.setAdkSettings(useAdk, url);
  });
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = ChatProvider();
    final settingsProvider = SettingsProvider();
    final tasksProvider = TasksProvider();
    _setupProviders(chatProvider, settingsProvider);
    // Initialize settings AFTER callbacks are registered
    settingsProvider.initialize();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: chatProvider),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: tasksProvider),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          final isDark = settings.isDarkMode;
          return CupertinoApp(
            title: 'JARVIS',
            debugShowCheckedModeBanner: false,
            theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
            home: Container(
              decoration: BoxDecoration(
                gradient: isDark ? AppTheme.darkGradient : null,
                color: isDark ? null : AppTheme.bgLightSecondary,
              ),
              child: const HomeScreen(),
            ),
          );
        },
      ),
    );
  }
}


