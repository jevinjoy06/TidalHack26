import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SelectableText, AdaptiveTextSelectionToolbar, ContextMenuButtonItem, SelectionChangedCause, EditableTextState, Colors;
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../models/message.dart';
import '../theme/app_theme.dart';
import 'rich_card.dart';

// #region agent log
void _log(String location, String message, Map<String, dynamic> data) {
  try {
    final payload = {
      'id': 'log_${DateTime.now().millisecondsSinceEpoch}',
      'location': location,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'sessionId': 'debug-session',
      'runId': 'run1',
      'hypothesisId': 'A'
    };
    // HTTP POST to debug server
    // ignore: unawaited_futures
    http.post(
      Uri.parse('http://127.0.0.1:7242/ingest/78061abd-f637-4255-9643-75d670b2aba6'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ).catchError((_) {
      // Return a dummy response to satisfy the Future type
      return http.Response('', 500);
    });
  } catch (e) {
    // Ignore logging errors
  }
}
// #endregion

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
    
    // #region agent log
    _log('message_bubble.dart:initState', 'Initializing message bubble', {
      'messageLength': widget.message.content.length,
      'hasLinks': _links.isNotEmpty,
      'isUser': widget.message.role == 'user'
    });
    // #endregion
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void _parseLinks() {
    final text = widget.message.content;
    _links = [];

    // #region agent log
    _log('message_bubble.dart:_parseLinks', 'Parsing links', {
      'textLength': text.length,
      'textPreview': text.length > 100 ? text.substring(0, 100) : text
    });
    // #endregion

    // Parse markdown links: [text](url)
    final markdownLinkRegex = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');
    for (var match in markdownLinkRegex.allMatches(text)) {
      _links.add(LinkInfo(
        url: match.group(2)!,
        startIndex: match.start,
        endIndex: match.end,
        displayText: match.group(1)!,
      ));
      // #region agent log
      _log('message_bubble.dart:_parseLinks', 'Found markdown link', {
        'url': match.group(2),
        'text': match.group(1),
        'startIndex': match.start,
        'endIndex': match.end
      });
      // #endregion
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
        // #region agent log
        _log('message_bubble.dart:_parseLinks', 'Found plain URL', {
          'url': match.group(0),
          'startIndex': match.start,
          'endIndex': match.end
        });
        // #endregion
      }
    }

    // Sort links by start index
    _links.sort((a, b) => a.startIndex.compareTo(b.startIndex));
    
    // #region agent log
    _log('message_bubble.dart:_parseLinks', 'Link parsing complete', {
      'totalLinks': _links.length
    });
    // #endregion
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
    // #region agent log
    _log('message_bubble.dart:_buildMessageText', 'Building message text', {
      'textLength': widget.message.content.length,
      'hasLinks': _links.isNotEmpty,
      'linkCount': _links.length
    });
    // #endregion
    
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

    // Use SelectableText.rich for native selection with clickable links
    // This provides web-like text selection (left-click drag, right-click drag)
    final textSpans = _buildTextSpans(baseStyle);
    
    final selectableText = SelectableText.rich(
      TextSpan(children: textSpans),
      style: baseStyle,
      enableInteractiveSelection: true,
      contextMenuBuilder: (context, editableTextState) {
        return _buildContextMenu(context, editableTextState);
      },
    );

    // #region agent log
    _log('message_bubble.dart:_buildMessageText', 'SelectableText.rich created', {
      'hasLinks': _links.isNotEmpty,
      'textLength': widget.message.content.length
    });
    // #endregion

    // Wrap in MouseRegion for cursor styling
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
          ..onTap = () {
            // #region agent log
            _log('message_bubble.dart:linkTap', 'Link tapped', {'url': link.url});
            // #endregion
            _launchUrl(link.url);
          },
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
            // #region agent log
            _log('message_bubble.dart:contextMenu', 'Copy action pressed', {});
            // #endregion
            editableTextState.copySelection(SelectionChangedCause.toolbar);
            Navigator.pop(context);
          },
        ),
        ContextMenuButtonItem(
          label: 'Select All',
          onPressed: () {
            // #region agent log
            _log('message_bubble.dart:contextMenu', 'Select All action pressed', {});
            // #endregion
            editableTextState.selectAll(SelectionChangedCause.toolbar);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }



  Future<void> _launchUrl(String url) async {
    // #region agent log
    _log('message_bubble.dart:_launchUrl', 'Launching URL', {'url': url});
    // #endregion
    try {
      final uri = Uri.parse(url);
      final canLaunch = await canLaunchUrl(uri);
      // #region agent log
      _log('message_bubble.dart:_launchUrl', 'canLaunchUrl result', {'canLaunch': canLaunch});
      // #endregion
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // #region agent log
        _log('message_bubble.dart:_launchUrl', 'URL launched successfully', {'url': url});
        // #endregion
      } else {
        // #region agent log
        _log('message_bubble.dart:_launchUrl', 'Cannot launch URL', {'url': url});
        // #endregion
      }
    } catch (e) {
      // #region agent log
      _log('message_bubble.dart:_launchUrl', 'Launch error', {'url': url, 'error': e.toString()});
      // #endregion
    }
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
