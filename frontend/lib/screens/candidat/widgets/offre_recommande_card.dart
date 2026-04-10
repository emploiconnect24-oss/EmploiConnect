import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/candidat_provider.dart';
import '../../../services/offres_service.dart';
import '../candidat_offer_detail_screen.dart';

/// Carte offre recommandée — grille dashboard (PRD §1).
class OffreRecommandeCard extends StatefulWidget {
  const OffreRecommandeCard({
    super.key,
    required this.offre,
    required this.index,
  });

  final Map<String, dynamic> offre;
  final int index;

  @override
  State<OffreRecommandeCard> createState() => _OffreRecommandeCardState();
}

class _OffreRecommandeCardState extends State<OffreRecommandeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scoreAnimation;
  bool _savedLocal = false;
  bool _saveBusy = false;

  Map<String, dynamic> _entrepriseMap() {
    final o = widget.offre;
    final e = o['entreprise'] ?? o['entreprises'];
    if (e is List && e.isNotEmpty && e.first is Map) {
      return Map<String, dynamic>.from(e.first as Map);
    }
    if (e is Map) return Map<String, dynamic>.from(e);
    return {};
  }

  int _score() {
    final raw = widget.offre['_score'] ?? widget.offre['score_compatibilite'];
    if (raw is num) return raw.round().clamp(0, 100);
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    final s = _score();
    _scoreAnimation = Tween<double>(begin: 0, end: s / 100).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    Future<void>.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _scoreColor(int s) {
    if (s >= 80) return const Color(0xFF10B981);
    if (s >= 60) return const Color(0xFF1A56DB);
    if (s >= 40) return const Color(0xFFF59E0B);
    if (s > 0) return const Color(0xFFEF4444);
    return const Color(0xFF94A3B8);
  }

  Future<void> _toggleSave(String offreId) async {
    if (_saveBusy || offreId.isEmpty) return;
    setState(() => _saveBusy = true);
    final svc = OffresService();
    try {
      if (_savedLocal) {
        await svc.removeSavedOffre(offreId);
        if (mounted) setState(() => _savedLocal = false);
      } else {
        await svc.saveOffre(offreId);
        if (mounted) setState(() => _savedLocal = true);
      }
      if (mounted) await context.read<CandidatProvider>().loadDashboardMetrics();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de mettre à jour la sauvegarde.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saveBusy = false);
    }
  }

  String _fmtSalaire(num? s) {
    if (s == null) return '';
    final v = s.round();
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).round()}K';
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.offre;
    final titre = (o['titre'] ?? '').toString();
    final ent = _entrepriseMap();
    final nom = (ent['nom_entreprise'] ?? '').toString();
    final logo = ent['logo_url']?.toString();
    final loc = (o['localisation'] ?? '').toString();
    final contrat = (o['type_contrat'] ?? '').toString();
    final sMin = o['salaire_min'];
    final num? salaireNum = sMin is num ? sMin : num.tryParse(sMin?.toString() ?? '');
    final devise = (o['devise'] ?? 'GNF').toString();
    final score = _score();
    final vedette = o['en_vedette'] == true;
    final offreId = (o['id'] ?? '').toString();
    final savedApi = o['est_sauvegardee'] == true;
    final saved = savedApi || _savedLocal;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: score >= 70
                  ? const Color(0xFF10B981).withValues(alpha: 0.35)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: score >= 70
                    ? const Color(0xFF10B981).withValues(alpha: 0.08)
                    : const Color(0x06000000),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _scoreColor(score).withValues(alpha: 0.07),
                      Colors.white,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _scoreAnimation,
                      builder: (context, _) {
                        return Row(
                          children: [
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const CircularProgressIndicator(
                                    value: 1,
                                    strokeWidth: 4,
                                    color: Color(0xFFF1F5F9),
                                  ),
                                  CircularProgressIndicator(
                                    value: _scoreAnimation.value.clamp(0.0, 1.0),
                                    strokeWidth: 4,
                                    backgroundColor: Colors.transparent,
                                    color: _scoreColor(score),
                                  ),
                                  Text(
                                    score > 0 ? '$score%' : '—',
                                    style: GoogleFonts.poppins(
                                      fontSize: score > 0 ? 10 : 12,
                                      fontWeight: FontWeight.w800,
                                      color: _scoreColor(score),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  score >= 80
                                      ? 'Excellent !'
                                      : score >= 60
                                          ? 'Bon match'
                                          : score >= 40
                                              ? 'Moyen'
                                              : score > 0
                                                  ? 'Faible'
                                                  : 'Non calculé',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _scoreColor(score),
                                  ),
                                ),
                                Text(
                                  'Compatibilité IA',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (vedette)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 10, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 2),
                                Text(
                                  'Vedette',
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _saveBusy ? null : () => _toggleSave(offreId),
                          child: Icon(
                            saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            size: 20,
                            color: saved ? const Color(0xFF1A56DB) : const Color(0xFFCBD5E1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: logo != null && logo.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: logo,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => _initialeLogo(nom),
                                  )
                                : _initialeLogo(nom),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              nom.isEmpty ? 'Entreprise' : nom,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        titre.isEmpty ? 'Offre' : titre,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          if (loc.isNotEmpty) _MiniTag(Icons.location_on_outlined, loc),
                          if (contrat.isNotEmpty) _MiniTag(Icons.work_outline_rounded, contrat),
                          if (salaireNum != null)
                            _MiniTag(Icons.payments_outlined, '${_fmtSalaire(salaireNum)} $devise'),
                        ],
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A56DB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: offreId.isEmpty
                              ? null
                              : () {
                                  Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      builder: (_) => CandidatOfferDetailScreen(offreId: offreId),
                                    ),
                                  );
                                },
                          child: const Text('Postuler'),
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
    );
  }

  Widget _initialeLogo(String nom) {
    return Center(
      child: Text(
        nom.isNotEmpty ? nom[0].toUpperCase() : '?',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A56DB),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 3),
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
