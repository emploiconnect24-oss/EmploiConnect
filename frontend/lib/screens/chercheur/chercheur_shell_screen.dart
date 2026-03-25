import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import '../profile_screen.dart';
import 'offres_list_screen.dart';
import 'suggestions_screen.dart';
import 'candidatures_screen.dart';
import 'cv_screen.dart';

class ChercheurShellScreen extends StatefulWidget {
  const ChercheurShellScreen({super.key});

  @override
  State<ChercheurShellScreen> createState() => _ChercheurShellScreenState();
}

class _ChercheurShellScreenState extends State<ChercheurShellScreen> {
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
        return 'Offres';
      case 1:
        return 'Pour moi';
      case 2:
        return 'Candidatures';
      case 3:
        return 'Mon CV';
      case 4:
        return 'Profil';
      default:
        return 'Chercheur';
    }
  }

  List<NavigationRailDestination> get _railDestinations => const [
        NavigationRailDestination(
          icon: Icon(Icons.list_alt_outlined),
          selectedIcon: Icon(Icons.list_alt),
          label: Text('Offres'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.star_outline),
          selectedIcon: Icon(Icons.star),
          label: Text('Pour moi'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment),
          label: Text('Candidatures'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description),
          label: Text('Mon CV'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Profil'),
        ),
      ];

  List<Widget> get _tabs => const [
        OffresListScreen(),
        SuggestionsScreen(),
        CandidaturesScreen(),
        CvScreen(),
        ProfileScreen(),
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
                          leading: Icon(Icons.person_search),
                          title: Text('Espace Candidat'),
                          subtitle: Text('Navigation'),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView(
                            children: [
                              _DrawerItem(
                                selected: _index == 0,
                                icon: Icons.list_alt,
                                label: 'Offres',
                                onTap: () => _select(0),
                              ),
                              _DrawerItem(
                                selected: _index == 1,
                                icon: Icons.star,
                                label: 'Pour moi',
                                onTap: () => _select(1),
                              ),
                              _DrawerItem(
                                selected: _index == 2,
                                icon: Icons.assignment,
                                label: 'Candidatures',
                                onTap: () => _select(2),
                              ),
                              _DrawerItem(
                                selected: _index == 3,
                                icon: Icons.description,
                                label: 'Mon CV',
                                onTap: () => _select(3),
                              ),
                              _DrawerItem(
                                selected: _index == 4,
                                icon: Icons.person,
                                label: 'Profil',
                                onTap: () => _select(4),
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
                          Icons.person_search,
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

