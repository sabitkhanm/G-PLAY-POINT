import 'package:flutter/material.dart';

/// Central design tokens for G-PLAY POINT.
///
/// Keep visual constants here so every feature uses the same design language.
abstract final class AppColors {
  // Light
  static const lightBackground = Color(0xFFF7F8FC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceAlt = Color(0xFFF1F3F8);
  static const lightBorder = Color(0xFFE5E7EF);

  // Dark
  static const darkBackground = Color(0xFF0B0D12);
  static const darkSurface = Color(0xFF14171E);
  static const darkSurfaceAlt = Color(0xFF1B1F28);
  static const darkBorder = Color(0xFF292E38);

  // Brand
  static const primary = Color(0xFF5B5CE2);
  static const primaryDark = Color(0xFF7C7EF2);
  static const primarySoft = Color(0xFFE9E9FF);

  // Semantic
  static const success = Color(0xFF16A36A);
  static const warning = Color(0xFFE69A17);
  static const danger = Color(0xFFD94B5B);
  static const info = Color(0xFF3182CE);

  static const white = Colors.white;
  static const black = Colors.black;
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const section = 28.0;
}

abstract final class AppRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const xl = 22.0;
  static const pill = 999.0;
}

abstract final class AppElevation {
  static const none = 0.0;
  static const card = 1.0;
  static const raised = 3.0;
  static const dialog = 12.0;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 240);
  static const medium = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 420);

  static const curve = Curves.easeOutCubic;
  static const emphasizedCurve = Curves.easeOutQuart;
}
