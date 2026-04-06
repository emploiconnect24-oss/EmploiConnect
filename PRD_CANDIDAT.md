# PRD — EmploiConnect · Tableau de Bord Candidat
## Product Requirements Document v2.2 — Candidate Dashboard
**Stack : Flutter (Dart) · GoRouter · Google Fonts (Poppins + Inter)**
**Outil : Cursor / Kirsoft AI**
**Module : Espace Candidat / Chercheur d'Emploi — Tableau de Bord Complet**
**Statut : Phase 5 — Suite Recruteur Dashboard validé**
**Date : Mars 2026**

---

> ### ⚠️ INSTRUCTIONS CRITIQUES POUR CURSOR
>
> 1. Homepage ✅ · Auth ✅ · Admin ✅ · Recruteur ✅ — NE PAS TOUCHER
> 2. **Même système de design** : AppColors, AppTextStyles, AppDimensions
> 3. **Même cohérence visuelle** : Poppins (titres) + Inter (corps)
> 4. Accessible UNIQUEMENT avec `role == 'candidat'`
> 5. Route protégée : `/dashboard` → redirection `/connexion` si non candidat
> 6. Design objectif : **chaleureux, motivant, encourageant**
>    Différence vs Admin/Recruteur : plus personnel, plus humain,
>    centré sur le parcours individuel du candidat
>    Référence : LinkedIn + Glassdoor + une app mobile moderne
> 7. Implémenter **dans l'ordre exact** de ce PRD

---

## Table des Matières

