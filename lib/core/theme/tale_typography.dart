import 'package:flutter/material.dart';

/// TaleTypography provides the full TextTheme for TaleTrail.
///
/// Fonts:
///   - Baloo2  → display & headline styles (playful, kid-friendly)
///   - Nunito  → title, body & label styles (friendly, highly legible)
///   - Inter   → reserved for parent-facing sections (see ParentDashboardShell)
abstract final class TaleTypography {
  // ---------------------------------------------------------------------------
  // Font family constants
  // ---------------------------------------------------------------------------
  static const String _baloo = 'Baloo2';
  static const String _nunito = 'Nunito';

  // ---------------------------------------------------------------------------
  // TextTheme getter
  // ---------------------------------------------------------------------------
  static TextTheme get textTheme => const TextTheme(
        // --- Display ---
        displayLarge: TextStyle(
          fontFamily: _baloo,
          fontSize: 40,
          fontWeight: FontWeight.w800,
          height: 1.2,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontFamily: _baloo,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        displaySmall: TextStyle(
          fontFamily: _baloo,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),

        // --- Headline ---
        headlineLarge: TextStyle(
          fontFamily: _baloo,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontFamily: _baloo,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
        headlineSmall: TextStyle(
          fontFamily: _baloo,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),

        // --- Title ---
        titleLarge: TextStyle(
          fontFamily: _nunito,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontFamily: _nunito,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        titleSmall: TextStyle(
          fontFamily: _nunito,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),

        // --- Body ---
        bodyLarge: TextStyle(
          fontFamily: _nunito,
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 1.6,
          letterSpacing: 0.2,
        ),
        bodyMedium: TextStyle(
          fontFamily: _nunito,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: _nunito,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),

        // --- Label ---
        labelLarge: TextStyle(
          fontFamily: _nunito,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: 0.5,
        ),
        labelMedium: TextStyle(
          fontFamily: _nunito,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        labelSmall: TextStyle(
          fontFamily: _nunito,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
      );
}
