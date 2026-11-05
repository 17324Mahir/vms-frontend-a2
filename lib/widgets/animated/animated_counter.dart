import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Inspired by Magic UI "Number Ticker".
///
/// Smoothly rolls numbers up from 0 (or previous value) to the target number
/// with a natural cubic ease-out curve, supporting currency and decimal formats.
class AnimatedCounter extends StatelessWidget {
  final num value;
  final String prefix;
  final String suffix;
  final int decimalDigits;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.decimalDigits = 0,
    this.style,
    this.duration = const Duration(milliseconds: 1400),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, currentValue, child) {
        String formattedNumber;
        if (decimalDigits > 0) {
          formattedNumber = NumberFormat.currency(
            symbol: '',
            decimalDigits: decimalDigits,
          ).format(currentValue);
        } else {
          formattedNumber = NumberFormat.decimalPattern().format(currentValue.round());
        }

        return Text(
          '$prefix$formattedNumber$suffix',
          style: style,
        );
      },
    );
  }
}

