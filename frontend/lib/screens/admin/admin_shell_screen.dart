import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_jobs_screen.dart';
import 'admin_companies_screen.dart';
import 'admin_signalements_screen.dart';
import 'admin_temoignages_screen.dart';
import 'admin_users_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_applications_screen.dart';
import 'admin_statistics_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_ressources_parcours_screen.dart';
import 'admin_profil_screen.dart';
import 'pages/admin_recherche_globale_page.dart';
import 'pages/apropos_admin_page.dart';
import 'pages/newsletter_admin_page.dart';
import 'pages/sous_admins_page.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_topbar.dart';

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key, this.initialRoute});

  /// Ouverture directe (ex. GoRouter `/admin/acces`).
  final String? initialRoute;

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  AdminProvider? _adminProviderRef;

  static const String _routeDashboard = '/admin';
  static const String _routeUsers = '/admin/utilisateurs';
  static const String _routeOffers = '/admin/offres';
  static const String _routeCompanies = '/admin/entreprises';
  static const String _routeApplications = '/admin/candidatures';
  static const String _routeModeration = '/admin/moderation';
  static const String _routeTemoignages = '/admin/temoignages';
  static const String _routeStats = '/admin/statistiques';
  static const String _routeNotifications = '/admin/notifications';
  static const String _routeSettings = '/admin/parametres';
  static const String _routeProfil = '/admin/profil';
  static const String _routeRecherche = '/admin/recherche';
  static const String _routeParcoursCarriere = '/admin/parcours-carriere';
  static const String _routeApropos = '/admin/apropos';
  static const String _routeNewsletter = '/admin/newsletter';
  static const String _routeAcces = '/admin/acces';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _sidebarCollapsed = false;
  late String _currentRoute;

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  static const Map<String, String> _titles = {
    _routeDashboard: 'Vue d\'ensemble',
    _routeUsers: 'Gestion des utilisateurs',
    _routeOffers: 'Gestion des offres d\'emploi',
    _routeCompanies: 'Gestion des entreprises',
    _routeApplications: 'Gestion des candidatures',
    _routeModeration: 'Modération & signalements',
    _routeTemoignages: 'Témoignages recrutement',
    _routeStats: 'Statistiques & analytiques',
    _routeNotifications: 'Notifications',
    _routeSettings: 'Paramètres plateforme',
    _routeRecherche: 'Recherche globale',
    _routeParcoursCarriere: 'Parcours Carrière (ressources)',
    _routeApropos: 'Page À propos',
    _routeNewsletter: 'Newsletter',
    _routeAcces: 'Gestion des accès',
  };

  @override
  void initState() {
    super.initState();
    final init = widget.initialRoute?.trim();
    _currentRoute = (init != null && init.isNotEmpty && _titles.containsKey(init))
        ? init
        : _routeDashboard;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final admin = context.read<AdminProvider>();
      _adminProviderRef = admin;
      admin.loadDashboard();
      admin.startAutoRefresh();
    });
  }

  @override
  void dispose() {
    _adminProviderRef?.stopAutoRefresh();
    super.dispose();
  }

  void _retourDashboard() {
    setState(() => _currentRoute = _routeDashboard);
  }

  /// Clé permission backend (`mes-permissions`), alignée sur [AdminProvider.peutVoirSection].
  static String? _sectionKeyPourRoute(String route) {
    switch (route) {
      case _routeDashboard:
        return 'dashboard';
      case _routeUsers:
        return 'utilisateurs';
      case _routeOffers:
        return 'offres';
      case _routeCompanies:
        return 'entreprises';
      case _routeApplications:
        return 'candidatures';
      case _routeModeration:
        return 'signalements';
      case _routeTemoignages:
        return 'temoignages';
      case _routeStats:
        return 'statistiques';
      case _routeNotifications:
        return 'messages';
      case _routeRecherche:
        return 'recherche';
      case _routeParcoursCarriere:
        return 'parcours';
      case _routeApropos:
        return 'apropos';
      case _routeNewsletter:
        return 'newsletter';
      default:
        return null;
    }
  }

  static const Map<String, String> _libelleSection = {
    'dashboard': 'Tableau de bord',
    'utilisateurs': 'Utilisateurs',
    'offres': 'Offres d\'emploi',
    'entreprises': 'Entreprises',
    'candidatures': 'Candidatures',
    'signalements': 'Modération & signalements',
    'temoignages': 'Témoignages',
    'statistiques': 'Statistiques',
    'messages': 'Notifications',
    'recherche': 'Recherche globale',
    'parcours': 'Parcours carrière',
    'apropos': 'Page À propos',
    'newsletter': 'Newsletter',
  };

  static const List<String> _routesSuperAdminSeulement = [
    _routeSettings,
    _routeAcces,
  ];

  /// N’appeler que lorsque [AdminProvider.adminAccessLoaded] est true
  /// (sauf profil / dashboard gérés dans [_buildRoutedPage]).
  static bool _routeAutorisee(AdminProvider admin, String route) {
    if (route == _routeProfil) return true;
    if (_routesSuperAdminSeulement.contains(route)) {
      return admin.adminEstSuper;
    }
    final key = _sectionKeyPourRoute(route);
    if (key == null) return true;
    return admin.peutVoirSection(key);
  }

  static String _libelleRefus(String route) {
    if (route == _routeSettings) return 'Paramètres plateforme';
    if (route == _routeAcces) return 'Gestion des accès';
    final key = _sectionKeyPourRoute(route);
    if (key != null) return _libelleSection[key] ?? key;
    return '';
  }

  Widget _pageSansGarde(String route) {
    switch (route) {
      case _routeDashboard:
        return const AdminDashboardScreen();
      case _routeUsers:
        return const AdminUsersScreen();
      case _routeModeration:
        return const AdminSignalementsScreen();
      case _routeTemoignages:
        return const AdminTemoignagesScreen();
      case _routeSettings:
        return const AdminSettingsScreen();
      case _routeOffers:
        return const AdminJobsScreen();
      case _routeCompanies:
        return const AdminCompaniesScreen();
      case _routeApplications:
        return const AdminApplicationsScreen();
      case _routeStats:
        return const AdminStatisticsScreen();
      case _routeNotifications:
        return const AdminNotificationsScreen();
      case _routeProfil:
        return const AdminProfilScreen();
      case _routeRecherche:
        return const AdminRechercheGlobalePage();
      case _routeParcoursCarriere:
        return const AdminRessourcesParcoursScreen();
      case _routeApropos:
        return const AproposAdminPage();
      case _routeNewsletter:
        return const NewsletterAdminPage();
      case _routeAcces:
        return const SousAdminsPage();
      default:
        return const AdminDashboardScreen();
    }
  }

  Widget _buildRoutedPage(AdminProvider admin) {
    final route = _currentRoute;
    final loaded = admin.adminAccessLoaded;

    // Évite d’injecter Paramètres / offres / etc. avant les droits → moins d’erreurs API et pas de « refus »
    // flash pour super admin.
    if (!loaded && route != _routeProfil && route != _routeDashboard) {
      return const _AdminAccessLoading();
    }

    if (loaded && !_routeAutorisee(admin, route)) {
      return AccesRefuseWidget(
        section: _libelleRefus(route),
        onRetourDashboard: _retourDashboard,
      );
    }

    return _pageSansGarde(route);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;
    final isTablet = width >= 900 && width < 1200;
    final useCollapsedSidebar = isTablet || _sidebarCollapsed;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: isMobile
          ? Drawer(
              width: 280,
              child: SafeArea(
                child: AdminSidebar(
                  isDrawer: true,
                  currentRoute: _currentRoute,
                  onRouteSelected: (route) {
                    setState(() => _currentRoute = route);
                    Navigator.of(context).pop();
                  },
                  onLogout: () async {
                    Navigator.of(context).pop();
                    await _logout();
                  },
                ),
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            AdminSidebar(
              collapsed: useCollapsedSidebar,
              currentRoute: _currentRoute,
              onRouteSelected: (route) => setState(() => _currentRoute = route),
              onLogout: _logout,
            ),
          Expanded(
            child: Consumer<AdminProvider>(
              builder: (context, admin, _) {
                final route = _currentRoute;
                final loaded = admin.adminAccessLoaded;
                final loading =
                    !loaded && route != _routeProfil && route != _routeDashboard;
                final refuse = loaded && !_routeAutorisee(admin, route);
                return Column(
                  children: [
                    AdminTopBar(
                      title: refuse
                          ? 'Accès non autorisé'
                          : loading
                              ? 'Chargement…'
                              : (_titles[route] ?? 'Administration'),
                      onMenuPressed: () {
                        if (isMobile) {
                          _scaffoldKey.currentState?.openDrawer();
                          return;
                        }
                        setState(() => _sidebarCollapsed = !_sidebarCollapsed);
                      },
                      isMobile: isMobile,
                      onLogout: _logout,
                      onOpenProfile: () => setState(() => _currentRoute = _routeProfil),
                      onOpenNotifications: () => setState(() => _currentRoute = _routeNotifications),
                      onOpenFullSearch: () => setState(() => _currentRoute = _routeRecherche),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: KeyedSubtree(
                          key: ValueKey<String>(_currentRoute),
                          child: _buildRoutedPage(admin),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminAccessLoading extends StatelessWidget {
  const _AdminAccessLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF1A56DB)),
    );
  }
}

/// Page affichée lorsqu’un sous-admin ouvre une section non autorisée.
class AccesRefuseWidget extends StatelessWidget {
  const AccesRefuseWidget({
    super.key,
    this.section = '',
    required this.onRetourDashboard,
  });

  final String section;
  final VoidCallback onRetourDashboard;

  void _retourDashboard(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go('/admin');
    } else {
      onRetourDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Color(0xFFEF4444),
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Accès non autorisé',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      section.isNotEmpty
                          ? 'Vous n\'avez pas les droits pour accéder à\n« $section ».'
                          : 'Vous n\'avez pas les droits pour accéder à cette section.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF991B1B),
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Contactez le Super Administrateur\npour obtenir les accès nécessaires.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Text(
                        'Retour au Dashboard',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A56DB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _retourDashboard(context),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Consumer<AdminProvider>(
                    builder: (ctx, provider, _) {
                      final role = provider.roleNom ?? '';
                      if (role.isEmpty) return const SizedBox.shrink();
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            size: 12,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Votre rôle : $role',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
