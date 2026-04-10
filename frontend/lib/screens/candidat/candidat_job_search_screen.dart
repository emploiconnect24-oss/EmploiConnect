import 'package:flutter/material.dart';

import '../../core/theme/theme_extension.dart';
import '../../services/candidatures_service.dart';
import '../../services/matching_service.dart';
import '../../services/offres_service.dart';
import '../../shared/widgets/ia_score_badge.dart';
import 'candidat_offer_detail_screen.dart';
import 'widgets/apply_bottom_sheet.dart';
import '../../widgets/responsive_container.dart';

class CandidatJobSearchScreen extends StatefulWidget {
  const CandidatJobSearchScreen({
    super.key,
    this.initialKeyword,
    this.initialVille,
    this.initialContract,
  });
  final String? initialKeyword;
  final String? initialVille;
  final String? initialContract;

  @override
  State<CandidatJobSearchScreen> createState() => _CandidatJobSearchScreenState();
}

class _CandidatJobSearchScreenState extends State<CandidatJobSearchScreen> {
  final _service = OffresService();
  final _candService = CandidaturesService();
  final _matchingService = MatchingService();
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _offres = [];
  Map<String, dynamic> _scores = {};
  final Set<String> _saved = {};
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;

  final Set<String> _selectedContracts = {};
  String? _hoveredOfferId;
  String? _selectedVille;
  String? _selectedSecteur;
  double _minSalaire = 0;
  String _sortBy = 'pertinence';

  static const _cities = ['Conakry', 'Kindia', 'Kankan', 'Labé', 'Boké', 'Mamou'];
  static const _contracts = ['CDI', 'CDD', 'Stage', 'Freelance', 'Temps partiel'];

