# PRD — EmploiConnect · Tableau de Bord Entreprise
## Product Requirements Document v2.1 — Enterprise Dashboard
**Stack : Flutter (Dart) · GoRouter · Google Fonts (Poppins + Inter)**
**Outil : Cursor / Kirsoft AI**
**Module : Espace Recruteur / Entreprise — Tableau de Bord Complet**
**Statut : Phase 4 — Suite Admin Dashboard validé**
**Date : Mars 2026**

---

> ### ⚠️ INSTRUCTIONS CRITIQUES POUR CURSOR
>
> 1. Homepage ✅ · Auth ✅ · Admin Dashboard ✅ — NE PAS TOUCHER
> 2. **Même système de design** : AppColors, AppTextStyles, AppDimensions
> 3. **Même cohérence visuelle** : Poppins (titres) + Inter (corps)
> 4. Accessible UNIQUEMENT avec `role == 'recruteur'`
> 5. Route protégée : `/dashboard-recruteur` → redirection `/connexion` si non recruteur
> 6. Design objectif : **professionnel, intuitif, moderne**
>    Différence avec Admin : sidebar plus claire, tons bleus/verts,
>    orienté "productivité recruteur" pas "supervision globale"
> 7. Implémenter **dans l'ordre exact** de ce PRD

---

## Table des Matières

