import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../widgets/responsive_container.dart';

class AdminSignalementsScreen extends StatefulWidget {
  const AdminSignalementsScreen({super.key});

  @override
  State<AdminSignalementsScreen> createState() => _AdminSignalementsScreenState();
}

class _AdminSignalementsScreenState extends State<AdminSignalementsScreen> {
  final _admin = AdminService();
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;
  String _selectedType = 'Tous';

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
      final r = await _admin.getSignalements(limit: 100);
      setState(() {
        _list = r.signalements;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _traiter(String id, String statut, String successMessage) async {
    try {
      await _admin.traiterSignalement(id, statut);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
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

    final filtered = _filtered;
    final urgentCount = filtered.where((e) => _priorityOf(e) == _ReportPriority.urgent).length;
    final inProgressCount = filtered.where((e) => _priorityOf(e) == _ReportPriority.medium).length;
    final resolvedCount = filtered.where((e) => _priorityOf(e) == _ReportPriority.low).length;

    return ResponsiveContainer(
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modération & Signalements',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '$urgentCount signalements urgents en attente de traitement',
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ModerationCounterCard(
                    title: 'Urgents',
                    count: urgentCount,
                    color: const Color(0xFFEF4444),
                    bgColor: const Color(0xFFFEE2E2),
                    icon: Icons.priority_high_rounded,
                  ),
                  _ModerationCounterCard(
                    title: 'En cours',
                    count: inProgressCount,
                    color: const Color(0xFFF59E0B),
                    bgColor: const Color(0xFFFEF3C7),
                    icon: Icons.timelapse_rounded,
                  ),
                  _ModerationCounterCard(
                    title: 'Résolus',
                    count: resolvedCount,
                    color: const Color(0xFF10B981),
                    bgColor: const Color(0xFFD1FAE5),
                    icon: Icons.verified_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in _allTypes)
                    ChoiceChip(
                      label: Text(type),
                      selected: _selectedType == type,
                      onSelected: (_) => setState(() => _selectedType = type),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(child: Text('Aucun signalement pour ce filtre.')),
                )
              else
                ...filtered.map(_buildReportCard),
            ],
          ),
        ),
      ),
    );
  }

  List<String> get _allTypes {
    final values = <String>{'Tous'};
    for (final s in _list) {
      values.add(_typeLabel(s));
    }
    final list = values.toList();
    list.sort();
    if (list.remove('Tous')) {
      list.insert(0, 'Tous');
    }
    return list;
  }

  List<Map<String, dynamic>> get _filtered {
    if (_selectedType == 'Tous') return _list;
    return _list.where((s) => _typeLabel(s) == _selectedType).toList();
  }

  String _typeLabel(Map<String, dynamic> s) {
    final raw = (s['type_objet']?.toString() ?? '').toLowerCase();
    if (raw.contains('offre')) return 'Offre frauduleuse';
    if (raw.contains('contenu')) return 'Contenu inapproprié';
    if (raw.contains('compte')) return 'Compte suspect';
    if (raw.contains('spam')) return 'Spam';
    return 'Autre';
  }

  _ReportPriority _priorityOf(Map<String, dynamic> s) {
    final statut = (s['statut']?.toString() ?? '').toLowerCase();
    final count = int.tryParse((s['nombre_signalements'] ?? s['report_count'] ?? 1).toString()) ?? 1;
    if (statut == 'traite' || statut == 'resolu') return _ReportPriority.low;
    if (count >= 3) return _ReportPriority.urgent;
    return _ReportPriority.medium;
  }

  Widget _buildReportCard(Map<String, dynamic> s) {
    final id = s['id']?.toString() ?? '';
    final priority = _priorityOf(s);
    final type = _typeLabel(s);
    final reason = (s['raison']?.toString() ?? 'Aucun détail fourni').trim();
    final count = (s['nombre_signalements'] ?? s['report_count'] ?? 1).toString();
    final timeAgo = (s['il_y_a']?.toString() ?? s['created_at']?.toString() ?? 'Récemment').trim();

    final leftColor = switch (priority) {
      _ReportPriority.urgent => const Color(0xFFEF4444),
      _ReportPriority.medium => const Color(0xFFF59E0B),
      _ReportPriority.low => const Color(0xFF10B981),
    };

    final priorityLabel = switch (priority) {
      _ReportPriority.urgent => 'URGENT',
      _ReportPriority.medium => 'MOYEN',
      _ReportPriority.low => 'RÉSOLU',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: leftColor, width: 4)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: leftColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    priorityLabel,
                    style: TextStyle(color: leftColor, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Text(type, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(timeAgo, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Signalé par $count utilisateur(s)',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"$reason"',
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Voir la ressource signalée (connexion détail à faire).')),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Voir'),
                ),
                FilledButton.icon(
                  onPressed: () => _traiter(id, 'rejete', 'Signalement rejeté / contenu supprimé'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Supprimer'),
                ),
                TextButton(
                  onPressed: () => _traiter(id, 'traite', 'Signalement marqué comme traité'),
                  child: const Text('Ignorer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _ReportPriority { urgent, medium, low }

class _ModerationCounterCard extends StatelessWidget {
  const _ModerationCounterCard({
    required this.title,
    required this.count,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  final String title;
  final int count;
  final Color color;
  final Color bgColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
