import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../widgets/responsive_container.dart';

class RecruteurStatisticsScreen extends StatefulWidget {
  const RecruteurStatisticsScreen({super.key});

  @override
  State<RecruteurStatisticsScreen> createState() => _RecruteurStatisticsScreenState();
}

class _RecruteurStatisticsScreenState extends State<RecruteurStatisticsScreen> {
  String _period = '30j';

  @override
  Widget build(BuildContext context) {
    final kpis = const [
      ('Vues totales', '12 480'),
      ('Candidatures reçues', '386'),
      ('Taux conversion', '3.1%'),
      ('Délai moyen', '9 j'),
    ];

    return ResponsiveContainer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 8, bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Statistiques recruteur', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                      SizedBox(height: 4),
                      Text('Suivez la performance de vos offres et candidatures.'),
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
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export PDF/Excel à brancher')),
                  ),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Exporter'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (_, c) {
                final cols = c.maxWidth >= 1200 ? 4 : (c.maxWidth >= 760 ? 2 : 1);
                return GridView.builder(
                  itemCount: kpis.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.4,
                  ),
                  itemBuilder: (_, i) => _KpiCard(label: kpis[i].$1, value: kpis[i].$2),
                );
              },
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (_, c) {
                if (c.maxWidth < 980) {
                  return const Column(
                    children: [
                      _ViewsLineChartCard(),
                      SizedBox(height: 12),
                      _FunnelCard(),
                    ],
                  );
                }
                return const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _ViewsLineChartCard()),
                    SizedBox(width: 12),
                    Expanded(child: _FunnelCard()),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (_, c) {
                if (c.maxWidth < 980) {
                  return const Column(
                    children: [
                      _SplitChartsCard(),
                      SizedBox(height: 12),
                      _OffersPerformanceTable(),
                    ],
                  );
                }
                return const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _SplitChartsCard()),
                    SizedBox(width: 12),
                    Expanded(child: _OffersPerformanceTable()),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            const _CandidateProfileInsightsCard(),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value});
  final String label;
  final String value;

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
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }
}

class _ViewsLineChartCard extends StatelessWidget {
  const _ViewsLineChartCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 340,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Évolution des vues (30j)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, _) =>
                          Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 36),
                      FlSpot(1, 42),
                      FlSpot(2, 48),
                      FlSpot(3, 40),
                      FlSpot(4, 56),
                      FlSpot(5, 62),
                      FlSpot(6, 58),
                    ],
                    isCurved: true,
                    color: const Color(0xFF1A56DB),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 22),
                      FlSpot(1, 24),
                      FlSpot(2, 28),
                      FlSpot(3, 26),
                      FlSpot(4, 30),
                      FlSpot(5, 34),
                      FlSpot(6, 38),
                    ],
                    isCurved: true,
                    color: const Color(0xFF10B981),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FunnelCard extends StatelessWidget {
  const _FunnelCard();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('Vues', 12480, 100.0, Color(0xFF1A56DB)),
      ('Candidatures', 386, 3.1, Color(0xFF2563EB)),
      ('En examen', 158, 1.3, Color(0xFF7C3AED)),
      ('Entretiens', 47, 0.4, Color(0xFFF59E0B)),
      ('Acceptés', 22, 0.2, Color(0xFF10B981)),
    ];

    return Container(
      height: 340,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Entonnoir de recrutement', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...steps.map((s) {
            final ratio = (s.$3 / 100).clamp(0.06, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('${s.$1} (${s.$2})')),
                      Text('${s.$3.toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  FractionallySizedBox(
                    widthFactor: ratio,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: s.$4.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SplitChartsCard extends StatelessWidget {
  const _SplitChartsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Répartition des candidatures', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
                      sections: [
                        PieChartSectionData(value: 34, color: Color(0xFF1A56DB), title: 'Dev'),
                        PieChartSectionData(value: 28, color: Color(0xFF10B981), title: 'Design'),
                        PieChartSectionData(value: 22, color: Color(0xFFF59E0B), title: 'Data'),
                        PieChartSectionData(value: 16, color: Color(0xFF7C3AED), title: 'Autres'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              const l = ['Cona', 'Kind', 'Labé', 'Boké'];
                              final i = v.toInt();
                              if (i < 0 || i >= l.length) return const SizedBox.shrink();
                              return Text(l[i], style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        _bar(0, 78),
                        _bar(1, 12),
                        _bar(2, 6),
                        _bar(3, 4),
                      ],
                    ),
                  ),
                ),
              ],
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
        BarChartRodData(toY: y, color: const Color(0xFF1A56DB), width: 14, borderRadius: BorderRadius.circular(5)),
      ],
    );
  }
}

class _OffersPerformanceTable extends StatelessWidget {
  const _OffersPerformanceTable();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['Développeur Flutter', '3 420', '124', '88%', '64%', '8 j'],
      ['Product Designer', '2 180', '92', '84%', '58%', '11 j'],
      ['Data Analyst', '1 760', '73', '79%', '51%', '9 j'],
    ];
    return Container(
      height: 360,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Performance par offre', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Offre')),
                  DataColumn(label: Text('Vues')),
                  DataColumn(label: Text('Candidatures')),
                  DataColumn(label: Text('Score IA')),
                  DataColumn(label: Text('Taux réponse')),
                  DataColumn(label: Text('Durée moy.')),
                ],
                rows: rows
                    .map(
                      (r) => DataRow(
                        cells: r.map((c) => DataCell(Text(c))).toList(),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateProfileInsightsCard extends StatelessWidget {
  const _CandidateProfileInsightsCard();

  @override
  Widget build(BuildContext context) {
    const skills = [
      ('Flutter', 42),
      ('Dart', 38),
      ('Figma', 26),
      ('SQL', 21),
      ('Node.js', 18),
    ];
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
          const Text('Profil moyen des candidats', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Expérience moyenne: 3.2 ans • Villes: Conakry 78%, Kindia 12%, autres 10%'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills
                .map(
                  (s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text('${s.$1} (${s.$2})'),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