1. [Vue d'ensemble Candidat](#1-vue-densemble-candidat)
2. [Architecture du Dashboard](#2-architecture-du-dashboard)
3. [Système de Design Candidat](#3-système-de-design-candidat)
4. [Layout Principal — CandidatShell](#4-layout-principal--candidatshell)
5. [Sidebar Navigation Candidat](#5-sidebar-navigation-candidat)
6. [TopBar Candidat](#6-topbar-candidat)
7. [Page Vue d'ensemble — Accueil Candidat](#7-page-vue-densemble--accueil-candidat)
8. [Page Mon Profil & CV](#8-page-mon-profil--cv)
9. [Page Recherche d'Offres](#9-page-recherche-doffres)
10. [Page Détail d'une Offre](#10-page-détail-dune-offre)
11. [Page Mes Candidatures](#11-page-mes-candidatures)
12. [Page Offres Recommandées par IA](#12-page-offres-recommandées-par-ia)
13. [Page Offres Sauvegardées](#13-page-offres-sauvegardées)
14. [Page Messagerie Candidat](#14-page-messagerie-candidat)
15. [Page Conseils & Ressources](#15-page-conseils--ressources)
16. [Page Alertes Emploi](#16-page-alertes-emploi)
17. [Page Notifications](#17-page-notifications)
18. [Page Paramètres Compte](#18-page-paramètres-compte)
19. [Composants Partagés Candidat](#19-composants-partagés-candidat)
20. [Routing Candidat Complet](#20-routing-candidat-complet)
21. [Animations & Micro-interactions](#21-animations--micro-interactions)
22. [Responsive Dashboard Candidat](#22-responsive-dashboard-candidat)
23. [Critères d'Acceptation](#23-critères-dacceptation)

---

## 1. Vue d'ensemble Candidat

### Rôle du Candidat
Le chercheur d'emploi dispose d'un espace personnel pour :
- Créer et optimiser son profil et son CV en ligne
- Rechercher des offres avec filtres avancés
- Recevoir des recommandations personnalisées par l'IA
- Postuler directement depuis la plateforme
- Suivre l'état de toutes ses candidatures
- Sauvegarder les offres intéressantes
- Communiquer avec les recruteurs
- Accéder à des conseils et ressources carrière
- Configurer des alertes emploi automatiques

### Pages du Dashboard Candidat
| # | Page | Route | Icône |
|---|------|-------|-------|
| 1 | Vue d'ensemble | `/dashboard` | `dashboard` |
| 2 | Mon Profil & CV | `/dashboard/profil` | `person` |
| 3 | Rechercher des offres | `/dashboard/offres` | `search` |
| 4 | Mes Candidatures | `/dashboard/candidatures` | `assignment` |
| 5 | Recommandations IA | `/dashboard/recommandations` | `auto_awesome` |
| 6 | Offres sauvegardées | `/dashboard/sauvegardes` | `bookmark` |
| 7 | Messagerie | `/dashboard/messages` | `chat` |
| 8 | Conseils & Ressources | `/dashboard/conseils` | `lightbulb` |
| 9 | Alertes emploi | `/dashboard/alertes` | `notifications_active` |
| 10 | Notifications | `/dashboard/notifications` | `notifications` |
| 11 | Paramètres | `/dashboard/parametres` | `settings` |

---

## 2. Architecture du Dashboard

### Structure des Fichiers
```
lib/
├── screens/
│   └── candidat/
│       ├── candidat_shell.dart
│       ├── pages/
│       │   ├── candidat_dashboard_page.dart
│       │   ├── profil_cv_page.dart
│       │   ├── recherche_offres_page.dart
│       │   ├── offre_detail_page.dart
│       │   ├── mes_candidatures_page.dart
│       │   ├── recommandations_ia_page.dart
│       │   ├── offres_sauvegardees_page.dart
│       │   ├── messagerie_candidat_page.dart
│       │   ├── conseils_ressources_page.dart
│       │   ├── alertes_emploi_page.dart
│       │   ├── notifications_candidat_page.dart
│       │   └── parametres_candidat_page.dart
│       └── widgets/
│           ├── candidat_sidebar.dart
│           ├── candidat_topbar.dart
│           ├── offre_list_card.dart
│           ├── candidature_timeline_card.dart
│           ├── profil_completion_bar.dart
│           ├── cv_section_editor.dart
│           ├── skill_chip_editor.dart
│           ├── alerte_card.dart
│           ├── conseil_card.dart
│           ├── apply_bottom_sheet.dart
│           └── ia_score_card.dart
├── models/
│   ├── candidat_profil.dart
│   ├── candidature_candidat.dart
│   ├── offre_sauvegardee.dart
│   └── alerte_emploi.dart
└── services/
    ├── profil_service.dart
    ├── candidature_candidat_service.dart
    └── alerte_service.dart
```

### Layout Global
```
╔══════════════════════════════════════════════════════════════╗
║  SIDEBAR DÉGRADÉE (240px)  │  TOPBAR (64px)                 ║
║  ────────────────────────  │  ────────────────────────────  ║
║                            │                                ║
║  Avatar + Prénom Nom       │  Titre page  [🔔] [🔍] [👤]   ║
║  Complétion profil 72%     │                                ║
║  ████████░░ 72%            │  ══════════════════════════    ║
║                            │                                ║
║  ─ MON ESPACE ─            │                                ║
║  🏠 Vue d'ensemble         │      CONTENU DE LA PAGE        ║
║  👤 Mon Profil & CV        │                                ║
║  📋 Mes candidatures (5)   │      (scrollable)              ║
║  🔖 Offres sauvegardées(3) │                                ║
║                            │                                ║
║  ─ EXPLORER ─              │                                ║
║  🔍 Rechercher offres      │                                ║
║  🤖 Recommandations IA(12) │                                ║
║  🔔 Alertes emploi (2)     │                                ║
║                            │                                ║
║  ─ COMMUNICATION ─         │                                ║
║  💬 Messagerie (1)         │                                ║
║  🔔 Notifications (3)      │                                ║
║                            │                                ║
║  ─ RESSOURCES ─            │                                ║
║  💡 Conseils carrière      │                                ║
║                            │                                ║
║  ─ COMPTE ─                │                                ║
║  ⚙️ Paramètres             │                                ║
║  🚪 Déconnexion            │                                ║
╚══════════════════════════════════════════════════════════════╝
```

---

## 3. Système de Design Candidat

### Identité Visuelle — Chaleureux & Motivant
```dart
// ADMIN     : Sidebar sombre, tons froids, supervision globale
// RECRUTEUR : Sidebar blanche, tons bleus/verts, productivité
// CANDIDAT  : Sidebar avec gradient subtil, tons bleus/indigo,
//             ambiance encourageante, personnelle, mobile-first

// Différences clés :
// - Avatar du candidat bien visible en haut de sidebar
// - Barre de complétion du profil dans la sidebar
// - Tons plus doux, plus de rondeurs (radius 14px sur les cards)
// - Section "Motivation" sur le dashboard (citations inspirantes)
// - Interface pensée avant tout pour mobile (candidats = mobiles)
```

### Couleurs Spécifiques Candidat
```dart
class CandidatColors {
  // Sidebar avec gradient subtil
  static const Color sidebarTop     = Color(0xFF1E3A8A); // Haut (bleu foncé)
  static const Color sidebarBottom  = Color(0xFF1A56DB); // Bas (bleu principal)
  // Textes sidebar
  static const Color sidebarText    = Color(0xCCFFFFFF); // Blanc 80%
  static const Color sidebarTextActive = Color(0xFFFFFFFF); // Blanc pur actif
  static const Color sidebarItemActiveBg = Color(0x1FFFFFFF); // Fond actif blanc 12%
  static const Color sidebarSection = Color(0x80FFFFFF); // Titres sections 50%

  // Contenu
  static const Color contentBg      = Color(0xFFF8FAFC);
  static const Color cardBg         = Color(0xFFFFFFFF);

  // Complétion profil
  static const Color completionLow  = Color(0xFFEF4444); // < 40%
  static const Color completionMid  = Color(0xFFF59E0B); // 40-70%
  static const Color completionHigh = Color(0xFF10B981); // > 70%
  static const Color completionBg   = Color(0x33FFFFFF); // fond barre

  // Statuts candidatures
  static const Color statEnvoyee    = Color(0xFF1A56DB);
  static const Color statEnvoyeeBg  = Color(0xFFEFF6FF);
  static const Color statEnExamen   = Color(0xFFF59E0B);
  static const Color statEnExamenBg = Color(0xFFFEF3C7);
  static const Color statEntretien  = Color(0xFF8B5CF6);
  static const Color statEntretienBg= Color(0xFFF5F3FF);
  static const Color statAcceptee   = Color(0xFF10B981);
  static const Color statAccepteeBg = Color(0xFFD1FAE5);
  static const Color statRefusee    = Color(0xFFEF4444);
  static const Color statRefuseeBg  = Color(0xFFFEE2E2);

  // Badges IA
  static const Color iaBadgeBg      = Color(0xFF1A56DB);
  static const Color iaBadgeText    = Color(0xFFFFFFFF);

  // Offres
  static const Color offreSaved     = Color(0xFFF59E0B);
  static const Color offreNew       = Color(0xFF10B981);  // Moins de 24h
  static const Color offreUrgent    = Color(0xFFEF4444);  // Expire bientôt
}
```

### Barre de Complétion du Profil
```dart
// Calculée automatiquement selon les sections remplies
// Chaque section vaut un % :
// Photo              : +10%
// Nom + Prénom       : +5%  (pré-rempli)
// Titre professionnel: +10%
// À propos           : +10%
// Expériences (≥1)   : +15%
// Formations (≥1)    : +10%
// Compétences (≥3)   : +10%
// Langues (≥1)       : +5%
// CV uploadé         : +15%
// Photo de profil    : +10%
// TOTAL              : 100%

// Couleur selon %:
// < 40%  → rouge  (incomplet)
// 40-70% → orange (en cours)
// > 70%  → vert   (bon profil)
// 100%   → or/gradient (profil parfait)
```

---

## 4. Layout Principal — CandidatShell

```dart
// lib/screens/candidat/candidat_shell.dart

class CandidatShell extends StatefulWidget {
  final Widget child;
  const CandidatShell({super.key, required this.child});
  @override
  State<CandidatShell> createState() => _CandidatShellState();
}

class _CandidatShellState extends State<CandidatShell> {

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: isMobile ? const CandidatSidebar(isDrawer: true) : null,
      body: Row(children: [

        // Sidebar fixe (desktop)
        if (!isMobile) const CandidatSidebar(),

        // Zone principale
        Expanded(child: Column(children: [

          // TopBar
          const CandidatTopBar(),

          // Page active
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: CurveTween(curve: Curves.easeOut).animate(anim),
                child: child,
              ),
              child: widget.child,
            ),
          ),
        ])),
      ]),
    );
  }
}
```

---

## 5. Sidebar Navigation Candidat

```dart
// lib/screens/candidat/widgets/candidat_sidebar.dart
// SIDEBAR AVEC GRADIENT BLEU — fond dégradé, texte blanc

class CandidatSidebar extends StatelessWidget {
  final bool isDrawer;
  const CandidatSidebar({super.key, this.isDrawer = false});

  @override
  Widget build(BuildContext context) {
    final candidat = context.watch<CandidatProvider>().profil;
    final currentRoute = GoRouterState.of(context).uri.path;
    final completion = _calculateCompletion(candidat);

    return Container(
      width: 240,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E3A8A), Color(0xFF1A56DB)],
        ),
      ),
      child: Column(children: [

        // ── Avatar & Profil ──────────────────────────────────
        _buildProfileHeader(candidat, completion),

        // ── Menu ────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(children: [

              _buildSection('MON ESPACE', [
                _SItem('Vue d\'ensemble', Icons.dashboard_outlined,
                  Icons.dashboard_rounded, '/dashboard'),
                _SItem('Mon Profil & CV', Icons.person_outline,
                  Icons.person_rounded, '/dashboard/profil'),
                _SItem('Mes candidatures', Icons.assignment_outlined,
                  Icons.assignment_rounded, '/dashboard/candidatures',
                  badge: '5', badgeColor: const Color(0xFF10B981)),
                _SItem('Offres sauvegardées', Icons.bookmark_outline,
                  Icons.bookmark_rounded, '/dashboard/sauvegardes',
                  badge: '3'),
              ]),

              _buildSection('EXPLORER', [
                _SItem('Rechercher des offres', Icons.search_outlined,
                  Icons.search_rounded, '/dashboard/offres'),
                _SItem('Recommandations IA', Icons.auto_awesome_outlined,
                  Icons.auto_awesome_rounded, '/dashboard/recommandations',
                  badge: '12', badgeColor: Colors.white),
                _SItem('Alertes emploi', Icons.notifications_active_outlined,
                  Icons.notifications_active_rounded, '/dashboard/alertes',
                  badge: '2'),
              ]),

              _buildSection('COMMUNICATION', [
                _SItem('Messagerie', Icons.chat_bubble_outline,
                  Icons.chat_bubble_rounded, '/dashboard/messages',
                  badge: '1', badgeColor: const Color(0xFFEF4444)),
                _SItem('Notifications', Icons.notifications_outlined,
                  Icons.notifications_rounded, '/dashboard/notifications',
                  badge: '3'),
              ]),

              _buildSection('RESSOURCES', [
                _SItem('Conseils carrière', Icons.lightbulb_outline,
                  Icons.lightbulb_rounded, '/dashboard/conseils'),
              ]),

              _buildSection('COMPTE', [
                _SItem('Paramètres', Icons.settings_outlined,
                  Icons.settings_rounded, '/dashboard/parametres'),
              ]),
            ]),
          ),
        ),

        // ── Déconnexion ──────────────────────────────────────
        _buildLogoutButton(context),
      ]),
    );
  }

  // Header avec avatar, nom, complétion
  Widget _buildProfileHeader(CandidatProfil? profil, int completion) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(children: [
        // Avatar
        Stack(children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withOpacity(0.2),
            backgroundImage: profil?.photoUrl != null
                ? NetworkImage(profil!.photoUrl!) : null,
            child: profil?.photoUrl == null
                ? Text(
                    '${profil?.firstName?[0] ?? 'C'}${profil?.lastName?[0] ?? ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 22, fontWeight: FontWeight.w700,
                      color: Colors.white))
                : null,
          ),
          // Badge photo (si pas de photo)
          if (profil?.photoUrl == null)
            Positioned(bottom: 0, right: 0, child: Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 12),
            )),
        ]),
        const SizedBox(height: 10),

        // Nom
        Text(
          profil != null
              ? '${profil.firstName} ${profil.lastName}'
              : 'Mon profil',
          style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
          textAlign: TextAlign.center,
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          profil?.title ?? 'Ajouter un titre professionnel',
          style: GoogleFonts.inter(
            fontSize: 11, color: Colors.white.withOpacity(0.70)),
          textAlign: TextAlign.center,
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),

        // Barre de complétion
        Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Complétion du profil', style: GoogleFonts.inter(
              fontSize: 10, color: Colors.white.withOpacity(0.70))),
            Text('$completion%', style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: _completionColor(completion))),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: completion / 100,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                _completionColor(completion)),
              minHeight: 6,
            ),
          ),
          if (completion < 100) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {}, // Navigate to profil
              child: Text('Améliorer mon profil →', style: GoogleFonts.inter(
                fontSize: 10, color: Colors.white.withOpacity(0.80),
                decoration: TextDecoration.underline,
                decorationColor: Colors.white.withOpacity(0.80))),
            ),
          ],
        ]),
      ]),
    );
  }

  Widget _buildSection(String title, List<_SItem> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
        child: Text(title, style: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.50), letterSpacing: 0.8)),
      ),
      ...items.map((item) => _buildItem(item)),
    ]);
  }

  Widget _buildItem(_SItem item) {
    return Builder(builder: (context) {
      final currentRoute = GoRouterState.of(context).uri.path;
      final isActive = currentRoute == item.route ||
          (item.route != '/dashboard' && currentRoute.startsWith(item.route));

      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () => context.go(item.route),
            borderRadius: BorderRadius.circular(8),
            hoverColor: Colors.white.withOpacity(0.10),
            splashColor: Colors.white.withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: 18,
                  color: isActive
                      ? Colors.white
                      : Colors.white.withOpacity(0.65),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(item.label, style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? Colors.white
                      : Colors.white.withOpacity(0.75),
                ))),
                if (item.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: (item.badgeColor ?? Colors.white).withOpacity(0.20),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: (item.badgeColor ?? Colors.white).withOpacity(0.40)),
                    ),
                    child: Text(item.badge!, style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: item.badgeColor ?? Colors.white)),
                  ),
              ]),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildLogoutButton(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: Colors.white.withOpacity(0.10))),
    ),
    child: InkWell(
      onTap: () => context.go('/connexion'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          Icon(Icons.logout_outlined, size: 18,
            color: Colors.white.withOpacity(0.50)),
          const SizedBox(width: 10),
          Text('Déconnexion', style: GoogleFonts.inter(
            fontSize: 14, color: Colors.white.withOpacity(0.60))),
        ]),
      ),
    ),
  );

  Color _completionColor(int pct) {
    if (pct < 40) return const Color(0xFFEF4444);
    if (pct < 70) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  int _calculateCompletion(CandidatProfil? p) {
    if (p == null) return 5;
    int score = 5; // Nom de base
    if (p.photoUrl != null) score += 10;
    if (p.title != null && p.title!.isNotEmpty) score += 10;
    if (p.about != null && p.about!.length >= 50) score += 10;
    if (p.experiences.isNotEmpty) score += 15;
    if (p.formations.isNotEmpty) score += 10;
    if (p.skills.length >= 3) score += 10;
    if (p.languages.isNotEmpty) score += 5;
    if (p.cvUrl != null) score += 15;
    if (p.phoneVerified) score += 5;
    if (p.city != null) score += 5;
    return score.clamp(0, 100);
  }
}
```

---

## 6. TopBar Candidat

```dart
// lib/screens/candidat/widgets/candidat_topbar.dart

class CandidatTopBar extends StatelessWidget {
  const CandidatTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1024;
    final currentRoute = GoRouterState.of(context).uri.path;

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [BoxShadow(
          color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [

        // Hamburger (mobile)
        if (isMobile) Builder(builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF64748B)),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        )),

        // Titre de la page
        Text(_getPageTitle(currentRoute), style: GoogleFonts.poppins(
          fontSize: 17, fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A))),

        const Spacer(),

        // Barre de recherche rapide (desktop)
        if (!isMobile)
          _QuickSearchBar(),

        const SizedBox(width: 12),

        // Bouton postuler rapidement
        if (!isMobile)
          TextButton.icon(
            icon: const Icon(Icons.bolt_rounded, size: 16),
            label: Text('Postuler vite', style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1A56DB),
              backgroundColor: const Color(0xFFEFF6FF),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => context.push('/dashboard/offres'),
          ),

        const SizedBox(width: 12),

        // Notifications
        Stack(children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
              color: Color(0xFF64748B)),
            onPressed: () => context.push('/dashboard/notifications'),
          ),
          Positioned(top: 8, right: 8, child: Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444), shape: BoxShape.circle),
          )),
        ]),

        // Avatar candidat
        GestureDetector(
          onTap: () => context.push('/dashboard/profil'),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF1A56DB),
            child: Text('M', style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }

  String _getPageTitle(String route) {
    const titles = {
      '/dashboard': 'Mon tableau de bord',
      '/dashboard/profil': 'Mon Profil & CV',
      '/dashboard/offres': 'Rechercher des offres',
      '/dashboard/candidatures': 'Mes candidatures',
      '/dashboard/recommandations': 'Recommandations IA',
      '/dashboard/sauvegardes': 'Offres sauvegardées',
      '/dashboard/messages': 'Messagerie',
      '/dashboard/conseils': 'Conseils & Ressources',
      '/dashboard/alertes': 'Alertes emploi',
      '/dashboard/notifications': 'Notifications',
      '/dashboard/parametres': 'Paramètres',
    };
    return titles[route] ?? 'EmploiConnect';
  }
}
```

---

## 7. Page Vue d'ensemble — Accueil Candidat

### Wireframe
```
┌─────────────────────────────────────────────────────────────────┐
│  Bonjour Mamadou ! 👋  Voici vos opportunités du jour.         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ⚠️ Complétez votre profil pour obtenir de meilleures offres   │
│  ████████░░  72%   [Compléter maintenant →]                    │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │ 📋   5  │  │ 🤖  12  │  │ 🔖   3  │  │ 👁️  47  │       │
│  │Candidat. │  │Recommand.│  │Sauvegard.│  │  Vues    │       │
│  │en cours  │  │  IA      │  │          │  │ profil   │       │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │
├─────────────────────────────────────────────────────────────────┤
│  🤖 Offres recommandées pour vous aujourd'hui    [Voir tout →] │
│  ┌────────────────────┐ ┌────────────────────┐                 │
│  │ 💼 Dev. Flutter    │ │ 💼 UX Designer     │                 │
│  │ Orange Guinée      │ │ Ecobank Guinée      │                 │
│  │ Conakry · CDI      │ │ Conakry · CDI       │                 │
│  │ Score IA : 94% ⭐  │ │ Score IA : 88%      │                 │
│  │ [Postuler] [Sauver]│ │ [Postuler] [Sauver] │                 │
│  └────────────────────┘ └────────────────────┘                 │
├─────────────────────────────────────────────────────────────────┤
│  📋 Suivi de mes candidatures                   [Voir tout →]  │
│  ● Orange Guinée · Dev Flutter  → En examen  · il y a 2j      │
│  ● MTN Guinée · Data Analyst    → Entretien  · 28 Mars 14h00  │
│  ● ONG Plan Int. · Chef Projet  → Envoyée    · il y a 5j      │
├─────────────────────────────────────────────────────────────────┤
│  💡 Citation du jour                                            │
│  "Le succès appartient à ceux qui commencent." — Commençons !  │
│                                                                 │
│  🔔 Nouvelles offres correspondant à vos alertes (3)           │
│  [Voir les nouvelles offres →]                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Code Flutter
```dart
// lib/screens/candidat/pages/candidat_dashboard_page.dart

class CandidatDashboardPage extends StatelessWidget {
  const CandidatDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Bienvenue
        _buildWelcomeHeader(context),
        const SizedBox(height: 16),

        // Alerte complétion profil (si < 80%)
        _buildProfileCompletionAlert(context, completion: 72),
        const SizedBox(height: 20),

        // 4 stat cards
        _buildStatsRow(),
        const SizedBox(height: 24),

        // Recommandations IA
        _buildIARecommendations(context),
        const SizedBox(height: 24),

        // Suivi candidatures
        _buildCandidaturesSuivi(context),
        const SizedBox(height: 24),

        // Citation motivante
        _buildMotivationQuote(),
        const SizedBox(height: 24),

        // Nouvelles offres alertes
        _buildNewAlertsSection(context),
      ]),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Bonjour' : hour < 18 ? 'Bon après-midi' : 'Bonsoir';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$greeting, Mamadou ! 👋', style: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text('Voici vos opportunités du jour.',
            style: GoogleFonts.inter(
              fontSize: 14, color: const Color(0xFF64748B))),
        ]),
        // Bouton postuler rapidement
        ElevatedButton.icon(
          icon: const Icon(Icons.search_rounded, size: 16),
          label: Text('Explorer les offres', style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => context.push('/dashboard/offres'),
        ),
      ],
    );
  }

  Widget _buildProfileCompletionAlert(BuildContext context, {required int completion}) {
    if (completion >= 90) return const SizedBox.shrink();
    return FadeInDown(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A56DB).withOpacity(0.08),
              const Color(0xFF0EA5E9).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1A56DB).withOpacity(0.20)),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.trending_up_rounded,
              color: Color(0xFF1A56DB), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Votre profil est complété à $completion%',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A))),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: completion / 100,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF1A56DB)),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 4),
            Text('Un profil complet reçoit 3x plus de vues',
              style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFF64748B))),
          ])),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56DB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            onPressed: () => context.push('/dashboard/profil'),
            child: const Text('Compléter'),
          ),
        ]),
      ),
    );
  }

  Widget _buildStatsRow() {
    final stats = [
      _CStat('Candidatures', '5', 'en cours',
        Icons.assignment_rounded, const Color(0xFF1A56DB), const Color(0xFFEFF6FF)),
      _CStat('Recommandations', '12', 'nouvelles offres IA',
        Icons.auto_awesome_rounded, const Color(0xFF8B5CF6), const Color(0xFFF5F3FF)),
      _CStat('Sauvegardées', '3', 'offres favorites',
        Icons.bookmark_rounded, const Color(0xFFF59E0B), const Color(0xFFFEF3C7)),
      _CStat('Vues profil', '47', 'ce mois',
        Icons.visibility_rounded, const Color(0xFF10B981), const Color(0xFFECFDF5)),
    ];
    return Row(children: stats.asMap().entries.map((e) => Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: e.key < 3 ? 14 : 0),
        child: FadeInUp(
          delay: Duration(milliseconds: e.key * 80),
          child: _CandidatStatCard(stat: e.value),
        ),
      ),
    )).toList());
  }

  Widget _buildMotivationQuote() {
    final quotes = [
      'Le succès appartient à ceux qui commencent.',
      'Chaque candidature est un pas vers votre réussite.',
      'Votre prochaine opportunité est à portée de main.',
      'Les grandes choses commencent par une petite action.',
    ];
    final today = DateTime.now().day % quotes.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1A56DB)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        const Icon(Icons.format_quote_rounded, color: Colors.white38, size: 32),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(quotes[today], style: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w600,
            color: Colors.white, height: 1.4)),
          const SizedBox(height: 4),
          Text('Citation du jour · EmploiConnect', style: GoogleFonts.inter(
            fontSize: 11, color: Colors.white.withOpacity(0.60))),
        ])),
      ]),
    );
  }
}
```

---

## 8. Page Mon Profil & CV

### Concept
```
Page de gestion complète du profil professionnel.
Divisée en sections éditables, avec indicateur de complétion.
Chaque section est une Card avec bouton "Modifier".
```

### Sections du Profil

```dart
// SECTION 1 : Photo & Identité
// - Photo de profil (upload, cercle)
// - Prénom + Nom
// - Titre professionnel (ex: "Développeur Flutter Senior")
// - Localisation (ville, Guinée)
// - Téléphone
// - Email (non modifiable, affiché seulement)
// - LinkedIn (optionnel)
// - Portfolio / Site web (optionnel)
// - Disponibilité (SegmentedButton) :
//   Immédiatement | Dans 1 mois | Dans 3 mois | En poste (pas dispo)