1. [Vue d'ensemble Entreprise](#1-vue-densemble-entreprise)
2. [Architecture du Dashboard](#2-architecture-du-dashboard)
3. [Système de Design Entreprise](#3-système-de-design-entreprise)
4. [Layout Principal — RecruteurShell](#4-layout-principal--recruteurshell)
5. [Sidebar Navigation Entreprise](#5-sidebar-navigation-entreprise)
6. [TopBar Recruteur](#6-topbar-recruteur)
7. [Page Vue d'ensemble — Accueil Recruteur](#7-page-vue-densemble--accueil-recruteur)
8. [Page Mes Offres d'Emploi](#8-page-mes-offres-demploi)
9. [Page Créer / Modifier une Offre](#9-page-créer--modifier-une-offre)
10. [Page Candidatures Reçues](#10-page-candidatures-reçues)
11. [Page Détail Candidature](#11-page-détail-candidature)
12. [Page Recherche de Talents (IA)](#12-page-recherche-de-talents-ia)
13. [Page Profil de l'Entreprise](#13-page-profil-de-lentreprise)
14. [Page Messagerie](#14-page-messagerie)
15. [Page Statistiques Recruteur](#15-page-statistiques-recruteur)
16. [Page Notifications](#16-page-notifications)
17. [Page Paramètres Compte](#17-page-paramètres-compte)
18. [Composants Partagés Recruteur](#18-composants-partagés-recruteur)
19. [Routing Recruteur Complet](#19-routing-recruteur-complet)
20. [Animations & Micro-interactions](#20-animations--micro-interactions)
21. [Responsive Dashboard Recruteur](#21-responsive-dashboard-recruteur)
22. [Critères d'Acceptation](#22-critères-dacceptation)

---

## 1. Vue d'ensemble Entreprise

### Rôle du Recruteur
Le recruteur (entreprise) dispose d'un espace dédié pour :
- Publier et gérer ses offres d'emploi
- Recevoir et traiter les candidatures
- Rechercher des talents via le moteur IA
- Consulter les profils et CV des candidats
- Communiquer directement avec les candidats
- Suivre ses performances de recrutement
- Gérer le profil public de son entreprise

### Pages du Dashboard Recruteur
| # | Page | Route | Icône |
|---|------|-------|-------|
| 1 | Vue d'ensemble | `/dashboard-recruteur` | `dashboard` |
| 2 | Mes offres | `/dashboard-recruteur/offres` | `work` |
| 3 | Créer une offre | `/dashboard-recruteur/offres/nouvelle` | `add_circle` |
| 4 | Candidatures | `/dashboard-recruteur/candidatures` | `people` |
| 5 | Recherche Talents | `/dashboard-recruteur/talents` | `search` |
| 6 | Profil entreprise | `/dashboard-recruteur/profil` | `business` |
| 7 | Messagerie | `/dashboard-recruteur/messages` | `chat` |
| 8 | Statistiques | `/dashboard-recruteur/statistiques` | `bar_chart` |
| 9 | Notifications | `/dashboard-recruteur/notifications` | `notifications` |
| 10 | Paramètres | `/dashboard-recruteur/parametres` | `settings` |

---

## 2. Architecture du Dashboard

### Structure des Fichiers
```
lib/
├── screens/
│   └── recruteur/
│       ├── recruteur_shell.dart
│       ├── pages/
│       │   ├── recruteur_dashboard_page.dart
│       │   ├── mes_offres_page.dart
│       │   ├── create_edit_offre_page.dart
│       │   ├── candidatures_page.dart
│       │   ├── candidature_detail_page.dart
│       │   ├── talents_search_page.dart
│       │   ├── profil_entreprise_page.dart
│       │   ├── messagerie_page.dart
│       │   ├── statistiques_recruteur_page.dart
│       │   ├── notifications_recruteur_page.dart
│       │   └── parametres_recruteur_page.dart
│       └── widgets/
│           ├── recruteur_sidebar.dart
│           ├── recruteur_topbar.dart
│           ├── offre_card.dart
│           ├── candidature_card.dart
│           ├── talent_card.dart
│           ├── matching_score_badge.dart
│           ├── cv_viewer.dart
│           ├── kanban_board.dart
│           ├── recruteur_stat_card.dart
│           └── offre_form_steps.dart
├── models/
│   ├── offre_model.dart
│   ├── candidature_model.dart
│   ├── talent_model.dart
│   └── message_model.dart
└── services/
    ├── offre_service.dart
    ├── candidature_service.dart
    ├── talent_service.dart
    └── message_service.dart
```

### Layout Global
```
╔══════════════════════════════════════════════════════════════╗
║  SIDEBAR CLAIRE (240px)  │  TOPBAR (64px)                   ║
║  ──────────────────────  │  ──────────────────────────────  ║
║                          │                                  ║
║  Logo EmploiConnect       │  Titre page  [🔔] [+ Offre] [👤]║
║  Nom de l'entreprise      │                                  ║
║                          │  ══════════════════════════════  ║
║  ─ PRINCIPAL ─           │                                  ║
║  🏠 Vue d'ensemble        │                                  ║
║  💼 Mes offres (12)       │      CONTENU DE LA PAGE          ║
║  👥 Candidatures (47)     │                                  ║
║  🔍 Recherche Talents     │      (scrollable)                ║
║  🏢 Profil entreprise     │                                  ║
║                          │                                  ║
║  ─ COMMUNICATION ─       │                                  ║
║  💬 Messagerie (3)        │                                  ║
║  🔔 Notifications (5)     │                                  ║
║                          │                                  ║
║  ─ ANALYSE ─             │                                  ║
║  📊 Statistiques          │                                  ║
║                          │                                  ║
║  ─ COMPTE ─              │                                  ║
║  ⚙️ Paramètres            │                                  ║
║  🚪 Déconnexion           │                                  ║
╚══════════════════════════════════════════════════════════════╝
```

---

## 3. Système de Design Entreprise

### Différence Visuelle Admin vs Recruteur
```dart
// ADMIN Dashboard :
// - Sidebar sombre (#0F172A)
// - Tons froids, supervision
// - Beaucoup de tableaux denses

// RECRUTEUR Dashboard :
// - Sidebar claire (#FFFFFF) avec bordure droite légère
// - Tons bleus et verts, productivité
// - Plus de cards, moins de tableaux
// - Interface plus "warm" et engageante
```

### Couleurs Spécifiques Recruteur
```dart
class RecruteurColors {
  // Sidebar claire
  static const Color sidebarBg        = Color(0xFFFFFFFF);
  static const Color sidebarBorder    = Color(0xFFE2E8F0);
  static const Color sidebarActive    = Color(0xFF1A56DB);
  static const Color sidebarActiveBg  = Color(0xFFEFF6FF);
  static const Color sidebarHoverBg   = Color(0xFFF8FAFC);
  static const Color sidebarText      = Color(0xFF64748B);
  static const Color sidebarTextActive= Color(0xFF1A56DB);
  static const Color sidebarSection   = Color(0xFF94A3B8);

  // Fond contenu
  static const Color contentBg        = Color(0xFFF8FAFC);

  // Stat cards
  static const Color statBlue         = Color(0xFF1A56DB);
  static const Color statBlueBg       = Color(0xFFEFF6FF);
  static const Color statGreen        = Color(0xFF10B981);
  static const Color statGreenBg      = Color(0xFFECFDF5);
  static const Color statOrange       = Color(0xFFF59E0B);
  static const Color statOrangeBg     = Color(0xFFFEF3C7);
  static const Color statPurple       = Color(0xFF8B5CF6);
  static const Color statPurpleBg     = Color(0xFFF5F3FF);

  // Statuts offres
  static const Color offreActive      = Color(0xFF10B981);
  static const Color offreActiveBg    = Color(0xFFD1FAE5);
  static const Color offreExpired     = Color(0xFF94A3B8);
  static const Color offreExpiredBg   = Color(0xFFF1F5F9);
  static const Color offreDraft       = Color(0xFFF59E0B);
  static const Color offreDraftBg     = Color(0xFFFEF3C7);
  static const Color offreClosed      = Color(0xFFEF4444);
  static const Color offreClosedBg    = Color(0xFFFEE2E2);

  // Statuts candidatures
  static const Color candidNew        = Color(0xFF1A56DB);
  static const Color candidNewBg      = Color(0xFFEFF6FF);
  static const Color candidReview     = Color(0xFFF59E0B);
  static const Color candidReviewBg   = Color(0xFFFEF3C7);
  static const Color candidInterview  = Color(0xFF8B5CF6);
  static const Color candidInterviewBg= Color(0xFFF5F3FF);
  static const Color candidAccepted   = Color(0xFF10B981);
  static const Color candidAcceptedBg = Color(0xFFD1FAE5);
  static const Color candidRejected   = Color(0xFFEF4444);
  static const Color candidRejectedBg = Color(0xFFFEE2E2);

  // Score IA matching
  static const Color scoreExcellent   = Color(0xFF10B981); // 80-100%
  static const Color scoreGood        = Color(0xFF1A56DB); // 60-79%
  static const Color scoreMedium      = Color(0xFFF59E0B); // 40-59%
  static const Color scoreLow         = Color(0xFFEF4444); // < 40%
}
```

---

## 4. Layout Principal — RecruteurShell

```dart
// lib/screens/recruteur/recruteur_shell.dart

class RecruteurShell extends StatefulWidget {
  final Widget child;
  const RecruteurShell({super.key, required this.child});

  @override
  State<RecruteurShell> createState() => _RecruteurShellState();
}

class _RecruteurShellState extends State<RecruteurShell> {

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: isMobile ? const RecruteurSidebar(isDrawer: true) : null,
      body: Row(children: [

        // Sidebar fixe (desktop uniquement)
        if (!isMobile) const RecruteurSidebar(),

        // Zone principale
        Expanded(child: Column(children: [

          // TopBar
          RecruteurTopBar(),

          // Page active avec transition
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

## 5. Sidebar Navigation Entreprise

```dart
// lib/screens/recruteur/widgets/recruteur_sidebar.dart
// SIDEBAR CLAIRE — fond blanc, texte sombre, accents bleus

class RecruteurSidebar extends StatelessWidget {
  final bool isDrawer;
  const RecruteurSidebar({super.key, this.isDrawer = false});

  @override
  Widget build(BuildContext context) {
    final company = context.watch<RecruteurProvider>().company;
    final currentRoute = GoRouterState.of(context).uri.path;

    return Container(
      width: 240,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(children: [

        // ── En-tête avec logo entreprise ──────────────────────
        _buildCompanyHeader(company),

        // ── Menu ──────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(children: [

              // PRINCIPAL
              _buildSection('PRINCIPAL', [
                _Item('Vue d\'ensemble', Icons.dashboard_outlined,
                  Icons.dashboard_rounded, '/dashboard-recruteur'),
                _Item('Mes offres', Icons.work_outline,
                  Icons.work_rounded, '/dashboard-recruteur/offres',
                  badge: '12'),
                _Item('Candidatures', Icons.people_outline,
                  Icons.people_rounded, '/dashboard-recruteur/candidatures',
                  badge: '47', badgeColor: const Color(0xFF10B981)),
                _Item('Recherche Talents', Icons.search_outlined,
                  Icons.search_rounded, '/dashboard-recruteur/talents'),
                _Item('Profil entreprise', Icons.business_outlined,
                  Icons.business_rounded, '/dashboard-recruteur/profil'),
              ]),

              // COMMUNICATION
              _buildSection('COMMUNICATION', [
                _Item('Messagerie', Icons.chat_bubble_outline,
                  Icons.chat_bubble_rounded, '/dashboard-recruteur/messages',
                  badge: '3', badgeColor: const Color(0xFF1A56DB)),
                _Item('Notifications', Icons.notifications_outlined,
                  Icons.notifications_rounded, '/dashboard-recruteur/notifications',
                  badge: '5'),
              ]),

              // ANALYSE
              _buildSection('ANALYSE', [
                _Item('Statistiques', Icons.bar_chart_outlined,
                  Icons.bar_chart_rounded, '/dashboard-recruteur/statistiques'),
              ]),

              // COMPTE
              _buildSection('COMPTE', [
                _Item('Paramètres', Icons.settings_outlined,
                  Icons.settings_rounded, '/dashboard-recruteur/parametres'),
              ]),
            ]),
          ),
        ),

        // ── Bouton publier une offre (CTA principal) ──────────
        _buildPublishCTA(context),

        // ── Déconnexion ────────────────────────────────────────
        _buildLogoutButton(context),
      ]),
    );
  }

  Widget _buildCompanyHeader(CompanyModel? company) => Container(
    padding: const EdgeInsets.all(16),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
    ),
    child: Row(children: [
      // Logo entreprise
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: company?.logoUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(company!.logoUrl!, fit: BoxFit.cover))
            : Center(child: Text(
                company?.name.substring(0, 1) ?? 'E',
                style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A56DB)))),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(company?.name ?? 'Mon entreprise',
          style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A)),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        Text('Espace Recruteur', style: GoogleFonts.inter(
          fontSize: 11, color: const Color(0xFF64748B))),
      ])),
    ]),
  );

  Widget _buildSection(String title, List<_Item> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
        child: Text(title, style: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w600,
          color: const Color(0xFF94A3B8), letterSpacing: 0.8)),
      ),
      ...items.map((item) => _buildItem(item)),
    ]);
  }

  Widget _buildItem(_Item item) {
    return Builder(builder: (context) {
      final currentRoute = GoRouterState.of(context).uri.path;
      final isActive = currentRoute == item.route ||
          (item.route != '/dashboard-recruteur' &&
           currentRoute.startsWith(item.route));

      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFEFF6FF)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () => context.go(item.route),
            borderRadius: BorderRadius.circular(8),
            hoverColor: const Color(0xFFF8FAFC),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: 18,
                  color: isActive
                      ? const Color(0xFF1A56DB)
                      : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(item.label, style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? const Color(0xFF1A56DB)
                      : const Color(0xFF64748B),
                ))),
                if (item.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.badgeColor?.withOpacity(0.15) ??
                          const Color(0xFF1A56DB).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(item.badge!, style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: item.badgeColor ?? const Color(0xFF1A56DB))),
                  ),
              ]),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPublishCTA(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
    ),
    child: ElevatedButton.icon(
      icon: const Icon(Icons.add_circle_outline, size: 18),
      label: Text('Publier une offre', style: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A56DB),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      onPressed: () => context.push('/dashboard-recruteur/offres/nouvelle'),
    ),
  );

  Widget _buildLogoutButton(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
    child: InkWell(
      onTap: () => context.go('/connexion'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          const Icon(Icons.logout_outlined, size: 18, color: Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Text('Déconnexion', style: GoogleFonts.inter(
            fontSize: 14, color: const Color(0xFF94A3B8))),
        ]),
      ),
    ),
  );
}
```

---

## 6. TopBar Recruteur

```dart
// lib/screens/recruteur/widgets/recruteur_topbar.dart

class RecruteurTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: [

        // Hamburger mobile
        Builder(builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF64748B)),
          onPressed: () => MediaQuery.of(ctx).size.width < 1024
              ? Scaffold.of(ctx).openDrawer()
              : null,
        )),
        const SizedBox(width: 8),

        // Fil d'Ariane
        _Breadcrumb(route: currentRoute),

        const Spacer(),

        // Bouton rapide "Publier une offre"
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: Text('Nouvelle offre', style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          onPressed: () => context.push('/dashboard-recruteur/offres/nouvelle'),
        ),
        const SizedBox(width: 16),

        // Notifications
        Stack(children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF64748B)),
            onPressed: () => context.push('/dashboard-recruteur/notifications'),
          ),
          Positioned(top: 8, right: 8, child: Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444), shape: BoxShape.circle),
          )),
        ]),
        const SizedBox(width: 8),

        // Avatar entreprise avec menu
        _CompanyAvatarMenu(),
      ]),
    );
  }
}

