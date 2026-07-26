import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import 'app_button.dart';
import 'surfaces.dart';

/// Neutral placeholder block that breathes while content loads.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Skeleton stand-in for a list of cards.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 3, this.height = 96});

  final int count;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: Row(
                children: [
                  const ShimmerBox(width: 44, height: 44, radius: 14),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 140 + (i * 18), height: 13),
                        const SizedBox(height: 9),
                        const ShimmerBox(width: 90, height: 11),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Shared empty / error state. One layout means "nothing here yet" always
/// looks intentional rather than broken.
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.tone = ChipTone.neutral,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final ChipTone tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = switch (tone) {
      ChipTone.danger => AppColors.danger,
      ChipTone.warning => AppColors.warning,
      ChipTone.success => AppColors.success,
      _ => AppColors.faint,
    };

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 28,
          vertical: compact ? 28 : 56,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.cardShadow,
              ),
              child: Icon(icon, size: 27, color: accent),
            ),
            const SizedBox(height: 18),
            Text(title, style: AppText.title.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(height: 1.55),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                tone: AppButtonTone.neutral,
                size: AppButtonSize.compact,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-screen loader for route-level waits.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
          if (label != null) ...[
            const SizedBox(height: 16),
            Text(label!, style: AppText.caption),
          ],
        ],
      ),
    );
  }
}
