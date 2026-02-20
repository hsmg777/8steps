import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppStyle {
  static const Color brandBlue = Color(0xFF2FB9E2);
  static const Color darkOverlay = Color(0xA1000000);
  static const Color registerBackground = Color(0xFF18191D);
  static const Color darkInputFill = Color(0xFF242731);
  static const Color darkInputBorder = Color(0xFF353944);
  static const Color pageBackground = Color(0xFF13151D);

  static ThemeData get theme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: brandBlue),
      useMaterial3: true,
      scaffoldBackgroundColor: pageBackground,
      textTheme: GoogleFonts.poppinsTextTheme(),
      primaryTextTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: pageBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ButtonStyle primaryButtonStyle({double radius = 16}) {
    return FilledButton.styleFrom(
      backgroundColor: brandBlue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