// Fil d'Ariane (breadcrumb)
class _Breadcrumb extends StatelessWidget {
  final String route;
  @override
  Widget build(BuildContext context) {
    final parts = _getBreadcrumb(route);
    return Row(children: parts.asMap().entries.map((e) {
      final isLast = e.key == parts.length - 1;
      return Row(children: [
        if (e.key > 0) ...[
          const Icon(Icons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
          const SizedBox(width: 4),
        ],
        Text(e.value, style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
          color: isLast ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
        )),
      ]);
    }).toList());
  }

  List<String> _getBreadcrumb(String route) {
    final map = {
      '/dashboard-recruteur': ['Accueil'],
      '/dashboard-recruteur/offres': ['Accueil', 'Mes offres'],
      '/dashboard-recruteur/offres/nouvelle': ['Mes offres', 'Nouvelle offre'],
      '/dashboard-recruteur/candidatures': ['Accueil', 'Candidatures'],
      '/dashboard-recruteur/talents': ['Accueil', 'Recherche Talents'],
      '/dashboard-recruteur/profil': ['Accueil', 'Profil entreprise'],
      '/dashboard-recruteur/messages': ['Accueil', 'Messagerie'],
      '/dashboard-recruteur/statistiques': ['Accueil', 'Statistiques'],
      '/dashboard-recruteur/parametres': ['Accueil', 'Paramètres'],
    };
    return map[route] ?? ['Accueil'];
  }
}
```

---

## 7. Page Vue d'ensemble — Accueil Recruteur

### Wireframe
```
┌─────────────────────────────────────────────────────────────────┐
│  Bonjour, Orange Guinée 👋   Vendredi 27 Mars 2026              │
│  Vous avez 5 nouvelles candidatures aujourd'hui.                │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │ 💼  12  │  │ 👥  47   │  │ 👁 1 284│  │ ⭐  89%  │       │
│  │  Offres  │  │Candidat. │  │  Vues    │  │Taux conv.│       │
│  │ actives  │  │ reçues   │  │ ce mois  │  │          │       │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │
├─────────────────────────────────────────────────────────────────┤
│  Candidatures récentes (5 aujourd'hui)      [Voir tout →]      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ [MB] Mamadou Barry · Dév. Flutter · Score IA: 94% [✓][✗]│  │
│  │ [AD] Aissatou Diallo · UX Designer · Score IA: 87% [✓][✗]│ │
│  │ [SK] Sekou Kouyaté · PM · Score IA: 76%           [✓][✗]│  │
│  └──────────────────────────────────────────────────────────┘  │
├──────────────────────────────┬──────────────────────────────────┤
│  📈 Vues des offres (30 j.)  │  💼 Mes offres actives           │
│  [Graphique courbes]         │  ● Développeur Flutter (23 cand.)│
│                              │  ● Chef de projet (12 cand.)     │
│                              │  ● Data Analyst (8 cand.)        │
│                              │  [Gérer mes offres →]            │
├──────────────────────────────┴──────────────────────────────────┤
│  🤖 Recommandations IA — Profils correspondant à vos offres     │
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐               │
│  │ [MB]   │  │ [AD]   │  │ [IB]   │  │ [MK]   │               │
│  │  94%   │  │  91%   │  │  88%   │  │  85%   │               │
│  │Contacter│  │Contacter│ │Contacter│ │Contacter│              │
│  └────────┘  └────────┘  └────────┘  └────────┘               │
└─────────────────────────────────────────────────────────────────┘
```

### Code Flutter
```dart
// lib/screens/recruteur/pages/recruteur_dashboard_page.dart

class RecruteurDashboardPage extends StatelessWidget {
  const RecruteurDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        _buildWelcomeHeader(context),
        const SizedBox(height: 24),

        // 4 stat cards
        _buildStatsRow(),
        const SizedBox(height: 24),

        // Candidatures récentes
        _buildRecentCandidatures(context),
        const SizedBox(height: 24),

        // Graphique + Mes offres actives
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 55, child: _buildViewsChart()),
          const SizedBox(width: 20),
          Expanded(flex: 45, child: _buildActiveOffers(context)),
        ]),
        const SizedBox(height: 24),

        // Recommandations IA
        _buildAIRecommendations(context),
      ]),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Bonjour, Orange Guinée 👋', style: GoogleFonts.poppins(
          fontSize: 22, fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A))),
        const SizedBox(height: 4),
        RichText(text: TextSpan(
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
          children: [
            const TextSpan(text: 'Vous avez '),
            TextSpan(text: '5 nouvelles candidatures',
              style: const TextStyle(
                color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
            const TextSpan(text: ' aujourd\'hui.'),
          ],
        )),
      ]),
      // Alerte si actions en attente
      _buildPendingAlert(context),
    ],
  );

  Widget _buildPendingAlert(BuildContext context) => GestureDetector(
    onTap: () => context.push('/dashboard-recruteur/candidatures'),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(children: [
        const Icon(Icons.hourglass_empty_rounded,
          color: Color(0xFFF59E0B), size: 16),
        const SizedBox(width: 8),
        Text('8 candidatures en attente de réponse',
          style: GoogleFonts.inter(fontSize: 13,
            color: const Color(0xFF92400E), fontWeight: FontWeight.w500)),
        const SizedBox(width: 6),
        const Icon(Icons.arrow_forward_ios,
          color: Color(0xFF92400E), size: 12),
      ]),
    ),
  );

  Widget _buildStatsRow() {
    final stats = [
      _RecruteurStat('Offres actives', '12', '+2 ce mois',
        Icons.work_rounded, RecruteurColors.statBlue, RecruteurColors.statBlueBg),
      _RecruteurStat('Candidatures', '47', '+5 aujourd\'hui',
        Icons.people_rounded, RecruteurColors.statGreen, RecruteurColors.statGreenBg),
      _RecruteurStat('Vues ce mois', '1 284', '+18%',
        Icons.visibility_rounded, RecruteurColors.statPurple, RecruteurColors.statPurpleBg),
      _RecruteurStat('Taux réponse', '89%', 'Excellent',
        Icons.star_rounded, RecruteurColors.statOrange, RecruteurColors.statOrangeBg),
    ];

    return Row(children: stats.asMap().entries.map((e) => Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: e.key < 3 ? 16 : 0),
        child: FadeInUp(
          delay: Duration(milliseconds: e.key * 80),
          duration: const Duration(milliseconds: 500),
          child: RecruteurStatCard(stat: e.value),
        ),
      ),
    )).toList());
  }

  Widget _buildAIRecommendations(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)]),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                const SizedBox(width: 4),
                Text('IA', style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
            const SizedBox(width: 10),
            Text('Recommandations IA', style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
          ]),
          Text('Profils correspondant à vos offres actives',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
        ]),
        TextButton(
          onPressed: () => context.push('/dashboard-recruteur/talents'),
          child: Text('Voir tous les talents →', style: GoogleFonts.inter(
            fontSize: 14, color: const Color(0xFF1A56DB), fontWeight: FontWeight.w500)),
        ),
      ]),
      const SizedBox(height: 16),
      // Grille de profils recommandés
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, childAspectRatio: 0.75,
          crossAxisSpacing: 16, mainAxisSpacing: 16,
        ),
        itemCount: 4,
        itemBuilder: (ctx, i) => FadeInUp(
          delay: Duration(milliseconds: i * 100),
          child: TalentCard(talent: _getMockTalents()[i], compact: true),
        ),
      ),
    ],
  );
}
```

---

## 8. Page Mes Offres d'Emploi

### Fonctionnalités
- Liste de toutes les offres de l'entreprise
- Filtres : statut, date, type de contrat
- Statistiques par offre (vues, candidatures)
- Actions CRUD complètes
- Duplication d'une offre
- Clôture anticipée d'une offre

### Wireframe
```
┌─────────────────────────────────────────────────────────────────┐
│  Mes offres d'emploi (12)               [+ Publier une offre]   │
├─────────────────────────────────────────────────────────────────┤
│  [Toutes(12)] [Actives(8)] [En attente(2)] [Expirées(1)] [Brouillons(1)]│
├─────────────────────────────────────────────────────────────────┤
│  🔍 Rechercher...    [Date ▼]  [Contrat ▼]  [Ville ▼]           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 💼 Développeur Flutter Senior          ● Active         │   │
│  │    Conakry · CDI · 3 000 000 GNF/mois                   │   │
│  │    📅 Publiée le 15 Mars · Expire le 15 Avril           │   │
│  │    👁 284 vues  👥 23 candidatures  ⏳ 8 non lues        │   │
│  │    [Voir candidatures] [Modifier] [Dupliquer] [Clôturer] │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 💼 Chef de Projet Digital               ● Active        │   │
│  │    Conakry · CDI · À négocier                           │   │
│  │    📅 Publiée le 20 Mars · Expire le 20 Avril           │   │
│  │    👁 156 vues  👥 12 candidatures  ⏳ 4 non lues        │   │
│  │    [Voir candidatures] [Modifier] [Dupliquer] [Clôturer] │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Code Flutter
```dart
// lib/screens/recruteur/pages/mes_offres_page.dart

class MesOffresPage extends StatefulWidget {
  const MesOffresPage({super.key});
  @override
  State<MesOffresPage> createState() => _MesOffresPageState();
}

class _MesOffresPageState extends State<MesOffresPage>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // En-tête
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mes offres d\'emploi', style: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
            Text('Gérez toutes vos annonces de recrutement',
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
          ]),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: Text('Publier une offre', style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56DB),
              foregroundColor: Colors.white, elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => context.push('/dashboard-recruteur/offres/nouvelle'),
          ),
        ]),
        const SizedBox(height: 24),

        // Card principale
        Container(
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(children: [

            // Tabs
            TabBar(
              controller: _tabController, isScrollable: true,
              labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
              labelColor: const Color(0xFF1A56DB),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF1A56DB),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: const [
                Tab(text: 'Toutes (12)'),
                Tab(text: 'Actives (8)'),
                Tab(text: 'En attente (2)'),
                Tab(text: 'Expirées (1)'),
                Tab(text: 'Brouillons (1)'),
              ],
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Filtres
            _buildFilters(),

            // Liste des offres
            ..._getMockOffres().map((offre) =>
              FadeInUp(child: _OffreCard(offre: offre))),
          ]),
        ),
      ]),
    );
  }
}

// Card d'une offre
class _OffreCard extends StatefulWidget {
  final OffreModel offre;
  @override
  State<_OffreCard> createState() => _OffreCardState();
}

class _OffreCardState extends State<_OffreCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFFAFAFF) : Colors.white,
          border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                StatusBadge(label: widget.offre.status),
                if (widget.offre.isFeatured) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text('En vedette', style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: const Color(0xFF92400E))),
                    ]),
                  ),
                ],
              ]),
              const SizedBox(height: 6),
              Text(widget.offre.title, style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                Text(' ${widget.offre.city}', style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF64748B))),
                const SizedBox(width: 12),
                const Icon(Icons.work_outline, size: 14, color: Color(0xFF94A3B8)),
                Text(' ${widget.offre.contractType}', style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF64748B))),
                if (widget.offre.salary != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.payments_outlined, size: 14, color: Color(0xFF94A3B8)),
                  Text(' ${widget.offre.salary}', style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF64748B))),
                ],
              ]),
            ])),
          ]),
          const SizedBox(height: 12),

          // Statistiques
          Row(children: [
            _StatChip(Icons.visibility_outlined, '${widget.offre.views} vues'),
            const SizedBox(width: 16),
            _StatChip(Icons.people_outline, '${widget.offre.applications} candidatures'),
            const SizedBox(width: 16),
            if (widget.offre.unread > 0)
              _StatChip(Icons.mark_email_unread_outlined,
                '${widget.offre.unread} non lues',
                color: const Color(0xFF10B981)),
            const Spacer(),
            Text('Expire le ${widget.offre.expiryDate}',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
          ]),
          const SizedBox(height: 14),

          // Actions
          Wrap(spacing: 8, children: [
            _ActionButton('Voir candidatures', Icons.people_outline,
              const Color(0xFF1A56DB),
              () => context.push('/dashboard-recruteur/candidatures?offreId=${widget.offre.id}')),
            _ActionButton('Modifier', Icons.edit_outlined,
              const Color(0xFF64748B),
              () => context.push('/dashboard-recruteur/offres/${widget.offre.id}/modifier')),
            _ActionButton('Dupliquer', Icons.copy_outlined,
              const Color(0xFF64748B), () {}),
            _ActionButton('Clôturer', Icons.close_outlined,
              const Color(0xFFEF4444), () => _confirmClose()),
          ]),
        ]),
      ),
    );
  }

  void _confirmClose() => showDialog(
    context: context,
    builder: (_) => ConfirmDialog(
      title: 'Clôturer cette offre ?',
      message: 'L\'offre ne sera plus visible par les candidats. Les candidatures reçues seront conservées.',
      confirmLabel: 'Clôturer',
      confirmColor: const Color(0xFFEF4444),
      onConfirm: () {},
    ),
  );
}
```

