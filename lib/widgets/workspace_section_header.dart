import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// The introduction for a fleet workspace page.
class WorkspaceSectionHeader extends StatelessWidget {
  const WorkspaceSectionHeader({
    super.key,
    required this.label,
    required this.title,
    required this.description,
    this.actions,
    this.badge,
  });

  final String label;
  final String title;
  final String description;
  final Widget? actions;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        gradient: AppTheme.workspaceHeroGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Wrap(
        spacing: AppTheme.space24,
        runSpacing: AppTheme.space12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 590),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.onNavyLabel,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: AppTheme.space8),
                Wrap(
                  spacing: AppTheme.space12,
                  runSpacing: AppTheme.space8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ),
                    ?badge,
                  ],
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.onNavyMuted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          ?actions,
        ],
      ),
    );
  }
}
