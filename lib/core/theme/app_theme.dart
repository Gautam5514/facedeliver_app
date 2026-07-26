import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Typography.
///
/// Sora ships upstream only as a variable font, so a weight is selected with a
/// `wght` font variation. `fontWeight` is set to the same value as well — it is
/// what the framework uses for fallback fonts and for synthetic bolding.
class AppText {
  const AppText._();

  static const String family = 'Sora';

  static TextStyle _sora({
    required double size,
    required int weight,
    double height = 1.4,
    double letterSpacing = 0,
    Color color = AppColors.ink,
    List<FontFeature>? features,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
      fontWeight: FontWeight.values[(weight ~/ 100) - 1],
      fontVariations: [FontVariation('wght', weight.toDouble())],
      fontFeatures: features,
    );
  }

  /// Small uppercase label above a heading — the product's signature "eyebrow".
  static final TextStyle eyebrow = _sora(
    size: 10,
    weight: 700,
    height: 1.2,
    letterSpacing: 2.0,
    color: AppColors.faint,
  );

  static final TextStyle display = _sora(
    size: 30,
    weight: 800,
    height: 1.15,
    letterSpacing: -0.8,
  );

  static final TextStyle title = _sora(
    size: 21,
    weight: 700,
    height: 1.22,
    letterSpacing: -0.4,
  );

  static final TextStyle heading = _sora(
    size: 16,
    weight: 700,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static final TextStyle body = _sora(
    size: 14,
    weight: 400,
    height: 1.5,
    color: AppColors.inkSoft,
  );

  static final TextStyle bodyStrong = _sora(size: 14, weight: 600, height: 1.4);

  static final TextStyle caption = _sora(
    size: 12,
    weight: 400,
    height: 1.4,
    color: AppColors.muted,
  );

  static final TextStyle micro = _sora(
    size: 11,
    weight: 500,
    height: 1.35,
    color: AppColors.faint,
  );

  /// Big tabular figures for stat cards — tabular so numbers do not jitter
  /// when they animate or refresh.
  static final TextStyle metric = _sora(
    size: 28,
    weight: 800,
    height: 1.05,
    letterSpacing: -1.0,
    features: const [FontFeature.tabularFigures()],
  );

  static final TextStyle button = _sora(
    size: 14,
    weight: 700,
    height: 1.2,
    letterSpacing: -0.1,
  );
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.ink,
      onPrimary: Colors.white,
      secondary: AppColors.inkSoft,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.danger,
      onError: Colors.white,
      outline: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppText.family,
      scaffoldBackgroundColor: AppColors.canvas,
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.heading,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.border,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: AppText.bodyStrong.copyWith(
          color: Colors.white,
          fontSize: 13,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.ink,
        linearTrackColor: AppColors.surfaceAlt,
        circularTrackColor: AppColors.surfaceAlt,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.ink,
        selectionColor: Color(0x2609090B),
        selectionHandleColor: AppColors.ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        hintStyle: AppText.body.copyWith(color: AppColors.ghost),
        border: _fieldBorder(AppColors.border),
        enabledBorder: _fieldBorder(AppColors.border),
        focusedBorder: _fieldBorder(AppColors.ink, width: 1.5),
        errorBorder: _fieldBorder(AppColors.dangerBorder),
        focusedErrorBorder: _fieldBorder(AppColors.danger, width: 1.5),
        errorStyle: AppText.micro.copyWith(color: AppColors.danger),
      ),
      textTheme: TextTheme(
        displaySmall: AppText.display,
        titleLarge: AppText.title,
        titleMedium: AppText.heading,
        bodyMedium: AppText.body,
        bodySmall: AppText.caption,
        labelSmall: AppText.micro,
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTokens.rMd),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