---

## 9. Page Créer / Modifier une Offre

### Concept : Formulaire Multi-Étapes (4 étapes)
```
●────────────────○────────────────○────────────────○
1. Informations  2. Description   3. Prérequis     4. Publication
   générales        & missions       & avantages
```

### Étape 1 — Informations générales
```dart
// Titre du poste (requis, max 80 chars)
// Secteur d'activité (Dropdown)
// Type de contrat (SegmentedButton) : CDI | CDD | Stage | Freelance | Temps partiel
// Ville (Dropdown villes guinéennes)
// Adresse précise (TextField, optionnel)
// Mode de travail (SegmentedButton) : Présentiel | Hybride | Télétravail
// Fourchette salariale (RangeSlider ou TextField) : optionnel
// Date limite candidature (DatePicker)
// Nombre de postes à pourvoir (NumberField)
```

### Étape 2 — Description & Missions
```dart
// Description du poste (TextEditor rich, min 100 chars)
// Missions principales (liste éditable, min 3 items)
//   - Bouton [+ Ajouter une mission]
//   - Chaque mission : TextField + bouton supprimer
// À propos de l'entreprise (pré-rempli depuis profil)
```

### Étape 3 — Prérequis & Avantages
```dart
// Niveau d'études requis (Dropdown) :
//   BEPC | Bac | Licence | Master | Doctorat | Sans diplôme
// Expérience requise (Dropdown) :
//   Sans expérience | 1-2 ans | 3-5 ans | 5-10 ans | 10+ ans
// Compétences requises (Chips éditables, max 10)
//   - TextField + bouton [+ Ajouter]
//   - Suggestions auto basées sur le titre
// Langues requises (MultiSelect) : Français | Anglais | Pular | Malinké | Soussou
// Avantages proposés (Chips sélectionnables) :
//   Assurance maladie | Transport | Logement | Formation | Bonus annuel |
//   Téléphone professionnel | Repas | Congés payés
```

