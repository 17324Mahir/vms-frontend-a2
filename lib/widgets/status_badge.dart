import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import 'animated/pulsing_beacon.dart';

/// Reusable status badge chip implementing Stark Group accessible status treatments.
///
/// Combines a distinct colored border, tint background, indicator dot,
/// and clear text label so status meaning does not rely on color alone.
class StatusBadge extends StatelessWidget {
  final VehicleStatus status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Status: ${status.label}',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: status.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: status.borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == VehicleStatus.active)
              PulsingBeacon(
                color: status.dotColor,
                size: compact ? 5 : 6,
                isOngoing: true,
              )
            else
              Container(
                width: compact ? 5 : 6,
                height: compact ? 5 : 6,
                decoration: BoxDecoration(
                  color: status.dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                status.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: status.textColor,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

