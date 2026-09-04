import 'package:flutter/material.dart';

/// Filmify brand colors: purple as the primary voice, green as the supporting
/// accent. Both schemes are tuned for Material 3.
class AppColors {
  AppColors._();

  // Brand ramp (purple).
  static const purple = Color(0xFF9333EA);
  static const purpleDim = Color(0xFF7E22CE);
  static const purpleBright = Color(0xFFA855F7);
  static const purplePale = Color(0xFFF3E8FF);

  // Brand ramp (green).
  static const green = Color(0xFF22C55E);
  static const greenDeep = Color(0xFF15803D);
  static const greenBright = Color(0xFF4ADE80);
  static const greenPale = Color(0xFFDCFCE7);

  // Cool dark surfaces (with a subtle brand cast) for the dark theme.
  static const darkBackground = Color(0xFF110E16);
  static const darkSurface = Color(0xFF1A1622);
  static const darkSurfaceHigh = Color(0xFF251F31);
}

/// One user-selectable accent palette. [id] is the persisted value (matches
/// [AppSettings.accentColor]); [label] is the l10n key suffix; [seed] drives
/// the Material-3 scheme; [primary]/[bright] are the light/dark primaries.
class AppAccent {
  const AppAccent({
    required this.id,
    required this.seed,
    required this.primary,
    required this.bright,
    this.secondary = AppColors.greenDeep,
    this.secondaryBright = AppColors.green,
  });

  final String id;
  final Color seed;
  final Color primary;
  final Color bright;

  /// Supporting accent — stays green for every palette (the app's brand).
  final Color secondary;
  final Color secondaryBright;

  AppAccent copyWith({Color? secondary, Color? secondaryBright}) => AppAccent(
        id: id,
        seed: seed,
        primary: primary,
        bright: bright,
        secondary: secondary ?? this.secondary,
        secondaryBright: secondaryBright ?? this.secondaryBright,
      );
}

/// The palettes users can choose from in onboarding and Settings. The green
/// palette swaps its own accent out for a warm complementary tone so it stays
/// distinguishable from the brand green.
const appAccents = <AppAccent>[
  AppAccent(
    id: 'purple',
    seed: AppColors.purpleDim,
    primary: AppColors.purple,
    bright: AppColors.purpleBright,
  ),
  AppAccent(
    id: 'blue',
    seed: Color(0xFF2563EB),
    primary: Color(0xFF2563EB),
    bright: Color(0xFF60A5FA),
  ),
  AppAccent(
    id: 'green',
    seed: AppColors.greenDeep,
    primary: AppColors.greenDeep,
    bright: AppColors.greenBright,
    secondary: Color(0xFFD97706),
    secondaryBright: Color(0xFFF59E0B),
  ),
  AppAccent(
    id: 'orange',
    seed: Color(0xFFEA580C),
    primary: Color(0xFFEA580C),
    bright: Color(0xFFFB923C),
  ),
  AppAccent(
    id: 'rose',
    seed: Color(0xFFE11D48),
    primary: Color(0xFFE11D48),
    bright: Color(0xFFFB7185),
  ),
  AppAccent(
    id: 'teal',
    seed: Color(0xFF0D9488),
    primary: Color(0xFF0D9488),
    bright: Color(0xFF2DD4BF),
  ),
];

/// Resolves an accent by its persisted id; unknown ids fall back to purple.
AppAccent accentById(String id) {
  for (final accent in appAccents) {
    if (accent.id == id) return accent;
  }
  return appAccents.first;
}

/// The default (brand) accent, usable as a const default parameter.
const defaultAccent = AppAccent(
  id: 'purple',
  seed: AppColors.purpleDim,
  primary: AppColors.purple,
  bright: AppColors.purpleBright,
);

ThemeData buildLightTheme({AppAccent accent = defaultAccent}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: accent.seed,
    primary: accent.primary,
    secondary: accent.secondary,
    brightness: Brightness.light,
  );
  return _baseTheme(scheme, Brightness.light);
}

ThemeData buildDarkTheme({AppAccent accent = defaultAccent}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: accent.seed,
    primary: accent.bright,
    secondary: accent.secondaryBright,
    brightness: Brightness.dark,
    surface: AppColors.darkSurface,
  );
  return _baseTheme(scheme, Brightness.dark).copyWith(
    scaffoldBackgroundColor: AppColors.darkBackground,
  );
}

ThemeData _baseTheme(ColorScheme scheme, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final fontColor = isDark ? Colors.white : const Color(0xFF1D1726);

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
        isDark ? AppColors.darkBackground : const Color(0xFFFAF8FD),
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
