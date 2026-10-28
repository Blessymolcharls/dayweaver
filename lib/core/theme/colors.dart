import 'package:flutter/material.dart';

/// Dayweaver Warm Aesthetic Color Palette
class AppColors {
  AppColors._();

  // Core Identity Palette
  static const Color background = Color(0xFFFAF6EF); // Warm cream
  static const Color surfaceSecondary = Color(0xFFF0E6D8); // Paper beige
  static const Color surfaceElevated = Color(0xFFFFFDF9); // Pristine warm card
  static const Color primary = Color(0xFFB96F52); // Muted terracotta
  static const Color primaryHover = Color(0xFFA55E43);
  static const Color secondary = Color(0xFF8A9B83); // Sage green
  static const Color textPrimary = Color(0xFF39332F); // Deep warm charcoal
  static const Color textSecondary = Color(0xFF6E655F); // Warm muted taupe
  static const Color textMuted = Color(0xFF9E948C); // Gentle stone
  static const Color borderSubtle = Color(
    0xFFE5DACD,
  ); // Subtle parchment border
  static const Color divider = Color(0xFFECE2D5);

  // Status Colors
  static const Color success = Color(0xFF6B8E68); // Earthy olive green
  static const Color warning = Color(0xFFD4924B); // Amber ochre
  static const Color error = Color(0xFFC04E44); // Brick red

  // Activity Category Coordinated Palette
  static const Color categoryCollege = Color(0xFF43657D); // Slate blue
  static const Color categoryCoding = Color(0xFFD48238); // Terracotta amber
  static const Color categoryPersonal = Color(0xFFB96F52); // Muted terracotta
  static const Color categoryMeals = Color(0xFFC76D55); // Warm rust peach
  static const Color categoryRest = Color(0xFF7B9975); // Sage leaf
  static const Color categorySleep = Color(0xFF58537B); // Dusk twilight
  static const Color categoryUnscheduled = Color(
    0xFFE8E0D5,
  ); // Soft empty timeline fill

  // Timeline Highlights
  static const Color nowIndicator = Color(0xFFC04E44);
  static const Color nowIndicatorGlow = Color(0x33C04E44);
}
