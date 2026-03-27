import 'package:flutter/material.dart';

class AppColors {
  // Couleurs primaires
  static const Color primary = Color(0xFF1A56DB);
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color primaryDeep = Color(0xFF0F172A);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color accent = Color(0xFF0EA5E9);

  // Couleurs texte
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMedium = Color(0xFF334155);
  static const Color textLight = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFFCBD5E1);

  // Couleurs fond
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color bgSection = Color(0xFFF1F5F9);
  static const Color bgDark = Color(0xFF0F172A);
  static const Color bgFooter = Color(0xFF1E293B);

  // Couleurs bordures
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderFocus = Color(0xFF1A56DB);

  // Couleurs sémantiques
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF065F46);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF1A56DB);

  // Couleurs icones cards
  static const Color candidatIconBg = Color(0xFFEFF6FF);
  static const Color candidatIcon = Color(0xFF1A56DB);
  static const Color recruteurIconBg = Color(0xFFECFDF5);
  static const Color recruteurIcon = Color(0xFF10B981);

  // Gradients
  static const List<Color> authPanelGradient = [
    Color(0xFF0F172A),
    Color(0xFF1E3A8A),
    Color(0xFF1A56DB),
  ];
  static const List<double> authPanelStops = [0.0, 0.55, 1.0];

  static const List<Color> heroGradient = [
    Color(0xCC0F172A),
    Color(0x660F172A),
  ];

  // Ombres
  static List<BoxShadow> cardShadow = const [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x06000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static List<BoxShadow> cardShadowHover = const [
    BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 40, offset: Offset(0, 16)),
  ];
  static List<BoxShadow> navbarShadow = const [
    BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 2)),
  ];
}

