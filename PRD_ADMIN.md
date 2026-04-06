# PRD — EmploiConnect · Tableau de Bord Administrateur
## Product Requirements Document v2.0 — Admin Dashboard
**Stack : Flutter (Dart) · GoRouter · Google Fonts (Poppins + Inter)**
**Outil : Cursor / Kirsoft AI**
**Module : Administration Complète de la Plateforme**
**Statut : Phase 3 — Suite Auth validée**
**Date : Mars 2026**

---

> ### ⚠️ INSTRUCTIONS CRITIQUES POUR CURSOR
>
> 1. Homepage ✅ validée — Auth ✅ validée — NE PAS TOUCHER
> 2. **Même système de design** : AppColors, AppTextStyles, AppDimensions
> 3. **Même cohérence visuelle** : Poppins (titres) + Inter (corps)
> 4. Le dashboard admin est accessible UNIQUEMENT avec `role == 'admin'`
> 5. Route protégée : `/admin` → redirection `/connexion` si non admin
> 6. Design objectif : **professionnel, intuitif, extraordinaire**
>    Référence visuelle : niveau Vercel Dashboard / Linear / Notion Admin
> 7. Implémenter **dans l'ordre exact** de ce PRD

---

## Table des Matières

1. [Vue d'ensemble Admin](#1-vue-densemble-admin)
2. [Architecture du Dashboard](#2-architecture-du-dashboard)
3. [Système de Design Admin](#3-système-de-design-admin)
4. [Layout Principal — AdminShell](#4-layout-principal--adminshell)
5. [Sidebar Navigation](#5-sidebar-navigation)
6. [TopBar Admin](#6-topbar-admin)
7. [Page Vue d'ensemble — Dashboard Home](#7-page-vue-densemble--dashboard-home)
8. [Page Gestion Utilisateurs](#8-page-gestion-utilisateurs)
9. [Page Gestion Offres d'Emploi](#9-page-gestion-offres-demploi)
10. [Page Gestion Entreprises](#10-page-gestion-entreprises)
11. [Page Gestion Candidatures](#11-page-gestion-candidatures)
12. [Page Modération & Signalements](#12-page-modération--signalements)
13. [Page Statistiques & Analytiques](#13-page-statistiques--analytiques)
14. [Page Paramètres Plateforme](#14-page-paramètres-plateforme)
15. [Page Notifications & Messages](#15-page-notifications--messages)
16. [Composants Partagés Admin](#16-composants-partagés-admin)
17. [Routing Admin Complet](#17-routing-admin-complet)
18. [Animations & Micro-interactions](#18-animations--micro-interactions)
19. [Responsive Admin](#19-responsive-admin)
20. [Critères d'Acceptation](#20-critères-dacceptation)

---

## 1. Vue d'ensemble Admin

### Rôle de l'Administrateur
L'administrateur a un **contrôle total** sur la plateforme EmploiConnect :
- Superviser tous les utilisateurs (candidats + recruteurs)
- Valider, modifier ou supprimer les offres d'emploi
- Gérer les entreprises inscrites
- Modérer les contenus signalés
- Consulter les statistiques globales en temps réel
- Configurer les paramètres de la plateforme
- Envoyer des notifications aux utilisateurs

### Pages du Dashboard Admin
| # | Page | Route | Icône |
|---|------|-------|-------|
| 1 | Vue d'ensemble | `/admin` | `dashboard` |
| 2 | Utilisateurs | `/admin/utilisateurs` | `people` |
| 3 | Offres d'emploi | `/admin/offres` | `work` |
| 4 | Entreprises | `/admin/entreprises` | `business` |
| 5 | Candidatures | `/admin/candidatures` | `assignment` |
| 6 | Modération | `/admin/moderation` | `shield` |
| 7 | Statistiques | `/admin/statistiques` | `bar_chart` |
| 8 | Paramètres | `/admin/parametres` | `settings` |
| 9 | Notifications | `/admin/notifications` | `notifications` |

---

## 2. Architecture du Dashboard

### Structure des Fichiers
```
lib/
├── screens/
│   └── admin/
│       ├── admin_shell.dart              ← Layout principal (sidebar + topbar)
│       ├── pages/
│       │   ├── admin_dashboard_page.dart ← Vue d'ensemble
│       │   ├── users_page.dart           ← Gestion utilisateurs
│       │   ├── jobs_page.dart            ← Gestion offres
│       │   ├── companies_page.dart       ← Gestion entreprises
│       │   ├── applications_page.dart    ← Gestion candidatures
│       │   ├── moderation_page.dart      ← Modération
│       │   ├── statistics_page.dart      ← Statistiques
│       │   ├── settings_page.dart        ← Paramètres
│       │   └── notifications_page.dart   ← Notifications
│       └── widgets/
│           ├── admin_sidebar.dart
│           ├── admin_topbar.dart
│           ├── stat_card.dart
│           ├── admin_data_table.dart
│           ├── admin_search_bar.dart
│           ├── status_badge.dart
│           ├── action_menu.dart
│           ├── chart_widget.dart
│           ├── admin_empty_state.dart
│           └── confirm_dialog.dart
├── models/
│   ├── admin_stats.dart
│   ├── user_model.dart
│   ├── job_offer.dart          ← déjà existant
│   ├── company_model.dart
│   ├── application_model.dart
│   └── report_model.dart
└── services/
    ├── admin_service.dart
    └── stats_service.dart
```

### Layout Global
```
╔══════════════════════════════════════════════════════════════╗
║  SIDEBAR (240px fixe)  │  TOPBAR (hauteur 64px)             ║
║  ────────────────────  │  ──────────────────────────────    ║
║                        │                                    ║
║  Logo EmploiConnect     │  Titre page  [🔔] [👤 Admin]      ║
║                        │                                    ║
║  ─ MENU PRINCIPAL ─    │  ══════════════════════════════    ║
║  🏠 Vue d'ensemble     │                                    ║
║  👥 Utilisateurs       │                                    ║
║  💼 Offres d'emploi    │      CONTENU DE LA PAGE            ║
║  🏢 Entreprises        │                                    ║
║  📋 Candidatures       │      (scrollable)                  ║
║  🛡️ Modération         │                                    ║
║  📊 Statistiques       │                                    ║
║                        │                                    ║
║  ─ CONFIGURATION ─     │                                    ║
║  🔔 Notifications      │                                    ║
║  ⚙️ Paramètres         │                                    ║
║                        │                                    ║
║  ─ COMPTE ─            │                                    ║
║  👤 Mon profil         │                                    ║
║  🚪 Déconnexion        │                                    ║
╚══════════════════════════════════════════════════════════════╝
```

---

## 3. Système de Design Admin

### Palette Spécifique Admin
```dart
// Extension de AppColors pour l'admin

class AdminColors {
  // Sidebar
  static const Color sidebarBg       = Color(0xFF0F172A); // Fond sidebar sombre
  static const Color sidebarBorder   = Color(0xFF1E293B); // Bordure sidebar
  static const Color sidebarActive   = Color(0xFF1A56DB); // Item actif
  static const Color sidebarActiveBg = Color(0x1A1A56DB); // Fond item actif (10% opacité)
  static const Color sidebarHover    = Color(0xFF1E293B); // Fond item hover
  static const Color sidebarText     = Color(0xFF94A3B8); // Texte items sidebar
  static const Color sidebarTextActive = Color(0xFFFFFFFF); // Texte item actif

  // Topbar
  static const Color topbarBg        = Color(0xFFFFFFFF);
  static const Color topbarBorder    = Color(0xFFE2E8F0);

  // Contenu
  static const Color contentBg       = Color(0xFFF8FAFC); // Fond du contenu
  static const Color cardBg          = Color(0xFFFFFFFF); // Fond des cards

  // Stat cards couleurs
  static const Color statBlue        = Color(0xFF1A56DB);
  static const Color statBlueBg      = Color(0xFFEFF6FF);
  static const Color statGreen       = Color(0xFF10B981);
  static const Color statGreenBg     = Color(0xFFECFDF5);
  static const Color statOrange      = Color(0xFFF59E0B);
  static const Color statOrangeBg    = Color(0xFFFEF3C7);
  static const Color statRed         = Color(0xFFEF4444);
  static const Color statRedBg       = Color(0xFFFEE2E2);
  static const Color statPurple      = Color(0xFF8B5CF6);
  static const Color statPurpleBg    = Color(0xFFF5F3FF);

  // Status badges
  static const Color statusActive    = Color(0xFF10B981); // Actif / Approuvé
  static const Color statusActiveBg  = Color(0xFFD1FAE5);
  static const Color statusPending   = Color(0xFFF59E0B); // En attente
  static const Color statusPendingBg = Color(0xFFFEF3C7);
  static const Color statusBlocked   = Color(0xFFEF4444); // Bloqué / Rejeté
  static const Color statusBlockedBg = Color(0xFFFEE2E2);
  static const Color statusDraft     = Color(0xFF64748B); // Brouillon
  static const Color statusDraftBg   = Color(0xFFF1F5F9);
}
```

### Dimensions Admin
```dart
static const double sidebarWidth        = 240.0;
static const double sidebarCollapsed    = 64.0;  // Mode réduit mobile
static const double topbarHeight        = 64.0;
static const double contentPaddingH     = 32.0;
static const double contentPaddingV     = 28.0;
static const double cardRadius          = 12.0;
static const double tableRowHeight      = 56.0;
static const double statCardHeight      = 120.0;
```

---

## 4. Layout Principal — AdminShell

```dart
// lib/screens/admin/admin_shell.dart
// C'est le widget parent qui contient TOUT le dashboard admin

class AdminShell extends StatefulWidget {
  final Widget child; // Page active injectée par GoRouter
  const AdminShell({super.key, required this.child});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  bool _sidebarCollapsed = false; // Pour mode compact

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // Mobile : drawer au lieu de sidebar fixe
      drawer: isMobile ? AdminSidebar(isDrawer: true) : null,
      body: Row(
        children: [
          // Sidebar fixe (desktop)
          if (!isMobile)
            AdminSidebar(collapsed: _sidebarCollapsed),

          // Contenu principal
          Expanded(
            child: Column(
              children: [
                // TopBar
                AdminTopBar(
                  onMenuPressed: isMobile
                      ? () => Scaffold.of(context).openDrawer()
                      : () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                ),
                // Page active
                Expanded(
                  child: FadeTransition(
                    opacity: const AlwaysStoppedAnimation(1.0),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 5. Sidebar Navigation

```dart
// lib/screens/admin/widgets/admin_sidebar.dart

class AdminSidebar extends StatelessWidget {
  final bool collapsed;
  final bool isDrawer;
  const AdminSidebar({super.key, this.collapsed = false, this.isDrawer = false});

  // Items du menu
  static const List<_SidebarSection> sections = [
    _SidebarSection(title: null, items: [
      _SidebarItem(label: 'Vue d\'ensemble', icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded, route: '/admin'),
    ]),
    _SidebarSection(title: 'GESTION', items: [
      _SidebarItem(label: 'Utilisateurs', icon: Icons.people_outline,
        activeIcon: Icons.people_rounded, route: '/admin/utilisateurs',
        badgeKey: 'pending_users'),
      _SidebarItem(label: 'Offres d\'emploi', icon: Icons.work_outline,
        activeIcon: Icons.work_rounded, route: '/admin/offres',
        badgeKey: 'pending_jobs'),
      _SidebarItem(label: 'Entreprises', icon: Icons.business_outlined,
        activeIcon: Icons.business_rounded, route: '/admin/entreprises'),
      _SidebarItem(label: 'Candidatures', icon: Icons.assignment_outlined,
        activeIcon: Icons.assignment_rounded, route: '/admin/candidatures'),
      _SidebarItem(label: 'Modération', icon: Icons.shield_outlined,
        activeIcon: Icons.shield_rounded, route: '/admin/moderation',
        badgeKey: 'reports', badgeColor: Color(0xFFEF4444)),
    ]),
    _SidebarSection(title: 'ANALYSE', items: [
      _SidebarItem(label: 'Statistiques', icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded, route: '/admin/statistiques'),
    ]),
    _SidebarSection(title: 'CONFIGURATION', items: [
      _SidebarItem(label: 'Notifications', icon: Icons.notifications_outlined,
        activeIcon: Icons.notifications_rounded, route: '/admin/notifications'),
      _SidebarItem(label: 'Paramètres', icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded, route: '/admin/parametres'),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: collapsed ? 64 : 240,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(right: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      child: Column(
        children: [
          // Logo
          _buildLogo(),
          const SizedBox(height: 8),

          // Menu items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sections.map((section) =>
                  _buildSection(section, currentRoute, collapsed)
                ).toList(),
              ),
            ),
          ),

          // Profil admin en bas
          _buildAdminProfile(collapsed),
        ],
      ),
    );
  }

  Widget _buildLogo() => Container(
    height: 64,
    padding: EdgeInsets.symmetric(horizontal: collapsed ? 12 : 20),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
    ),
    child: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.work_outline, color: Colors.white, size: 18),
      ),
      if (!collapsed) ...[
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('EmploiConnect', style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          Text('Administration', style: GoogleFonts.inter(
            fontSize: 10, color: const Color(0xFF64748B))),
        ]),
      ],
    ]),
  );

  Widget _buildSection(_SidebarSection section, String currentRoute, bool collapsed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title != null && !collapsed)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
            child: Text(section.title!, style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w600,
              color: const Color(0xFF475569), letterSpacing: 0.8,
            )),
          ),
        ...section.items.map((item) =>
          _buildSidebarItem(item, currentRoute, collapsed)),
      ],
    );
  }

  Widget _buildSidebarItem(_SidebarItem item, String currentRoute, bool collapsed) {
    final isActive = currentRoute == item.route ||
        (item.route != '/admin' && currentRoute.startsWith(item.route));

    return Builder(builder: (context) => Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF1A56DB).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () => context.go(item.route),
          borderRadius: BorderRadius.circular(8),
          hoverColor: const Color(0xFF1E293B),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 16 : 12, vertical: 10),
            child: Row(children: [
              Icon(
                isActive ? item.activeIcon : item.icon,
                size: 20,
                color: isActive
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFF94A3B8),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Expanded(child: Text(item.label, style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? Colors.white : const Color(0xFF94A3B8),
                ))),
                // Badge de notification
                if (item.badgeKey != null)
                  _NotificationBadge(badgeKey: item.badgeKey!, color: item.badgeColor),
              ],
            ]),
          ),
        ),
      ),
    ));
  }

  Widget _buildAdminProfile(bool collapsed) => Container(
    padding: EdgeInsets.symmetric(horizontal: collapsed ? 12 : 16, vertical: 16),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0xFF1E293B))),
    ),
    child: Row(children: [
      CircleAvatar(
        radius: 16, backgroundColor: const Color(0xFF1A56DB),
        child: Text('A', style: GoogleFonts.inter(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
      if (!collapsed) ...[
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Administrateur', style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          Text('Super Admin', style: GoogleFonts.inter(
            fontSize: 11, color: const Color(0xFF64748B))),
        ])),
        Builder(builder: (ctx) => IconButton(
          icon: const Icon(Icons.logout_outlined, color: Color(0xFF64748B), size: 18),
          tooltip: 'Déconnexion',
          onPressed: () => _showLogoutDialog(ctx),
        )),
      ],
    ]),
  );

  void _showLogoutDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => ConfirmDialog(
      title: 'Déconnexion',
      message: 'Êtes-vous sûr de vouloir vous déconnecter ?',
      confirmLabel: 'Se déconnecter',
      confirmColor: const Color(0xFFEF4444),
      onConfirm: () => context.go('/connexion'),
    ));
  }
}
```

---

## 6. TopBar Admin

```dart
// lib/screens/admin/widgets/admin_topbar.dart