// SECTION 2 : À propos
// - Zone de texte riche (min 100, max 600 chars)
// - Compteur de caractères
// - Conseils intégrés : "Parlez de vos ambitions et de ce qui vous motive"

// SECTION 3 : Expériences Professionnelles
// - Liste d'expériences (ordre chronologique inverse)
// - Chaque expérience :
//   Poste | Entreprise | Ville | Date début - Date fin | En cours (checkbox)
//   Description des missions (textarea, max 300 chars)
// - Bouton [+ Ajouter une expérience]
// - Drag pour réordonner

// SECTION 4 : Formations
// - Liste de formations
// - Chaque formation :
//   Diplôme | Établissement | Ville | Année
//   Mention (optionnel)
// - Bouton [+ Ajouter une formation]

// SECTION 5 : Compétences
// - Chips éditables avec niveau
// - Niveau par compétence : Débutant | Intermédiaire | Avancé | Expert
// - Max 20 compétences
// - Bouton [+ Ajouter une compétence]
// - Suggestions automatiques basées sur le titre de poste

// SECTION 6 : Langues
// - Chips avec niveau
// - Niveaux : Notions | Intermédiaire | Courant | Bilingue | Langue maternelle
// - Langues suggérées : Français | Pular | Malinké | Soussou | Anglais | Arabe

