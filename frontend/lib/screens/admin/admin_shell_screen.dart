import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_signalements_screen.dart';
import 'admin_users_screen.dart';
import 'admin_settings_screen.dart';

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
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
        return 'Tableau de bord';
      case 1:
        return 'Utilisateurs';
      case 2:
        return 'Signalements';
      case 3:
        return 'Paramètres';
      default:
        return 'Admin';
    }
  }

  List<NavigationRailDestination> get _railDestinations => const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Tableau de bord'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: Text('Utilisateurs'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.flag_outlined),
          selectedIcon: Icon(Icons.flag),
          label: Text('Signalements'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Paramètres'),
        ),
      ];

  List<Widget> get _tabs => const [
        AdminDashboardScreen(),
        AdminUsersScreen(),
        AdminSignalementsScreen(),
        AdminSettingsScreen(),
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
                          leading: Icon(Icons.admin_panel_settings),
                          title: Text('Administration'),
                          subtitle: Text('Navigation'),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView(
                            children: [
                              _DrawerItem(
                                selected: _index == 0,
                                icon: Icons.dashboard,
                                label: 'Tableau de bord',
                                onTap: () => _select(0),
                              ),
                              _DrawerItem(
                                selected: _index == 1,
                                icon: Icons.people,
                                label: 'Utilisateurs',
                                onTap: () => _select(1),
                              ),
                              _DrawerItem(
                                selected: _index == 2,
                                icon: Icons.flag,
                                label: 'Signalements',
                                onTap: () => _select(2),
                              ),
                              _DrawerItem(
                                selected: _index == 3,
                                icon: Icons.settings,
                                label: 'Paramètres',
                                onTap: () => _select(3),
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
                          Icons.admin_panel_settings,
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

