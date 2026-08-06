import 'package:flutter/material.dart';

/// Design tokens straight out of rakbaan_md/01-brand-identity.md §4/§6.
/// Keep this file and that doc in sync -- it's the single source of truth.
class AppColors {
  AppColors._();

  // Primary -- Deep Trust Navy
  static const navy900 = Color(0xFF0A1F3D);
  static const navy700 = Color(0xFF0F2C59);
  static const navy500 = Color(0xFF25467A);
  static const navy100 = Color(0xFFDCE3EF);

  // Secondary -- Home Warm White
  static const warmWhite = Color(0xFFF8F9FA);
  static const pureWhite = Color(0xFFFFFFFF);

  // Accent -- Jasmine Gold / Star Yellow
  // gold500 has low contrast on white: use gold600 for text, and navy900
  // (never white) for text drawn on a gold500 background.
  static const gold600 = Color(0xFFD89600);
  static const gold500 = Color(0xFFFFB800);
  static const gold100 = Color(0xFFFFF3D6);

  // Supporting -- Safe Mint Green
  static const mint700 = Color(0xFF0E9A70);
  static const mint500 = Color(0xFF10B981);
  static const mint100 = Color(0xFFD8F5E9);

  // Neutral / Gray Scale
  static const gray900 = Color(0xFF1A1D21);
  static const gray600 = Color(0xFF5B6370);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray100 = Color(0xFFF1F3F5);

  // Semantic / Status
  static const error600 = Color(0xFFDC2626);
  static const error100 = Color(0xFFFEE2E2);
  static const warning600 = Color(0xFFEA8C00);
  static const warning100 = Color(0xFFFFEFD6);
  static const info600 = Color(0xFF2563EB);

  static const terracotta = Color(0xFFC77B4A);
}

class AppSpacing {
  AppSpacing._();

  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
}

class AppRadius {
  AppRadius._();

  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const full = 999.0;
}

class AppShadows {
  AppShadows._();

  static const sm = [
    BoxShadow(color: Color(0x140F2C59), offset: Offset(0, 1), blurRadius: 3),
  ];
  static const md = [
    BoxShadow(color: Color(0x1F0F2C59), offset: Offset(0, 4), blurRadius: 12),
  ];
  static const lg = [
    BoxShadow(color: Color(0x290F2C59), offset: Offset(0, 8), blurRadius: 24),
  ];
}
