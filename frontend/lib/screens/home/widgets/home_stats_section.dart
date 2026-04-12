import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../../config/api_config.dart';
import 'home_design_tokens.dart';

/// Agrégats accueil (une seule requête possible depuis [HomePage]).
class HomepageStatsSnapshot {
  const HomepageStatsSnapshot({
    required this.entreprises,
    required this.candidats,
    required this.offres,
    required this.satisfaction,
  });

  final int entreprises;
  final int candidats;
  final int offres;
  final int satisfaction;

  @override
  bool operator ==(Object other) {
    return other is HomepageStatsSnapshot &&
        other.entreprises == entreprises &&
        other.candidats == candidats &&
        other.offres == offres &&
        other.satisfaction == satisfaction;
  }

  @override
  int get hashCode => Object.hash(entreprises, candidats, offres, satisfaction);
}

/// Stats `GET /api/stats/homepage` — cartes plates, chiffres lisibles, compteur animé.
class HomeStatsSection extends StatefulWidget {
  const HomeStatsSection({
    super.key,
    this.statsSnapshot,
    this.expectParentStats = false,
  });

  /// Si fourni, aucun appel HTTP (données déjà chargées par la page d’accueil).
  final HomepageStatsSnapshot? statsSnapshot;
  /// Si true et pas encore de [statsSnapshot] : on attend le parent (pas de double GET).
  final bool expectParentStats;

  @override
  State<HomeStatsSection> createState() => _HomeStatsSectionState();
}

class _HomeStatsSectionState extends State<HomeStatsSection> with SingleTickerProviderStateMixin {
  int _nbEntreprises = 0;
  int _nbCandidats = 0;
  int _nbOffres = 0;
  int _satisfaction = 0;
  bool _loaded = false;

