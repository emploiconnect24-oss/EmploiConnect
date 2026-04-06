import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/recruteur_service.dart';

class RecruteurStatisticsConnectedScreen extends StatefulWidget {
  const RecruteurStatisticsConnectedScreen({super.key});

  @override
  State<RecruteurStatisticsConnectedScreen> createState() => _RecruteurStatisticsConnectedScreenState();
}

class _RecruteurStatisticsConnectedScreenState extends State<RecruteurStatisticsConnectedScreen> {
  static const _primary = Color(0xFF1A56DB);
  final _svc = RecruteurService();
  Map<String, dynamic>? _stats;
  String _periode = '30d';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = context.read<AuthProvider>().token ?? '';
    final res = await _svc.getStats(token, periode: _periode);
    setState(() {
      _stats = res['data'] as Map<String, dynamic>?;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _primary));
    final kpis = _stats?['kpis'] as Map<String, dynamic>? ?? {};
    final evol = List<Map<String, dynamic>>.from(_stats?['evolution_par_jour'] ?? const []);
    final perf = List<Map<String, dynamic>>.from(_stats?['performance_par_offre'] ?? const []);
    final rep = Map<String, dynamic>.from(_stats?['repartition_statuts'] ?? const {});
    final insights = Map<String, dynamic>.from(_stats?['insights'] ?? const {});
    final alerts = List<String>.from(insights['alertes'] ?? const []);

    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statistiques',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Suivi performance offres et candidatures',
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.9)),
                        ),
                      ],
                    ),
                  ),
                  for (final p in const ['7d', '30d', '3m'])
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ChoiceChip(
                        label: Text(p),
                        selected: _periode == p,
                        onSelected: (_) {
                          setState(() => _periode = p);
                          _load();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _kpi('Candidatures', '${kpis['candidatures']?['valeur'] ?? 0}', kpis['candidatures']?['tendance']),
                    _kpi('Vues', '${kpis['vues']?['valeur'] ?? 0}', kpis['vues']?['tendance']),
                    _kpi('Taux réponse', '${kpis['taux_reponse']?['valeur'] ?? 0}%'),
                    _kpi('Score IA', '${kpis['score_ia_moyen']?['valeur'] ?? 0}%'),
                  ],
                ),
                const SizedBox(height: 14),
                _panel(
                  title: 'Évolution quotidienne',
                  child: evol.isEmpty
                      ? const Text('Aucune donnée')
                      : SizedBox(
                          height: 170,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: evol.map((e) {
                              final c = (e['candidatures'] as num?)?.toInt() ?? 0;
                              final v = (e['vues'] as num?)?.toInt() ?? 0;
                              final h = (c + v).clamp(0, 20) * 6.0 + 8;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 1),
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      height: h,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDBEAFE),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                ),
                const SizedBox(height: 14),
                _panel(
                  title: 'Répartition statuts candidatures',
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _pill('En attente', '${rep['en_attente'] ?? 0}', const Color(0xFF1A56DB)),
                      _pill('En examen', '${rep['en_cours'] ?? 0}', const Color(0xFFF59E0B)),
                      _pill('Entretien', '${rep['entretien'] ?? 0}', const Color(0xFF8B5CF6)),
                      _pill('Acceptées', '${rep['acceptees'] ?? 0}', const Color(0xFF10B981)),
                      _pill('Refusées', '${rep['refusees'] ?? 0}', const Color(0xFFEF4444)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _panel(
                  title: 'Performance par offre',
                  child: perf.isEmpty
                      ? const Text('Aucune offre')
                      : Column(
                          children: perf.take(10).map((o) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text((o['titre'] ?? 'Offre').toString()),
                              subtitle: Text(
                                'Candidatures: ${o['nb_candidatures'] ?? 0} · Conversion: ${o['taux_conversion'] ?? 0}%',
                              ),
                              trailing: Text('Vues ${o['nb_vues'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            );
                          }).toList(),
                        ),
                ),
                if (alerts.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _panel(
                    title: 'Alertes',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: alerts
                          .map((a) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(a)),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpi(String label, String value, [dynamic trend]) => Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
              if (trend != null) ...[
                const SizedBox(width: 8),
                Text(
                  '${trend is num ? trend.toInt() : trend}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: (trend is num && trend < 0) ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                ),
              ],
            ],
          ),
        ]),
      );

  Widget _panel({required String title, required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );

  Widget _pill(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(color: color)),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ]),
      );
}
