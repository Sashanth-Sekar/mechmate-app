import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary – Electric Orange (automotive accent)
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color primaryOrangeLight = Color(0xFFFF8C5A);
  static const Color primaryOrangeDark = Color(0xFFCC4D1F);

  // Dark theme surfaces
  static const Color darkBg = Color(0xFF0D0F14);
  static const Color darkSurface = Color(0xFF161A22);
  static const Color darkCard = Color(0xFF1E2430);
  static const Color darkCardElevated = Color(0xFF252C3A);
  static const Color darkBorder = Color(0xFF2A3040);

  // Light theme surfaces
  static const Color lightBg = Color(0xFFF4F5F0);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF8F9F5);
  static const Color lightBorder = Color(0xFFE2E3DE);

  // Accent
  static const Color cyanAccent = Color(0xFF00D4FF);
  static const Color steelBlue = Color(0xFF1A6B9A);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color primaryBlue = Color(0xFF3B82F6);

  // Dark text
  static const Color textDarkPrimary = Color(0xFFF0F1F5);
  static const Color textDarkSecondary = Color(0xFF8B93A8);
  static const Color textDarkMuted = Color(0xFF4A5268);

  // Light text
  static const Color textLightPrimary = Color(0xFF111827);
  static const Color textLightSecondary = Color(0xFF4B5563);
  static const Color textLightMuted = Color(0xFF9CA3AF);

  // Gradients
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF9500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBgGradient = LinearGradient(
    colors: [Color(0xFF0D0F14), Color(0xFF141820)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF0899CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1E2430), Color(0xFF161A22)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightCardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF5F5F0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
