import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../services/download_service.dart';
import '../../widgets/responsive_container.dart';
import 'widgets/admin_page_shimmer.dart';

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  final _admin = AdminService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _stats = const {};
  List<Map<String, dynamic>> _topEntreprises = const [];
  String _period = '30j';
  bool _isExporting = false;

  String _apiPeriod(String ui) {
    switch (ui) {
      case '7j':
        return '7d';
      case '30j':
        return '30d';
      case '3m':
        return '3m';
      case '6m':
        return '6m';
      case '1an':
        return '1an';
      default:
        return '30d';
    }
  }

  Map<String, dynamic>? get _dataNested => _stats['data'] as Map<String, dynamic>?;

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
      final per = _apiPeriod(_period);
      final s = await _admin.getStatistiques(periode: per);
      final top = await _admin.getTopEntreprises();
      final rawTop = top['data'];
      final listTop = rawTop is List
          ? rawTop.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : const <Map<String, dynamic>>[];
      setState(() {
        _stats = s;
        _topEntreprises = listTop;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int _v(String key) {
    final value = _stats[key];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _conversionPercent() {
    final apps = _v('nombre_candidatures');
    final offers = _v('nombre_offres_total');
    if (apps == 0 || offers == 0) return 0;
    final val = ((apps / (offers * 10)) * 100).round();
    return val.clamp(0, 100);
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
    final per = _apiPeriod(_period);
    final fileName = 'stats_emploiconnect_$per.csv';
    setState(() => _isExporting = true);
    try {
      await DownloadService.downloadCsvFromApi(
        apiPathAndQuery: '/admin/statistiques/export?periode=${Uri.encodeQueryComponent(per)}',
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
      if (mounted) setState(() => _isExporting = false);
    }
  }

  List<({String label, int value, String? trend})> _kpiRows() {
    final nested = _dataNested?['kpis'] as Map<String, dynamic>?;
    if (nested != null) {
      int valOf(String key) {
        final block = nested[key] as Map<String, dynamic>?;
        final v = block?['valeur'];
        if (v is int) return v;
        return int.tryParse(v?.toString() ?? '') ?? 0;
      }

      String? trendOf(String key) {
        final block = nested[key] as Map<String, dynamic>?;
        final t = block?['tendance'];
        if (t == null) return null;
        return '${t is num ? t.round() : t}%';
      }

      return [
        (label: 'Nouveaux utilisateurs', value: valOf('nouveaux_utilisateurs'), trend: trendOf('nouveaux_utilisateurs')),
        (label: 'Nouvelles offres', value: valOf('nouvelles_offres'), trend: trendOf('nouvelles_offres')),
        (label: 'Nouvelles candidatures', value: valOf('nouvelles_candidatures'), trend: trendOf('nouvelles_candidatures')),
        (label: 'Taux conversion (approx.)', value: _conversionPercent(), trend: null),
      ];
    }
    return [
      (label: 'Utilisateurs totaux', value: _v('nombre_chercheurs') + _v('nombre_entreprises') + _v('nombre_admins'), trend: null),
      (label: 'Offres (total)', value: _v('nombre_offres_total'), trend: null),
      (label: 'Candidatures', value: _v('nombre_candidatures'), trend: null),
      (label: 'Taux conversion', value: _conversionPercent(), trend: null),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ResponsiveContainer(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: const AdminStatisticsShimmer(),
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

    final kpis = _kpiRows();

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
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statistiques & Analytiques',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Suivi des KPIs et des tendances de la plateforme',
                          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final p in const ['7j', '30j', '3m', '6m', '1an'])
                        ChoiceChip(
                          label: Text(p),
                          selected: _period == p,
                          onSelected: (_) {
                            setState(() => _period = p);
                            _load();
                          },
                        ),
                      OutlinedButton.icon(
                        onPressed: _isExporting ? null : _exportCsv,
                        icon: _isExporting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.download_outlined, size: 18),
                        label: Text(_isExporting ? 'Export…' : 'Exporter CSV'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, c) {
                  final cols = c.maxWidth >= 1200 ? 4 : (c.maxWidth >= 760 ? 2 : 1);
                  return GridView.builder(
                    itemCount: kpis.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.3,
                    ),
                    itemBuilder: (_, i) => _KpiCard(
                      label: kpis[i].label,
                      value: kpis[i].value,
                      trend: kpis[i].trend,
                    ),
                  );
                },
              ),
              if (_topEntreprises.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Top entreprises (nombre d’offres)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _topEntreprises.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final e = _topEntreprises[i];
                      final nom = e['nom']?.toString() ?? '—';
                      final nb = e['nb'] is int ? e['nb'] as int : int.tryParse(e['nb']?.toString() ?? '') ?? 0;
                      return Container(
                        width: 200,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(nom, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('$nb offre(s)', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, c) {
                  if (c.maxWidth < 980) {
                    return Column(
                      children: [
                        _UsersGrowthChartCard(evolution: _evolutionList),
                        const SizedBox(height: 12),
                        _SectorBarChartCard(secteurs: _secteurCounts),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _UsersGrowthChartCard(evolution: _evolutionList)),
                      const SizedBox(width: 12),
                      Expanded(child: _SectorBarChartCard(secteurs: _secteurCounts)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              _GeoBarChartCard(villes: _villeCounts),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _evolutionList {
    final raw = _dataNested?['evolution_par_jour'] as List<dynamic>?;
    if (raw == null) return const [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Map<String, int> get _secteurCounts {
    final m = _dataNested?['distribution_secteurs'];
    if (m is! Map) return const {};
    return m.map((k, v) => MapEntry(k.toString(), int.tryParse(v.toString()) ?? 0));
  }

  Map<String, int> get _villeCounts {
    final m = _dataNested?['distribution_villes'];
    if (m is! Map) return const {};
    return m.map((k, v) => MapEntry(k.toString(), int.tryParse(v.toString()) ?? 0));
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value, this.trend});
  final String label;
  final int value;
  final String? trend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          if (trend != null) ...[
            const SizedBox(height: 4),
            Text('Tendance: $trend', style: const TextStyle(fontSize: 12, color: Color(0xFF1A56DB))),
          ],
        ],
      ),
    );
  }
}

class _UsersGrowthChartCard extends StatelessWidget {
  const _UsersGrowthChartCard({required this.evolution});

  final List<Map<String, dynamic>> evolution;

  @override
  Widget build(BuildContext context) {
    final spotsU = <FlSpot>[];
    final spotsO = <FlSpot>[];
    for (var i = 0; i < evolution.length; i++) {
      final e = evolution[i];
      final u = (e['utilisateurs'] is num) ? (e['utilisateurs'] as num).toDouble() : 0.0;
      final o = (e['offres'] is num) ? (e['offres'] as num).toDouble() : 0.0;
      spotsU.add(FlSpot(i.toDouble(), u));
      spotsO.add(FlSpot(i.toDouble(), o));
    }
    final maxY = [
      ...spotsU.map((s) => s.y),
      ...spotsO.map((s) => s.y),
      1.0,
    ].fold<double>(0, (a, b) => a > b ? a : b);

    return Container(
      height: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Inscriptions & offres (période sélectionnée)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Expanded(
            child: spotsU.isEmpty
                ? const Center(child: Text('Pas de données', style: TextStyle(color: Color(0xFF64748B))))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY > 5 ? (maxY / 4).ceilToDouble() : 1,
                        getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= evolution.length) return const SizedBox.shrink();
                              final d = evolution[i]['date']?.toString() ?? '';
                              final short = d.length >= 10 ? d.substring(8, 10) : d;
                              return Text(short, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)));
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, _) => Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: maxY < 1 ? 4 : maxY * 1.1,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spotsU,
                          isCurved: true,
                          color: const Color(0xFF1A56DB),
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                        ),
                        LineChartBarData(
                          spots: spotsO,
                          isCurved: true,
                          color: const Color(0xFF10B981),
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 800),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectorBarChartCard extends StatelessWidget {
  const _SectorBarChartCard({required this.secteurs});

  final Map<String, int> secteurs;

  @override
  Widget build(BuildContext context) {
    final entries = secteurs.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(8).toList();
    final maxY = top.isEmpty
        ? 1.0
        : top.map((e) => e.value.toDouble()).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Offres par secteur (domaine)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Expanded(
            child: top.isEmpty
                ? const Center(child: Text('Pas de données', style: TextStyle(color: Color(0xFF64748B))))
                : BarChart(
                    BarChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY > 5 ? (maxY / 4).ceilToDouble() : 1,
                        getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, _) => Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              final i = value.toInt();
                              if (i < 0 || i >= top.length) return const SizedBox.shrink();
                              final label = top[i].key;
                              final short = label.length > 10 ? '${label.substring(0, 8)}…' : label;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(short, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      maxY: maxY < 1 ? 4 : maxY * 1.1,
                      barGroups: [
                        for (var i = 0; i < top.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: top[i].value.toDouble(),
                                width: 18,
                                color: const Color(0xFF1A56DB),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 800),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GeoBarChartCard extends StatelessWidget {
  const _GeoBarChartCard({required this.villes});

  final Map<String, int> villes;

  @override
  Widget build(BuildContext context) {
    final entries = villes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(12).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Répartition géographique (offres actives)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (top.isEmpty)
            const Text('Pas de données', style: TextStyle(color: Color(0xFF64748B)))
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final e in top)
                  _CityPill(city: e.key.isEmpty ? '—' : e.key, value: e.value),
              ],
            ),
        ],
      ),
    );
  }
}

class _CityPill extends StatelessWidget {
  const _CityPill({required this.city, required this.value});
  final String city;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text('$city  •  $value', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
    );
  }
}
