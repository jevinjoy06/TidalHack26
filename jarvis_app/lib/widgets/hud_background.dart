import 'dart:ui';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

/// Figma-style HUD background: concentric circles, grid, scanning arc, corner brackets.
class HudBackground extends StatelessWidget {
  const HudBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.3,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return CustomPaint(
              painter: _HudPainter(),
              size: Size(constraints.maxWidth, constraints.maxHeight),
            );
          },
        ),
      ),
    );
  }
}

class _HudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.shortestSide * 0.45;

    final accentPaint = Paint()
      ..color = AppTheme.figmaAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    final secondaryPaint = Paint()
      ..color = AppTheme.figmaSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Concentric circles
    for (final r in [maxR, maxR * 0.8, maxR * 0.6, maxR * 0.4]) {
      canvas.drawCircle(center, r, r > maxR * 0.5 ? accentPaint : secondaryPaint);
    }
    accentPaint.strokeWidth = 0.3;
    accentPaint.color = AppTheme.figmaAccent.withOpacity(0.2);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), accentPaint);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), accentPaint);
    secondaryPaint.strokeWidth = 0.3;
    secondaryPaint.color = AppTheme.figmaSecondary.withOpacity(0.2);
    final d = maxR * 0.7;
    canvas.drawLine(
      Offset(center.dx - d, center.dy - d),
      Offset(center.dx + d, center.dy + d),
      secondaryPaint,
    );
    canvas.drawLine(
      Offset(center.dx + d, center.dy - d),
      Offset(center.dx - d, center.dy + d),
      secondaryPaint,
    );
    // Scanning arc
    accentPaint.strokeWidth = 1.5;
    accentPaint.color = AppTheme.figmaAccent.withOpacity(0.6);
    final rect = Rect.fromCircle(center: center, radius: maxR);
    canvas.drawArc(rect, -1.57, 1.0, false, accentPaint);
    // Corner brackets
    final bracketPaint = Paint()
      ..color = AppTheme.figmaSecondary.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const b = 60.0;
    canvas.drawPath(
      Path()
        ..moveTo(b, b)..lineTo(b, b + 50)..moveTo(b, b)..lineTo(b + 50, b),
      bracketPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - b, b)..lineTo(size.width - b, b + 50)..moveTo(size.width - b, b)..lineTo(size.width - b - 50, b),
      bracketPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(b, size.height - b)..lineTo(b, size.height - b - 50)..moveTo(b, size.height - b)..lineTo(b + 50, size.height - b),
      bracketPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - b, size.height - b)..lineTo(size.width - b, size.height - b - 50)..moveTo(size.width - b, size.height - b)..lineTo(size.width - b - 50, size.height - b),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
