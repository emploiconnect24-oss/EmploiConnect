import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme_extension.dart';
import 'home_design_tokens.dart';

/// CTA finale — fond animé bleu très léger, boutons dégradé / outline bleu.
class HomeCtaSection extends StatefulWidget {
  const HomeCtaSection({super.key});

  @override
  State<HomeCtaSection> createState() => _HomeCtaSectionState();
}

class _HomeCtaSectionState extends State<HomeCtaSection> with SingleTickerProviderStateMixin {
  late final AnimationController _wave;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final margin = w < 700 ? 16.0 : 40.0;
    final padH = w < 700 ? 22.0 : 48.0;
    final padV = w < 700 ? 32.0 : 44.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(margin, 12, margin, 40),
      child: AnimatedBuilder(
        animation: _wave,
        builder: (context, _) {
          final t = _wave.value;
          final ax = math.cos(t * math.pi * 2) * 0.35;
          final ay = math.sin(t * math.pi * 2) * 0.25;
          final a = Alignment(ax, ay);
          final dark = context.isDark;
          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: a,
                end: Alignment(-ax, -ay),
                colors: dark
                    ? const [
                        Color(0xFF0F172A),
                        Color(0xFF1A2F5E),
                        Color(0xFF0F172A),
                      ]
                    : [
                        HomeDesign.surfaceBlue,
                        const Color(0xFFE0F2FE),
                        HomeDesign.surfaceBlue,
                      ],
                stops: const [0.0, 0.52, 1.0],
              ),
              border: Border.all(color: HomeDesign.primary.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: HomeDesign.primary.withValues(alpha: 0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -20,
                  top: -24,
                  child: IgnorePointer(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: HomeDesign.primaryLight.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -30,
                  bottom: -36,
                  child: IgnorePointer(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: HomeDesign.primary.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      'Votre prochaine étape',
                      style: GoogleFonts.poppins(
                        fontSize: w < 600 ? 26 : 32,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.15,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(duration: 550.ms, curve: Curves.easeOutCubic)
                        .slideY(begin: 0.06, duration: 550.ms, curve: Curves.easeOutCubic),
                    const SizedBox(height: 12),
                    Text(
                      'Créez un compte en quelques minutes et accédez aux offres, au matching et aux outils IA.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.55,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(delay: 90.ms, duration: 550.ms, curve: Curves.easeOutCubic),
                    const SizedBox(height: 28),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      alignment: WrapAlignment.center,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: HomeDesign.gradientBrand,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: HomeDesign.primary.withValues(alpha: 0.3),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.person_add_rounded, size: 18, color: Colors.white),
                            label: Text(
                              'Je cherche un emploi',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => Navigator.of(context).pushNamed('/register'),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 160.ms, duration: 450.ms)
                            .scale(
                              begin: const Offset(0.92, 0.92),
                              delay: 160.ms,
                              duration: 450.ms,
                              curve: Curves.easeOutBack,
                            ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.business_rounded, size: 18, color: HomeDesign.primary),
                          label: Text(
                            'Je recrute',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: HomeDesign.primary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: HomeDesign.primary.withValues(alpha: 0.45)),
                            foregroundColor: HomeDesign.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => Navigator.of(context).pushNamed('/register'),
                        )
                            .animate()
                            .fadeIn(delay: 220.ms, duration: 450.ms)
                            .slideX(begin: 0.04, delay: 220.ms, duration: 450.ms, curve: Curves.easeOutCubic),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
