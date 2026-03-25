import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import 'mes_offres_screen.dart';
import 'entreprise_settings_screen.dart';
import 'entreprise_profile_screen.dart';

class EntrepriseShellScreen extends StatefulWidget {
  const EntrepriseShellScreen({super.key});

  @override
  State<EntrepriseShellScreen> createState() => _EntrepriseShellScreenState();
}

class _EntrepriseShellScreenState extends State<EntrepriseShellScreen> {
  int _index = 0;

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String get _title {
    switch (_index) {
      case 0:
        return 'Mes offres';
      case 1:
        return 'Profil';
      case 2:
        return 'Paramètres';
      default:
        return 'Entreprise';
    }
  }

  List<NavigationRailDestination> get _railDestinations => const [
        NavigationRailDestination(
          icon: Icon(Icons.work_outline),
          selectedIcon: Icon(Icons.work),
          label: Text('Mes offres'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Profil'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Paramètres'),
        ),
      ];

  List<Widget> get _tabs => const [
        MesOffresScreen(),
        EntrepriseProfileScreen(),
        EntrepriseSettingsScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final useRail = w >= 780;

        final body = IndexedStack(
          index: _index.clamp(0, _tabs.length - 1),
          children: _tabs,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text('EmploiConnect — $_title'),
            actions: [
              IconButton(
                tooltip: 'Déconnexion',
                icon: const Icon(Icons.logout),
                onPressed: _logout,
              ),
            ],
          ),
          drawer: useRail
              ? null
              : Drawer(
                  child: SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        const ListTile(
                          leading: Icon(Icons.apartment),
                          title: Text('Espace Entreprise'),
                          subtitle: Text('Navigation'),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView(
                            children: [
                              _DrawerItem(
                                selected: _index == 0,
                                icon: Icons.work,
                                label: 'Mes offres',
                                onTap: () => _select(0),
                              ),
                              _DrawerItem(
                                selected: _index == 1,
                                icon: Icons.person,
                                label: 'Profil',
                                onTap: () => _select(1),
                              ),
                              _DrawerItem(
                                selected: _index == 2,
                                icon: Icons.settings,
                                label: 'Paramètres',
                                onTap: () => _select(2),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text('Déconnexion'),
                          onTap: () async {
                            Navigator.of(context).pop();
                            await _logout();
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
          body: useRail
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _index,
                      onDestinationSelected: (i) => setState(() => _index = i),
                      labelType: w >= 1100
                          ? NavigationRailLabelType.none
                          : NavigationRailLabelType.selected,
                      extended: w >= 1100,
                      minExtendedWidth: 240,
                      leading: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Icon(
                          Icons.apartment,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      trailing: Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: IconButton(
                              tooltip: 'Déconnexion',
                              onPressed: _logout,
                              icon: const Icon(Icons.logout),
                            ),
                          ),
                        ),
                      ),
                      destinations: _railDestinations,
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: body),
                  ],
                )
              : body,
        );
      },
    );
  }

  void _select(int i) {
    setState(() => _index = i);
    Navigator.of(context).maybePop();
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}

