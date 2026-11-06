import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Keeps record details readable beside actions, or above them on small panes.
class WorkspaceRecordCard extends StatelessWidget {
  const WorkspaceRecordCard({
    super.key,
    required this.leading,
    required this.details,
    required this.actions,
  });

  final Widget leading;
  final Widget details;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final summary = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
                const SizedBox(width: AppTheme.space12),
                Expanded(child: details),
              ],
            );
            final controls = Wrap(
              spacing: AppTheme.space4,
              runSpacing: AppTheme.space4,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: actions,
            );
            if (constraints.maxWidth < 590) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  summary,
                  const SizedBox(height: AppTheme.space8),
                  controls,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: summary),
                const SizedBox(width: AppTheme.space16),
                controls,
              ],
            );
          },
        ),
      ),
    );
  }
}
