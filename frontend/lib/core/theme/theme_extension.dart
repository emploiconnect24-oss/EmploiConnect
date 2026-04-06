import 'package:flutter/material.dart';

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color sectionBg;
  final Color cardBorder;
  final Color sidebarAdminBg;
  final Color sidebarRecruteurBg;
  final Color inputFill;
  final Color shimmerBase;
  final Color shimmerHighlight;
  final Color tagBg;
  final Color tagText;
  final Color successBg;
  final Color warningBg;
  final Color errorBg;
  final Color infoBg;
  final Color candidatIconBg;
  final Color recruteurIconBg;
  final Color heroOverlay;
  final Color navbarShadow;

  const AppThemeExtension({
    required this.sectionBg,
    required this.cardBorder,
    required this.sidebarAdminBg,
    required this.sidebarRecruteurBg,
    required this.inputFill,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.tagBg,
    required this.tagText,
    required this.successBg,
    required this.warningBg,
    required this.errorBg,
    required this.infoBg,
    required this.candidatIconBg,
    required this.recruteurIconBg,
    required this.heroOverlay,
    required this.navbarShadow,
  });

  static const AppThemeExtension light = AppThemeExtension(
    sectionBg: Color(0xFFF8FAFC),
    cardBorder: Color(0xFFE2E8F0),
    sidebarAdminBg: Color(0xFF0F172A),
    sidebarRecruteurBg: Color(0xFFFFFFFF),
    inputFill: Color(0xFFF8FAFC),
    shimmerBase: Color(0xFFE2E8F0),
    shimmerHighlight: Color(0xFFF8FAFC),
    tagBg: Color(0xFFF1F5F9),
    tagText: Color(0xFF64748B),
    successBg: Color(0xFFD1FAE5),
    warningBg: Color(0xFFFEF3C7),
    errorBg: Color(0xFFFEE2E2),
    infoBg: Color(0xFFEFF6FF),
    candidatIconBg: Color(0xFFEFF6FF),
    recruteurIconBg: Color(0xFFECFDF5),
    heroOverlay: Color(0xCC0F172A),
    navbarShadow: Color(0x14000000),
  );

  static const AppThemeExtension dark = AppThemeExtension(
    sectionBg: Color(0xFF0F172A),
    cardBorder: Color(0xFF293548),
    sidebarAdminBg: Color(0xFF060D18),
    sidebarRecruteurBg: Color(0xFF0F172A),
    inputFill: Color(0xFF293548),
    shimmerBase: Color(0xFF1E293B),
    shimmerHighlight: Color(0xFF293548),
    tagBg: Color(0xFF293548),
    tagText: Color(0xFF94A3B8),
    successBg: Color(0xFF064E3B),
    warningBg: Color(0xFF451A03),
    errorBg: Color(0xFF450A0A),
    infoBg: Color(0xFF1E3A5F),
    candidatIconBg: Color(0xFF1E3A5F),
    recruteurIconBg: Color(0xFF064E3B),
    heroOverlay: Color(0xE60F172A),
    navbarShadow: Color(0x33000000),
  );

  @override
  AppThemeExtension copyWith({
    Color? sectionBg,
    Color? cardBorder,
    Color? sidebarAdminBg,
    Color? sidebarRecruteurBg,
    Color? inputFill,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? tagBg,
    Color? tagText,
    Color? successBg,
    Color? warningBg,
    Color? errorBg,
    Color? infoBg,
    Color? candidatIconBg,
    Color? recruteurIconBg,
    Color? heroOverlay,
    Color? navbarShadow,
  }) {
    return AppThemeExtension(
      sectionBg: sectionBg ?? this.sectionBg,
      cardBorder: cardBorder ?? this.cardBorder,
      sidebarAdminBg: sidebarAdminBg ?? this.sidebarAdminBg,
      sidebarRecruteurBg: sidebarRecruteurBg ?? this.sidebarRecruteurBg,
      inputFill: inputFill ?? this.inputFill,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      tagBg: tagBg ?? this.tagBg,
      tagText: tagText ?? this.tagText,
      successBg: successBg ?? this.successBg,
      warningBg: warningBg ?? this.warningBg,
      errorBg: errorBg ?? this.errorBg,
      infoBg: infoBg ?? this.infoBg,
      candidatIconBg: candidatIconBg ?? this.candidatIconBg,
      recruteurIconBg: recruteurIconBg ?? this.recruteurIconBg,
      heroOverlay: heroOverlay ?? this.heroOverlay,
      navbarShadow: navbarShadow ?? this.navbarShadow,
    );
  }

  @override
  AppThemeExtension lerp(AppThemeExtension? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      sectionBg: Color.lerp(sectionBg, other.sectionBg, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      sidebarAdminBg: Color.lerp(sidebarAdminBg, other.sidebarAdminBg, t)!,
      sidebarRecruteurBg: Color.lerp(sidebarRecruteurBg, other.sidebarRecruteurBg, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
      tagBg: Color.lerp(tagBg, other.tagBg, t)!,
      tagText: Color.lerp(tagText, other.tagText, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      errorBg: Color.lerp(errorBg, other.errorBg, t)!,
      infoBg: Color.lerp(infoBg, other.infoBg, t)!,
      candidatIconBg: Color.lerp(candidatIconBg, other.candidatIconBg, t)!,
      recruteurIconBg: Color.lerp(recruteurIconBg, other.recruteurIconBg, t)!,
      heroOverlay: Color.lerp(heroOverlay, other.heroOverlay, t)!,
      navbarShadow: Color.lerp(navbarShadow, other.navbarShadow, t)!,
    );
  }
}

extension ThemeExtensionContext on BuildContext {
  AppThemeExtension get themeExt => Theme.of(this).extension<AppThemeExtension>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
