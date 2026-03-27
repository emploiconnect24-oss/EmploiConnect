import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Titres homepage
  static TextStyle heroTitle = GoogleFonts.poppins(
    fontSize: 54,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    height: 1.15,
    letterSpacing: -0.5,
  );
  static TextStyle sectionTitle = GoogleFonts.poppins(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    height: 1.2,
  );
  static TextStyle sectionSubtitle = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
    height: 1.6,
  );

  // Titres auth
  static TextStyle authTitle = GoogleFonts.poppins(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    height: 1.25,
  );
  static TextStyle authSubtitle = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
    height: 1.5,
  );
  static TextStyle authPanelTitle = GoogleFonts.poppins(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.3,
  );
  static TextStyle authPanelBody = GoogleFonts.inter(
    fontSize: 14,
    color: const Color(0xCCFFFFFF),
    height: 1.65,
  );

  // Formulaires
  static TextStyle inputLabel = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF374151),
  );
  static TextStyle inputText = GoogleFonts.inter(
    fontSize: 15,
    color: AppColors.textDark,
  );
  static TextStyle inputHint = GoogleFonts.inter(
    fontSize: 14,
    color: AppColors.textDisabled,
  );
  static TextStyle inputError = GoogleFonts.inter(
    fontSize: 12,
    color: AppColors.error,
  );
  static TextStyle linkText = GoogleFonts.inter(
    fontSize: 14,
    color: AppColors.primary,
    fontWeight: FontWeight.w600,
  );
  static TextStyle buttonLabel = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // Footer
  static TextStyle footerTitle = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  static TextStyle footerLink = GoogleFonts.inter(
    fontSize: 14,
    color: const Color(0x99FFFFFF),
  );
  static TextStyle copyright = GoogleFonts.inter(
    fontSize: 13,
    color: const Color(0x66FFFFFF),
  );
}

