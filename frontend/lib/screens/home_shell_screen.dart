import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'chercheur/chercheur_shell_screen.dart';
import 'recruteur/recruteur_shell_screen.dart';
import 'admin/admin_shell_screen.dart';

/// Navigation principale selon le rôle (alignée sur l’API backend).
class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  void _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role ?? '';

    if (role == 'chercheur') {
      return const ChercheurShellScreen();
    }

    if (role == 'entreprise' || role == 'recruteur') {
      return const RecruteurShellScreen();
    }

    if (role == 'admin') {
      return const AdminShellScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('EmploiConnect'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context)),
        ],
      ),
      body: const Center(child: Text('Rôle non reconnu')),
    );
  }
}
