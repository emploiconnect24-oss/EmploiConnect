import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../entreprise/entreprise_profile_screen.dart';
import '../entreprise/entreprise_settings_screen.dart';
import '../entreprise/mes_offres_screen.dart';
import '../entreprise/offre_form_screen.dart';
import '../login_screen.dart';
import 'recruteur_dashboard_screen.dart';
import 'recruteur_candidatures_screen.dart';
import 'recruteur_messagerie_screen.dart';
import 'recruteur_notifications_screen.dart';
import 'recruteur_statistics_screen.dart';
import 'recruteur_talents_screen.dart';
import 'widgets/recruteur_sidebar.dart';
import 'widgets/recruteur_topbar.dart';

class RecruteurShellScreen extends StatefulWidget {
  const RecruteurShellScreen({super.key});

  @override
  State<RecruteurShellScreen> createState() => _RecruteurShellScreenState();
}

class _RecruteurShellScreenState extends State<RecruteurShellScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _currentRoute = '/dashboard-recruteur';

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget get _activePage {
    switch (_currentRoute) {
      case '/dashboard-recruteur':
        return const RecruteurDashboardScreen();
      case '/dashboard-recruteur/offres':
        return const MesOffresScreen();
      case '/dashboard-recruteur/offres/nouvelle':
        return const OffreFormScreen();
      case '/dashboard-recruteur/candidatures':
        return const RecruteurCandidaturesScreen();
      case '/dashboard-recruteur/profil':
        return const EntrepriseProfileScreen();
      case '/dashboard-recruteur/statistiques':
        return const RecruteurStatisticsScreen();
      case '/dashboard-recruteur/notifications':
        return const RecruteurNotificationsScreen();
      case '/dashboard-recruteur/parametres':
        return const EntrepriseSettingsScreen();
      case '/dashboard-recruteur/talents':
        return const RecruteurTalentsScreen();
      case '/dashboard-recruteur/messages':
        return const RecruteurMessagerieScreen();
      default:
        return const MesOffresScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1024;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: isMobile
          ? Drawer(
              width: 280,
              child: SafeArea(
                child: RecruteurSidebar(
                  isDrawer: true,
                  currentRoute: _currentRoute,
                  onRouteSelected: (route) {
                    setState(() => _currentRoute = route);
                    Navigator.of(context).pop();
                  },
                  onLogout: _logout,
                ),
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            RecruteurSidebar(
              currentRoute: _currentRoute,
              onRouteSelected: (route) => setState(() => _currentRoute = route),
              onLogout: _logout,
            ),
          Expanded(
            child: Column(
              children: [
                RecruteurTopBar(
                  currentRoute: _currentRoute,
                  onMenuPressed: isMobile ? () => _scaffoldKey.currentState?.openDrawer() : null,
                  onQuickOffer: () => setState(() => _currentRoute = '/dashboard-recruteur/offres/nouvelle'),
                  onNotifications: () => setState(() => _currentRoute = '/dashboard-recruteur/notifications'),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                      child: child,
                    ),
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
