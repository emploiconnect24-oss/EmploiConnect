import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme_extension.dart';
import 'home_design_tokens.dart';

/// PRD v2 §3 — 8 cartes max (2×4), animations d’entrée + hover.
class HomeSolutionsPrdSection extends StatefulWidget {
  const HomeSolutionsPrdSection({super.key});

  @override
  State<HomeSolutionsPrdSection> createState() => _HomeSolutionsPrdSectionState();
}

class _HomeSolutionsPrdSectionState extends State<HomeSolutionsPrdSection> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  static final _solutions = <_Solution>[
    _Solution('🤖', 'Matching IA',
        'Claude analyse votre profil et trouve les offres parfaites pour vous.', HomeDesign.primary, 'Populaire'),
    _Solution('📄', 'Créateur de CV',
        'Générez un CV pro en quelques minutes avec nos modèles optimisés.', HomeDesign.primaryMid, null),
    _Solution('🎤', 'Simulateur IA',
        'Préparez vos entretiens avec notre IA qui simule de vrais recruteurs.', HomeDesign.primary, 'Nouveau'),
    _Solution('💰', 'Calculateur salaire',
        'Estimez votre valeur sur le marché guinéen grâce à l\'IA.', HomeDesign.primaryMid, null),
    _Solution('🔔', 'Alertes emploi',
        'Recevez en temps réel les offres qui correspondent à votre profil.', HomeDesign.primary, null),
    _Solution('🏆', 'Parcours Carrière',
        'Guides, ressources et conseils pour booster votre carrière.', HomeDesign.primaryMid, null),
    _Solution('🏢', 'Vitrine entreprise',
        'Créez votre page entreprise attractive pour attirer les meilleurs.', HomeDesign.primary, null),
    _Solution('📊', 'Analytics recruteur',
        'Suivez vos performances et optimisez vos campagnes de recrutement.', HomeDesign.primaryMid, 'Pro'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    Future<void>.delayed(const Duration(milliseconds: 280), () {
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
    final pad = MediaQuery.sizeOf(context).width < 700 ? 16.0 : 40.0;
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(pad, 20, pad, 44),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              builder: (context, v, child) {
                return Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - v)),
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: HomeDesign.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: HomeDesign.primary.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      'Propulsé par l’IA',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: HomeDesign.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nos solutions',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Des outils intelligents pour candidats\net recruteurs en Guinée',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            LayoutBuilder(
              builder: (context, c) {
                final mw = c.maxWidth;
                final cols = mw < 768 ? 2 : (mw < 1100 ? 2 : 4);
                final gap = mw < 768 ? 10.0 : 14.0;
                final tileW = (mw - gap * (cols - 1)) / cols;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: _solutions.asMap().entries.map((entry) {
                    final i = entry.key;
                    final s = entry.value;
                    final interval = Interval(
                      (i * 0.08).clamp(0.0, 0.7),
                      1,
                      curve: Curves.easeOutBack,
                    );
                    return SizedBox(
                      width: tileW,
                      child: AnimatedBuilder(
                        animation: _ctrl,
                        builder: (context, child) {
                          final v = CurvedAnimation(parent: _ctrl, curve: interval).value;
                          return Opacity(
                            opacity: v.clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(0, 24 * (1 - v)),
                              child: child,
                            ),
                          );
                        },
                        child: _CarteSolution(solution: s, compact: mw < 768),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Solution {
  const _Solution(this.emoji, this.titre, this.desc, this.couleur, this.badge);

  final String emoji;
  final String titre;
  final String desc;
  final Color couleur;
  final String? badge;
}

class _CarteSolution extends StatefulWidget {
  const _CarteSolution({required this.solution, this.compact = false});

  final _Solution solution;
  final bool compact;

  @override
  State<_CarteSolution> createState() => _CarteSolutionState();
}

class _CarteSolutionState extends State<_CarteSolution> with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _ctrl;
  late Animation<double> _elevAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _elevAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.solution;
    final cs = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    final pad = widget.compact ? 14.0 : 20.0;
    final iconBox = widget.compact ? 44.0 : 48.0;
    final emojiSize = widget.compact ? 20.0 : 22.0;
    final titreSize = widget.compact ? 14.0 : 15.0;
    final descSize = widget.compact ? 11.5 : 12.0;
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _ctrl.reverse();
      },
      child: AnimatedBuilder(
        animation: _elevAnim,
        builder: (context, _) {
          return Transform.translate(
            offset: Offset(0, -6 * _elevAnim.value),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(pad),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hovered ? s.couleur.withValues(alpha: 0.4) : ext.cardBorder,
                  width: _hovered ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _hovered ? s.couleur.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.04),
                    blurRadius: _hovered ? 26 : 8,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: iconBox,
                        height: iconBox,
                        decoration: BoxDecoration(
                          color: _hovered ? s.couleur.withValues(alpha: 0.15) : s.couleur.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(child: Text(s.emoji, style: TextStyle(fontSize: emojiSize))),
                      ),
                      SizedBox(height: widget.compact ? 10 : 12),
                      Text(
                        s.titre,
                        style: GoogleFonts.poppins(
                          fontSize: titreSize,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      SizedBox(height: widget.compact ? 4 : 6),
                      Text(
                        s.desc,
                        style: GoogleFonts.inter(
                          fontSize: descSize,
                          color: cs.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 10),
                      AnimatedOpacity(
                        opacity: _hovered ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Row(
                          children: [
                            Text(
                              'En savoir plus',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: s.couleur,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 12, color: s.couleur),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (s.badge != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: s.couleur == HomeDesign.primaryMid
                                ? [HomeDesign.primaryMid, HomeDesign.primaryLight]
                                : [HomeDesign.primaryDeep, HomeDesign.primary],
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          s.badge!,
                          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
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
}
