import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../shared/widgets/job_card_widget.dart';
import '../../../../shared/widgets/section_header.dart';

class RecentJobsSectionWidget extends StatelessWidget {
  const RecentJobsSectionWidget({super.key});

  Future<List<Map<String, dynamic>>> _loadMockJobs() async {
    await Future.delayed(const Duration(milliseconds: 900));
    return [
      {
        'title': 'Développeur Flutter',
        'company': 'Orange Guinée',
        'location': 'Conakry',
        'contract': 'CDI',
        'summary': "Concevoir des interfaces modernes, intégrer des API REST et maintenir l'application mobile.",
        'date': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'title': 'Comptable Senior',
        'company': 'Ecobank Guinée',
        'location': 'Conakry',
        'contract': 'CDI',
        'summary': 'Superviser la comptabilité générale, garantir la conformité et produire les reportings mensuels.',
        'date': DateTime.now().subtract(const Duration(days: 3)),
      },
      {
        'title': 'Chef de projet',
        'company': 'Plan International',
        'location': 'Kindia',
        'contract': 'CDD',
        'summary': 'Coordonner les projets terrain, gérer les parties prenantes et piloter les indicateurs d’impact.',
        'date': DateTime.now().subtract(const Duration(days: 4)),
      },
      {
        'title': 'Data Analyst',
        'company': 'MTN Guinée',
        'location': 'Conakry',
        'contract': 'Stage',
        'summary': 'Analyser les données commerciales, produire des dashboards et recommander des optimisations.',
        'date': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'title': 'Ingénieur réseau',
        'company': 'Sotelgui',
        'location': 'Conakry',
        'contract': 'CDI',
        'summary': 'Assurer la disponibilité réseau, diagnostiquer les incidents et renforcer la sécurité des infrastructures.',
        'date': DateTime.now().subtract(const Duration(days: 5)),
      },
      {
        'title': 'RH Manager',
        'company': 'Groupe Hadja Binta',
        'location': 'Labé',
        'contract': 'CDI',
        'summary': 'Piloter le recrutement, la gestion des talents et les plans de formation.',
        'date': DateTime.now().subtract(const Duration(days: 6)),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 900;

    int cols = 3;
    if (w < 700) {
      cols = 1;
    } else if (w < 980) {
      cols = 2;
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80, vertical: isMobile ? 36 : 64),
        child: Column(
          children: [
            const SectionHeader(
              title: "Dernières Offres d'Emploi",
              subtitle: 'Opportunités récentes publiées par des entreprises en Guinée.',
            ),
            const SizedBox(height: 24),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadMockJobs(),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return _ShimmerGrid(columns: cols);
                }
                final jobs = snap.data ?? const <Map<String, dynamic>>[];
                if (jobs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Text('Aucune offre disponible pour le moment.'),
                  );
                }
                return _JobsGrid(columns: cols, jobs: jobs);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Voir toutes les offres'),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobsGrid extends StatelessWidget {
  const _JobsGrid({required this.columns, required this.jobs});

  final int columns;
  final List<Map<String, dynamic>> jobs;

  @override
  Widget build(BuildContext context) {
    final spacing = 14.0;
    return LayoutBuilder(
      builder: (context, c) {
        final itemW = (c.maxWidth - (columns - 1) * spacing) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final j in jobs)
              SizedBox(
                width: itemW,
                height: 252,
                child: JobCardWidget(job: j, onTap: () {}),
              ),
          ],
        );
      },
    );
  }
}

class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid({required this.columns});

  final int columns;

  @override
  Widget build(BuildContext context) {
    final spacing = 14.0;
    return LayoutBuilder(
      builder: (context, c) {
        final itemW = (c.maxWidth - (columns - 1) * spacing) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(
            3,
            (index) => SizedBox(
              width: itemW,
              height: 252,
              child: Shimmer.fromColors(
                baseColor: const Color(0xFFE5E7EB),
                highlightColor: const Color(0xFFF3F4F6),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
                          const SizedBox(width: 10),
                          Expanded(child: Container(height: 16, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(height: 12, width: 160, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 120, color: Colors.white),
                      const SizedBox(height: 12),
                      Container(height: 24, width: 62, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100))),
                      const SizedBox(height: 12),
                      Container(height: 12, width: double.infinity, color: Colors.white),
                      const SizedBox(height: 6),
                      Container(height: 12, width: 180, color: Colors.white),
                      const Spacer(),
                      Row(
                        children: [
                          Container(height: 10, width: 60, color: Colors.white),
                          const Spacer(),
                          Container(height: 10, width: 90, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

