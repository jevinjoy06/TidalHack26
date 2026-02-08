import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_screen.dart';
import 'tasks_screen.dart';
import 'ili_screen.dart';
import 'settings_screen.dart';
import '../theme/app_theme.dart';
import '../providers/chat_provider.dart';
import '../providers/chat_history_provider.dart';
import '../widgets/chat_history_list.dart';

/// Figma UI layout: left sidebar (280px) + main content.
/// Sidebar: logo, New Chat, search (chat only), recent (chat only), bottom nav.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.025),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    // Allow "New Chat" to work even when already on chat (index 0)
    if (index == _currentIndex && index != 0) return;
    _animController.reset();
    setState(() => _currentIndex = index);
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // Left Sidebar (Figma: w-[280px])
        _buildSidebar(isDark),
        // Main content
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: IndexedStack(
                index: _currentIndex,
                children: const [
                  ChatScreen(key: ValueKey('chat')),
                  TasksScreen(key: ValueKey('tasks')),
                  IliScreen(key: ValueKey('ili')),
                  SettingsScreen(key: ValueKey('settings')),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar(bool isDark) {
    final sidebarBg = isDark ? AppTheme.figmaSidebar : AppTheme.bgLight;
    final borderColor = isDark ? AppTheme.figmaSidebarBorder : AppTheme.borderLight;
    final textFg = isDark ? AppTheme.figmaForeground : AppTheme.textDark;
    final mutedFg = isDark ? AppTheme.figmaMutedForeground : AppTheme.textDarkSecondary;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(
          right: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo / Brand
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.figmaAccent.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.sparkles,
                    size: 18,
                    color: CupertinoColors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JARVIS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textFg,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'v2.1.0',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: mutedFg,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // New Chat button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: () {
                  // Clear chat and switch to chat screen
                  final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                  chatProvider.clearMessages();
                  _onNavTap(0);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.figmaAccent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.figmaAccent.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.add, size: 18, color: CupertinoColors.white),
                      SizedBox(width: 8),
                      Text(
                        'New Chat',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Search (only on chat page)
          if (_currentIndex == 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.figmaInputBackground : AppTheme.bgLightTertiary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppTheme.figmaBorder : AppTheme.borderLight,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.search,
                      size: 16,
                      color: mutedFg,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search conversations',
                        style: TextStyle(
                          fontSize: 14,
                          color: mutedFg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Recent section (show on all tabs)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'RECENT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: mutedFg,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer2<ChatHistoryProvider, ChatProvider>(
              builder: (context, historyProvider, chatProvider, _) {
                return ChatHistoryList(
                  history: historyProvider.history,
                  currentChatId: chatProvider.currentChatId,
                  isLoadingMessage: chatProvider.isLoading,
                  onChatTap: (chatId) async {
                    if (chatProvider.isLoading) return;
                    await historyProvider.loadChatById(chatId);
                    if (_currentIndex == 0) {
                      _animController.reset();
                      _animController.forward();
                    } else {
                      _onNavTap(0);
                    }
                  },
                  onChatDelete: (chatId) => historyProvider.deleteChat(chatId),
                  onChatRename: (chatId, newName) => historyProvider.renameChat(chatId, newName),
                );
              },
            ),
          ),
          // Bottom nav (Tasks, Settings) — Chat is reached via "New Chat" only
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? AppTheme.figmaSidebarBorder : AppTheme.borderLight,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SidebarNavItem(
                  icon: CupertinoIcons.checkmark_circle,
                  label: 'Tasks',
                  active: _currentIndex == 1,
                  onTap: () => _onNavTap(1),
                  isDark: isDark,
                ),
                const SizedBox(height: 4),
                _SidebarNavItem(
                  icon: CupertinoIcons.graph_square,
                  label: 'ILI Alignment',
                  active: _currentIndex == 2,
                  onTap: () => _onNavTap(2),
                  isDark: isDark,
                ),
                const SizedBox(height: 4),
                _SidebarNavItem(
                  icon: CupertinoIcons.settings,
                  label: 'Settings',
                  active: _currentIndex == 3,
                  onTap: () => _onNavTap(3),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool isDark;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppTheme.figmaForeground : AppTheme.textDark;
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onPressed: onTap,
      alignment: Alignment.centerLeft,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? (isDark ? AppTheme.figmaAccent.withOpacity(0.2) : AppTheme.figmaAccent.withOpacity(0.1))
              : null,
          borderRadius: BorderRadius.circular(10),
          border: active
              ? Border.all(
                  color: AppTheme.figmaAccent.withOpacity(0.3),
                  width: 1,
                )
              : null,
          boxShadow: active && isDark
              ? [
                  BoxShadow(
                    color: AppTheme.figmaAccent.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: active ? AppTheme.figmaAccent : fg,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? AppTheme.figmaAccent : fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
