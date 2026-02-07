import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Wraps a child widget with a fade + slide-up entry animation.
/// Used for tab content transitions like the TechHub reference app.
class AnimatedPage extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const AnimatedPage({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: duration, curve: Curves.easeOut)
        .slideY(
          begin: 0.03,
          end: 0,
          duration: duration,
          curve: Curves.easeOut,
        );
  }
}

/// Animates a list item with staggered fade + slide entry.
/// index controls the stagger delay.
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration staggerDelay;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.staggerDelay = const Duration(milliseconds: 50),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: staggerDelay * index)
        .fadeIn(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        )
        .slideY(
          begin: 0.05,
          end: 0,
          duration: const Duration(milliseconds: 350),
          curve: const Cubic(0.4, 0, 0.2, 1),
        );
  }
}

/// Pulse animation for live status indicators
class PulsingDot extends StatelessWidget {
  final Color color;
  final double size;

  const PulsingDot({
    super.key,
    required this.color,
    this.size = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: const Duration(milliseconds: 800))
        .then()
        .fade(
          begin: 1.0,
          end: 0.4,
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOut,
        );
  }
}
