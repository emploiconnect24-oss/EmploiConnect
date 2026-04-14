import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/theme_extension.dart';

import '../../../../services/offres_service.dart';
import '../../../app/public_routes.dart';
import '../../../../shared/widgets/job_card_widget.dart';
import 'home_design_tokens.dart';

Map<String, dynamic> _mapOffreToJobCard(Map<String, dynamic> o) {
  dynamic ent = o['entreprise'] ?? o['entreprises'];
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
  const RecentJobsSectionWidget({
    super.key,
    this.backgroundColor,
    this.homepageV2Gradient = false,
  });

  final Color? backgroundColor;
  /// PRD v2 §4 — bandeau blanc → bleu très clair → blanc.
  final bool homepageV2Gradient;

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
      final r = await OffresService().getOffresPublic(page: 1, limit: _kMaxOffresAccueil);
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

    final flatBg = widget.backgroundColor ?? context.themeExt.sectionBg;
    final cs = Theme.of(context).colorScheme;
    final dark = context.isDark;
    return Container(
      width: double.infinity,
      decoration: widget.homepageV2Gradient
          ? BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: dark
                    ? const [
                        Color(0xFF0F172A),
                        Color(0xFF1A2F5E),
                        Color(0xFF0F172A),
                      ]
                    : const [
                        Color(0xFFFFFFFF),
                        Color(0xFFF0F7FF),
                        Color(0xFFFFFFFF),
                      ],
              ),
            )
          : BoxDecoration(
              color: flatBg,
              border: Border(
                top: BorderSide(color: context.themeExt.cardBorder.withValues(alpha: 0.65)),
              ),
            ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 48, vertical: isMobile ? 28 : 48),
        child: Column(
          children: [
            Text(
              "Dernières offres",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: w < 600 ? 24 : 28,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            )
                .animate()
                .fadeIn(duration: 450.ms, curve: Curves.easeOutCubic)
                .slideY(begin: 0.05, duration: 450.ms, curve: Curves.easeOutCubic),
            const SizedBox(height: 8),
            Text(
              'Les publications les plus récentes — parcourez toute la liste en un clic.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            )
                .animate()
                .fadeIn(delay: 80.ms, duration: 450.ms, curve: Curves.easeOutCubic),
            const SizedBox(height: 22),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return _ShimmerGrid(columns: cols, itemCount: cols * 2);
                }
                final jobs = snap.data ?? const <Map<String, dynamic>>[];
                if (jobs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Text(
                      'Aucune offre disponible pour le moment.',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  );
                }
                final maxItems = cols * 2;
                final visible = jobs.length <= maxItems ? jobs : jobs.sublist(0, maxItems);
                return _JobsGrid(columns: cols, jobs: visible);
              },
            ),
            const SizedBox(height: 22),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: HomeDesign.gradientBrand,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: HomeDesign.primary.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(PublicRoutes.listPath);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                label: Text(
                  'Voir toutes les offres',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 180.ms, duration: 500.ms, curve: Curves.easeOutCubic)
                .scale(
                  begin: const Offset(0.94, 0.94),
                  delay: 180.ms,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
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
            for (var i = 0; i < jobs.length; i++)
              SizedBox(
                width: itemW,
                height: 252,
                child: JobCardWidget(
                  job: jobs[i],
                  onTap: () {
                    final id = jobs[i]['offre_id']?.toString();
                    if (id == null || id.isEmpty) return;
                    Navigator.of(context).pushNamed(PublicRoutes.offre(id));
                  },
                )
                    .animate()
                    .fadeIn(
                      delay: (60 * i).ms,
                      duration: 420.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .slideY(
                      begin: 0.07,
                      delay: (60 * i).ms,
                      duration: 420.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .scale(
                      begin: const Offset(0.97, 0.97),
                      delay: (60 * i).ms,
                      duration: 420.ms,
                      curve: Curves.easeOutCubic,
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
    final shimmerBlock = context.themeExt.shimmerHighlight;
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
                          Container(width: 42, height: 42, decoration: BoxDecoration(color: shimmerBlock, borderRadius: BorderRadius.circular(12))),
                          const SizedBox(width: 10),
                          Expanded(child: Container(height: 16, color: shimmerBlock)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(height: 12, width: 160, color: shimmerBlock),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 120, color: shimmerBlock),
                      const SizedBox(height: 12),
                      Container(height: 24, width: 62, decoration: BoxDecoration(color: shimmerBlock, borderRadius: BorderRadius.circular(100))),
                      const SizedBox(height: 12),
                      Container(height: 12, width: double.infinity, color: shimmerBlock),
                      const SizedBox(height: 6),
                      Container(height: 12, width: 180, color: shimmerBlock),
                      const Spacer(),
                      Row(
                        children: [
                          Container(height: 10, width: 60, color: shimmerBlock),
                          const Spacer(),
                          Container(height: 10, width: 90, color: shimmerBlock),
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
