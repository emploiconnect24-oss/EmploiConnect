import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../shared/widgets/logo_widget.dart';
import '../../../shared/widgets/theme_toggle_button.dart';
import '../../../app/public_routes.dart';

class NavbarWidget extends StatelessWidget {
  const NavbarWidget({super.key, required this.isScrolled});

  final bool isScrolled;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isScrolled ? scheme.surface : Colors.transparent,
        boxShadow: isScrolled
            ? [
                BoxShadow(
                  color: context.themeExt.navbarShadow,
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              _buildLogo(isScrolled),
              const Spacer(),
              if (!isMobile) _buildDesktopMenu(context, isScrolled),
              if (isMobile) _buildMobileMenuButton(context, isScrolled),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isScrolled) {
    return Builder(
      builder: (context) => InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.of(context).pushNamed('/landing'),
        child: Row(
          children: [
            LogoWidget(
              height: 38,
              fallbackTextColor: isScrolled
                  ? const Color(0xFF0F172A)
                  : Colors.white,
              fallbackAccentColor: const Color(0xFF1A56DB),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopMenu(BuildContext context, bool isScrolled) {
    final scheme = Theme.of(context).colorScheme;
    final textColor = isScrolled ? scheme.onSurface : Colors.white;
    return Row(
      children: [
        _NavItem(
          label: 'Accueil',
          icon: Icons.home_outlined,
          color: textColor,
          onTap: () => Navigator.of(context).pushNamed('/landing'),
        ),
        const SizedBox(width: 32),
        _NavItem(
          label: "Offres d'emploi",
          icon: Icons.work_outline,
          color: textColor,
          onTap: () =>
              Navigator.of(context).pushNamed(PublicRoutes.listPath),
        ),
        const SizedBox(width: 32),
        ThemeToggleButton(showLabel: false),
        const SizedBox(width: 14),
        OutlinedButton.icon(
          icon: const Icon(Icons.login_outlined, size: 16),
          label: const Text('Connexion'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(120, 44),
            foregroundColor: isScrolled ? scheme.primary : Colors.white,
            side: BorderSide(color: isScrolled ? scheme.primary : Colors.white),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => Navigator.of(context).pushNamed('/login'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.person_add_outlined, size: 16),
          label: const Text('Inscription'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(120, 44),
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          onPressed: () => Navigator.of(context).pushNamed('/register'),
        ),
      ],
    );
  }

  Widget _buildMobileMenuButton(BuildContext context, bool isScrolled) {
    final scheme = Theme.of(context).colorScheme;
    return Builder(
      builder: (ctx) => IconButton(
        tooltip: 'Ouvrir le menu',
        icon: Icon(
          Icons.menu_rounded,
          color: isScrolled ? scheme.onSurface : Colors.white,
          size: 28,
        ),
        onPressed: () => Scaffold.of(ctx).openEndDrawer(),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
