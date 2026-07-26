import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/brand_mark.dart';

/// Shown only while the stored session is read from the keychain — a few
/// hundred milliseconds. It carries the brand rather than a bare spinner.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 84),
            const SizedBox(height: 16),
            Text(AppConfig.appName, style: AppText.title),
            const SizedBox(height: 6),
            Text('Your photos, found by your face', style: AppText.caption),
            const SizedBox(height: 34),
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
