import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/settings_provider.dart';
import '../providers/chat_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/connection_status_widget.dart';
import '../models/connection_status.dart';

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
    final controller = TextEditingController(text: settings.model);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Common Featherless.ai models (matching their actual format)
    final commonModels = [
      'Qwen/Qwen2.5-14B-Instruct',
      'Qwen/Qwen2.5-7B-Instruct',
      'meta-llama/Llama-3.1-8B-Instruct',
      'meta-llama/Llama-3.1-70B-Instruct',
      'mistralai/Mistral-7B-Instruct-v0.3',
      'deepseek-ai/DeepSeek-V2-Chat-0628',
      'deepseek-ai/deepseek-coder-33b-instruct',
    ];

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Select Model'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CupertinoTextField(
                    controller: controller,
                    placeholder: 'Enter model name (e.g., google/gemma-3-27b-it)',
                    autocorrect: false,
                  ),
                ),
                const Text(
                  'Common Models:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...commonModels.map((model) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: settings.model == model 
                        ? AppTheme.primaryMaroon 
                        : CupertinoColors.systemGrey6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          model,
                          style: TextStyle(
                            color: settings.model == model 
                                ? CupertinoColors.white 
                                : CupertinoColors.black,
                          ),
                        ),
                        if (settings.model == model)
                          const Icon(
                            CupertinoIcons.checkmark,
                            color: CupertinoColors.white,
                            size: 18,
                          ),
                      ],
                    ),
                    onPressed: () {
                      controller.text = model;
                      settings.setModel(model);
                      chatProvider.updateModel(model);
                      Navigator.pop(context);
                    },
                  ),
                )),
              ],
            ),
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
              if (controller.text.isNotEmpty) {
                settings.setModel(controller.text);
                chatProvider.updateModel(controller.text);
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
