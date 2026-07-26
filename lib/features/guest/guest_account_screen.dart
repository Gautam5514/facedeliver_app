import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/guest_repository.dart';
import '../../state/session_controller.dart';
import '../../widgets/app_button.dart';
import '../../widgets/feedback.dart';
import '../../widgets/surfaces.dart';

/// Account and privacy controls for a guest.
///
/// Erasure is a legal right here, not a settings nicety, so it gets a full
/// explanation of what disappears and a deliberate confirmation.
class GuestAccountScreen extends StatefulWidget {
  const GuestAccountScreen({super.key});

  @override
  State<GuestAccountScreen> createState() => _GuestAccountScreenState();
}

class _GuestAccountScreenState extends State<GuestAccountScreen> {
  bool _deleting = false;

  Future<void> _deleteMyData() async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete all my data',
      message:
          'This permanently removes everything FaceDeliver holds about you, '
          'across every event you registered for. It cannot be undone.',
      confirmLabel: 'Delete everything',
      icon: Icons.delete_forever_rounded,
      destructive: true,
      consequences: const [
        'Your selfie and face descriptor',
        'Every matched photo link in your gallery',
        'Your complete download history',
      ],
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    try {
      final message = await context.read<GuestRepository>().deleteMyData();
      if (!mounted) return;
      showSnack(context, message, tone: SnackTone.success);
      await context.read<SessionController>().signOut();
    } on ApiException catch (error) {
      if (mounted) showSnack(context, error.message, tone: SnackTone.danger);
    } catch (_) {
      if (mounted) {
        showSnack(
          context,
          'Deletion failed. Please try again.',
          tone: SnackTone.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await confirmAction(
      context,
      title: 'Sign out',
      message:
          'You can sign back in any time with the same email — your photos stay '
          'exactly where they are.',
      confirmLabel: 'Sign out',
      icon: Icons.logout_rounded,
    );
    if (!confirmed || !mounted) return;
    await context.read<SessionController>().signOut();
  }

  Future<void> _emailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppConfig.supportEmail,
      queryParameters: {'subject': 'FaceDeliver — help with my photos'},
    );
    if (!await launchUrl(uri) && mounted) {
      showSnack(
        context,
        'No email app found. Write to ${AppConfig.supportEmail}.',
        tone: SnackTone.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Account & privacy'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          AppCard(
            child: Row(
              children: [
                Avatar(label: user?.name ?? 'Guest', size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'Guest', style: AppText.bodyStrong),
                      const SizedBox(height: 3),
                      Text(
                        user?.email ?? '',
                        style: AppText.caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeading(
            eyebrow: 'Your data',
            title: 'How FaceDeliver treats it',
          ),
          const SizedBox(height: 14),
          const _FactRow(
            icon: Icons.face_retouching_natural_rounded,
            title: 'Face descriptor, not a face database',
            body:
                'Your selfie becomes a set of numbers used only to match you '
                'against event photos.',
          ),
          const _FactRow(
            icon: Icons.auto_delete_outlined,
            title: 'Deleted automatically',
            body:
                'All face data is permanently removed '
                '${AppConfig.retentionDays} days after each event.',
          ),
          const _FactRow(
            icon: Icons.lock_outline_rounded,
            title: 'Only your own photos',
            body:
                'Every download is checked against your matches — you can never '
                'reach another guest’s gallery.',
          ),
          const SizedBox(height: 24),
          const SectionHeading(eyebrow: 'Controls', title: 'Manage access'),
          const SizedBox(height: 14),
          AppButton(
            label: 'Contact support',
            icon: Icons.mail_outline_rounded,
            tone: AppButtonTone.neutral,
            onPressed: _emailSupport,
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'Sign out',
            icon: Icons.logout_rounded,
            tone: AppButtonTone.neutral,
            onPressed: _signOut,
          ),
          const SizedBox(height: 24),
          AppCard(
            borderColor: AppColors.dangerBorder,
            background: AppColors.dangerSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.delete_forever_rounded,
                      size: 18,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 9),
                    Text(
                      'Right to erasure',
                      style: AppText.bodyStrong.copyWith(
                        color: AppColors.danger,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  'Remove your selfie, face descriptor, matches and download '
                  'history from every event — immediately and permanently.',
                  style: AppText.caption.copyWith(
                    color: AppColors.danger,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Delete all my data',
                  icon: Icons.delete_outline_rounded,
                  tone: AppButtonTone.danger,
                  busy: _deleting,
                  onPressed: _deleteMyData,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 16, color: AppColors.inkSoft),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.bodyStrong.copyWith(fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(body, style: AppText.caption.copyWith(height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