class AdminTopBar extends StatelessWidget {
  final VoidCallback onMenuPressed;
  const AdminTopBar({super.key, required this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final pageTitle = _getPageTitle(currentRoute);

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [BoxShadow(
          color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: [

        // Bouton menu (hamburger / collapse)
        IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF64748B)),
          onPressed: onMenuPressed,
        ),
        const SizedBox(width: 16),

        // Titre de la page
        Text(pageTitle, style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        )),

        const Spacer(),

        // Barre de recherche globale
        _GlobalSearchBar(),
        const SizedBox(width: 16),

        // Bouton notifications
        _NotificationButton(),
        const SizedBox(width: 8),

        // Avatar admin
        _AdminAvatarMenu(),
      ]),
    );
  }

  String _getPageTitle(String route) {
    final titles = {
      '/admin': 'Vue d\'ensemble',
      '/admin/utilisateurs': 'Gestion des Utilisateurs',
      '/admin/offres': 'Gestion des Offres',
      '/admin/entreprises': 'Gestion des Entreprises',
      '/admin/candidatures': 'Gestion des Candidatures',
      '/admin/moderation': 'Modération & Signalements',
      '/admin/statistiques': 'Statistiques & Analytiques',
      '/admin/parametres': 'Paramètres Plateforme',
      '/admin/notifications': 'Notifications',
    };
    return titles[route] ?? 'Administration';
  }
}

