import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/settings_provider.dart';
import '../providers/chat_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/connection_status_widget.dart';
import '../models/connection_status.dart';
import '../services/featherless_service.dart';
import '../services/agent_orchestrator.dart';
import '../services/tools/tool_registry.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLightSecondary,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? AppTheme.bgDarkSecondary : AppTheme.bgLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
            width: 1,
          ),
        ),
        middle: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.textPrimary : AppTheme.textDark,
          ),
        ),
      ),
      child: SafeArea(
        child: Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return ListView(
              children: [
                // Connection Status
                _buildSection(
                  'Connection',
                  [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ConnectionStatusWidget(
                        status: settings.connectionStatus,
                        errorMessage: settings.connectionError,
                        lastChecked: DateTime.now(),
                        onRefresh: () => settings.testConnection(),
                      ),
                    ),
                  ],
                  isDark,
                )
                    .animate(delay: 0.ms)
                    .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                    .slideY(begin: 0.04, end: 0, duration: 350.ms, curve: const Cubic(0.4, 0, 0.2, 1)),

                // API Configuration
                _buildSection(
                  'Featherless.ai API',
                  [
                    _buildApiKeyDropdown(context, settings, isDark),
                    _buildNavigationTile(
                      'Base URL',
                      settings.featherlessBaseUrl,
                      CupertinoIcons.link,
                      () => _showBaseUrlDialog(context, settings),
                      isDark,
                    ),
                    _buildNavigationTile(
                      'Model',
                      settings.model,
                      CupertinoIcons.cube,
                      () => _showModelDialog(context, settings),
                      isDark,
                      showDivider: false,
                    ),
                  ],
                  isDark,
                )
                    .animate(delay: 80.ms)
                    .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                    .slideY(begin: 0.04, end: 0, duration: 350.ms, curve: const Cubic(0.4, 0, 0.2, 1)),

                // Debug: Test Tool Calling & Orchestrator (only in debug mode)
                if (kDebugMode)
                  _buildSection(
                    'Debug',
                    [
                      _buildDebugTestToolCallTile(context, settings, isDark),
                      _buildDebugTestOrchestratorTile(context, settings, isDark),
                      _buildDebugTestToolRegistryTile(context, settings, isDark),
                    ],
                    isDark,
                  ),

                // Appearance
                _buildSection(
                  'Appearance',
                  [
                    _buildSwitchTile(
                      'Dark Mode',
                      CupertinoIcons.moon_fill,
                      settings.isDarkMode,
                      (value) => settings.setDarkMode(value),
                      isDark,
                    ),
                  ],
                  isDark,
                )
                    .animate(delay: 160.ms)
                    .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                    .slideY(begin: 0.04, end: 0, duration: 350.ms, curve: const Cubic(0.4, 0, 0.2, 1)),

                // Voice
                _buildSection(
                  'Voice',
                  [
                    _buildSwitchTile(
                      'Voice Input',
                      CupertinoIcons.mic,
                      settings.voiceEnabled,
                      (value) => settings.setVoiceEnabled(value),
                      isDark,
                    ),
                    _buildSwitchTile(
                      'Sound Effects',
                      CupertinoIcons.speaker_2,
                      settings.soundEnabled,
                      (value) => settings.setSoundEnabled(value),
                      isDark,
                      showDivider: false,
                    ),
                  ],
                  isDark,
                )
                    .animate(delay: 240.ms)
                    .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                    .slideY(begin: 0.04, end: 0, duration: 350.ms, curve: const Cubic(0.4, 0, 0.2, 1)),

                // About
                _buildSection(
                  'About',
                  [
                    _buildInfoTile('Version', '1.0.0', isDark),
                    _buildInfoTile('Made with', 'Flutter & Featherless.ai', isDark,
                        showDivider: false),
                  ],
                  isDark,
                )
                    .animate(delay: 320.ms)
                    .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                    .slideY(begin: 0.04, end: 0, duration: 350.ms, curve: const Cubic(0.4, 0, 0.2, 1)),

                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDebugTestToolCallTile(
      BuildContext context, SettingsProvider settings, bool isDark) {
    return CupertinoButton(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.centerLeft,
      onPressed: () => _runToolCallingTest(context, settings, isDark),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.wrench,
            color: isDark ? AppTheme.textSecondary : AppTheme.textDarkSecondary,
          ),
          const SizedBox(width: 12),
          Text(
            'Test Tool Calling (Step 1)',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppTheme.textPrimary : AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runToolCallingTest(
      BuildContext context, SettingsProvider settings, bool isDark) async {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Testing...'),
        content: const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('Calling Featherless with a test tool...'),
        ),
      ),
    );

    try {
      final service = FeatherlessService(
        apiKey: settings.apiKey,
        baseUrl: settings.featherlessBaseUrl,
        model: settings.model,
      );
      final tools = [
        {
          'type': 'function',
          'function': {
            'name': 'get_weather',
            'description': 'Get the current weather for a location',
            'parameters': {
              'type': 'object',
              'properties': {
                'location': {'type': 'string', 'description': 'City name'},
              },
            },
          },
        },
      ];
      final messages = [
        {'role': 'user', 'content': 'What is the weather in Boston?'},
      ];
      final result =
          await service.sendMessageWithTools(messages, tools);
      service.dispose();

      if (!context.mounted) return;
      Navigator.pop(context); // Dismiss loading

      final msg = result.hasToolCalls
          ? 'Tool calls: ${result.toolCalls!.map((t) => t.name).join(", ")}\n'
              'Args: ${result.toolCalls!.first.arguments}'
          : 'Content: ${result.content ?? "(empty)"}';
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Step 1 OK'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(msg),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Dismiss loading
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Test Failed'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(e.toString()),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDebugTestOrchestratorTile(
      BuildContext context, SettingsProvider settings, bool isDark) {
    return CupertinoButton(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.centerLeft,
      onPressed: () => _runOrchestratorTest(context, settings, isDark),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.arrow_2_circlepath,
            color: isDark ? AppTheme.textSecondary : AppTheme.textDarkSecondary,
          ),
          const SizedBox(width: 12),
          Text(
            'Test Orchestrator (Step 2)',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppTheme.textPrimary : AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runOrchestratorTest(
      BuildContext context, SettingsProvider settings, bool isDark) async {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Testing...'),
        content: const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('Running agent loop (LLM → tool → LLM)...'),
        ),
      ),
    );

    try {
      final service = FeatherlessService(
        apiKey: settings.apiKey,
        baseUrl: settings.featherlessBaseUrl,
        model: settings.model,
      );
      final tools = [
        {
          'type': 'function',
          'function': {
            'name': 'get_weather',
            'description': 'Get the current weather for a location',
            'parameters': {
              'type': 'object',
              'properties': {
                'location': {'type': 'string', 'description': 'City name'},
              },
            },
          },
        },
      ];
      final orchestrator = AgentOrchestrator(
        service: service,
        tools: tools,
        executeTool: (name, args) async {
          // Stub: return fake weather for any location
          return 'Sunny, 72°F (22°C). Light breeze.';
        },
      );
      final result = await orchestrator.run('What is the weather in Boston?');
      service.dispose();

      if (!context.mounted) return;
      Navigator.pop(context);

      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Step 2 OK'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text('Final answer:\n\n$result'),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Test Failed'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(e.toString()),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDebugTestToolRegistryTile(
      BuildContext context, SettingsProvider settings, bool isDark) {
    return CupertinoButton(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.centerLeft,
      onPressed: () => _runToolRegistryTest(context, settings, isDark),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.square_stack_3d_up,
            color: isDark ? AppTheme.textSecondary : AppTheme.textDarkSecondary,
          ),
          const SizedBox(width: 12),
          Text(
            'Test Tool Registry (Step 3)',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppTheme.textPrimary : AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runToolRegistryTest(
      BuildContext context, SettingsProvider settings, bool isDark) async {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Testing...'),
        content: const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('Running agent with ToolRegistry (open_url, send_email, etc.)...'),
        ),
      ),
    );

    try {
      final service = FeatherlessService(
        apiKey: settings.apiKey,
        baseUrl: settings.featherlessBaseUrl,
        model: settings.model,
      );
      final registry = ToolRegistry.global;
      final orchestrator = AgentOrchestrator(
        service: service,
        tools: registry.getToolsForLLM(),
        executeTool: (name, args) => registry.execute(name, args),
      );
      final result = await orchestrator.run(
        'Open https://google.com in my browser.',
      );
      service.dispose();

      if (!context.mounted) return;
      Navigator.pop(context);

      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Step 3 OK'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text('Result:\n\n$result'),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Test Failed'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(e.toString()),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSection(String title, List<Widget> children, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.textTertiary : AppTheme.textDarkSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: AppTheme.cardDecoration(isDark),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildApiKeyDropdown(BuildContext context, SettingsProvider settings, bool isDark) {
    final availableKeys = settings.availableApiKeyNames;
    final selectedKey = settings.selectedApiKeyName;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.lock,
                  color: CupertinoColors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API Key',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppTheme.textPrimary : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (availableKeys.isEmpty)
                      Text(
                        'No keys found in .env file',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppTheme.textTertiary : AppTheme.textDarkSecondary,
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.bgDarkTertiary : AppTheme.bgLightTertiary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                            width: 1,
                          ),
                        ),
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minSize: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  selectedKey.isEmpty 
                                      ? 'Select API Key' 
                                      : '$selectedKey (${_maskApiKey(settings.apiKey)})',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? AppTheme.textPrimary : AppTheme.textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                CupertinoIcons.chevron_down,
                                size: 16,
                                color: isDark ? AppTheme.textTertiary : AppTheme.textDarkSecondary,
                              ),
                            ],
                          ),
                          onPressed: () => _showApiKeyDropdown(context, settings, isDark),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (availableKeys.isEmpty) ...[
            const SizedBox(height: 12),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              child: Text(
                '+ Add API Key',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryMaroon,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () => _showAddApiKeyDialog(context, settings),
            ),
          ],
        ],
      ),
    );
  }

  String _maskApiKey(String key) {
    if (key.isEmpty) return '';
    if (key.length <= 8) return '••••';
    return '${key.substring(0, 4)}••••${key.substring(key.length - 4)}';
  }

  void _showApiKeyDropdown(BuildContext context, SettingsProvider settings, bool isDark) {
    final availableKeys = settings.availableApiKeyNames;
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select API Key'),
        actions: [
          ...availableKeys.map((keyName) {
            final isSelected = settings.selectedApiKeyName == keyName;
            return CupertinoActionSheetAction(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(keyName),
                  if (isSelected)
                    Icon(
                      CupertinoIcons.checkmark,
                      color: AppTheme.primaryMaroon,
                    ),
                ],
              ),
              onPressed: () {
                Navigator.pop(context);
                settings.setSelectedApiKey(keyName);
              },
            );
          }),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: false,
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showAddApiKeyDialog(BuildContext context, SettingsProvider settings) {
    final nameController = TextEditingController(text: 'API Key ${settings.availableApiKeyNames.length + 1}');
    final keyController = TextEditingController();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Add API Key'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoTextField(
                controller: nameController,
                placeholder: 'Key Name (e.g., API Key 1)',
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6.resolveFrom(context),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: keyController,
                placeholder: 'Enter your API key (rc_...)',
                obscureText: true,
                autocorrect: false,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6.resolveFrom(context),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Add'),
            onPressed: () {
              if (keyController.text.isNotEmpty) {
                settings.addApiKey(nameController.text, keyController.text);
                chatProvider.updateApiKey(keyController.text);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark, {
    bool showDivider = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  width: 1,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: CupertinoColors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.textPrimary : AppTheme.textDark,
              ),
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryMaroon,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    bool isDark, {
    bool showDivider = true,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom: BorderSide(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                    width: 1,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: CupertinoColors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppTheme.textPrimary : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppTheme.textTertiary : AppTheme.textDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: isDark ? AppTheme.textTertiary : AppTheme.textDarkSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    String title,
    String value,
    bool isDark, {
    bool showDivider = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  width: 1,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.textPrimary : AppTheme.textDark,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppTheme.textSecondary : AppTheme.textDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context, SettingsProvider settings) {
    // This is now handled by the dropdown, but keep for backward compatibility
    _showAddApiKeyDialog(context, settings);
  }

  void _showBaseUrlDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.featherlessBaseUrl);

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Featherless.ai Base URL'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'https://api.featherless.ai/v1',
            autocorrect: false,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Save'),
            onPressed: () {
              settings.setFeatherlessBaseUrl(controller.text);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showModelDialog(BuildContext context, SettingsProvider settings) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    final modelSections = <String, List<String>>{
      'Top-tier': [
        'Qwen/Qwen3-Coder-480B-A35B-Instruct',
        'Qwen/Qwen2.5-72B-Instruct',
        'deepseek-ai/DeepSeek-R1-Distill-Qwen-32B',
        'meta-llama/Meta-Llama-3.1-70B-Instruct',
        'NousResearch/Hermes-3-Llama-3.1-70B',
        'mistralai/Mistral-Small-3.1-24B-Instruct-2503',
      ],
      'Mid-size': [
        'Qwen/Qwen2.5-14B-Instruct',
        'deepseek-ai/DeepSeek-R1-Distill-Qwen-14B',
        'microsoft/Phi-4-mini-instruct',
        'mistralai/Mistral-Nemo-Instruct-2407',
      ],
      'Lightweight': [
        'Qwen/Qwen2.5-7B-Instruct',
        'deepseek-ai/DeepSeek-R1-Distill-Llama-8B',
        'meta-llama/Meta-Llama-3.1-8B-Instruct',
        'mistralai/Mistral-7B-Instruct-v0.3',
      ],
    };

    final customController = TextEditingController();

    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (ctx) => CupertinoPageScaffold(
          backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLightSecondary,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: isDark ? AppTheme.bgDarkSecondary : AppTheme.bgLight,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                width: 1,
              ),
            ),
            middle: Text(
              'Select Model',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.textPrimary : AppTheme.textDark,
              ),
            ),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
          child: SafeArea(
            child: ListView(
              children: [
                // Custom model input
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'CUSTOM MODEL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.textTertiary : AppTheme.textDarkSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: AppTheme.cardDecoration(isDark),
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoTextField(
                          controller: customController,
                          placeholder: 'org/model-name',
                          autocorrect: false,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: const BoxDecoration(),
                          style: TextStyle(
                            color: isDark ? AppTheme.textPrimary : AppTheme.textDark,
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Use',
                          style: TextStyle(
                            color: AppTheme.primaryMaroon,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          final model = customController.text.trim();
                          if (model.isNotEmpty) {
                            settings.setModel(model);
                            chatProvider.updateModel(model);
                            Navigator.pop(ctx);
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Model sections
                ...modelSections.entries.map((section) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          section.key.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.textTertiary : AppTheme.textDarkSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: AppTheme.cardDecoration(isDark),
                        child: Column(
                          children: section.value.asMap().entries.map((entry) {
                            final index = entry.key;
                            final model = entry.value;
                            final isSelected = settings.model == model;
                            final isLast = index == section.value.length - 1;
                            // Extract short display name from full model ID
                            final parts = model.split('/');
                            final org = parts[0];
                            final name = parts.length > 1 ? parts[1] : model;

                            return GestureDetector(
                              onTap: () {
                                settings.setModel(model);
                                chatProvider.updateModel(model);
                                Navigator.pop(ctx);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryMaroon.withOpacity(isDark ? 0.2 : 0.08)
                                      : null,
                                  border: isLast
                                      ? null
                                      : Border(
                                          bottom: BorderSide(
                                            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                                            width: 0.5,
                                          ),
                                        ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                              color: isSelected
                                                  ? AppTheme.primaryMaroon
                                                  : (isDark ? AppTheme.textPrimary : AppTheme.textDark),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            org,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? AppTheme.textTertiary : AppTheme.textDarkSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        CupertinoIcons.checkmark_circle_fill,
                                        color: AppTheme.primaryMaroon,
                                        size: 22,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
