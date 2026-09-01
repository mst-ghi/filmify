import 'package:flutter/material.dart';

/// Filmify palette: orange as the primary voice, green as the supporting
/// accent. Both schemes are tuned for Material 3.
class AppColors {
  AppColors._();

  // Brand ramp (orange).
  static const orange = Color(0xFFF97316);
  static const orangeDim = Color(0xFFC2410C);
  static const orangeBright = Color(0xFFFB923C);
  static const orangePale = Color(0xFFFFEDD5);

  // Brand ramp (green).
  static const green = Color(0xFF22C55E);
  static const greenDeep = Color(0xFF15803D);
  static const greenBright = Color(0xFF4ADE80);
  static const greenPale = Color(0xFFDCFCE7);

  // Warm dark surfaces (with a subtle orange cast) for the dark theme.
  static const darkBackground = Color(0xFF131011);
  static const darkSurface = Color(0xFF1D181A);
  static const darkSurfaceHigh = Color(0xFF282124);
}

const _lightSeed = AppColors.orangeDim;
const _darkSeed = AppColors.orange;

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: _lightSeed,
    primary: AppColors.orange,
    secondary: AppColors.greenDeep,
    brightness: Brightness.light,
  );
  return _baseTheme(scheme, Brightness.light);
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: _darkSeed,
    primary: AppColors.orangeBright,
    secondary: AppColors.green,
    brightness: Brightness.dark,
    surface: AppColors.darkSurface,
  );
  return _baseTheme(scheme, Brightness.dark).copyWith(
    scaffoldBackgroundColor: AppColors.darkBackground,
  );
}

ThemeData _baseTheme(ColorScheme scheme, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final fontColor = isDark ? Colors.white : const Color(0xFF231A15);

  TextTheme buildText(TextTheme base) => base
      .apply(bodyColor: fontColor, displayColor: fontColor)
      .copyWith(
        titleLarge: base.titleLarge!.copyWith(fontWeight: FontWeight.w700),
        titleMedium: base.titleMedium!.copyWith(fontWeight: FontWeight.w600),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Vazirmatn',
    textTheme: buildText(ThemeData(brightness: brightness).textTheme),
    scaffoldBackgroundColor:
        isDark ? AppColors.darkBackground : const Color(0xFFFDF8F4),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: fontColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Vazirmatn',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: fontColor,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      indicatorColor: scheme.primary.withValues(alpha: 0.16),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      indicatorColor: scheme.primary.withValues(alpha: 0.16),
      selectedIconTheme: IconThemeData(color: scheme.primary),
      unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(
          fontFamily: 'Vazirmatn',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? AppColors.darkSurfaceHigh : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.4),
      space: 1,
      thickness: 1,
    ),
  );
}
