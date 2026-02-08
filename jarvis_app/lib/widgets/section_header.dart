import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

/// Figma-style section header: title, optional badge, optional trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? badge;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.title,
    this.badge,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppTheme.figmaForeground : AppTheme.textDark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.figmaSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.figmaSecondary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: AppTheme.figmaSecondary.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
