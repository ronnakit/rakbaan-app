import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

/// Builds ThemeData from the tokens in design_tokens.dart. IBM Plex Sans
/// Thai is used app-wide (its Latin glyphs are fine for numbers/English too)
/// rather than mixing it with Inter per-widget -- simpler, matches the
/// "minimize custom code" call in rakbaan_md/07-technical-requirements.md §1.3.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.warmWhite,
      colorScheme: const ColorScheme.light(
        primary: AppColors.navy700,
        onPrimary: AppColors.pureWhite,
        secondary: AppColors.gold500,
        onSecondary: AppColors.navy900,
        surface: AppColors.pureWhite,
        onSurface: AppColors.gray900,
        error: AppColors.error600,
        onError: AppColors.pureWhite,
      ),
    );

    final textTheme = GoogleFonts.ibmPlexSansThaiTextTheme(base.textTheme)
        .copyWith(
      displayLarge: _textStyle(28, FontWeight.bold, 1.3, AppColors.gray900),
      headlineLarge: _textStyle(24, FontWeight.bold, 1.35, AppColors.gray900),
      headlineSmall:
          _textStyle(20, FontWeight.w600, 1.4, AppColors.gray900),
      titleMedium: _textStyle(16, FontWeight.w600, 1.4, AppColors.gray900),
      bodyMedium: _textStyle(14, FontWeight.normal, 1.6, AppColors.gray900),
      bodyLarge: _textStyle(16, FontWeight.normal, 1.6, AppColors.gray900),
      bodySmall: _textStyle(12, FontWeight.normal, 1.5, AppColors.gray600),
      labelLarge: _textStyle(15, FontWeight.w600, 1.0, AppColors.pureWhite),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.warmWhite,
        foregroundColor: AppColors.navy900,
        titleTextStyle: textTheme.titleMedium,
      ),
      cardTheme: CardThemeData(
        color: AppColors.pureWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.gray300,
        thickness: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy700,
          foregroundColor: AppColors.pureWhite,
          minimumSize: const Size.fromHeight(44),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy700,
          minimumSize: const Size.fromHeight(44),
          side: const BorderSide(color: AppColors.navy500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.gray100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.pureWhite,
        indicatorColor: AppColors.navy100,
        labelTextStyle: WidgetStateProperty.all(
          _textStyle(12, FontWeight.w600, 1.2, AppColors.navy900),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.navy700 : AppColors.gray600,
          );
        }),
      ),
    );
  }

  static TextStyle _textStyle(
    double size,
    FontWeight weight,
    double lineHeight,
    Color color,
  ) {
    return GoogleFonts.ibmPlexSansThai(
      fontSize: size,
      fontWeight: weight,
      height: lineHeight,
      color: color,
    );
  }
}
