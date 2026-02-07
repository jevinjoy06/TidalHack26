import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

/// A widget that displays animated linear soundwave bars (like an audio visualizer)
class SoundwaveAnimation extends StatefulWidget {
  final bool isSpeaking;
  final Color? color;
  final int barCount;
  final double barWidth;
  final double spacing;
  final double idleMinHeight;
  final double idleMaxHeight;
  final double speakingMinHeight;
  final double speakingMaxHeight;

  const SoundwaveAnimation({
    super.key,
    this.isSpeaking = false,
    this.color,
    this.barCount = 7,
    this.barWidth = 4.0,
    this.spacing = 3.0,
    this.idleMinHeight = 0.3,
    this.idleMaxHeight = 1.0,
    this.speakingMinHeight = 0.5,
    this.speakingMaxHeight = 1.5,
  });

  @override
  State<SoundwaveAnimation> createState() => _SoundwaveAnimationState();
}

class _SoundwaveAnimationState extends State<SoundwaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void didUpdateWidget(SoundwaveAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Adjust animation speed based on speaking state
    if (widget.isSpeaking != oldWidget.isSpeaking) {
      _controller.duration = widget.isSpeaking
          ? const Duration(milliseconds: 400)
          : const Duration(milliseconds: 800);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getHeight(int index) {
    final minHeight = widget.isSpeaking
        ? widget.speakingMinHeight
        : widget.idleMinHeight;
    final maxHeight = widget.isSpeaking
        ? widget.speakingMaxHeight
        : widget.idleMaxHeight;

    // Staggered animation using sine wave with offset
    final offset = index * (2 * math.pi / widget.barCount);
    final value = (_controller.value * 2 * math.pi + offset) % (2 * math.pi);
    final normalizedValue = (math.sin(value) + 1) / 2; // 0 to 1

    return minHeight + (maxHeight - minHeight) * normalizedValue;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final color = widget.color ??
        (isDark
            ? CupertinoColors.systemBlue.darkColor
            : CupertinoColors.systemBlue);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(widget.barCount, (index) {
            final height = _getHeight(index);
            return Container(
              width: widget.barWidth,
              height: 30 * height,
              margin: EdgeInsets.only(
                right: index < widget.barCount - 1 ? widget.spacing : 0,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(0.7 + (height - 0.3) * 0.3),
                borderRadius: BorderRadius.circular(widget.barWidth / 2),
              ),
            );
          }),
        );
      },
    );
  }
}
