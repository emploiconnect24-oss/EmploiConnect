import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../core/theme/theme_extension.dart';

class SolutionsSectionWidget extends StatelessWidget {
  const SolutionsSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 900;
    final scheme = Theme.of(context).colorScheme;

    int cols = 3;
    if (w < 700) {
      cols = 1;
    } else if (w < 980) {
      cols = 2;
    }

    final items = const <_SolutionData>[
      _SolutionData(
        title: 'Recherche intelligente',
        description: 'Trouvez plus vite des offres pertinentes grâce à des filtres clairs et un matching optimisé.',
        icon: Icons.search_rounded,
        tint: Color(0xFF1A56DB),
      ),
      _SolutionData(
        title: 'Candidature express',
        description: 'Postulez rapidement et suivez vos candidatures avec un tableau de bord simple.',
        icon: Icons.flash_on_outlined,
        tint: Color(0xFFFF8A00),
      ),
      _SolutionData(
        title: 'Espace recruteur pro',
        description: 'Publiez des offres et gérez les candidatures avec des outils pensés pour les entreprises.',
        icon: Icons.business_center_outlined,
        tint: Color(0xFF7C3AED),
      ),
      _SolutionData(
        title: 'Alertes emploi',
        description: 'Ne ratez aucune opportunité : recevez des alertes et recommandations sur vos offres favorites.',
        icon: Icons.notifications_outlined,
        tint: Color(0xFFEF4444),
      ),
      _SolutionData(
        title: 'Conseils personnalisés',
        description: 'Des conseils pratiques pour améliorer votre CV, réussir vos entretiens et accélérer votre recherche.',
        icon: Icons.lightbulb_outline,
        tint: Color(0xFFF59E0B),
      ),
      _SolutionData(
        title: 'Profil IA optimisé',
        description: 'Analyse CV, extraction des compétences et suggestions plus pertinentes (module IA prévu).',
        icon: Icons.psychology_outlined,
        tint: Color(0xFF10B981),
      ),
    ];

    return Container(
      width: double.infinity,
      color: scheme.surface,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80, vertical: isMobile ? 36 : 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Nos solutions',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 26 : 34,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Des fonctionnalités modernes pour candidats, recruteurs et administrateurs.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: scheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 26),
            LayoutBuilder(
              builder: (context, c) {
                final maxW = c.maxWidth;
                final spacing = 14.0;
                final itemW = (maxW - (cols - 1) * spacing) / cols;
                final itemH = isMobile ? 176.0 : 190.0;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (int i = 0; i < items.length; i++)
                      SizedBox(
                        width: itemW,
                        height: itemH,
                        child: _RevealOnce(
                          key: ValueKey('solution_$i'),
                          delayMs: 100 * i,
                          child: _SolutionCard(items[i]),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SolutionData {
  const _SolutionData({
    required this.title,
    required this.description,
    required this.icon,
    required this.tint,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color tint;
}

class _RevealOnce extends StatefulWidget {
  const _RevealOnce({super.key, required this.child, this.delayMs = 0});

  final Widget child;
  final int delayMs;

  @override
  State<_RevealOnce> createState() => _RevealOnceState();
}

class _RevealOnceState extends State<_RevealOnce> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    if (_shown) return widget.child;

    return VisibilityDetector(
      key: Key('vis_${widget.key ?? UniqueKey()}'),
      onVisibilityChanged: (info) {
        if (_shown) return;
        if (info.visibleFraction >= 0.18) {
          setState(() => _shown = true);
        }
      },
      child: FadeInUp(
        duration: const Duration(milliseconds: 600),
        delay: Duration(milliseconds: widget.delayMs),
        child: widget.child,
      ),
    );
  }
}

class _SolutionCard extends StatefulWidget {
  const _SolutionCard(this.data);

  final _SolutionData data;

  @override
  State<_SolutionCard> createState() => _SolutionCardState();
}

class _SolutionCardState extends State<_SolutionCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hover ? -6 : 0, 0),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ext.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hover ? 0.09 : 0.05),
              blurRadius: _hover ? 26 : 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: widget.data.tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: widget.data.tint.withValues(alpha: 0.18)),
                ),
                child: Icon(widget.data.icon, color: widget.data.tint),
              ),
              const SizedBox(height: 12),
              Text(
                widget.data.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  widget.data.description,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: scheme.onSurfaceVariant,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