### Étape 4 — Publication
```dart
// Aperçu de l'offre (preview exacte comme sur la homepage)
// Options de publication :
//   ○ Publier maintenant
//   ○ Planifier pour plus tard (DateTimePicker)
//   ○ Sauvegarder en brouillon
// Option "Mettre en vedette" (si disponible dans le plan)
// Confirmation et soumission

// Bouton [Publier l'offre] → succès avec animation confetti
// Bouton [Sauvegarder brouillon]
```

### Code Flutter — Formulaire
```dart
// lib/screens/recruteur/pages/create_edit_offre_page.dart

class CreateEditOffrePage extends StatefulWidget {
  final String? offreId; // null = création, sinon = modification
  const CreateEditOffrePage({super.key, this.offreId});
  @override
  State<CreateEditOffrePage> createState() => _CreateEditOffrePageState();
}

class _CreateEditOffrePageState extends State<CreateEditOffrePage> {
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isSaving = false;

  // Contrôleurs
  final _titleCtrl        = TextEditingController();
  final _descriptionCtrl  = TextEditingController();
  final _addressCtrl      = TextEditingController();
  String? _sector, _city, _contractType, _workMode, _education, _experience;
  String? _salary;
  DateTime? _deadline;
  int _positions = 1;
  List<String> _missions      = [''];
  List<String> _skills        = [];
  List<String> _languages     = [];
  List<String> _benefits      = [];
  String _publishOption       = 'now';
  DateTime? _scheduledDate;

  final List<String> _benefits_options = [
    'Assurance maladie', 'Transport', 'Logement', 'Formation continue',
    'Bonus annuel', 'Téléphone professionnel', 'Repas', 'Congés payés',
    'Tickets restaurant', 'Prime d\'ancienneté',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Formulaire principal (70%)
        Expanded(flex: 70, child: Column(children: [

          // En-tête
          _buildFormHeader(),
          const SizedBox(height: 24),

          // Stepper
          _StepperHeader(current: _currentStep + 1, total: 4),
          const SizedBox(height: 24),

          // Contenu de l'étape
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.03, 0), end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(_currentStep),
              child: _buildStepContent(),
            ),
          ),
          const SizedBox(height: 24),

          // Boutons navigation
          _buildNavButtons(),
        ])),

        const SizedBox(width: 24),

        // Panneau latéral : conseils (30%)
        Expanded(flex: 30, child: _TipsPanel(step: _currentStep)),
      ]),
    );
  }

  Widget _buildFormHeader() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          widget.offreId == null ? 'Publier une offre' : 'Modifier l\'offre',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A))),
        Text('Remplissez les informations pour attirer les meilleurs candidats',
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
      ]),
      // Sauvegarde automatique
      if (_isSaving)
        Row(children: [
          const SizedBox(width: 12, height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF94A3B8))),
          const SizedBox(width: 8),
          Text('Sauvegarde...', style: GoogleFonts.inter(
            fontSize: 13, color: const Color(0xFF94A3B8))),
        ])
      else
        Text('Sauvegarde automatique', style: GoogleFonts.inter(
          fontSize: 13, color: const Color(0xFF10B981))),
    ],
  );

  Widget _buildNavButtons() => Row(children: [
    if (_currentStep > 0) ...[
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => setState(() => _currentStep--),
        child: Text('← Précédent', style: GoogleFonts.inter(
          fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
      ),
      const SizedBox(width: 12),
    ],
    Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A56DB),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: _currentStep < 3
            ? () => setState(() => _currentStep++)
            : _publishOffer,
        child: _isLoading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(
                _currentStep == 3 ? 'Publier l\'offre ✓' : 'Continuer →',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600,
                  color: Colors.white)),
      ),
    ),
    if (_currentStep < 3) ...[
      const SizedBox(width: 12),
      TextButton(
        onPressed: _saveDraft,
        child: Text('Sauvegarder brouillon', style: GoogleFonts.inter(
          fontSize: 14, color: const Color(0xFF64748B))),
      ),
    ],
  ]);

  Future<void> _publishOffer() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);
    // Animation succès + redirection
    if (mounted) {
      _showSuccessAnimation();
      await Future.delayed(const Duration(seconds: 2));
      context.go('/dashboard-recruteur/offres');
    }
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PublishSuccessDialog(),
    );
  }

  Future<void> _saveDraft() async {}
}

// Dialog succès publication
class _PublishSuccessDialog extends StatelessWidget {
  const _PublishSuccessDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ZoomIn(
            child: Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFD1FAE5), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded,
                color: Color(0xFF10B981), size: 48),
            ),
          ),
          const SizedBox(height: 20),
          Text('Offre publiée avec succès !', style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text('Votre offre est maintenant visible\npar tous les candidats sur EmploiConnect.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B), height: 1.5)),
        ]),
      ),
    );
  }
}
```

### Panneau Conseils Latéral
```dart
// _TipsPanel : panneau latéral avec conseils selon l'étape active
// Étape 1 : "Choisissez un titre clair et précis"
//           "Indiquez le salaire pour +40% de candidatures"
// Étape 2 : "Listez 5 à 8 missions maximum"
//           "Utilisez des verbes d'action"
// Étape 3 : "Les compétences IA sont extraites automatiquement"
//           "Listez les avantages pour attirer plus de talents"
// Étape 4 : "Aperçu exact de votre offre sur la plateforme"
```

---

## 10. Page Candidatures Reçues

### Concept : Vue Kanban + Vue Liste (switchable)

```
╔════════════════════════════════════════════════════════╗
║  [📋 Liste]  [🗂️ Kanban]           [Filtrer] [Exporter]║
╠═══════════╦════════════╦═══════════╦══════════╦═══════╣
║  REÇUES   ║ EN EXAMEN  ║ ENTRETIEN ║ ACCEPTÉS ║REFUSÉS║
║  (12)     ║   (8)      ║   (3)     ║   (2)    ║  (4)  ║
╠═══════════╬════════════╬═══════════╬══════════╬═══════╣
║ [MB] 94%  ║ [AD] 87%   ║ [IB] 91%  ║ [MK] 96% ║       ║
║ Mamadou B.║ Aissatou D.║ Ibrahima B║ Mohamed K║       ║
║ Dev Flutt.║ UX Designer║ PM Senior ║ Data Eng.║       ║
║ [Voir CV] ║ [Voir CV]  ║ [Planifier║ [Contrat]║       ║
║           ║            ║  RDV]     ║          ║       ║
╚═══════════╩════════════╩═══════════╩══════════╩═══════╝
```

### Code Kanban Board
```dart
// lib/screens/recruteur/widgets/kanban_board.dart

class KanbanBoard extends StatelessWidget {
  final List<CandidatureColumn> columns;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columns.map((col) => _KanbanColumn(column: col)).toList(),
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final CandidatureColumn column;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: Column(children: [
        // Header colonne
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(children: [
            Container(width: 10, height: 10,
              decoration: BoxDecoration(
                color: column.color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(column.title, style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A))),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: column.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text('${column.count}', style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: column.color)),
            ),
          ]),
        ),
        // Cards candidatures
        DragTarget<CandidatureModel>(
          onAccept: (data) => _moveCandidature(data, column.status),
          builder: (ctx, candidates, rejected) => Container(
            constraints: const BoxConstraints(minHeight: 200),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              children: column.candidatures.map((c) =>
                Draggable<CandidatureModel>(
                  data: c,
                  feedback: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(width: 260, child: CandidatureKanbanCard(c: c)),
                  ),
                  childWhenDragging: Opacity(opacity: 0.3,
                    child: CandidatureKanbanCard(c: c)),
                  child: CandidatureKanbanCard(c: c),
                )
              ).toList(),
            ),
          ),
        ),
      ]),
    );
  }

  void _moveCandidature(CandidatureModel c, String newStatus) {
    // Mettre à jour le statut via le service
  }
}

// Card candidature dans le kanban
class CandidatureKanbanCard extends StatelessWidget {
  final CandidatureModel c;
  const CandidatureKanbanCard({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(
          color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 16, backgroundColor: const Color(0xFF1A56DB),
            child: Text(c.candidatName[0], style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.candidatName, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
            Text(c.postePostule, style: GoogleFonts.inter(
              fontSize: 11, color: const Color(0xFF64748B))),
          ])),
          MatchingScoreBadge(score: c.matchingScore),
        ]),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(c.timeAgo, style: GoogleFonts.inter(
            fontSize: 11, color: const Color(0xFF94A3B8))),
          Row(children: [
            _QuickAction(Icons.visibility_outlined, () =>
              context.push('/dashboard-recruteur/candidatures/${c.id}')),
            _QuickAction(Icons.chat_bubble_outline, () =>
              context.push('/dashboard-recruteur/messages?candidatId=${c.candidatId}')),
          ]),
        ]),
      ]),
    );
  }
}
```

