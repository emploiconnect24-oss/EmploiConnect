import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/candidatures_service.dart';
import '../../services/offres_service.dart';
import 'candidat_offer_detail_screen.dart';

class CandidatSavedOffersScreen extends StatefulWidget {
  const CandidatSavedOffersScreen({super.key});

  @override
  State<CandidatSavedOffersScreen> createState() => _CandidatSavedOffersScreenState();
}

class _CandidatSavedOffersScreenState extends State<CandidatSavedOffersScreen> {
  final _offresService = OffresService();
  final _candidaturesService = CandidaturesService();

  final List<_SavedOffer> _saved = [];
  bool _loading = true;
  String? _error;

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
      final rows = await _offresService.getSavedOffres();
      final now = DateTime.now();
      final generated = rows.map((item) {
        final offre = (item['offre'] as Map?)?.cast<String, dynamic>() ?? {};
        final entRaw = offre['entreprise'] ?? offre['entreprises'];
        final entreprise = (entRaw is Map) ? entRaw.cast<String, dynamic>() : <String, dynamic>{};
        final dateRaw =
            item['date_sauvegarde'] ?? item['date_creation'] ?? item['created_at'];
        final savedAt =
            DateTime.tryParse(dateRaw?.toString() ?? '')?.toLocal() ?? now;
        final lim = offre['date_limite']?.toString();
        final expiresAt = lim != null && lim.isNotEmpty
            ? (DateTime.tryParse(lim)?.toLocal() ??
                now.add(const Duration(days: 365)))
            : now.add(const Duration(days: 365));
        return _SavedOffer(
          id: (offre['id'] ?? item['offre_id'] ?? '').toString(),
          title: (offre['titre'] ?? 'Offre').toString(),
          company: (entreprise['nom_entreprise'] ?? 'Entreprise').toString(),
          city: (offre['localisation'] ?? '—').toString(),
          contract: (offre['type_contrat'] ?? '—').toString(),
          scoreIa: null,
          savedAt: savedAt,
          expiresAt: expiresAt,
          statut: (offre['statut'] ?? '').toString(),
        );
      }).toList();
      setState(() {
        _saved
          ..clear()
          ..addAll(generated);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<_SavedOffer> get _recent {
    final now = DateTime.now();
    return _saved
        .where((o) => now.difference(o.savedAt).inDays <= 7)
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  List<_SavedOffer> get _older {
    final now = DateTime.now();
    return _saved
        .where((o) => now.difference(o.savedAt).inDays > 7)
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  Future<void> _apply(_SavedOffer offer) async {
    try {
      await _candidaturesService.postuler(offreId: offer.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Candidature envoyée pour "${offer.title}".')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    if (_saved.isEmpty) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bookmark_outline, size: 40, color: Color(0xFF94A3B8)),
              const SizedBox(height: 10),
              const Text('Vous n\'avez pas encore sauvegardé d\'offres', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Allez dans "Rechercher des offres" pour explorer.')),
                  );
                },
                icon: const Icon(Icons.travel_explore_outlined, size: 16),
                label: const Text('Explorer les offres'),
              ),
            ],
          ),
        ),
      );
    }

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
          const Text('Offres sauvegardées', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text(
            'Retrouvez les offres que vous avez gardées pour postuler plus tard.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          _groupSection(
            title: 'Récemment ajoutées',
            icon: Icons.schedule_outlined,
            items: _recent,
          ),
          const SizedBox(height: 14),
          _groupSection(
            title: 'Plus anciennes',
            icon: Icons.history_outlined,
            items: _older,
          ),
        ],
      ),
    );
  }

  Widget _groupSection({
    required String title,
    required IconData icon,
    required List<_SavedOffer> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF475569)),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(width: 8),
            Text('(${items.length})', style: const TextStyle(color: Color(0xFF64748B))),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map(_tile),
      ],
    );
  }

  Widget _tile(_SavedOffer o) {
    final now = DateTime.now();
    final expired = o.expiresAt.isBefore(now) || (o.statut != 'active' && o.statut != 'publiee');
    final daysLeft = o.expiresAt.difference(now).inDays;
    final almostExpired = !expired && daysLeft <= 3;
    final df = DateFormat('dd/MM/yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: expired ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: expired ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${o.company} • ${o.city} • ${o.contract}',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (expired)
                _chip('EXPIRÉE', const Color(0xFFFEE2E2), const Color(0xFFB91C1C))
              else if (o.scoreIa != null && o.scoreIa! > 0)
                _chip('${o.scoreIa}% IA', const Color(0xFFEFF6FF), const Color(0xFF1E40AF))
              else
                _chip('IA —', const Color(0xFFF1F5F9), const Color(0xFF64748B)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Sauvegardée le ${df.format(o.savedAt)}', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              const SizedBox(width: 8),
              if (almostExpired) _chip('Expire dans $daysLeft j', const Color(0xFFFEF3C7), const Color(0xFF92400E)),
            ],
          ),
          if (expired) ...[
            const SizedBox(height: 8),
            const Text(
              'Cette offre n\'est plus disponible.',
              style: TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!expired)
                ElevatedButton(
                  onPressed: () => _apply(o),
                  child: const Text('Postuler'),
                ),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => CandidatOfferDetailScreen(offreId: o.id)),
                  );
                },
                child: const Text('Voir'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await _offresService.removeSavedOffre(o.id);
                    setState(() => _saved.removeWhere((e) => e.id == o.id));
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                child: const Text('Retirer des favoris'),
              ),
              if (expired)
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Redirection vers offres similaires à brancher.')),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: const Text('Voir offres similaires'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w700)),
    );
  }
}

class _SavedOffer {
  _SavedOffer({
    required this.id,
    required this.title,
    required this.company,
    required this.city,
    required this.contract,
    this.scoreIa,
    required this.savedAt,
    required this.expiresAt,
    this.statut = '',
  });

  final String id;
  final String title;
  final String company;
  final String city;
  final String contract;
  final int? scoreIa;
  final DateTime savedAt;
  final DateTime expiresAt;
  final String statut;
}
