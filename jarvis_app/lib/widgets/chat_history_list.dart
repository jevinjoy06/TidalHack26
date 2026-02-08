import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/chat_history.dart';
import '../theme/app_theme.dart';
import '../utils/time_formatter.dart';

class ChatHistoryList extends StatelessWidget {
  final List<ChatHistoryItem> history;
  final String? currentChatId;
  final bool isLoadingMessage;
  final Future<void> Function(String) onChatTap;
  final Function(String) onChatDelete;
  final Function(String, String) onChatRename;

  const ChatHistoryList({
    super.key,
    required this.history,
    this.currentChatId,
    this.isLoadingMessage = false,
    required this.onChatTap,
    required this.onChatDelete,
    required this.onChatRename,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No recent chats',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.figmaMutedForeground : AppTheme.textDarkSecondary,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: history.length,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemBuilder: (context, index) {
        final item = history[index];
        final isActive = item.id == currentChatId;

        return _ChatHistoryItem(
          item: item,
          isActive: isActive,
          isDark: isDark,
          isDisabled: isLoadingMessage && !isActive,
          onTap: () => onChatTap(item.id),
          onDelete: () => _showDeleteConfirmation(context, item.id, isDark),
          onRename: () => _showRenameDialog(context, item.id, item.summary, isDark),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, String chatId, bool isDark) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this conversation?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              onChatDelete(chatId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, String chatId, String currentSummary, bool isDark) {
    final controller = TextEditingController(text: currentSummary);

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Rename Chat'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Chat summary',
            maxLength: 50,
            style: TextStyle(
              color: isDark ? AppTheme.figmaForeground : AppTheme.textDark,
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final newSummary = controller.text.trim();
              if (newSummary.isNotEmpty) {
                Navigator.of(context).pop();
                onChatRename(chatId, newSummary);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ChatHistoryItem extends StatelessWidget {
  final ChatHistoryItem item;
  final bool isActive;
  final bool isDark;
  final bool isDisabled;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const _ChatHistoryItem({
    required this.item,
    required this.isActive,
    required this.isDark,
    this.isDisabled = false,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final textFg = isDark ? AppTheme.figmaForeground : AppTheme.textDark;
    final mutedFg = isDark ? AppTheme.figmaMutedForeground : AppTheme.textDarkSecondary;
    final bgColor = isDark ? AppTheme.figmaSidebar : AppTheme.bgLight;
    final hoverColor = isDark 
        ? AppTheme.figmaAccent.withOpacity(0.1) 
        : AppTheme.figmaAccent.withOpacity(0.05);

    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        onLongPress: isDisabled ? null : () => _showContextMenu(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? hoverColor : bgColor,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border.all(color: AppTheme.figmaAccent.withOpacity(0.3), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.summary,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textFg,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      getRelativeTime(item.lastUpdated),
                      style: TextStyle(
                        fontSize: 11,
                        color: mutedFg,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.isLoading) ...[
                const SizedBox(width: 8),
                const CupertinoActivityIndicator(radius: 6),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              onRename();
            },
            child: const Text('Rename'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            child: const Text('Delete'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}
