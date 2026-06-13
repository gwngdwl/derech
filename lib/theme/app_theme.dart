import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// עיצוב האפליקציה — דרך
class AppTheme {
  AppTheme._();

  // ---- צבעים ----
  static const _primaryColor = Color(0xFF6C63FF);
  static const _secondaryColor = Color(0xFF3B82F6);
  static const _accentColor = Color(0xFF00D4AA);

  // Dark mode colors
  static const _darkBg = Color(0xFF0F0F1A);
  static const _darkSurface = Color(0xFF1A1A2E);
  static const _darkCard = Color(0xFF242440);
  static const _darkText = Color(0xFFE8E8F0);
  static const _darkTextSecondary = Color(0xFF9090A8);
  static const surfaceMuted = Color(0xFF202035);
  static const panelBorder = Color(0xFF3A3A55);

  // Map colors (dark)
  static const mapBackground = Color(0xFF1A1A2E);
  static const mapWater = Color(0xFF1A3A4A);
  static const mapGreen = Color(0xFF1E3A2A);
  static const mapBuilding = Color(0xFF252538);
  static const mapLanduse = Color(0xFF1E1E30);

  // Road colors (dark)
  static const roadMotorway = Color(0xFFE8965A);
  static const roadTrunk = Color(0xFFD4785A);
  static const roadPrimary = Color(0xFFE8C84A);
  static const roadSecondary = Color(0xFFD0D0E0);
  static const roadTertiary = Color(0xFFA0A0B8);
  static const roadResidential = Color(0xFF808098);
  static const roadService = Color(0xFF606078);
  static const roadPath = Color(0xFF505068);

  // Route
  static const routeColor = Color(0xFF6C63FF);
  static const routeOutline = Color(0xFF3B32CC);

  // Gradient
  static const gradient = LinearGradient(
    colors: [_primaryColor, _secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ---- Theme Data ----
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBg,
      colorScheme: const ColorScheme.dark(
        primary: _primaryColor,
        secondary: _secondaryColor,
        tertiary: _accentColor,
        surface: _darkSurface,
        onSurface: _darkText,
        onPrimary: Colors.white,
      ),
      textTheme: _buildTextTheme(),
      cardTheme: CardThemeData(
        color: _darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      iconTheme: const IconThemeData(
        color: _darkTextSecondary,
        size: 24,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.heebo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.heebo(
          color: _darkTextSecondary,
          fontSize: 15,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.heebo(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: _darkText,
      ),
      headlineMedium: GoogleFonts.heebo(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: _darkText,
      ),
      titleLarge: GoogleFonts.heebo(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _darkText,
      ),
      titleMedium: GoogleFonts.heebo(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: _darkText,
      ),
      bodyLarge: GoogleFonts.heebo(
        fontSize: 16,
        color: _darkText,
      ),
      bodyMedium: GoogleFonts.heebo(
        fontSize: 14,
        color: _darkText,
      ),
      bodySmall: GoogleFonts.heebo(
        fontSize: 12,
        color: _darkTextSecondary,
      ),
      labelLarge: GoogleFonts.heebo(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _darkText,
      ),
    );
  }

  // ---- Glassmorphism decoration ----
  static BoxDecoration get glassDecoration => BoxDecoration(
        color: _darkCard.withAlpha(200),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: panelBorder.withAlpha(180),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(64),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration get glassDecorationTop => BoxDecoration(
        color: _darkCard.withAlpha(220),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
        border: Border.all(
          color: panelBorder.withAlpha(180),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 32,
            offset: const Offset(0, -4),
          ),
        ],
      );

  // ---- Road styling ----
  static Color getRoadColor(String fclass) {
    switch (fclass) {
      case 'motorway':
      case 'motorway_link':
        return roadMotorway;
      case 'trunk':
      case 'trunk_link':
        return roadTrunk;
      case 'primary':
      case 'primary_link':
        return roadPrimary;
      case 'secondary':
      case 'secondary_link':
        return roadSecondary;
      case 'tertiary':
      case 'tertiary_link':
        return roadTertiary;
      case 'residential':
      case 'living_street':
        return roadResidential;
      case 'service':
        return roadService;
      default:
        return roadPath;
    }
  }

  static double getRoadWidth(String fclass, double zoom) {
    double base;
    switch (fclass) {
      case 'motorway':
      case 'motorway_link':
        base = 3.5;
        break;
      case 'trunk':
      case 'trunk_link':
        base = 3.0;
        break;
      case 'primary':
      case 'primary_link':
        base = 2.5;
        break;
      case 'secondary':
      case 'secondary_link':
        base = 2.0;
        break;
      case 'tertiary':
      case 'tertiary_link':
        base = 1.8;
        break;
      case 'residential':
      case 'living_street':
        base = 1.5;
        break;
      case 'service':
        base = 1.0;
        break;
      default:
        base = 0.8;
    }
    // Scale width with zoom
    final scale = (zoom - 8) / 8;
    return base * (1 + scale.clamp(0, 2));
  }

  /// סוגי כבישים שצריכים להופיע ברמת זום מסוימת
  static Set<String> getVisibleRoadClasses(double zoom) {
    if (zoom >= 16) {
      return {
        'motorway', 'motorway_link', 'trunk', 'trunk_link',
        'primary', 'primary_link', 'secondary', 'secondary_link',
        'tertiary', 'tertiary_link', 'residential', 'living_street',
        'unclassified', 'service', 'track', 'footway', 'path',
        'pedestrian', 'cycleway', 'steps',
      };
    }
    if (zoom >= 14) {
      return {
        'motorway', 'motorway_link', 'trunk', 'trunk_link',
        'primary', 'primary_link', 'secondary', 'secondary_link',
        'tertiary', 'tertiary_link', 'residential', 'living_street',
        'unclassified', 'service',
      };
    }
    if (zoom >= 12) {
      return {
        'motorway', 'motorway_link', 'trunk', 'trunk_link',
        'primary', 'primary_link', 'secondary', 'secondary_link',
        'tertiary', 'tertiary_link',
      };
    }
    if (zoom >= 10) {
      return {
        'motorway', 'motorway_link', 'trunk', 'trunk_link',
        'primary', 'primary_link', 'secondary', 'secondary_link',
      };
    }
    return {
      'motorway', 'motorway_link', 'trunk', 'trunk_link',
      'primary', 'primary_link',
    };
  }
}
