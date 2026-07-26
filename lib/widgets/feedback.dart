import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import 'app_button.dart';

enum SnackTone { neutral, success, danger }

/// One toast style for the whole app: dark pill, icon, single line of copy.
void showSnack(
  BuildContext context,
  String message, {
  SnackTone tone = SnackTone.neutral,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  final (icon, accent) = switch (tone) {
    SnackTone.success => (Icons.check_circle_rounded, AppColors.success),
    SnackTone.danger => (Icons.error_rounded, AppColors.danger),
    SnackTone.neutral => (Icons.info_rounded, Colors.white70),
  };

  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        duration: Duration(seconds: tone == SnackTone.danger ? 5 : 3),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.rMd),
        ),
        content: Row(
          children: [
            Icon(icon, size: 17, color: accent),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                message,
                style: AppText.bodyStrong.copyWith(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}

/// Bottom-sheet confirmation for destructive or irreversible actions.
/// Returns true only when the user explicitly confirms.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  IconData icon = Icons.warning_amber_rounded,
  bool destructive = false,
  List<String> consequences = const [],
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: destructive
                        ? AppColors.dangerSoft
                        : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: destructive ? AppColors.danger : AppColors.inkSoft,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(title, style: AppText.title.copyWith(fontSize: 18)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(message, style: AppText.body.copyWith(height: 1.55)),
            if (consequences.isNotEmpty) ...[
              const SizedBox(height: 14),
              for (final item in consequences)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.remove_rounded,
                        size: 14,
                        color: destructive ? AppColors.danger : AppColors.faint,
                      ),
                      const SizedBox(width: 9),
                      Expanded(child: Text(item, style: AppText.caption)),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: cancelLabel,
                    tone: AppButtonTone.neutral,
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: confirmLabel,
                    tone: destructive
                        ? AppButtonTone.danger
                        : AppButtonTone.primary,
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  return result ?? false;
}
