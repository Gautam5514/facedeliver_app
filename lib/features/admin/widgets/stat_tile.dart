import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/surfaces.dart';

/// A single headline number with its label and one line of context.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.caption,
    this.tone = ChipTone.neutral,
  });

  final String label;
  final int value;
  final IconData icon;
  final String? caption;
  final ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final accent = switch (tone) {
      ChipTone.success => AppColors.success,
      ChipTone.warning => AppColors.warning,
      ChipTone.danger => AppColors.danger,
      _ => AppColors.inkSoft,
    };

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppText.eyebrow,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 15, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(Format.count(value), style: AppText.metric.copyWith(fontSize: 25)),
          if (caption != null) ...[
            const SizedBox(height: 5),
            Text(
              caption!,
              style: AppText.micro,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// Two-column grid of stat tiles that keeps a consistent tile height.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.32,
      children: tiles,
    );
  }
}
