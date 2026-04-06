import 'package:flutter/material.dart';
import 'home/widgets/top_entreprises_marquee_section_widget.dart';
import '../shared/widgets/logo_widget.dart';
import '../widgets/responsive_container.dart';
import '../widgets/carousel_banner.dart';
import '../widgets/hover_scale.dart';
import '../widgets/reveal_on_scroll.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const orange = Color(0xFFFF8A00);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: ResponsiveContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Row(
                      children: [
                        const LogoWidget(
                          height: 38,
                          fallbackTextColor: Color(0xFF0F172A),
                          fallbackAccentColor: Color(0xFF1A56DB),
                        ),
                      ],
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/login'),
                      child: const Text('Connexion'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/register'),
                      child: const Text('Inscription'),
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // HERO - bannière (hauteur réduite) + texte/CTA séparés (pro, non encombré)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      child: CarouselBanner(
                        messages: defaultBanners(),
                        height: 260,
                        fullBleed: true,
                      ),
                    ),

                    const SizedBox(height: 14),

                    ResponsiveContainer(
                      child: RevealOnScroll(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Plateforme intelligente d’offres et de recherche d’emploi',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'EmploiConnect centralise les offres, les candidatures et le matching IA '
                                        'pour accélérer le recrutement et l’accès à l’emploi en Guinée.',
                                        style: TextStyle(
                                          color: scheme.onSurfaceVariant,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: [
                                          HoverScale(
                                            onTap: () => Navigator.of(
                                              context,
                                            ).pushNamed('/register'),
                                            child: FilledButton.icon(
                                              style: FilledButton.styleFrom(
                                                backgroundColor: orange,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 18,
                                                      vertical: 14,
                                                    ),
                                              ),
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pushNamed('/register'),
                                              icon: const Icon(
                                                Icons.rocket_launch,
                                              ),
                                              label: const Text(
                                                'Créer un compte',
                                              ),
                                            ),
                                          ),
                                          HoverScale(
                                            onTap: () => Navigator.of(
                                              context,
                                            ).pushNamed('/login'),
                                            child: OutlinedButton.icon(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pushNamed('/login'),
                                              icon: const Icon(Icons.login),
                                              label: const Text('Se connecter'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 220,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: scheme.primary.withValues(
                                      alpha: 0.06,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: scheme.primary.withValues(
                                        alpha: 0.14,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Conseil',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: scheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Pour des suggestions IA, téléversez votre CV après inscription.',
                                        style: TextStyle(
                                          color: scheme.onSurfaceVariant,
                                          height: 1.35,
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
                    ),

                    const SizedBox(height: 18),

                    // Solutions section
                    RevealOnScroll(
                      child: ResponsiveContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Découvrir nos solutions',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Trois espaces, une seule plateforme : chercheur d’emploi, entreprise et administrateur.',
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, c) {
                                final isNarrow = c.maxWidth < 820;
                                final children = [
                                  HoverScale(
                                    child: _SolutionCard(
                                      icon: Icons.person_search,
                                      title: 'Chercheur d’emploi',
                                      bullets: const [
                                        'Créer un compte et gérer son profil',
                                        'Téléverser son CV (PDF/DOCX)',
                                        'Voir des suggestions d’offres compatibles',
                                        'Postuler et suivre ses candidatures',
                                      ],
                                      accent: scheme.primary,
                                    ),
                                  ),
                                  HoverScale(
                                    child: _SolutionCard(
                                      icon: Icons.apartment,
                                      title: 'Entreprise / Recruteur',
                                      bullets: const [
                                        'Publier, modifier et supprimer des offres',
                                        'Suivre les candidatures reçues',
                                        'Changer le statut des candidatures',
                                        'Accéder au lien CV (URL signée)',
                                      ],
                                      accent: orange,
                                    ),
                                  ),
                                  HoverScale(
                                    child: _SolutionCard(
                                      icon: Icons.admin_panel_settings,
                                      title: 'Administrateur',
                                      bullets: const [
                                        'Valider et activer/désactiver les comptes',
                                        'Consulter les statistiques globales',
                                        'Traiter les signalements',
                                        'Garantir la conformité des contenus',
                                      ],
                                      accent: const Color(0xFF0F6D2B),
                                    ),
                                  ),
                                ];

                                if (isNarrow) {
                                  return Column(
                                    children: [
                                      for (final w in children) ...[
                                        w,
                                        const SizedBox(height: 10),
                                      ],
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (
                                      int i = 0;
                                      i < children.length;
                                      i++
                                    ) ...[
                                      Expanded(child: children[i]),
                                      if (i != children.length - 1)
                                        const SizedBox(width: 12),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // CTA section
                    RevealOnScroll(
                      child: ResponsiveContainer(
                        child: Card(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  scheme.primary.withValues(alpha: 0.10),
                                  orange.withValues(alpha: 0.10),
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Passe à l’action',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Crée ton compte et commence dès maintenant : '
                                          'publie une offre, téléverse un CV, reçois des suggestions et suis tes candidatures.',
                                          style: TextStyle(
                                            color: scheme.onSurfaceVariant,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  HoverScale(
                                    onTap: () => Navigator.of(
                                      context,
                                    ).pushNamed('/register'),
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: orange,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 14,
                                        ),
                                      ),
                                      onPressed: () => Navigator.of(
                                        context,
                                      ).pushNamed('/register'),
                                      child: const Text('Commencer'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    const TopEntreprisesMarqueeSectionWidget(),

                    const SizedBox(height: 22),

                    // Footer
                    Container(
                      width: double.infinity,
                      color: const Color(0xFF0B1220),
                      child: ResponsiveContainer(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 18,
                        ),
                        child: Column(
                          children: [
                            LayoutBuilder(
                              builder: (context, c) {
                                final narrow = c.maxWidth < 820;
                                final cols = [
                                  _FooterCol(
                                    title: 'EmploiConnect',
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'EmploiConnect est une plateforme intelligente de mise en relation '
                                          'entre chercheurs d’emploi et entreprises en Guinée.',
                                          style: TextStyle(
                                            color: Color(0xFFCBD5E1),
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: const [
                                            _SocialIcon(Icons.facebook),
                                            SizedBox(width: 10),
                                            _SocialIcon(Icons.telegram),
                                            SizedBox(width: 10),
                                            // Material Icons ne contient pas "whatsapp" par défaut
                                            _SocialIcon(Icons.chat),
                                            SizedBox(width: 10),
                                            _SocialIcon(Icons.link),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  _FooterCol(
                                    title: 'Liens utiles',
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _FooterLink(
                                          label: 'Connexion',
                                          onTap: () => Navigator.of(
                                            context,
                                          ).pushNamed('/login'),
                                        ),
                                        _FooterLink(
                                          label: 'Inscription',
                                          onTap: () => Navigator.of(
                                            context,
                                          ).pushNamed('/register'),
                                        ),
                                        const _FooterLink(
                                          label: 'Offres (après connexion)',
                                        ),
                                        const _FooterLink(
                                          label: 'Suggestions (après CV)',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const _FooterCol(
                                    title: 'À propos',
                                    child: Text(
                                      'Plateforme développée dans le cadre d’un projet académique (2025–2026).\n'
                                      'Objectif : digitaliser et optimiser le recrutement.',
                                      style: TextStyle(
                                        color: Color(0xFFCBD5E1),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ];

                                if (narrow) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      cols[0],
                                      const SizedBox(height: 14),
                                      cols[1],
                                      const SizedBox(height: 14),
                                      cols[2],
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: cols[0]),
                                    const SizedBox(width: 16),
                                    Expanded(child: cols[1]),
                                    const SizedBox(width: 16),
                                    Expanded(child: cols[2]),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 1,
                              color: const Color(0xFF1F2937),
                            ),
                            const SizedBox(height: 12),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '© 2026 EmploiConnect — Tous droits réservés.',
                                style: TextStyle(color: Color(0xFF94A3B8)),
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
          ],
        ),
      ),
    );
  }
}

class _SolutionCard extends StatelessWidget {
  const _SolutionCard({
    required this.icon,
    required this.title,
    required this.bullets,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final List<String> bullets;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withValues(alpha: 0.18)),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            for (final b in bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FooterCol extends StatelessWidget {
  const _FooterCol({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final w = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          color: const Color(0xFFCBD5E1),
          decoration: onTap != null
              ? TextDecoration.underline
              : TextDecoration.none,
        ),
      ),
    );
    if (onTap == null) return w;
    return InkWell(onTap: onTap, child: w);
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 18),
    );
  }
}