  late AnimationController _ctrl;

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    final snap = widget.statsSnapshot;
    if (snap != null) {
      _applySnapshot(snap);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ctrl.forward(from: 0);
      });
    } else if (!widget.expectParentStats) {
      _loadStats();
    }
  }

  @override
  void didUpdateWidget(covariant HomeStatsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final s = widget.statsSnapshot;
    if (s != null && s != oldWidget.statsSnapshot) {
      _applySnapshot(s);
      _ctrl.forward(from: 0);
    }
  }

  void _applySnapshot(HomepageStatsSnapshot s) {
    setState(() {
      _nbEntreprises = s.entreprises;
      _nbCandidats = s.candidats;
      _nbOffres = s.offres;
      _satisfaction = s.satisfaction.clamp(0, 100);
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final res = await http
          .get(Uri.parse('$apiBaseUrl$apiPrefix/stats/homepage'))
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = body['data'];
        if (data is Map) {
          setState(() {
            _nbEntreprises = _asInt(data['entreprises']);
            _nbCandidats = _asInt(data['candidats']);
            _nbOffres = _asInt(data['offres']);
            _satisfaction = _asInt(data['satisfaction']).clamp(0, 100);
            _loaded = true;
          });
          _ctrl.forward(from: 0);
          return;
        }
      }
    } catch (_) {
      // ignore
    }
    if (!mounted) return;
    setState(() {
      _nbEntreprises = 0;
      _nbCandidats = 0;
      _nbOffres = 0;
      _satisfaction = 0;
      _loaded = true;
    });
    _ctrl.forward(from: 0);
  }

  static double _easeOutExpo(double t) {
    if (t >= 1) return 1;
    return 1 - math.pow(2, -10 * t).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final pad = w < 700 ? 14.0 : 40.0;
    final waitingParent = widget.expectParentStats && widget.statsSnapshot == null && !_loaded;
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.fromLTRB(pad, 28, pad, 20),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, v, child) {
                return Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, 14 * (1 - v)),
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  Text(
                    'Des chiffres qui parlent',
                    style: GoogleFonts.poppins(
                      fontSize: w < 600 ? 24 : 28,
                      fontWeight: FontWeight.w800,
                      color: HomeDesign.dark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _loaded ? 'La plateforme qui grandit avec vous' : 'Chargement…',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (!waitingParent) ...[
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, c) {
                  final mw = c.maxWidth;
                  final cols = mw < 768 ? 2 : (mw < 1100 ? 2 : 4);
                  final gap = mw < 768 ? 10.0 : 14.0;
                  final tileW = (mw - gap * (cols - 1)) / cols;

                  final tiles = <Widget>[
                  _StatAnimee(
                    icone: Icons.apartment_rounded,
                    valeurFinale: _nbEntreprises,
                    label: 'Entreprises\npartenaires',
                    suffixe: _nbEntreprises >= 100 ? '+' : '',
                    ctrl: _ctrl,
                    delai: 0,
                    valeurStatique: null,
                    cardWidth: tileW,
                  ),
                  _StatAnimee(
                    icone: Icons.groups_rounded,
                    valeurFinale: _nbCandidats,
                    label: 'Candidats\ninscrits',
                    suffixe: _nbCandidats >= 100 ? '+' : '',
                    ctrl: _ctrl,
                    delai: 110,
                    valeurStatique: null,
                    cardWidth: tileW,
                  ),
                  _StatAnimee(
                    icone: Icons.work_outline_rounded,
                    valeurFinale: _nbOffres,
                    label: 'Offres\npubliées',
                    suffixe: _nbOffres >= 50 ? '+' : '',
                    ctrl: _ctrl,
                    delai: 220,
                    valeurStatique: null,
                    cardWidth: tileW,
                  ),
                  _StatAnimee(
                    icone: Icons.star_rounded,
                    valeurFinale: _satisfaction,
                    label: 'Satisfaction',
                    suffixe: '%',
                    ctrl: _ctrl,
                    delai: 330,
                    valeurStatique: _satisfaction <= 0 && _loaded ? '—' : null,
                    cardWidth: tileW,
                  ),
                ];

                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    children: tiles,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatAnimee extends StatefulWidget {
  const _StatAnimee({
    required this.icone,
    required this.valeurFinale,
    required this.label,
    required this.suffixe,
    required this.ctrl,
    required this.delai,
    required this.cardWidth,
    this.valeurStatique,
  });

  final IconData icone;
  final int valeurFinale;
  final String label;
  final String suffixe;
  final AnimationController ctrl;
  final int delai;
  final String? valeurStatique;
  final double cardWidth;

  @override
  State<_StatAnimee> createState() => _StatAnimeeState();
}

class _StatAnimeeState extends State<_StatAnimee> with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _hoverCtrl;
  late Animation<double> _hoverScale;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _hoverScale = Tween<double>(begin: 1, end: 1.03).animate(
      CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const totalMs = 1800;
    final start = (widget.delai / totalMs).clamp(0.0, 0.88);
    final anim = CurvedAnimation(
      parent: widget.ctrl,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _hoverCtrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _hoverCtrl.reverse();
      },
      child: ScaleTransition(
        scale: _hoverScale,
        child: SizedBox(
          width: widget.cardWidth,
          child: AnimatedBuilder(
            animation: anim,
            builder: (context, _) {
              final t = _HomeStatsSectionState._easeOutExpo(anim.value);
              final brut = (t * widget.valeurFinale).round();
              final afficheStatique = widget.valeurStatique;
              final texteNombre = afficheStatique ?? '$brut${widget.suffixe}';
              final scaleNombre = Tween<double>(begin: 0.82, end: 1).transform(
                Curves.easeOutBack.transform(anim.value.clamp(0.0, 1.0)),
              );

              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _hovered ? HomeDesign.primary.withValues(alpha: 0.35) : const Color(0xFFE2E8F0),
                    width: _hovered ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: _hovered ? 0.08 : 0.04),
                      blurRadius: _hovered ? 16 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: HomeDesign.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(widget.icone, color: HomeDesign.primary, size: 22),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Transform.scale(
                                scale: scaleNombre,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  texteNombre,
                                  style: GoogleFonts.poppins(
                                    fontSize: afficheStatique != null ? 26 : 28,
                                    fontWeight: FontWeight.w900,
                                    color: HomeDesign.primary,
                                    height: 1,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF475569),
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: anim.value,
                        minHeight: 3,
                        backgroundColor: HomeDesign.primary.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(HomeDesign.primaryMid),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
