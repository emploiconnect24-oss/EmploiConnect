import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'core/theme/theme_provider.dart';
import 'core/constants/app_animations.dart';
import 'providers/app_config_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/candidat_provider.dart';
import 'providers/recruteur_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'core/utils/reset_token.dart';
import 'app/public_routes.dart';
import 'screens/home_shell_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/admin/admin_shell_screen.dart';
import 'screens/public/public_offres_screen.dart';
import 'screens/public/public_offer_detail_screen.dart';
import 'theme/app_theme.dart';

String? _parseResetTokenFromRoute(String name) {
  if (name.contains('?')) {
    return Uri.parse('http://x$name').queryParameters['token'];
  }
  return readResetPasswordTokenFromUrl();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  timeago.setLocaleMessages('fr_short', timeago.FrShortMessages());
  final themeProvider = ThemeProvider();
  await themeProvider.init();
  runApp(EmploiConnectApp(themeProvider: themeProvider));
}

class EmploiConnectApp extends StatelessWidget {
  const EmploiConnectApp({super.key, required this.themeProvider});

  final ThemeProvider themeProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadSession()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => AppConfigProvider()..reload()),
        ChangeNotifierProvider(create: (_) => RecruteurProvider()),
        ChangeNotifierProvider(create: (_) => CandidatProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => AnimatedTheme(
          data: theme.isDark(context)
              ? AppTheme.darkTheme
              : AppTheme.lightTheme,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: MaterialApp(
            title: 'EmploiConnect',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: theme.themeMode,
            builder: (context, child) => _GlobalMaintenanceBanner(
              child: child ?? const SizedBox.shrink(),
            ),
            initialRoute: '/',
            onGenerateRoute: (settings) {
              Widget page;
              final name = settings.name ?? '/';
              final path = PublicRoutes.pathOnly(name);
              const candidatRoutes = <String>{
                '/dashboard',
                '/dashboard/profil',
                '/dashboard/offres',
                '/dashboard/candidatures',
                '/dashboard/recommandations',
                '/dashboard/ia-demo',
                '/dashboard/sauvegardes',
                '/dashboard/messages',
                '/dashboard/conseils',
                '/dashboard/alertes',
                '/dashboard/notifications',
                '/dashboard/parametres',
                '/dashboard/temoignage',
              };

              if (candidatRoutes.contains(path)) {
                page = HomeShellScreen(initialRoute: path);
              } else if (path == PublicRoutes.listPath) {
                page = PublicOffresScreen(
                  initialSearch: PublicRoutes.queryParam(name, 'q'),
                  entrepriseId: PublicRoutes.queryParam(name, 'e'),
                  entrepriseNom: PublicRoutes.queryParam(name, 'n'),
                );
              } else if (path.startsWith(PublicRoutes.offrePrefix) &&
                  path.length > PublicRoutes.offrePrefix.length) {
                final encoded =
                    path.substring(PublicRoutes.offrePrefix.length);
                page = PublicOfferDetailScreen(
                  offreId: Uri.decodeComponent(encoded),
                );
              } else {
                switch (path) {
                  case '/':
                    page = const AuthWrapper();
                    break;
                  case '/landing':
                    page = const HomeScreen();
                    break;
                  case '/login':
                    page = const LoginScreen();
                    break;
                  case '/register':
                    page = const RegisterScreen();
                    break;
                  case '/forgot-password':
                    page = const ForgotPasswordScreen();
                    break;
                  case '/reset-password':
                    page = ResetPasswordScreen(
                      initialToken: _parseResetTokenFromRoute(name),
                    );
                    break;
                  case '/home':
                    page = const HomeShellScreen();
                    break;
                  case '/admin':
                    page = const AdminRouteGuard();
                    break;
                  default:
                    if (path.startsWith('/reset-password')) {
                      page = ResetPasswordScreen(
                        initialToken: _parseResetTokenFromRoute(name),
                      );
                    } else {
                      page = const AuthWrapper();
                    }
                }
              }

              final useFade =
                  path == '/login' ||
                  path == '/register' ||
                  path == '/forgot-password' ||
                  path.startsWith('/reset-password');

              if (!useFade) {
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => page,
                );
              }

              return PageRouteBuilder<void>(
                settings: settings,
                pageBuilder: (context, animation, secondaryAnimation) => page,
                transitionDuration: AppAnimations.normal,
                reverseTransitionDuration: AppAnimations.normal,
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      final curved = CurvedAnimation(
                        parent: animation,
                        curve: AppAnimations.standard,
                      );
                      return FadeTransition(opacity: curved, child: child);
                    },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Affiche un écran de chargement puis /home si connecté, sinon /login.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.sessionLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (auth.isLoggedIn) {
          return const HomeShellScreen();
        }
        return const HomeScreen();
      },
    );
  }
}

class AdminRouteGuard extends StatelessWidget {
  const AdminRouteGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.sessionLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!auth.isLoggedIn || auth.role != 'admin') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const AdminShellScreen();
      },
    );
  }
}

class _GlobalMaintenanceBanner extends StatefulWidget {
  const _GlobalMaintenanceBanner({required this.child});
  final Widget child;

  @override
  State<_GlobalMaintenanceBanner> createState() =>
      _GlobalMaintenanceBannerState();
}

class _GlobalMaintenanceBannerState extends State<_GlobalMaintenanceBanner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 45), (_) async {
      if (!mounted) return;
      await context.read<AppConfigProvider>().reload();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppConfigProvider>(
      builder: (context, config, _) {
        if (!config.modeMaintenanceActif) return widget.child;
        return Column(
          children: [
            Material(
              color: const Color(0xFFEF4444),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.construction_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          config.messageMaintenanceText.isNotEmpty
                              ? config.messageMaintenanceText
                              : 'La plateforme est en cours de maintenance.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x33FFFFFF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'MAINTENANCE',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: widget.child),
          ],
        );
      },
    );
  }
}