// Barre de recherche globale dans le topbar
class _GlobalSearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 280,
    height: 38,
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(children: [
      const SizedBox(width: 10),
      const Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
      const SizedBox(width: 8),
      Expanded(child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFCBD5E1)),
          border: InputBorder.none, isDense: true,
        ),
        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
      )),
      Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text('⌘K', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
      ),
    ]),
  );
}
```

---

## 7. Page Vue d'ensemble — Dashboard Home

### Wireframe
```
┌─────────────────────────────────────────────────────────────────┐
│  Bonjour, Administrateur 👋   Vendredi 27 Mars 2026             │
│  Voici un aperçu de la plateforme EmploiConnect aujourd'hui.    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │ 👥 1 284 │  │ 💼  487  │  │ 🏢  156  │  │ 📋 3 892 │       │
│  │Utilisat. │  │  Offres  │  │Entrepris.│  │Candidat. │       │
│  │ +12% ↑  │  │  +8% ↑  │  │ +5% ↑   │  │ +23% ↑  │       │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │
│                                                                 │
│  ┌──────────┐  ┌──────────┐                                     │
│  │ ⏳  23   │  │ 🛡️   7   │                                     │
│  │En attent.│  │Signalemt.│                                     │
│  │          │  │ URGENT  │                                     │
│  └──────────┘  └──────────┘                                     │
│                                                                 │
├──────────────────────────────┬──────────────────────────────────┤
│  📈 Activité (7 derniers j.) │  🕐 Activité Récente             │
│  [Graphique courbes]         │  ● Nouveau candidat inscrit      │
│                              │    Mamadou Diallo — il y a 5min  │
│                              │  ● Offre publiée                 │
│                              │    Orange Guinée — il y a 12min  │
│                              │  ● Signalement reçu              │
│                              │    Offre #247 — il y a 1h        │
│                              │  ● Entreprise validée            │
│                              │    MTN Guinée — il y a 2h        │
├──────────────────────────────┴──────────────────────────────────┤
│  🕐 Offres en attente de validation (23)          [Voir tout →] │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Développeur Mobile · Conakry · Orange Guinée  [✓][✗]    │   │
│  │ Chef de projet · Kindia · ONG Plan Int.       [✓][✗]    │   │
│  │ Comptable · Conakry · Ecobank                 [✓][✗]    │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Code Flutter — Admin Dashboard Page

