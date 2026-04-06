# PRD — EmploiConnect · Système de Thème Clair / Sombre
## Product Requirements Document v2.3 — Dark Mode & Theme System
**Stack : Flutter (Dart) · GoRouter · Google Fonts (Poppins + Inter)**
**Outil : Cursor / Kirsoft AI**
**Module : Thème Global — Mode Clair & Mode Sombre sur toute la plateforme**
**Statut : Phase 6 — Suite Candidat Dashboard validé**
**Date : Mars 2026**

---

> ### ⚠️ INSTRUCTIONS CRITIQUES POUR CURSOR
>
> 1. Homepage ✅ · Auth ✅ · Admin ✅ · Recruteur ✅ · Candidat ✅ — TOUS VALIDÉS
> 2. Ce PRD ajoute le **système de thème** à TOUTE la plateforme existante
> 3. **NE PAS recréer** les pages existantes — uniquement adapter le système de couleurs
> 4. Utiliser **ThemeData + ThemeExtension** de Flutter natif
> 5. Le thème doit être **persisté** (SharedPreferences) et appliqué au démarrage
> 6. Le changement de thème doit être **instantané et fluide** (AnimatedTheme)
> 7. **Chaque couleur hardcodée** dans le code existant doit être remplacée
>    par une référence au thème dynamique
> 8. Implémenter **dans l'ordre exact** de ce PRD

---

## Table des Matières

