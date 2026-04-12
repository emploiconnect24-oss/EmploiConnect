import 'package:flutter/material.dart';

/// Accueil — blanc + bleus (dégradés), sans orange.
abstract final class HomeDesign {
  static const Color primary = Color(0xFF1A56DB);
  static const Color primaryMid = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF38BDF8);
  static const Color primaryDeep = Color(0xFF1E3A8A);
  /// Violet — hors palette accueil principale ; compat.
  static const Color secondary = Color(0xFF7C3AED);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color dark = Color(0xFF0F172A);
  static const Color light = Color(0xFFF8FAFC);
  static const Color surfaceBlue = Color(0xFFEFF6FF);
  static const Color tickerBg = Color(0xFFE8F1FF);
  static const Color heroBg1 = Color(0xFF0D1B3E);
  static const Color heroBg2 = Color(0xFF1A2F5E);
  static const Color heroBg3 = Color(0xFF2D1B69);

  /// Boutons / bandeaux : bleu → bleu clair.
  static const LinearGradient gradientBrand = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF1E3A8A), Color(0xFF1A56DB), Color(0xFF38BDF8)],
  );

  static const LinearGradient gradientBrandVertical = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E40AF), Color(0xFF1A56DB), Color(0xFF0EA5E9)],
  );

  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [Color(0xFF1A56DB), Color(0xFF2563EB)],
  );
}
