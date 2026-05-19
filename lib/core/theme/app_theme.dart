import 'package:flutter/material.dart';
import 'tale_colors.dart';
import 'tale_typography.dart';

// ---------------------------------------------------------------------------
// StoryPalette
// ---------------------------------------------------------------------------

/// Describes the color palette for a specific story's dynamic theme.
class StoryPalette {
  const StoryPalette({
    required this.accentColor,
    required this.backgroundColor,
    required this.textColor,
  });

  final Color accentColor;
  final Color backgroundColor;
  final Color textColor;
}

// ---------------------------------------------------------------------------
// Shared shape / component helpers
// ---------------------------------------------------------------------------

const _defaultRadius = 16.0;
const _pillRadius = 100.0;

const _defaultShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(_defaultRadius)),
);

const _pillShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(_pillRadius)),
);

AppBarTheme _appBarTheme({required Color foregroundColor}) => AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: foregroundColor,
      titleTextStyle: TaleTypography.textTheme.titleLarge?.copyWith(
        color: foregroundColor,
        fontWeight: FontWeight.w700,
      ),
      centerTitle: false,
    );

FloatingActionButtonThemeData _fabTheme({
  required Color backgroundColor,
  required Color foregroundColor,
}) =>
    FloatingActionButtonThemeData(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 4,
      shape: const CircleBorder(),
    );

CardTheme _cardTheme({Color? color}) => CardTheme(
      color: color,
      elevation: 0,
      shape: _defaultShape,
      margin: EdgeInsets.zero,
    );

InputDecorationTheme _inputTheme({
  required Color fillColor,
  required Color borderColor,
  required Color focusedBorderColor,
}) =>
    InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(_defaultRadius)),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(_defaultRadius)),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(_defaultRadius)),
        borderSide: BorderSide(color: focusedBorderColor, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(_defaultRadius)),
        borderSide: BorderSide(color: TaleColors.error),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(_defaultRadius)),
        borderSide: BorderSide(color: TaleColors.error, width: 2),
      ),
    );

ElevatedButtonThemeData _elevatedButtonTheme({
  required Color backgroundColor,
  required Color foregroundColor,
}) =>
    ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 0,
        shape: _pillShape,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: TaleTypography.textTheme.labelLarge,
      ),
    );

// ---------------------------------------------------------------------------
// TaleTheme
// ---------------------------------------------------------------------------

/// Exposes the three core ThemeData instances for TaleTrail.
abstract final class TaleTheme {
  static ThemeData get lightTheme => _buildLightTheme();
  static ThemeData get bedtimeTheme => _buildBedtimeTheme();
  static ThemeData storyDynamicTheme(StoryPalette palette) =>
      _buildStoryDynamicTheme(palette);
}

// ---------------------------------------------------------------------------
// Light Theme
// ---------------------------------------------------------------------------

ThemeData _buildLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: TaleColors.terracotta,
    brightness: Brightness.light,
    primary: TaleColors.terracotta,
    onPrimary: Colors.white,
    primaryContainer: TaleColors.terracottaLight,
    onPrimaryContainer: TaleColors.terracottaDark,
    secondary: TaleColors.warmGold,
    onSecondary: TaleColors.warmGrey900,
    secondaryContainer: TaleColors.warmGoldLight,
    onSecondaryContainer: TaleColors.warmGrey800,
    surface: TaleColors.parchment,
    onSurface: TaleColors.warmGrey900,
    surfaceContainerHighest: TaleColors.parchmentDark,
    error: TaleColors.error,
    onError: Colors.white,
    outline: TaleColors.warmGrey300,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: TaleColors.parchment,
    fontFamily: 'Nunito',
    textTheme: TaleTypography.textTheme,
    appBarTheme: _appBarTheme(foregroundColor: TaleColors.warmGrey900),
    floatingActionButtonTheme: _fabTheme(
      backgroundColor: TaleColors.terracotta,
      foregroundColor: Colors.white,
    ),
    cardTheme: _cardTheme(color: TaleColors.warmWhite),
    inputDecorationTheme: _inputTheme(
      fillColor: TaleColors.warmWhite,
      borderColor: TaleColors.warmGrey300,
      focusedBorderColor: TaleColors.terracotta,
    ),
    elevatedButtonTheme: _elevatedButtonTheme(
      backgroundColor: TaleColors.terracotta,
      foregroundColor: Colors.white,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: TaleColors.warmGrey100,
      labelStyle: TaleTypography.textTheme.labelSmall,
      shape: const StadiumBorder(),
      side: BorderSide.none,
    ),
    dividerTheme: const DividerThemeData(
      color: TaleColors.warmGrey200,
      thickness: 1,
      space: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: TaleColors.warmWhite,
      selectedItemColor: TaleColors.terracotta,
      unselectedItemColor: TaleColors.warmGrey400,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}

