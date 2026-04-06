import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/theme_extension.dart';
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
                title: title,
                company: company,
                logoUrl: _logoUrl(offer),
                status: status,
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
    required this.title,
    required this.company,
    this.logoUrl,
    required this.status,
    required this.dateLabel,
    required this.statusMessage,
    this.raisonRefus,
    this.onViewOffer,
    this.onMessage,
    this.onPrepareInterview,
    this.onCancel,
  });

  final String title;
  final String company;
  final String? logoUrl;
  final String status;
  final String dateLabel;
  final String statusMessage;
  final String? raisonRefus;
  final VoidCallback? onViewOffer;
  final VoidCallback? onMessage;
  final VoidCallback? onPrepareInterview;
  final VoidCallback? onCancel;

  int get _step {
    switch (status) {
      case 'Envoyée':
        return 0;
      case 'En examen':
        return 1;
      case 'Entretien':
        return 2;
      case 'Acceptée':
      case 'Refusée':
      case 'Annulée':
        return 3;
      default:
        return 0;
    }
  }

  bool get _isRejected => status == 'Refusée';

  @override
  Widget build(BuildContext context) {
    const steps = ['Envoyée', 'En examen', 'Entretien', 'Réponse'];
    return LayoutBuilder(
      builder: (context, c) {
        final scheme = Theme.of(context).colorScheme;
        final ext = context.themeExt;
        final isMobile = c.maxWidth < 700;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ext.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CompanyAvatar(logoUrl: logoUrl, company: company),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          company,
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                dateLabel,
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 12),
              if (isMobile)
                _buildVerticalTimeline(steps)
              else
                _buildHorizontalTimeline(steps),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _statusBg(status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusMessage,
                  style: TextStyle(color: _statusFg(status)),
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
                      const Text(
                        'Motif communiqué par l’entreprise',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        raisonRefus!,
                        style: const TextStyle(
                          color: Color(0xFF991B1B),
                          height: 1.35,
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
                      icon: const Icon(Icons.calendar_today_outlined, size: 14),
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
        );
      },
    );
  }

  Widget _buildHorizontalTimeline(List<String> steps) {
    return Row(
      children: List.generate(steps.length, (i) {
        final completed = i < _step || (_isRejected && i == 3);
        final current = i == _step && !_isRejected;
        final rejectedStep = _isRejected && i == 3;
        final color = rejectedStep
            ? const Color(0xFFEF4444)
            : (completed || current
                  ? const Color(0xFF1A56DB)
                  : const Color(0xFFE2E8F0));
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: current
                            ? Border.all(
                                color: const Color(0xFF1A56DB),
                                width: 3,
                              )
                            : null,
                      ),
                      child: (completed || rejectedStep)
                          ? Icon(
                              rejectedStep ? Icons.close : Icons.check,
                              size: 12,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: completed || current
                            ? const Color(0xFF1A56DB)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    height: 2,
                    color: i < _step
                        ? const Color(0xFF1A56DB)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildVerticalTimeline(List<String> steps) {
    return Column(
      children: List.generate(steps.length, (i) {
        final completed = i < _step || (_isRejected && i == 3);
        final current = i == _step && !_isRejected;
        final rejectedStep = _isRejected && i == 3;
        final color = rejectedStep
            ? const Color(0xFFEF4444)
            : (completed || current
                  ? const Color(0xFF1A56DB)
                  : const Color(0xFFE2E8F0));
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: current
                        ? Border.all(color: const Color(0xFF1A56DB), width: 3)
                        : null,
                  ),
                  child: (completed || rejectedStep)
                      ? Icon(
                          rejectedStep ? Icons.close : Icons.check,
                          size: 11,
                          color: Colors.white,
                        )
                      : null,
                ),
                if (i < steps.length - 1)
                  Container(
                    width: 2,
                    height: 24,
                    color: i < _step
                        ? const Color(0xFF1A56DB)
                        : const Color(0xFFE2E8F0),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  steps[i],
                  style: TextStyle(
                    fontSize: 12,
                    color: completed || current
                        ? const Color(0xFF1A56DB)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _statusBadge(String s) {
    final bg = _statusBg(s);
    final fg = _statusFg(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        s,
        style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }

  Color _statusBg(String s) {
    switch (s) {
      case 'En examen':
        return const Color(0xFFFEF3C7);
      case 'Entretien':
        return const Color(0xFFF5F3FF);
      case 'Acceptée':
        return const Color(0xFFD1FAE5);
      case 'Refusée':
      case 'Annulée':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFEFF6FF);
    }
  }

  Color _statusFg(String s) {
    switch (s) {
      case 'En examen':
        return const Color(0xFF92400E);
      case 'Entretien':
        return const Color(0xFF6D28D9);
      case 'Acceptée':
        return const Color(0xFF047857);
      case 'Refusée':
      case 'Annulée':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFF1E40AF);
    }
  }
}

class _CompanyAvatar extends StatelessWidget {
  const _CompanyAvatar({this.logoUrl, required this.company});

  final String? logoUrl;
  final String company;

  @override
  Widget build(BuildContext context) {
    final letter =
        company.trim().isNotEmpty ? company.trim()[0].toUpperCase() : 'E';
    final u = logoUrl;
    if (u != null && u.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          u,
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(letter),
        ),
      );
    }
    return _fallback(letter);
  }

  Widget _fallback(String letter) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A56DB),
          ),
        ),
      ),
    );
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
