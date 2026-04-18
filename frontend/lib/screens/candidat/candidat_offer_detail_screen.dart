import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/theme_extension.dart';
import '../../providers/candidat_provider.dart';
import '../../services/candidatures_service.dart';
import '../../services/matching_service.dart';
import '../../services/offres_service.dart';
import '../../widgets/dialog_analyse_postulation.dart';
import '../../widgets/signalement_content_sheet.dart';
import 'widgets/apply_bottom_sheet.dart';

class CandidatOfferDetailScreen extends StatefulWidget {
  const CandidatOfferDetailScreen({super.key, required this.offreId});
  final String offreId;

  @override
  State<CandidatOfferDetailScreen> createState() => _CandidatOfferDetailScreenState();
}

class _CandidatOfferDetailScreenState extends State<CandidatOfferDetailScreen> {
  final _offres = OffresService();
  final _candidatures = CandidaturesService();
  final _matching = MatchingService();

  Map<String, dynamic>? _offre;
  bool _loading = true;
  String? _error;
  bool _saved = false;
  bool _bookmarkBusy = false;
  bool _posting = false;
  int? _scoreIa;
  Map<String, dynamic>? _myCandidature;

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
      final o = await _offres.getOffreById(widget.offreId);
      setState(() {
        _offre = o;
        _loading = false;
      });
      final scoreRes = await _matching.getScore(widget.offreId);
      if (scoreRes['success'] == true && mounted) {
        final raw = scoreRes['data']?['score'];
        setState(() {
          if (raw is num) {
            _scoreIa = raw.round().clamp(0, 100);
          } else {
            _scoreIa = null;
          }
        });
      }
      try {
        final list = await _candidatures.getCandidatures(offreId: widget.offreId);
        if (mounted) {
          setState(() {
            _myCandidature = list.isEmpty
                ? null
                : Map<String, dynamic>.from(list.first);
          });
        }
      } catch (_) {
        if (mounted) setState(() => _myCandidature = null);
      }
      await _syncSavedFromApi();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _syncSavedFromApi() async {
    try {
      final rows = await _offres.getSavedOffres();
      final oid = widget.offreId;
      final isSaved = rows.any((row) {
        final nested = row['offre'];
        final rid = (row['offre_id'] ?? (nested is Map ? nested['id'] : null))
            ?.toString() ??
            '';
        return rid == oid;
      });
      if (mounted) setState(() => _saved = isSaved);
    } catch (_) {}
  }