// SECTION 7 : Mon CV
// - Zone d'upload (PDF ou DOCX, max 5MB)
// - Aperçu du CV si déjà uploadé (nom du fichier + date)
// - Bouton [Télécharger mon CV] (pour le voir)
// - Bouton [Remplacer le CV]
// - Bouton [Supprimer le CV]
// - Analyse IA du CV (si CV uploadé) :
//   "Votre CV mentionne : Flutter, Dart, Firebase, REST API, Git"
//   "Score IA de votre profil : 87/100"
//   Suggestions d'amélioration

// SECTION 8 : Visibilité du profil
// - Mon profil est visible par les recruteurs (Toggle on/off)
// - Recevoir des propositions de contact (Toggle)
```

### Code Flutter
```dart
// lib/screens/candidat/pages/profil_cv_page.dart

class ProfilCvPage extends StatefulWidget {
  const ProfilCvPage({super.key});
  @override
  State<ProfilCvPage> createState() => _ProfilCvPageState();
}

class _ProfilCvPageState extends State<ProfilCvPage> {

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Colonne principale (70%)
        Expanded(flex: 70, child: Column(children: [

          // Barre complétion globale
          _buildCompletionHeader(),
          const SizedBox(height: 20),

          // Sections du profil
          _ProfileSection(
            title: 'Photo & Identité',
            icon: Icons.person_outline,
            completion: 80,
            onEdit: () => _editSection('identite'),
            child: _IdentityView(),
          ),
          const SizedBox(height: 14),

          _ProfileSection(
            title: 'À propos',
            icon: Icons.notes_outlined,
            completion: 100,
            onEdit: () => _editSection('about'),
            child: _AboutView(),
          ),
          const SizedBox(height: 14),

          _ProfileSection(
            title: 'Expériences professionnelles',
            icon: Icons.work_history_outlined,
            completion: 100,
            onEdit: () {},
            showAddButton: true,
            onAdd: () => _addExperience(),
            child: _ExperiencesList(),
          ),
          const SizedBox(height: 14),

          _ProfileSection(
            title: 'Formations',
            icon: Icons.school_outlined,
            completion: 100,
            onEdit: () {},
            showAddButton: true,
            onAdd: () => _addFormation(),
            child: _FormationsList(),
          ),
          const SizedBox(height: 14),

          _ProfileSection(
            title: 'Compétences',
            icon: Icons.psychology_outlined,
            completion: 90,
            onEdit: () {},
            child: _SkillsEditor(),
          ),
          const SizedBox(height: 14),

          _ProfileSection(
            title: 'Langues',
            icon: Icons.language_outlined,
            completion: 100,
            onEdit: () {},
            child: _LanguagesEditor(),
          ),
          const SizedBox(height: 14),

          _ProfileSection(
            title: 'Mon CV',
            icon: Icons.description_outlined,
            completion: 100,
            onEdit: () {},
            child: _CvUploadSection(),
          ),
        ])),

        const SizedBox(width: 20),

        // Panneau latéral droit (30%) : analyse IA + conseils
        Expanded(flex: 30, child: _ProfilSidePanel()),
      ]),
    );
  }
}

// Section réutilisable avec header
class _ProfileSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final int completion; // % de complétion de cette section
  final VoidCallback onEdit;
  final Widget child;
  final bool showAddButton;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(
          color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(children: [
        // Header section
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF1A56DB), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A)))),
            // Indicateur complétion
            if (completion < 100)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('$completion%', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: const Color(0xFF92400E))),
              ),
            if (showAddButton && onAdd != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                  color: Color(0xFF1A56DB), size: 20),
                onPressed: onAdd,
              ),
            ],
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                color: Color(0xFF94A3B8), size: 18),
              onPressed: onEdit,
            ),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        Padding(padding: const EdgeInsets.all(20), child: child),
      ]),
    );
  }
}

// Panneau latéral droit : Analyse IA du profil
class _ProfilSidePanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Score IA global
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF1A56DB)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('Analyse IA de votre profil', style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          ]),
          const SizedBox(height: 16),
          // Score circulaire
          Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 90, height: 90,
              child: CircularProgressIndicator(
                value: 0.87,
                strokeWidth: 8,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            Column(children: [
              Text('87', style: GoogleFonts.poppins(
                fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
              Text('/100', style: GoogleFonts.inter(
                fontSize: 11, color: Colors.white70)),
            ]),
          ]),
          const SizedBox(height: 12),
          Text('Très bon profil !', style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          Text('Vous apparaissez dans plus de recherches',
            style: GoogleFonts.inter(
              fontSize: 11, color: Colors.white.withOpacity(0.70),
              textAlign: TextAlign.center)),
        ]),
      ),
      const SizedBox(height: 14),

      // Suggestions d'amélioration
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('💡 Pour améliorer votre score', style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A))),
          const SizedBox(height: 12),
          ...[
            '📸 Ajouter une photo de profil (+10pts)',
            '📝 Détailler votre section À propos (+5pts)',
            '🔗 Ajouter votre profil LinkedIn (+3pts)',
          ].map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              const Icon(Icons.radio_button_unchecked,
                size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              Expanded(child: Text(s, style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFF64748B)))),
            ]),
          )),
        ]),
      ),
      const SizedBox(height: 14),

      // Compétences extraites par IA
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.psychology_outlined,
              color: Color(0xFF1A56DB), size: 16),
            const SizedBox(width: 6),
            Text('Compétences détectées par IA', style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A))),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            'Flutter', 'Dart', 'Firebase',
            'REST API', 'Git', 'Agile',
          ].map((skill) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Text(skill, style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w500,
              color: const Color(0xFF1E40AF))),
          )).toList()),
        ]),
      ),
    ]);
  }
}
```

---

## 9. Page Recherche d'Offres

### Fonctionnalités
```dart
// Barre de recherche principale (titre, compétence, entreprise)
// Filtres avancés :
//   - Secteur d'activité (dropdown multi-select)
//   - Type de contrat (chips : CDI | CDD | Stage | Freelance)
//   - Ville (dropdown villes guinéennes)
//   - Niveau d'expérience (dropdown)
//   - Niveau d'études (dropdown)
//   - Salaire minimum (slider)
//   - Date de publication (dropdown : Aujourd'hui | 7j | 30j | Tout)
//   - Mode de travail (chips : Présentiel | Hybride | Télétravail)
// Tri : [Pertinence] [Date] [Score IA] [Salaire]
// Vue : [Grille] [Liste]
// Nombre de résultats + pagination infinie

