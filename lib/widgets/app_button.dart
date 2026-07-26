import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

enum AppButtonTone { primary, neutral, ghost, danger }

enum AppButtonSize { regular, compact }

/// The single button in the app. Tone changes the palette, never the shape —
/// that consistency is what makes the surface feel designed rather than
/// assembled.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.tone = AppButtonTone.primary,
    this.size = AppButtonSize.regular,
    this.busy = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonTone tone;
  final AppButtonSize size;
  final bool busy;
  final bool expand;

  bool get _enabled => onPressed != null && !busy;

  @override
  Widget build(BuildContext context) {
    final palette = _palette;
    final height = size == AppButtonSize.regular ? 52.0 : 42.0;
    final radius = size == AppButtonSize.regular ? AppTokens.rMd : AppTokens.rSm;

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(palette.foreground),
            ),
          )
        else if (icon != null)
          Icon(icon, size: size == AppButtonSize.regular ? 18 : 16),
        if (busy || icon != null) const SizedBox(width: 9),
        Flexible(
          child: Text(
            busy ? 'Please wait…' : label,
            overflow: TextOverflow.ellipsis,
            style: AppText.button.copyWith(
              fontSize: size == AppButtonSize.regular ? 14.5 : 13,
              color: palette.foreground,
            ),
          ),
        ),
      ],
    );

    return Opacity(
      opacity: _enabled ? 1 : 0.45,
      child: SizedBox(
        height: height,
        width: expand ? double.infinity : null,
        child: Material(
          color: palette.background,
          borderRadius: BorderRadius.circular(radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _enabled ? onPressed : null,
            splashColor: palette.foreground.withValues(alpha: 0.08),
            highlightColor: palette.foreground.withValues(alpha: 0.04),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: palette.border == null
                    ? null
                    : Border.all(color: palette.border!),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size == AppButtonSize.regular ? 22 : 16,
                ),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ({Color background, Color foreground, Color? border}) get _palette =>
      switch (tone) {
        AppButtonTone.primary => (
            background: AppColors.ink,
            foreground: Colors.white,
            border: null,
          ),
        AppButtonTone.neutral => (
            background: AppColors.surface,
            foreground: AppColors.ink,
            border: AppColors.border,
          ),
        AppButtonTone.ghost => (
            background: Colors.transparent,
            foreground: AppColors.muted,
            border: null,
          ),
        AppButtonTone.danger => (
            background: AppColors.danger,
            foreground: Colors.white,
            border: null,
          ),
      };
}

/// Compact circular icon button used in app bars and photo overlays.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.busy = false,
    this.onDark = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool busy;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final foreground = onDark ? Colors.white : AppColors.inkSoft;
    final background =
        onDark ? Colors.white.withValues(alpha: 0.12) : AppColors.surface;
    final border =
        onDark ? Colors.white.withValues(alpha: 0.16) : AppColors.border;

    final button = SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: background,
        shape: CircleBorder(side: BorderSide(color: border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy ? null : onPressed,
          child: Center(
            child: busy
                ? SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(foreground),
                    ),
                  )
                : Icon(icon, size: 18, color: foreground),
          ),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
