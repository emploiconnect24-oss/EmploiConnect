import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/recruteur_provider.dart';
import '../entreprise/entreprise_profile_screen.dart';
import '../entreprise/entreprise_settings_screen.dart';
import '../entreprise/mes_offres_screen.dart';
import '../entreprise/offre_form_screen.dart';
import '../login_screen.dart';
import 'pages/candidatures_page.dart';
import 'recruteur_dashboard_connected_screen.dart';
import 'recruteur_messagerie_connected_screen.dart';
import 'recruteur_notifications_connected_screen.dart';
import 'recruteur_statistics_connected_screen.dart';
import 'recruteur_talents_connected_screen.dart';
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
  String? _candidaturesOffreId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final token = context.read<AuthProvider>().token ?? '';
      if (token.isEmpty) return;
      await context.read<RecruteurProvider>().loadAll(token);
    });
  }

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
        return RecruteurDashboardConnectedScreen(
          onShellNavigate: (route) {
            if (!mounted) return;
            setState(() => _currentRoute = route);
          },
        );
      case '/dashboard-recruteur/offres':
        return MesOffresScreen(
          onOpenCandidaturesForOffre: (offreId) {
            if (!mounted) return;
            setState(() {
              _candidaturesOffreId = offreId;
              _currentRoute = '/dashboard-recruteur/candidatures';
            });
          },
        );
      case '/dashboard-recruteur/offres/nouvelle':
        return const OffreFormScreen();
      case '/dashboard-recruteur/candidatures':
        return CandidaturesPage(
          key: ValueKey<String>(_candidaturesOffreId ?? 'all'),
          offreId: _candidaturesOffreId,
          onShellNavigate: (route) {
            if (!mounted) return;
            setState(() => _currentRoute = route);
          },
        );
      case '/dashboard-recruteur/profil':
        return const EntrepriseProfileScreen();
      case '/dashboard-recruteur/statistiques':
        return const RecruteurStatisticsConnectedScreen();
      case '/dashboard-recruteur/notifications':
        return const RecruteurNotificationsConnectedScreen();
      case '/dashboard-recruteur/parametres':
        return EntrepriseSettingsScreen(
          onOpenEntrepriseProfile: () {
            if (!mounted) return;
            setState(() => _currentRoute = '/dashboard-recruteur/profil');
          },
        );
      case '/dashboard-recruteur/talents':
        return const RecruteurTalentsConnectedScreen();
      case '/dashboard-recruteur/messages':
        return RecruteurMessagerieConnectedScreen(
          onShellNavigate: (route) {
            if (!mounted) return;
            setState(() => _currentRoute = route);
          },
        );
      default:
        return MesOffresScreen(
          onOpenCandidaturesForOffre: (offreId) {
            if (!mounted) return;
            setState(() {
              _candidaturesOffreId = offreId;
              _currentRoute = '/dashboard-recruteur/candidatures';
            });
          },
        );
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
                    setState(() {
                      _currentRoute = route;
                      if (route == '/dashboard-recruteur/candidatures') {
                        _candidaturesOffreId = null;
                      }
                    });
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
              onRouteSelected: (route) {
                setState(() {
                  _currentRoute = route;
                  if (route == '/dashboard-recruteur/candidatures') {
                    _candidaturesOffreId = null;
                  }
                });
              },
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
                  onOpenProfil: () => setState(() => _currentRoute = '/dashboard-recruteur/profil'),
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
