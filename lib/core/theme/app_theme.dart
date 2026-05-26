import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  AppTheme._();

  // ─── DARK ──────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryOrange,
        secondary: AppColors.cyanAccent,
        surface: AppColors.darkSurface,
        error: AppColors.error,
      ),
      textTheme: _textTheme(Brightness.dark),
      appBarTheme: _appBarTheme(Brightness.dark),
      bottomNavigationBarTheme: _bottomNavTheme(Brightness.dark),
      inputDecorationTheme: _inputTheme(Brightness.dark),
      elevatedButtonTheme: _elevatedBtnTheme(),
      outlinedButtonTheme: _outlinedBtnTheme(),
      cardTheme: _cardTheme(Brightness.dark),
      chipTheme: _chipTheme(Brightness.dark),
      tabBarTheme: _tabBarTheme(Brightness.dark),
      dialogTheme: _dialogThemeData(Brightness.dark),
      snackBarTheme: _snackbarTheme(),
      dividerTheme: DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
      ),
      switchTheme: _switchTheme(),
    );
  }

  // ─── LIGHT ─────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryOrange,
        secondary: AppColors.cyanAccent,
        surface: AppColors.lightSurface,
        error: AppColors.error,
      ),
      textTheme: _textTheme(Brightness.light),
      appBarTheme: _appBarTheme(Brightness.light),
      bottomNavigationBarTheme: _bottomNavTheme(Brightness.light),
      inputDecorationTheme: _inputTheme(Brightness.light),
      elevatedButtonTheme: _elevatedBtnTheme(),
      outlinedButtonTheme: _outlinedBtnTheme(),
      cardTheme: _cardTheme(Brightness.light),
      chipTheme: _chipTheme(Brightness.light),
      tabBarTheme: _tabBarTheme(Brightness.light),
      dialogTheme: _dialogThemeData(Brightness.light),
      snackBarTheme: _snackbarTheme(),
      dividerTheme: DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
      ),
      switchTheme: _switchTheme(),
    );
  }

  // ─── HELPERS ───────────────────────────────────────────

  static TextTheme _textTheme(Brightness b) {
    final isDark = b == Brightness.dark;
    final primary =
        isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary;
    final secondary =
        isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary;
    return TextTheme(
      displayLarge: GoogleFonts.rajdhani(
          fontSize: 48, fontWeight: FontWeight.w800, color: primary),
      displayMedium: GoogleFonts.rajdhani(
          fontSize: 36, fontWeight: FontWeight.w700, color: primary),
      titleLarge: GoogleFonts.rajdhani(
          fontSize: 22, fontWeight: FontWeight.w700, color: primary),
      titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: primary),
      bodyLarge: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w400, color: secondary),
      bodyMedium: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w400, color: secondary),
      labelLarge: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600, color: primary),
    );
  }

  static AppBarTheme _appBarTheme(Brightness b) {
    final isDark = b == Brightness.dark;
    return AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(
        color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
      ),
      titleTextStyle: GoogleFonts.rajdhani(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color:
            isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
      ),
    );
  }

  static BottomNavigationBarThemeData _bottomNavTheme(Brightness b) {
    final isDark = b == Brightness.dark;
    return BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor:
          isDark ? AppColors.darkSurface : AppColors.lightSurface,
      selectedItemColor: AppColors.primaryOrange,
      unselectedItemColor:
          isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
      selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle:
          GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400),
      elevation: 0,
    );
  }

  static InputDecorationTheme _inputTheme(Brightness b) {
    final isDark = b == Brightness.dark;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? AppColors.darkCard : AppColors.lightSurface,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.primaryOrange, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.8),
      ),
      labelStyle: TextStyle(
          color: isDark
              ? AppColors.textDarkMuted
              : AppColors.textLightMuted,
          fontSize: 14),
      hintStyle: TextStyle(
          color: isDark
              ? AppColors.textDarkMuted
              : AppColors.textLightMuted,
          fontSize: 14),
      prefixIconColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return AppColors.primaryOrange;
        }
        return isDark ? AppColors.textDarkMuted : AppColors.textLightMuted;
      }),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  static ElevatedButtonThemeData _elevatedBtnTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        elevation: 0,
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedBtnTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryOrange,
        side: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
    );
  }

  static CardThemeData _cardTheme(Brightness b) {
    final isDark = b == Brightness.dark;
    return CardThemeData(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
    );
  }

  static ChipThemeData _chipTheme(Brightness b) {
    final isDark = b == Brightness.dark;
    return ChipThemeData(
      backgroundColor:
          isDark ? AppColors.darkCard : AppColors.lightCard,
      selectedColor: AppColors.primaryOrange.withValues(alpha: 0.15),
      labelStyle: TextStyle(
          fontSize: 13,
          color: isDark
              ? AppColors.textDarkSecondary
              : AppColors.textLightSecondary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
    );
  }

  static TabBarThemeData _tabBarTheme(Brightness b) {
    final isDark = b == Brightness.dark;
    return TabBarThemeData(
      labelColor: AppColors.primaryOrange,
      unselectedLabelColor:
          isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
      indicatorColor: AppColors.primaryOrange,
      labelStyle:
          GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelStyle:
          GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400),
    );
  }

  static DialogThemeData _dialogThemeData(Brightness b) {
    final isDark = b == Brightness.dark;
    return DialogThemeData(
      backgroundColor:
          isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: GoogleFonts.rajdhani(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
      ),
    );
  }

  static SnackBarThemeData _snackbarTheme() {
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentTextStyle: GoogleFonts.inter(fontSize: 13),
    );
  }

  static SwitchThemeData _switchTheme() {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryOrange;
        }
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryOrange.withValues(alpha: 0.3);
        }
        return Colors.grey.withValues(alpha: 0.3);
      }),
    );
  }
}