```dart
// lib/screens/admin/pages/admin_dashboard_page.dart

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // En-tête de bienvenue
        _buildWelcomeHeader(),
        const SizedBox(height: 28),

        // Grille stats principales (6 cards)
        _buildStatsGrid(),
        const SizedBox(height: 28),

        // Graphique + Activité récente
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 60, child: _buildActivityChart()),
          const SizedBox(width: 20),
          Expanded(flex: 40, child: _buildRecentActivity()),
        ]),
        const SizedBox(height: 28),

        // Offres en attente
        _buildPendingJobs(),
        const SizedBox(height: 28),

        // Utilisateurs récents + Stats rapides
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 55, child: _buildRecentUsers()),
          const SizedBox(width: 20),
          Expanded(flex: 45, child: _buildQuickStats()),
        ]),
      ]),
    );
  }

  Widget _buildWelcomeHeader() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Bonjour, Administrateur 👋', style: GoogleFonts.poppins(
          fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
        const SizedBox(height: 4),
        Text('Voici un aperçu de la plateforme EmploiConnect aujourd\'hui.',
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
      ]),
      // Date du jour
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(_getFormattedDate(), style: GoogleFonts.inter(
            fontSize: 13, color: const Color(0xFF64748B))),
        ]),
      ),
    ],
  );

  Widget _buildStatsGrid() {
    final stats = [
      _StatData('Utilisateurs', '1 284', '+12%', true,
        Icons.people_rounded, AdminColors.statBlue, AdminColors.statBlueBg),
      _StatData('Offres actives', '487', '+8%', true,
        Icons.work_rounded, AdminColors.statGreen, AdminColors.statGreenBg),
      _StatData('Entreprises', '156', '+5%', true,
        Icons.business_rounded, AdminColors.statPurple, AdminColors.statPurpleBg),
      _StatData('Candidatures', '3 892', '+23%', true,
        Icons.assignment_rounded, AdminColors.statOrange, AdminColors.statOrangeBg),
      _StatData('En attente', '23', '', false,
        Icons.hourglass_empty_rounded, AdminColors.statOrange, AdminColors.statOrangeBg),
      _StatData('Signalements', '7', 'URGENT', false,
        Icons.shield_rounded, AdminColors.statRed, AdminColors.statRedBg),
    ];

    return LayoutBuilder(builder: (ctx, constraints) {
      final crossCount = constraints.maxWidth > 900 ? 3 : 2;
      return GridView.count(
        crossAxisCount: crossCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.2,
        children: stats.asMap().entries.map((e) =>
          FadeInUp(
            delay: Duration(milliseconds: e.key * 80),
            duration: const Duration(milliseconds: 500),
            child: StatCard(data: e.value),
          )
        ).toList(),
      );
    });
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const days = ['Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi','Dimanche'];
    const months = ['Jan','Fév','Mar','Avr','Mai','Jun','Jul','Aoû','Sep','Oct','Nov','Déc'];
    return '${days[now.weekday - 1]} ${now.day} ${months[now.month - 1]} ${now.year}';
  }
}
```

### StatCard Widget

```dart
// lib/screens/admin/widgets/stat_card.dart

class StatCard extends StatefulWidget {
  final _StatData data;
  const StatCard({super.key, required this.data});

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered
                ? widget.data.color.withOpacity(0.3)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: _hovered
              ? [BoxShadow(color: widget.data.color.withOpacity(0.1),
                  blurRadius: 20, offset: const Offset(0, 8))]
              : [const BoxShadow(color: Color(0x08000000),
                  blurRadius: 8, offset: Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          // Icône
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: widget.data.bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.data.icon, color: widget.data.color, size: 24),
          ),
          const SizedBox(width: 16),
          // Contenu
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.data.label, style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF64748B))),
              const SizedBox(height: 4),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(widget.data.value, style: GoogleFonts.poppins(
                  fontSize: 24, fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                )),
                if (widget.data.trend.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.data.isPositive
                          ? const Color(0xFFD1FAE5)
                          : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(widget.data.trend, style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: widget.data.isPositive
                          ? const Color(0xFF065F46)
                          : const Color(0xFF991B1B),
                    )),
                  ),
                ],
              ]),
            ],
          )),
        ]),
      ),
    );
  }
}
```

---

## 8. Page Gestion Utilisateurs

### Fonctionnalités
- Liste paginée de tous les utilisateurs (candidats + recruteurs)
- Filtres : rôle, statut, date d'inscription, ville
- Recherche par nom / email
- Actions : voir profil, activer, bloquer, supprimer
- Validation des nouveaux comptes en attente

### Wireframe
```
┌─────────────────────────────────────────────────────────────────┐
│  Gestion des Utilisateurs           [+ Ajouter un utilisateur]  │
├─────────────────────────────────────────────────────────────────┤
│  Filtres :  [Tous ▼]  [Statut ▼]  [Ville ▼]  [🔍 Rechercher]   │
│                                                                 │
│  Tabs : [Tous (1284)] [Candidats (1041)] [Recruteurs (243)]     │
│         [En attente (23)] [Bloqués (8)]                         │
├─────────────────────────────────────────────────────────────────┤
│  Avatar │ Nom              │ Email       │ Rôle   │ Statut│ 📋  │
│  ─────────────────────────────────────────────────────────────  │
│  [MB]   │ Mamadou Barry    │ m@gmail.com │ Candidat│ ●Actif│ ⋮  │
│  [AD]   │ Aissatou Diallo  │ a@gmail.com │ Candidat│ ●Actif│ ⋮  │
│  [OG]   │ Orange Guinée    │ hr@orange.gn│ Recruteur│ ●Actif│ ⋮ │
│  [SK]   │ Sekou Kouyaté    │ s@gmail.com │ Candidat│ ⏳Att.│ ⋮  │
│                                                                 │
│  ◀ Précédent    Page 1 / 43    Suivant ▶                        │
└─────────────────────────────────────────────────────────────────┘
```

### Code Flutter

