import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Reusable modal confirmation dialog for destructive or critical actions.
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
  });

  /// Generic confirmation dialog helper.
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ConfirmationDialog(
        title: title,
        isDestructive: isDestructive,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textDark,
            height: 1.5,
          ),
        ),
      ),
    );
    return result ?? false;
  }

  /// Displays a delete confirmation dialog identifying the vehicle by its vehicle number.
  static Future<bool> showDelete(
    BuildContext context, {
    required String vehicleNumber,
    required String company,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Vehicle',
        isDestructive: true,
        confirmLabel: 'Delete Vehicle',
        cancelLabel: 'Keep Vehicle',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textDark,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'Are you sure you want to delete vehicle '),
                  TextSpan(
                    text: vehicleNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' belonging to $company?'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: AppTheme.errorRedBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.errorRedBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: AppTheme.errorRed),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action permanently removes the vehicle from the fleet registry.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.errorRed,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  /// Displays an unsaved changes confirmation dialog.
  static Future<bool> showDiscard(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const ConfirmationDialog(
        title: 'Discard Unsaved Changes?',
        isDestructive: true,
        confirmLabel: 'Discard Changes',
        cancelLabel: 'Continue Editing',
        content: Text(
          'You have unsaved changes on this form. If you leave now, all your inputs will be lost.',
          style: TextStyle(fontSize: 14, color: AppTheme.textDark, height: 1.5),
        ),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: const BorderSide(color: AppTheme.borderNeutral),
      ),
      backgroundColor: AppTheme.surfaceWhite,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textDark,
        ),
      ),
      content: content,
      actionsPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space24,
        vertical: AppTheme.space16,
      ),
      actions: [
        OutlinedButton(
          autofocus: !isDestructive,
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          autofocus: isDestructive,
          style: isDestructive
              ? ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorRed,
                  foregroundColor: Colors.white,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
