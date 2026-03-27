import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/offres_service.dart';
import '../../widgets/responsive_container.dart';
import '../entreprise/offre_form_screen.dart';

class AdminJobsScreen extends StatefulWidget {
  const AdminJobsScreen({super.key});

  @override
  State<AdminJobsScreen> createState() => _AdminJobsScreenState();
}

class _AdminJobsScreenState extends State<AdminJobsScreen> {
  final _service = OffresService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _all = [];

  String _query = '';
  String _statusFilter = 'tous';
  String _cityFilter = 'toutes';
  String _sectorFilter = 'tous';
  String _activeTab = 'Toutes';
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
      final res = await _service.getOffres(limit: 200, offset: 0);
      setState(() {
        _all = res.offres;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _statusOf(Map<String, dynamic> o) {
    final raw = (o['statut']?.toString() ?? '').toLowerCase().trim();
    if (raw.contains('attente')) return 'En attente';
    if (raw.contains('refus')) return 'Refusée';
    if (raw.contains('expire')) return 'Expirée';
    if (raw.contains('vedette') || (o['featured'] == true)) return 'En vedette';
    if (raw.contains('publie')) return 'Publiée';
    return 'Publiée';
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    return _all.where((o) {
      final title = (o['titre']?.toString() ?? '').toLowerCase();
      final entreprise = (o['nom_entreprise']?.toString() ?? o['entreprise_nom']?.toString() ?? '').toLowerCase();
      final status = _statusOf(o);
      final city = (o['localisation']?.toString() ?? '').trim();
      final sector = (o['domaine']?.toString() ?? '').trim();

      if (q.isNotEmpty && !title.contains(q) && !entreprise.contains(q)) return false;
      if (_statusFilter != 'tous' && status != _statusFilter) return false;
      if (_cityFilter != 'toutes' && city.toLowerCase() != _cityFilter.toLowerCase()) return false;
      if (_sectorFilter != 'tous' && sector.toLowerCase() != _sectorFilter.toLowerCase()) return false;

      if (_activeTab == 'En attente' && status != 'En attente') return false;
      if (_activeTab == 'Publiées' && status != 'Publiée') return false;
      if (_activeTab == 'Refusées' && status != 'Refusée') return false;
      if (_activeTab == 'Expirées' && status != 'Expirée') return false;

      return true;
    }).toList();
  }

  Map<String, int> get _tabCounts {
    int pending = 0;
    int published = 0;
    int refused = 0;
    int expired = 0;
    for (final o in _all) {
      final s = _statusOf(o);
      if (s == 'En attente') pending++;
      if (s == 'Publiée') published++;
      if (s == 'Refusée') refused++;
      if (s == 'Expirée') expired++;
    }
    return {
      'Toutes': _all.length,
      'En attente': pending,
      'Publiées': published,
      'Refusées': refused,
      'Expirées': expired,
    };
  }

  int get _totalPages {
    final c = _filtered.length;
    if (c == 0) return 1;
    return (c / _perPage).ceil();
  }

  List<Map<String, dynamic>> get _paged {
    final list = _filtered;
    final start = (_currentPage - 1) * _perPage;
    if (start >= list.length) return const [];
    final end = (start + _perPage).clamp(0, list.length);
    return list.sublist(start, end);
  }

  List<String> _cities() {
    final set = <String>{};
    for (final o in _all) {
      final v = (o['localisation']?.toString() ?? '').trim();
      if (v.isNotEmpty) set.add(v);
    }
    final l = set.toList()..sort();
    return l;
  }

  List<String> _sectors() {
    final set = <String>{};
    for (final o in _all) {
      final v = (o['domaine']?.toString() ?? '').trim();
      if (v.isNotEmpty) set.add(v);
    }
    final l = set.toList()..sort();
    return l;
  }

  Future<void> _setStatus(Map<String, dynamic> offer, String target) async {
    final id = offer['id']?.toString();
    if (id == null || id.isEmpty) return;
    final ok = await _confirm(
      title: 'Confirmer',
      message: 'Appliquer le statut "$target" pour cette offre ?',
      confirmLabel: 'Confirmer',
      confirmColor: const Color(0xFF1A56DB),
    );
    if (!ok) return;
    try {
      await _service.updateOffre(id, {'statut': _toBackendStatus(target)});
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Statut mis à jour : $target')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  String _toBackendStatus(String ui) {
    switch (ui) {
      case 'En attente':
        return 'en_attente';
      case 'Refusée':
        return 'refusee';
      case 'Expirée':
        return 'expiree';
      case 'En vedette':
        return 'en_vedette';
      default:
        return 'publiee';
    }
  }

  Future<void> _deleteOffer(Map<String, dynamic> offer) async {
    final id = offer['id']?.toString();
    if (id == null || id.isEmpty) return;
    final ok = await _confirm(
      title: 'Supprimer cette offre ?',
      message: 'Cette action est irreversible.',
      confirmLabel: 'Supprimer',
      confirmColor: const Color(0xFFEF4444),
    );
    if (!ok) return;
    try {
      await _service.deleteOffre(id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offre supprimée')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final v = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: confirmColor, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return v == true;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final tabs = _tabCounts;
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
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestion des Offres d\'emploi',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                      SizedBox(height: 4),
                      Text('Validation, modification et modération des offres',
                          style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Rechercher une offre ou une entreprise...',
                        prefixIcon: Icon(Icons.search),
                      ),
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
                        _JobsFilter(
                          label: 'Statut',
                          value: _statusFilter,
                          items: const {
                            'tous': 'Tous',
                            'Publiée': 'Publiée',
                            'En attente': 'En attente',
                            'Refusée': 'Refusée',
                            'Expirée': 'Expirée',
                            'En vedette': 'En vedette',
                          },
                          onChanged: (v) => setState(() {
                            _statusFilter = v;
                            _currentPage = 1;
                          }),
                        ),
                        _JobsFilter(
                          label: 'Ville',
                          value: _cityFilter,
                          items: {
                            'toutes': 'Toutes',
                            ...{for (final city in _cities()) city.toLowerCase(): city},
                          },
                          onChanged: (v) => setState(() {
                            _cityFilter = v;
                            _currentPage = 1;
                          }),
                        ),
                        _JobsFilter(
                          label: 'Secteur',
                          value: _sectorFilter,
                          items: {
                            'tous': 'Tous',
                            ...{for (final s in _sectors()) s.toLowerCase(): s},
                          },
                          onChanged: (v) => setState(() {
                            _sectorFilter = v;
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
                        for (final tab in const ['Toutes', 'En attente', 'Publiées', 'Refusées', 'Expirées'])
                          ChoiceChip(
                            label: Text('$tab (${tabs[tab] ?? 0})'),
                            selected: _activeTab == tab,
                            onSelected: (_) => setState(() {
                              _activeTab = tab;
                              _currentPage = 1;
                            }),
                          ),
                      ],
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
                  child: const Center(child: Text('Aucune offre ne correspond aux filtres.')),
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
                            DataColumn(label: Text('OFFRE')),
                            DataColumn(label: Text('SECTEUR')),
                            DataColumn(label: Text('VILLE')),
                            DataColumn(label: Text('TYPE')),
                            DataColumn(label: Text('STATUT')),
                            DataColumn(label: Text('CANDIDATURES')),
                            DataColumn(label: Text('DATE')),
                            DataColumn(label: Text('')),
                          ],
                          rows: list.map((o) => _buildRow(o)).toList(),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Affichage $from-$to sur $totalFiltered offres',
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

  DataRow _buildRow(Map<String, dynamic> o) {
    final title = o['titre']?.toString() ?? '-';
    final company = (o['nom_entreprise']?.toString() ?? o['entreprise_nom']?.toString() ?? '').trim();
    final status = _statusOf(o);
    final secteur = (o['domaine']?.toString() ?? '-').trim();
    final ville = (o['localisation']?.toString() ?? '-').trim();
    final type = (o['type_contrat']?.toString() ?? '-').trim();
    final candidates = (o['nombre_candidatures'] ?? o['candidatures_count'] ?? 0).toString();
    final date = _fmtDate(o['date_publication']?.toString() ?? o['created_at']?.toString());
    return DataRow(
      cells: [
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                company.isEmpty ? 'Entreprise inconnue' : company,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        DataCell(Text(secteur.isEmpty ? '-' : secteur)),
        DataCell(Text(ville.isEmpty ? '-' : ville)),
        DataCell(Text(type.isEmpty ? '-' : type)),
        DataCell(_StatusBadge(label: status)),
        DataCell(Text(candidates)),
        DataCell(Text(date)),
        DataCell(
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'validate') await _setStatus(o, 'Publiée');
              if (v == 'edit' && mounted) {
                final id = o['id']?.toString();
                if (id == null || id.isEmpty) return;
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => OffreFormScreen(offreId: id)),
                );
                if (mounted) {
                  await _load();
                }
              }
              if (v == 'feature') await _setStatus(o, 'En vedette');
              if (v == 'archive') await _setStatus(o, 'Expirée');
              if (v == 'delete') await _deleteOffer(o);
            },
            itemBuilder: (context) => [
              if (status == 'En attente')
                const PopupMenuItem<String>(
                  value: 'validate',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.check_circle_outline, color: Color(0xFF10B981)),
                    title: Text('Valider'),
                  ),
                ),
              const PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Modifier'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'feature',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.star_outline, color: Color(0xFFF59E0B)),
                  title: Text('Mettre en vedette'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'archive',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.lock_outline),
                  title: Text('Archiver'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                  title: Text('Supprimer'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmtDate(String? iso) {
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
        const SnackBar(content: Text('Aucune offre à exporter.')),
      );
      return;
    }
    final buffer =
        StringBuffer('titre,entreprise,secteur,ville,type_contrat,statut,candidatures,date_publication\n');
    for (final o in rows) {
      final title = (o['titre']?.toString() ?? '').replaceAll(',', ' ');
      final company =
          (o['nom_entreprise']?.toString() ?? o['entreprise_nom']?.toString() ?? '').replaceAll(',', ' ');
      final secteur = (o['domaine']?.toString() ?? '').replaceAll(',', ' ');
      final ville = (o['localisation']?.toString() ?? '').replaceAll(',', ' ');
      final type = (o['type_contrat']?.toString() ?? '').replaceAll(',', ' ');
      final statut = _statusOf(o).replaceAll(',', ' ');
      final candidatures = (o['nombre_candidatures'] ?? o['candidatures_count'] ?? 0).toString();
      final date = (o['date_publication']?.toString() ?? o['created_at']?.toString() ?? '').replaceAll(',', ' ');
      buffer.writeln('$title,$company,$secteur,$ville,$type,$statut,$candidatures,$date');
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV offres copié dans le presse-papiers.')),
    );
  }
}

class _JobsFilter extends StatelessWidget {
  const _JobsFilter({
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF475569);
    if (label == 'Publiée') {
      bg = const Color(0xFFD1FAE5);
      fg = const Color(0xFF065F46);
    } else if (label == 'En attente') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
    } else if (label == 'Refusée') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFF991B1B);
    } else if (label == 'En vedette') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
