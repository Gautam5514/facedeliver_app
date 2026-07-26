import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/billing_models.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/surfaces.dart';

/// Upload capacity for the current billing period.
///
/// Billing is enforced in the upload path, so this is not decoration: at zero
/// remaining uploads the organiser is blocked mid-event. It states the number
/// plainly and escalates colour as the ceiling approaches.
class QuotaCard extends StatelessWidget {
  const QuotaCard({super.key, required this.billing, this.onManage});

  final BillingStatus billing;

  /// Null on the billing screen itself, where "manage plan" would lead nowhere.
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    if (!billing.hasPlan) return _noPlan();

    final subscription = billing.subscription!;
    final usage = billing.usage!;
    final percent = billing.usagePercent;

    final (tone, accent, headline) = switch (percent) {
      >= 90 => (
          ChipTone.danger,
          AppColors.danger,
          'Almost out of capacity',
        ),
      >= 70 => (
          ChipTone.warning,
          AppColors.warning,
          'Capacity getting tight',
        ),
      _ => (ChipTone.success, AppColors.success, 'Capacity is healthy'),
    };

    final daysLeft = subscription.daysRemaining;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('UPLOAD CAPACITY', style: AppText.eyebrow),
                    const SizedBox(height: 5),
                    Text(headline, style: AppText.title.copyWith(fontSize: 17)),
                  ],
                ),
              ),
              StatusChip(label: subscription.planName, tone: ChipTone.ink),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                Format.count(usage.remainingUploads),
                style: AppText.metric.copyWith(color: accent),
              ),
              const SizedBox(width: 7),
              Text(
                'of ${Format.count(subscription.uploadLimit)} left',
                style: AppText.caption,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressTrack(percent: percent, color: accent),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${Format.count(usage.usedUploads)} uploaded this period',
                  style: AppText.micro,
                ),
              ),
              if (daysLeft != null)
                Text(
                  daysLeft == 0
                      ? 'Renews today'
                      : 'Renews in ${Format.plural(daysLeft, 'day')}',
                  style: AppText.micro,
                ),
            ],
          ),
          if (tone != ChipTone.success && onManage != null) ...[
            const SizedBox(height: 14),
            AppButton(
              label: 'Manage plan',
              icon: Icons.credit_card_rounded,
              tone: AppButtonTone.neutral,
              size: AppButtonSize.compact,
              onPressed: onManage,
            ),
          ],
        ],
      ),
    );
  }

  Widget _noPlan() {
    return AppCard(
      borderColor: AppColors.warningBorder,
      background: AppColors.warningSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_outlined,
                size: 18,
                color: AppColors.warning,
              ),
              const SizedBox(width: 9),
              Text(
                'No active plan',
                style: AppText.bodyStrong.copyWith(
                  color: AppColors.warning,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            'Photo uploads are blocked until a plan is active. Everything else — '
            'events, QR codes and guest registration — keeps working.',
            style: AppText.caption.copyWith(
              color: AppColors.warning,
              height: 1.5,
            ),
          ),
          if (onManage != null) ...[
            const SizedBox(height: 16),
            AppButton(
              label: 'Choose a plan',
              icon: Icons.arrow_forward_rounded,
              size: AppButtonSize.compact,
              onPressed: onManage,
            ),
          ],
        ],
      ),
    );
  }
}
