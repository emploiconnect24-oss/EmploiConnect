import 'package:flutter/material.dart';

import '../../services/candidatures_service.dart';
import '../../services/matching_service.dart';
import '../../services/offres_service.dart';
import '../../shared/widgets/offre_card_compact.dart';

class CandidatRecommendationsScreen extends StatefulWidget {
  const CandidatRecommendationsScreen({super.key});

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
      final res = await _matchingService.getSuggestions(limite: 24);
      final suggestions = (res['data'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final savedRows = await _offresService.getSavedOffres();
      final savedIds = savedRows
          .map((e) => (e['offre_id'] ?? e['offre']?['id'])?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toSet();
      setState(() {
        _items = suggestions;
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
    try {
      await _candidaturesService.postuler(offreId: id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Candidature envoyée avec succès.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
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
          const Text(
            'Offres recommandées par IA',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Notre IA analyse votre profil et votre CV pour vous proposer les offres les plus adaptées à vos compétences.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          _globalScoreBar(_globalScore),
          const SizedBox(height: 12),
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
            const Padding(
              padding: EdgeInsets.only(top: 36),
              child: Center(
                child: Text('Aucune recommandation pour ces filtres.'),
              ),
            )
          else
            LayoutBuilder(
              builder: (_, c) {
                int count = 1;
                if (c.maxWidth >= 1200) {
                  count = 3;
                } else if (c.maxWidth >= 760) {
                  count = 2;
                }
                return GridView.builder(
                  itemCount: items.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count,
                    childAspectRatio: 1.5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemBuilder: (_, i) {
                    final o = items[i];
                    final id = (o['id'] ?? '').toString();
                    return OffreCardCompact(
                      offre: o,
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
          _tipsSection(),
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