```dart
// lib/screens/admin/pages/users_page.dart

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});
  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  String _searchQuery = '';
  String _selectedRole = 'Tous';
  String _selectedStatus = 'Tous';
  int _currentPage = 1;
  final int _perPage = 20;

  final List<String> _tabs = [
    'Tous', 'Candidats', 'Recruteurs', 'En attente', 'Bloqués'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // En-tête + bouton ajouter
        _buildHeader(),
        const SizedBox(height: 24),

        // Card principale
        Container(
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [BoxShadow(
              color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Column(children: [

            // Filtres et recherche
            _buildFiltersBar(),

            // Tabs
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
              labelColor: const Color(0xFF1A56DB),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF1A56DB),
              indicatorWeight: 2,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: [
                Tab(text: 'Tous (1 284)'),
                Tab(text: 'Candidats (1 041)'),
                Tab(text: 'Recruteurs (243)'),
                Tab(text: 'En attente (23)'),
                Tab(text: 'Bloqués (8)'),
              ],
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Tableau
            _buildUsersTable(),

            // Pagination
            _buildPagination(),
          ]),
        ),
      ]),
    );
  }

  Widget _buildHeader() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Gestion des Utilisateurs', style: GoogleFonts.poppins(
          fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
        Text('Gérez tous les comptes de la plateforme',
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
      ]),
      ElevatedButton.icon(
        icon: const Icon(Icons.person_add_outlined, size: 18),
        label: const Text('Ajouter un utilisateur'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A56DB),
          foregroundColor: Colors.white, elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        onPressed: () => _showAddUserDialog(),
      ),
    ],
  );

  Widget _buildFiltersBar() => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(children: [
      // Recherche
      Expanded(child: AdminSearchBar(
        hint: 'Rechercher par nom, email...',
        onChanged: (v) => setState(() => _searchQuery = v),
      )),
      const SizedBox(width: 12),
      // Filtre rôle
      _FilterDropdown(
        value: _selectedRole,
        items: ['Tous', 'Candidat', 'Recruteur', 'Admin'],
        onChanged: (v) => setState(() => _selectedRole = v!),
      ),
      const SizedBox(width: 12),
      // Filtre statut
      _FilterDropdown(
        value: _selectedStatus,
        items: ['Tous', 'Actif', 'En attente', 'Bloqué'],
        onChanged: (v) => setState(() => _selectedStatus = v!),
      ),
      const SizedBox(width: 12),
      // Export
      OutlinedButton.icon(
        icon: const Icon(Icons.download_outlined, size: 16),
        label: const Text('Exporter'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF64748B),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontSize: 14),
        ),
        onPressed: () {},
      ),
    ]),
  );

  Widget _buildUsersTable() {
    // Colonnes : Avatar+Nom | Email | Rôle | Statut | Ville | Date | Actions
    return AdminDataTable(
      columns: const ['Utilisateur', 'Email', 'Rôle', 'Statut', 'Ville', 'Inscrit le', ''],
      rows: _getMockUsers().map((user) => [
        // Colonne Utilisateur (Avatar + Nom)
        Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF1A56DB),
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null
                ? Text(user.name[0], style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))
                : null,
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.name, style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF0F172A))),
            Text(user.phone ?? '', style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFF64748B))),
          ]),
        ]),
        // Email
        Text(user.email, style: GoogleFonts.inter(
          fontSize: 14, color: const Color(0xFF64748B))),
        // Rôle
        StatusBadge(label: user.role, type: StatusType.role),
        // Statut
        StatusBadge(label: user.status, type: StatusType.status),
        // Ville
        Text(user.city ?? '-', style: GoogleFonts.inter(
          fontSize: 14, color: const Color(0xFF64748B))),
        // Date
        Text(user.createdAt, style: GoogleFonts.inter(
          fontSize: 13, color: const Color(0xFF94A3B8))),
        // Actions
        ActionMenu(actions: [
          ActionItem(icon: Icons.visibility_outlined, label: 'Voir le profil',
            onTap: () => context.push('/admin/utilisateurs/${user.id}')),
          if (user.status == 'En attente')
            ActionItem(icon: Icons.check_circle_outline, label: 'Valider',
              color: const Color(0xFF10B981),
              onTap: () => _validateUser(user.id)),
          if (user.status == 'Actif')
            ActionItem(icon: Icons.block_outlined, label: 'Bloquer',
              color: const Color(0xFFF59E0B),
              onTap: () => _blockUser(user.id)),
          ActionItem(icon: Icons.delete_outline, label: 'Supprimer',
            color: const Color(0xFFEF4444),
            onTap: () => _deleteUser(user.id)),
        ]),
      ]).toList(),
    );
  }

  Widget _buildPagination() => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('Affichage 1-20 sur 1 284 utilisateurs',
        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
      Row(children: [
        _PaginationButton(icon: Icons.chevron_left, onTap: () {}),
        ...List.generate(5, (i) => _PageNumber(number: i + 1, isActive: i == 0)),
        _PaginationButton(icon: Icons.chevron_right, onTap: () {}),
      ]),
    ]),
  );

  // Actions
  void _validateUser(String id) => _showConfirmDialog(
    'Valider cet utilisateur ?',
    'Le compte sera activé et l\'utilisateur pourra accéder à la plateforme.',
    'Valider', const Color(0xFF10B981), () {},
  );

  void _blockUser(String id) => _showConfirmDialog(
    'Bloquer cet utilisateur ?',
    'L\'utilisateur ne pourra plus se connecter à la plateforme.',
    'Bloquer', const Color(0xFFF59E0B), () {},
  );

  void _deleteUser(String id) => _showConfirmDialog(
    'Supprimer cet utilisateur ?',
    'Cette action est irréversible. Toutes les données seront supprimées.',
    'Supprimer', const Color(0xFFEF4444), () {},
  );

  void _showConfirmDialog(String title, String message,
      String confirmLabel, Color confirmColor, VoidCallback onConfirm) {
    showDialog(context: context, builder: (_) => ConfirmDialog(
      title: title, message: message,
      confirmLabel: confirmLabel, confirmColor: confirmColor,
      onConfirm: onConfirm,
    ));
  }

  void _showAddUserDialog() {} // Ouvre un dialog/panel de création
}
```

---

## 9. Page Gestion Offres d'Emploi

### Fonctionnalités
- Liste de toutes les offres (publiées + en attente + expirées)
- Filtres : statut, secteur, ville, entreprise, date
- Validation des offres en attente (priorité haute)
- Modification / suppression d'offres
- Mettre en avant une offre (featured)
- Export des offres

### Actions Disponibles par Offre
```dart
// Actions dans le menu contextuel de chaque offre :
// ✅ Valider (si en attente)
// ✏️ Modifier
// ⭐ Mettre en avant (featured)
// 🔒 Archiver
// 🗑️ Supprimer

// Statuts possibles :
// "Publiée"    → vert   — visible sur la plateforme
// "En attente" → orange — attend validation admin
// "Refusée"    → rouge  — refusée avec motif
// "Expirée"    → gris   — date de validité dépassée
// "En vedette" → violet — mise en avant sur la homepage
```

### Colonnes du Tableau
```dart
// Colonnes :
// Offre (titre + entreprise) | Secteur | Ville | Type | Statut | Candidatures | Date | Actions

// Filtre rapide par statut (tabs) :
// Toutes | En attente (23) | Publiées (412) | Refusées (15) | Expirées (37)
```

---

## 10. Page Gestion Entreprises

### Fonctionnalités
- Liste de toutes les entreprises inscrites
- Validation des nouvelles inscriptions entreprise
- Consultation du profil complet de chaque entreprise
- Voir les offres publiées par entreprise
- Voir les candidatures reçues par entreprise
- Activer / suspendre / supprimer un compte entreprise

### Colonnes du Tableau
```dart
// Logo | Nom entreprise | Secteur | Ville | Offres actives | Statut | Date | Actions

// Actions :
// 👁️ Voir le profil
// 💼 Voir les offres
// ✅ Valider (si en attente)
// ⛔ Suspendre
// 🗑️ Supprimer
```

---

## 11. Page Gestion Candidatures

