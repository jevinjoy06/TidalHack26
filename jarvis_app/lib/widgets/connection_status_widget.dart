import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/connection_status.dart';
import '../theme/app_theme.dart';

class ConnectionStatusWidget extends StatelessWidget {
  final ConnectionStatus status;
  final String? errorMessage;
  final DateTime? lastChecked;
  final VoidCallback? onRefresh;

  const ConnectionStatusWidget({
    super.key,
    required this.status,
    this.errorMessage,
    this.lastChecked,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: status == ConnectionStatus.connected
                      ? AppTheme.primaryGradient
                      : null,
                  color: status == ConnectionStatus.connected
                      ? null
                      : status.statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: status == ConnectionStatus.connected
                      ? [
                          BoxShadow(
                            color: AppTheme.success.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: status == ConnectionStatus.connecting
                    ? const CupertinoActivityIndicator()
                    : Icon(
                        status.statusIcon,
                        color: status == ConnectionStatus.connected
                            ? CupertinoColors.white
                            : status.statusColor,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.textPrimary : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      errorMessage ?? status.errorMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppTheme.textSecondary : AppTheme.textDarkSecondary,
                      ),
                    ),
                    if (lastChecked != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Last checked: ${_formatTime(lastChecked!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.textTertiary : AppTheme.textDarkSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onRefresh != null)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.bgDarkTertiary : AppTheme.bgLightTertiary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      CupertinoIcons.refresh,
                      size: 18,
                      color: isDark ? AppTheme.textSecondary : AppTheme.textDarkSecondary,
                    ),
                  ),
                  onPressed: status == ConnectionStatus.connecting ? null : onRefresh,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