---

## 11. Page Détail Candidature

```dart
// Route : /dashboard-recruteur/candidatures/:id
// Layout deux colonnes : infos candidat (60%) | actions (40%)

// COLONNE GAUCHE :
// ── CV et profil
//   Avatar + Nom + Poste recherché
//   Score IA matching (grand badge coloré)
//   Informations : email, téléphone, ville, disponibilité
//   Compétences détectées par IA (chips)
//   Expérience professionnelle (timeline)
//   Formation (timeline)
//   Lettre de motivation (expandable)
//   Bouton [📄 Télécharger le CV]
//   Bouton [👁 Voir profil complet]

// COLONNE DROITE :
// ── Statut et actions
//   Statut actuel (StatusBadge éditable)
//   Changer le statut (boutons ou dropdown)
//   Notes internes (TextArea, visibles par l'entreprise seulement)
//   Planifier un entretien (DateTimePicker + lien visio)
//   Envoyer un message (shortcut vers messagerie)
//   Boutons principaux :
//     [✓ Accepter] vert
//     [✗ Refuser] rouge (avec motif optionnel)
//     [📅 Planifier entretien] violet

// Historique des actions sur cette candidature (audit trail)
```

---

## 12. Page Recherche de Talents (IA)

### Concept
```
Moteur de recherche intelligent alimenté par l'IA NLP.
L'entreprise entre ses critères et l'IA propose les profils
les plus pertinents avec un score de matching.
```

### Wireframe
```
┌─────────────────────────────────────────────────────────────────┐
│  🤖 Recherche de Talents par IA                                 │
│  Trouvez le profil idéal parmi 1 200+ candidats inscrits        │
├─────────────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ 🔍 Titre du poste ou compétences...                  [→]  │  │
│  └───────────────────────────────────────────────────────────┘  │
│  Filtres : [Expérience ▼] [Ville ▼] [Études ▼] [Disponibilité ▼]│
├───────────────────┬─────────────────────────────────────────────┤
│  FILTRES (gauche) │  RÉSULTATS (droite)                         │
│  ─────────────    │  ─────────────────────────────────────────  │
│  Expérience       │  Triés par : [Score IA ▼]   47 résultats    │
│  ○ Sans exp.      │                                             │
│  ○ 1-2 ans        │  ┌────────────────────────────────────────┐ │
│  ● 3-5 ans        │  │ [MB] Mamadou Barry        Score : 94%  │ │
│  ○ 5+ ans         │  │ Développeur Flutter · 4 ans exp.       │ │
│                   │  │ Conakry · Disponible maintenant        │ │
│  Ville            │  │ Skills: Flutter, Dart, Firebase, REST  │ │
│  ● Conakry        │  │ [Voir profil] [Contacter] [Sauvegarder]│ │
│  ○ Kindia         │  └────────────────────────────────────────┘ │
│  ○ Boké           │                                             │
│                   │  ┌────────────────────────────────────────┐ │
│  Études           │  │ [AD] Aissatou Diallo       Score : 91% │ │
│  ○ Licence        │  │ UX/UI Designer · 3 ans exp.            │ │
│  ● Master         │  │ Conakry · Disponible dans 1 mois       │ │
│                   │  └────────────────────────────────────────┘ │
└───────────────────┴─────────────────────────────────────────────┘
```

### Code Flutter
```dart
// lib/screens/recruteur/pages/talents_search_page.dart
// Fonctionnalités :
// - Barre de recherche avec suggestions auto
// - Filtres : expérience, ville, études, disponibilité, langues
// - Résultats triés par score IA (desc par défaut)
// - TalentCard avec score matching, compétences, actions
// - Pagination infinie (LoadMore) ou paginée
// - Sauvegarder un talent dans une liste "favoris"
// - Contacter directement depuis la card
// - Voir le profil complet dans un SidePanel ou nouvelle page

class TalentCard extends StatelessWidget {
  final TalentModel talent;
  final bool compact; // version réduite pour la homepage

  // Contenu full card :
  // Avatar + Nom + Titre
  // MatchingScoreBadge (grand, coloré selon %)
  // Chips compétences (max 4 visibles + "+X")
  // Infos : ville, expérience, disponibilité
  // Boutons : [Voir profil] [Contacter] [♡ Sauvegarder]
}
```

### Widget Score Matching
```dart
// lib/screens/recruteur/widgets/matching_score_badge.dart

class MatchingScoreBadge extends StatelessWidget {
  final int score; // 0-100

  Color get _color {
    if (score >= 80) return const Color(0xFF10B981); // Excellent
    if (score >= 60) return const Color(0xFF1A56DB); // Bon
    if (score >= 40) return const Color(0xFFF59E0B); // Moyen
    return const Color(0xFFEF4444); // Faible
  }

  String get _label {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Bon match';
    if (score >= 40) return 'Moyen';
    return 'Faible';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.auto_awesome, size: 12, color: _color),
        const SizedBox(width: 4),
        Text('$score% · $_label', style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600, color: _color)),
      ]),
    );
  }
}
```

---

## 13. Page Profil de l'Entreprise

### Sections
```dart
// SECTION 1 : Identité visuelle
// - Photo de couverture (bannière, upload)
// - Logo (upload, carré)
// - Nom de l'entreprise
// - Slogan / Tagline (max 120 chars)

// SECTION 2 : Informations générales
// - Secteur d'activité
// - Taille (1-10 / 11-50 / 51-200 / ...)
// - Année de fondation
// - Site web
// - Email de contact public
// - Téléphone public
// - Adresse complète (Ville, Guinée)

// SECTION 3 : Description & Culture
// - À propos (éditeur rich text, min 150 chars)
// - Mission de l'entreprise (max 280 chars)
// - Valeurs (tags éditables, max 5)
// - Avantages employeur (chips sélectionnables)

// SECTION 4 : Réseaux sociaux
// - LinkedIn
// - Facebook
// - Twitter / X
// - Instagram
// - WhatsApp Business

// SECTION 5 : Aperçu public
// Preview du profil tel qu'il apparaît aux candidats
// Bouton "Voir mon profil public →"

// Actions :
// [Sauvegarder les modifications]
// Auto-save toutes les 30 secondes
```

---

## 14. Page Messagerie

### Concept
```
Interface de messagerie interne bidirectionnelle.
L'entreprise peut contacter les candidats qui ont postulé
ou que l'IA a recommandés.
```

