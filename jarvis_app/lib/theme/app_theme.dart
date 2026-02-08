import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Exact match to FigmaUI theme.css :root (dark design).
/// All hex and opacity values from Figma.
class AppTheme {
  // Figma theme.css :root
  static const Color figmaBackground = Color(0xFF0A0A0F);
  static const Color figmaForeground = Color(0xFFE5E5E7);
  static const Color figmaCard = Color(0xFF16161D);
  static const Color figmaCardForeground = Color(0xFFE5E5E7);
  static const Color figmaMuted = Color(0xFF27272F);
  static const Color figmaMutedForeground = Color(0xFFA1A1AA);
  static const Color figmaAccent = Color(0xFFDC2626);
  static const Color figmaAccentForeground = Color(0xFFFFFFFF);
  static const Color figmaSecondary = Color(0xFF0EA5E9);
  static const Color figmaSecondaryForeground = Color(0xFFFFFFFF);
  static const Color figmaDestructive = Color(0xFFD4183D);
  static const Color figmaSidebar = Color(0xFF12121A);
  static const Color figmaSidebarAccent = Color(0xFF1C1C24);
  static const Color figmaInputBackground = Color(0xFF1C1C24);
  // border: rgba(255,255,255,0.1)
  static const Color figmaBorder = Color(0x1AFFFFFF);
  // sidebar-border: rgba(255,255,255,0.08)
  static const Color figmaSidebarBorder = Color(0x14FFFFFF);
  // radius 0.75rem = 12
  static const double figmaRadius = 12.0;

  // Aliases used across app (Figma-aligned)
  static const Color primaryMaroon = figmaAccent;
  static const Color primaryRed = figmaAccent;
  static const Color accentRed = Color(0xFFB91C1C);
  static const Color darkMaroon = Color(0xFF5C0000);

  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color bgLightSecondary = Color(0xFFF8F9FA);
  static const Color bgLightTertiary = Color(0xFFE9ECEF);

  static const Color bgDark = figmaBackground;
  static const Color bgDarkSecondary = figmaSidebar;
  static const Color bgDarkTertiary = figmaInputBackground;

  static const Color textPrimary = figmaForeground;
  static const Color textSecondary = figmaMutedForeground;
  static const Color textTertiary = figmaMutedForeground;
  static const Color textLight = figmaAccentForeground;

  static const Color textDark = Color(0xFF212529);
  static const Color textDarkSecondary = Color(0xFF6C757D);
  static const Color systemGray = Color(0xFFADB5BD);
  static const Color primaryBlue = figmaSecondary;
  static const Color primaryPurple = figmaAccent;
  static const Color accentGreen = success;

  static const Color borderLight = Color(0xFFDEE2E6);
  static const Color borderDark = figmaBorder;

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFEAB308);
  static const Color error = figmaAccent;
  static const Color info = figmaSecondary;

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [figmaAccent, Color(0xFFB91C1C)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [figmaBackground, figmaCard],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [figmaAccent, figmaSecondary],
  );

  static CupertinoThemeData get lightTheme {
    return CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: figmaAccent,
      primaryContrastingColor: figmaAccentForeground,
      scaffoldBackgroundColor: bgLightSecondary,
      barBackgroundColor: bgLight,
      textTheme: const CupertinoTextThemeData(
        primaryColor: textDark,
        textStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          color: textDark,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        navTitleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textDark,
          letterSpacing: -0.3,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textDark,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  /// Figma design theme (dark, theme.css :root).
  static CupertinoThemeData get darkTheme {
    return CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: figmaAccent,
      primaryContrastingColor: figmaAccentForeground,
      scaffoldBackgroundColor: figmaBackground,
      barBackgroundColor: figmaSidebar,
      textTheme: const CupertinoTextThemeData(
        primaryColor: figmaForeground,
        textStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          color: figmaForeground,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        navTitleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: figmaForeground,
          letterSpacing: -0.3,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: figmaForeground,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  static BoxDecoration cardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? figmaCard : bgLight,
      borderRadius: BorderRadius.circular(figmaRadius),
      border: Border.all(
        color: isDark ? figmaBorder : borderLight,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration buttonDecoration(bool isDark, {bool isPrimary = true}) {
    return BoxDecoration(
      gradient: isPrimary ? primaryGradient : null,
      color: isPrimary ? null : (isDark ? figmaSidebarAccent : bgLightSecondary),
      borderRadius: BorderRadius.circular(figmaRadius - 4),
      border: isPrimary ? null : Border.all(color: isDark ? figmaBorder : borderLight, width: 1),
      boxShadow: isPrimary
          ? [
              BoxShadow(
                color: figmaAccent.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }

  static BoxDecoration inputDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? figmaInputBackground : bgLight,
      borderRadius: BorderRadius.circular(figmaRadius),
      border: Border.all(
        color: isDark ? figmaBorder : borderLight,
        width: 1,
      ),
    );
  }  static BoxDecoration sidebarItemDecoration(bool isSelected, bool isDark) {
    return BoxDecoration(
      color: isSelected ? (isDark ? figmaAccent.withOpacity(0.2) : figmaAccent) : Colors.transparent,
      borderRadius: BorderRadius.circular(figmaRadius - 4),
      border: isSelected && isDark ? Border.all(color: figmaAccent.withOpacity(0.3), width: 1) : null,
    );
  }
}