// OFFRE CARD (en liste) :
// Logo entreprise | Titre | Entreprise | Ville | Type | Salaire
// Score IA matching (si connecté et profil rempli)
// Boutons : [Voir détails] [🔖 Sauvegarder] [Postuler →]
// Badge NOUVEAU (si < 24h) | Badge URGENT (si expire dans 3j)
```

### Wireframe
```
┌─────────────────────────────────────────────────────────────────┐
│  🔍 ┌─────────────────────────────────────┐ [Rechercher]       │
│     │ Titre, compétence, entreprise...    │                    │
│     └─────────────────────────────────────┘                    │
│  [CDI] [CDD] [Stage] [Freelance]  [Conakry ▼] [Secteur ▼]     │
│  [Date ▼] [Expérience ▼]          [+ Plus de filtres]          │
├───────────────────┬─────────────────────────────────────────────┤
│  FILTRES AVANCÉS  │  487 offres trouvées    Trier: [Pertin. ▼] │
│  (panneau gauche) │                                             │
│  Secteur          │  ┌──────────────────────────────────────┐  │
│  ☑ Technologie    │  │ 🆕 Développeur Flutter Senior        │  │
│  ☑ Finance        │  │    Orange Guinée · Conakry · CDI      │  │
│  ☐ Santé          │  │    3 000 000 - 4 000 000 GNF/mois    │  │
│                   │  │    🤖 Score IA : 94%  👁 284 vues     │  │
│  Salaire min.     │  │    [Voir détail] [🔖] [Postuler →]   │  │
│  0────●────500k   │  └──────────────────────────────────────┘  │
│                   │                                             │
│  Mode travail     │  ┌──────────────────────────────────────┐  │
│  ○ Présentiel     │  │ Chef de Projet Digital               │  │
│  ○ Hybride        │  │    Ecobank Guinée · Conakry · CDI    │  │
│  ○ Télétravail    │  │    À négocier                        │  │
│                   │  │    🤖 Score IA : 88%  👁 156 vues    │  │
│                   │  │    [Voir détail] [🔖] [Postuler →]   │  │
│                   │  └──────────────────────────────────────┘  │
└───────────────────┴─────────────────────────────────────────────┘
```

### Code Flutter
```dart
// lib/screens/candidat/pages/recherche_offres_page.dart

class RechercheOffresPage extends StatefulWidget {
  const RechercheOffresPage({super.key});
  @override
  State<RechercheOffresPage> createState() => _RechercheOffresPageState();
}

class _RechercheOffresPageState extends State<RechercheOffresPage> {
  final _searchCtrl = TextEditingController();
  List<String> _selectedContrats = [];
  String? _selectedVille;
  String? _selectedSecteur;
  String? _sortBy = 'pertinence';
  double _minSalaire = 0;
  bool _showAdvancedFilters = false;
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Filtres (panneau gauche fixe, desktop)
      if (MediaQuery.of(context).size.width >= 1024)
        SizedBox(width: 260, child: _FiltersPanel(
          selectedContrats: _selectedContrats,
          selectedVille: _selectedVille,
          minSalaire: _minSalaire,
          onContratChanged: (v) => setState(() => _selectedContrats = v),
          onVilleChanged: (v) => setState(() => _selectedVille = v),
          onSalaireChanged: (v) => setState(() => _minSalaire = v),
        )),

      // Zone résultats
      Expanded(child: Column(children: [

        // Barre de recherche + filtres rapides
        _buildSearchArea(),

        // Résultats
        Expanded(child: _buildResults()),
      ])),
    ]);
  }

  Widget _buildSearchArea() => Container(
    color: Colors.white,
    padding: const EdgeInsets.all(20),
    child: Column(children: [

      // Champ de recherche principal
      Row(children: [
        Expanded(child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(children: [
            const SizedBox(width: 14),
            const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
            const SizedBox(width: 10),
            Expanded(child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Titre du poste, compétence, entreprise...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14, color: const Color(0xFFCBD5E1)),
                border: InputBorder.none,
              ),
              style: GoogleFonts.inter(
                fontSize: 14, color: const Color(0xFF0F172A)),
            )),
          ]),
        )),
        const SizedBox(width: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          onPressed: () {},
          child: Text('Rechercher', style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 12),

      // Filtres rapides (chips de contrat)
      Row(children: [
        Expanded(child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            'CDI', 'CDD', 'Stage', 'Freelance', 'Temps partiel',
          ].map((type) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(type),
              selected: _selectedContrats.contains(type),
              onSelected: (v) => setState(() {
                v ? _selectedContrats.add(type)
                  : _selectedContrats.remove(type);
              }),
              selectedColor: const Color(0xFFEFF6FF),
              checkmarkColor: const Color(0xFF1A56DB),
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                color: _selectedContrats.contains(type)
                    ? const Color(0xFF1A56DB)
                    : const Color(0xFF64748B)),
              side: BorderSide(
                color: _selectedContrats.contains(type)
                    ? const Color(0xFF1A56DB)
                    : const Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
          )).toList()),
        )),
      ]),
    ]),
  );
}

// Card d'offre dans la liste
class OffreListCard extends StatefulWidget {
  final OffreModel offre;
  final bool isSaved;
  @override
  State<OffreListCard> createState() => _OffreListCardState();
}

class _OffreListCardState extends State<OffreListCard> {
  bool _isSaved = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered
                ? const Color(0xFF1A56DB).withOpacity(0.3)
                : const Color(0xFFE2E8F0)),
          boxShadow: _hovered
              ? [BoxShadow(color: const Color(0xFF1A56DB).withOpacity(0.08),
                  blurRadius: 20, offset: const Offset(0, 8))]
              : [const BoxShadow(color: Color(0x06000000),
                  blurRadius: 4, offset: Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Logo
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Center(child: Text(
                widget.offre.companyName[0],
                style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A56DB)))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(widget.offre.title, style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A)))),
                // Badge nouveau
                if (widget.offre.isNew)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text('NOUVEAU', style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: const Color(0xFF065F46))),
                  ),
                // Badge urgent
                if (widget.offre.isUrgent)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text('URGENT', style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: const Color(0xFF991B1B))),
                  ),
              ]),
              const SizedBox(height: 3),
              Text(widget.offre.companyName, style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B))),
            ])),
          ]),
          const SizedBox(height: 12),
          // Infos
          Wrap(spacing: 16, runSpacing: 6, children: [
            _InfoChip(Icons.location_on_outlined, widget.offre.city),
            _InfoChip(Icons.work_outline, widget.offre.contractType),
            if (widget.offre.salary != null)
              _InfoChip(Icons.payments_outlined, widget.offre.salary!),
            // Score IA
            if (widget.offre.aiScore != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.auto_awesome, size: 12, color: Color(0xFF1A56DB)),
                  const SizedBox(width: 4),
                  Text('Score IA : ${widget.offre.aiScore}%', style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E40AF))),
                ]),
              ),
          ]),
          const SizedBox(height: 14),
          // Actions
          Row(children: [
            Expanded(child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A56DB),
                side: const BorderSide(color: Color(0xFF1A56DB)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              onPressed: () => context.push('/dashboard/offres/${widget.offre.id}'),
              child: const Text('Voir les détails'),
            )),
            const SizedBox(width: 10),
            // Bouton sauvegarder
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                icon: Icon(
                  _isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline,
                  color: _isSaved ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
                ),
                onPressed: () => setState(() => _isSaved = !_isSaved),
              ),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              onPressed: () => _showApplyBottomSheet(context),
              child: const Text('Postuler →'),
            ),
          ]),
        ]),
      ),
    );
  }

  void _showApplyBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ApplyBottomSheet(offre: widget.offre),
    );
  }
}
```

---

## 10. Page Détail d'une Offre

```dart
// Route : /dashboard/offres/:id
// Layout : contenu (65%) + sidebar (35%)

// CONTENU PRINCIPAL :
// ── En-tête offre
//   Logo + Titre + Entreprise + Ville + Type + Salaire
//   Badges : NOUVEAU | URGENT | ⭐ En vedette
//   Date publication + Expire le
//   Score IA matching + Bouton [Postuler] (CTA sticky)

// ── Description
//   À propos de l'offre (texte complet)
//   Missions (liste à puces)

// ── Prérequis
//   Niveau d'études | Expérience | Langues
//   Compétences requises (chips)

// ── Avantages
//   Chips des avantages offerts

// ── À propos de l'entreprise
//   Logo + Nom + Secteur + Taille + Ville
//   Description courte
//   Bouton [Voir le profil de l'entreprise]

// SIDEBAR DROITE :
// ── CTA Principal
//   Bouton [Postuler à cette offre] (gros, bleu)
//   Bouton [🔖 Sauvegarder]
//   Partager : [🔗] [WhatsApp] [Email]

// ── Informations pratiques
//   Type de contrat | Ville | Salaire | Date limite
//   Nombre de postes

// ── Score IA
//   Votre score de correspondance : 94%
//   Compétences correspondantes : Flutter ✓ Dart ✓ Firebase ✓
//   Compétences manquantes : Docker ✗ AWS ✗

