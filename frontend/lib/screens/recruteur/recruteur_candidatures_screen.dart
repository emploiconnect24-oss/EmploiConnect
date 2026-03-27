import 'package:flutter/material.dart';

import '../../services/candidatures_service.dart';
import '../../services/cv_service.dart';
import '../../widgets/responsive_container.dart';
import 'recruteur_candidature_detail_screen.dart';

class RecruteurCandidaturesScreen extends StatefulWidget {
  const RecruteurCandidaturesScreen({super.key});

  @override
  State<RecruteurCandidaturesScreen> createState() => _RecruteurCandidaturesScreenState();
}

class _RecruteurCandidaturesScreenState extends State<RecruteurCandidaturesScreen> {
  final _service = CandidaturesService();
  final _cvService = CvService();
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _all = [];
  bool _loading = true;
  String? _error;
  bool _kanban = false;
  String _statusFilter = 'tous';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  String _normalizeStatus(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('accep')) return 'acceptes';
    if (s.contains('refus')) return 'refuses';
    if (s.contains('entretien')) return 'entretien';
    if (s.contains('cours') || s.contains('examen')) return 'en_examen';
    return 'recues';
  }

  String _statusLabel(String key) {
    switch (key) {
      case 'recues':
        return 'Reçues';
      case 'en_examen':
        return 'En examen';
      case 'entretien':
        return 'Entretien';
      case 'acceptes':
        return 'Acceptés';
      case 'refuses':
        return 'Refusés';
      default:
        return 'Reçues';
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _all.where((c) {
      final id = (c['id']?.toString() ?? '').toLowerCase();
      final offre = (c['offre_titre']?.toString() ?? c['titre_offre']?.toString() ?? '').toLowerCase();
      final user = (c['candidat_nom']?.toString() ?? c['nom']?.toString() ?? '').toLowerCase();
      final st = _normalizeStatus(c['statut']?.toString() ?? '');
      if (q.isNotEmpty && !id.contains(q) && !offre.contains(q) && !user.contains(q)) {
        return false;
      }
      if (_statusFilter != 'tous' && st != _statusFilter) return false;
      return true;
    }).toList();
  }

  Map<String, int> get _counts {
    final map = <String, int>{
      'recues': 0,
      'en_examen': 0,
      'entretien': 0,
      'acceptes': 0,
      'refuses': 0,
    };
    for (final c in _all) {
      final k = _normalizeStatus(c['statut']?.toString() ?? '');
      map[k] = (map[k] ?? 0) + 1;
    }
    return map;
  }

  Future<void> _updateStatus(String id, String toStatus) async {
    try {
      await _service.updateStatut(id, toStatus);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Statut mis à jour')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _showCv(String candidatureId) async {
    try {
      final url = await _cvService.getDownloadUrl(candidatureId: candidatureId);
      if (!mounted) return;
      if (url == null || url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucun CV disponible')));
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Lien CV'),
          content: SelectableText(url),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _exportCsv() {
    final rows = <List<String>>[
      ['id', 'offre', 'candidat', 'statut', 'score'],
      ..._filtered.map((c) {
        return [
          (c['id'] ?? '').toString(),
          (c['offre_titre'] ?? c['titre_offre'] ?? '').toString(),
          (c['candidat_nom'] ?? c['nom'] ?? '').toString(),
          _statusLabel(_normalizeStatus((c['statut'] ?? '').toString())),
          (c['score_compatibilite'] ?? '').toString(),
        ];
      }),
    ];
    final csv = rows.map((r) => r.map((e) => '"${e.replaceAll('"', '""')}"').join(',')).join('\n');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export CSV'),
        content: SelectableText(csv),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
      ),
    );
  }

  Future<void> _openDetail(String id) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecruteurCandidatureDetailScreen(candidatureId: id),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Candidatures reçues', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              SizedBox(height: 6),
              Text('Suivez vos candidatures en vue liste ou kanban.'),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(value: false, icon: Icon(Icons.view_list_rounded), label: Text('Liste')),
            ButtonSegment<bool>(value: true, icon: Icon(Icons.view_kanban_outlined), label: Text('Kanban')),
          ],
          selected: {_kanban},
          onSelectionChanged: (v) => setState(() => _kanban = v.first),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(onPressed: _exportCsv, icon: const Icon(Icons.download_outlined), label: const Text('Exporter')),
      ],
    );
  }

  Widget _statusPills(Map<String, int> counts) {
    const keys = ['recues', 'en_examen', 'entretien', 'acceptes', 'refuses'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text('Toutes (${_filtered.length})'),
          selected: _statusFilter == 'tous',
          onSelected: (_) => setState(() => _statusFilter = 'tous'),
        ),
        ...keys.map(
          (k) => ChoiceChip(
            label: Text('${_statusLabel(k)} (${counts[k] ?? 0})'),
            selected: _statusFilter == k,
            onSelected: (_) => setState(() => _statusFilter = k),
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Candidat')),
            DataColumn(label: Text('Offre')),
            DataColumn(label: Text('Score')),
            DataColumn(label: Text('Statut')),
            DataColumn(label: Text('Actions')),
          ],
          rows: list.map((c) {
            final id = (c['id'] ?? '').toString();
            final score = c['score_compatibilite']?.toString() ?? '-';
            final offer = (c['offre_titre'] ?? c['titre_offre'] ?? 'Offre').toString();
            final user = (c['candidat_nom'] ?? c['nom'] ?? 'Candidat').toString();
            final key = _normalizeStatus((c['statut'] ?? '').toString());
            return DataRow(
              cells: [
                DataCell(Text(user), onTap: () => _openDetail(id)),
                DataCell(Text(offer)),
                DataCell(Text(score)),
                DataCell(_StatusBadge(label: _statusLabel(key), keyName: key)),
                DataCell(
                  Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        tooltip: 'Détail',
                        onPressed: () => _openDetail(id),
                        icon: const Icon(Icons.open_in_new),
                      ),
                      IconButton(
                        tooltip: 'Voir CV',
                        onPressed: () => _showCv(id),
                        icon: const Icon(Icons.description_outlined),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz),
                        onSelected: (v) {
                          if (v == 'cv') {
                            _showCv(id);
                            return;
                          }
                          _updateStatus(id, v);
                        },
                        itemBuilder: (ctx) => const [
                          PopupMenuItem(value: 'cv', child: Text('Voir CV')),
                          PopupMenuItem(value: 'en_cours', child: Text('Passer en examen')),
                          PopupMenuItem(value: 'entretien', child: Text('Planifier entretien')),
                          PopupMenuItem(value: 'acceptee', child: Text('Accepter')),
                          PopupMenuItem(value: 'refusee', child: Text('Refuser')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildKanban(List<Map<String, dynamic>> list, Map<String, int> counts) {
    const keys = ['recues', 'en_examen', 'entretien', 'acceptes', 'refuses'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: keys.map((k) {
          final columnItems = list.where((e) => _normalizeStatus(e['statut']?.toString() ?? '') == k).toList();
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_statusLabel(k)} (${counts[k] ?? 0})', style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (columnItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Aucune candidature')),
                  )
                else
                  ...columnItems.map((c) {
                    final id = (c['id'] ?? '').toString();
                    final score = c['score_compatibilite']?.toString() ?? '-';
                    final user = (c['candidat_nom'] ?? c['nom'] ?? 'Candidat').toString();
                    final offer = (c['offre_titre'] ?? c['titre_offre'] ?? 'Offre').toString();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(offer, maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('Score: $score'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: () => _showCv(id),
                                child: const Text('Voir CV'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => _openDetail(id),
                                child: const Text('Détail'),
                              ),
                              const SizedBox(width: 8),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.swap_horiz),
                                onSelected: (v) => _updateStatus(id, v),
                                itemBuilder: (ctx) => const [
                                  PopupMenuItem(value: 'en_cours', child: Text('En examen')),
                                  PopupMenuItem(value: 'entretien', child: Text('Entretien')),
                                  PopupMenuItem(value: 'acceptee', child: Text('Accepté')),
                                  PopupMenuItem(value: 'refusee', child: Text('Refusé')),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final list = _filtered;
    final counts = _counts;

    return ResponsiveContainer(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 20),
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 320,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Rechercher candidat / offre / id',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                        ),
                      ),
                    ),
                    _statusPills(counts),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Aucune candidature trouvée')),
                ),
              )
            else if (_kanban)
              _buildKanban(list, counts)
            else
              _buildList(list),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.keyName});
  final String label;
  final String keyName;

  Color _bg() {
    switch (keyName) {
      case 'acceptes':
        return const Color(0xFFD1FAE5);
      case 'refuses':
        return const Color(0xFFFEE2E2);
      case 'entretien':
        return const Color(0xFFEDE9FE);
      case 'en_examen':
        return const Color(0xFFDBEAFE);
      default:
        return const Color(0xFFFFEDD5);
    }
  }

  Color _fg() {
    switch (keyName) {
      case 'acceptes':
        return const Color(0xFF047857);
      case 'refuses':
        return const Color(0xFFB91C1C);
      case 'entretien':
        return const Color(0xFF6D28D9);
      case 'en_examen':
        return const Color(0xFF1D4ED8);
      default:
        return const Color(0xFFB45309);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _bg(), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: _fg(), fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
