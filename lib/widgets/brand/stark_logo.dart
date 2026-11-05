import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum StarkLogoSize {
  small(28, 13, 9),
  medium(36, 15, 10),
  large(48, 20, 12);

  final double emblemSize;
  final double titleFontSize;
  final double subtitleFontSize;

  const StarkLogoSize(this.emblemSize, this.titleFontSize, this.subtitleFontSize);
}

enum StarkLogoVariant {
  /// For dark backgrounds (deep navy navbar, sidebar, dark sheets).
  dark,

  /// For light backgrounds (white cards, canvas, dialogs).
  light,
}

/// Unified, professional Stark Group Brand Logo with custom geometric S-crest emblem.
///
/// Designed to provide consistent corporate identity across:
/// - Navigation bars and sidebars
/// - Authentication cards (Login, Register, Password Reset)
/// - Home landing page hero and drawer
class StarkLogo extends StatelessWidget {
  final StarkLogoSize size;
  final StarkLogoVariant variant;
  final String title;
  final String? subtitle;
  final String? badge;
  final bool showBadge;
  final bool showSubtitle;
  final bool isCentered;
  final VoidCallback? onTap;

  const StarkLogo({
    super.key,
    this.size = StarkLogoSize.medium,
    this.variant = StarkLogoVariant.dark,
    this.title = 'STARK GROUP',
    this.subtitle = 'Vehicle Management System',
    this.badge = 'VMS',
    this.showBadge = true,
    this.showSubtitle = true,
    this.isCentered = false,
    this.onTap,
  });

  /// Convenient factory for dark surfaces (navbar, sidebar).
  const StarkLogo.dark({
    super.key,
    this.size = StarkLogoSize.medium,
    this.title = 'STARK GROUP',
    this.subtitle = 'Vehicle Management System',
    this.badge = 'VMS',
    this.showBadge = true,
    this.showSubtitle = true,
    this.isCentered = false,
    this.onTap,
  }) : variant = StarkLogoVariant.dark;

  /// Convenient factory for light surfaces (cards, canvas).
  const StarkLogo.light({
    super.key,
    this.size = StarkLogoSize.medium,
    this.title = 'STARK GROUP',
    this.subtitle = 'Vehicle Management System',
    this.badge = 'VMS',
    this.showBadge = true,
    this.showSubtitle = true,
    this.isCentered = false,
    this.onTap,
  }) : variant = StarkLogoVariant.light;

  @override
  Widget build(BuildContext context) {
    final isDark = variant == StarkLogoVariant.dark;
    final primaryTextColor = isDark ? Colors.white : AppTheme.textDark;
    final subtitleTextColor = isDark ? const Color(0xFF94A3B8) : AppTheme.textMuted;
    final badgeBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF);
    final badgeTextColor = isDark ? const Color(0xFF38BDF8) : AppTheme.primaryBlue;
    final badgeBorder = isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Geometric Emblem
        StarkEmblem(size: size.emblemSize),
        const SizedBox(width: 12),

        // Text & Descriptor
        Flexible(
          child: Column(
            crossAxisAlignment: isCentered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: size.titleFontSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        height: 1.15,
                      ),
                    ),
                  ),
                  if (showBadge && badge != null && badge!.isNotEmpty) ...[
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: badgeBorder, width: 0.8),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          color: badgeTextColor,
                          fontSize: size.titleFontSize * 0.68,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (showSubtitle && subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtitleTextColor,
                    fontSize: size.subtitleFontSize,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                    height: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Standalone aerodynamic geometric Stark Emblem.
/// Scales seamlessly from 24px to 128px using custom anti-aliased vector paths.
class StarkEmblem extends StatelessWidget {
  final double size;

  const StarkEmblem({
    super.key,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A), // Slate 900
            Color(0xFF1E3A8A), // Blue 900
            Color(0xFF2563EB), // Blue 600
          ],
        ),
        border: Border.all(
          color: const Color(0x4038BDF8), // Subtle cyan rim light
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.26),
        child: CustomPaint(
          size: Size(size, size),
          painter: const _StarkEmblemPainter(),
        ),
      ),
    );
  }
}

class _StarkEmblemPainter extends CustomPainter {
  const _StarkEmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Subtle background speed lines / geometric lattice
    final linePaint = Paint()
      ..color = const Color(0x1AFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(w * 0.15, h * 0.85), Offset(w * 0.85, h * 0.15), linePaint);

    // Dynamic Futuristic "S" Monogram Vector
    final path = Path();

    // Upper Wing of "S"
    path.moveTo(w * 0.32, h * 0.22);
    path.lineTo(w * 0.74, h * 0.22);
    path.lineTo(w * 0.74, h * 0.36);
    path.lineTo(w * 0.44, h * 0.36);
    path.lineTo(w * 0.58, h * 0.52);
    path.lineTo(w * 0.74, h * 0.52);
    path.lineTo(w * 0.74, h * 0.78);
    path.lineTo(w * 0.26, h * 0.78);
    path.lineTo(w * 0.26, h * 0.64);
    path.lineTo(w * 0.56, h * 0.64);
    path.lineTo(w * 0.42, h * 0.48);
    path.lineTo(w * 0.26, h * 0.48);
    path.lineTo(w * 0.26, h * 0.32);
    path.close();

    // High-contrast clean white and electric-cyan gradient fill
    final gradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white,
        Color(0xFFE0F2FE), // Sky 100
        Color(0xFF38BDF8), // Sky 400
      ],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final fillPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path, fillPaint);

    // Inner energetic core accent dot (Arc-Reactor node)
    final nodePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.5, h * 0.5), size.width * 0.05, nodePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
