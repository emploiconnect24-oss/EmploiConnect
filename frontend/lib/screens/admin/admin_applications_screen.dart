import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/candidatures_service.dart';
import '../../widgets/responsive_container.dart';

class AdminApplicationsScreen extends StatefulWidget {
  const AdminApplicationsScreen({super.key});

  @override
  State<AdminApplicationsScreen> createState() => _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState extends State<AdminApplicationsScreen> {
  final _service = CandidaturesService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _all = [];

  String _query = '';
  String _statusFilter = 'tous';
  String _companyFilter = 'toutes';
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
      final list = await _service.getCandidatures();
      setState(() {
        _all = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _uiStatus(Map<String, dynamic> c) {
    final raw = (c['statut']?.toString() ?? '').toLowerCase();
    if (raw.contains('entretien')) return 'Entretien';
    if (raw.contains('accepte')) return 'Acceptée';
    if (raw.contains('refus')) return 'Refusée';
    if (raw.contains('cours')) return 'En cours';
    return 'Reçue';
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    return _all.where((c) {
      final candidate = (c['nom_candidat']?.toString() ?? c['candidat_nom']?.toString() ?? '').toLowerCase();
      final job = (c['titre_offre']?.toString() ?? c['offre_titre']?.toString() ?? '').toLowerCase();
      final company = (c['nom_entreprise']?.toString() ?? c['entreprise_nom']?.toString() ?? '').toLowerCase();
      final s = _uiStatus(c);
      if (q.isNotEmpty && !candidate.contains(q) && !job.contains(q) && !company.contains(q)) return false;
      if (_statusFilter != 'tous' && s != _statusFilter) return false;
      if (_companyFilter != 'toutes' && company != _companyFilter) return false;
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

  List<String> _companies() {
    final values = <String>{};
    for (final c in _all) {
      final name = (c['nom_entreprise']?.toString() ?? c['entreprise_nom']?.toString() ?? '').toLowerCase().trim();
      if (name.isNotEmpty) values.add(name);
    }
    final list = values.toList()..sort();
    return list;
  }

  Future<void> _setStatus(String id, String uiStatus) async {
    final apiStatus = switch (uiStatus) {
      'En cours' => 'en_cours',
      'Entretien' => 'entretien',
      'Acceptée' => 'acceptee',
      'Refusée' => 'refusee',
      _ => 'reçue',
    };
    try {
      await _service.updateStatut(id, apiStatus);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Statut mis à jour: $uiStatus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final list = _paged;
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestion des Candidatures',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Vue globale des candidatures de la plateforme',
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
                          labelText: 'Rechercher candidat, poste, entreprise...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (v) => setState(() {
                          _query = v;
                          _currentPage = 1;
                        }),
                      ),
                    ),
                    _ApplicationsFilter(
                      label: 'Statut',
                      value: _statusFilter,
                      items: const {
                        'tous': 'Tous',
                        'Reçue': 'Reçue',
                        'En cours': 'En cours',
                        'Entretien': 'Entretien',
                        'Acceptée': 'Acceptée',
                        'Refusée': 'Refusée',
                      },
                      onChanged: (v) => setState(() {
                        _statusFilter = v;
                        _currentPage = 1;
                      }),
                    ),
                    _ApplicationsFilter(
                      label: 'Entreprise',
                      value: _companyFilter,
                      items: {
                        'toutes': 'Toutes',
                        ...{for (final c in _companies()) c: c},
                      },
                      onChanged: (v) => setState(() {
                        _companyFilter = v;
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
                  child: const Center(child: Text('Aucune candidature ne correspond aux filtres.')),
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
                            DataColumn(label: Text('CANDIDAT')),
                            DataColumn(label: Text('POSTE')),
                            DataColumn(label: Text('ENTREPRISE')),
                            DataColumn(label: Text('DATE')),
                            DataColumn(label: Text('STATUT')),
                            DataColumn(label: Text('')),
                          ],
                          rows: list.map((c) => _row(c)).toList(),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Affichage $from-$to sur $totalFiltered candidatures',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                            Row(
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

  DataRow _row(Map<String, dynamic> c) {
    final id = c['id']?.toString() ?? '';
    final candidate = (c['nom_candidat']?.toString() ?? c['candidat_nom']?.toString() ?? '-').trim();
    final job = (c['titre_offre']?.toString() ?? c['offre_titre']?.toString() ?? '-').trim();
    final company = (c['nom_entreprise']?.toString() ?? c['entreprise_nom']?.toString() ?? '-').trim();
    final date = _fmt(c['created_at']?.toString() ?? c['date_candidature']?.toString());
    final status = _uiStatus(c);
    return DataRow(
      cells: [
        DataCell(Text(candidate.isEmpty ? '-' : candidate)),
        DataCell(Text(job.isEmpty ? '-' : job)),
        DataCell(Text(company.isEmpty ? '-' : company)),
        DataCell(Text(date)),
        DataCell(_ApplicationStatusBadge(status: status)),
        DataCell(
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'received') await _setStatus(id, 'Reçue');
              if (v == 'in_progress') await _setStatus(id, 'En cours');
              if (v == 'interview') await _setStatus(id, 'Entretien');
              if (v == 'accepted') await _setStatus(id, 'Acceptée');
              if (v == 'rejected') await _setStatus(id, 'Refusée');
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'received', child: Text('Marquer Reçue')),
              PopupMenuItem(value: 'in_progress', child: Text('Marquer En cours')),
              PopupMenuItem(value: 'interview', child: Text('Marquer Entretien')),
              PopupMenuItem(value: 'accepted', child: Text('Marquer Acceptée')),
              PopupMenuItem(value: 'rejected', child: Text('Marquer Refusée')),
            ],
          ),
        ),
      ],
    );
  }

  String _fmt(String? iso) {
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
        const SnackBar(content: Text('Aucune candidature à exporter.')),
      );
      return;
    }
    final buffer = StringBuffer('candidat,poste,entreprise,date,statut\n');
    for (final c in rows) {
      final candidate = (c['nom_candidat']?.toString() ?? c['candidat_nom']?.toString() ?? '').replaceAll(',', ' ');
      final job = (c['titre_offre']?.toString() ?? c['offre_titre']?.toString() ?? '').replaceAll(',', ' ');
      final company =
          (c['nom_entreprise']?.toString() ?? c['entreprise_nom']?.toString() ?? '').replaceAll(',', ' ');
      final date = (c['created_at']?.toString() ?? c['date_candidature']?.toString() ?? '').replaceAll(',', ' ');
      final status = _uiStatus(c).replaceAll(',', ' ');
      buffer.writeln('$candidate,$job,$company,$date,$status');
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV candidatures copié dans le presse-papiers.')),
    );
  }
}

class _ApplicationsFilter extends StatelessWidget {
  const _ApplicationsFilter({
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

class _ApplicationStatusBadge extends StatelessWidget {
  const _ApplicationStatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFFEFF6FF);
    Color fg = const Color(0xFF1E40AF);
    if (status == 'En cours') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
    } else if (status == 'Entretien') {
      bg = const Color(0xFFF5F3FF);
      fg = const Color(0xFF5B21B6);
    } else if (status == 'Acceptée') {
      bg = const Color(0xFFD1FAE5);
      fg = const Color(0xFF065F46);
    } else if (status == 'Refusée') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFF991B1B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(status, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
