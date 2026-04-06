import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/theme_extension.dart';
import '../../services/candidatures_service.dart';
import '../../services/matching_service.dart';
import '../../services/offres_service.dart';
import '../../shared/widgets/ia_score_badge.dart';
import '../../widgets/signalement_content_sheet.dart';

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

  Future<void> _apply() async {
    final lettreCtrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).extension<AppThemeExtension>()!.cardBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Postuler à cette offre', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: lettreCtrl,
                maxLines: 5,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Lettre de motivation (optionnel)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Envoyer ma candidature'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;
    try {
      setState(() => _posting = true);
      await _candidatures.postuler(
        offreId: widget.offreId,
        lettreMotivation: lettreCtrl.text.trim().isEmpty ? null : lettreCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _myCandidature = {
          'statut': 'en_attente',
          'offre_id': widget.offreId,
        };
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Candidature envoyée avec succès !')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Widget _logoPlaceholder(String name) {
    final letter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'E';
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A56DB),
            fontSize: 22,
          ),
        ),
      ),
    );
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

  void _showCompanyProfile(
    BuildContext context,
    Map<String, dynamic> ent,
    String fallbackName,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (_, scrollCtrl) {
          final b = (ent['banniere_url'] ?? '').toString();
          final logo = (ent['logo_url'] ?? '').toString();
          final nom = (ent['nom_entreprise'] ?? fallbackName).toString();
          final desc = (ent['description'] ?? '').toString();
          final mission = (ent['mission'] ?? '').toString();
          final slogan = (ent['slogan'] ?? '').toString();
          final site = (ent['site_web'] ?? '').toString();
          return ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              if (b.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 21 / 9,
                    child: Image.network(
                      b,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFFE2E8F0)),
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
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  if (logo.isNotEmpty) const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      nom,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              if (slogan.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  slogan,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Présentation',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(desc, style: const TextStyle(height: 1.45)),
              ],
              if (mission.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Mission',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(mission, style: const TextStyle(height: 1.45)),
              ],
              if (site.isNotEmpty) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _openUrl(site),
                  icon: const Icon(Icons.language, size: 18),
                  label: const Text('Site web'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
      appBar: AppBar(
        title: const Text('Détail offre'),
        actions: [
          IconButton(
            tooltip: 'Signaler cette offre',
            icon: const Icon(Icons.flag_outlined),
            onPressed: _loading
                ? null
                : () => showSignalementContentDialog(
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
      body: LayoutBuilder(
        builder: (context, c) {
          final desktop = c.maxWidth > 900;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).size.width <= 900 ? 80 : 24,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: desktop ? 65 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (bannerUrl.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: AspectRatio(
                            aspectRatio: 21 / 9,
                            child: Image.network(
                              bannerUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (alreadyApplied)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.assignment_turned_in_outlined,
                                        color: scheme.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Vous avez déjà postulé · $candLabel',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (candStatut.toLowerCase().trim() == 'refusee' &&
                                      raisonRefus.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Motif : $raisonRefus',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Une seule candidature par offre est autorisée sur EmploiConnect.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (logoUrl.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      logoUrl,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _logoPlaceholder(company),
                                    ),
                                  )
                                else
                                  _logoPlaceholder(company),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$company · $city · $type',
                                        style: TextStyle(
                                          color: scheme.onSurfaceVariant,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        salaire,
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (aiScore != null)
                                  IAScoreBadge(score: aiScore)
                                else
                                  Text(
                                    'Score IA : —',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                const _OfferTag('NOUVEAU'),
                              ],
                            ),
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              onPressed: (!canPostuler || _posting) ? null : _apply,
                              icon: _posting
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: scheme.onPrimary,
                                      ),
                                    )
                                  : Icon(
                                      alreadyApplied
                                          ? Icons.check_rounded
                                          : Icons.send_outlined,
                                    ),
                              label: Text(
                                _posting
                                    ? 'Envoi...'
                                    : (alreadyApplied
                                        ? 'Déjà candidaté'
                                        : 'Postuler'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _card(
                        title: 'Description',
                        child: SelectableText(
                          description.isEmpty
                              ? 'Aucune description.'
                              : description,
                          style: const TextStyle(height: 1.5, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _card(
                        title: 'Prérequis',
                        child: SelectableText(
                          exigences.isEmpty
                              ? 'Aucun prérequis.'
                              : exigences,
                          style: const TextStyle(height: 1.5, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _card(
                        title: 'À propos de l’entreprise',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              company,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text('Secteur : ${o['domaine'] ?? '-'}'),
                            Text('Ville : $city'),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () => _showCompanyProfile(
                                context,
                                entMap,
                                company,
                              ),
                              icon: const Icon(Icons.business_outlined, size: 18),
                              label: const Text('Voir le profil de l’entreprise'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (desktop) const SizedBox(width: 12),
                Expanded(
                  flex: desktop ? 35 : 1,
                  child: Column(
                    children: [
                      _card(
                        title: 'Actions',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilledButton(
                              onPressed: (!canPostuler || _posting) ? null : _apply,
                              child: Text(
                                alreadyApplied
                                    ? 'Déjà candidaté'
                                    : 'Postuler à cette offre',
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _bookmarkBusy ? null : _toggleBookmark,
                              icon: _bookmarkBusy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      _saved
                                          ? Icons.bookmark_rounded
                                          : Icons.bookmark_outline,
                                    ),
                              label: Text(
                                _saved ? 'Sauvegardée' : 'Sauvegarder',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _card(
                        title: 'Informations pratiques',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type : $type'),
                            Text('Ville : $city'),
                            Text('Salaire : $salaire'),
                            Text('Date limite : ${o['date_limite'] ?? '-'}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _card(
                        title: 'Score IA',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (aiScore != null) ...[
                              Center(
                                child: IAScoreBadge(
                                  score: aiScore,
                                  large: true,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Votre score de correspondance : $aiScore %',
                              ),
                            ] else ...[
                              const Center(
                                child: Text(
                                  '—',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Pas encore calculé ou profil incomplet. Complétez votre CV pour obtenir un score.',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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

class _OfferTag extends StatelessWidget {
  const _OfferTag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final ext = context.themeExt;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ext.infoBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.primary)),
    );
  }
}
