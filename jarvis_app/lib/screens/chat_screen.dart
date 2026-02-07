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

          // Main content area
          Expanded(
            child: Column(
              children: [
                // Small Type/Voice toggle pill at top
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.bgDarkSecondary : AppTheme.bgLightSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                        width: 1,
                      ),
                    ),
                    child: CupertinoSlidingSegmentedControl<int>(
                      groupValue: _selectedMode,
                      backgroundColor: Colors.transparent,
                      thumbColor: isDark ? AppTheme.bgDarkTertiary : AppTheme.bgLight,
                      onValueChanged: (value) {
                        if (value != null) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedMode = value;
                          });
                        }
                      },
                      children: {
                        0: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          child: Text(
                            'Type',
                            style: TextStyle(
                              color: _selectedMode == 0 
                                  ? (isDark ? AppTheme.textPrimary : AppTheme.textDark)
                                  : (isDark ? AppTheme.textTertiary : AppTheme.textDarkSecondary),
                              fontWeight: _selectedMode == 0 ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        1: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          child: Text(
                            'Voice',
                            style: TextStyle(
                              color: _selectedMode == 1 
                                  ? (isDark ? AppTheme.textPrimary : AppTheme.textDark)
                                  : (isDark ? AppTheme.textTertiary : AppTheme.textDarkSecondary),
                              fontWeight: _selectedMode == 1 ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      },
                    ),
                  ),
                ),

                // Content area
                Expanded(
                  child: _selectedMode == 0
                      ? Consumer<ChatProvider>(
                          builder: (context, provider, _) {
                            if (provider.messages.isEmpty) {
                              return _buildEmptyStateWithInput(context, isDark);
                            }
                            return _buildChatWithInput(context, provider, isDark);
                          },
                        )
                      : const VoiceModeWidget(),
                ),
              ],
            ),
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

  Widget _buildEmptyStateWithInput(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppTheme.darkGradient : null,
        color: isDark ? null : AppTheme.bgLightSecondary,
      ),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              // JARVIS branding with gradient + float animation
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.sparkles,
                  size: 50,
                  color: CupertinoColors.white,
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                  .scaleXY(begin: 0.6, end: 1.0, duration: 500.ms, curve: Curves.easeOut)
                  .then()
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: 0, end: -5, duration: 3000.ms, curve: Curves.easeInOut),
              const SizedBox(height: 32),
              Text(
                'Hello, I\'m JARVIS',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.textPrimary : AppTheme.textDark,
                  letterSpacing: -0.5,
                ),
              )
                  .animate(delay: 150.ms)
                  .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.1, end: 0, duration: 350.ms, curve: Curves.easeOut),
              const SizedBox(height: 12),
              Text(
                'Your AI-powered assistant',
                style: TextStyle(
                  fontSize: 18,
                  color: isDark ? AppTheme.textSecondary : AppTheme.textDarkSecondary,
                  fontWeight: FontWeight.w400,
                ),
              )
                  .animate(delay: 250.ms)
                  .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.1, end: 0, duration: 350.ms, curve: Curves.easeOut),
              const SizedBox(height: 48),
              _buildSuggestionChips(isDark),
              const SizedBox(height: 48),
              // Centered input box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _buildCompactInputArea(context, isDark),
              )
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.08, end: 0, duration: 400.ms, curve: Curves.easeOut),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatWithInput(BuildContext context, ChatProvider provider, bool isDark) {
    // Get bottom padding to account for tab bar
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
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
          ),
        ),
        // Bottom input area (centered, smaller width) - lifted above tab bar
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding + 50),
              child: _buildCompactInputArea(context, isDark),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionChips(bool isDark) {
    final suggestions = [
      'Check my email',
      'What are my tasks?',
      'Play some music',
      'Search the web',
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: suggestions.asMap().entries.map((entry) {
        final index = entry.key;
        final text = entry.value;
        return GestureDetector(
          onTap: () {
            _textController.text = text;
            _sendMessage(context.read<ChatProvider>());
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: AppTheme.cardDecoration(isDark),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.textPrimary : AppTheme.textDark,
              ),
            ),
          ),
        )
            .animate(delay: Duration(milliseconds: 300 + index * 80))
            .fadeIn(duration: 350.ms, curve: Curves.easeOut)
            .scaleXY(begin: 0.9, end: 1.0, duration: 350.ms, curve: Curves.easeOut);
      }).toList(),
    );
  }

  Widget _buildCompactInputArea(BuildContext context, bool isDark) {
    return Container(
      decoration: AppTheme.inputDecoration(isDark).copyWith(
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Text input
          Expanded(
            child: CupertinoTextField(
              controller: _textController,
              focusNode: _focusNode,
              placeholder: 'Ask JARVIS anything...',
              placeholderStyle: TextStyle(
                color: isDark ? AppTheme.textTertiary : AppTheme.textDarkSecondary,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              decoration: const BoxDecoration(),
              style: TextStyle(
                color: isDark ? AppTheme.textPrimary : AppTheme.textDark,
                fontSize: 16,
              ),
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(context.read<ChatProvider>()),
            ),
          ),

          // Send button
          Consumer<ChatProvider>(
            builder: (context, provider, _) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: provider.isLoading
                      ? null
                      : () => _sendMessage(provider),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: provider.isLoading
                        ? BoxDecoration(
                            color: isDark ? AppTheme.bgDarkTertiary : AppTheme.bgLightTertiary,
                            borderRadius: BorderRadius.circular(10),
                          )
                        : AppTheme.buttonDecoration(isDark, isPrimary: true),
                    child: Icon(
                      CupertinoIcons.arrow_up,
                      size: 20,
                      color: provider.isLoading
                          ? (isDark ? AppTheme.textTertiary : AppTheme.textDarkSecondary)
                          : CupertinoColors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}


