import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/public_routes.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../providers/app_config_provider.dart';
import '../../../providers/auth_provider.dart';
import 'home_design_tokens.dart';

/// Header accueil — fond blanc, ombre au scroll, thème clair/sombre.
class HomeHeaderWidget extends StatelessWidget {
  /// Non-`const` volontairement : le hot reload rejette parfois les changements sur les widgets `const`
  /// (ex. suppression de champs statiques).
  // ignore: prefer_const_constructors_in_immutables
  HomeHeaderWidget({
    super.key,
    required this.isScrolled,
    this.onOpenMenu,
  });

  final bool isScrolled;
  final VoidCallback? onOpenMenu;

  static void _about(BuildContext context) {
    Navigator.of(context).pushNamed('/a-propos');
  }

  static void _parcours(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn && auth.role == 'chercheur') {
      Navigator.of(context).pushNamed('/dashboard/parcours');
    } else {
      Navigator.of(context).pushNamed('/register');
    }
  }

  Widget _themeToggle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) {
        final dark = theme.isDark(context);
        return IconButton(
          tooltip: dark ? 'Mode clair' : 'Mode sombre',
          onPressed: () => theme.toggleTheme(context),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              key: ValueKey<bool>(dark),
              color: cs.onSurface,
              size: 22,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final wide = w > 900;
    final padH = w < 600 ? 16.0 : 24.0;
    final cs = Theme.of(context).colorScheme;
    final isDark = context.watch<ThemeProvider>().isDark(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: isScrolled
            ? [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 2),
                ),
              ]
            : const [],
      ),
      child: Row(
        children: [
          Row(
            children: [
              Consumer<AppConfigProvider>(
                builder: (context, cfg, _) {
                  final logoUrl = cfg.logoUrl.trim();
                  if (logoUrl.isNotEmpty) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        logoUrl,
                        height: 42,
                        width: 42,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const _HeaderLogoFallback(),
                      ),
                    );
                  }
                  return const _HeaderLogoFallback();
                },
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer<AppConfigProvider>(
                    builder: (context, cfg, _) {
                      return Text(
                        cfg.nomPlateforme,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      );
                    },
                  ),
                  Text(
                    'Guinée · Plateforme d\'emploi',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          if (!wide) ...[
            _themeToggle(context),
            const SizedBox(width: 4),
          ],
          if (!wide && onOpenMenu != null)
            IconButton(
              icon: Icon(Icons.menu_rounded, color: cs.onSurface),
              onPressed: onOpenMenu,
            ),
          if (wide) ...[
            _NavItem(
              'Offres d\'emploi',
              () => Navigator.of(context).pushNamed(PublicRoutes.listPath),
              muted: cs.onSurfaceVariant,
            ),
            _NavItem(
              'Entreprises',
              () => Navigator.of(context).pushNamed(PublicRoutes.listPath),
              muted: cs.onSurfaceVariant,
            ),
            _NavItem('Parcours Carrière', () => _parcours(context), muted: cs.onSurfaceVariant),
            _NavItem('À propos', () => _about(context), muted: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            _themeToggle(context),
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.38) : const Color(0xFF1A56DB),
                ),
                foregroundColor: isDark ? Colors.white : const Color(0xFF1A56DB),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(context).pushNamed('/login'),
              child: Text(
                'Connexion',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: HomeDesign.gradientBrand,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: HomeDesign.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.of(context).pushNamed('/register'),
                child: Text(
                  'S\'inscrire gratuitement',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderLogoFallback extends StatelessWidget {
  const _HeaderLogoFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: HomeDesign.gradientBrand,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: HomeDesign.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'E',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem(this.titre, this.onTap, {required this.muted});

  final String titre;
  final VoidCallback onTap;
  final Color muted;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _hovered ? HomeDesign.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            widget.titre,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _hovered ? HomeDesign.primary : widget.muted,
            ),
          ),
        ),
      ),
    );
  }
}
