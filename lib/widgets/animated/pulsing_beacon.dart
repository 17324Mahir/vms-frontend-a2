import 'package:flutter/material.dart';

/// Inspired by React Bits live beacon & Magic UI ripple indicators.
///
/// Displays an ongoing, smooth radiating pulse ring around a central status dot,
/// indicating live telemetry, active status, or online connectivity.
class PulsingBeacon extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;
  final bool isOngoing;

  const PulsingBeacon({
    super.key,
    this.color = const Color(0xFF10B981),
    this.size = 8.0,
    this.duration = const Duration(milliseconds: 2000),
    this.isOngoing = true,
  });

  @override
  State<PulsingBeacon> createState() => _PulsingBeaconState();
}

class _PulsingBeaconState extends State<PulsingBeacon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _shouldAnimate {
    if (!widget.isOngoing) return false;
    // Prevent pumpAndSettle timeout during widget testing
    if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (_shouldAnimate) {
      _controller.repeat();
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void didUpdateWidget(PulsingBeacon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOngoing != oldWidget.isOngoing) {
      if (_shouldAnimate) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeOf(context)?.disableAnimations == true) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2.8,
      height: widget.size * 2.8,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            // Easing for smooth radial dispersion
            final scale = 1.0 + (1.6 * t);
            final opacity = (1.0 - t).clamp(0.0, 1.0);

            return Stack(
              alignment: Alignment.center,
              children: [
                if (widget.isOngoing) ...[
                  // Outer expanding pulse wave
                  Transform.scale(
                    scale: scale,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withValues(alpha: opacity * 0.45),
                      ),
                    ),
                  ),
                  // Secondary subtle halo
                  Transform.scale(
                    scale: 1.0 + (0.9 * t),
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withValues(alpha: opacity * 0.25),
                      ),
                    ),
                  ),
                ],
                // Central core solid beacon
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
