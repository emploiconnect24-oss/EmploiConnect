import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../widgets/responsive_container.dart';

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
  String _period = '30j';

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
      final s = await _admin.getStatistiques();
      setState(() {
        _stats = s;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final kpis = [
      ('Utilisateurs totaux', _v('nombre_chercheurs') + _v('nombre_entreprises') + _v('nombre_admins')),
      ('Offres ce mois', _v('nombre_offres_total')),
      ('Candidatures', _v('nombre_candidatures')),
      ('Taux conversion', _conversionPercent()),
    ];

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
                    children: [
                      for (final p in const ['7j', '30j', '3m', '6m', '1an'])
                        ChoiceChip(
                          label: Text(p),
                          selected: _period == p,
                          onSelected: (_) => setState(() => _period = p),
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
                    itemBuilder: (_, i) => _KpiCard(label: kpis[i].$1, value: kpis[i].$2),
                  );
                },
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, c) {
                  if (c.maxWidth < 980) {
                    return const Column(
                      children: [
                        _UsersGrowthChartCard(),
                        SizedBox(height: 12),
                        _SectorBarChartCard(),
                      ],
                    );
                  }
                  return const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _UsersGrowthChartCard()),
                      SizedBox(width: 12),
                      Expanded(child: _SectorBarChartCard()),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              const _GeoBarChartCard(),
            ],
          ),
        ),
      ),
    );
  }

  int _conversionPercent() {
    final apps = _v('nombre_candidatures');
    final offers = _v('nombre_offres_total');
    if (apps == 0 || offers == 0) return 0;
    final val = ((apps / (offers * 10)) * 100).round();
    return val.clamp(0, 100);
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value});
  final String label;
  final int value;

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
        ],
      ),
    );
  }
}

class _UsersGrowthChartCard extends StatelessWidget {
  const _UsersGrowthChartCard();

  @override
  Widget build(BuildContext context) {
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
          const Text('Croissance utilisateurs (12 mois)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        const labels = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                        final i = value.toInt();
                        if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                        return Text(labels[i], style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 8),
                      FlSpot(1, 12),
                      FlSpot(2, 15),
                      FlSpot(3, 18),
                      FlSpot(4, 22),
                      FlSpot(5, 20),
                      FlSpot(6, 26),
                      FlSpot(7, 30),
                      FlSpot(8, 34),
                      FlSpot(9, 38),
                      FlSpot(10, 40),
                      FlSpot(11, 45),
                    ],
                    isCurved: true,
                    color: const Color(0xFF1A56DB),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 4),
                      FlSpot(1, 7),
                      FlSpot(2, 9),
                      FlSpot(3, 10),
                      FlSpot(4, 12),
                      FlSpot(5, 14),
                      FlSpot(6, 16),
                      FlSpot(7, 18),
                      FlSpot(8, 19),
                      FlSpot(9, 21),
                      FlSpot(10, 23),
                      FlSpot(11, 24),
                    ],
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
  const _SectorBarChartCard();

  @override
  Widget build(BuildContext context) {
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
          const Text('Offres par secteur', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
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
                        const labels = ['Tech', 'Finance', 'Santé', 'Commerce', 'Autres'];
                        final i = value.toInt();
                        if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(labels[i], style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _bar(0, 42),
                  _bar(1, 30),
                  _bar(2, 24),
                  _bar(3, 36),
                  _bar(4, 18),
                ],
              ),
              duration: const Duration(milliseconds: 800),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _bar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 18,
          color: const Color(0xFF1A56DB),
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }
}

class _GeoBarChartCard extends StatelessWidget {
  const _GeoBarChartCard();

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
        children: [
          const Text('Répartition géographique', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _CityPill(city: 'Conakry', value: 42),
              _CityPill(city: 'Kindia', value: 18),
              _CityPill(city: 'Labé', value: 12),
              _CityPill(city: 'Kankan', value: 14),
              _CityPill(city: 'Boké', value: 9),
              _CityPill(city: 'Mamou', value: 7),
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
