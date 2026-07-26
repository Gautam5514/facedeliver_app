import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// The FaceDeliver mark, shared with the web app.
///
/// The artwork is transparent, so it sits directly on whatever surface it is
/// placed on rather than inside a coloured chip.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/mark.png',
      width: size,
      height: size,
      // Decode near the display size — the source is 512px square and would
      // otherwise cost far more memory than it needs to at 40dp.
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
      filterQuality: FilterQuality.medium,
    );
  }
}

/// Mark plus wordmark, used wherever the product introduces itself.
class BrandLockup extends StatelessWidget {
  const BrandLockup({
    super.key,
    this.size = 34,
    this.onDark = false,
    this.tagline,
  });

  final double size;
  final bool onDark;
  final String? tagline;

  @override
  Widget build(BuildContext context) {
    final foreground = onDark ? Colors.white : AppColors.ink;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: size),
        SizedBox(width: size * 0.26),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppConfig.appName,
              style: AppText.title.copyWith(
                fontSize: size * 0.56,
                color: foreground,
                letterSpacing: -0.6,
              ),
            ),
            if (tagline != null)
              Text(
                tagline!.toUpperCase(),
                style: AppText.eyebrow.copyWith(
                  fontSize: size * 0.24,
                  color: onDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppColors.faint,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
