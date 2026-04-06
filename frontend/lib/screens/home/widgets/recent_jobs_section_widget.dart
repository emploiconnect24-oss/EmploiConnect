import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/theme_extension.dart';

import '../../../../services/offres_service.dart';
import '../../../app/public_routes.dart';
import '../../../../shared/widgets/job_card_widget.dart';
import '../../../../shared/widgets/section_header.dart';

Map<String, dynamic> _mapOffreToJobCard(Map<String, dynamic> o) {
  dynamic ent = o['entreprises'];
  String company = '';
  if (ent is Map) {
    company = ent['nom_entreprise']?.toString() ?? '';
  } else if (ent is List && ent.isNotEmpty && ent.first is Map) {
    company = (ent.first as Map)['nom_entreprise']?.toString() ?? '';
  }
  final desc = o['description']?.toString() ?? '';
  final summary = desc.length > 180 ? '${desc.substring(0, 180)}…' : desc;
  final pub = o['date_publication'] ?? o['date_creation'];
  DateTime? date;
  if (pub is String) date = DateTime.tryParse(pub);

  return {
    'title': o['titre']?.toString() ?? 'Offre',
    'company': company.isEmpty ? 'Entreprise' : company,
    'location': o['localisation']?.toString() ?? '',
    'contract': o['type_contrat']?.toString() ?? '',
    'summary': summary,
    'date': date ?? DateTime.now(),
    'offre_id': o['id']?.toString(),
  };
}

class RecentJobsSectionWidget extends StatefulWidget {
  const RecentJobsSectionWidget({super.key});

  @override
  State<RecentJobsSectionWidget> createState() => _RecentJobsSectionWidgetState();
}

class _RecentJobsSectionWidgetState extends State<RecentJobsSectionWidget> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  /// Au plus 6 offres (3 colonnes × 2 lignes) ; l’affichage réel est `colonnes × 2` selon la largeur.
  static const int _kMaxOffresAccueil = 6;

  Future<List<Map<String, dynamic>>> _load() async {
    try {
      final r = await OffresService().getOffresPublic(offset: 0, limit: _kMaxOffresAccueil);
      final list = r.offres.map(_mapOffreToJobCard).toList();
      list.sort((a, b) {
        final da = a['date'] is DateTime ? a['date'] as DateTime : DateTime.fromMillisecondsSinceEpoch(0);
        final db = b['date'] is DateTime ? b['date'] as DateTime : DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });
      return list;
    } catch (_) {
      return [];
    }
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
      color: context.themeExt.sectionBg,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80, vertical: isMobile ? 36 : 64),
        child: Column(
          children: [
            const SectionHeader(
              title: "Dernières Offres d'Emploi",
              subtitle:
                  'Aperçu des offres les plus récentes (deux lignes sur l’accueil). Consultez la liste complète via le bouton ci-dessous.',
            ),
            const SizedBox(height: 24),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return _ShimmerGrid(columns: cols, itemCount: cols * 2);
                }
                final jobs = snap.data ?? const <Map<String, dynamic>>[];
                if (jobs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Text('Aucune offre disponible pour le moment.'),
                  );
                }
                final maxItems = cols * 2;
                final visible = jobs.length <= maxItems ? jobs : jobs.sublist(0, maxItems);
                return _JobsGrid(columns: cols, jobs: visible);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(PublicRoutes.listPath);
              },
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
                child: JobCardWidget(
                  job: j,
                  onTap: () {
                    final id = j['offre_id']?.toString();
                    if (id == null || id.isEmpty) return;
                    Navigator.of(context).pushNamed(PublicRoutes.offre(id));
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid({required this.columns, required this.itemCount});

  final int columns;
  final int itemCount;

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
            itemCount.clamp(1, 64),
            (index) => SizedBox(
              width: itemW,
              height: 252,
              child: Shimmer.fromColors(
                baseColor: context.themeExt.shimmerBase,
                highlightColor: context.themeExt.shimmerHighlight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.themeExt.cardBorder),
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