### Layout
```
┌─────────────────────────────────────────────────────────────────┐
│  💬 Messagerie                    [✏️ Nouveau message]          │
├──────────────────────┬──────────────────────────────────────────┤
│  LISTE CONVERSATIONS │  CONVERSATION ACTIVE                     │
│  ─────────────────   │  ──────────────────────────────────────  │
│  🔍 Rechercher...    │  [MB] Mamadou Barry · Dev Flutter        │
│                      │  Offre : Développeur Flutter Senior      │
│  [MB] Mamadou Barry  │                                          │
│  "Merci pour votre   │  ┌─────────────────────────────────────┐ │
│   retour..."   2min  │  │ Entreprise (vous)    10:30           │ │
│   ● non lu           │  │ Bonjour Mamadou, nous avons bien    │ │
│                      │  │ reçu votre candidature...           │ │
│  [AD] Aissatou D.    │  └─────────────────────────────────────┘ │
│  "Oui, je suis       │                                          │
│   disponible"  1h    │  ┌─────────────────────────────────────┐ │
│                      │  │ Mamadou Barry         10:45          │ │
│  [IB] Ibrahima B.    │  │ Merci pour votre retour ! Je suis   │ │
│  "Merci, à bientôt"  │  │ très intéressé par le poste...      │ │
│   3h                 │  └─────────────────────────────────────┘ │
│                      │                                          │
│                      │  ┌─────────────────────────────────────┐ │
│                      │  │ 📎  [Écrire un message...] → [Send] │ │
│                      │  └─────────────────────────────────────┘ │
└──────────────────────┴──────────────────────────────────────────┘
```

### Code Flutter
```dart
// lib/screens/recruteur/pages/messagerie_page.dart

class MessageriePage extends StatefulWidget {
  final String? candidatId; // Ouvrir directement une conversation
  const MessageriePage({super.key, this.candidatId});
  @override
  State<MessageriePage> createState() => _MessageriePageState();
}

class _MessageriePageState extends State<MessageriePage> {
  String? _selectedConversationId;
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  // Layout :
  // Mobile (<768px) : liste OU conversation (pas les deux)
  // Desktop : split 35/65

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Container(
      color: const Color(0xFFF8FAFC),
      child: isMobile
          ? _buildMobileLayout()
          : Row(children: [
              SizedBox(width: 320, child: _buildConversationsList()),
              Expanded(child: _buildConversationView()),
            ]),
    );
  }

  Widget _buildMessageBubble(MessageModel msg) {
    final isMe = msg.senderId == 'entreprise';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.55),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1A56DB) : Colors.white,
          borderRadius: BorderRadius.circular(12).copyWith(
            bottomRight: isMe ? const Radius.circular(2) : null,
            bottomLeft: !isMe ? const Radius.circular(2) : null,
          ),
          boxShadow: const [BoxShadow(
            color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(msg.content, style: GoogleFonts.inter(
            fontSize: 14, color: isMe ? Colors.white : const Color(0xFF0F172A),
            height: 1.4)),
          const SizedBox(height: 4),
          Text(msg.time, style: GoogleFonts.inter(
            fontSize: 11,
            color: isMe ? Colors.white60 : const Color(0xFF94A3B8))),
        ]),
      ),
    );
  }
}
```

---

## 15. Page Statistiques Recruteur

### KPIs et Graphiques
```dart
// SECTION 1 : KPIs principaux (4 cards)
// Vues totales des offres | Candidatures reçues | Taux de conversion | Délai moyen

// SECTION 2 : Évolution des vues (graphique courbes, 30j)
// X: dates   Y: nombre de vues par jour
// Courbes multiples si plusieurs offres actives

// SECTION 3 : Entonnoir de recrutement (funnel)
// Vues → Candidatures → En examen → Entretiens → Acceptés
// Visualisation verticale avec pourcentages à chaque étape

// SECTION 4 : Répartition des candidatures
// Par poste (pie chart)
// Par ville d'origine (bar chart horizontal)
// Par niveau d'études (bar chart)

// SECTION 5 : Performance par offre
// Tableau : Offre | Vues | Candidatures | Score moyen IA | Taux réponse | Durée moy.

// SECTION 6 : Profil moyen des candidats
// Expérience moyenne : 3.2 ans
// Villes principales : Conakry 78%, Kindia 12%...
// Compétences les plus représentées (word cloud ou bar)

// Filtre période : [7j] [30j] [3 mois] [6 mois] [1 an]
// Bouton export rapport PDF/Excel
```

---

## 16. Page Notifications

```dart
// Notifications groupées par type et date :
// AUJOURD'HUI
//   🟢 Nouvelle candidature — Mamadou Barry a postulé à "Développeur Flutter" — il y a 5 min
//   🔵 Message reçu — Aissatou Diallo vous a envoyé un message — il y a 23 min
//   🟡 Offre bientôt expirée — "Chef de projet" expire dans 3 jours — il y a 1h

// HIER
//   🟢 Nouvelle candidature — Sekou Kouyaté a postulé... — hier 14:32
//   ✅ Offre validée — Votre offre "Data Analyst" a été validée par l'admin — hier 09:15

// CETTE SEMAINE
//   [...]

// Fonctionnalités :
// Marquer tout comme lu
// Filtrer par type (candidatures / messages / offres / système)
// Cliquer sur une notification → naviguer vers la page correspondante
// Préférences de notification (lien vers paramètres)
```

---

## 17. Page Paramètres Compte

### Sections
```dart
// SECTION 1 : Informations du compte
// Email du compte
// Changer le mot de passe
// Langue de l'interface
// Fuseau horaire

// SECTION 2 : Préférences de notification
// Email : nouvelles candidatures (on/off)
// Email : messages reçus (on/off)
// Email : offre bientôt expirée (on/off)
// Email : résumé hebdomadaire (on/off)
// Push notifications (on/off)

// SECTION 3 : Confidentialité
// Visibilité du profil entreprise
// Afficher/masquer le salaire dans les offres par défaut
// Permettre aux candidats de vous contacter directement

// SECTION 4 : Facturation (futur)
// Plan actuel : Gratuit
// Upgrade vers plan Pro (désactivé pour v1, affichage seulement)

// SECTION 5 : Danger Zone
// Désactiver temporairement le compte
// Supprimer définitivement le compte
// (avec ConfirmDialog renforcé : saisir "SUPPRIMER" pour confirmer)
```

---

## 18. Composants Partagés Recruteur

### Récapitulatif des widgets à créer
```dart
// RecruteurStatCard    : card statistique avec icône, valeur, tendance
// OffreCard            : card d'offre dans la liste (avec stats + actions)
// CandidatureCard      : card candidature en vue liste
// CandidatureKanbanCard: card candidature en vue kanban (plus compacte)
// TalentCard           : card profil talent dans la recherche IA
// MatchingScoreBadge   : badge score IA (couleur selon %)
// KanbanBoard          : board kanban draggable
// CvViewer             : visualiseur de CV intégré
// OffreFormSteps       : stepper du formulaire offre
// TipsPanel            : panneau conseils latéral (formulaire offre)
// MessageBubble        : bulle de message
// ConversationTile     : tile de conversation dans la liste
// NotificationTile     : item de notification
// _ActionButton        : bouton d'action inline dans les cards
// _StatChip            : chip de statistique dans les cards offres
```

---

## 19. Routing Recruteur Complet

```dart
// lib/app/router.dart — AJOUTER ces routes

ShellRoute(
  builder: (context, state, child) => RecruteurShell(child: child),
  routes: [
    GoRoute(
      path: '/dashboard-recruteur',
      redirect: (ctx, state) {
        // if (!authService.isRecruteur) return '/connexion';
        return null;
      },
      builder: (ctx, state) => const RecruteurDashboardPage(),
    ),
    GoRoute(
      path: '/dashboard-recruteur/offres',
      builder: (ctx, state) => const MesOffresPage(),
    ),
    GoRoute(
      path: '/dashboard-recruteur/offres/nouvelle',
      builder: (ctx, state) => const CreateEditOffrePage(),
    ),
    GoRoute(
      path: '/dashboard-recruteur/offres/:id/modifier',
      builder: (ctx, state) => CreateEditOffrePage(
        offreId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/dashboard-recruteur/candidatures',
      builder: (ctx, state) {
        final offreId = state.uri.queryParameters['offreId'];
        return CandidaturesPage(offreId: offreId);
      },
    ),
    GoRoute(
      path: '/dashboard-recruteur/candidatures/:id',
      builder: (ctx, state) => CandidatureDetailPage(
        candidatureId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/dashboard-recruteur/talents',
      builder: (ctx, state) => const TalentsSearchPage(),
    ),
    GoRoute(
      path: '/dashboard-recruteur/profil',
      builder: (ctx, state) => const ProfilEntreprisePage(),
    ),
    GoRoute(
      path: '/dashboard-recruteur/messages',
      builder: (ctx, state) {
        final candidatId = state.uri.queryParameters['candidatId'];
        return MessageriePage(candidatId: candidatId);
      },
    ),
    GoRoute(
      path: '/dashboard-recruteur/statistiques',
      builder: (ctx, state) => const StatistiquesRecruteurPage(),
    ),
    GoRoute(
      path: '/dashboard-recruteur/notifications',
      builder: (ctx, state) => const NotificationsRecruteurPage(),
    ),
    GoRoute(
      path: '/dashboard-recruteur/parametres',
      builder: (ctx, state) => const ParametresRecruteurPage(),
    ),
  ],
),
```

