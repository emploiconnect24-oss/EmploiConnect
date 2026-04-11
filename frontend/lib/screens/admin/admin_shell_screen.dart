import 'package:flutter/material.dart';
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
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_topbar.dart';

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _sidebarCollapsed = false;
  String _currentRoute = _routeDashboard;

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
  };

  @override
  void initState() {
    super.initState();
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

  Widget get _activePage {
    switch (_currentRoute) {
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
      default:
        return const AdminDashboardScreen();
    }
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
            child: Column(
              children: [
                AdminTopBar(
                  title: _titles[_currentRoute] ?? 'Administration',
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
                      child: _activePage,
                    ),
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


