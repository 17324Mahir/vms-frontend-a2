import 'package:flutter/material.dart';

/// Inspired by Magic UI's "Dot Pattern" & "Grid Pattern".
///
/// Renders a subtle, clean geometric dot matrix or grid pattern
/// behind content to establish high-end depth and architectural elegance.
class AmbientGridPattern extends StatelessWidget {
  final Widget? child;
  final double spacing;
  final double dotRadius;
  final Color dotColor;
  final bool showGridLines;

  const AmbientGridPattern({
    super.key,
    this.child,
    this.spacing = 28.0,
    this.dotRadius = 1.2,
    this.dotColor = const Color(0xFFCBD5E1),
    this.showGridLines = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AmbientPatternPainter(
        spacing: spacing,
        dotRadius: dotRadius,
        dotColor: dotColor,
        showGridLines: showGridLines,
      ),
      child: child,
    );
  }
}

class _AmbientPatternPainter extends CustomPainter {
  final double spacing;
  final double dotRadius;
  final Color dotColor;
  final bool showGridLines;

  _AmbientPatternPainter({
    required this.spacing,
    required this.dotRadius,
    required this.dotColor,
    required this.showGridLines,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..isAntiAlias = true;

    if (showGridLines) {
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 0.5;

      for (double x = 0; x <= size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else {
      paint.style = PaintingStyle.fill;
      for (double x = spacing / 2; x <= size.width; x += spacing) {
        for (double y = spacing / 2; y <= size.height; y += spacing) {
          canvas.drawCircle(Offset(x, y), dotRadius, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_AmbientPatternPainter oldDelegate) {
    return oldDelegate.spacing != spacing ||
        oldDelegate.dotRadius != dotRadius ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.showGridLines != showGridLines;
  }
}