// ── Offres similaires (3 cards)
```

---

## 11. Page Mes Candidatures

### Concept : Timeline de suivi
```
Chaque candidature est une card avec sa progression visuelle
sous forme de timeline d'étapes.
```

### Wireframe
```
┌─────────────────────────────────────────────────────────────────┐
│  Mes candidatures (5)                                           │
│  [Toutes(5)] [En cours(3)] [Entretiens(1)] [Terminées(1)]       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  🏢 Orange Guinée · Développeur Flutter                         │
│  📅 Postulé le 20 Mars · il y a 7 jours                        │
│  ──●────────●────────○────────○──                               │
│  Envoyée  En examen Entretien Réponse                           │
│  "Votre candidature est en cours d'examen"                      │
│  [Voir l'offre] [Envoyer un message]                            │
│                                                                 │
│  🏢 MTN Guinée · Data Analyst                                   │
│  📅 Postulé le 15 Mars · Entretien le 28 Mars à 14h00          │
│  ──●────────●────────●────────○──                               │
│  Envoyée  En examen Entretien Réponse                           │
│  🗓️ Entretien confirmé : Vendredi 28 Mars à 14h00               │
│  [Préparer l'entretien] [Ajouter à l'agenda]                   │
│                                                                 │
│  🏢 ONG Plan International · Chef de Projet                     │
│  📅 Postulé le 10 Mars · Refusé le 20 Mars                     │
│  ──●────────●────────────────────● (rouge)                      │
│  Envoyée  En examen              Refusée                        │
│  "Merci pour votre candidature. Nous avons retenu d'autres..."  │
│  [Voir le motif] [Postuler à une offre similaire]               │
└─────────────────────────────────────────────────────────────────┘
```

### Code Flutter
```dart
// lib/screens/candidat/pages/mes_candidatures_page.dart

class CandidatureTimelineCard extends StatelessWidget {
  final CandidatureCandidatModel candidature;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(
          color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // En-tête
        Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(
              candidature.companyName[0],
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700,
                color: const Color(0xFF1A56DB))))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(candidature.jobTitle, style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A))),
            Text(candidature.companyName, style: GoogleFonts.inter(
              fontSize: 13, color: const Color(0xFF64748B))),
          ])),
          StatusBadge(label: candidature.status),
        ]),
        const SizedBox(height: 6),
        Text('Postulé le ${candidature.appliedDate}', style: GoogleFonts.inter(
          fontSize: 12, color: const Color(0xFF94A3B8))),
        const SizedBox(height: 16),

        // Timeline de progression
        _buildTimeline(candidature),
        const SizedBox(height: 14),

        // Message contextuel
        if (candidature.statusMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _statusBgColor(candidature.status),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Icon(_statusIcon(candidature.status),
                color: _statusColor(candidature.status), size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(candidature.statusMessage!, style: GoogleFonts.inter(
                fontSize: 13, color: _statusColor(candidature.status)))),
            ]),
          ),
        const SizedBox(height: 12),

        // Actions
        Row(children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: GoogleFonts.inter(fontSize: 13),
            ),
            onPressed: () => context.push('/dashboard/offres/${candidature.jobId}'),
            child: const Text('Voir l\'offre'),
          ),
          const SizedBox(width: 8),
          if (candidature.status == 'Entretien')
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today_outlined, size: 14),
              label: const Text('Préparer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              onPressed: () {},
            ),
          if (candidature.status != 'Refusée')
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.chat_outlined, size: 14),
                label: const Text('Message'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A56DB),
                  side: const BorderSide(color: Color(0xFF1A56DB)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onPressed: () => context.push(
                  '/dashboard/messages?companyId=${candidature.companyId}'),
              ),
            ),
        ]),
      ]),
    );
  }

  Widget _buildTimeline(CandidatureCandidatModel c) {
    final steps = ['Envoyée', 'En examen', 'Entretien', 'Réponse'];
    final currentStep = _getStepIndex(c.status);
    final isRejected = c.status == 'Refusée';

    return Row(children: steps.asMap().entries.map((e) {
      final i = e.key;
      final isCompleted = i < currentStep || (isRejected && i == steps.length - 1);
      final isCurrent = i == currentStep && !isRejected;
      final isRejectedStep = isRejected && i == steps.length - 1;

      return Expanded(child: Row(children: [
        Expanded(child: Column(children: [
          // Cercle
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: isRejectedStep
                  ? const Color(0xFFEF4444)
                  : isCompleted || isCurrent
                      ? const Color(0xFF1A56DB)
                      : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
              border: isCurrent
                  ? Border.all(color: const Color(0xFF1A56DB), width: 3)
                  : null,
            ),
            child: isCompleted || isRejectedStep
                ? Icon(
                    isRejectedStep ? Icons.close : Icons.check,
                    color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(height: 4),
          // Label
          Text(e.value, style: GoogleFonts.inter(
            fontSize: 10,
            color: isCompleted || isCurrent
                ? const Color(0xFF1A56DB)
                : const Color(0xFF94A3B8),
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400),
            textAlign: TextAlign.center),
        ])),
        // Ligne de connexion
        if (i < steps.length - 1)
          Expanded(child: Container(
            height: 2,
            margin: const EdgeInsets.only(bottom: 18),
            color: i < currentStep
                ? const Color(0xFF1A56DB)
                : const Color(0xFFE2E8F0),
          )),
      ]));
    }).toList());
  }

  int _getStepIndex(String status) {
    switch (status) {
      case 'Envoyée':   return 0;
      case 'En examen': return 1;
      case 'Entretien': return 2;
      case 'Acceptée':
      case 'Refusée':   return 3;
      default:          return 0;
    }
  }
}
```

---

## 12. Page Offres Recommandées par IA

```dart
// lib/screens/candidat/pages/recommandations_ia_page.dart

// En-tête explicatif
// "Notre IA analyse votre profil et votre CV pour vous proposer
//  les offres les plus adaptées à vos compétences."

// Barre de score global
// "Votre profil IA : 87/100 — Complétez votre profil pour de meilleures suggestions"

// Filtres légers : [Tout] [>80%] [>90%] | [CDI] [Stage] | [Conakry]

// Grille d'offres recommandées (3 col desktop, 2 tab, 1 mobile)
// Chaque card :
//   Score IA prominent (grand, coloré)
//   Logo + Titre + Entreprise + Infos
//   Compétences correspondantes (chips verts)
//   Compétences manquantes (chips rouges)
//   Boutons : [Postuler] [🔖 Sauvegarder] [Ignorer cette suggestion]

// Section "Améliorez vos suggestions"
// Conseils pour améliorer le score IA et obtenir de meilleures recommandations
```

---

## 13. Page Offres Sauvegardées

```dart
// lib/screens/candidat/pages/offres_sauvegardees_page.dart

// Liste des offres bookmarkées
// Groupées par : Récemment ajoutées | Plus anciennes
// Chaque offre :
//   Statut en temps réel (toujours active ? expirée ?)
//   Date de sauvegarde
//   Bouton [Postuler] | [Retirer des favoris]
//   Badge "Expire dans X jours" si proche

// Si une offre est expirée :
//   Fond grisé + badge "EXPIRÉE" rouge
//   Texte "Cette offre n'est plus disponible"
//   Bouton [Voir offres similaires →]

// Empty state si aucune offre :
//   Illustration + "Vous n'avez pas encore sauvegardé d'offres"
//   Bouton [Explorer les offres →]
```

---

## 14. Page Messagerie Candidat

```dart
// lib/screens/candidat/pages/messagerie_candidat_page.dart

// Même layout que la messagerie recruteur (split 35/65)
// Le candidat peut :
//   - Voir les messages reçus des recruteurs
//   - Répondre aux messages
//   - Initier un message si l'entreprise l'a contacté
//   - Voir le statut lu/non lu

// Particularités candidat :
// - Chaque conversation est liée à une offre spécifique
// - Affichage : "💼 Orange Guinée · Développeur Flutter"
// - Si nouveau message non lu : badge rouge + notification

// Différence visuelle messages :
// Candidat (vous) → droite, fond bleu (#1A56DB)
// Recruteur → gauche, fond blanc avec ombre
```

---

## 15. Page Conseils & Ressources

### Sections
```dart
// SECTION 1 : Conseils featured (mise en avant)
// Grande card avec image + titre + résumé + [Lire →]

// SECTION 2 : Catégories
// [CV & Lettre de motivation] [Entretien] [Recherche emploi]
// [Négociation salaire] [Reconversion] [Entrepreneuriat]

// SECTION 3 : Articles récents (grille 3 col)
// Chaque card :
//   Image | Catégorie badge | Titre | Résumé (2 lignes) | Temps de lecture
//   [Lire l'article →]

// SECTION 4 : Vidéos conseils (carrousel horizontal)
// Miniature vidéo + titre + durée
// Lecture dans une modale ou redirection

// SECTION 5 : Checklist de candidature
// ☑ Vérifier son CV avant chaque candidature
// ☑ Personnaliser la lettre de motivation
// ☐ Se renseigner sur l'entreprise
// ☐ Préparer des questions pour l'entretien
// ☐ Relancer après 1 semaine sans réponse

// SECTION 6 : Outils utiles
// [Générateur de CV] [Simulateur entretien IA] [Calculateur salaire]
// (Fonctionnalités futures — afficher comme "Bientôt disponible")
```

### Conseil Cards
```dart
class ConseilCard extends StatefulWidget {
  final ConseilModel conseil;

