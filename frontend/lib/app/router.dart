import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/admin/admin_shell_screen.dart';
import '../screens/admin/pages/user_detail_page.dart';
import '../screens/home/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/public/public_offer_detail_screen.dart';
import '../screens/offres/offres_page.dart';

/// Router GoRouter (prêt pour une migration depuis [MaterialApp.onGenerateRoute]).
/// En parallèle, les mêmes chemins sont gérés dans `main.dart` via [Navigator.pushNamed].
///
/// - Offres publiques : `/public/offres` (query `q`, `e` entreprise, `n` nom), `/public/offre/:id`
/// - Admin : `/admin/utilisateurs/:id`
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/public/offres',
      builder: (BuildContext context, GoRouterState state) => OffresPage(
            initialSearch: state.uri.queryParameters['q'],
            entrepriseId: state.uri.queryParameters['e'],
            entrepriseNom: state.uri.queryParameters['n'],
          ),
    ),
    GoRoute(
      path: '/public/offre/:id',
      builder: (BuildContext context, GoRouterState state) =>
          PublicOfferDetailScreen(
            offreId: state.pathParameters['id']!,
          ),
    ),
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) => child,
      routes: [
        GoRoute(
          path: '/admin/utilisateurs/:id',
          builder: (BuildContext context, GoRouterState state) => UserDetailPage(
                userId: state.pathParameters['id']!,
              ),
        ),
        GoRoute(
          path: '/admin/acces',
          builder: (BuildContext context, GoRouterState state) {
            return Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (!auth.sessionLoaded) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!auth.isLoggedIn || auth.role != 'admin') {
                  return const LoginScreen();
                }
                return const AdminShellScreen(initialRoute: '/admin/acces');
              },
            );
          },
        ),
      ],
    ),
  ],
);

