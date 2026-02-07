import 'package:flutter/cupertino.dart';
import 'chat_screen.dart';
import 'tasks_screen.dart';
import 'settings_screen.dart';
import '../theme/app_theme.dart';

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
    // Play initial animation
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    // Reset and replay the animation on every tab switch
    _animController.reset();
    setState(() => _currentIndex = index);
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      child: Column(
        children: [
          // Tab content
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
                    SettingsScreen(key: ValueKey('settings')),
                  ],
                ),
              ),
            ),
          ),
          // Tab bar
          CupertinoTabBar(
            backgroundColor: isDark ? AppTheme.bgDarkSecondary : AppTheme.bgLight,
            border: Border(
              top: BorderSide(
                color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                width: 1,
              ),
            ),
            activeColor: AppTheme.primaryMaroon,
            inactiveColor: isDark ? AppTheme.textTertiary : AppTheme.textDarkSecondary,
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.chat_bubble_2),
                activeIcon: Icon(CupertinoIcons.chat_bubble_2_fill),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.checkmark_circle),
                activeIcon: Icon(CupertinoIcons.checkmark_circle_fill),
                label: 'Tasks',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.settings),
                activeIcon: Icon(CupertinoIcons.settings_solid),
                label: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
