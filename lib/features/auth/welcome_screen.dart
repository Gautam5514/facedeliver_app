import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/brand_mark.dart';
import 'widgets/photo_wall.dart';

/// The landing page. Two audiences use this app for opposite reasons, so the
/// first decision is which one you are — everything after that is tailored.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    // Tall enough to feel like a hero, never so tall that the role cards fall
    // below the fold on a small phone.
    final heroHeight = (screenHeight * 0.36).clamp(240.0, 330.0);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 14, 24, 12),
                child: BrandLockup(size: 34, tagline: 'Event photo delivery'),
              ),
            ),
            SliverToBoxAdapter(child: PhotoWall(height: heroHeight)),
            SliverToBoxAdapter(
              child: Padding(
                // The wall's gradient already resolves to the canvas colour,
                // so the copy can sit straight underneath it. Nothing is
                // offset into the imagery — small type over event photos is
                // unreadable, and the lockup above already carries the
                // "event photo delivery" line.
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Every photo\nyou are in.',
                      style: AppText.display.copyWith(
                        fontSize: 36,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Scan the QR code at your event, take one selfie, and '
                      'your photos arrive automatically. No scrolling '
                      'through thousands of strangers.',
                      style: AppText.body.copyWith(height: 1.6),
                    ),
                    const SizedBox(height: 18),
                    const _TrustRow(),
                    const SizedBox(height: 24),
                    _RoleCard(
                      eyebrow: 'For guests',
                      title: 'Find my photos',
                      description:
                          'Scan your event QR code, or sign in with the '
                          'email you registered with.',
                      icon: Icons.qr_code_scanner_rounded,
                      primary: true,
                      onTap: () => context.push(Routes.scan),
                      secondaryLabel: 'Already registered? Sign in',
                      onSecondary: () => context.push(Routes.guestLogin),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      eyebrow: 'For organisers',
                      title: 'Manage my events',
                      description:
                          'Upload galleries, track delivery, and let '
                          'matching reach every guest.',
                      icon: Icons.camera_alt_rounded,
                      primary: false,
                      onTap: () => context.push(Routes.adminAuth),
                    ),
                    const SizedBox(height: 22),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 13,
                            color: AppColors.ghost,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Face data deleted ${AppConfig.retentionDays} days after each event',
                              style: AppText.micro,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20 + MediaQuery.paddingOf(context).bottom),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three short proof points — concrete promises without a feature list.
class _TrustRow extends StatelessWidget {
  const _TrustRow();

  static const _items = <(IconData, String)>[
    (Icons.bolt_rounded, 'Instant'),
    (Icons.face_retouching_natural_rounded, 'Face-matched'),
    (Icons.lock_outline_rounded, 'Private'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (icon, label) in _items)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.rPill),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 13, color: AppColors.inkSoft),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppText.micro.copyWith(
                      fontSize: 11.5,
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w600,
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.primary,
    required this.onTap,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final background = primary ? AppColors.ink : AppColors.surface;
    final foreground = primary ? Colors.white : AppColors.ink;
    final subdued = primary
        ? Colors.white.withValues(alpha: 0.62)
        : AppColors.muted;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppTokens.rXl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.rXl),
            border: Border.all(
              color: primary ? AppColors.ink : AppColors.border,
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primary
                          ? Colors.white.withValues(alpha: 0.12)
                          : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, size: 19, color: foreground),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eyebrow.toUpperCase(),
                          style: AppText.eyebrow.copyWith(color: subdued),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: AppText.title.copyWith(
                            fontSize: 18,
                            color: foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, size: 18, color: subdued),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: AppText.caption.copyWith(color: subdued, height: 1.5),
              ),
              if (secondaryLabel != null && onSecondary != null) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: onSecondary,
                  borderRadius: BorderRadius.circular(AppTokens.rSm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          secondaryLabel!,
                          style: AppText.bodyStrong.copyWith(
                            fontSize: 13,
                            color: foreground,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: foreground,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
