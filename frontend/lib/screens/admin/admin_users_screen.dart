import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../widgets/responsive_container.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/hover_scale.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _admin = AdminService();
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  String _roleFilter = 'tous';
  String _validFilter = 'tous';
  String _activeFilter = 'tous';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _admin.getUtilisateurs(limit: 100);
      setState(() {
        _users = r.utilisateurs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    return _users.where((u) {
      final email = (u['email']?.toString() ?? '').toLowerCase();
      final nom = (u['nom']?.toString() ?? '').toLowerCase();
      final role = u['role']?.toString() ?? '';
      final estValide = u['est_valide'] == true;
      final estActif = u['est_actif'] == true;

      if (q.isNotEmpty && !email.contains(q) && !nom.contains(q)) return false;
      if (_roleFilter != 'tous' && role != _roleFilter) return false;
      if (_validFilter == 'valide' && !estValide) return false;
      if (_validFilter == 'non_valide' && estValide) return false;
      if (_activeFilter == 'actif' && !estActif) return false;
      if (_activeFilter == 'inactif' && estActif) return false;
      return true;
    }).toList();
  }

  Future<void> _valider(String id, bool valide) async {
    try {
      await _admin.patchUtilisateur(id, estValide: valide);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(valide ? 'Compte validé' : 'Validation retirée')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _actif(String id, bool actif) async {
    try {
      await _admin.patchUtilisateur(id, estActif: actif);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(actif ? 'Compte activé' : 'Compte désactivé')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final list = _filtered;
    final scheme = Theme.of(context).colorScheme;

    return ResponsiveContainer(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Text(
              'Utilisateurs',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Rechercher, valider et activer/désactiver des comptes.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Rechercher (email / nom)',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _FilterDropdown(
                          label: 'Rôle',
                          value: _roleFilter,
                          items: const {
                            'tous': 'Tous',
                            'chercheur': 'Chercheur',
                            'entreprise': 'Entreprise',
                            'admin': 'Admin',
                          },
                          onChanged: (v) => setState(() => _roleFilter = v),
                        ),
                        _FilterDropdown(
                          label: 'Validation',
                          value: _validFilter,
                          items: const {
                            'tous': 'Tous',
                            'valide': 'Validés',
                            'non_valide': 'Non validés',
                          },
                          onChanged: (v) => setState(() => _validFilter = v),
                        ),
                        _FilterDropdown(
                          label: 'Statut',
                          value: _activeFilter,
                          items: const {
                            'tous': 'Tous',
                            'actif': 'Actifs',
                            'inactif': 'Inactifs',
                          },
                          onChanged: (v) => setState(() => _activeFilter = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Center(child: Text('Aucun utilisateur ne correspond aux filtres.')),
              )
            else
              ...list.map((u) {
                final id = u['id']?.toString() ?? '';
                final email = u['email']?.toString() ?? '';
                final nom = u['nom']?.toString() ?? '';
                final role = u['role']?.toString() ?? '';
                final valide = u['est_valide'] == true;
                final actif = u['est_actif'] == true;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    email,
                                    style: const TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    nom.isEmpty ? '—' : nom,
                                    style: TextStyle(color: scheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            StatusChip(value: role),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            StatusChip(value: valide ? 'valide' : 'non_valide'),
                            StatusChip(value: actif ? 'actif' : 'inactif'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (role != 'admin')
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              HoverScale(
                                onTap: () => _valider(id, true),
                                child: FilledButton.icon(
                                  onPressed: () => _valider(id, true),
                                  icon: const Icon(Icons.verified),
                                  label: const Text('Valider'),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _valider(id, false),
                                icon: const Icon(Icons.block),
                                label: const Text('Invalider'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _actif(id, true),
                                icon: const Icon(Icons.toggle_on),
                                label: const Text('Activer'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _actif(id, false),
                                icon: const Icon(Icons.toggle_off),
                                label: const Text('Désactiver'),
                              ),
                            ],
                          )
                        else
                          Text(
                            'Compte admin (actions désactivées).',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
        ),
        items: items.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: (v) => onChanged(v ?? value),
      ),
    );
  }
}
