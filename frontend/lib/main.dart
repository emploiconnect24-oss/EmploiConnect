import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'core/constants/app_animations.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_shell_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/admin/admin_shell_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  timeago.setLocaleMessages('fr_short', timeago.FrShortMessages());
  runApp(const EmploiConnectApp());
}

class EmploiConnectApp extends StatelessWidget {
  const EmploiConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..loadSession(),
      child: MaterialApp(
        title: 'EmploiConnect',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          Widget page;
          switch (settings.name) {
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
            case '/home':
              page = const HomeShellScreen();
              break;
            case '/admin':
              page = const AdminRouteGuard();
              break;
            default:
              page = const AuthWrapper();
          }

          final useFade = settings.name == '/login' ||
              settings.name == '/register' ||
              settings.name == '/forgot-password';

          if (!useFade) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => page,
            );
          }

          return PageRouteBuilder<void>(
            settings: settings,
            pageBuilder: (_, __, ___) => page,
            transitionDuration: AppAnimations.normal,
            reverseTransitionDuration: AppAnimations.normal,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: AppAnimations.standard,
              );
              return FadeTransition(
                opacity: curved,
                child: child,
              );
            },
          );
        },
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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!auth.isLoggedIn || auth.role != 'admin') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return const AdminShellScreen();
      },
    );
  }
}