---

## 20. Animations & Micro-interactions

```dart
// ── SIDEBAR ───────────────────────────────────────────────────
// Item actif : fond bleu clair #EFF6FF, texte bleu, transition 150ms
// Hover : fond gris #F8FAFC, transition 150ms
// Badge count : pulse animation si nouveau(x) élément(s)

// ── STAT CARDS ────────────────────────────────────────────────
// Entrée : FadeInUp stagger 80ms
// Valeurs : TweenAnimationBuilder (compteur 0 → valeur)
// Hover : translateY(-4px) + ombre, 200ms

// ── LISTE OFFRES ──────────────────────────────────────────────
// Chaque OffreCard : FadeInUp stagger 60ms
// Hover : fond légèrement coloré, 150ms

// ── KANBAN ────────────────────────────────────────────────────
// Drag : Material elevation 8 + feedback semi-transparent
// Drop : AnimatedContainer scale 1.0→1.02→1.0
// Colonnes : FadeInLeft stagger 100ms

// ── FORMULAIRE OFFRE ──────────────────────────────────────────
// Transitions étapes : AnimatedSwitcher FadeTransition + SlideTransition
// Success dialog : ZoomIn + confetti (lottie animation)
// Auto-save indicator : fade in/out

// ── MESSAGERIE ────────────────────────────────────────────────
// Messages entrants : FadeInLeft
// Messages envoyés : FadeInRight
// Scroll auto vers le bas à l'ouverture

// ── SCORE MATCHING ────────────────────────────────────────────
// Badge : ZoomIn à l'apparition
// Couleur : AnimatedContainer 300ms si changement

// ── NOTIFICATIONS ─────────────────────────────────────────────
// Nouvelles : FadeInDown
// Badge topbar : scale 1.0→1.2→1.0 si nouvelle notification
```

---

## 21. Responsive Dashboard Recruteur

```dart
// ── BREAKPOINTS ───────────────────────────────────────────────
// Desktop  : >= 1024px → sidebar 240px + contenu
// Tablet   : 768-1023px → sidebar en drawer + contenu pleine largeur
// Mobile   : < 768px → drawer + layout simplifié

// ── SPÉCIFICITÉS PAR PAGE ─────────────────────────────────────

// Dashboard home :
// Desktop : 4 stat cards en ligne, graphique+offres côte à côte
// Mobile  : 2 stat cards par ligne, sections empilées

// Mes offres :
// Desktop : liste pleine largeur avec toutes les infos
// Mobile  : cards simplifiées (titre + statut + 2 actions)

// Créer une offre :
// Desktop : formulaire (70%) + panneau conseils (30%)
// Mobile  : formulaire seul, conseils en Tooltip/InfoSheet

// Candidatures Kanban :
// Desktop : 5 colonnes visibles (scroll horizontal si besoin)
// Tablet  : 3 colonnes + scroll horizontal
// Mobile  : vue liste uniquement (kanban masqué)

// Messagerie :
// Desktop : split 35/65
// Mobile  : liste OU conversation (back button pour revenir)

// Statistiques :
// Desktop : graphiques côte à côte
// Mobile  : graphiques empilés verticalement, taille réduite
```

---

## 22. Critères d'Acceptation

### ✅ RecruteurShell (Layout)
- [ ] Sidebar blanche avec bordure droite légère
- [ ] Logo entreprise dans le header sidebar (initiales si pas de logo)
- [ ] Items sidebar avec états actif/hover corrects (bleu)
- [ ] Badges de count sur Mes offres, Candidatures, Messagerie, Notifications
- [ ] Bouton CTA "Publier une offre" en bas de sidebar
- [ ] TopBar avec fil d'ariane, bouton "Nouvelle offre", notif badge
- [ ] Drawer sur mobile/tablette
- [ ] Transitions page fade 250ms

### ✅ Dashboard Home
- [ ] Message bienvenue avec nom entreprise et date
- [ ] Alerte candidatures en attente (si > 0)
- [ ] 4 stat cards avec compteur animé
- [ ] Section candidatures récentes avec score IA
- [ ] Graphique vues des offres
- [ ] Liste offres actives avec lien vers candidatures
- [ ] Section recommandations IA (4 profils)

### ✅ Mes Offres
- [ ] Tabs Toutes/Actives/En attente/Expirées/Brouillons
- [ ] OffreCard avec stats (vues, candidatures, non lues)
- [ ] Actions : voir candidatures, modifier, dupliquer, clôturer
- [ ] ConfirmDialog pour clôture
- [ ] Filtres fonctionnels

### ✅ Créer/Modifier une Offre
- [ ] Stepper 4 étapes avec barre progression
- [ ] Tous les champs de l'Étape 1 (titre, secteur, contrat, ville, salaire, deadline)
- [ ] Étape 2 : description + missions éditables dynamiquement
- [ ] Étape 3 : compétences chips + niveaux + avantages sélectionnables
- [ ] Étape 4 : aperçu + options publication
- [ ] Auto-save visible
- [ ] Dialog succès animé après publication
- [ ] Panneau conseils latéral (desktop)

### ✅ Candidatures
- [ ] Vue Liste et Vue Kanban switchables
- [ ] Kanban : 5 colonnes draggable (Reçues/Examen/Entretien/Acceptés/Refusés)
- [ ] MatchingScoreBadge coloré sur chaque candidature
- [ ] Actions rapides depuis les cards
- [ ] Page détail avec CV, score IA, notes internes, actions (accepter/refuser/entretien)

### ✅ Recherche Talents IA
- [ ] Barre de recherche avec suggestions
- [ ] Filtres avancés (expérience, ville, études, dispo)
- [ ] TalentCards avec score matching
- [ ] Tri par score IA
- [ ] Actions : voir profil, contacter, sauvegarder

### ✅ Profil Entreprise
- [ ] Upload logo et bannière
- [ ] Tous les champs d'informations
- [ ] Éditeur description rich text
- [ ] Réseaux sociaux
- [ ] Aperçu public

### ✅ Messagerie
- [ ] Liste conversations avec dernière réponse
- [ ] Bulles de message avec design distinct envoyé/reçu
- [ ] Champ de saisie avec envoi (Entrée ou bouton)
- [ ] Scroll automatique vers le bas
- [ ] Layout split desktop / séquentiel mobile

### ✅ Statistiques
- [ ] 4 KPI cards
- [ ] Graphique courbes vues (fl_chart)
- [ ] Entonnoir de recrutement
- [ ] Tableau performance par offre
- [ ] Filtre période

### ✅ Global
- [ ] Design cohérent avec homepage et admin (AppColors, fonts)
- [ ] Sidebar claire différenciée de la sidebar admin sombre
- [ ] StatusBadge cohérents sur toutes les pages
- [ ] SnackBars succès/erreur sur toutes les actions
- [ ] Aucune erreur console Flutter
- [ ] Test responsive : 375px / 768px / 1024px / 1280px / 1440px

---

*PRD EmploiConnect v2.1 — Dashboard Recruteur/Entreprise — Flutter*
*Projet académique — Licence Professionnelle Génie Logiciel — Guinée 2025-2026*
*BARRY YOUSSOUF (22 000 46) · DIALLO ISMAILA (23 008 60)*
*Encadré par M. DIALLO BOUBACAR — CEO Rasenty*
*Cursor / Kirsoft AI — Phase 4 — Suite Admin Dashboard validé*
