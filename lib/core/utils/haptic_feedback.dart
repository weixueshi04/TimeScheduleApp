import 'package:flutter/services.dart';

/// Haptic feedback utilities
class AppHaptics {
  AppHaptics._(); // Prevent instantiation

  /// Light impact feedback (for buttons, switches)
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium impact feedback (for selections)
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact feedback (for important actions)
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection feedback (for scrolling pickers)
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  /// Vibrate feedback (for errors, alerts)
  static Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }

  /// Success feedback (double light impact)
  static Future<void> success() async {
    await lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await lightImpact();
  }

  /// Error feedback (vibrate)
  static Future<void> error() async {
    await vibrate();
  }
}
