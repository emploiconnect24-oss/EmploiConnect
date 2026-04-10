import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/candidatures_service.dart';
import 'candidat_offer_detail_screen.dart';

class CandidatApplicationsScreen extends StatefulWidget {
  const CandidatApplicationsScreen({
    super.key,
    this.offreIdFilter,
    this.onOpenMessages,
  });
  final String? offreIdFilter;
  final VoidCallback? onOpenMessages;

  @override
  State<CandidatApplicationsScreen> createState() =>
      _CandidatApplicationsScreenState();
}

class _CandidatApplicationsScreenState
    extends State<CandidatApplicationsScreen> {
  final _service = CandidaturesService();
  List<Map<String, dynamic>> _list = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  String? _error;
  String _activeTab = 'Toutes';

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
      final res = await _service.getMesCandidatures(limite: 100);
      setState(() {
        _list = res.candidatures;
        _stats = res.stats;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Aligné sur les statuts API (`candidatures.statut`).
  String _statusLabel(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'en_attente':
        return 'Envoyée';
      case 'en_cours':
        return 'En examen';
      case 'entretien':
        return 'Entretien';
      case 'acceptee':
        return 'Acceptée';
      case 'refusee':
        return 'Refusée';
      case 'annulee':
        return 'Annulée';
      default:
        final s = raw.toLowerCase();
        if (s.contains('refus')) return 'Refusée';
        if (s.contains('accep')) return 'Acceptée';
        if (s.contains('entretien')) return 'Entretien';
        if (s.contains('cours') || s.contains('examen')) return 'En examen';
        if (s.contains('annul')) return 'Annulée';
        return 'Envoyée';
    }
  }

  Map<String, dynamic>? _offreMap(Map<String, dynamic> c) {
    final o = c['offre'];
    if (o is Map) return Map<String, dynamic>.from(o);
    final legacy = c['offres_emploi'];
    if (legacy is Map) return Map<String, dynamic>.from(legacy);
    return null;
  }

  Map<String, dynamic>? _entrepriseMap(Map<String, dynamic>? offer) {
    if (offer == null) return null;
    final e = offer['entreprise'] ?? offer['entreprises'];
    if (e is Map) return Map<String, dynamic>.from(e);
    return null;
  }

  String _offerTitle(Map<String, dynamic>? offer) =>
      (offer?['titre'] ?? 'Offre').toString();

  String _companyName(Map<String, dynamic>? offer) {
    final ent = _entrepriseMap(offer);
    return (ent?['nom_entreprise'] ?? 'Entreprise').toString();
  }

  String? _logoUrl(Map<String, dynamic>? offer) {
    final ent = _entrepriseMap(offer);
    final u = ent?['logo_url']?.toString();
    if (u == null || u.isEmpty) return null;
    return u;
  }

  String _offerId(Map<String, dynamic>? offer) =>
      (offer?['id'] ?? '').toString();

  String _offerLocation(Map<String, dynamic>? offer) =>
      (offer?['localisation'] ?? offer?['ville'] ?? '').toString();

  String _offerContract(Map<String, dynamic>? offer) =>
      (offer?['type_contrat'] ?? '').toString();

  List<Map<String, dynamic>> get _filtered {
    return _list.where((c) {
      if (widget.offreIdFilter != null && widget.offreIdFilter!.isNotEmpty) {
        final oid = _offerId(_offreMap(c));
        if (oid != widget.offreIdFilter) return false;
      }
      final s = _statusLabel((c['statut'] ?? '').toString());
      if (_activeTab == 'Toutes') return true;
      if (_activeTab == 'En cours') return s == 'Envoyée' || s == 'En examen';
      if (_activeTab == 'Entretiens') return s == 'Entretien';
      if (_activeTab == 'Terminées') {
        return s == 'Acceptée' || s == 'Refusée' || s == 'Annulée';
      }
      return true;
    }).toList();
  }

  Future<void> _cancel(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la candidature ?'),
        content: const Text(
          'Cette action mettra la candidature en statut annulé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.updateStatut(id, 'annulee');
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Candidature annulée')));
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

    final list = _filtered;
    final fmt = DateFormat('dd/MM/yyyy');
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
            'Mes candidatures',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            '${_stats['total'] ?? _list.length} candidature(s) au total',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatPill(
                label: 'En attente',
                value: (_stats['en_attente'] as num?)?.toInt() ?? 0,
              ),
              _StatPill(
                label: 'En cours',
                value: (_stats['en_cours'] as num?)?.toInt() ?? 0,
              ),
              _StatPill(
                label: 'Entretien',
                value: (_stats['entretien'] as num?)?.toInt() ?? 0,
              ),
              _StatPill(
                label: 'Acceptées',
                value: (_stats['acceptees'] as num?)?.toInt() ?? 0,
              ),
              _StatPill(
                label: 'Refusées',
                value: (_stats['refusees'] as num?)?.toInt() ?? 0,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Toutes', 'En cours', 'Entretiens', 'Terminées']
                .map(
                  (t) => ChoiceChip(
                    label: Text(t),
                    selected: _activeTab == t,
                    onSelected: (_) => setState(() => _activeTab = t),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          if (_list.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                child: Text(
                  'Vous n’avez encore postulé à aucune offre.\nExplorez les offres et envoyez votre première candidature.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                ),
              ),
            )
          else if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('Aucune candidature pour ce filtre.')),
            )
          else
            ...list.map((c) {
              final id = (c['id'] ?? '').toString();
              final raw = (c['statut'] ?? '').toString();
              final status = _statusLabel(raw);
              final offer = _offreMap(c);
              final title = _offerTitle(offer);
              final company = _companyName(offer);
              final offerId = _offerId(offer);
              final dateStr = c['date_candidature']?.toString();
              DateTime? d;
              if (dateStr != null) {
                try {
                  d = DateTime.parse(dateStr);
                } catch (_) {}
              }
              final dateLabel = d == null
                  ? 'Date inconnue'
                  : 'Postulé le ${fmt.format(d)}';
              final raison =
                  (c['raison_refus'] ?? '').toString().trim();
              return _TimelineCard(
                rawStatut: raw,
                title: title,
                company: company,
                logoUrl: _logoUrl(offer),
                status: status,
                loc: _offerLocation(offer),
                contrat: _offerContract(offer),
                dateCandidature: d,
                dateLabel: dateLabel,
                statusMessage: _statusMessage(status),
                raisonRefus:
                    status == 'Refusée' && raison.isNotEmpty ? raison : null,
                onViewOffer: offerId.isEmpty
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                CandidatOfferDetailScreen(offreId: offerId),
                          ),
                        );
                      },
                onMessage: status == 'Refusée'
                    ? null
                    : () {
                        if (widget.onOpenMessages != null) {
                          widget.onOpenMessages!();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ouvrez l’onglet Messages dans le menu.'),
                            ),
                          );
                        }
                      },
                onPrepareInterview: status == 'Entretien'
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Module préparation entretien à connecter.',
                            ),
                          ),
                        );
                      }
                    : null,
                onCancel:
                    (status == 'Acceptée' ||
                        status == 'Refusée' ||
                        status == 'Annulée')
                    ? null
                    : () => _cancel(id),
              );
            }),
        ],
      ),
    );
  }

  String _statusMessage(String status) {
    switch (status) {
      case 'En examen':
        return 'Votre candidature est en cours d’examen.';
      case 'Entretien':
        return 'Entretien confirmé. Préparez vos réponses et questions.';
      case 'Acceptée':
        return 'Félicitations, votre candidature a été acceptée.';
      case 'Refusée':
        return 'Merci pour votre candidature. D’autres profils ont été retenus.';
      case 'Annulée':
        return 'Cette candidature a été annulée.';
      default:
        return 'Votre candidature a bien été envoyée.';
    }
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.rawStatut,
    required this.title,
    required this.company,
    this.logoUrl,
    required this.status,
    required this.loc,
    required this.contrat,
    this.dateCandidature,
    required this.dateLabel,
    required this.statusMessage,
    this.raisonRefus,
    this.onViewOffer,
    this.onMessage,
    this.onPrepareInterview,
    this.onCancel,
  });

  final String rawStatut;
  final String title;
  final String company;
  final String? logoUrl;
  final String status;
  final String loc;
  final String contrat;
  final DateTime? dateCandidature;
  final String dateLabel;
  final String statusMessage;
  final String? raisonRefus;
  final VoidCallback? onViewOffer;
  final VoidCallback? onMessage;
  final VoidCallback? onPrepareInterview;
  final VoidCallback? onCancel;

  Color get _accent => _candidatureStatutColor(rawStatut);

  @override
  Widget build(BuildContext context) {
    final fmtShort = DateFormat('dd/MM/yyyy');
    final dateStr = dateCandidature != null
        ? fmtShort.format(dateCandidature!.toLocal())
        : dateLabel.replaceFirst('Postulé le ', '');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: logoUrl != null && logoUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    logoUrl!,
                                    fit: BoxFit.cover,
                                    width: 36,
                                    height: 36,
                                    errorBuilder: (_, _, _) =>
                                        _logoLetter(company),
                                  ),
                                )
                              : _logoLetter(company),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                company,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: _accent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _candidatureStatutIcon(rawStatut),
                                size: 11,
                                color: _accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                status,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (loc.isNotEmpty) ...[
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              loc,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF94A3B8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (contrat.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              contrat,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF1A56DB),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Text(
                          dateStr,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    _BarreEvolution(statut: rawStatut),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusMessage,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.35,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                    if (raisonRefus != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Motif communiqué par l’entreprise',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: const Color(0xFF991B1B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              raisonRefus!,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF991B1B),
                                height: 1.35,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: onViewOffer,
                          child: const Text('Voir l\'offre'),
                        ),
                        if (onPrepareInterview != null)
                          ElevatedButton.icon(
                            onPressed: onPrepareInterview,
                            icon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                            ),
                            label: const Text('Préparer'),
                          ),
                        if (onMessage != null)
                          OutlinedButton.icon(
                            onPressed: onMessage,
                            icon: const Icon(Icons.chat_outlined, size: 14),
                            label: const Text('Message'),
                          ),
                        if (onCancel != null)
                          TextButton(
                            onPressed: onCancel,
                            child: const Text('Annuler'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoLetter(String nomEnt) {
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
}

class _BarreEvolution extends StatefulWidget {
  const _BarreEvolution({required this.statut});

  final String statut;

  @override
  State<_BarreEvolution> createState() => _BarreEvolutionState();
}

class _BarreEvolutionState extends State<_BarreEvolution>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  static const _etapes = [
    _Etape('Envoyée', Icons.send_rounded, Color(0xFF94A3B8)),
    _Etape('En examen', Icons.search_rounded, Color(0xFF1A56DB)),
    _Etape('Entretien', Icons.event_available_rounded, Color(0xFF8B5CF6)),
    _Etape('Décision', Icons.gavel_rounded, Color(0xFFF59E0B)),
  ];

  int get _etapeActuelle {
    switch (widget.statut.toLowerCase().trim()) {
      case 'en_attente':
        return 0;
      case 'en_cours':
        return 1;
      case 'entretien':
        return 2;
      case 'acceptee':
      case 'refusee':
      case 'annulee':
        return 3;
      default:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final etapeIdx = _etapeActuelle;
    final raw = widget.statut.toLowerCase().trim();
    final isRefusee = raw == 'refusee' || raw == 'annulee';
    final isAcceptee = raw == 'acceptee';
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _anim,
            builder: (_, _) {
              final progress = etapeIdx == 0
                  ? 0.0
                  : (etapeIdx / (_etapes.length - 1)) * _anim.value;
              return ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: isRefusee ? 1.0 * _anim.value : progress,
                  minHeight: 4,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation(
                    isRefusee
                        ? const Color(0xFFEF4444)
                        : isAcceptee
                            ? const Color(0xFF10B981)
                            : const Color(0xFF1A56DB),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(_etapes.length, (i) {
              final fait = i < etapeIdx;
              final enCours = i == etapeIdx && !isRefusee && !isAcceptee;
              final etape = _etapes[i];
              Color couleurFinale;
              if (isAcceptee && i == _etapes.length - 1) {
                couleurFinale = const Color(0xFF10B981);
              } else if (isRefusee && i == _etapes.length - 1) {
                couleurFinale = const Color(0xFFEF4444);
              } else {
                couleurFinale = etape.couleur;
              }
              return Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: fait || enCours
                            ? couleurFinale.withValues(alpha: 0.15)
                            : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: fait || enCours
                              ? couleurFinale
                              : const Color(0xFFE2E8F0),
                          width: enCours ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        fait ? Icons.check_rounded : etape.icon,
                        size: 13,
                        color: fait || enCours
                            ? couleurFinale
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      i == _etapes.length - 1 && isAcceptee
                          ? 'Acceptée ✓'
                          : i == _etapes.length - 1 && isRefusee
                              ? 'Refusée'
                              : etape.label,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: enCours || (fait && i == etapeIdx - 1)
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: fait || enCours
                            ? couleurFinale
                            : const Color(0xFF94A3B8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Etape {
  const _Etape(this.label, this.icon, this.couleur);
  final String label;
  final IconData icon;
  final Color couleur;
}

Color _candidatureStatutColor(String raw) {
  final s = raw.toLowerCase().trim();
  switch (s) {
    case 'acceptee':
      return const Color(0xFF10B981);
    case 'entretien':
      return const Color(0xFF8B5CF6);
    case 'en_cours':
      return const Color(0xFF1A56DB);
    case 'refusee':
    case 'annulee':
      return const Color(0xFFEF4444);
    default:
      return const Color(0xFFF59E0B);
  }
}

IconData _candidatureStatutIcon(String raw) {
  final s = raw.toLowerCase().trim();
  switch (s) {
    case 'acceptee':
      return Icons.check_circle_rounded;
    case 'entretien':
      return Icons.event_available_rounded;
    case 'en_cours':
      return Icons.search_rounded;
    case 'refusee':
    case 'annulee':
      return Icons.cancel_rounded;
    default:
      return Icons.hourglass_empty_rounded;
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '$label : $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
      ),
    );
  }
}
