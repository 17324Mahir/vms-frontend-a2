import 'package:flutter/material.dart';

/// Helper utility and widget for building responsive web and desktop layouts.
class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  /// Mobile breakpoint (< 768px)
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 768;

  /// Tablet breakpoint (>= 768px and < 1100px)
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 768 &&
      MediaQuery.sizeOf(context).width < 1100;

  /// Desktop breakpoint (>= 1100px)
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1100;

  /// Returns responsive value based on current screen size.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return desktop;
    if (width >= 768 && tablet != null) return tablet;
    return mobile;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) {
      return desktop;
    } else if (width >= 768 && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}
