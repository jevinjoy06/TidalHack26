import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChatSession {
  final String id;
  final String title;
  final String lastMessage;
  final String updatedAt;

  ChatSession({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.updatedAt,
  });
}

class ChatSidebar extends StatefulWidget {
  final String apiUrl; // Not used anymore, kept for compatibility
  final Function(String) onChatSelected;
  final String? currentChatId;
  final VoidCallback? onChatsChanged;
  final VoidCallback? onMinimize;

  const ChatSidebar({
    super.key,
    required this.apiUrl,
    required this.onChatSelected,
    this.currentChatId,
    this.onChatsChanged,
    this.onMinimize,
  });

  @override
  State<ChatSidebar> createState() => _ChatSidebarState();
}

class _ChatSidebarState extends State<ChatSidebar> {
  List<ChatSession> _chats = [];

  @override
  void initState() {
    super.initState();
    // Chats are now managed locally, no API calls needed
  }

  Future<void> _createNewChat() async {
    // Create a new local chat session
    final newChat = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Chat',
      lastMessage: '',
      updatedAt: DateTime.now().toIso8601String(),
    );

    setState(() {
      _chats.insert(0, newChat);
    });

    widget.onChatsChanged?.call();
    widget.onChatSelected(newChat.id);
  }

  void _deleteChat(String chatId) {
    setState(() {
      _chats.removeWhere((chat) => chat.id == chatId);
    });

    widget.onChatsChanged?.call();

    if (widget.currentChatId == chatId) {
      if (_chats.isNotEmpty) {
        widget.onChatSelected(_chats[0].id);
      } else {
        widget.onChatSelected(''); // Clear selection
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 260,
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
          // Header with minimize button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.onMinimize != null)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 32,
                    onPressed: widget.onMinimize,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.bgDarkTertiary : AppTheme.bgLightTertiary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          CupertinoIcons.sidebar_left,
                          size: 18,
                          color: isDark ? AppTheme.textSecondary : AppTheme.textDarkSecondary,
                        ),
                      ),
                  ),
              ],
            ),
          ),
          // New Chat Button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _createNewChat,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryMaroon.withOpacity(0.3),
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Chat List
          Expanded(
            child: _chats.isEmpty
                ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'No chats yet.\nCreate a new chat to get started!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? AppTheme.textTertiary : AppTheme.textDarkSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                  )
                : ListView.builder(
                    itemCount: _chats.length,
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      return _buildChatTile(
                        id: chat.id,
                        title: chat.title,
                        lastMessage: chat.lastMessage,
                        isSelected: widget.currentChatId == chat.id,
                        onTap: () => widget.onChatSelected(chat.id),
                        onDelete: () => _deleteChat(chat.id),
                      );
                    },
                  ),
          ),

          // Bottom info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.folder,
                  size: 16,
                  color: isDark ? AppTheme.textTertiary : AppTheme.textDarkSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_chats.length} conversation${_chats.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: isDark ? AppTheme.textTertiary : AppTheme.textDarkSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile({
    required String id,
    required String title,
    required String lastMessage,
    required bool isSelected,
    required VoidCallback onTap,
    required VoidCallback? onDelete,
  }) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? null : Border.all(
            color: Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.chat_bubble,
              size: 20,
              color: isSelected 
                  ? CupertinoColors.white 
                  : (isDark ? AppTheme.textSecondary : AppTheme.textDarkSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected 
                          ? CupertinoColors.white 
                          : (isDark ? AppTheme.textPrimary : AppTheme.textDark),
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (lastMessage.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      lastMessage,
                      style: TextStyle(
                        color: isSelected
                            ? CupertinoColors.white.withOpacity(0.8)
                            : (isDark ? AppTheme.textTertiary : AppTheme.textDarkSecondary),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (onDelete != null)
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 32,
                onPressed: () {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text('Delete Chat'),
                      content: const Text(
                          'Are you sure you want to delete this conversation?'),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        CupertinoDialogAction(
                          onPressed: () {
                            Navigator.pop(context);
                            onDelete();
                          },
                          isDestructiveAction: true,
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                child: Icon(
                  CupertinoIcons.delete,
                  size: 16,
                  color: isDark ? AppTheme.textTertiary : AppTheme.textDarkSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