1. [Vue d'ensemble du Système de Thème](#1-vue-densemble-du-système-de-thème)
2. [Architecture du Système](#2-architecture-du-système)
3. [Palette Couleurs — Mode Clair](#3-palette-couleurs--mode-clair)
4. [Palette Couleurs — Mode Sombre](#4-palette-couleurs--mode-sombre)
5. [ThemeData Flutter Complet](#5-themedata-flutter-complet)
6. [ThemeExtension — Couleurs Personnalisées](#6-themeextension--couleurs-personnalisées)
7. [ThemeProvider — Gestion d'État](#7-themeprovider--gestion-détat)
8. [Persistance du Thème](#8-persistance-du-thème)
9. [Toggle de Thème — Composants UI](#9-toggle-de-thème--composants-ui)
10. [Adaptation Homepage](#10-adaptation-homepage)
11. [Adaptation Pages Auth](#11-adaptation-pages-auth)
12. [Adaptation Admin Dashboard](#12-adaptation-admin-dashboard)
13. [Adaptation Recruteur Dashboard](#13-adaptation-recruteur-dashboard)
14. [Adaptation Candidat Dashboard](#14-adaptation-candidat-dashboard)
15. [Animations de Transition de Thème](#15-animations-de-transition-de-thème)
16. [Règles de Remplacement des Couleurs Hardcodées](#16-règles-de-remplacement-des-couleurs-hardcodées)
17. [Tests & Vérifications](#17-tests--vérifications)
18. [Critères d'Acceptation](#18-critères-dacceptation)

---

## 1. Vue d'ensemble du Système de Thème

### Objectif
Permettre à chaque utilisateur de choisir entre le **mode clair** (défaut)
et le **mode sombre** sur l'intégralité de la plateforme EmploiConnect —
homepage, auth, admin, recruteur, candidat — avec une transition fluide
et une persistance entre les sessions.

### Principes Fondamentaux
```
✅ Mode clair  : fond blanc, textes sombres (design actuel validé)
✅ Mode sombre : fond très sombre, textes clairs — confortable et élégant
✅ Transition  : AnimatedTheme Flutter — instantané et fluide
✅ Persistance : SharedPreferences — mémorisé entre les sessions
✅ Respect OS  : option "Suivre le système" (MediaQuery brightness)
✅ Cohérence   : même design language, juste les couleurs inversées
```

### Points de Contrôle du Toggle
```
Le toggle thème est accessible depuis :
1. TopBar de tous les dashboards (icône soleil/lune) — priorité haute
2. Page Paramètres de chaque dashboard (section Apparence)
3. Menu avatar dans le TopBar (dropdown)
4. Paramètres de la page d'accueil (si utilisateur connecté)
```

### Ce qui NE change PAS entre les thèmes
```
- Logo EmploiConnect (couleur bleue conservée)
- Couleur primaire bleue (#1A56DB) pour les CTAs principaux
- Gradient du panneau gauche Auth (reste sombre dans les deux thèmes)
- Gradient de la sidebar Candidat (reste bleu dans les deux thèmes)
- Couleurs sémantiques (succès vert, erreur rouge, warning orange)
- Fonts (Poppins + Inter)
- Border-radius et dimensions
- Animations
```

---

## 2. Architecture du Système

### Structure des Fichiers à Créer
```
lib/
├── core/
│   ├── theme/
│   │   ├── app_theme.dart           ← ThemeData light + dark
│   │   ├── app_colors.dart          ← Mise à jour avec tokens dynamiques
│   │   ├── theme_extension.dart     ← AppThemeExtension (couleurs custom)
│   │   └── theme_provider.dart      ← Provider/Riverpod state
│   └── constants/
│       └── theme_constants.dart     ← Clés SharedPreferences, etc.
└── shared/
    └── widgets/
        ├── theme_toggle_button.dart  ← Bouton toggle réutilisable
        └── theme_selector_tile.dart  ← Tile pour la page paramètres
```

### Dépendances à Ajouter
```yaml
# pubspec.yaml — ajouter :
dependencies:
  shared_preferences: ^2.2.2    # Persistance du thème
  provider: ^6.1.1              # Si pas déjà utilisé (ou utiliser Riverpod)
  # animated_theme_switcher: ^2.0.10  # Optionnel pour animation avancée
```

---

## 3. Palette Couleurs — Mode Clair

```dart
// lib/core/theme/app_colors.dart — SECTION LIGHT MODE

class LightColors {

  // ── FONDS ──────────────────────────────────────────────────
  static const Color background        = Color(0xFFFFFFFF); // Fond principal
  static const Color backgroundSecond  = Color(0xFFF8FAFC); // Fond sections
  static const Color backgroundThird   = Color(0xFFF1F5F9); // Fond sections alt
  static const Color surface           = Color(0xFFFFFFFF); // Cards, modals
  static const Color surfaceVariant    = Color(0xFFF8FAFC); // Input bg

  // ── TEXTES ─────────────────────────────────────────────────
  static const Color textPrimary       = Color(0xFF0F172A); // Titres
  static const Color textSecondary     = Color(0xFF334155); // Corps
  static const Color textTertiary      = Color(0xFF64748B); // Sous-titres
  static const Color textHint          = Color(0xFF94A3B8); // Hints
  static const Color textDisabled      = Color(0xFFCBD5E1); // Désactivé

  // ── BORDURES ───────────────────────────────────────────────
  static const Color border            = Color(0xFFE2E8F0); // Bordure standard
  static const Color borderLight       = Color(0xFFF1F5F9); // Bordure légère
  static const Color borderFocus       = Color(0xFF1A56DB); // Focus inputs

  // ── OMBRES ─────────────────────────────────────────────────
  static const Color shadow            = Color(0x0A000000); // Ombre cards
  static const Color shadowMedium      = Color(0x14000000); // Ombre hover
  static const Color shadowStrong      = Color(0x1F000000); // Ombre modals

  // ── TOPBAR / NAVBAR ────────────────────────────────────────
  static const Color navbarBg          = Color(0xFFFFFFFF);
  static const Color navbarBorder      = Color(0xFFE2E8F0);
  static const Color navbarText        = Color(0xFF334155);

  // ── SIDEBAR ADMIN ──────────────────────────────────────────
  static const Color adminSidebarBg    = Color(0xFF0F172A);
  static const Color adminSidebarBorder= Color(0xFF1E293B);

  // ── SIDEBAR RECRUTEUR ──────────────────────────────────────
  static const Color recruteurSidebarBg= Color(0xFFFFFFFF);

  // ── DIVIDERS ───────────────────────────────────────────────
  static const Color divider           = Color(0xFFE2E8F0);
  static const Color dividerLight      = Color(0xFFF1F5F9);

  // ── INPUTS ─────────────────────────────────────────────────
  static const Color inputFill         = Color(0xFFF8FAFC);
  static const Color inputBorder       = Color(0xFFE2E8F0);
  static const Color inputFocusBorder  = Color(0xFF1A56DB);
  static const Color inputErrorBorder  = Color(0xFFEF4444);

  // ── OVERLAYS ───────────────────────────────────────────────
  static const Color overlay           = Color(0x80000000);
  static const Color overlayLight      = Color(0x40000000);

  // ── SKELETON / SHIMMER ─────────────────────────────────────
  static const Color shimmerBase       = Color(0xFFE2E8F0);
  static const Color shimmerHighlight  = Color(0xFFF8FAFC);
}
```

---

## 4. Palette Couleurs — Mode Sombre

```dart
// lib/core/theme/app_colors.dart — SECTION DARK MODE

class DarkColors {

  // ── FONDS ──────────────────────────────────────────────────
  // Règle des niveaux de profondeur :
  // Level 0 (le plus sombre) : #0A0F1A — fond principal global
  // Level 1                  : #0F172A — fond sections, pages
  // Level 2                  : #1E293B — cards, panels
  // Level 3                  : #293548 — cards hover, inputs
  // Level 4                  : #334155 — bordures légères, dividers
  static const Color background        = Color(0xFF0A0F1A); // Fond principal
  static const Color backgroundSecond  = Color(0xFF0F172A); // Fond sections
  static const Color backgroundThird   = Color(0xFF1A2234); // Fond sections alt
  static const Color surface           = Color(0xFF1E293B); // Cards, modals
  static const Color surfaceVariant    = Color(0xFF293548); // Input bg, hover

  // ── TEXTES ─────────────────────────────────────────────────
  static const Color textPrimary       = Color(0xFFF1F5F9); // Titres (pas blanc pur)
  static const Color textSecondary     = Color(0xFFCBD5E1); // Corps
  static const Color textTertiary      = Color(0xFF94A3B8); // Sous-titres
  static const Color textHint          = Color(0xFF64748B); // Hints
  static const Color textDisabled      = Color(0xFF475569); // Désactivé

  // ── BORDURES ───────────────────────────────────────────────
  static const Color border            = Color(0xFF293548); // Bordure standard
  static const Color borderLight       = Color(0xFF1E293B); // Bordure légère
  static const Color borderFocus       = Color(0xFF3B82F6); // Focus inputs (bleu + clair)

  // ── OMBRES ─────────────────────────────────────────────────
  // En dark mode, les ombres sont moins visibles — utiliser border à la place
  static const Color shadow            = Color(0x1A000000);
  static const Color shadowMedium      = Color(0x33000000);
  static const Color shadowStrong      = Color(0x4D000000);

  // ── TOPBAR / NAVBAR ────────────────────────────────────────
  static const Color navbarBg          = Color(0xFF0F172A);
  static const Color navbarBorder      = Color(0xFF1E293B);
  static const Color navbarText        = Color(0xFFCBD5E1);

  // ── SIDEBAR ADMIN ──────────────────────────────────────────
  // La sidebar admin est déjà sombre — légèrement différente en dark mode
  static const Color adminSidebarBg    = Color(0xFF060D18); // encore plus sombre
  static const Color adminSidebarBorder= Color(0xFF0F172A);

  // ── SIDEBAR RECRUTEUR ──────────────────────────────────────
  // Devient sombre en dark mode (au lieu de blanc)
  static const Color recruteurSidebarBg= Color(0xFF0F172A);

  // ── DIVIDERS ───────────────────────────────────────────────
  static const Color divider           = Color(0xFF293548);
  static const Color dividerLight      = Color(0xFF1E293B);

  // ── INPUTS ─────────────────────────────────────────────────
  static const Color inputFill         = Color(0xFF293548);
  static const Color inputBorder       = Color(0xFF334155);
  static const Color inputFocusBorder  = Color(0xFF3B82F6);
  static const Color inputErrorBorder  = Color(0xFFEF4444);

  // ── OVERLAYS ───────────────────────────────────────────────
  static const Color overlay           = Color(0xCC000000);
  static const Color overlayLight      = Color(0x80000000);

  // ── SKELETON / SHIMMER ─────────────────────────────────────
  static const Color shimmerBase       = Color(0xFF1E293B);
  static const Color shimmerHighlight  = Color(0xFF293548);

  // ── COULEURS QUI NE CHANGENT PAS ───────────────────────────
  // (identiques dans les deux thèmes)
  // primary       : #1A56DB (bleu principal)
  // primaryDark   : #1E3A8A
  // accent        : #0EA5E9
  // success       : #10B981
  // warning       : #F59E0B
  // error         : #EF4444
}
```

---

## 5. ThemeData Flutter Complet

```dart
// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_extension.dart';

class AppTheme {

  // ── COULEURS COMMUNES (identiques dans les deux thèmes) ────
  static const Color _primary      = Color(0xFF1A56DB);
  static const Color _primaryDark  = Color(0xFF1E3A8A);
  static const Color _accent       = Color(0xFF0EA5E9);
  static const Color _success      = Color(0xFF10B981);
  static const Color _warning      = Color(0xFFF59E0B);
  static const Color _error        = Color(0xFFEF4444);

  // ═══════════════════════════════════════════════════════════
  // THÈME CLAIR
  // ═══════════════════════════════════════════════════════════
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: _primary,
      secondary: _accent,
      error: _error,
      background: const Color(0xFFFFFFFF),
      surface: const Color(0xFFFFFFFF),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: const Color(0xFF0F172A),
      onSurface: const Color(0xFF0F172A),
      onError: Colors.white,
      outline: const Color(0xFFE2E8F0),
      surfaceVariant: const Color(0xFFF8FAFC),
      onSurfaceVariant: const Color(0xFF64748B),
    ),

    // Typographie
    textTheme: _buildTextTheme(const Color(0xFF0F172A)),

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: const Color(0x14000000),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A)),
      iconTheme: const IconThemeData(color: Color(0xFF64748B)),
    ),

    // Scaffold
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),

    // Cards
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
    ),

    // Inputs
    inputDecorationTheme: _buildInputTheme(
      fillColor: const Color(0xFFF8FAFC),
      borderColor: const Color(0xFFE2E8F0),
      focusBorderColor: _primary,
      textColor: const Color(0xFF0F172A),
      hintColor: const Color(0xFFCBD5E1),
    ),

    // Boutons
    elevatedButtonTheme: _buildElevatedButtonTheme(),
    outlinedButtonTheme: _buildOutlinedButtonTheme(Colors.white),
    textButtonTheme: _buildTextButtonTheme(),

    // Dividers
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE2E8F0), thickness: 1, space: 1),

    // Checkbox
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) =>
        states.contains(MaterialState.selected) ? _primary : Colors.transparent),
      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) =>
        states.contains(MaterialState.selected) ? Colors.white : const Color(0xFF94A3B8)),
      trackColor: MaterialStateProperty.resolveWith((states) =>
        states.contains(MaterialState.selected)
            ? _primary : const Color(0xFFE2E8F0)),
    ),

    // Slider
    sliderTheme: SliderThemeData(
      activeTrackColor: _primary,
      thumbColor: _primary,
      overlayColor: _primary.withOpacity(0.12),
      inactiveTrackColor: const Color(0xFFE2E8F0),
    ),

    // TabBar
    tabBarTheme: TabBarTheme(
      labelColor: _primary,
      unselectedLabelColor: const Color(0xFF64748B),
      indicatorColor: _primary,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF1F5F9),
      selectedColor: const Color(0xFFEFF6FF),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
      labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
    ),

    // ProgressIndicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primary,
      linearTrackColor: Color(0xFFE2E8F0),
      circularTrackColor: Color(0xFFE2E8F0),
    ),

    // BottomSheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ),

    // Dialog
    dialogTheme: DialogTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14, color: const Color(0xFF64748B), height: 1.5),
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
    ),

    // PopupMenu
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      elevation: 8,
      shadowColor: const Color(0x1F000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      textStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF334155)),
    ),

    // Drawer
    drawerTheme: const DrawerThemeData(
      backgroundColor: Colors.white,
      elevation: 16,
    ),

    // Tooltip
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white),
    ),

    // Extension personnalisée
    extensions: [AppThemeExtension.light],
  );

  // ═══════════════════════════════════════════════════════════
  // THÈME SOMBRE
  // ═══════════════════════════════════════════════════════════
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: _primary,
      secondary: _accent,
      error: _error,
      background: const Color(0xFF0A0F1A),
      surface: const Color(0xFF1E293B),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: const Color(0xFFF1F5F9),
      onSurface: const Color(0xFFF1F5F9),
      onError: Colors.white,
      outline: const Color(0xFF293548),
      surfaceVariant: const Color(0xFF293548),
      onSurfaceVariant: const Color(0xFF94A3B8),
    ),

    // Typographie
    textTheme: _buildTextTheme(const Color(0xFFF1F5F9)),

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF0F172A),
      foregroundColor: const Color(0xFFF1F5F9),
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black26,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: const Color(0xFFF1F5F9)),
      iconTheme: const IconThemeData(color: Color(0xFF94A3B8)),
      surfaceTintColor: Colors.transparent,
    ),

    // Scaffold
    scaffoldBackgroundColor: const Color(0xFF0A0F1A),

    // Cards
    cardTheme: CardTheme(
      color: const Color(0xFF1E293B),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF293548)),
      ),
      clipBehavior: Clip.antiAlias,
    ),

    // Inputs
    inputDecorationTheme: _buildInputTheme(
      fillColor: const Color(0xFF293548),
      borderColor: const Color(0xFF334155),
      focusBorderColor: const Color(0xFF3B82F6),
      textColor: const Color(0xFFF1F5F9),
      hintColor: const Color(0xFF64748B),
    ),

    // Boutons
    elevatedButtonTheme: _buildElevatedButtonTheme(),
    outlinedButtonTheme: _buildOutlinedButtonTheme(const Color(0xFF1E293B)),
    textButtonTheme: _buildTextButtonTheme(),

    // Dividers
    dividerTheme: const DividerThemeData(
      color: Color(0xFF293548), thickness: 1, space: 1),

    // Checkbox
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) =>
        states.contains(MaterialState.selected) ? _primary : Colors.transparent),
      side: const BorderSide(color: Color(0xFF475569), width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) =>
        states.contains(MaterialState.selected)
            ? Colors.white : const Color(0xFF64748B)),
      trackColor: MaterialStateProperty.resolveWith((states) =>
        states.contains(MaterialState.selected)
            ? _primary : const Color(0xFF293548)),
    ),

    // Slider
    sliderTheme: SliderThemeData(
      activeTrackColor: _primary,
      thumbColor: _primary,
      overlayColor: _primary.withOpacity(0.12),
      inactiveTrackColor: const Color(0xFF293548),
    ),

    // TabBar
    tabBarTheme: TabBarTheme(
      labelColor: const Color(0xFF60A5FA),
      unselectedLabelColor: const Color(0xFF64748B),
      indicatorColor: const Color(0xFF60A5FA),
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF293548),
      selectedColor: const Color(0xFF1E3A8A),
      side: const BorderSide(color: Color(0xFF334155)),
      labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
    ),

    // ProgressIndicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primary,
      linearTrackColor: Color(0xFF293548),
      circularTrackColor: Color(0xFF293548),
    ),

    // BottomSheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ),

    // Dialog
    dialogTheme: DialogTheme(
      backgroundColor: const Color(0xFF1E293B),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF293548)),
      ),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w700,
        color: const Color(0xFFF1F5F9)),
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14, color: const Color(0xFF94A3B8), height: 1.5),
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF293548)),
      ),
      contentTextStyle: GoogleFonts.inter(
        color: const Color(0xFFF1F5F9), fontSize: 14),
    ),

    // PopupMenu
    popupMenuTheme: PopupMenuThemeData(
      color: const Color(0xFF1E293B),
      elevation: 8,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF293548)),
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 14, color: const Color(0xFFCBD5E1)),
    ),

    // Drawer
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color(0xFF0F172A),
      elevation: 16,
    ),

    // Tooltip
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: const Color(0xFF293548),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      textStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFF1F5F9)),
    ),

    // Extension personnalisée
    extensions: [AppThemeExtension.dark],
  );

  // ── MÉTHODES COMMUNES ──────────────────────────────────────

  static TextTheme _buildTextTheme(Color textColor) => TextTheme(
    displayLarge:  GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.w800, color: textColor),
    displayMedium: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w700, color: textColor),
    headlineLarge: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: textColor),
    headlineMedium:GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: textColor),
    headlineSmall: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
    titleLarge:    GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
    titleMedium:   GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: textColor),
    titleSmall:    GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: textColor),
    bodyLarge:     GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: textColor),
    bodyMedium:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: textColor),
    bodySmall:     GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: textColor),
    labelLarge:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
    labelMedium:   GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
    labelSmall:    GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
  );

  static InputDecorationTheme _buildInputTheme({
    required Color fillColor,
    required Color borderColor,
    required Color focusBorderColor,
    required Color textColor,
    required Color hintColor,
  }) => InputDecorationTheme(
    filled: true,
    fillColor: fillColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    hintStyle: GoogleFonts.inter(fontSize: 14, color: hintColor),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: borderColor, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: borderColor, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: focusBorderColor, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2.0),
    ),
    errorStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFEF4444)),
  );

  static ElevatedButtonThemeData _buildElevatedButtonTheme() =>
    ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1A56DB),
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
    ));

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(Color bg) =>
    OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF1A56DB),
      backgroundColor: bg,
      side: const BorderSide(color: Color(0xFF1A56DB), width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
    ));

  static TextButtonThemeData _buildTextButtonTheme() =>
    TextButtonThemeData(style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF1A56DB),
      textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
    ));
}
```

---

## 6. ThemeExtension — Couleurs Personnalisées

```dart
// lib/core/theme/theme_extension.dart
// Couleurs spécifiques à EmploiConnect non couvertes par ThemeData standard

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color sectionBg;          // Fond des sections alternées
  final Color cardBorder;         // Bordure des cards
  final Color sidebarAdminBg;     // Fond sidebar admin
  final Color sidebarRecruteurBg; // Fond sidebar recruteur
  final Color inputFill;          // Fond des champs de formulaire
  final Color shimmerBase;        // Couleur shimmer loading
  final Color shimmerHighlight;   // Couleur shimmer highlight
  final Color tagBg;              // Fond des badges/tags neutres
  final Color tagText;            // Texte des badges/tags neutres
  final Color successBg;          // Fond succès (vert clair)
  final Color warningBg;          // Fond warning (orange clair)
  final Color errorBg;            // Fond error (rouge clair)
  final Color infoBg;             // Fond info (bleu clair)
  final Color candidatIconBg;     // Fond icône candidat
  final Color recruteurIconBg;    // Fond icône recruteur
  final Color heroOverlay;        // Overlay du hero (gradient)
  final Color navbarShadow;       // Ombre de la navbar

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

  // ── MODE CLAIR ─────────────────────────────────────────────
  static const AppThemeExtension light = AppThemeExtension(
    sectionBg         : Color(0xFFF8FAFC),
    cardBorder        : Color(0xFFE2E8F0),
    sidebarAdminBg    : Color(0xFF0F172A),
    sidebarRecruteurBg: Color(0xFFFFFFFF),
    inputFill         : Color(0xFFF8FAFC),
    shimmerBase       : Color(0xFFE2E8F0),
    shimmerHighlight  : Color(0xFFF8FAFC),
    tagBg             : Color(0xFFF1F5F9),
    tagText           : Color(0xFF64748B),
    successBg         : Color(0xFFD1FAE5),
    warningBg         : Color(0xFFFEF3C7),
    errorBg           : Color(0xFFFEE2E2),
    infoBg            : Color(0xFFEFF6FF),
    candidatIconBg    : Color(0xFFEFF6FF),
    recruteurIconBg   : Color(0xFFECFDF5),
    heroOverlay       : Color(0xCC0F172A),
    navbarShadow      : Color(0x14000000),
  );

  // ── MODE SOMBRE ────────────────────────────────────────────
  static const AppThemeExtension dark = AppThemeExtension(
    sectionBg         : Color(0xFF0F172A),
    cardBorder        : Color(0xFF293548),
    sidebarAdminBg    : Color(0xFF060D18),
    sidebarRecruteurBg: Color(0xFF0F172A),
    inputFill         : Color(0xFF293548),
    shimmerBase       : Color(0xFF1E293B),
    shimmerHighlight  : Color(0xFF293548),
    tagBg             : Color(0xFF293548),
    tagText           : Color(0xFF94A3B8),
    successBg         : Color(0xFF064E3B),   // vert très sombre
    warningBg         : Color(0xFF451A03),   // orange très sombre
    errorBg           : Color(0xFF450A0A),   // rouge très sombre
    infoBg            : Color(0xFF1E3A5F),   // bleu très sombre
    candidatIconBg    : Color(0xFF1E3A5F),
    recruteurIconBg   : Color(0xFF064E3B),
    heroOverlay       : Color(0xE60F172A),   // plus opaque en dark
    navbarShadow      : Color(0x33000000),
  );

  // ── MÉTHODES REQUISES ──────────────────────────────────────
  @override
  AppThemeExtension copyWith({
    Color? sectionBg, Color? cardBorder, Color? sidebarAdminBg,
    Color? sidebarRecruteurBg, Color? inputFill, Color? shimmerBase,
    Color? shimmerHighlight, Color? tagBg, Color? tagText,
    Color? successBg, Color? warningBg, Color? errorBg, Color? infoBg,
    Color? candidatIconBg, Color? recruteurIconBg,
    Color? heroOverlay, Color? navbarShadow,
  }) => AppThemeExtension(
    sectionBg:          sectionBg ?? this.sectionBg,
    cardBorder:         cardBorder ?? this.cardBorder,
    sidebarAdminBg:     sidebarAdminBg ?? this.sidebarAdminBg,
    sidebarRecruteurBg: sidebarRecruteurBg ?? this.sidebarRecruteurBg,
    inputFill:          inputFill ?? this.inputFill,
    shimmerBase:        shimmerBase ?? this.shimmerBase,
    shimmerHighlight:   shimmerHighlight ?? this.shimmerHighlight,
    tagBg:              tagBg ?? this.tagBg,
    tagText:            tagText ?? this.tagText,
    successBg:          successBg ?? this.successBg,
    warningBg:          warningBg ?? this.warningBg,
    errorBg:            errorBg ?? this.errorBg,
    infoBg:             infoBg ?? this.infoBg,
    candidatIconBg:     candidatIconBg ?? this.candidatIconBg,
    recruteurIconBg:    recruteurIconBg ?? this.recruteurIconBg,
    heroOverlay:        heroOverlay ?? this.heroOverlay,
    navbarShadow:       navbarShadow ?? this.navbarShadow,
  );

  @override
  AppThemeExtension lerp(AppThemeExtension? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      sectionBg:          Color.lerp(sectionBg, other.sectionBg, t)!,
      cardBorder:         Color.lerp(cardBorder, other.cardBorder, t)!,
      sidebarAdminBg:     Color.lerp(sidebarAdminBg, other.sidebarAdminBg, t)!,
      sidebarRecruteurBg: Color.lerp(sidebarRecruteurBg, other.sidebarRecruteurBg, t)!,
      inputFill:          Color.lerp(inputFill, other.inputFill, t)!,
      shimmerBase:        Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight:   Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
      tagBg:              Color.lerp(tagBg, other.tagBg, t)!,
      tagText:            Color.lerp(tagText, other.tagText, t)!,
      successBg:          Color.lerp(successBg, other.successBg, t)!,
      warningBg:          Color.lerp(warningBg, other.warningBg, t)!,
      errorBg:            Color.lerp(errorBg, other.errorBg, t)!,
      infoBg:             Color.lerp(infoBg, other.infoBg, t)!,
      candidatIconBg:     Color.lerp(candidatIconBg, other.candidatIconBg, t)!,
      recruteurIconBg:    Color.lerp(recruteurIconBg, other.recruteurIconBg, t)!,
      heroOverlay:        Color.lerp(heroOverlay, other.heroOverlay, t)!,
      navbarShadow:       Color.lerp(navbarShadow, other.navbarShadow, t)!,
    );
  }
}

// ── HELPER EXTENSION ──────────────────────────────────────────
// Accès rapide depuis n'importe quel widget :
// final ext = context.themeExt;
extension ThemeExtensionContext on BuildContext {
  AppThemeExtension get themeExt =>
    Theme.of(this).extension<AppThemeExtension>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
```

---

## 7. ThemeProvider — Gestion d'État

```dart
// lib/core/theme/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  static const String _key = 'emploiconnect_theme_mode';
  AppThemeMode _mode = AppThemeMode.system;
  SharedPreferences? _prefs;

  AppThemeMode get mode => _mode;

  // Thème actuel calculé selon le mode et la luminosité du système
  ThemeMode get themeMode {
    switch (_mode) {
      case AppThemeMode.light:  return ThemeMode.light;
      case AppThemeMode.dark:   return ThemeMode.dark;
      case AppThemeMode.system: return ThemeMode.system;
    }
  }

  bool isDark(BuildContext context) {
    if (_mode == AppThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _mode == AppThemeMode.dark;
  }

  // Initialisation — charger le thème sauvegardé
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs?.getString(_key);
    if (saved != null) {
      _mode = AppThemeMode.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => AppThemeMode.system,
      );
    }
    notifyListeners();
  }

  // Changer le thème
  Future<void> setTheme(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    await _prefs?.setString(_key, mode.name);
    notifyListeners();
  }

  // Toggle rapide entre clair et sombre
  Future<void> toggleTheme(BuildContext context) async {
    final newMode = isDark(context) ? AppThemeMode.light : AppThemeMode.dark;
    await setTheme(newMode);
  }
}
```

---

## 8. Persistance du Thème

### Initialisation dans main.dart
```dart
// lib/main.dart — MISE À JOUR COMPLÈTE

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'app/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser le ThemeProvider avec le thème sauvegardé
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: const EmploiConnectApp(),
    ),
  );
}

class EmploiConnectApp extends StatelessWidget {
  const EmploiConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return AnimatedTheme(
      data: themeProvider.themeMode == ThemeMode.dark
          ? AppTheme.darkTheme
          : AppTheme.lightTheme,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: MaterialApp.router(
        title: 'EmploiConnect',
        debugShowCheckedModeBanner: false,

        // Thèmes
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeProvider.themeMode,

        // Router
        routerConfig: appRouter,
      ),
    );
  }
}
```

---

## 9. Toggle de Thème — Composants UI

### 9.1 Bouton Toggle Rapide (TopBar)
```dart
// lib/shared/widgets/theme_toggle_button.dart
// Icône soleil/lune dans le TopBar de tous les dashboards et la navbar

class ThemeToggleButton extends StatefulWidget {
  final bool showLabel; // Afficher "Clair/Sombre" à côté
  const ThemeToggleButton({super.key, this.showLabel = false});

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));
    _rotation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark(context);

    return Tooltip(
      message: isDark ? 'Passer en mode clair' : 'Passer en mode sombre',
      child: GestureDetector(
        onTap: () async {
          _controller.forward(from: 0);
          await themeProvider.toggleTheme(context);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF293548)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            RotationTransition(
              turns: _rotation,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim, child: child),
                child: Icon(
                  isDark
                      ? Icons.wb_sunny_outlined   // Mode sombre → affiche soleil
                      : Icons.dark_mode_outlined,  // Mode clair → affiche lune
                  key: ValueKey(isDark),
                  size: 18,
                  color: isDark
                      ? const Color(0xFFF59E0B)  // Soleil doré
                      : const Color(0xFF64748B), // Lune grise
                ),
              ),
            ),
            if (widget.showLabel) ...[
              const SizedBox(width: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  isDark ? 'Clair' : 'Sombre',
                  key: ValueKey(isDark),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }
}
```

### 9.2 Sélecteur de Thème (Page Paramètres)
```dart
// lib/shared/widgets/theme_selector_tile.dart
// Utilisé dans les pages Paramètres de tous les dashboards

class ThemeSelectorTile extends StatelessWidget {
  const ThemeSelectorTile({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.themeExt.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Titre section
        Row(children: [
          Icon(Icons.palette_outlined,
            color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Text('Apparence', style: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface)),
        ]),
        const SizedBox(height: 16),

        // 3 options : Clair | Sombre | Système
        Row(children: [
          Expanded(child: _ThemeOption(
            icon: Icons.wb_sunny_outlined,
            label: 'Clair',
            isSelected: themeProvider.mode == AppThemeMode.light,
            onTap: () => themeProvider.setTheme(AppThemeMode.light),
          )),
          const SizedBox(width: 10),
          Expanded(child: _ThemeOption(
            icon: Icons.dark_mode_outlined,
            label: 'Sombre',
            isSelected: themeProvider.mode == AppThemeMode.dark,
            onTap: () => themeProvider.setTheme(AppThemeMode.dark),
          )),
          const SizedBox(width: 10),
          Expanded(child: _ThemeOption(
            icon: Icons.settings_suggest_outlined,
            label: 'Système',
            isSelected: themeProvider.mode == AppThemeMode.system,
            onTap: () => themeProvider.setTheme(AppThemeMode.system),
          )),
        ]),
      ]),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon, required this.label,
    required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.10)
              : context.themeExt.inputFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : context.themeExt.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(children: [
          Icon(icon,
            size: 22,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}
```

---

## 10. Adaptation Homepage

```dart
// Modifications à apporter dans les widgets homepage :

// ── navbar_widget.dart ──────────────────────────────────────
// Remplacer Colors.white par Theme.of(context).colorScheme.surface
// Remplacer Color(0xFF334155) par Theme.of(context).colorScheme.onSurface
// Remplacer Color(0xFF64748B) par Theme.of(context).colorScheme.onSurfaceVariant
// Ajouter ThemeToggleButton() dans la navbar (avant les boutons Connexion/Inscription)

// ── hero_section_widget.dart ────────────────────────────────
// Hero : PAS de changement (images + overlay sombre restent)
// Le hero est toujours sombre — les 2 thèmes sont OK

// ── platform_section_widget.dart ───────────────────────────
// Container fond : context.themeExt.sectionBg (au lieu de Color(0xFFF8FAFC))
// Card fond : Theme.of(context).colorScheme.surface
// Card border : context.themeExt.cardBorder
// Titre : Theme.of(context).colorScheme.onBackground
// Texte corps : Theme.of(context).colorScheme.onSurfaceVariant
// Icône candidat bg : context.themeExt.candidatIconBg
// Icône recruteur bg : context.themeExt.recruteurIconBg

// ── tips_carousel_widget.dart ───────────────────────────────
// Fond section : context.themeExt.sectionBg
// Card fond : Theme.of(context).colorScheme.surface
// Card border : context.themeExt.cardBorder

// ── solutions_section_widget.dart ──────────────────────────
// Fond section : Theme.of(context).colorScheme.background
// Card fond : Theme.of(context).colorScheme.surface
// Card border : context.themeExt.cardBorder

// ── recent_jobs_section_widget.dart ────────────────────────
// Fond section : context.themeExt.sectionBg
// JobCard fond : Theme.of(context).colorScheme.surface
// JobCard border : context.themeExt.cardBorder
// Textes : couleurs dynamiques du thème

// ── footer_widget.dart ──────────────────────────────────────
// Footer : TOUJOURS sombre (Color(0xFF0F172A)) — ne change PAS
// Le footer est identique dans les deux thèmes

// RÈGLE GÉNÉRALE HOMEPAGE :
// Utiliser toujours Theme.of(context).xxx ou context.themeExt.xxx
// Ne jamais laisser de couleurs hardcodées (sauf footer et hero)
```

---

## 11. Adaptation Pages Auth

```dart
// ── login_screen.dart / register screens ────────────────────
// Panneau gauche : TOUJOURS gradient sombre (ne change pas)
// Panneau droit (fond) : Theme.of(context).colorScheme.surface
// Formulaire texte titres : Theme.of(context).colorScheme.onSurface
// Formulaire texte sous-titres : Theme.of(context).colorScheme.onSurfaceVariant
// Inputs : utilise InputDecorationTheme → automatiquement adapté
// Liens : Theme.of(context).colorScheme.primary
// Dividers : context.themeExt.cardBorder
// Cards inscription rapide : context.themeExt.inputFill + context.themeExt.cardBorder
// MobileAuthHeader : TOUJOURS gradient sombre (ne change pas)

// NOTE IMPORTANTE :
// Le panneau gauche Auth et le MobileAuthHeader utilisent le même
// gradient bleu sombre dans les DEUX thèmes.
// Seul le panneau DROIT s'adapte au thème.
```

---

## 12. Adaptation Admin Dashboard

```dart
// ── admin_sidebar.dart ──────────────────────────────────────
// La sidebar admin est TOUJOURS sombre (#0F172A en light, #060D18 en dark)
// Récupérer depuis : context.themeExt.sidebarAdminBg
// Légèrement plus sombre en dark mode pour garder le contraste

// ── admin_topbar.dart ────────────────────────────────────────
// Fond : Theme.of(context).colorScheme.surface
// Bordure : context.themeExt.cardBorder
// Texte titre : Theme.of(context).colorScheme.onSurface
// Barre recherche fond : context.themeExt.inputFill
// Barre recherche bordure : context.themeExt.cardBorder
// Ajouter ThemeToggleButton() dans le topbar admin

// ── admin_dashboard_page.dart ────────────────────────────────
// Fond page : Theme.of(context).colorScheme.background
// StatCard fond : Theme.of(context).colorScheme.surface
// StatCard bordure : context.themeExt.cardBorder
// Graphique fond : Theme.of(context).colorScheme.surface

// ── Tableaux (admin_data_table.dart) ─────────────────────────
// En-tête : Theme.of(context).colorScheme.surface
// Lignes alternées : alternance surface / sectionBg
// Hover : context.themeExt.infoBg (bleu sombre en dark)
// Texte header : Theme.of(context).colorScheme.onSurfaceVariant
```

---

## 13. Adaptation Recruteur Dashboard

```dart
// ── recruteur_sidebar.dart ───────────────────────────────────
// Fond sidebar :
//   Light mode → Colors.white (comme avant)
//   Dark mode  → context.themeExt.sidebarRecruteurBg (#0F172A)
// Bordure : context.themeExt.cardBorder
// Textes items :
//   Light : Color(0xFF64748B)
//   Dark  : Color(0xFF94A3B8)
// Item actif bg :
//   Light : Color(0xFFEFF6FF)
//   Dark  : Color(0xFF1E3A5F)
// Item actif texte :
//   Light : Color(0xFF1A56DB)
//   Dark  : Color(0xFF60A5FA)
// Logo entreprise fond :
//   Light : Color(0xFFEFF6FF)
//   Dark  : Color(0xFF1E3A5F)

// ── recruteur_topbar.dart ────────────────────────────────────
// Fond : Theme.of(context).colorScheme.surface
// Ajouter ThemeToggleButton()

// ── Pages recruteur ──────────────────────────────────────────
// Toutes les cards : Theme.of(context).colorScheme.surface + context.themeExt.cardBorder
// Tous les fonds de page : Theme.of(context).colorScheme.background
// Textes : couleurs dynamiques du thème

// ── Kanban board ─────────────────────────────────────────────
// Fond colonnes : context.themeExt.sectionBg
// Cards kanban : Theme.of(context).colorScheme.surface
// ── Messagerie ────────────────────────────────────────────────
// Bulles "moi" : Color(0xFF1A56DB) — ne change pas
// Bulles "autre" : Theme.of(context).colorScheme.surface
```

---

## 14. Adaptation Candidat Dashboard

```dart
// ── candidat_sidebar.dart ────────────────────────────────────
// Le gradient bleu de la sidebar candidat NE CHANGE PAS
// Il reste [#1E3A8A → #1A56DB] dans les deux thèmes
// Le gradient est déjà sombre → adapté aux deux modes

// ── candidat_topbar.dart ─────────────────────────────────────
// Fond : Theme.of(context).colorScheme.surface
// Ajouter ThemeToggleButton()

// ── candidat_dashboard_page.dart ─────────────────────────────
// Fond page : Theme.of(context).colorScheme.background
// Alerte complétion :
//   Light : Color(0xFF1A56DB).withOpacity(0.08) + border 0.20
//   Dark  : Color(0xFF1A56DB).withOpacity(0.15) + border 0.30
// Citation motivante : gradient reste le même (déjà sombre)

// ── recherche_offres_page.dart ───────────────────────────────
// FilterChip :
//   Sélectionné light : Color(0xFFEFF6FF)
//   Sélectionné dark  : Color(0xFF1E3A5F)
// OffreListCard :
//   Fond : Theme.of(context).colorScheme.surface
//   Border hover : Color(0xFF1A56DB) — même dans les deux thèmes

// ── candidature_timeline_card.dart ──────────────────────────
// Fond : Theme.of(context).colorScheme.surface
// Timeline — cercles complétés : Color(0xFF1A56DB) — ne change pas
// Timeline — cercles vides : context.themeExt.cardBorder

// ── profil_cv_page.dart ──────────────────────────────────────
// Sections fond : Theme.of(context).colorScheme.surface
// Panneau IA : gradient reste sombre (ne change pas)
// Score circulaire : fond context.themeExt.sectionBg

// ── apply_bottom_sheet.dart ──────────────────────────────────
// Fond : automatique depuis BottomSheetThemeData
```

---

## 15. Animations de Transition de Thème

```dart
// Transition principale : AnimatedTheme (natif Flutter)
// Durée : 300ms, Curves.easeInOut
// Défini dans main.dart → s'applique automatiquement à TOUT

// ── Toggle button animation ───────────────────────────────────
// Rotation de l'icône : 360° en 400ms (RotationTransition)
// Scale de l'icône : ScaleTransition 0→1 (AnimatedSwitcher)
// Container fond : AnimatedContainer 300ms (couleur bg)

// ── Changement de couleurs ────────────────────────────────────
// Toutes les couleurs via Theme → interpolées automatiquement
// par AnimatedTheme (Color.lerp entre les deux palettes)
// Résultat : transition douce et fluide sur toute l'interface

// ── Sidebar recruteur ─────────────────────────────────────────
// Blanc → sombre : AnimatedContainer sur le fond
// duration: 300ms, Curves.easeInOut

// ── Spécificités Dark Mode ─────────────────────────────────────
// Les ombres (boxShadow) disparaissent en dark mode
// → remplacées par des bordures plus prononcées
// AnimatedContainer gère la transition ombre → bordure

// ── Accessibilité ─────────────────────────────────────────────
// Si prefers-reduced-motion → durée réduite à 0ms
// Vérifier via : MediaQuery.of(context).disableAnimations
```

---

## 16. Règles de Remplacement des Couleurs Hardcodées

### Tableau de correspondance complet
```dart
// RÈGLE : remplacer TOUTES les couleurs hardcodées
// par des références dynamiques

// ── FONDS ────────────────────────────────────────────────────
// Color(0xFFFFFFFF)  → Theme.of(ctx).colorScheme.surface
// Color(0xFFF8FAFC)  → context.themeExt.sectionBg  OU
//                      Theme.of(ctx).colorScheme.surfaceVariant
// Color(0xFFF1F5F9)  → context.themeExt.sectionBg

// ── TEXTES ───────────────────────────────────────────────────
// Color(0xFF0F172A)  → Theme.of(ctx).colorScheme.onBackground
// Color(0xFF334155)  → Theme.of(ctx).colorScheme.onSurface
// Color(0xFF64748B)  → Theme.of(ctx).colorScheme.onSurfaceVariant
// Color(0xFF94A3B8)  → Theme.of(ctx).colorScheme.outline
// Color(0xFFCBD5E1)  → Theme.of(ctx).textTheme.bodySmall?.color

// ── BORDURES ─────────────────────────────────────────────────
// Color(0xFFE2E8F0)  → context.themeExt.cardBorder
// Color(0xFFF1F5F9)  → context.themeExt.cardBorder.withOpacity(0.5)

// ── CARDS ────────────────────────────────────────────────────
// BoxDecoration avec color: Colors.white →
//   color: Theme.of(ctx).colorScheme.surface
// BorderSide avec color: Color(0xFFE2E8F0) →
//   color: context.themeExt.cardBorder

// ── INPUTS ───────────────────────────────────────────────────
// fillColor: Color(0xFFF8FAFC) → context.themeExt.inputFill
// border Color(0xFFE2E8F0)    → context.themeExt.cardBorder

// ── ICÔNES DANS CONTAINERS ───────────────────────────────────
// Container bleu clair (candidat) : context.themeExt.candidatIconBg
// Container vert clair (recruteur): context.themeExt.recruteurIconBg
// Container bg générique          : context.themeExt.sectionBg

// ── BADGES / TAGS ────────────────────────────────────────────
// Fond neutre : context.themeExt.tagBg
// Texte neutre : context.themeExt.tagText
// Fond succès  : context.themeExt.successBg
// Fond warning : context.themeExt.warningBg
// Fond error   : context.themeExt.errorBg
// Fond info    : context.themeExt.infoBg

// ── CE QUI NE CHANGE PAS ─────────────────────────────────────
// Color(0xFF1A56DB) → GARDER tel quel (primaire)
// Color(0xFF10B981) → GARDER tel quel (succès)
// Color(0xFFEF4444) → GARDER tel quel (erreur)
// Color(0xFFF59E0B) → GARDER tel quel (warning)
// Gradient hero     → GARDER tel quel
// Gradient sidebar candidat → GARDER tel quel
// Gradient panneau auth gauche → GARDER tel quel
// Footer (#0F172A)  → GARDER tel quel
// Sidebar admin     → GARDER (utiliser context.themeExt.sidebarAdminBg)
```

---

## 17. Tests & Vérifications

### Checklist de test par section
```dart
// Pour chaque page, tester en mode CLAIR puis SOMBRE :

// HOMEPAGE
// ☐ Navbar : fond adapté, textes lisibles, toggle visible
// ☐ Hero : inchangé (image + overlay)
// ☐ Section Plateforme : fond adapté, cards lisibles
// ☐ Carrousel conseils : fond adapté, cartes lisibles
// ☐ Section Solutions : fond adapté, cards lisibles
// ☐ Section Offres : fond adapté, JobCards lisibles
// ☐ Footer : inchangé (toujours sombre)

// AUTH
// ☐ Panneau gauche : inchangé (gradient sombre)
// ☐ Panneau droit : fond adapté, formulaire lisible
// ☐ Inputs : fond adapté, texte visible, focus bleu visible
// ☐ Erreurs : rouge visible dans les deux thèmes
// ☐ MobileAuthHeader : inchangé (gradient sombre)

// ADMIN DASHBOARD
// ☐ Sidebar : encore plus sombre en dark (visible)
// ☐ TopBar : fond adapté, toggle présent
// ☐ Stat cards : fond adapté, textes lisibles
// ☐ Tableaux : alternance de fonds visible
// ☐ Badges status : lisibles dans les deux thèmes

// RECRUTEUR DASHBOARD
// ☐ Sidebar : blanche en light, sombre en dark
// ☐ Cards offres : fond adapté
// ☐ Kanban : colonnes et cards adaptées
// ☐ Messagerie : bulles distinctes dans les deux thèmes
// ☐ Formulaire offre : tous les steps adaptés

// CANDIDAT DASHBOARD
// ☐ Sidebar : gradient bleu INCHANGÉ dans les deux thèmes
// ☐ Dashboard : alerte complétion adaptée
// ☐ OffreListCard : fond et hover adaptés
// ☐ Timeline candidatures : cercles et lignes visibles
// ☐ Profil : toutes les sections adaptées
// ☐ BottomSheet postuler : fond adapté

// CONTRASTES (WCAG 2.1 AA minimum)
// ☐ Texte primaire sur fond : ratio ≥ 4.5:1
// ☐ Bouton bleu texte blanc : ratio ≥ 4.5:1
// ☐ Inputs : placeholder visible
// ☐ Badges : texte lisible sur fond coloré
```

### Utilitaire de débogage (développement seulement)
```dart
// Ajouter un bouton de débogage en développement :
// FloatingActionButton qui bascule rapidement entre les thèmes
// Ne pas inclure dans la build de production

if (kDebugMode)
  FloatingActionButton.small(
    onPressed: () => context.read<ThemeProvider>().toggleTheme(context),
    child: Icon(context.isDark ? Icons.wb_sunny : Icons.dark_mode),
  )
```

---

## 18. Critères d'Acceptation

### ✅ Système de Thème — Core
- [ ] `AppTheme.lightTheme` et `AppTheme.darkTheme` créés avec tous les composants
- [ ] `AppThemeExtension` créée avec les 17 couleurs personnalisées
- [ ] `ThemeProvider` créé avec `init()`, `setTheme()`, `toggleTheme()`
- [ ] `SharedPreferences` : thème persisté et rechargé au démarrage
- [ ] `main.dart` mis à jour avec `ChangeNotifierProvider` + `MaterialApp.router`
- [ ] Transition fluide `AnimatedTheme` 300ms entre les deux thèmes

### ✅ Composants UI
- [ ] `ThemeToggleButton` : icône soleil ↔ lune avec animation rotation 400ms
- [ ] `ThemeSelectorTile` : 3 options (Clair/Sombre/Système) avec sélection visuelle
- [ ] Toggle dans la navbar Homepage
- [ ] Toggle dans le TopBar Admin
- [ ] Toggle dans le TopBar Recruteur
- [ ] Toggle dans le TopBar Candidat
- [ ] `ThemeSelectorTile` dans les 3 pages Paramètres (Admin, Recruteur, Candidat)

### ✅ Homepage
- [ ] Navbar adapte fond + textes + toggle visible
- [ ] Hero section : inchangée (image toujours immersive)
- [ ] Toutes les sections adaptent fond et cards
- [ ] Footer reste toujours sombre (inchangé)

### ✅ Pages Auth
- [ ] Panneau gauche inchangé (gradient toujours sombre)
- [ ] Panneau droit fond blanc ↔ sombre
- [ ] Inputs adaptés via InputDecorationTheme
- [ ] Formulaires lisibles dans les deux thèmes

### ✅ Admin Dashboard
- [ ] Sidebar légèrement plus sombre en dark mode
- [ ] TopBar + pages adaptés
- [ ] Tableaux : alternance fonds visible en dark
- [ ] Badges status lisibles dans les deux thèmes

### ✅ Recruteur Dashboard
- [ ] Sidebar blanche → sombre (#0F172A) en dark mode
- [ ] Toutes les pages adaptées
- [ ] Kanban colonnes et cards adaptés
- [ ] Messagerie : bulles distinctes dans les deux thèmes

### ✅ Candidat Dashboard
- [ ] Sidebar gradient bleu IDENTIQUE dans les deux thèmes
- [ ] Toutes les pages adaptées
- [ ] OffreListCard hover visible en dark mode
- [ ] Timeline candidatures lisible en dark

### ✅ Qualité
- [ ] Zéro couleur hardcodée dans le code (sauf footer, hero, gradients permanents)
- [ ] Contrastes WCAG 2.1 AA respectés dans les deux thèmes
- [ ] Transition instantanée au toggle (pas de flash blanc/noir)
- [ ] Shimmer loading adapté aux deux thèmes
- [ ] Aucune erreur console Flutter
- [ ] Test : 375px / 768px / 1280px en mode clair ET sombre

---

*PRD EmploiConnect v2.3 — Système Thème Clair/Sombre — Flutter*
*Projet académique — Licence Professionnelle Génie Logiciel — Guinée 2025-2026*
*BARRY YOUSSOUF (22 000 46) · DIALLO ISMAILA (23 008 60)*
*Encadré par M. DIALLO BOUBACAR — CEO Rasenty*
*Cursor / Kirsoft AI — Phase 6 — Suite Candidat Dashboard validé*
