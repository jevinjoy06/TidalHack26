import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SelectableText, AdaptiveTextSelectionToolbar, ContextMenuButtonItem, SelectionChangedCause, EditableTextState, Colors;
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/message.dart';
import '../theme/app_theme.dart';
import 'rich_card.dart';

class LinkInfo {
  final String url;
  final int startIndex;
  final int endIndex;
  final String displayText;

  LinkInfo({
    required this.url,
    required this.startIndex,
    required this.endIndex,
    required this.displayText,
  });
}

class MessageBubble extends StatefulWidget {
  final Message message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _mounted = true;
  List<LinkInfo> _links = [];

  @override
  void initState() {
    super.initState();
    _parseLinks();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void _parseLinks() {
    final text = widget.message.content;
    _links = [];

    // Parse markdown links: [text](url)
    final markdownLinkRegex = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');
    for (var match in markdownLinkRegex.allMatches(text)) {
      _links.add(LinkInfo(
        url: match.group(2)!,
        startIndex: match.start,
        endIndex: match.end,
        displayText: match.group(1)!,
      ));
    }

    // Parse plain URLs: https?://...
    final urlRegex = RegExp(r'(https?://[^\s]+)');
    for (var match in urlRegex.allMatches(text)) {
      // Check if this URL is already part of a markdown link
      bool isPartOfMarkdownLink = false;
      for (var link in _links) {
        if (match.start >= link.startIndex && match.end <= link.endIndex) {
          isPartOfMarkdownLink = true;
          break;
        }
      }
      if (!isPartOfMarkdownLink) {
        _links.add(LinkInfo(
          url: match.group(0)!,
          startIndex: match.start,
          endIndex: match.end,
          displayText: match.group(0)!,
        ));
      }
    }

    // Sort links by start index
    _links.sort((a, b) => a.startIndex.compareTo(b.startIndex));
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final isUser = widget.message.role == MessageRole.user;
    final isError = widget.message.status == MessageStatus.error;

    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) ...[
          _buildAvatar(isDark),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isUser ? AppTheme.primaryGradient : null,
              color: isUser
                  ? null
                  : isError
                      ? AppTheme.error.withOpacity(0.15)
                      : (isDark
                          ? AppTheme.bgDarkSecondary
                          : AppTheme.bgLightSecondary),
              borderRadius: BorderRadius.circular(16),
              border: isUser ? null : Border.all(
                color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMessageText(
                  isUser: isUser,
                  isError: isError,
                  isDark: isDark,
                  context: context,
                ),
                if (widget.message.hasRichCard)
                  RichCard(
                    cardType: widget.message.cardType!,
                    data: widget.message.richData!,
                  ),
                if (widget.message.status == MessageStatus.sending) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CupertinoActivityIndicator(
                          radius: 6,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Sending...',
                        style: TextStyle(
                          fontSize: 12,
                          color: isUser
                              ? CupertinoColors.white.withOpacity(0.7)
                              : CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        if (isUser) ...[
          const SizedBox(width: 8),
          _buildUserAvatar(isDark),
        ],
      ],
    );
  }

  Widget _buildMessageText({
    required bool isUser,
    required bool isError,
    required bool isDark,
    required BuildContext context,
  }) {
    final content = widget.message.content.trim();
    if (content.isEmpty) {
      return const SizedBox.shrink();
    }

    final baseStyle = TextStyle(
      fontSize: 17,
      color: isUser
          ? CupertinoColors.white
          : isError
              ? AppTheme.error
              : (isDark
                  ? CupertinoColors.white
                  : CupertinoColors.black),
    );

    // Assistant messages: render as Markdown (bold, italic, code, links).
    if (!isUser) {
      final styleSheet = MarkdownStyleSheet(
        p: baseStyle,
        h1: baseStyle.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
        h2: baseStyle.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
        h3: baseStyle.copyWith(fontSize: 19, fontWeight: FontWeight.w600),
        a: baseStyle.copyWith(
          color: CupertinoColors.systemBlue,
          decoration: TextDecoration.underline,
        ),
        code: baseStyle.copyWith(
          fontFamily: 'monospace',
          fontSize: 16,
          backgroundColor: isDark
              ? CupertinoColors.systemGrey.withOpacity(0.3)
              : CupertinoColors.systemGrey5,
        ),
        codeblockDecoration: BoxDecoration(
          color: isDark
              ? CupertinoColors.systemGrey.withOpacity(0.25)
              : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8),
        ),
        codeblockPadding: const EdgeInsets.all(12),
      );
      return MarkdownBody(
        data: widget.message.content,
        selectable: true,
        styleSheet: styleSheet,
        onTapLink: (text, href, title) {
          if (href != null && href.isNotEmpty) _launchUrl(href);
        },
      );
    }

    // User messages: plain text with clickable links (existing behavior).
    final textSpans = _buildTextSpans(baseStyle);
    final selectableText = SelectableText.rich(
      TextSpan(children: textSpans),
      style: baseStyle,
      enableInteractiveSelection: true,
      contextMenuBuilder: (context, editableTextState) {
        return _buildContextMenu(context, editableTextState);
      },
    );

    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: selectableText,
    );
  }
  
  List<TextSpan> _buildTextSpans(TextStyle baseStyle) {
    if (_links.isEmpty) {
      // No links - just return plain text
      return [TextSpan(text: widget.message.content, style: baseStyle)];
    }
    
    // Build TextSpans with clickable links
    final spans = <TextSpan>[];
    final text = widget.message.content;
    int lastIndex = 0;
    
    // Sort links by start index
    final sortedLinks = List<LinkInfo>.from(_links)..sort((a, b) => a.startIndex.compareTo(b.startIndex));
    
    for (var link in sortedLinks) {
      // Add text before the link
      if (link.startIndex > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, link.startIndex),
          style: baseStyle,
        ));
      }
      
      // Add clickable link
      spans.add(TextSpan(
        text: text.substring(link.startIndex, link.endIndex),
        style: baseStyle.copyWith(
          color: CupertinoColors.systemBlue,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _launchUrl(link.url),
      ));
      
      lastIndex = link.endIndex;
    }
    
    // Add remaining text after last link
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }
    
    return spans;
  }
  
  Widget _buildContextMenu(BuildContext context, EditableTextState editableTextState) {
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: [
        ContextMenuButtonItem(
          label: 'Copy',
          onPressed: () {
            editableTextState.copySelection(SelectionChangedCause.toolbar);
            Navigator.pop(context);
          },
        ),
        ContextMenuButtonItem(
          label: 'Select All',
          onPressed: () {
            editableTextState.selectAll(SelectionChangedCause.toolbar);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }



  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Widget _buildAvatar(bool isDark) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryMaroon.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'J',
          style: TextStyle(
            color: CupertinoColors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(bool isDark) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.systemGrey5.darkColor
            : CupertinoColors.systemGrey5,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        CupertinoIcons.person_fill,
        size: 18,
        color: isDark ? CupertinoColors.white : CupertinoColors.systemGrey,
      ),
    );
  }


  void _showCopiedToast(BuildContext context) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Copied to clipboard',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () => entry.remove());
  }
}