### Fonctionnalités
- Vue globale de toutes les candidatures de la plateforme
- Filtres : statut, poste, entreprise, date, ville
- Statistiques de conversion (vues → candidatures → entretiens)
- Export des données

### Statuts Candidatures
```dart
// "Reçue"      → bleu   — candidature soumise
// "En cours"   → orange — en cours d'examen
// "Entretien"  → violet — entretien planifié
// "Acceptée"   → vert   — candidat sélectionné
// "Refusée"    → rouge  — candidature rejetée
```

### Colonnes
```dart
// Candidat | Poste | Entreprise | Date | Statut | Actions
```

---

## 12. Page Modération & Signalements

### Wireframe
```
┌─────────────────────────────────────────────────────────────────┐
│  🛡️ Modération & Signalements                                   │
│  7 signalements en attente de traitement                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                       │
│  │ 🔴  7   │  │ 🟡  12  │  │ 🟢  89  │                       │
│  │ Urgents │  │ En cours │  │ Résolus  │                       │
│  └──────────┘  └──────────┘  └──────────┘                       │
│                                                                 │
│  Type : [Tous] [Offre frauduleuse] [Contenu inapproprié]        │
│         [Compte suspect] [Spam]                                 │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ 🔴 URGENT │ Offre frauduleuse · Offre #247              │   │
│  │ Signalé par 3 utilisateurs · il y a 2h                  │   │
│  │ "Offre avec numéro de téléphone suspect..."             │   │
│  │ [Voir l'offre] [Supprimer l'offre] [Ignorer]            │   │
│  ├──────────────────────────────────────────────────────────┤   │
│  │ 🟡 MOYEN │ Compte suspect · Utilisateur #891            │   │
│  │ Signalé par 1 utilisateur · il y a 5h                   │   │
│  │ [Voir le profil] [Bloquer] [Ignorer]                    │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Code Flutter — Moderation Page

```dart
// Types de signalements
enum ReportType {
  fraudJob('Offre frauduleuse'),
  inappropriateContent('Contenu inapproprié'),
  suspiciousAccount('Compte suspect'),
  spam('Spam'),
  other('Autre');

  final String label;
  const ReportType(this.label);
}

// Priorités
enum ReportPriority { urgent, medium, low }

// Card de signalement
class ReportCard extends StatelessWidget {
  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(
          color: _priorityColor(report.priority), width: 4)),
        boxShadow: const [BoxShadow(
          color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // En-tête
          Row(children: [
            _PriorityBadge(priority: report.priority),
            const SizedBox(width: 8),
            Text(report.type.label, style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
            const Spacer(),
            Text(report.timeAgo, style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFF94A3B8))),
          ]),
          const SizedBox(height: 8),
          Text('Signalé par ${report.reportCount} utilisateur(s)',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('"${report.reason}"', style: GoogleFonts.inter(
              fontSize: 13, color: const Color(0xFF334155), fontStyle: FontStyle.italic)),
          ),
          const SizedBox(height: 12),
          // Actions
          Row(children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.visibility_outlined, size: 15),
              label: Text('Voir ${report.targetType}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A56DB),
                side: const BorderSide(color: Color(0xFF1A56DB)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_outline, size: 15),
              label: const Text('Supprimer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {},
              child: Text('Ignorer', style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF94A3B8))),
            ),
          ]),
        ]),
      ),
    );
  }

  Color _priorityColor(ReportPriority p) {
    switch (p) {
      case ReportPriority.urgent: return const Color(0xFFEF4444);
      case ReportPriority.medium: return const Color(0xFFF59E0B);
      case ReportPriority.low:    return const Color(0xFF10B981);
    }
  }
}
```

---

## 13. Page Statistiques & Analytiques

### Sections
```dart
// 1. KPIs Globaux (en haut)
//    Utilisateurs totaux | Offres publiées ce mois | Candidatures | Taux de conversion

// 2. Graphique Croissance Utilisateurs (courbes)
//    X: 12 derniers mois | Y: nombre d'inscriptions
//    2 courbes : Candidats (bleu) + Recruteurs (vert)

// 3. Graphique Offres par Secteur (barres horizontales)
//    Technologie | Finance | Santé | Commerce | ...

// 4. Graphique Répartition Géographique (barres verticales)
//    Conakry | Kindia | Boké | Labé | Mamou | Kankan | ...

// 5. Statistiques IA (matching)
//    Score moyen de matching | CV analysés | Recommandations envoyées

// 6. Tableau Top Entreprises Recruteurs
//    Classement par nombre d'offres et candidatures reçues

// 7. Période de sélection (filtre)
//    [7 jours] [30 jours] [3 mois] [6 mois] [1 an] [Personnalisé]
```

### Graphiques Flutter
```dart
// Utiliser le package fl_chart pour les graphiques
// Ajouter dans pubspec.yaml : fl_chart: ^0.68.0

// Graphique courbes (LineChart fl_chart)
// Graphique barres (BarChart fl_chart)
// Graphique camembert (PieChart fl_chart) pour les secteurs

// Style des graphiques :
// Fond blanc, grille grise légère (#F1F5F9)
// Courbes lisses (isCurved: true)
// Points avec cercles blancs bordés de couleur
// Tooltip élégant avec fond blanc et ombre
// Animations d'entrée des graphiques
```

---

## 14. Page Paramètres Plateforme

### Sections de Paramètres

```dart
// SECTION 1 : Informations Générales
// - Nom de la plateforme
// - Description courte
// - Email de contact
// - Téléphone
// - Adresse (Conakry, Guinée)
// - Logo et favicon (upload)

// SECTION 2 : Gestion des Comptes
// - Activer/désactiver l'inscription libre
// - Validation automatique ou manuelle des nouveaux comptes
// - Nombre max d'offres par recruteur (gratuit)
// - Durée de validité des offres (jours)
// - Politique de suppression des comptes inactifs

// SECTION 3 : Notifications Email
// - Template email de bienvenue (on/off)
// - Notification nouvelles candidatures (on/off)
// - Résumé hebdomadaire (on/off)
// - Email de validation de compte (on/off)
// - Signature email

// SECTION 4 : IA & Matching
// - Seuil minimum score matching (slider 0-100%)
// - Activer/désactiver les suggestions automatiques
// - Fréquence de mise à jour des recommandations
// - Modèle NLP utilisé (affichage)

// SECTION 5 : Maintenance
// - Mode maintenance (on/off avec message personnalisé)
// - Cache (vider le cache)
// - Logs d'erreurs (voir les 50 dernières erreurs)
// - Sauvegarde de la base de données

// SECTION 6 : Sécurité
// - Durée de session (minutes)
// - Nombre max de tentatives de connexion
// - Activer 2FA pour les admins
// - IPs bloquées
```

### Layout Paramètres
```dart
// Sidebar de navigation (sections) + Contenu à droite
// Chaque section dans une Card blanche
// Bouton "Sauvegarder" sticky en bas de page
// Indicateur de changements non sauvegardés

