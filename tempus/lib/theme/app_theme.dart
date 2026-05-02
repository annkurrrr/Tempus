import 'package:flutter/material.dart';

/// Custom color tokens that vary between light and dark themes.
@immutable
class TempusColors extends ThemeExtension<TempusColors> {
  final Color scaffoldBg;
  final Color cardBg;
  final Color surfaceLight;
  final Color surfaceLighter;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color level0;
  final Color navBarBg;

  const TempusColors({
    required this.scaffoldBg,
    required this.cardBg,
    required this.surfaceLight,
    required this.surfaceLighter,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.level0,
    required this.navBarBg,
  });

  /// Convenience accessor from any BuildContext.
  static TempusColors of(BuildContext context) =>
      Theme.of(context).extension<TempusColors>()!;

  // ── Dark palette ──────────────────────────────────────────────────────
  static const dark = TempusColors(
    scaffoldBg: Color(0xFF0D0D0D),
    cardBg: Color(0xFF1A1A1A),
    surfaceLight: Color(0xFF252525),
    surfaceLighter: Color(0xFF2E2E2E),
    textPrimary: Color(0xFFF5F5F5),
    textSecondary: Color(0xFFB0B0B0),
    textTertiary: Color(0xFF707070),
    level0: Color(0xFF2A2A2A),
    navBarBg: Color(0xFF141414),
  );

  // ── Light palette ─────────────────────────────────────────────────────
  static const light = TempusColors(
    scaffoldBg: Color(0xFFF5F7F5),
    cardBg: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFEEF1EE),
    surfaceLighter: Color(0xFFE0E3E0),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF5A5A5A),
    textTertiary: Color(0xFF9E9E9E),
    level0: Color(0xFFE0E3E0),
    navBarBg: Color(0xFFFFFFFF),
  );

  @override
  TempusColors copyWith({
    Color? scaffoldBg,
    Color? cardBg,
    Color? surfaceLight,
    Color? surfaceLighter,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? level0,
    Color? navBarBg,
  }) {
    return TempusColors(
      scaffoldBg: scaffoldBg ?? this.scaffoldBg,
      cardBg: cardBg ?? this.cardBg,
      surfaceLight: surfaceLight ?? this.surfaceLight,
      surfaceLighter: surfaceLighter ?? this.surfaceLighter,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      level0: level0 ?? this.level0,
      navBarBg: navBarBg ?? this.navBarBg,
    );
  }

  @override
  TempusColors lerp(covariant TempusColors? other, double t) {
    if (other == null) return this;
    return TempusColors(
      scaffoldBg: Color.lerp(scaffoldBg, other.scaffoldBg, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      surfaceLight: Color.lerp(surfaceLight, other.surfaceLight, t)!,
      surfaceLighter: Color.lerp(surfaceLighter, other.surfaceLighter, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      level0: Color.lerp(level0, other.level0, t)!,
      navBarBg: Color.lerp(navBarBg, other.navBarBg, t)!,
    );
  }
}

/// Centralized theme configuration for Tempus.
class AppTheme {
  AppTheme._();

  // ── Brand Colors (same in both themes) ────────────────────────────────
  static const Color primary = Color(0xFF00C853);
  static const Color primaryDark = Color(0xFF009624);
  static const Color accent = Color(0xFF69F0AE);

  // ── Productivity Levels ───────────────────────────────────────────────
  static const Color level1 = Color(0xFF1B5E20);
  static const Color level2 = Color(0xFF2E7D32);
  static const Color level3 = Color(0xFF43A047);
  static const Color level4 = Color(0xFF00E676);

  static Color levelColor(int level, {TempusColors? colors}) {
    switch (level) {
      case 1:
        return level1;
      case 2:
        return level2;
      case 3:
        return level3;
      case 4:
        return level4;
      default:
        return colors?.level0 ?? TempusColors.dark.level0;
    }
  }

  static String levelLabel(int level) {
    switch (level) {
      case 1:
        return '30m – 2h';
      case 2:
        return '2h – 5h';
      case 3:
        return '5h – 8h';
      case 4:
        return '8h+';
      default:
        return '< 30m';
    }
  }

  // ── ThemeData builders ────────────────────────────────────────────────

  static ThemeData get darkTheme => _buildTheme(Brightness.dark, TempusColors.dark);
  static ThemeData get lightTheme => _buildTheme(Brightness.light, TempusColors.light);

  static ThemeData _buildTheme(Brightness brightness, TempusColors colors) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: colors.scaffoldBg,
      primaryColor: primary,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.black,
        secondary: accent,
        onSecondary: Colors.black,
        surface: colors.cardBg,
        onSurface: colors.textPrimary,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.cardBg,
        elevation: isDark ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.navBarBg,
        selectedItemColor: primary,
        unselectedItemColor: colors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: isDark ? 0 : 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: colors.textTertiary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerColor: colors.surfaceLighter,
      dialogTheme: DialogThemeData(
        backgroundColor: colors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      extensions: [colors],
    );
  }
}