// ---------------------------------------------------------------------------
// Bedtime Theme
// ---------------------------------------------------------------------------

ThemeData _buildBedtimeTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: TaleColors.softGold,
    brightness: Brightness.dark,
    primary: TaleColors.softGold,
    onPrimary: TaleColors.nightNavy,
    primaryContainer: TaleColors.nightNavyLight,
    onPrimaryContainer: TaleColors.softGold,
    secondary: TaleColors.moonlight,
    onSecondary: TaleColors.nightNavy,
    surface: TaleColors.nightNavy,
    onSurface: TaleColors.moonlight,
    surfaceContainerHighest: TaleColors.nightNavySurface,
    error: TaleColors.error,
    onError: Colors.white,
    outline: TaleColors.nightNavyLight,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: TaleColors.nightNavy,
    fontFamily: 'Nunito',
    textTheme: TaleTypography.textTheme.apply(
      bodyColor: TaleColors.moonlight,
      displayColor: TaleColors.moonlight,
    ),
    appBarTheme: _appBarTheme(foregroundColor: TaleColors.moonlight),
    floatingActionButtonTheme: _fabTheme(
      backgroundColor: TaleColors.softGold,
      foregroundColor: TaleColors.nightNavy,
    ),
    cardTheme: _cardTheme(color: TaleColors.nightNavySurface),
    inputDecorationTheme: _inputTheme(
      fillColor: TaleColors.nightNavySurface,
      borderColor: TaleColors.nightNavyLight,
      focusedBorderColor: TaleColors.softGold,
    ),
    elevatedButtonTheme: _elevatedButtonTheme(
      backgroundColor: TaleColors.softGold,
      foregroundColor: TaleColors.nightNavy,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: TaleColors.nightNavyLight,
      labelStyle: TaleTypography.textTheme.labelSmall?.copyWith(
        color: TaleColors.moonlight,
      ),
      shape: const StadiumBorder(),
      side: BorderSide.none,
    ),
    dividerTheme: const DividerThemeData(
      color: TaleColors.nightNavyLight,
      thickness: 1,
      space: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: TaleColors.nightNavySurface,
      selectedItemColor: TaleColors.softGold,
      unselectedItemColor: TaleColors.warmGrey600,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}

// ---------------------------------------------------------------------------
// Story Dynamic Theme
// ---------------------------------------------------------------------------

ThemeData _buildStoryDynamicTheme(StoryPalette palette) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: palette.accentColor,
    brightness: ThemeData.estimateBrightnessForColor(palette.backgroundColor),
    primary: palette.accentColor,
    onPrimary: palette.textColor,
    surface: palette.backgroundColor,
    onSurface: palette.textColor,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: palette.backgroundColor,
    fontFamily: 'Nunito',
    textTheme: TaleTypography.textTheme.apply(
      bodyColor: palette.textColor,
      displayColor: palette.textColor,
    ),
    appBarTheme: _appBarTheme(foregroundColor: palette.textColor),
    floatingActionButtonTheme: _fabTheme(
      backgroundColor: palette.accentColor,
      foregroundColor: palette.textColor,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: _defaultShape,
      margin: EdgeInsets.zero,
      color: palette.accentColor.withAlpha(30),
    ),
    inputDecorationTheme: _inputTheme(
      fillColor: palette.backgroundColor,
      borderColor: palette.accentColor.withAlpha(80),
      focusedBorderColor: palette.accentColor,
    ),
    elevatedButtonTheme: _elevatedButtonTheme(
      backgroundColor: palette.accentColor,
      foregroundColor: palette.textColor,
    ),
  );
}

// ---------------------------------------------------------------------------
// Convenience top-level getters (used in app.dart)
// ---------------------------------------------------------------------------

/// Light theme alias — convenience getter.
ThemeData get lightTheme => TaleTheme.lightTheme;

/// Bedtime theme alias — convenience getter.
ThemeData get bedtimeTheme => TaleTheme.bedtimeTheme;

/// Generates a story-specific ThemeData from [palette].
ThemeData storyDynamicTheme(StoryPalette palette) =>
    TaleTheme.storyDynamicTheme(palette);
