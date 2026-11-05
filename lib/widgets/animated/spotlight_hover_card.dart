import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'border_beam.dart';

/// Inspired by React Bits Spotlight & 21st.dev modern interactive cards.
///
/// Features smooth 60fps hover elevation, animated border glow,
/// subtle ambient shadow diffusion, and optional continuous border beam.
class SpotlightHoverCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color backgroundColor;
  final Color borderColor;
  final Color? hoverBorderColor;
  final VoidCallback? onTap;
  final bool hasBorderBeam;
  final Color? beamColor;
  final Color? beamAccentColor;
  final double liftDistance;

  const SpotlightHoverCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.space16),
    this.borderRadius = 14.0,
    this.backgroundColor = Colors.white,
    this.borderColor = AppTheme.borderNeutral,
    this.hoverBorderColor,
    this.onTap,
    this.hasBorderBeam = false,
    this.beamColor,
    this.beamAccentColor,
    this.liftDistance = 3.0,
  });

  @override
  State<SpotlightHoverCard> createState() => _SpotlightHoverCardState();
}

class _SpotlightHoverCardState extends State<SpotlightHoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeHoverBorder = widget.hoverBorderColor ?? AppTheme.primaryBlue.withValues(alpha: 0.6);

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(
        0,
        _isHovered ? -widget.liftDistance : 0,
        0,
      ),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: widget.hasBorderBeam
            ? null
            : Border.all(
                color: _isHovered ? activeHoverBorder : widget.borderColor,
                width: _isHovered ? 1.5 : 1.0,
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.02),
            blurRadius: _isHovered ? 18 : 6,
            offset: Offset(0, _isHovered ? 8 : 2),
          ),
          if (_isHovered)
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: widget.child,
    );

    if (widget.hasBorderBeam) {
      content = BorderBeam(
        borderRadius: widget.borderRadius,
        baseBorderColor: _isHovered ? activeHoverBorder : widget.borderColor,
        beamColor: widget.beamColor ?? AppTheme.primaryBlue,
        accentColor: widget.beamAccentColor ?? const Color(0xFF818CF8),
        child: content,
      );
    }

    if (widget.onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          onTap: widget.onTap,
          child: content,
        ),
      );
    }

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: content,
    );
  }
}

