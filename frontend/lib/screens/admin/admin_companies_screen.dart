import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import '../../services/download_service.dart';
import '../../widgets/responsive_container.dart';
import 'widgets/admin_page_shimmer.dart';
import 'widgets/entreprise_actions_menu.dart';

class AdminCompaniesScreen extends StatefulWidget {
  const AdminCompaniesScreen({super.key});

  @override
  State<AdminCompaniesScreen> createState() => _AdminCompaniesScreenState();
}

class _AdminCompaniesScreenState extends State<AdminCompaniesScreen> {
  final _admin = AdminService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _companies = [];

  String _query = '';
  String _statusFilter = 'tous';
  String _cityFilter = 'toutes';
  int _currentPage = 1;
  static const int _perPage = 20;
  bool _exportingCsv = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _syncAdminBadges() {
    if (!mounted) return;
    context.read<AdminProvider>().loadDashboard();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _admin.getEntreprises(page: 1, limite: 200);
      final data = res['data'] as Map<String, dynamic>?;
      final raw = data?['entreprises'] as List<dynamic>? ?? const [];
      setState(() {
        _companies = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Map<String, dynamic>? _userOf(Map<String, dynamic> c) {
    final u = c['utilisateurs'];
    if (u is Map) return Map<String, dynamic>.from(u);
    if (u is List && u.isNotEmpty && u.first is Map) {
      return Map<String, dynamic>.from(u.first as Map);
    }
    return null;
  }

  String _status(Map<String, dynamic> c) {
    final user = _userOf(c);
    final valid = user?['est_valide'] == true;
    final active = user?['est_actif'] == true;
    if (!active) return 'Suspendu';
    if (!valid) return 'En attente';
    return 'Actif';
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    return _companies.where((c) {
      final name = (c['nom_entreprise']?.toString() ?? c['nom']?.toString() ?? '').toLowerCase();
      final email = (_userOf(c)?['email']?.toString() ?? c['email']?.toString() ?? '').toLowerCase();
      final city = (c['ville']?.toString() ?? c['adresse_siege']?.toString() ?? '').trim();
      final s = _status(c);

      if (q.isNotEmpty && !name.contains(q) && !email.contains(q)) return false;
      if (_statusFilter != 'tous' && s != _statusFilter) return false;
      if (_cityFilter != 'toutes' && city.toLowerCase() != _cityFilter.toLowerCase()) return false;
      return true;
    }).toList();
  }

  int get _totalPages {
    final len = _filtered.length;
    if (len == 0) return 1;
    return (len / _perPage).ceil();
  }

  List<Map<String, dynamic>> get _paged {
    final list = _filtered;
    final start = (_currentPage - 1) * _perPage;
    if (start >= list.length) return const [];
    final end = (start + _perPage).clamp(0, list.length);
    return list.sublist(start, end);
  }

  List<String> _cities() {
    final values = <String>{};
    for (final c in _companies) {
      final city = (c['ville']?.toString() ?? c['adresse_siege']?.toString() ?? '').trim();
      if (city.isNotEmpty) values.add(city);
    }
    final list = values.toList()..sort();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ResponsiveContainer(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: const AdminListScreenShimmer(showHeaderAction: false),
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
            FilledButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    final list = _paged;
    final totalFiltered = _filtered.length;
    final from = totalFiltered == 0 ? 0 : ((_currentPage - 1) * _perPage) + 1;
    final to = ((_currentPage - 1) * _perPage + list.length).clamp(0, totalFiltered);

    return ResponsiveContainer(
      child: RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFF1A56DB),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestion des Entreprises',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Validation, suspension et suivi des comptes recruteurs',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 320,
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Rechercher (entreprise / email)',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (v) => setState(() {
                          _query = v;
                          _currentPage = 1;
                        }),
                      ),
                    ),
                    _CompaniesFilter(
                      label: 'Statut',
                      value: _statusFilter,
                      items: const {
                        'tous': 'Tous',
                        'Actif': 'Actif',
                        'En attente': 'En attente',
                        'Suspendu': 'Suspendu',
                      },
                      onChanged: (v) => setState(() {
                        _statusFilter = v;
                        _currentPage = 1;
                      }),
                    ),
                    _CompaniesFilter(
                      label: 'Ville',
                      value: _cityFilter,
                      items: {
                        'toutes': 'Toutes',
                        ...{for (final c in _cities()) c.toLowerCase(): c},
                      },
                      onChanged: (v) => setState(() {
                        _cityFilter = v;
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
              ),
              const SizedBox(height: 16),
              if (list.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(child: Text('Aucune entreprise ne correspond aux filtres.')),
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
                          columnSpacing: 20,
                          columns: const [
                            DataColumn(label: Text('LOGO')),
                            DataColumn(label: Text('ENTREPRISE')),
                            DataColumn(label: Text('SECTEUR')),
                            DataColumn(label: Text('VILLE')),
                            DataColumn(label: Text('OFFRES ACTIVES')),
                            DataColumn(label: Text('STATUT')),
                            DataColumn(label: Text('DATE')),
                            DataColumn(label: Text('')),
                          ],
                          rows: list.map((c) => _buildRow(c)).toList(),
                        ),
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
                              'Affichage $from-$to sur $totalFiltered entreprises',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                                  icon: const Icon(Icons.chevron_left),
                                ),
                                Text('Page $_currentPage / $_totalPages'),
                                IconButton(
                                  onPressed:
                                      _currentPage < _totalPages ? () => setState(() => _currentPage++) : null,
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
            ],
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(Map<String, dynamic> c) {
    final name = (c['nom_entreprise']?.toString() ?? c['nom']?.toString() ?? '-').trim();
    final secteur = (c['secteur_activite']?.toString() ?? c['domaine']?.toString() ?? '-').trim();
    final city = (c['ville']?.toString() ?? c['adresse_siege']?.toString() ?? '-').trim();
    final offers = (c['nb_offres_actives'] ?? c['offres_actives'] ?? c['nombre_offres'] ?? 0).toString();
    final status = _status(c);
    final created = _formatDate(c['date_creation']?.toString() ?? _userOf(c)?['date_creation']?.toString());

    return DataRow(
      cells: [
        DataCell(
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFEFF6FF),
            child: Text(
              (name.isNotEmpty ? name[0] : 'E').toUpperCase(),
              style: const TextStyle(color: Color(0xFF1A56DB), fontWeight: FontWeight.w700),
            ),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              name.isEmpty ? '-' : name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              secteur.isEmpty ? '-' : secteur,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Text(
              city.isEmpty ? '-' : city,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(offers)),
        DataCell(_CompanyStatusBadge(status: status)),
        DataCell(Text(created)),
        DataCell(
          EntrepriseActionsMenu(
            entreprise: c,
            onRefresh: () async {
              await _load();
              _syncAdminBadges();
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Future<void> _exportCsv() async {
    final rows = _filtered;
    if (rows.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune entreprise à exporter.')),
      );
      return;
    }
    const fileName = 'entreprises_emploiconnect.csv';
    final buffer = StringBuffer('nom_entreprise,email,secteur,ville,offres_actives,statut,date_creation\n');
    for (final c in rows) {
      final name = (c['nom_entreprise']?.toString() ?? c['nom']?.toString() ?? '').replaceAll(',', ' ');
      final email = (_userOf(c)?['email']?.toString() ?? c['email']?.toString() ?? '').replaceAll(',', ' ');
      final secteur = (c['secteur_activite']?.toString() ?? c['domaine']?.toString() ?? '').replaceAll(',', ' ');
      final city = (c['ville']?.toString() ?? c['adresse_siege']?.toString() ?? '').replaceAll(',', ' ');
      final offers = (c['nb_offres_actives'] ?? c['offres_actives'] ?? c['nombre_offres'] ?? 0).toString();
      final status = _status(c).replaceAll(',', ' ');
      final date = (c['date_creation']?.toString() ?? _userOf(c)?['date_creation']?.toString() ?? '').replaceAll(',', ' ');
      buffer.writeln('$name,$email,$secteur,$city,$offers,$status,$date');
    }
    setState(() => _exportingCsv = true);
    try {
      await DownloadService.downloadCsvFromString(
        csvContent: buffer.toString(),
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

class _CompaniesFilter extends StatelessWidget {
  const _CompaniesFilter({
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
        decoration: InputDecoration(labelText: label),
        items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
        onChanged: (v) => onChanged(v ?? value),
      ),
    );
  }
}

class _CompanyStatusBadge extends StatelessWidget {
  const _CompanyStatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFFD1FAE5);
    Color fg = const Color(0xFF065F46);
    if (status == 'En attente') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
    } else if (status == 'Suspendu') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFF991B1B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
