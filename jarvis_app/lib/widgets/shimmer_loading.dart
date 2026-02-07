import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

/// Shimmer effect widget - creates a shimmering loading placeholder
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(-1.0 + 2.0 * _controller.value + 1.0, 0),
              colors: isDark
                  ? [
                      AppTheme.bgDarkSecondary,
                      AppTheme.bgDarkTertiary.withOpacity(0.7),
                      AppTheme.bgDarkSecondary,
                    ]
                  : [
                      AppTheme.bgLightTertiary.withOpacity(0.4),
                      AppTheme.bgLightTertiary.withOpacity(0.8),
                      AppTheme.bgLightTertiary.withOpacity(0.4),
                    ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton card with shimmer effect for loading states
class SkeletonCard extends StatelessWidget {
  final int lines;

  const SkeletonCard({super.key, this.lines = 3});

  @override
  Widget build(BuildContext context) {
    final isDark =
        CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShimmerBox(width: 24, height: 24, borderRadius: 12),
              const SizedBox(width: 12),
              ShimmerBox(width: 180, height: 18, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(lines, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ShimmerBox(
              width: i == lines - 1 ? 120 : double.infinity,
              height: 14,
              borderRadius: 4,
            ),
          )),
        ],
      ),
    );
  }
}

/// Skeleton message bubble for chat loading
class SkeletonMessage extends StatelessWidget {
  final bool isUser;

  const SkeletonMessage({super.key, this.isUser = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const ShimmerBox(width: 32, height: 32, borderRadius: 10),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              ShimmerBox(
                width: isUser ? 180 : 240,
                height: 48,
                borderRadius: 16,
              ),
            ],
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const ShimmerBox(width: 32, height: 32, borderRadius: 10),
          ],
        ],
      ),
    );
  }
}
