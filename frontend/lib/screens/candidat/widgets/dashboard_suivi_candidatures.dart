import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Suivi candidatures animé — dashboard (PRD §2).
class DashboardSuiviCandidatures extends StatefulWidget {
  const DashboardSuiviCandidatures({
    super.key,
    required this.stats,
    required this.candidaturesRecentes,
    this.onVoirTout,
  });

  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> candidaturesRecentes;
  final VoidCallback? onVoirTout;

  @override
  State<DashboardSuiviCandidatures> createState() => _DashboardSuiviCandidaturesState();
}

class _DashboardSuiviCandidaturesState extends State<DashboardSuiviCandidatures>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  static const _etapes = [
    _Etape('En attente', Icons.hourglass_empty_rounded, Color(0xFFF59E0B)),
    _Etape('En examen', Icons.search_rounded, Color(0xFF1A56DB)),
    _Etape('Entretien', Icons.event_available_rounded, Color(0xFF8B5CF6)),
    _Etape('Acceptées', Icons.check_circle_rounded, Color(0xFF10B981)),
    _Etape('Refusées', Icons.cancel_rounded, Color(0xFFEF4444)),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      5,
      (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 600)),
    );
    _animations = _controllers
        .map(
          (c) => Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(parent: c, curve: Curves.elasticOut),
          ),
        )
        .toList();
    for (var i = 0; i < 5; i++) {
      Future<void>.delayed(Duration(milliseconds: 90 * i), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<int> _values() {
    final s = widget.stats;
    return [
      (s['en_attente'] as num?)?.toInt() ?? 0,
      (s['en_cours'] as num?)?.toInt() ?? 0,
      (s['entretiens'] as num?)?.toInt() ?? 0,
      (s['acceptees'] as num?)?.toInt() ?? 0,
      (s['refusees'] as num?)?.toInt() ?? 0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final values = _values();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Suivi de mes candidatures',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            TextButton(
              onPressed: widget.onVoirTout,
              child: Text(
                'Tout voir →',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A56DB)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth > 600 ? 5 : 3;
            final w = (c.maxWidth - (cols - 1) * 10) / cols;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(5, (i) {
                return SizedBox(
                  width: w,
                  child: ScaleTransition(
                    scale: _animations[i],
                    child: _StatutCard(
                      etape: _etapes[i],
                      count: values[i],
                      onTap: widget.onVoirTout,
                    ),
                  ),
                );
              }),
            );
          },
        ),
        if (widget.candidaturesRecentes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: widget.candidaturesRecentes.take(3).toList().asMap().entries.map((e) {
                final i = e.key;
                final cand = e.value;
                return _CandidatureRecenteItem(
                  candidature: cand,
                  showDivider: i < 2,
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _Etape {
  const _Etape(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

class _StatutCard extends StatelessWidget {
  const _StatutCard({
    required this.etape,
    required this.count,
    this.onTap,
  });

  final _Etape etape;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: etape.color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: etape.color.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: etape.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(etape.icon, color: etape.color, size: 20),
            ),
            const SizedBox(height: 6),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: count),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, val, _) => Text(
                '$val',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: etape.color,
                ),
              ),
            ),
            Text(
              etape.label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidatureRecenteItem extends StatelessWidget {
  const _CandidatureRecenteItem({
    required this.candidature,
    required this.showDivider,
  });

  final Map<String, dynamic> candidature;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final offre = candidature['offre'];
    final offMap = offre is Map ? Map<String, dynamic>.from(offre) : <String, dynamic>{};
    final ent = offMap['entreprise'];
    final entMap = ent is Map ? Map<String, dynamic>.from(ent) : <String, dynamic>{};
    final titre = (offMap['titre'] ?? '').toString();
    final nomEnt = (entMap['nom_entreprise'] ?? '').toString();
    final logo = entMap['logo_url']?.toString();
    final statut = (candidature['statut'] ?? '').toString();
    final date = candidature['date_candidature']?.toString();

    late Color sc;
    late String sl;
    late IconData si;
    switch (statut) {
      case 'acceptee':
        sc = const Color(0xFF10B981);
        sl = 'Acceptée ✓';
        si = Icons.check_circle_rounded;
        break;
      case 'entretien':
        sc = const Color(0xFF8B5CF6);
        sl = 'Entretien';
        si = Icons.event_available_rounded;
        break;
      case 'en_cours':
        sc = const Color(0xFF1A56DB);
        sl = 'En examen';
        si = Icons.search_rounded;
        break;
      case 'refusee':
        sc = const Color(0xFFEF4444);
        sl = 'Refusée';
        si = Icons.cancel_rounded;
        break;
      default:
        sc = const Color(0xFFF59E0B);
        sl = 'En attente';
        si = Icons.hourglass_empty_rounded;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: logo != null && logo.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: logo,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _logoFallback(nomEnt),
                      )
                    : _logoFallback(nomEnt),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre.isEmpty ? 'Offre' : titre,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      nomEnt.isEmpty ? 'Entreprise' : nomEnt,
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: sc.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(si, size: 10, color: sc),
                        const SizedBox(width: 3),
                        Text(
                          sl,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: sc,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (date != null && date.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      _fmtDate(date),
                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 14, endIndent: 14, color: Color(0xFFF1F5F9)),
      ],
    );
  }

  Widget _logoFallback(String nomEnt) {
    return Center(
      child: Text(
        nomEnt.isNotEmpty ? nomEnt[0].toUpperCase() : '?',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A56DB),
        ),
      ),
    );
  }

  String _fmtDate(String d) {
    try {
      final dt = DateTime.parse(d).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays == 0) return 'Aujourd\'hui';
      if (diff.inDays == 1) return 'Hier';
      return 'Il y a ${diff.inDays}j';
    } catch (_) {
      return '';
    }
  }
}
