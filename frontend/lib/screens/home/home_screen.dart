import 'package:flutter/material.dart';

import '../../app/public_routes.dart';
import 'home_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      endDrawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Accueil'),
                onTap: () => Navigator.of(context).pushNamed('/landing'),
              ),
              ListTile(
                leading: const Icon(Icons.work_outline),
                title: const Text("Offres d'emploi"),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(PublicRoutes.listPath);
                },
              ),
              ListTile(
                leading: const Icon(Icons.login_outlined),
                title: const Text('Connexion'),
                onTap: () => Navigator.of(context).pushNamed('/login'),
              ),
              ListTile(
                leading: const Icon(Icons.person_add_outlined),
                title: const Text('Inscription'),
                onTap: () => Navigator.of(context).pushNamed('/register'),
              ),
            ],
          ),
        ),
      ),
      body: HomePage(onOpenMenu: () => _scaffoldKey.currentState?.openEndDrawer()),
    );
  }
}

