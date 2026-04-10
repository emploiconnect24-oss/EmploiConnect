import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Carte offre « recommandations IA » (PRD §6) : entrée échelonnée, score animé, logo, actions.
class OffreIACard extends StatefulWidget {
  const OffreIACard({
    super.key,
    required this.offre,
    this.index = 0,
    this.onPostuler,
    this.onSauvegarder,
    this.onIgnorer,
    this.estSauvegardee = false,
  });

  final Map<String, dynamic> offre;

  /// Index dans la grille pour décaler l’animation (PRD : 80 ms × index).
  final int index;
  final VoidCallback? onPostuler;
  final VoidCallback? onSauvegarder;
  final VoidCallback? onIgnorer;
  final bool estSauvegardee;

  @override
  State<OffreIACard> createState() => _OffreIACardState();
}

class _OffreIACardState extends State<OffreIACard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<double>(
      begin: 20,
      end: 0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    final delayMs = 80 * widget.index.clamp(0, 24);
    Future<void>.delayed(Duration(milliseconds: delayMs), () {
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
    final entreprise =
        (widget.offre['entreprise'] as Map?)?.cast<String, dynamic>() ??
        (widget.offre['entreprises'] as Map?)?.cast<String, dynamic>() ??
        {};
    final titre = (widget.offre['titre'] ?? '').toString();
    final nomEnt = (entreprise['nom_entreprise'] ?? 'Entreprise').toString();
    final logoUrl = (entreprise['logo_url'] ?? '').toString().trim();
    final localisation = (widget.offre['localisation'] ?? '').toString();
    final contrat = (widget.offre['type_contrat'] ?? '').toString();
    final score = (widget.offre['score_compatibilite'] as num?)?.round() ?? 0;
    final vedette = widget.offre['en_vedette'] == true;
    final ringColor = score >= 80
        ? const Color(0xFF10B981)
        : score >= 60
        ? const Color(0xFF1A56DB)
        : const Color(0xFFF59E0B);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Opacity(
        opacity: _fade.value,
        child: Transform.translate(
          offset: Offset(0, _slide.value),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: vedette
                    ? const Color(0xFFFDE68A)
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D0F172A),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (score > 0) ...[
                                  CircularProgressIndicator(
                                    value: 1,
                                    strokeWidth: 2,
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(
                                      begin: 0,
                                      end: (score.clamp(0, 100)) / 100,
                                    ),
                                    duration: const Duration(milliseconds: 700),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, v, child) =>
                                        CircularProgressIndicator(
                                          value: v,
                                          strokeWidth: 2,
                                          backgroundColor: Colors.transparent,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            ringColor,
                                          ),
                                        ),
                                  ),
                                  TweenAnimationBuilder<int>(
                                    tween: IntTween(
                                      begin: 0,
                                      end: score.clamp(0, 100),
                                    ),
                                    duration: const Duration(milliseconds: 700),
                                    builder: (context, v, child) => Text(
                                      '$v',
                                      style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ] else
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    color: ringColor.withValues(alpha: 0.85),
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: logoUrl.isNotEmpty
                                  ? Image.network(
                                      logoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          _logoFallback(nomEnt),
                                    )
                                  : _logoFallback(nomEnt),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nomEnt,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  titre,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 3,
                        runSpacing: 3,
                        children: [
                          if (localisation.isNotEmpty)
                            _chip(localisation, Icons.location_on_outlined),
                          if (contrat.isNotEmpty)
                            _chip(contrat, Icons.work_outline_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                  child: Row(
                    children: [
                      if (widget.onIgnorer != null)
                        IconButton(
                          onPressed: widget.onIgnorer,
                          icon: const Icon(Icons.close_rounded, size: 18),
                          color: const Color(0xFF94A3B8),
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      if (widget.onSauvegarder != null)
                        IconButton(
                          onPressed: widget.onSauvegarder,
                          icon: Icon(
                            widget.estSauvegardee
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 18,
                          ),
                          color: widget.estSauvegardee
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF64748B),
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      const Spacer(),
                      if (widget.onPostuler != null)
                        Expanded(
                          child: FilledButton(
                            onPressed: widget.onPostuler,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1A56DB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              'Postuler',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
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
      ),
    );
  }

  static Widget _logoFallback(String nomEnt) {
    return ColoredBox(
      color: const Color(0xFFEFF6FF),
      child: Center(
        child: Text(
          nomEnt.isNotEmpty ? nomEnt[0].toUpperCase() : '?',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: Color(0xFF1A56DB),
          ),
        ),
      ),
    );
  }

  static Widget _chip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 8, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
