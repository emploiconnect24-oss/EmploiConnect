import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'theme_extension.dart';

class AppTheme {
  static ThemeData get lightTheme => _build(
        brightness: Brightness.light,
        scheme: const ColorScheme.light(
          primary: AppThemeColors.primary,
          secondary: AppThemeColors.accent,
          error: AppThemeColors.error,
          surface: LightColors.surface,
          onSurface: LightColors.textPrimary,
          onSurfaceVariant: LightColors.textTertiary,
          outline: LightColors.border,
          surfaceContainerHighest: LightColors.backgroundThird,
        ),
        scaffoldBg: LightColors.backgroundSecond,
        appBarBg: LightColors.surface,
        cardBg: LightColors.surface,
        inputFill: LightColors.inputFill,
        inputBorder: LightColors.border,
        extension: AppThemeExtension.light,
      );

  static ThemeData get darkTheme => _build(
        brightness: Brightness.dark,
        scheme: const ColorScheme.dark(
          primary: AppThemeColors.primary,
          secondary: AppThemeColors.accent,
          error: AppThemeColors.error,
          surface: DarkColors.surface,
          onSurface: DarkColors.textPrimary,
          onSurfaceVariant: DarkColors.textTertiary,
          outline: DarkColors.border,
          surfaceContainerHighest: DarkColors.backgroundThird,
        ),
        scaffoldBg: DarkColors.background,
        appBarBg: DarkColors.backgroundSecond,
        cardBg: DarkColors.surface,
        inputFill: DarkColors.inputFill,
        inputBorder: DarkColors.border,
        extension: AppThemeExtension.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color scaffoldBg,
    required Color appBarBg,
    required Color cardBg,
    required Color inputFill,
    required Color inputBorder,
    required AppThemeExtension extension,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ).apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: extension.cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppThemeColors.primary, width: 1.4),
        ),
      ),
      dividerTheme: DividerThemeData(color: extension.cardBorder),
      chipTheme: ChipThemeData(
        backgroundColor: extension.tagBg,
        selectedColor: extension.infoBg,
        side: BorderSide(color: extension.cardBorder),
        labelStyle: TextStyle(color: extension.tagText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      extensions: [extension],
    );
  }
}
