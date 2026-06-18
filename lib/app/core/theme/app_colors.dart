import 'package:flutter/material.dart';

/// Brand + semantic color tokens. The Material 3 [ColorScheme] is generated
/// from [seed]; status colors map to the driver-facing booking stages.
class AppColors {
  const AppColors._();

  /// Veha brand seed (modern teal) — drives the whole M3 palette.
  static const Color seed = Color(0xFF0E9488);

  // Booking stage colors (used by StatusChip).
  static const Color assigned = Color(0xFFF59E0B); // amber
  static const Color accepted = Color(0xFF2563EB); // blue
  static const Color onTrip = Color(0xFF7C3AED); // violet
  static const Color completed = Color(0xFF10B981); // green
  static const Color cancelled = Color(0xFFDC2626); // red

  /// Map a stage string from the API to its display color.
  static Color forStage(String stage) {
    switch (stage) {
      case 'assigned':
        return assigned;
      case 'accepted':
        return accepted;
      case 'on_trip':
        return onTrip;
      case 'completed':
        return completed;
      case 'cancelled':
        return cancelled;
      default:
        return assigned;
    }
  }
}
