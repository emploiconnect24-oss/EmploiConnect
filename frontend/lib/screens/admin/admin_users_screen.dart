import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../services/download_service.dart';
import '../../widgets/responsive_container.dart';
import '../../widgets/status_chip.dart';
import 'package:intl/intl.dart';
import 'widgets/admin_search_bar.dart';
import 'widgets/user_actions_menu.dart';
import 'widgets/admin_empty_state.dart';
import 'widgets/admin_page_shimmer.dart';

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
  bool _exportingCsv = false;

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

  void _syncAdminBadges() {
    if (!mounted) return;
    context.read<AdminProvider>().loadDashboard();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    return _users.where((u) {
      final email = (u['email']?.toString() ?? '').toLowerCase();
      final nom = (u['nom']?.toString() ?? '').toLowerCase();
      final role = u['role']?.toString() ?? '';
      final estValide = u['est_valide'] == true;
      final estActif = u['est_actif'] == true;
      final city = _displayCity(u);

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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ResponsiveContainer(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: const AdminListScreenShimmer(showHeaderAction: true),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            FilledButton(
              onPressed: _load,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final list = _paged;
    final counts = _tabCounts;
    final totalFiltered = _filtered.length;
    final from = totalFiltered == 0 ? 0 : ((_currentPage - 1) * _perPage) + 1;
    final to = ((_currentPage - 1) * _perPage + list.length).clamp(0, totalFiltered);

    return ResponsiveContainer(
      child: RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFF1A56DB),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
            LayoutBuilder(
              builder: (context, bc) {
                final narrow = bc.maxWidth < 520;
                final titleBlock = const Column(
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
                );
                final exportHeaderBtn = OutlinedButton.icon(
                  icon: _exportingCsv
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined, size: 16),
                  label: Text(_exportingCsv ? 'Export…' : 'Exporter CSV'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: GoogleFonts.inter(fontSize: 14),
                  ),
                  onPressed: _exportingCsv ? null : _exportCsv,
                );
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      titleBlock,
                      const SizedBox(height: 12),
                      exportHeaderBtn,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: titleBlock),
                    const SizedBox(width: 12),
                    exportHeaderBtn,
                  ],
                );
              },
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
                          onPressed: _exportingCsv ? null : _exportCsv,
                          icon: _exportingCsv
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.download_outlined, size: 16),
                          label: Text(_exportingCsv ? 'Export…' : 'Exporter'),
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
                    LayoutBuilder(
                      builder: (context, tableBc) {
                        final minW = tableBc.hasBoundedWidth && tableBc.maxWidth > 0
                            ? tableBc.maxWidth
                            : 900.0;
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: minW),
                            child: DataTable(
                        columnSpacing: 22,
                        headingTextStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                        columns: [
                          const DataColumn(label: Text('UTILISATEUR')),
                          const DataColumn(label: Text('EMAIL')),
                          const DataColumn(label: Text('RÔLE')),
                          const DataColumn(label: Text('STATUT')),
                          DataColumn(
                            label: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('VILLE', style: _tableHeadStyle()),
                                Text(
                                  '(adresse)',
                                  style: _tableHeadStyle().copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataColumn(
                            label: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('INSCRIT LE', style: _tableHeadStyle()),
                                Text(
                                  '(date création)',
                                  style: _tableHeadStyle().copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const DataColumn(label: Text('')),
                        ],
                        rows: list.map((u) => _buildRow(context, u)).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Text(
                            'Affichage $from-$to sur $totalFiltered utilisateurs',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
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
    );
          },
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, Map<String, dynamic> u) {
    final email = u['email']?.toString() ?? '';
    final nom = u['nom']?.toString() ?? '';
    final role = u['role']?.toString() ?? '';
    final valide = u['est_valide'] == true;
    final actif = u['est_actif'] == true;
    final city = _displayCity(u);
    final createdAt = _formatDate(_createdAtRaw(u));
    return DataRow(
      cells: [
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Row(
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
                Expanded(
                  child: Text(
                    nom.isEmpty ? '—' : nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(StatusChip(value: role)),
        DataCell(StatusChip(value: actif ? (valide ? 'actif' : 'en_attente') : 'bloque')),
        DataCell(Text(city.isEmpty ? '-' : city)),
        DataCell(Text(createdAt)),
        DataCell(
          UserActionsMenu(
            user: u,
            onRefresh: () async {
              await _load();
              _syncAdminBadges();
            },
          ),
        ),
      ],
    );
  }

  TextStyle _tableHeadStyle() => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF64748B),
      );

  /// API Supabase : `adresse` (pas `ville`) ; tolère les deux + alias backend.
  String _displayCity(Map<String, dynamic> u) {
    for (final key in ['ville', 'adresse', 'city', 'localisation']) {
      final v = u[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return '';
  }

  String? _createdAtRaw(Map<String, dynamic> u) {
    for (final key in ['date_creation', 'created_at', 'date_inscription']) {
      final v = u[key]?.toString();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  List<String> _extractCities() {
    final cities = <String>{};
    for (final u in _users) {
      final city = _displayCity(u);
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

  Future<void> _exportCsv() async {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour exporter.')),
      );
      return;
    }
    const fileName = 'utilisateurs_emploiconnect.csv';
    setState(() => _exportingCsv = true);
    try {
      await DownloadService.downloadCsvFromApi(
        apiPathAndQuery: '/admin/utilisateurs/export/csv',
        token: token,
        fileName: fileName,
        context: context,
      );
      if (!mounted) return;
      DownloadService.showWebDownloadSnackBar(context, fileName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _exportingCsv = false);
    }
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