  // Style :
  // Image en haut (CachedNetworkImage, height 140, borderRadius top 12)
  // Badge catégorie (couleur selon catégorie)
  // Titre (Poppins w600 16px)
  // Résumé (Inter 13px, 2 lignes max)
  // Footer : temps de lecture + icône [Lire →]
  // Hover : translateY(-4px) + ombre
}
```

---

## 16. Page Alertes Emploi

### Fonctionnalités
```dart
// L'utilisateur crée des alertes qui lui envoient des notifications
// quand de nouvelles offres correspondant à ses critères sont publiées

// CRÉER UNE ALERTE :
// Formulaire :
//   Mots-clés (ex: "Flutter, Dart, Mobile")
//   Secteur (dropdown)
//   Type de contrat (chips multi-select)
//   Ville (dropdown)
//   Salaire minimum (optionnel)
//   Fréquence : Immédiatement | Quotidien | Hebdomadaire
//   [Créer l'alerte]

// LISTE DES ALERTES ACTIVES :
// Chaque alerte :
//   🔔 Nom auto-généré ("Flutter · Conakry · CDI")
//   Critères résumés
//   Fréquence
//   Dernière notification : "Hier, 3 nouvelles offres"
//   Toggle actif/inactif
//   Bouton [Voir les offres] | [Modifier] | [Supprimer]

// HISTORIQUE des notifications d'alertes
// "📬 3 nouvelles offres correspondent à 'Flutter · Conakry' — Hier"
```

### Code Flutter
```dart
// lib/screens/candidat/pages/alertes_emploi_page.dart

class AlerteCard extends StatelessWidget {
  final AlerteEmploi alerte;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: alerte.isActive
                ? const Color(0xFFEFF6FF)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.notifications_active_outlined,
            color: alerte.isActive
                ? const Color(0xFF1A56DB)
                : const Color(0xFF94A3B8), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(alerte.name, style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(alerte.summary, style: GoogleFonts.inter(
            fontSize: 12, color: const Color(0xFF64748B))),
          const SizedBox(height: 4),
          if (alerte.lastNotification != null)
            Text('Dernière notification : ${alerte.lastNotification}',
              style: GoogleFonts.inter(
                fontSize: 11, color: const Color(0xFF10B981),
                fontWeight: FontWeight.w500)),
        ])),
        // Toggle
        Switch(
          value: alerte.isActive,
          onChanged: (v) {},
          activeColor: const Color(0xFF1A56DB),
        ),
        // Menu actions
        PopupMenuButton(itemBuilder: (_) => [
          const PopupMenuItem(value: 'voir', child: Text('Voir les offres')),
          const PopupMenuItem(value: 'modifier', child: Text('Modifier')),
          const PopupMenuItem(value: 'supprimer',
            child: Text('Supprimer', style: TextStyle(color: Color(0xFFEF4444)))),
        ]),
      ]),
    );
  }
}
```

---

## 17. Page Notifications

```dart
// lib/screens/candidat/pages/notifications_candidat_page.dart

// Groupées par date :
// AUJOURD'HUI
//   🟢 Votre candidature chez Orange Guinée est en cours d'examen — 5min
//   🔵 Nouveau message de Orange Guinée — 30min
//   🤖 12 nouvelles offres correspondent à votre profil — 1h

// HIER
//   🗓️ Rappel : Entretien MTN Guinée demain à 14h00 — hier
//   🔔 Alerte emploi : 3 nouvelles offres "Flutter · Conakry" — hier

// CETTE SEMAINE
//   ✅ Votre profil a été consulté 15 fois — il y a 3j

// Actions globales :
// [Tout marquer comme lu] [Paramètres de notification]
```

---

## 18. Page Paramètres Compte

```dart
// SECTION 1 : Informations du compte
// Email (affiché, non modifiable directement)
// Changer le mot de passe
// Langue (Français par défaut)
// Fuseau horaire

// SECTION 2 : Confidentialité & Visibilité
// Mon profil est visible par les recruteurs (Toggle)
// Afficher mon profil dans la recherche de talents (Toggle)
// Recevoir des propositions de contact des recruteurs (Toggle)
// Mes candidatures sont confidentielles (Toggle)

// SECTION 3 : Préférences de notification
// Email : changement statut candidature (on/off)
// Email : nouveaux messages (on/off)
// Email : nouvelles offres alertes emploi (on/off)
// Email : conseils et ressources (on/off)
// Résumé hebdomadaire de vos candidatures (on/off)

// SECTION 4 : Préférences de recherche d'emploi
// Types de contrat préférés (multi-select)
// Villes préférées (multi-select)
// Secteurs préférés (multi-select)
// Disponibilité (mise à jour rapide)
// Salaire souhaité (optionnel, confidentiel)

// SECTION 5 : Données & Confidentialité
// Télécharger mes données (RGPD)
// Supprimer mon compte (Danger zone)

// SECTION 6 : Danger Zone
// Désactiver temporairement le compte
// Supprimer définitivement le compte (ConfirmDialog : saisir "SUPPRIMER")
```

---

## 19. Composants Partagés Candidat

```dart
// WIDGETS À CRÉER dans lib/screens/candidat/widgets/ :

// CandidatStatCard      : card stat dashboard (valeur + icône + sous-titre)
// OffreListCard         : card offre dans la liste (avec score IA, save, postuler)
// CandidatureTimelineCard: card candidature avec timeline de statuts
// ProfilCompletionBar   : barre de complétion du profil (dans sidebar et page profil)
// ProfileSection        : section éditable du profil (wrapper avec header)
// CvSectionEditor       : éditeur de section CV (expériences, formations)
// SkillChipEditor       : éditeur de compétences avec niveau
// AlerteCard            : card d'alerte emploi avec toggle
// ConseilCard           : card d'article conseil
// ApplyBottomSheet      : feuille modale pour postuler à une offre
// IaScoreCard           : card d'analyse IA du profil (panneau latéral)
// OffreQuickCard        : card compacte pour les recommandations IA
// NotificationTile      : item de notification (groupé par date)
```

### ApplyBottomSheet — Widget Clé
```dart
// lib/screens/candidat/widgets/apply_bottom_sheet.dart

class ApplyBottomSheet extends StatefulWidget {
  final OffreModel offre;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Handle bar
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(100)),
          )),
          const SizedBox(height: 20),

          // Titre
          Text('Postuler à cette offre', style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
          Text(offre.title, style: GoogleFonts.inter(
            fontSize: 14, color: const Color(0xFF64748B))),
          const SizedBox(height: 20),

          // CV sélectionné
          Text('CV à envoyer', style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF374151))),
          const SizedBox(height: 8),
          // Afficher le CV du profil ou option d'upload
          _CvSelector(),
          const SizedBox(height: 16),

          // Lettre de motivation (optionnel)
          Text('Lettre de motivation (optionnel)', style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF374151))),
          const SizedBox(height: 8),
          TextFormField(
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Personnalisez votre candidature...',
              hintStyle: GoogleFonts.inter(
                fontSize: 14, color: const Color(0xFFCBD5E1)),
              filled: true, fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1A56DB), width: 1.5),
              ),
            ),
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
            maxLength: 1000,
          ),
          const SizedBox(height: 20),

          // Bouton soumettre
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send_outlined, size: 18),
              label: Text('Envoyer ma candidature', style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _submitApplication(context),
            ),
          ),
          const SizedBox(height: 10),
          Center(child: Text(
            'Votre candidature sera envoyée directement au recruteur',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
            textAlign: TextAlign.center)),
        ]),
      ),
    );
  }

  Future<void> _submitApplication(BuildContext context) async {
    // Appel API
    Navigator.pop(context);
    // Afficher SnackBar succès
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white),
        const SizedBox(width: 10),
        Text('Candidature envoyée avec succès !', style: GoogleFonts.inter(
          color: Colors.white, fontSize: 14)),
      ]),
      backgroundColor: const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }
}
```

---

## 20. Routing Candidat Complet

```dart
// lib/app/router.dart — AJOUTER ces routes

