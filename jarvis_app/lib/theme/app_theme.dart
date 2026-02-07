import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  // TechHub-inspired color palette
  // Maroon/red primary with clean light backgrounds
  static const Color primaryMaroon = Color(0xFF8B0000); // Maroon
  static const Color primaryRed = Color(0xFFDC143C); // Crimson
  static const Color accentRed = Color(0xFFB22222); // Firebrick
  static const Color darkMaroon = Color(0xFF5C0000); // Dark maroon
  
  // Light background colors (TechHub style)
  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color bgLightSecondary = Color(0xFFF8F9FA); // Very light gray
  static const Color bgLightTertiary = Color(0xFFE9ECEF); // Light gray
  
  // Dark background colors (for dark mode)
  static const Color bgDark = Color(0xFF1A1A1A);
  static const Color bgDarkSecondary = Color(0xFF2D2D2D);
  static const Color bgDarkTertiary = Color(0xFF3A3A3A);
  
  // Text colors
  static const Color textPrimary = Color(0xFF212529); // Almost black
  static const Color textSecondary = Color(0xFF6C757D); // Gray
  static const Color textTertiary = Color(0xFFADB5BD); // Light gray
  static const Color textLight = Color(0xFFFFFFFF);
  
  // Aliases for compatibility
  static const Color textDark = textPrimary;
  static const Color textDarkSecondary = textSecondary;
  static const Color systemGray = textTertiary;
  static const Color primaryBlue = primaryMaroon; // Use maroon instead
  static const Color primaryPurple = primaryMaroon; // Use maroon instead
  static const Color accentGreen = success; // Use success green
  
  // Border colors
  static const Color borderLight = Color(0xFFDEE2E6); // Light border
  static const Color borderDark = Color(0xFF495057); // Dark border
  
  // Semantic colors
  static const Color success = Color(0xFF28A745); // Green
  static const Color warning = Color(0xFFFFC107); // Amber
  static const Color error = Color(0xFFDC3545); // Red
  static const Color info = Color(0xFF17A2B8); // Cyan
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryMaroon,
      primaryRed,
    ],
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      bgDark,
      bgDarkSecondary,
    ],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryRed,
      accentRed,
    ],
  );

  static CupertinoThemeData get lightTheme {
    return CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: primaryMaroon,
      primaryContrastingColor: CupertinoColors.white,
      scaffoldBackgroundColor: bgLightSecondary,
      barBackgroundColor: bgLight,
      textTheme: const CupertinoTextThemeData(
        primaryColor: textPrimary,
        textStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          color: textPrimary,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        navTitleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
  
  static CupertinoThemeData get darkTheme {
    return CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryRed,
      primaryContrastingColor: CupertinoColors.white,
      scaffoldBackgroundColor: bgDark,
      barBackgroundColor: bgDarkSecondary,
      textTheme: const CupertinoTextThemeData(
        primaryColor: textLight,
        textStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          color: textLight,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        navTitleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textLight,
          letterSpacing: -0.3,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textLight,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
  
  // Helper method for card styling (TechHub style - white cards on light background)
  static BoxDecoration cardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? bgDarkSecondary : bgLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark ? borderDark : borderLight,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
  
  // Helper method for button styling
  static BoxDecoration buttonDecoration(bool isDark, {bool isPrimary = true}) {
    return BoxDecoration(
      gradient: isPrimary ? primaryGradient : null,
      color: isPrimary ? null : (isDark ? bgDarkSecondary : bgLightSecondary),
      borderRadius: BorderRadius.circular(8),
      border: isPrimary ? null : Border.all(
        color: isDark ? borderDark : borderLight,
        width: 1,
      ),
      boxShadow: isPrimary ? [
        BoxShadow(
          color: primaryMaroon.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ] : null,
    );
  }
  
  // Helper method for input field styling
  static BoxDecoration inputDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? bgDarkSecondary : bgLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark ? borderDark : borderLight,
        width: 1.5,
      ),
    );
  }
  
  // Helper method for sidebar item styling (TechHub maroon highlight)
  static BoxDecoration sidebarItemDecoration(bool isSelected, bool isDark) {
    return BoxDecoration(
      color: isSelected 
          ? (isDark ? primaryMaroon.withOpacity(0.2) : primaryMaroon)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
    );
  }
}
