import 'package:flutter/material.dart';

/// Centralized design tokens and Material 3 theme for Stark Group VMS.
///
/// Implements a unified, cohesive design system across all screens:
/// - Light neutral canvas (#F3F6FD)
/// - Deep navy brand/navigation (#091226)
/// - Pure white content surfaces (#FFFFFF)
/// - Restrained blue primary actions (#275CF5)
/// - High-contrast readable typography (#101C34 primary, #53637C secondary)
/// - Subtle borders (#DFE6F2) and minimal shadows.
class AppTheme {
  // Brand Palette: Deep Navy & Blue
  static const Color brandObsidian = Color(0xFF081121); // Modern deep obsidian navy
  static const Color brandNavy = Color(0xFF091226); // Main brand/sidebar navy
  static const Color navy900 = brandNavy;
  static const Color navy800 = Color(0xFF233052); // Sidebar hover/borders
  static const Color navy700 = Color(0xFF334155); // Muted navy

  static const Color primaryBlue = Color(0xFF275CF5); // Primary actions & selected
  static const Color primaryIndigo = Color(0xFF4F46E5); // Modern electric indigo accent
  static const Color primaryBlueHover = Color(0xFF1749DD); // Active/pressed blue
  static const Color primaryBlueSubtle = Color(0xFFEDF3FF); // Selected tint
  static const Color accentBlue = Color(0xFF8BADFF); // Blue glow & telemetry highlight

  // Brand Gradients (Magic UI & 21st.dev style)
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primaryBlue, primaryBlueHover],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkSidebarGradient = LinearGradient(
    colors: [brandNavy, Color(0xFF0C1934)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const RadialGradient authBackdrop = RadialGradient(
    center: Alignment(0.65, 0.15),
    radius: 1.1,
    colors: [Color(0xFF18346C), brandObsidian],
  );

  // Neutral Background & Surfaces
  static const Color canvasLight = Color(0xFFF3F6FD); // Main page canvas
  static const Color neutralBg = canvasLight;
  static const Color surfaceWhite = Color(0xFFFFFFFF); // Content cards & surfaces
  static const Color borderNeutral = Color(0xFFDFE6F2); // Subtle borders
  static const Color borderLight = borderNeutral;
  static const Color borderSubtle = Color(0xFFF1F5F9); // Table dividers / light borders
  static const Color borderHover = Color(0xFF9BB7FF); // Interactive card hover border

  // Typography Neutrals
  static const Color textDark = Color(0xFF101C34); // High-contrast primary text
  static const Color textPrimary = textDark;
  static const Color textMuted = Color(0xFF53637C); // High-contrast secondary / helper text
  static const Color textSecondary = textMuted;
  static const Color textDisabled = Color(0xFF94A3B8); // Inactive / placeholder

  // Feedback Colors (WCAG AAA compliant)
  static const Color errorRed = Color(0xFFB91C1C); // Destructive / validation error
  static const Color errorRedBg = Color(0xFFFEF2F2); // Error alert background
  static const Color errorRedBorder = Color(0xFFFECACA); // Error alert border

  // Status Colors (Green, Amber, Neutral, Purple)
  static const Color statusActiveText = Color(0xFF059669);
  static const Color statusActiveBg = Color(0xFFECFDF5);
  static const Color statusActiveBorder = Color(0xFFA7F3D0);

  static const Color statusInactiveText = Color(0xFF475569);
  static const Color statusInactiveBg = Color(0xFFF1F5F9);
  static const Color statusInactiveBorder = Color(0xFFCBD5E1);

  static const Color statusMaintenanceText = Color(0xFFD97706);
  static const Color statusMaintenanceBg = Color(0xFFFFFBEB);
  static const Color statusMaintenanceBorder = Color(0xFFFDE68A);

  static const Color statusDriverText = Color(0xFF7C3AED);
  static const Color statusDriverBg = Color(0xFFF5F3FF);
  static const Color statusDriverBorder = Color(0xFFDDD6FE);

  // Spacing Scale Tokens
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // Radius Tokens
  static const double radiusSm = 6.0;
  static const double radiusMd = 10.0;
  static const double radiusLg = 14.0;
  static const double radiusXl = 18.0;

  /// Centralized Material 3 Theme for Stark Group VMS
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        surface: surfaceWhite,
        error: errorRed,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: canvasLight,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textDark),
        shape: Border(
          bottom: BorderSide(color: borderNeutral, width: 1),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: borderNeutral, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space12,
        ),
        hintStyle: const TextStyle(
          color: textDisabled,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderNeutral, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderNeutral, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: space16,
            vertical: space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textDark,
          elevation: 0,
          side: const BorderSide(color: borderNeutral, width: 1),
          padding: const EdgeInsets.symmetric(
            horizontal: space16,
            vertical: space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderNeutral,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