ShellRoute(
  builder: (context, state, child) => CandidatShell(child: child),
  routes: [
    GoRoute(
      path: '/dashboard',
      redirect: (ctx, state) {
        // if (!authService.isCandidat) return '/connexion';
        return null;
      },
      builder: (ctx, state) => const CandidatDashboardPage(),
    ),
    GoRoute(
      path: '/dashboard/profil',
      builder: (ctx, state) => const ProfilCvPage(),
    ),
    GoRoute(
      path: '/dashboard/offres',
      builder: (ctx, state) => const RechercheOffresPage(),
    ),
    GoRoute(
      path: '/dashboard/offres/:id',
      builder: (ctx, state) => OffreDetailPage(
        jobId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/dashboard/candidatures',
      builder: (ctx, state) => const MesCandidaturesPage(),
    ),
    GoRoute(
      path: '/dashboard/recommandations',
      builder: (ctx, state) => const RecommandationsIAPage(),
    ),
    GoRoute(
      path: '/dashboard/sauvegardes',
      builder: (ctx, state) => const OffresSauvegardeesPage(),
    ),
    GoRoute(
      path: '/dashboard/messages',
      builder: (ctx, state) {
        final companyId = state.uri.queryParameters['companyId'];
        return MessagerieCandidatPage(companyId: companyId);
      },
    ),
    GoRoute(
      path: '/dashboard/conseils',
      builder: (ctx, state) => const ConseilsRessourcesPage(),
    ),
    GoRoute(
      path: '/dashboard/alertes',
      builder: (ctx, state) => const AlertesEmploiPage(),
    ),
    GoRoute(
      path: '/dashboard/notifications',
      builder: (ctx, state) => const NotificationsCandidatPage(),
    ),
    GoRoute(
      path: '/dashboard/parametres',
      builder: (ctx, state) => const ParametresCandidatPage(),
    ),
  ],
),
```

---

## 21. Animations & Micro-interactions

```dart
// ── SIDEBAR ───────────────────────────────────────────────────
// Gradient bleu animé subtil (très léger mouvement)
// Avatar : pulse si profil incomplet (opacity 0.7→1.0 en loop)
// Barre complétion : TweenAnimationBuilder (0→valeur) à l'entrée
// Items : hover blanc translucide 10%, transition 150ms
// Badge count : ZoomIn + bounce si nouveau

// ── DASHBOARD HOME ────────────────────────────────────────────
// Alerte complétion : FadeInDown 500ms
// Stat cards : FadeInUp stagger 80ms + compteur animé
// Recommandations IA : FadeInUp stagger 100ms par card
// Timeline candidatures : slide depuis la gauche
// Citation : FadeIn 600ms + légère rotation initiale

// ── RECHERCHE D'OFFRES ────────────────────────────────────────
// Résultats : FadeInUp stagger 60ms au chargement
// FilterChip : scale + couleur animés 150ms
// Card offre hover : translateY(-4px) + border couleur + ombre
// Bouton sauvegarder : rotation + couleur 200ms

// ── PROFIL ────────────────────────────────────────────────────
// Score IA : TweenAnimationBuilder cercle de 0→87 (800ms)
// Barre complétion globale : animation 600ms
// Sections : FadeInUp stagger 100ms
// Éditeur ouvert : slide du bas 300ms

// ── CANDIDATURES TIMELINE ─────────────────────────────────────
// Dessin de la timeline : animation séquentielle des cercles (100ms entre chaque)
// Statut changé : confetti léger (lottie) pour Acceptée

// ── APPLIQUER (BottomSheet) ───────────────────────────────────
// Ouverture : slide du bas 350ms (DraggableScrollableSheet)
// Envoi : spinner → checkmark animé → fermeture
// SnackBar succès : slide du bas droit

// ── RÈGLES GLOBALES ───────────────────────────────────────────
// Durée standard : 250ms (transitions), 500ms (entrées)
// Courbe : Curves.easeOut
// Stagger max : 80-100ms entre éléments de même liste
// Éviter les animations > 800ms
```

---

## 22. Responsive Dashboard Candidat

```dart
// ── BREAKPOINTS ───────────────────────────────────────────────
// Desktop  : >= 1024px → sidebar gradient (240px) + contenu
// Tablet   : 768-1023px → drawer + contenu centré
// Mobile   : < 768px → drawer + layout mobile-first

// ── PARTICULARITÉS CANDIDAT (mobile-first) ───────────────────
// Le dashboard candidat est conçu en priorité pour mobile
// Car les chercheurs d'emploi utilisent principalement leur smartphone

// ── SIDEBAR MOBILE ────────────────────────────────────────────
// Drawer avec le même gradient bleu
// Swipe depuis le bord gauche pour ouvrir
// Fond overlay semi-transparent derrière

// ── STAT CARDS ────────────────────────────────────────────────
// Desktop : 4 en ligne
// Tablet  : 2x2
// Mobile  : 2x2 (taille réduite)

// ── RECHERCHE D'OFFRES ────────────────────────────────────────
// Desktop : panneau filtres fixe (260px) + résultats
// Tablet  : filtres en BottomSheet (bouton "Filtrer")
// Mobile  : filtres en BottomSheet full screen

// ── PROFIL ────────────────────────────────────────────────────
// Desktop : sections (70%) + panneau IA (30%)
// Mobile  : sections seules, panneau IA en bas

// ── CANDIDATURES ──────────────────────────────────────────────
// Desktop/Tablet : timeline horizontale
// Mobile : timeline verticale (plus lisible)

// ── APPLY BOTTOM SHEET ────────────────────────────────────────
// Sur tous les écrans : BottomSheet (mobile-friendly)
// Hauteur : 70% de l'écran (draggable)

// ── MESSAGERIE ────────────────────────────────────────────────
// Desktop : split 35/65
// Mobile  : liste OU conversation (retour avec AppBar back)
```

---

## 23. Critères d'Acceptation

### ✅ CandidatShell (Layout)
- [ ] Sidebar avec gradient bleu (#1E3A8A → #1A56DB)
- [ ] Avatar du candidat avec initiales dans le header sidebar
- [ ] Barre de complétion animée dans la sidebar (couleur selon %)
- [ ] Texte "Améliorer mon profil →" si complétion < 100%
- [ ] Badges de count sur Candidatures, Recommandations, Messagerie
- [ ] TopBar avec titre dynamique et bouton "Postuler vite"
- [ ] Drawer sur mobile/tablette
- [ ] Transition page fade 250ms

### ✅ Dashboard Home
- [ ] Salutation contextuelle (Bonjour/Bon après-midi/Bonsoir)
- [ ] Alerte complétion profil si < 90%
- [ ] 4 stat cards avec compteur animé (FadeInUp stagger)
- [ ] Section recommandations IA (4 offres min)
- [ ] Suivi candidatures (3 dernières avec statut)
- [ ] Citation motivante du jour (rotative)
- [ ] Alerte nouvelles offres (si alertes actives)

### ✅ Mon Profil & CV
- [ ] 8 sections complètes avec header éditables
- [ ] Indicateur % de complétion par section
- [ ] Upload photo de profil fonctionnel
- [ ] Ajout/suppression expériences dynamique
- [ ] Ajout/suppression formations dynamique
- [ ] SkillChipEditor avec niveaux
- [ ] Upload CV (PDF/DOCX, max 5MB)
- [ ] Panneau IA latéral (score, suggestions, compétences extraites)
- [ ] Auto-save visible

### ✅ Recherche d'Offres
- [ ] Barre de recherche principale
- [ ] FilterChips contrats (CDI/CDD/Stage/Freelance)
- [ ] Panneau filtres avancés (desktop fixe, mobile BottomSheet)
- [ ] OffreListCard avec badge NOUVEAU/URGENT
- [ ] Score IA affiché si profil rempli
- [ ] Bouton sauvegarder (bookmark) animé
- [ ] ApplyBottomSheet fonctionnel
- [ ] Pagination / LoadMore

### ✅ Mes Candidatures
- [ ] Tabs Toutes/En cours/Entretiens/Terminées
- [ ] CandidatureTimelineCard avec timeline visuelle
- [ ] Message contextuel selon le statut
- [ ] Actions selon le statut (voir offre, message, préparer entretien)
- [ ] Animation timeline (dessin séquentiel)

### ✅ Recommandations IA
- [ ] Explication du fonctionnement de l'IA
- [ ] Score profil IA global
- [ ] Grille d'offres avec score prominent
- [ ] Compétences correspondantes vs manquantes
- [ ] Bouton "Ignorer cette suggestion"

### ✅ Offres Sauvegardées
- [ ] Liste des bookmarks avec statut en temps réel
- [ ] Badge "Expire dans X jours"
- [ ] Offres expirées grisées avec message
- [ ] Empty state avec CTA

### ✅ Messagerie
- [ ] Split desktop / séquentiel mobile
- [ ] Bulles distinctes candidat (droite, bleu) / recruteur (gauche, blanc)
- [ ] Conversation liée à une offre spécifique
- [ ] Scroll auto vers le bas

### ✅ Conseils & Ressources
- [ ] Carte featured en haut
- [ ] Catégories filtrables
- [ ] Grille articles avec image, badge, résumé
- [ ] Checklist de candidature interactive

### ✅ Alertes Emploi
- [ ] Formulaire de création complet
- [ ] AlerteCard avec toggle actif/inactif
- [ ] Historique des notifications d'alertes
- [ ] Suppression avec confirmation

### ✅ Paramètres
- [ ] 5 sections complètes
- [ ] Toggles de notification et confidentialité
- [ ] Préférences de recherche
- [ ] Danger zone avec ConfirmDialog sécurisé

### ✅ Global Candidat
- [ ] Design cohérent avec homepage, auth, admin, recruteur
- [ ] Sidebar gradient distincte (vs admin sombre vs recruteur blanc)
- [ ] SnackBars succès/erreur sur toutes les actions importantes
- [ ] Empty states sur toutes les listes potentiellement vides
- [ ] Aucune erreur console Flutter
- [ ] Mobile-first : test prioritaire sur 375px et 414px
- [ ] Test desktop : 1024px / 1280px / 1440px

---

*PRD EmploiConnect v2.2 — Dashboard Candidat/Chercheur d'Emploi — Flutter*
*Projet académique — Licence Professionnelle Génie Logiciel — Guinée 2025-2026*
*BARRY YOUSSOUF (22 000 46) · DIALLO ISMAILA (23 008 60)*
*Encadré par M. DIALLO BOUBACAR — CEO Rasenty*
*Cursor / Kirsoft AI — Phase 5 — Suite Recruteur Dashboard validé*
