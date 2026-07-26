import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/event_models.dart';
import '../../../widgets/surfaces.dart';

/// One event in a list: identity, headline counts, and a way in.
class EventRow extends StatelessWidget {
  const EventRow({super.key, required this.event, required this.onTap});

  final EventSummary event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          EventMonogram(label: event.name, size: 44),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: AppText.bodyStrong.copyWith(fontSize: 14.5),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  event.code,
                  style: AppText.micro,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    _Metric(
                      icon: Icons.groups_rounded,
                      value: event.guestCount,
                      label: 'guests',
                    ),
                    const SizedBox(width: 14),
                    _Metric(
                      icon: Icons.photo_library_rounded,
                      value: event.photoCount,
                      label: 'photos',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppColors.ghost,
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.faint),
        const SizedBox(width: 5),
        Text(
          '${Format.count(value)} $label',
          style: AppText.micro.copyWith(fontSize: 11.5),
        ),
      ],
    );
  }
}