  Future<void> _toggleBookmark() async {
    if (_bookmarkBusy) return;
    setState(() => _bookmarkBusy = true);
    try {
      if (_saved) {
        await _offres.removeSavedOffre(widget.offreId);
      } else {
        await _offres.saveOffre(widget.offreId);
      }
      if (mounted) setState(() => _saved = !_saved);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _bookmarkBusy = false);
    }
  }

  Future<void> _ouvrirSheetPostulation() async {
    setState(() => _posting = true);
    final titre = (_offre?['titre'] ?? 'Offre').toString();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ApplyBottomSheet(
        offerTitle: titre,
        onSubmit: (motivation) async {
          await _candidatures.postuler(
            offreId: widget.offreId,
            lettreMotivation: motivation,
          );
        },
      ),
    );
    if (!mounted) return;
    setState(() => _posting = false);
    if (ok != true) return;
    setState(() {
      _myCandidature = {
        'statut': 'en_attente',
        'offre_id': widget.offreId,
      };
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Candidature envoyée avec succès !')));
  }

  Future<void> _apply() async {
    final titre = (_offre?['titre'] ?? 'Offre').toString();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DialogAnalysePostulation(
        offreId: widget.offreId,
        offreTitre: titre,
        onConfirmerPostulation: () {
          _ouvrirSheetPostulation();
        },
      ),
    );
  }

  String? _extractEntreprisePeerId(Map<String, dynamic> offre, Map<String, dynamic> ent) {
    final candidates = <dynamic>[
      ent['utilisateur_id'],
      ent['user_id'],
      ent['id_utilisateur'],
      offre['entreprise_utilisateur_id'],
      offre['entreprise_user_id'],
      offre['user_id_entreprise'],
      offre['recruteur_id'],
    ];
    for (final raw in candidates) {
      final v = raw?.toString().trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return null;
  }

  void _contactEntreprise({
    required String entrepriseNom,
    required String? photoUrl,
    required Map<String, dynamic> offre,
    required Map<String, dynamic> ent,
  }) {
    final peerId = _extractEntreprisePeerId(offre, ent);
    if (peerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de contacter cette entreprise pour le moment.')),
      );
      return;
    }
    context.read<CandidatProvider>().setMessageriePrefill(
      peerId: peerId,
      nom: entrepriseNom,
      photoUrl: photoUrl,
    );
    context.go('/dashboard/messages');
  }

  static String _statutLabel(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'en_attente':
        return 'Candidature envoyée';
      case 'en_cours':
        return 'En examen';
      case 'acceptee':
        return 'Acceptée';
      case 'refusee':
        return 'Refusée';
      case 'annulee':
        return 'Annulée';
      default:
        return 'Candidature enregistrée';
    }
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final u = Uri.tryParse(url);
    if (u == null) return;
    await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  Future<void> _partager() async {
    final titre = (_offre?['titre'] ?? 'Offre').toString();
    await Clipboard.setData(ClipboardData(text: '$titre — ${widget.offreId}'));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien/copier de l’offre prêt.')),
    );
  }

  Color _scoreColor(int s) {
    if (s >= 70) return const Color(0xFF10B981);
    if (s >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _fmtSalaire(num s) => s.toStringAsFixed(0);

  void _showCompanyProfile(
    BuildContext context,
    Map<String, dynamic> ent,
    String fallbackName,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _EntrepriseProfilCompletPage(
          ent: ent,
          fallbackName: fallbackName,
          onOpenUrl: _openUrl,
        ),
      ),
    );
  }

  Widget _buildCompatibiliteIA(Map<String, dynamic> offre, int? scoreIa) {
    if (scoreIa == null || scoreIa == 0) return const SizedBox.shrink();
    final compsOffre = List<String>.from(offre['competences_requises'] as List? ?? const []);
    final compsProfil = List<String>.from(
      (offre['competences_candidat'] as List?) ??
          (offre['competences_profil'] as List?) ??
          (offre['profil_competences'] as List?) ??
          const [],
    );
    final compsCorrespondantes = compsOffre
        .where(
          (c) => compsProfil.any(
            (p) => p.toLowerCase().contains(c.toLowerCase()) || c.toLowerCase().contains(p.toLowerCase()),
          ),
        )
        .toList();
    final compsManquantes = compsOffre.where((c) => !compsCorrespondantes.contains(c)).take(5).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1A56DB), Color(0xFF7C3AED)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Compatibilité IA',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _scoreIa! / 100),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) {
              final pct = (v * 100).round();
              final color = pct >= 70 ? const Color(0xFF10B981) : (pct >= 50 ? const Color(0xFF1A56DB) : const Color(0xFFF59E0B));
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withValues(alpha: 0.06), Colors.white]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(value: 1, strokeWidth: 7, color: color.withValues(alpha: 0.15)),
                          CircularProgressIndicator(value: v, strokeWidth: 7, backgroundColor: Colors.transparent, valueColor: AlwaysStoppedAnimation(color)),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('$pct%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
                              const Text('Match', style: TextStyle(fontSize: 8, color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pct >= 80 ? '🎯 Excellent profil !' : (pct >= 60 ? '👍 Bon profil' : (pct >= 40 ? '📈 Profil partiel' : '⚠️ Profil incomplet')),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pct >= 70
                                ? 'Vos compétences correspondent très bien à cette offre'
                                : (pct >= 50
                                    ? 'Vous avez la plupart des compétences requises'
                                    : 'Certaines compétences requises manquent dans votre profil'),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: LinearProgressIndicator(value: v, minHeight: 6, backgroundColor: color.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation(color)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (compsOffre.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (compsCorrespondantes.isNotEmpty)
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 600),
                      builder: (_, v, child) => Opacity(opacity: v, child: child),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 15),
                                const SizedBox(width: 5),
                                Text('${compsCorrespondantes.length} Maîtrisées', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF065F46))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: compsCorrespondantes
                                  .map(
                                    (c) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(100),
                                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                                      ),
                                      child: Text(c, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF065F46))),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (compsCorrespondantes.isNotEmpty && compsManquantes.isNotEmpty) const SizedBox(width: 10),
                if (compsManquantes.isNotEmpty)
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      builder: (_, v, child) => Opacity(opacity: v, child: child),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFF59E0B), size: 15),
                                const SizedBox(width: 5),
                                Text('${compsManquantes.length} À acquérir', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: compsManquantes
                                  .map(
                                    (c) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(100),
                                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                                      ),
                                      child: Text(c, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF92400E))),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Text(_error!)));
    final o = _offre ?? <String, dynamic>{};
    final entRaw = o['entreprises'];
    final entMap = entRaw is Map
        ? Map<String, dynamic>.from(entRaw)
        : <String, dynamic>{};
    final company = (entMap['nom_entreprise'] ?? 'Entreprise').toString();
    final logoUrl = (entMap['logo_url'] ?? '').toString();
    final bannerUrl = (entMap['banniere_url'] ?? '').toString();
    final title = o['titre']?.toString() ?? 'Offre';
    final city = o['localisation']?.toString() ?? '-';
    final type = o['type_contrat']?.toString() ?? '-';
    final description = o['description']?.toString() ?? '';
    final exigences = o['exigences']?.toString() ?? '';
    final sMin = o['salaire_min']?.toString();
    final sMax = o['salaire_max']?.toString();
    final fromOffre = (o['score_compatibilite'] as num?)?.round();
    final int? aiScore = _scoreIa ?? fromOffre;

    final salaire = (sMin != null || sMax != null) ? '${sMin ?? '...'} - ${sMax ?? '...'} GNF' : 'À négocier';

    final cand = _myCandidature;
    final candStatut = (cand?['statut'] ?? '').toString();
    final candLabel = cand != null ? _statutLabel(candStatut) : '';
    final raisonRefus = (cand?['raison_refus'] ?? '').toString().trim();
    final alreadyApplied = cand != null;
    final canPostuler = !alreadyApplied;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1A56DB),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A56DB), Color(0xFF0D1B3E)],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.04)),
                    ),
                  ),
                  Positioned(
                    right: 40,
                    bottom: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [BoxShadow(color: Color(0x20000000), blurRadius: 8)],
                              ),
                              child: logoUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(logoUrl, fit: BoxFit.cover),
                                    )
                                  : Center(child: Text(company.isNotEmpty ? company[0] : '?', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A56DB), fontSize: 18))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(company, style: const TextStyle(fontSize: 13, color: Colors.white70))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _HeaderTag(Icons.location_on_outlined, city),
                            _HeaderTag(Icons.work_outline_rounded, type),
                            if (sMin != null)
                              _HeaderTag(Icons.payments_outlined, '${_fmtSalaire(num.tryParse(sMin) ?? 0)} - ${_fmtSalaire(num.tryParse(sMax ?? '0') ?? 0)} GNF'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: Icon(_saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: Colors.white),
                onPressed: _toggleBookmark,
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                onPressed: _partager,
              ),
              IconButton(
                tooltip: 'Signaler cette offre',
                icon: const Icon(Icons.flag_outlined, color: Colors.white),
                onPressed: () => showSignalementContentDialog(
                  context,
                  typeObjet: 'offre',
                  objetId: widget.offreId,
                  dialogTitle: 'Signaler cette offre',
                  description:
                      'Expliquez le problème (offre trompeuse, contenu inapproprié, discrimination présumée, etc.). La modération en sera informée.',
                ),
              ),
            ],
          ),
          if (bannerUrl.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                height: 120,
                margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(image: NetworkImage(bannerUrl), fit: BoxFit.cover),
                  boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 3))],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.black.withValues(alpha: 0.15), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
          if (aiScore != null && aiScore > 0)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_scoreColor(aiScore).withValues(alpha: 0.08), Colors.white]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _scoreColor(aiScore).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Color(0xFF1A56DB), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Compatibilité IA : $aiScore% — ${aiScore >= 70 ? 'Excellent match pour votre profil !' : aiScore >= 50 ? 'Bon match pour votre profil' : 'Match partiel — améliorez votre profil'}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _scoreColor(aiScore)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              child: Column(
                children: [
                  if (alreadyApplied)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        candStatut.toLowerCase().trim() == 'refusee' && raisonRefus.isNotEmpty
                            ? 'Vous avez déjà postulé · $candLabel\nMotif : $raisonRefus'
                            : 'Vous avez déjà postulé · $candLabel',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  _buildCompatibiliteIA(o, aiScore),
                  _card(
                    title: 'Description',
                    child: SelectableText(description.isEmpty ? 'Aucune description.' : description, style: const TextStyle(height: 1.5, fontSize: 14)),
                  ),
                  const SizedBox(height: 14),
                  _card(
                    title: 'Prérequis',
                    child: SelectableText(exigences.isEmpty ? 'Aucun prérequis.' : exigences, style: const TextStyle(height: 1.5, fontSize: 14)),
                  ),
                  const SizedBox(height: 14),
                  _card(
                    title: 'À propos de l’entreprise',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(company, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text('Secteur : ${o['domaine'] ?? '-'}'),
                        Text('Ville : $city'),
                        Text('Salaire : $salaire'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showCompanyProfile(context, entMap, company),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF1A56DB).withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.business_rounded, color: Color(0xFF1A56DB), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Voir le profil complet de $company',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A56DB)),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF1A56DB)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Contacter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A56DB),
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                onPressed: () => _contactEntreprise(
                  entrepriseNom: company,
                  photoUrl: logoUrl.isNotEmpty ? logoUrl : null,
                  offre: o,
                  ent: entMap,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(alreadyApplied ? 'Déjà candidaté' : 'Postuler maintenant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56DB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                onPressed: (!canPostuler || _posting) ? null : _apply,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({String? title, required Widget child}) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ext.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }

}

class _HeaderTag extends StatelessWidget {
  const _HeaderTag(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: Colors.white70),
            const SizedBox(width: 4),
            Text(text, style: const TextStyle(fontSize: 11, color: Colors.white)),
          ],
        ),
      );
}

class _EntrepriseProfilCompletPage extends StatelessWidget {
  const _EntrepriseProfilCompletPage({
    required this.ent,
    required this.fallbackName,
    required this.onOpenUrl,
  });

  final Map<String, dynamic> ent;
  final String fallbackName;
  final Future<void> Function(String?) onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final b = (ent['banniere_url'] ?? '').toString();
    final logo = (ent['logo_url'] ?? '').toString();
    final nom = (ent['nom_entreprise'] ?? fallbackName).toString();
    final desc = (ent['description'] ?? '').toString();
    final mission = (ent['mission'] ?? '').toString();
    final slogan = (ent['slogan'] ?? '').toString();
    final site = (ent['site_web'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Profil entreprise')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (b.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 21 / 9,
                child: Image.network(
                  b,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          if (b.isNotEmpty) const SizedBox(height: 12),
          Row(
            children: [
              if (logo.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    logo,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              if (logo.isNotEmpty) const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nom,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          if (slogan.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(slogan, style: const TextStyle(color: Color(0xFF64748B))),
          ],
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Présentation', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(desc, style: const TextStyle(height: 1.45)),
          ],
          if (mission.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Mission', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(mission, style: const TextStyle(height: 1.45)),
          ],
          if (site.isNotEmpty) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => onOpenUrl(site),
              icon: const Icon(Icons.language, size: 18),
              label: const Text('Site web'),
            ),
          ],
        ],
      ),
    );
  }
}
