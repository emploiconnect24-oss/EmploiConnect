import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/admin_service.dart';
import '../../widgets/responsive_container.dart';
import '../../widgets/status_chip.dart';
import 'package:intl/intl.dart';
import 'widgets/admin_search_bar.dart';
import 'widgets/action_menu.dart';
import 'widgets/admin_empty_state.dart';

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
  String _statusFilter = 'tous';
  String _cityFilter = 'toutes';
  String _activeFilter = 'tous';
  String _activeTab = 'Tous';
  int _currentPage = 1;
  static const int _perPage = 20;

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
      final city = (u['ville']?.toString() ?? '').trim();

      if (q.isNotEmpty && !email.contains(q) && !nom.contains(q)) return false;
      if (_roleFilter != 'tous' && role != _roleFilter) return false;
      if (_statusFilter == 'en_attente' && estValide) return false;
      if (_statusFilter == 'actif' && (!estValide || !estActif)) return false;
      if (_statusFilter == 'bloque' && estActif) return false;
      if (_activeFilter == 'actif' && !estActif) return false;
      if (_activeFilter == 'inactif' && estActif) return false;
      if (_cityFilter != 'toutes' && city.toLowerCase() != _cityFilter.toLowerCase()) return false;

      if (_activeTab == 'Candidats' && role != 'chercheur') return false;
      if (_activeTab == 'Recruteurs' && role != 'entreprise') return false;
      if (_activeTab == 'En attente' && estValide) return false;
      if (_activeTab == 'Bloqués' && estActif) return false;

      return true;
    }).toList();
  }

  int get _totalPages {
    final count = _filtered.length;
    if (count == 0) return 1;
    return (count / _perPage).ceil();
  }

  List<Map<String, dynamic>> get _paged {
    final list = _filtered;
    final start = (_currentPage - 1) * _perPage;
    if (start >= list.length) return const [];
    final end = (start + _perPage).clamp(0, list.length);
    return list.sublist(start, end);
  }

  Map<String, int> get _tabCounts {
    int candidats = 0;
    int recruteurs = 0;
    int attente = 0;
    int bloques = 0;
    for (final u in _users) {
      final role = u['role']?.toString() ?? '';
      final estValide = u['est_valide'] == true;
      final estActif = u['est_actif'] == true;
      if (role == 'chercheur') candidats++;
      if (role == 'entreprise') recruteurs++;
      if (!estValide) attente++;
      if (!estActif) bloques++;
    }
    return {
      'Tous': _users.length,
      'Candidats': candidats,
      'Recruteurs': recruteurs,
      'En attente': attente,
      'Bloqués': bloques,
    };
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

    final list = _paged;
    final counts = _tabCounts;
    final totalFiltered = _filtered.length;
    final from = totalFiltered == 0 ? 0 : ((_currentPage - 1) * _perPage) + 1;
    final to = ((_currentPage - 1) * _perPage + list.length).clamp(0, totalFiltered);

    return ResponsiveContainer(
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestion des Utilisateurs',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Gérez tous les comptes de la plateforme',
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: _showAddUserDialog,
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: const Text('Ajouter un utilisateur'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56DB),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminSearchBar(
                      hint: 'Rechercher par nom, email...',
                      onChanged: (v) => setState(() {
                        _query = v;
                        _currentPage = 1;
                      }),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
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
                          onChanged: (v) => setState(() {
                            _roleFilter = v;
                            _currentPage = 1;
                          }),
                        ),
                        _FilterDropdown(
                          label: 'Statut',
                          value: _statusFilter,
                          items: const {
                            'tous': 'Tous',
                            'actif': 'Actif',
                            'en_attente': 'En attente',
                            'bloque': 'Bloqué',
                          },
                          onChanged: (v) => setState(() {
                            _statusFilter = v;
                            _currentPage = 1;
                          }),
                        ),
                        _FilterDropdown(
                          label: 'Ville',
                          value: _cityFilter,
                          items: {
                            'toutes': 'Toutes',
                            ...{
                              for (final city in _extractCities())
                                city.toLowerCase(): city
                            },
                          },
                          onChanged: (v) => setState(() {
                            _cityFilter = v;
                            _currentPage = 1;
                          }),
                        ),
                        _FilterDropdown(
                          label: 'Activation',
                          value: _activeFilter,
                          items: const {
                            'tous': 'Tous',
                            'actif': 'Actifs',
                            'inactif': 'Inactifs',
                          },
                          onChanged: (v) => setState(() {
                            _activeFilter = v;
                            _currentPage = 1;
                          }),
                        ),
                        OutlinedButton.icon(
                          onPressed: _exportCsv,
                          icon: const Icon(Icons.download_outlined, size: 16),
                          label: const Text('Exporter'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tab in const [
                          'Tous',
                          'Candidats',
                          'Recruteurs',
                          'En attente',
                          'Bloqués'
                        ])
                          ChoiceChip(
                            label: Text('$tab (${counts[tab] ?? 0})'),
                            selected: _activeTab == tab,
                            onSelected: (_) => setState(() {
                              _activeTab = tab;
                              _currentPage = 1;
                            }),
                            selectedColor: const Color(0xFFEFF6FF),
                            labelStyle: TextStyle(
                              color: _activeTab == tab
                                  ? const Color(0xFF1A56DB)
                                  : const Color(0xFF64748B),
                              fontWeight: _activeTab == tab ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (list.isEmpty)
              AdminEmptyState(
                icon: Icons.people_outline_rounded,
                iconColor: const Color(0xFF1A56DB),
                title: 'Aucun utilisateur trouvé',
                subtitle: 'Aucun utilisateur ne correspond aux filtres sélectionnés.',
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 22,
                        headingTextStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                        columns: const [
                          DataColumn(label: Text('UTILISATEUR')),
                          DataColumn(label: Text('EMAIL')),
                          DataColumn(label: Text('RÔLE')),
                          DataColumn(label: Text('STATUT')),
                          DataColumn(label: Text('VILLE')),
                          DataColumn(label: Text('INSCRIT LE')),
                          DataColumn(label: Text('')),
                        ],
                        rows: list.map((u) => _buildRow(context, u)).toList(),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Affichage $from-$to sur $totalFiltered utilisateurs',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _currentPage > 1
                                    ? () => setState(() => _currentPage--)
                                    : null,
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Text(
                                'Page $_currentPage / $_totalPages',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              IconButton(
                                onPressed: _currentPage < _totalPages
                                    ? () => setState(() => _currentPage++)
                                    : null,
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 22),
          ],
        ),
      ),
    ),
    );
  }

  DataRow _buildRow(BuildContext context, Map<String, dynamic> u) {
    final id = u['id']?.toString() ?? '';
    final email = u['email']?.toString() ?? '';
    final nom = u['nom']?.toString() ?? '';
    final role = u['role']?.toString() ?? '';
    final valide = u['est_valide'] == true;
    final actif = u['est_actif'] == true;
    final city = (u['ville']?.toString() ?? '-').trim();
    final createdAt = _formatDate(u['created_at']?.toString());
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: const Color(0xFF1A56DB),
                child: Text(
                  (nom.isNotEmpty ? nom[0] : (email.isNotEmpty ? email[0] : 'U')).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                nom.isEmpty ? '—' : nom,
                style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        DataCell(Text(email)),
        DataCell(StatusChip(value: role)),
        DataCell(StatusChip(value: actif ? (valide ? 'actif' : 'en_attente') : 'bloque')),
        DataCell(Text(city.isEmpty ? '-' : city)),
        DataCell(Text(createdAt)),
        DataCell(
          ActionMenu(
            actions: [
              ActionItem(
                icon: Icons.visibility_outlined,
                label: 'Voir le profil',
                onTap: () {},
              ),
              if (!valide)
                ActionItem(
                  icon: Icons.check_circle_outline,
                  label: 'Valider',
                  color: const Color(0xFF10B981),
                  onTap: () async {
                    final ok = await _showConfirmDialog(
                      title: 'Valider cet utilisateur ?',
                      message: 'Le compte sera activé.',
                      confirmLabel: 'Valider',
                      confirmColor: const Color(0xFF10B981),
                    );
                    if (ok) await _valider(id, true);
                  },
                ),
              if (actif)
                ActionItem(
                  icon: Icons.block_outlined,
                  label: 'Bloquer',
                  color: const Color(0xFFF59E0B),
                  onTap: () async {
                    final ok = await _showConfirmDialog(
                      title: 'Bloquer cet utilisateur ?',
                      message: 'L\'utilisateur ne pourra plus se connecter.',
                      confirmLabel: 'Bloquer',
                      confirmColor: const Color(0xFFF59E0B),
                    );
                    if (ok) await _actif(id, false);
                  },
                ),
              ActionItem(
                icon: Icons.delete_outline,
                label: 'Supprimer',
                color: const Color(0xFFEF4444),
                dividerBefore: true,
                onTap: () async {
                  final ok = await _showConfirmDialog(
                    title: 'Supprimer cet utilisateur ?',
                    message: 'Cette action est irreversible.',
                    confirmLabel: 'Supprimer',
                    confirmColor: const Color(0xFFEF4444),
                  );
                  if (!ok || !mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Suppression à connecter côté API admin.')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: confirmColor, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return ok == true;
  }

  List<String> _extractCities() {
    final cities = <String>{};
    for (final u in _users) {
      final city = (u['ville']?.toString() ?? '').trim();
      if (city.isNotEmpty) cities.add(city);
    }
    final sorted = cities.toList()..sort();
    return sorted;
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '-';
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  void _showAddUserDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ajout utilisateur à implémenter dans l’étape dédiée.')),
    );
  }

  Future<void> _exportCsv() async {
    final rows = _filtered;
    if (rows.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune donnée à exporter.')),
      );
      return;
    }
    final buffer = StringBuffer('nom,email,role,est_valide,est_actif,ville,date_creation\n');
    for (final u in rows) {
      final nom = (u['nom']?.toString() ?? '').replaceAll(',', ' ');
      final email = (u['email']?.toString() ?? '').replaceAll(',', ' ');
      final role = (u['role']?.toString() ?? '').replaceAll(',', ' ');
      final valide = (u['est_valide'] == true).toString();
      final actif = (u['est_actif'] == true).toString();
      final ville = (u['ville']?.toString() ?? '').replaceAll(',', ' ');
      final date = (u['created_at']?.toString() ?? '').replaceAll(',', ' ');
      buffer.writeln('$nom,$email,$role,$valide,$actif,$ville,$date');
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV copié dans le presse-papiers.')),
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
        ),
        items: items.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: (v) => onChanged(v ?? value),
      ),
    );
  }
}
