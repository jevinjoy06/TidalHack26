import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';

import '../models/message.dart';
import '../providers/chat_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/voice_mode_widget.dart';
import '../widgets/chat_sidebar.dart';
import '../widgets/hud_background.dart';

enum SidebarState { hidden, minimized, expanded }

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();
  int _selectedMode = 0; // 0 = Type, 1 = Voice
  String? _currentChatId;
  SidebarState _sidebarState = SidebarState.expanded;
  List<Map<String, dynamic>> _chats = [];

  @override
  void initState() {
    super.initState();
    // Load chats directly for the minimized sidebar view
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _loadChats();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    // Chat history is now managed locally in the provider
    // No need to load from backend
    setState(() {
      _chats = []; // Empty for now, can be extended later
    });
  }

  void _toggleSidebar() {
    setState(() {
      if (_sidebarState == SidebarState.hidden) {
        _sidebarState = SidebarState.expanded;
      } else {
        _sidebarState = SidebarState.hidden;
      }
    });
  }

  void _minimizeSidebar() {
    if (_sidebarState == SidebarState.expanded) {
      setState(() {
        _sidebarState = SidebarState.minimized;
      });
    }
  }

  void _expandSidebar() {
    setState(() {
      _sidebarState = SidebarState.expanded;
    });
  }

  bool _handleKeyEvent(KeyEvent event) {
    // Ctrl+B or Cmd+B to toggle sidebar
    if (event is KeyDownEvent) {
      final isControlPressed = HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;

      if (isControlPressed && event.logicalKey == LogicalKeyboardKey.keyB) {
        _toggleSidebar();
        return true;
      }
    }
    return false;
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }


  void _sendMessage(ChatProvider provider) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    provider.sendMessage(text);
    _textController.clear();
    _scrollToBottom();

    // Auto-minimize sidebar after sending message
    _minimizeSidebar();
  }

  void _onChatSelected(String chatId) async {
    final provider = context.read<ChatProvider>();

    // Don't allow switching while generating a response
    if (provider.isLoading) {
      return;
    }

    // If empty string (no chats left), just clear everything
    if (chatId.isEmpty) {
      setState(() {
        _currentChatId = null;
      });
      provider.clearMessages();
      return;
    }

    // Don't switch if already on this chat
    if (_currentChatId == chatId) {
      return;
    }

    setState(() {
      _currentChatId = chatId;
    });

    // Chat switching is now handled locally
    // No backend call needed
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      onKeyEvent: _handleKeyEvent,
      autofocus: true,
      child: Row(
        children: [
          // Chat Sidebar (full height, only in Type mode)
          if (_selectedMode == 0 && _sidebarState != SidebarState.hidden)
            _sidebarState == SidebarState.minimized
                ? _buildMinimizedSidebar(isDark)
                : ChatSidebar(
                    apiUrl: '', // Not needed for Featherless.ai
                    currentChatId: _currentChatId,
                    onChatSelected: _onChatSelected,
                    onChatsChanged: _loadChats,
                    onMinimize: _minimizeSidebar,
                  ),

          // Main content area (Figma: HUD + top bar + content + input bar)
          Expanded(
            child: _selectedMode == 0
                ? Consumer<ChatProvider>(
                    builder: (context, provider, _) {
                      return Stack(
                        children: [
                          // HUD background (Figma)
                          if (provider.messages.isEmpty)
                            const Positioned.fill(child: HudBackground()),
                          Column(
                            children: [
                              // Top bar: Voice Mode button + user avatar (Figma)
                              _buildTopBar(isDark),
                              // Content
                              Expanded(
                                child: provider.messages.isEmpty
                                    ? _buildEmptyStateWithInput(context, isDark)
                                    : _buildChatWithInput(context, provider, isDark),
                              ),
                              // Bottom input bar (Figma style) - only in type mode empty state or when messages
                              if (provider.messages.isNotEmpty)
                                _buildBottomInputBar(context, isDark)
                              else
                                _buildWelcomeInputBar(context, isDark),
                            ],
                          ),
                        ],
                      );
                    },
                  )
                : const VoiceModeWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimizedSidebar(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: const Cubic(0.4, 0, 0.2, 1),
      width: 60,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgDarkSecondary : AppTheme.bgLightSecondary,
        border: Border(
          right: BorderSide(
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Expand button
          GestureDetector(
            onTap: _expandSidebar,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                CupertinoIcons.sidebar_left,
                size: 20,
                color: CupertinoColors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Chat icons (minimized view) - using actual chat data
          Expanded(
            child: _chats.isEmpty
                ? Center(
                    child: Icon(
                      CupertinoIcons.chat_bubble,
                      size: 20,
                      color: isDark ? AppTheme.textTertiary : AppTheme.textDarkSecondary,
                    ),
                  )
                : ListView.builder(
                    itemCount: _chats.length,
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      final isSelected = _currentChatId == chat['id'];

                      return GestureDetector(
                        onTap: () => _onChatSelected(chat['id']),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: isSelected ? AppTheme.primaryGradient : null,
                              color: isSelected ? null : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              CupertinoIcons.chat_bubble,
                              size: 20,
                              color: isSelected 
                                  ? CupertinoColors.white 
                                  : (isDark ? AppTheme.textTertiary : AppTheme.textDarkSecondary),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Keyboard shortcut hint
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '⌘B',
              style: const TextStyle(
                color: Color(0xFF757575),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _promptCards = [
    'Summarize my latest messages',
    'Draft a reply in a friendly tone',
    'Turn this into tasks',
    'Plan my day',
    'Extract action items',
    'Find key dates',
  ];

  Widget _buildEmptyStateWithInput(BuildContext context, bool isDark) {
    final fg = isDark ? AppTheme.figmaForeground : AppTheme.textDark;
    final muted = isDark ? AppTheme.figmaMutedForeground : AppTheme.textDarkSecondary;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 200,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1152),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title with gradient (Figma: "Welcome to JARVIS")
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        AppTheme.figmaForeground,
                        AppTheme.figmaAccent,
                        AppTheme.figmaSecondary,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'Welcome to JARVIS',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                      .slideY(begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOut),
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    width: 256,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppTheme.figmaAccent.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your personal command center for chat, tasks, and automation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: muted,
                      height: 1.5,
                    ),
                  )
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                      .slideY(begin: 0.05, end: 0, duration: 350.ms, curve: Curves.easeOut),
                  const SizedBox(height: 48),
                  // 2x3 prompt cards (Figma)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: List.generate(_promptCards.length, (i) {
                      return SizedBox(
                        width: 220,
                        child: _buildPromptCard(
                          _promptCards[i],
                          isDark,
                          fg,
                          muted,
                          i,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPromptCard(String text, bool isDark, Color fg, Color muted, int index) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        _textController.text = text;
        _sendMessage(context.read<ChatProvider>());
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.figmaCard.withOpacity(0.4) : AppTheme.bgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppTheme.figmaBorder : AppTheme.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: fg,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.arrow_right,
              size: 16,
              color: muted,
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 150 + index * 60))
        .fadeIn(duration: 350.ms, curve: Curves.easeOut)
        .slideY(begin: 0.05, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }

  Widget _buildTopBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.bgDark : AppTheme.bgLight).withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: (isDark ? AppTheme.figmaBorder : AppTheme.borderLight).withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.figmaAccent.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.person_fill,
              size: 18,
              color: CupertinoColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatWithInput(BuildContext context, ChatProvider provider, bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: provider.messages.length + (provider.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.messages.length && provider.isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: TypingIndicator(),
          );
        }
        final message = provider.messages[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: MessageBubble(message: message),
        )
            .animate()
            .fadeIn(duration: 300.ms, curve: Curves.easeOut)
            .slideX(
              begin: message.role == MessageRole.user ? 0.05 : -0.05,
              end: 0,
              duration: 300.ms,
              curve: Curves.easeOut,
            );
      },
    );
  }

  Widget _buildWelcomeInputBar(BuildContext context, bool isDark) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomPadding),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.bgDark : AppTheme.bgLight).withOpacity(0.8),
        border: Border(
          top: BorderSide(
            color: (isDark ? AppTheme.figmaBorder : AppTheme.borderLight).withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 896),
          child: _buildFigmaInputBar(context, isDark),
        ),
      ),
    );
  }

  Widget _buildBottomInputBar(BuildContext context, bool isDark) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomPadding),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.bgDark : AppTheme.bgLight).withOpacity(0.8),
        border: Border(
          top: BorderSide(
            color: (isDark ? AppTheme.figmaBorder : AppTheme.borderLight).withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 896),
          child: _buildFigmaInputBar(context, isDark),
        ),
      ),
    );
  }

  Widget _buildFigmaInputBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.figmaCard.withOpacity(0.6) : AppTheme.bgLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.figmaBorder : AppTheme.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.figmaAccent.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: _textController,
              focusNode: _focusNode,
              placeholder: 'Ask JARVIS anything…',
              placeholderStyle: TextStyle(
                color: isDark ? AppTheme.figmaMutedForeground : AppTheme.textDarkSecondary,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(),
              style: TextStyle(
                color: isDark ? AppTheme.figmaForeground : AppTheme.textDark,
                fontSize: 15,
              ),
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(context.read<ChatProvider>()),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(10),
            minSize: 0,
            onPressed: () {
              setState(() => _selectedMode = 1);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.figmaMuted.withOpacity(0.5) : AppTheme.bgLightTertiary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                CupertinoIcons.mic_fill,
                size: 18,
                color: isDark ? AppTheme.figmaMutedForeground : AppTheme.textDarkSecondary,
              ),
            ),
          ),
          Consumer<ChatProvider>(
            builder: (context, provider, _) {
              return CupertinoButton(
                padding: const EdgeInsets.all(10),
                minSize: 0,
                onPressed: provider.isLoading
                    ? null
                    : () => _sendMessage(provider),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: provider.isLoading
                        ? (isDark ? AppTheme.figmaMuted : AppTheme.bgLightTertiary)
                        : AppTheme.figmaAccent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: provider.isLoading
                        ? null
                        : [
                            BoxShadow(
                              color: AppTheme.figmaAccent.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Icon(
                    CupertinoIcons.arrow_up,
                    size: 18,
                    color: provider.isLoading
                        ? (isDark ? AppTheme.figmaMutedForeground : AppTheme.textDarkSecondary)
                        : CupertinoColors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

}