class SettingsPage extends StatefulWidget {
  // Sections navigables via une mini-sidebar gauche :
  // [ ] Général
  // [ ] Comptes
  // [ ] Notifications
  // [ ] IA & Matching
  // [ ] Maintenance
  // [ ] Sécurité

  // Toggle switch pour les options on/off :
  // Switch(
  //   value: _setting,
  //   onChanged: (v) => setState(() => _setting = v),
  //   activeColor: Color(0xFF1A56DB),
  // )

  // Slider pour les valeurs numériques :
  // SliderTheme(
  //   data: SliderTheme.of(context).copyWith(
  //     activeTrackColor: Color(0xFF1A56DB),
  //     thumbColor: Color(0xFF1A56DB),
  //   ),
  //   child: Slider(value: _threshold, min: 0, max: 100, onChanged: ...)
  // )
}
```

---

## 15. Page Notifications & Messages

### Fonctionnalités
```dart
// 1. Composer et envoyer des notifications push aux utilisateurs
//    - À tous les utilisateurs
//    - Aux candidats uniquement
//    - Aux recruteurs uniquement
//    - À un utilisateur spécifique

// 2. Historique des notifications envoyées
//    - Titre | Destinataires | Date | Statut (envoyé/échec)

// 3. Templates de notifications prédéfinis
//    - "Nouvelle offre dans votre secteur"
//    - "Votre CV a été consulté"
//    - "Rappel de compléter votre profil"
//    - "Maintenance planifiée"

// 4. Notifications système (reçues par l'admin)
//    - Nouveaux signalements
//    - Nouveaux comptes en attente
//    - Erreurs système
```

### Widget de Composition
```dart
// Formulaire d'envoi de notification :
// - Titre (TextField)
// - Message (TextArea, max 500 chars, compteur)
// - Destinataires (DropdownMultiSelect ou SegmentedButton)
// - Planifier pour plus tard (DateTimePicker) — optionnel
// - [Envoyer maintenant] ou [Planifier]

// Aperçu de la notification (preview card mobile)
```

---

## 16. Composants Partagés Admin

### `AdminDataTable`
```dart
// Table de données réutilisable pour toutes les pages
// Colonnes configurables
// Tri par colonne (asc/desc)
// Sélection multiple (checkbox)
// Actions bulk (supprimer sélectionnés, exporter sélectionnés)
// Ligne alternée : blanc / #F8FAFC
// Hover : fond #EFF6FF (bleu très clair)
// Hauteur ligne : 56px
// Texte header : Inter 12px w600 #64748B uppercase
```

### `StatusBadge`
```dart
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType type;

  // Styles selon le statut :
  // "Actif" / "Publié" / "Accepté" / "Validé"
  //   → bg: #D1FAE5, text: #065F46, label: label

  // "En attente" / "En cours"
  //   → bg: #FEF3C7, text: #92400E

  // "Bloqué" / "Refusé" / "Suspendu"
  //   → bg: #FEE2E2, text: #991B1B

  // "Brouillon" / "Expiré" / "Archivé"
  //   → bg: #F1F5F9, text: #475569

  // "Candidat"
  //   → bg: #EFF6FF, text: #1E40AF

  // "Recruteur"
  //   → bg: #F5F3FF, text: #5B21B6

  // "Admin"
  //   → bg: #0F172A, text: #FFFFFF

  // "⭐ En vedette"
  //   → bg: #FEF3C7, text: #92400E
}
```

### `ActionMenu`
```dart
// Menu contextuel (3 points ⋮) avec liste d'actions
// Apparaît dans un PopupMenuButton
// Chaque action : icône + label + couleur optionnelle
// Séparateur possible entre groupes d'actions
// Animation d'ouverture : scale depuis le bouton

class ActionMenu extends StatelessWidget {
  final List<ActionItem> actions;

  // Rendu : IconButton(Icons.more_vert_outlined)
  // PopupMenu avec shadow élégant
  // Items colorés selon la criticité de l'action
}
```

### `AdminSearchBar`
```dart
// Barre de recherche pour les tableaux
// Icône loupe à gauche
// Bouton ✕ pour effacer
// Debounce 300ms avant de lancer la recherche
// onChanged callback
```

### `ConfirmDialog`
```dart
// Dialog de confirmation pour les actions destructives
// - Titre
// - Message explicatif
// - Bouton Annuler (gris)
// - Bouton Confirmer (couleur selon criticité)
// Animation : scale + fade au centre de l'écran
// Forme arrondie, padding généreux
```

### `AdminEmptyState`
```dart
// État vide pour les listes
// Illustration (icône grande colorée dans cercle)
// Titre
// Sous-titre
// Bouton d'action optionnel (ex: "Ajouter un utilisateur")

class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;
}
```

---

## 17. Routing Admin Complet

```dart
// lib/app/router.dart — AJOUTER ces routes

