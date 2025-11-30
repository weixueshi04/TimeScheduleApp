import 'package:flutter/material.dart';

/// App color palette - centralized color constants
class AppColors {
  AppColors._(); // Prevent instantiation

  // Primary colors
  static const Color primary = Color(0xFF2196F3); // Blue
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF64B5F6);

  // Secondary colors
  static const Color secondary = Color(0xFF4CAF50); // Green
  static const Color secondaryDark = Color(0xFF388E3C);
  static const Color secondaryLight = Color(0xFF81C784);

  // Accent colors
  static const Color accent = Color(0xFFFF9800); // Orange
  static const Color accentDark = Color(0xFFF57C00);
  static const Color accentLight = Color(0xFFFFB74D);

  // Status colors
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color warning = Color(0xFFFFC107); // Amber
  static const Color error = Color(0xFFF44336); // Red
  static const Color info = Color(0xFF2196F3); // Blue

  // Neutral colors - Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textDisabled = Color(0xFF9E9E9E);

  // Neutral colors - Background
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color divider = Color(0xFFE0E0E0);

  // Border colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFEEEEEE);
  static const Color borderDark = Color(0xFFBDBDBD);

  // Shadow colors
  static const Color shadow = Color(0x1F000000); // 12% opacity
  static const Color shadowLight = Color(0x0A000000); // 4% opacity
  static const Color shadowDark = Color(0x3D000000); // 24% opacity

  // Gradient colors for study room energy bars
  static const List<Color> energyGradient = [
    Color(0xFF4CAF50), // Green (high energy)
    Color(0xFFFFC107), // Yellow (medium energy)
    Color(0xFFF44336), // Red (low energy)
  ];

  // Special UI colors
  static const Color overlay = Color(0x80000000); // 50% black
  static const Color shimmer = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // Task priority colors
  static const Color priorityHigh = Color(0xFFF44336); // Red
  static const Color priorityMedium = Color(0xFFFF9800); // Orange
  static const Color priorityLow = Color(0xFF4CAF50); // Green

  // Study room type colors
  static const Color typeWork = Color(0xFF2196F3); // Blue
  static const Color typeStudy = Color(0xFF9C27B0); // Purple
  static const Color typeReading = Color(0xFF00BCD4); // Cyan
  static const Color typeExam = Color(0xFFFF5722); // Deep Orange
  static const Color typeOther = Color(0xFF607D8B); // Blue Grey

  // Focus timer colors
  static const Color focusActive = Color(0xFF4CAF50);
  static const Color focusPaused = Color(0xFFFFC107);
  static const Color focusBreak = Color(0xFF2196F3);

  // Health tracking colors
  static const Color healthSleep = Color(0xFF3F51B5); // Indigo
  static const Color healthWater = Color(0xFF00BCD4); // Cyan
  static const Color healthExercise = Color(0xFFFF5722); // Deep Orange
  static const Color healthMeal = Color(0xFF4CAF50); // Green
  static const Color healthWeight = Color(0xFF9C27B0); // Purple
  static const Color healthMood = Color(0xFFFFEB3B); // Yellow
}
