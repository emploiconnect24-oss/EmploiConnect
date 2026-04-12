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
  const HomeHeaderWidget({
    super.key,
    required this.isScrolled,
    this.onOpenMenu,
  });

  final bool isScrolled;
  final VoidCallback? onOpenMenu;

  static const Color _textDark = Color(0xFF0F172A);
  static const Color _navGrey = Color(0xFF374151);

  static void _about(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('À propos', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'EmploiConnect connecte les talents aux entreprises en Guinée. '
          'Parcours candidat, matching et outils pour avancer dans votre carrière.',
          style: GoogleFonts.inter(height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        ],
      ),
    );
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
              color: _navGrey,
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: isScrolled
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
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
                  Text(
                    'EmploiConnect',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                  Text(
                    'Guinée · Plateforme d\'emploi',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: const Color(0xFF94A3B8),
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
              icon: const Icon(Icons.menu_rounded, color: _navGrey),
              onPressed: onOpenMenu,
            ),
          if (wide) ...[
            _NavItem(
              'Offres d\'emploi',
              () => Navigator.of(context).pushNamed(PublicRoutes.listPath),
            ),
            _NavItem(
              'Entreprises',
              () => Navigator.of(context).pushNamed(PublicRoutes.listPath),
            ),
            _NavItem('Parcours Carrière', () => _parcours(context)),
            _NavItem('À propos', () => _about(context)),
            const SizedBox(width: 12),
            _themeToggle(context),
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1A56DB)),
                foregroundColor: const Color(0xFF1A56DB),
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
  const _NavItem(this.titre, this.onTap);

  final String titre;
  final VoidCallback onTap;

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
              color: _hovered ? HomeDesign.primary : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }
}