  @override
  void initState() {
    super.initState();
    if (widget.initialKeyword != null && widget.initialKeyword!.trim().isNotEmpty) {
      _searchCtrl.text = widget.initialKeyword!.trim();
    }
    if (widget.initialVille != null && widget.initialVille!.trim().isNotEmpty) {
      _selectedVille = widget.initialVille!.trim();
    }
    if (widget.initialContract != null && widget.initialContract!.trim().isNotEmpty) {
      _selectedContracts.add(widget.initialContract!.trim());
    }
    _load(reset: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _offset = 0;
        _hasMore = true;
      });
    } else {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }

    try {
      final r = await _service.getOffres(
        domaine: _selectedSecteur,
        localisation: _selectedVille,
        typeContrat: _selectedContracts.isEmpty ? null : _selectedContracts.first.toLowerCase(),
        recherche: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        offset: _offset,
        limit: _limit,
      );

      final next = reset ? r.offres : [..._offres, ...r.offres];
      setState(() {
        _offres = next;
        if (reset) _scores = {};
        _offset += r.offres.length;
        _hasMore = r.offres.length >= _limit;
        _loading = false;
        _loadingMore = false;
      });
      if (reset) {
        await _hydrateSavedIds();
      }
      await _loadScores(next);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _hydrateSavedIds() async {
    try {
      final rows = await _service.getSavedOffres();
      final ids = rows
          .map((row) {
            final nested = row['offre'];
            final fromNested = nested is Map ? nested['id'] : null;
            return (row['offre_id'] ?? fromNested)?.toString() ?? '';
          })
          .where((id) => id.isNotEmpty)
          .toSet();
      if (mounted) {
        setState(() {
          _saved
            ..clear()
            ..addAll(ids);
        });
      }
    } catch (_) {
      // Liste sauvegardes optionnelle si table absente / erreur réseau
    }
  }

  Future<void> _toggleSaveOffer(String offreId, bool wasSaved) async {
    if (offreId.isEmpty) return;
    try {
      if (wasSaved) {
        await _service.removeSavedOffre(offreId);
        if (mounted) setState(() => _saved.remove(offreId));
      } else {
        await _service.saveOffre(offreId);
        if (mounted) setState(() => _saved.add(offreId));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _loadScores(List<Map<String, dynamic>> offres) async {
    if (offres.isEmpty) return;
    try {
      final ids = offres
          .map((o) => o['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      final res = await _matchingService.getScoresMultiples(ids);
      if (res['success'] == true && mounted) {
        setState(() {
          _scores = Map<String, dynamic>.from(res['data'] as Map? ?? {});
        });
      }
    } catch (_) {
      // Non bloquant: on garde l'affichage sans score IA en direct.
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final list = _offres.where((o) {
      final salaryMin = (o['salaire_min'] as num?)?.toDouble() ?? 0;
      final type = (o['type_contrat']?.toString() ?? '').toLowerCase();

      // Le texte de recherche est déjà appliqué côté API (`recherche`) ; ne pas
      // refiltrer ici pour éviter d’exclure des offres matchées sur la description.
      if (_selectedContracts.isNotEmpty && !_selectedContracts.map((e) => e.toLowerCase()).contains(type)) return false;
      if (_minSalaire > 0 && salaryMin < _minSalaire) return false;
      return true;
    }).toList();

    if (_sortBy == 'date') {
      list.sort((a, b) => (b['created_at']?.toString() ?? '').compareTo(a['created_at']?.toString() ?? ''));
    } else if (_sortBy == 'salaire') {
      list.sort((a, b) => ((b['salaire_min'] as num?) ?? 0).compareTo((a['salaire_min'] as num?) ?? 0));
    } else if (_sortBy == 'score_ia') {
      list.sort((a, b) => ((b['score_compatibilite'] as num?) ?? 0).compareTo((a['score_compatibilite'] as num?) ?? 0));
    }
    return list;
  }

  bool get _hasFiltresAvances =>
      _selectedVille != null ||
      (_selectedSecteur != null && _selectedSecteur!.isNotEmpty) ||
      _minSalaire > 0 ||
      _sortBy != 'pertinence';

  Future<void> _applyBottomSheet(Map<String, dynamic> offre) async {
    final id = offre['id']?.toString() ?? '';
    final title = (offre['titre'] ?? 'Offre').toString();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ApplyBottomSheet(
        offerTitle: title,
        onSubmit: (motivation) async {
          await _candService.postuler(
            offreId: id,
            lettreMotivation: motivation,
          );
        },
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Candidature envoyée avec succès !')),
    );
  }

  Future<void> _openFiltersBottomSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filtres avancés', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  const Text('Type de contrat'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _contracts
                        .map(
                          (c) => FilterChip(
                            label: Text(c),
                            selected: _selectedContracts.contains(c),
                            onSelected: (v) {
                              setState(() => v ? _selectedContracts.add(c) : _selectedContracts.remove(c));
                              setModal(() {});
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedVille,
                    decoration: const InputDecoration(labelText: 'Ville', isDense: true),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Toutes')),
                      ..._cities.map((v) => DropdownMenuItem(value: v, child: Text(v))),
                    ],
                    onChanged: (v) => setState(() => _selectedVille = v),
                  ),
                  const SizedBox(height: 12),
                  Text('Salaire minimum : ${_minSalaire.toInt()} GNF'),
                  Slider(
                    min: 0,
                    max: 8000000,
                    divisions: 16,
                    value: _minSalaire,
                    onChanged: (v) => setState(() => _minSalaire = v),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _load(reset: true);
                      },
                      child: const Text('Appliquer'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final compact = MediaQuery.of(context).size.width < 380;
    final list = _filtered;
    final scheme = Theme.of(context).colorScheme;
    final ext = context.themeExt;

    final listBottom = MediaQuery.of(context).size.width <= 900 ? 80.0 : 20.0;
    return ResponsiveContainer(
      padding: EdgeInsets.fromLTRB(compact ? 12 : 20, compact ? 12 : 16, compact ? 12 : 20, 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ext.cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recherche d\'offres',
                        style: TextStyle(
                          fontSize: compact ? 18 : 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Text(
                      '${list.length} offre(s)',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) {
                          setState(() {});
                          if (v.length >= 2 || v.isEmpty) _load(reset: true);
                        },
                        decoration: InputDecoration(
                          hintText: 'Titre, entreprise, compétence...',
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1A56DB), size: 22),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8)),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    _load(reset: true);
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF1A56DB), width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FiltreChip('Tous', null, _selectedContracts.isEmpty ? null : _selectedContracts.first, (v) {
                              setState(() => _selectedContracts.clear());
                              _load(reset: true);
                            }),
                            ...['CDI', 'CDD', 'Stage', 'Freelance'].map(
                              (type) => _FiltreChip(type, type, _selectedContracts.isEmpty ? null : _selectedContracts.first, (v) {
                                setState(() {
                                  _selectedContracts
                                    ..clear()
                                    ..add(type);
                                });
                                _load(reset: true);
                              }),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _openFiltersBottomSheet,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: _hasFiltresAvances ? const Color(0xFF1A56DB) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: _hasFiltresAvances ? const Color(0xFF1A56DB) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.tune_rounded, size: 14, color: _hasFiltresAvances ? Colors.white : const Color(0xFF64748B)),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Filtres',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _hasFiltresAvances ? Colors.white : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDesktop)
                  Container(
                    width: 260,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ext.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Filtres avancés', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedVille,
                          decoration: const InputDecoration(labelText: 'Ville', isDense: true),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Toutes')),
                            ..._cities.map((v) => DropdownMenuItem(value: v, child: Text(v))),
                          ],
                          onChanged: (v) => setState(() => _selectedVille = v),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          onChanged: (v) => _selectedSecteur = v.trim().isEmpty ? null : v.trim(),
                          decoration: const InputDecoration(labelText: 'Secteur', isDense: true),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _sortBy,
                          decoration: const InputDecoration(labelText: 'Trier par', isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'pertinence', child: Text('Pertinence')),
                            DropdownMenuItem(value: 'date', child: Text('Date')),
                            DropdownMenuItem(value: 'score_ia', child: Text('Score IA')),
                            DropdownMenuItem(value: 'salaire', child: Text('Salaire')),
                          ],
                          onChanged: (v) => setState(() => _sortBy = v ?? 'pertinence'),
                        ),
                        const SizedBox(height: 12),
                        Text('Salaire min: ${_minSalaire.toInt()} GNF'),
                        Slider(
                          value: _minSalaire,
                          min: 0,
                          max: 8000000,
                          divisions: 16,
                          onChanged: (v) => setState(() => _minSalaire = v),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => _load(reset: true),
                            child: const Text('Appliquer'),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(child: Text(_error!, textAlign: TextAlign.center))
                          : RefreshIndicator(
                              onRefresh: () => _load(reset: true),
                              child: ListView(
                                padding: EdgeInsets.only(bottom: listBottom),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text('${list.length} offres trouvées'),
                                  ),
                                  if (list.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 80),
                                      child: Center(child: Text('Aucune offre trouvée')),
                                    )
                                  else
                                    ...list.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final o = entry.value;
                                      final id = o['id']?.toString() ?? '';
                                      final title = o['titre']?.toString() ?? '';
                                      final ent = o['entreprises'];
                                      final company = ent is Map ? (ent['nom_entreprise']?.toString() ?? '-') : '-';
                                      final city = o['localisation']?.toString() ?? '';
                                      final type = o['type_contrat']?.toString() ?? '';
                                      final salaryMin = o['salaire_min']?.toString();
                                      final salaryMax = o['salaire_max']?.toString();
                                      final ai = (_scores[id]?['score'] as num?)?.round()
                                          ?? (o['score_compatibilite'] as num?)?.round();
                                      final saved = _saved.contains(id);
                                      final createdAt = o['created_at']?.toString() ?? '';
                                      final isNew = createdAt.isNotEmpty &&
                                          DateTime.tryParse(createdAt)?.isAfter(DateTime.now().subtract(const Duration(hours: 24))) == true;

                                      return TweenAnimationBuilder<double>(
                                        tween: Tween<double>(begin: 0, end: 1),
                                        duration: Duration(milliseconds: 320 + (index * 60)),
                                        curve: Curves.easeOut,
                                        builder: (context, t, child) => Opacity(
                                          opacity: t.clamp(0, 1),
                                          child: Transform.translate(
                                            offset: Offset(0, (1 - t) * 16),
                                            child: child,
                                          ),
                                        ),
                                        child: MouseRegion(
                                          onEnter: (_) => setState(() => _hoveredOfferId = id),
                                          onExit: (_) => setState(() => _hoveredOfferId = null),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 180),
                                            margin: const EdgeInsets.only(bottom: 12),
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: scheme.surface,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _hoveredOfferId == id ? const Color(0xFF1A56DB) : ext.cardBorder,
                                              ),
                                              boxShadow: _hoveredOfferId == id
                                                  ? const [
                                                      BoxShadow(
                                                        color: Color(0x14000000),
                                                        blurRadius: 12,
                                                        offset: Offset(0, 6),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            transform: Matrix4.translationValues(0, _hoveredOfferId == id ? -4 : 0, 0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                                    ),
                                                    if (isNew)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFD1FAE5),
                                                          borderRadius: BorderRadius.circular(999),
                                                        ),
                                                        child: const Text('NOUVEAU'),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text('$company · $city · $type'),
                                                if (salaryMin != null || salaryMax != null)
                                                  Text(
                                                    '${salaryMin ?? '...'} - ${salaryMax ?? '...'} GNF/mois',
                                                    style: const TextStyle(color: Color(0xFF64748B)),
                                                  ),
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: [
                                                    if (ai != null && ai > 0) IAScoreBadge(score: ai),
                                                    OutlinedButton(
                                                      onPressed: () {
                                                        Navigator.of(context).push(
                                                          MaterialPageRoute<void>(builder: (_) => CandidatOfferDetailScreen(offreId: id)),
                                                        );
                                                      },
                                                      child: const Text('Voir détails'),
                                                    ),
                                                    IconButton(
                                                      onPressed: () => _toggleSaveOffer(id, saved),
                                                      icon: AnimatedRotation(
                                                        turns: saved ? 0.12 : 0,
                                                        duration: const Duration(milliseconds: 200),
                                                        child: Icon(
                                                          saved ? Icons.bookmark_rounded : Icons.bookmark_outline,
                                                          color: saved ? const Color(0xFF1A56DB) : null,
                                                        ),
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () => _applyBottomSheet(o),
                                                      child: const Text('Postuler →'),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  if (_hasMore)
                                    Center(
                                      child: _loadingMore
                                          ? const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: CircularProgressIndicator(),
                                            )
                                          : OutlinedButton.icon(
                                              onPressed: () => _load(reset: false),
                                              icon: const Icon(Icons.expand_more),
                                              label: const Text('Charger plus'),
                                            ),
                                    ),
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
}

class _FiltreChip extends StatelessWidget {
  const _FiltreChip(this.label, this.valeur, this.selected, this.onTap);
  final String label;
  final String? valeur;
  final String? selected;
  final Function(String?) onTap;

  @override
  Widget build(BuildContext context) {
    final isSel = valeur == selected;
    return GestureDetector(
      onTap: () => onTap(isSel ? null : valeur),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF1A56DB) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSel ? const Color(0xFF1A56DB) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSel ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
