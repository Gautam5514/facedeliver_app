import 'package:flutter/material.dart';

/// FaceDeliver palette — a restrained monochrome scale (zinc) with three
/// semantic accents. Mirrors the web app so both surfaces read as one product.
class AppColors {
  const AppColors._();

  // ── Neutrals ──────────────────────────────────────────────────────────────
  static const canvas = Color(0xFFFAFAFA); // page background  (zinc-50)
  static const surface = Color(0xFFFFFFFF); // cards
  static const surfaceAlt = Color(0xFFF4F4F5); // inset fills    (zinc-100)
  static const border = Color(0xFFE4E4E7); // hairlines        (zinc-200)
  static const borderStrong = Color(0xFFD4D4D8); // (zinc-300)

  static const ink = Color(0xFF09090B); // primary text / buttons (zinc-950)
  static const inkSoft = Color(0xFF3F3F46); // (zinc-700)
  static const muted = Color(0xFF71717A); // secondary text   (zinc-500)
  static const faint = Color(0xFFA1A1AA); // tertiary text    (zinc-400)
  static const ghost = Color(0xFFD4D4D8); // disabled / hints

  // ── Semantic accents ──────────────────────────────────────────────────────
  static const success = Color(0xFF059669);
  static const successSoft = Color(0xFFECFDF5);
  static const successBorder = Color(0xFFA7F3D0);

  static const warning = Color(0xFFD97706);
  static const warningSoft = Color(0xFFFFFBEB);
  static const warningBorder = Color(0xFFFDE68A);

  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFEF2F2);
  static const dangerBorder = Color(0xFFFECACA);

  // ── Dark capture surfaces (scanner, selfie, photo viewer) ────────────────
  static const night = Color(0xFF0D1117);
  static const nightSoft = Color(0xFF161B22);
  static const nightBorder = Color(0x1AFFFFFF);
  static const nightText = Color(0xFFF4F4F5);
  static const nightMuted = Color(0xFF8B949E);

  // ── Elevation ─────────────────────────────────────────────────────────────
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> raisedShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 28,
      offset: Offset(0, 10),
    ),
  ];
}

/// Spacing, radii and motion tokens. Kept in one place so every screen scales
/// on the same rhythm instead of drifting into bespoke numbers.
class AppTokens {
  const AppTokens._();

  static const double gutter = 20;
  static const double gap = 12;
  static const double gapLg = 16;

  static const double rSm = 12;
  static const double rMd = 16;
  static const double rLg = 20;
  static const double rXl = 26;
  static const double rPill = 999;

  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);
}
