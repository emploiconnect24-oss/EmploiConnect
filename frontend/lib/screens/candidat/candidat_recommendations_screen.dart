import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/candidatures_service.dart';
import '../../services/matching_service.dart';
import '../../services/offres_service.dart';
import 'widgets/apply_bottom_sheet.dart';
import 'widgets/offre_ia_card.dart';

class CandidatRecommendationsScreen extends StatefulWidget {
  const CandidatRecommendationsScreen({super.key, this.onGoProfil});

  final VoidCallback? onGoProfil;

  @override
  State<CandidatRecommendationsScreen> createState() =>
      _CandidatRecommendationsScreenState();
}

class _CandidatRecommendationsScreenState
    extends State<CandidatRecommendationsScreen> {
  final _matchingService = MatchingService();
  final _candidaturesService = CandidaturesService();
  final _offresService = OffresService();

  List<Map<String, dynamic>> _items = [];
  final Set<String> _saved = <String>{};
  final Set<String> _ignored = <String>{};
  bool _loading = true;
  String? _error;

  /// Score complétion profil (GET /candidat/recommandations), sinon null.
  int? _scoreProfilIa;
  List<String> _conseilsApi = [];
  bool _usedRecommandationsEndpoint = false;

  String _scoreFilter = 'Tout';
  String _contractFilter = 'Tous';
  String _cityFilter = 'Toutes';

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
      List<Map<String, dynamic>> suggestions = [];
      int? scoreProfil;
      List<String> conseils = [];
      var usedNew = false;

      try {
        final res = await _matchingService.getRecommandationsIa(limite: 24);
        final data = res['data'] as Map<String, dynamic>?;
        if (res['success'] == true && data != null) {
          usedNew = true;
          scoreProfil = (data['score_profil'] as num?)?.toInt();
          final rawC = data['conseils'];
          if (rawC is List) {
            conseils = rawC
                .map((e) => e.toString())
                .where((s) => s.isNotEmpty)
                .toList();
          }
          final offres = data['offres'] as List<dynamic>? ?? [];
          suggestions = offres
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      } catch (_) {
        usedNew = false;
      }

      if (!usedNew) {
        final res = await _matchingService.getSuggestions(limite: 24);
        suggestions = (res['data'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        scoreProfil = null;
        conseils = [];
      }

      final savedRows = await _offresService.getSavedOffres();
      final savedIds = savedRows
          .map((e) => (e['offre_id'] ?? e['offre']?['id'])?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toSet();
      setState(() {
        _items = suggestions;
        _scoreProfilIa = scoreProfil;
        _conseilsApi = conseils;
        _usedRecommandationsEndpoint = usedNew;
        _saved
          ..clear()
          ..addAll(savedIds);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  int? _score(Map<String, dynamic> o) {
    final s = o['score_compatibilite'];
    if (s is! num) return null;
    final v = s.toInt().clamp(0, 100);
    return v > 0 ? v : null;
  }

  String _contract(Map<String, dynamic> o) =>
      (o['type_contrat'] ?? 'Non précisé').toString();
  String _city(Map<String, dynamic> o) =>
      (o['localisation'] ?? 'Non précisée').toString();

  List<Map<String, dynamic>> get _filtered {
    return _items.where((o) {
      final id = (o['id'] ?? '').toString();
      if (_ignored.contains(id)) return false;

      final score = _score(o);
      if (_scoreFilter == '>80%' && (score == null || score < 80)) return false;
      if (_scoreFilter == '>90%' && (score == null || score < 90)) return false;

      if (_contractFilter != 'Tous' && _contract(o) != _contractFilter) {
        return false;
      }
      if (_cityFilter != 'Toutes' && _city(o) != _cityFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  List<String> get _contracts {
    final values =
        _items.map(_contract).where((e) => e.trim().isNotEmpty).toSet().toList()
          ..sort();
    return ['Tous', ...values];
  }

  List<String> get _cities {
    final values =
        _items.map(_city).where((e) => e.trim().isNotEmpty).toSet().toList()
          ..sort();
    return ['Toutes', ...values];
  }

  int? get _globalScore {
    final scores = _items.map(_score).whereType<int>().toList();
    if (scores.isEmpty) return null;
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    return avg.round();
  }

  Future<void> _apply(Map<String, dynamic> offre) async {
    final id = (offre['id'] ?? '').toString();
    if (id.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Offre invalide.')));
      return;
    }
    final title = (offre['titre'] ?? 'Offre').toString();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ApplyBottomSheet(
        offerTitle: title,
        onSubmit: (motivation) async {
          await _candidaturesService.postuler(
            offreId: id,
            lettreMotivation: motivation,
          );
        },
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Candidature envoyée avec succès.')),
    );
  }

  /// PRD §6 — aucune offre renvoyée par l’API (différent du cas « filtres trop stricts »).
  Widget _emptyNoRecommendations() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 40, 8, 24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF1A56DB),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune recommandation disponible',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Complétez votre profil et uploadez votre CV\n'
            'pour recevoir des recommandations personnalisées.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.onGoProfil != null) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: widget.onGoProfil,
              icon: const Icon(Icons.person_outline_rounded, size: 18),
              label: Text(
                'Compléter mon profil',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final items = _filtered;
    final pagePad = EdgeInsets.fromLTRB(
      20,
      16,
      20,
      MediaQuery.of(context).size.width <= 900 ? 80 : 24,
    );
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: pagePad,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A56DB), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 11,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'IA',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recommandations IA',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'L\'IA analyse votre profil pour proposer les offres les plus adaptées.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          if (_usedRecommandationsEndpoint && _scoreProfilIa != null)
            _profilScoreCard(_scoreProfilIa!)
          else
            _globalScoreBar(_globalScore),
          const SizedBox(height: 12),
          if (_conseilsApi.isNotEmpty) ...[
            _conseilsCard(),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...['Tout', '>80%', '>90%'].map(
                (f) => ChoiceChip(
                  label: Text(f),
                  selected: _scoreFilter == f,
                  onSelected: (_) => setState(() => _scoreFilter = f),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 170,
                child: DropdownButtonFormField<String>(
                  initialValue: _contractFilter,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Contrat',
                  ),
                  items: _contracts
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _contractFilter = v ?? 'Tous'),
                ),
              ),
              SizedBox(
                width: 170,
                child: DropdownButtonFormField<String>(
                  initialValue: _cityFilter,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Ville',
                  ),
                  items: _cities
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _cityFilter = v ?? 'Toutes'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            _items.isEmpty
                ? _emptyNoRecommendations()
                : const Padding(
                    padding: EdgeInsets.only(top: 36),
                    child: Center(
                      child: Text('Aucune recommandation pour ces filtres.'),
                    ),
                  )
          else
            LayoutBuilder(
              builder: (_, c) {
                final cols = c.maxWidth > 1100
                    ? 4
                    : c.maxWidth > 750
                    ? 3
                    : c.maxWidth > 500
                    ? 2
                    : 1;
                final aspect = cols >= 4
                    ? 1.15
                    : cols == 3
                    ? 1.05
                    : cols == 2
                    ? 1.0
                    : 1.3;
                return GridView.builder(
                  itemCount: items.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    childAspectRatio: aspect,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemBuilder: (_, i) {
                    final o = items[i];
                    final id = (o['id'] ?? '').toString();
                    return OffreIACard(
                      offre: o,
                      index: i,
                      estSauvegardee: _saved.contains(id),
                      onPostuler: () => _apply(o),
                      onSauvegarder: () async {
                        final messenger = ScaffoldMessenger.maybeOf(context);
                        try {
                          if (_saved.contains(id)) {
                            await _offresService.removeSavedOffre(id);
                            if (!mounted) return;
                            setState(() => _saved.remove(id));
                          } else {
                            await _offresService.saveOffre(id);
                            if (!mounted) return;
                            setState(() => _saved.add(id));
                          }
                        } catch (e) {
                          if (!mounted) return;
                          messenger?.showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                      onIgnorer: () => setState(() => _ignored.add(id)),
                    );
                  },
                );
              },
            ),
          const SizedBox(height: 16),
          if (_conseilsApi.isEmpty) _tipsSection(),
        ],
      ),
    );
  }

  Widget _profilScoreCard(int score) {
    final ok = score >= 70;
    final mid = score >= 40;
    final grad = ok
        ? const [Color(0xFFECFDF5), Color(0xFFF0FDF4)]
        : mid
        ? const [Color(0xFFEFF6FF), Color(0xFFF0F9FF)]
        : const [Color(0xFFFEF3C7), Color(0xFFFFFBEB)];
    final border = ok
        ? const Color(0xFF10B981)
        : mid
        ? const Color(0xFF1A56DB)
        : const Color(0xFFF59E0B);
    final msg = ok
        ? 'Excellent ! Votre profil attire les recruteurs.'
        : mid
        ? 'Bon profil. Ajoutez des détails pour affiner les matchs.'
        : 'Profil incomplet. Complétez-le pour de meilleures offres.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: grad),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 6,
                  color: const Color(0xFFE2E8F0),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: score / 100),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => CircularProgressIndicator(
                    value: v,
                    strokeWidth: 6,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(border),
                  ),
                ),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: score),
                  duration: const Duration(milliseconds: 900),
                  builder: (_, v, _) => Text(
                    '$v',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score de votre profil',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  msg,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF374151),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 5,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(border),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _conseilsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFFF59E0B),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Améliorer vos suggestions',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._conseilsApi.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.onGoProfil != null)
            TextButton(
              onPressed: widget.onGoProfil,
              child: Text(
                'Compléter mon profil',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A56DB),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _globalScoreBar(int? score) {
    if (score == null || score <= 0) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score IA moyen : —',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              'Les scores apparaîtront quand votre profil et votre CV permettront un calcul fiable.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }
    final color = score >= 90
        ? const Color(0xFF10B981)
        : score >= 80
        ? const Color(0xFF1A56DB)
        : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score IA moyen : $score/100',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Complétez votre profil pour de meilleures suggestions.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _tipsSection() {
    final tips = <String>[
      'Ajoutez des compétences techniques précises (frameworks, outils, cloud).',
      'Complétez vos expériences avec des résultats chiffrés.',
      'Mettez à jour votre disponibilité et votre localisation.',
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Améliorez vos suggestions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...tips.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Color(0xFF1A56DB),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t,
                      style: const TextStyle(color: Color(0xFF334155)),
                    ),
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
