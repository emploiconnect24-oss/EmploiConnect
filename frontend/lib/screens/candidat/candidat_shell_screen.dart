import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/candidat_provider.dart';
import '../login_screen.dart';
import 'candidat_applications_screen.dart';
import 'candidat_dashboard_screen.dart';
import 'candidat_job_search_screen.dart';
import 'candidat_job_alerts_screen.dart';
import 'candidat_messaging_screen.dart';
import 'candidat_notifications_screen.dart';
import 'candidat_profile_cv_screen.dart';
import 'candidat_recommendations_screen.dart';
import 'candidat_saved_offers_screen.dart';
import 'candidat_settings_screen.dart';
import 'candidat_temoignage_screen.dart';
import 'candidat_tips_resources_screen.dart';
import 'pages/createur_cv_page.dart';
import 'pages/ia_demo_page.dart';
import 'widgets/candidat_sidebar.dart';
import 'widgets/candidat_topbar.dart';

class CandidatShellScreen extends StatefulWidget {
  const CandidatShellScreen({super.key, this.initialRoute});

  final String? initialRoute;

  @override
  State<CandidatShellScreen> createState() => _CandidatShellScreenState();
}

class _CandidatShellScreenState extends State<CandidatShellScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _currentRoute = '/dashboard';
  /// Incrémenté quand la recherche est lancée depuis la topbar (recrée l’écran offres avec le mot-clé).
  int _offresSearchKey = 0;
  String? _offresInitialKeyword;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRoute;
    if (initial != null && initial.startsWith('/dashboard')) {
      _currentRoute = initial;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<CandidatProvider>().loadDashboardMetrics();
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
      case '/dashboard':
        return CandidatDashboardScreen(
          onGoOffres: () => setState(() => _currentRoute = '/dashboard/offres'),
          onGoProfil: () => setState(() => _currentRoute = '/dashboard/profil'),
          onGoRecommandations: () => setState(() => _currentRoute = '/dashboard/recommandations'),
          onGoCandidatures: () => setState(() => _currentRoute = '/dashboard/candidatures'),
          onGoAlertes: () => setState(() => _currentRoute = '/dashboard/alertes'),
        );
      case '/dashboard/offres':
        return CandidatJobSearchScreen(
          key: ValueKey<String>('offres_$_offresSearchKey'),
          initialKeyword: _offresInitialKeyword,
        );
      case '/dashboard/recommandations':
        return CandidatRecommendationsScreen(
          onGoProfil: () => setState(() => _currentRoute = '/dashboard/profil'),
        );
      case '/dashboard/ia-demo':
        return IADemoPage(
          onOpenRecommandations: () =>
              setState(() => _currentRoute = '/dashboard/recommandations'),
        );
      case '/dashboard/candidatures':
        return CandidatApplicationsScreen(
          onOpenMessages: () => setState(() => _currentRoute = '/dashboard/messages'),
        );
      case '/dashboard/profil':
        return const CandidatProfileCvScreen();
      case '/dashboard/cv/creer':
        return CreateurCvPage(
          onClose: () => setState(() => _currentRoute = '/dashboard/profil'),
          onDone: () async {
            await context.read<CandidatProvider>().loadDashboardMetrics();
            if (!mounted) return;
            setState(() => _currentRoute = '/dashboard/profil');
          },
        );
      case '/dashboard/sauvegardes':
        return const CandidatSavedOffersScreen();
      case '/dashboard/messages':
        final prefill = context.read<CandidatProvider>().messageriePrefill;
        return CandidatMessagingScreen(
          initialPeerId: prefill?['peerId'],
          initialPeerName: prefill?['nom'],
          initialPeerPhotoUrl: prefill?['photoUrl'],
        );
      case '/dashboard/conseils':
        return const CandidatTipsResourcesScreen();
      case '/dashboard/parcours':
        return const CandidatTipsResourcesScreen();
      case '/dashboard/alertes':
        return const CandidatJobAlertsScreen();
      case '/dashboard/notifications':
        return const CandidatNotificationsScreen();
      case '/dashboard/parametres':
        return const CandidatSettingsScreen();
      case '/dashboard/temoignage':
        return const CandidatTemoignageScreen();
      default:
        return _CandidatPlaceholder(title: 'Espace Candidat');
    }
  }

  @override
  Widget build(BuildContext context) {
    // PRD ÉTAPE 2 : layout desktop si largeur > 900
    final isMobile = MediaQuery.of(context).size.width <= 900;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: isMobile
          ? Drawer(
              width: 270,
              child: CandidatSidebar(
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
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            CandidatSidebar(
              currentRoute: _currentRoute,
              onRouteSelected: (route) => setState(() => _currentRoute = route),
              onLogout: _logout,
            ),
          if (!isMobile)
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFFE2E8F0),
            ),
          Expanded(
            child: Column(
              children: [
                CandidatTopBar(
                  currentRoute: _currentRoute,
                  isMobile: isMobile,
                  unreadNotifications: context.watch<CandidatProvider>().badge('notifications'),
                  onMenuPressed: isMobile ? () => _scaffoldKey.currentState?.openDrawer() : null,
                  onQuickApply: () => setState(() => _currentRoute = '/dashboard/offres'),
                  onNotifications: () => setState(() => _currentRoute = '/dashboard/notifications'),
                  onProfile: () => setState(() => _currentRoute = '/dashboard/profil'),
                  onJobSearchSubmit: (q) {
                    setState(() {
                      _offresInitialKeyword = q.isEmpty ? null : q;
                      _offresSearchKey++;
                      _currentRoute = '/dashboard/offres';
                    });
                  },
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

class _CandidatPlaceholder extends StatelessWidget {
  const _CandidatPlaceholder({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_rounded, size: 36, color: Color(0xFF1A56DB)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Cette section candidat sera implémentée dans les prochaines étapes du PRD.',
              style: TextStyle(color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