// ShellRoute pour le layout admin (sidebar + topbar persistants)
ShellRoute(
  builder: (context, state, child) => AdminShell(child: child),
  routes: [
    GoRoute(
      path: '/admin',
      redirect: (ctx, state) {
        // Vérifier que l'utilisateur est admin
        // if (!authService.isAdmin) return '/connexion';
        return null;
      },
      builder: (ctx, state) => const AdminDashboardPage(),
    ),
    GoRoute(
      path: '/admin/utilisateurs',
      builder: (ctx, state) => const UsersPage(),
    ),
    GoRoute(
      path: '/admin/utilisateurs/:id',
      builder: (ctx, state) => UserDetailPage(
        userId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/admin/offres',
      builder: (ctx, state) => const JobsPage(),
    ),
    GoRoute(
      path: '/admin/offres/:id',
      builder: (ctx, state) => JobAdminDetailPage(
        jobId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/admin/entreprises',
      builder: (ctx, state) => const CompaniesPage(),
    ),
    GoRoute(
      path: '/admin/entreprises/:id',
      builder: (ctx, state) => CompanyDetailPage(
        companyId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/admin/candidatures',
      builder: (ctx, state) => const ApplicationsPage(),
    ),
    GoRoute(
      path: '/admin/moderation',
      builder: (ctx, state) => const ModerationPage(),
    ),
    GoRoute(
      path: '/admin/statistiques',
      builder: (ctx, state) => const StatisticsPage(),
    ),
    GoRoute(
      path: '/admin/parametres',
      builder: (ctx, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/admin/notifications',
      builder: (ctx, state) => const NotificationsPage(),
    ),
  ],
),
```

---

## 18. Animations & Micro-interactions

```dart
// ── SIDEBAR ──────────────────────────────────────────────────
// Item actif : AnimatedContainer 150ms (fond + couleur texte)
// Collapse sidebar : AnimatedContainer 250ms (largeur 240→64)
// Hover items : couleur fond 150ms

// ── STAT CARDS ───────────────────────────────────────────────
// Entrée : FadeInUp stagger 80ms entre chaque card
// Hover : translateY(-4px) + ombre augmentée 200ms
// Valeurs : compteur animé (TweenAnimationBuilder 0 → valeur finale)

// ── TABLEAUX ─────────────────────────────────────────────────
// Apparition : FadeIn 400ms
// Hover ligne : fond #EFF6FF 150ms
// Sort click : rotation icône flèche 200ms

// ── DIALOGS ──────────────────────────────────────────────────
// Ouverture : scale 0.95→1.0 + opacity 0→1, 250ms
// Fermeture : scale 1.0→0.95 + opacity 1→0, 200ms

// ── NOTIFICATIONS BADGE ──────────────────────────────────────
// Pulse animation si signalements urgents
// Scale 1.0→1.15→1.0 en loop 2s

// ── GRAPHIQUES ───────────────────────────────────────────────
// Entrée : animation de dessin des courbes (fl_chart built-in)
// Durée : 800ms, Curves.easeOut

// ── TRANSITIONS ENTRE PAGES ADMIN ────────────────────────────
// FadeTransition 250ms (plus rapide que les pages auth)
// Pas de slide (tableau de bord = navigation instantanée)

// ── TOASTS / SNACKBARS ───────────────────────────────────────
// Succès vert : après validation, suppression, sauvegarde
// Erreur rouge : en cas d'échec API
// Info bleu : informations non critiques
// Position : bottom-right du contenu (pas du bas de l'écran)
```

---

## 19. Responsive Admin

```dart
// ── BREAKPOINTS ──────────────────────────────────────────────
// Large desktop : >= 1400px → sidebar 240px + contenu large
// Desktop       : 1024-1399px → sidebar 240px + contenu normal
// Tablet        : 768-1023px → sidebar collapse (64px) ou drawer
// Mobile        : < 768px → drawer uniquement + layout simplifié

// ── COMPORTEMENT SIDEBAR ─────────────────────────────────────
// Desktop (>=1024) : sidebar fixe à gauche (240px)
// Tablet (768-1023): sidebar collapsed (64px, icônes uniquement)
// Mobile (<768)    : Drawer Flutter (swipe depuis gauche)

// ── GRILLES STAT CARDS ───────────────────────────────────────
// Desktop : 3 colonnes
// Tablet  : 2 colonnes
// Mobile  : 1 colonne (scroll vertical)

// ── TABLEAUX ─────────────────────────────────────────────────
// Desktop : toutes les colonnes visibles
// Tablet  : masquer colonnes secondaires (téléphone, date inscription)
// Mobile  : SingleChildScrollView horizontal + colonnes essentielles

// ── GRAPHIQUES ───────────────────────────────────────────────
// Desktop : graphique + activité récente côte à côte (60/40)
// Mobile  : empilés verticalement

// ── TOPBAR ───────────────────────────────────────────────────
// Desktop : SearchBar visible
// Mobile  : SearchBar masquée (icône loupe à la place)
```

---

## 20. Critères d'Acceptation

### ✅ AdminShell (Layout)
- [ ] Sidebar fixe gauche (240px) avec logo EmploiConnect
- [ ] Item actif visuellement distinct (fond bleu + texte blanc)
- [ ] Badges de notification sur Utilisateurs, Offres, Modération
- [ ] Profil admin en bas de sidebar avec bouton déconnexion
- [ ] Collapse sidebar sur tablette (64px, icônes seules)
- [ ] Drawer sur mobile
- [ ] TopBar avec titre de page dynamique
- [ ] Barre de recherche globale dans le TopBar
- [ ] Transitions fluides entre pages (fade 250ms)
- [ ] Route `/admin` protégée (redirection si non admin)

### ✅ Dashboard Home
- [ ] Message de bienvenue avec date du jour
- [ ] 6 stat cards avec icônes, valeurs, badges de tendance
- [ ] Hover effect sur les stat cards
- [ ] Graphique d'activité (7 derniers jours)
- [ ] Feed activité récente (temps réel ou mock)
- [ ] Section offres en attente avec actions rapides (✓/✗)
- [ ] Animations FadeInUp staggerées sur les cards

### ✅ Gestion Utilisateurs
- [ ] Tableau avec 7 colonnes + menu actions
- [ ] Tabs : Tous / Candidats / Recruteurs / En attente / Bloqués
- [ ] Barre de filtres (recherche + rôle + statut)
- [ ] Actions : voir, valider, bloquer, supprimer
- [ ] Dialog de confirmation pour les actions destructives
- [ ] Pagination (20 par page)
- [ ] Export CSV/Excel

### ✅ Gestion Offres
- [ ] Tableau avec statut, candidatures, actions
- [ ] Tabs : Toutes / En attente / Publiées / Refusées / Expirées
- [ ] Validation rapide depuis le tableau
- [ ] Option "Mettre en vedette"

### ✅ Modération
- [ ] Cards de signalements avec bordure colorée (priorité)
- [ ] Filtres par type de signalement
- [ ] Actions : voir, supprimer, ignorer
- [ ] Compteurs Urgents / En cours / Résolus

### ✅ Statistiques
- [ ] Graphique courbes (inscriptions 12 mois)
- [ ] Graphique barres (offres par secteur)
- [ ] Graphique barres (répartition villes guinéennes)
- [ ] Filtre période (7j / 30j / 3m / 6m / 1an)
- [ ] Animations graphiques à l'entrée

### ✅ Paramètres
- [ ] 6 sections navigables
- [ ] Toggles fonctionnels
- [ ] Sliders pour valeurs numériques
- [ ] Bouton sauvegarder sticky
- [ ] Feedback toast après sauvegarde

### ✅ Global Admin
- [ ] Design cohérent avec homepage (mêmes couleurs, fonts)
- [ ] Sidebar sombre (#0F172A) contrastée avec contenu clair (#F8FAFC)
- [ ] StatusBadge cohérents sur toutes les pages
- [ ] ConfirmDialog systématique pour actions destructives
- [ ] Snackbars succès/erreur sur toutes les actions
- [ ] Aucune erreur console Flutter
- [ ] Test responsive : 375px / 768px / 1024px / 1280px / 1440px

---

*PRD EmploiConnect v2.0 — Tableau de Bord Administrateur — Flutter*
*Projet académique — Licence Professionnelle Génie Logiciel — Guinée 2025-2026*
*BARRY YOUSSOUF (22 000 46) · DIALLO ISMAILA (23 008 60)*
*Encadré par M. DIALLO BOUBACAR — CEO Rasenty*
*Cursor / Kirsoft AI — Phase 3 — Suite Auth validée*
