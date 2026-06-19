import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Green Palette (Default/Emerald)
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color mintGreen = Color(0xFFE8F5E9);
  
  // Midnight Palette
  static const Color midnightPrimary = Color(0xFF1A237E);
  static const Color midnightSecondary = Color(0xFF3949AB);
  static const Color midnightSurface = Color(0xFF0D1117);

  // High-performance static cache for built themes to prevent GoogleFonts and JIT build latency
  static final Map<String, ThemeData> _themeCache = {};

  static ThemeData getTheme(String themeId) {
    if (_themeCache.containsKey(themeId)) {
      return _themeCache[themeId]!;
    }

    ThemeData theme;
    switch (themeId) {
      case 'midnight_theme':
        theme = _buildTheme(
          primary: const Color(0xFF3949AB), // Beautiful Midnight Indigo Blue
          secondary: const Color(0xFF5C6BC0), // Sleek secondary indigo
          surface: const Color(0xFF0D1117), // Premium dark background
          isDark: true,
        );
        break;
      case 'neutral_theme':
        theme = _buildTheme(
          primary: const Color(0xFF37474F),
          secondary: const Color(0xFF546E7A),
          surface: const Color(0xFFF5F7F8),
          isDark: false,
        );
        break;
      case 'ocean_theme':
        theme = _buildTheme(
          primary: const Color(0xFF64B5F6), // Pastel Sky Blue
          secondary: const Color(0xFF81D4FA), // Lighter Sky Blue
          surface: const Color(0xFFF4FAFF), // Very soft icy blue background
          isDark: false,
        );
        break;
      case 'emerald_theme':
      default:
        theme = _buildTheme(
          primary: const Color(0xFF2E7D32), // Emerald/Pastel Green
          secondary: const Color(0xFF4CAF50),
          surface: const Color(0xFFF4F9F1), // Very Light Pastel Green
          isDark: false,
        );
        break;
    }

    _themeCache[themeId] = theme;
    return theme;
  }

  static ThemeData _buildTheme({
    required Color primary,
    required Color secondary,
    required Color surface,
    required bool isDark,
  }) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF263238);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF455A64);

    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: surface,
      colorScheme: isDark 
        ? ColorScheme.dark(primary: primary, secondary: secondary, surface: surface)
        : ColorScheme.light(primary: primary, secondary: secondary, surface: surface),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary),
        displayMedium: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
        titleLarge: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: GoogleFonts.outfit(fontSize: 15, color: textPrimary),
        bodyMedium: GoogleFonts.outfit(fontSize: 13, color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        elevation: 4,
        shadowColor: primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  static ThemeData get lightTheme => getTheme('default');
}
