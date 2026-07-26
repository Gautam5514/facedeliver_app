import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// The base card: white, hairline border, soft lift. Every panel in the app is
/// one of these so nothing floats without a container.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.borderColor,
    this.background,
    this.radius = AppTokens.rLg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? background;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final decorated = Container(
      decoration: BoxDecoration(
        color: background ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return decorated;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: AppColors.ink.withValues(alpha: 0.04),
        highlightColor: AppColors.ink.withValues(alpha: 0.02),
        child: decorated,
      ),
    );
  }
}

/// Eyebrow + title, with an optional action on the right.
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    this.action,
  });

  final String eyebrow;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow.toUpperCase(), style: AppText.eyebrow),
              const SizedBox(height: 5),
              Text(title, style: AppText.title.copyWith(fontSize: 19)),
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 12), action!],
      ],
    );
  }
}

enum ChipTone { neutral, success, warning, danger, ink }

/// Small status pill — plan state, processing state, match counts.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = ChipTone.neutral,
    this.icon,
  });

  final String label;
  final ChipTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, border) = switch (tone) {
      ChipTone.neutral => (
          AppColors.surfaceAlt,
          AppColors.muted,
          AppColors.border
        ),
      ChipTone.success => (
          AppColors.successSoft,
          AppColors.success,
          AppColors.successBorder
        ),
      ChipTone.warning => (
          AppColors.warningSoft,
          AppColors.warning,
          AppColors.warningBorder
        ),
      ChipTone.danger => (
          AppColors.dangerSoft,
          AppColors.danger,
          AppColors.dangerBorder
        ),
      ChipTone.ink => (AppColors.ink, Colors.white, AppColors.ink),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTokens.rPill),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppText.micro.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Square-ish monogram tile used wherever an event needs an identity.
class EventMonogram extends StatelessWidget {
  const EventMonogram({
    super.key,
    required this.label,
    this.size = 40,
    this.selected = true,
  });

  final String label;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final letter =
        label.trim().isNotEmpty ? label.trim()[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.ink : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Text(
        letter,
        style: AppText.bodyStrong.copyWith(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w800,
          color: selected ? Colors.white : AppColors.muted,
        ),
      ),
    );
  }
}

/// Inline explanatory banner — quota warnings, processing notices, consent.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.info_outline_rounded,
    this.tone = ChipTone.neutral,
    this.action,
  });

  final String message;
  final String? title;
  final IconData icon;
  final ChipTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, border) = switch (tone) {
      ChipTone.success => (
          AppColors.successSoft,
          AppColors.success,
          AppColors.successBorder
        ),
      ChipTone.warning => (
          AppColors.warningSoft,
          AppColors.warning,
          AppColors.warningBorder
        ),
      ChipTone.danger => (
          AppColors.dangerSoft,
          AppColors.danger,
          AppColors.dangerBorder
        ),
      _ => (AppColors.surfaceAlt, AppColors.inkSoft, AppColors.border),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: foreground),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: AppText.bodyStrong
                        .copyWith(fontSize: 13, color: foreground),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  message,
                  style: AppText.caption.copyWith(
                    color: tone == ChipTone.neutral
                        ? AppColors.muted
                        : foreground.withValues(alpha: 0.9),
                    height: 1.45,
                  ),
                ),
                if (action != null) ...[const SizedBox(height: 10), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal progress track used for upload quota and upload progress.
class ProgressTrack extends StatelessWidget {
  const ProgressTrack({
    super.key,
    required this.percent,
    this.color = AppColors.ink,
    this.height = 8,
  });

  final int percent;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.rPill),
      child: Stack(
        children: [
          Container(height: height, color: AppColors.surfaceAlt),
          AnimatedFractionallySizedBox(
            duration: AppTokens.slow,
            curve: Curves.easeOutCubic,
            widthFactor: (percent.clamp(0, 100)) / 100,
            child: Container(height: height, color: color),
          ),
        ],
      ),
    );
  }
}

/// Circular avatar backed by a remote image, falling back to a monogram.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.label,
    this.imageUrl,
    this.size = 42,
  });

  final String label;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter =
        label.trim().isNotEmpty ? label.trim()[0].toUpperCase() : '?';

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.ink,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: imageUrl == null
          ? Center(
              child: Text(
                letter,
                style: AppText.bodyStrong.copyWith(
                  color: Colors.white,
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  letter,
                  style: AppText.bodyStrong.copyWith(
                    color: Colors.white,
                    fontSize: size * 0.38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
    );
  }
}
