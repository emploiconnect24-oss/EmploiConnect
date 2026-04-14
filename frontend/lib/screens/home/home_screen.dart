import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app/public_routes.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/theme_extension.dart';
import '../../providers/app_config_provider.dart';
import 'home_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const double _kMobileDrawerHeaderHeight = 88;

  Widget _drawerLogo(bool isNarrow) {
    final size = isNarrow ? 34.0 : 40.0;
    return Consumer<AppConfigProvider>(
      builder: (context, cfg, _) {
        final logoUrl = cfg.logoUrl.trim();
        if (logoUrl.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              logoUrl,
              height: size,
              width: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _drawerLogoFallback(isNarrow),
            ),
          );
        }
        return _drawerLogoFallback(isNarrow);
      },
    );
  }

  Widget _drawerLogoFallback(bool isNarrow) => Container(
    width: isNarrow ? 34 : 40,
    height: isNarrow ? 34 : 40,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Center(
      child: Text(
        'E',
        style: TextStyle(
          color: Colors.white,
          fontSize: isNarrow ? 17 : 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );

  Widget _buildMenuMobile(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isNarrow = w < 360;
    final cs = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.82,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: Container(
        color: cs.surface,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                constraints: BoxConstraints(minHeight: isNarrow ? 80 : _kMobileDrawerHeaderHeight),
                padding: EdgeInsets.fromLTRB(isNarrow ? 14 : 20, isNarrow ? 14 : 18, isNarrow ? 14 : 20, isNarrow ? 12 : 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: const [Color(0xFF1A56DB), Color(0xFF3B82F6)],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A1A56DB),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _drawerLogo(isNarrow),
                    SizedBox(width: isNarrow ? 8 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EmploiConnect',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: isNarrow ? 15 : 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Guinée · Emploi & Carrière',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: isNarrow ? 10 : 11, color: Colors.white.withValues(alpha: 0.82)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: isNarrow ? 6 : 10),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: isNarrow ? 28 : 30,
                        height: isNarrow ? 28 : 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: isNarrow ? 8 : 12, vertical: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
                      child: Text(
                        'NAVIGATION',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    _DrawerItemClair(
                      icone: Icons.home_rounded,
                      titre: 'Accueil',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed('/landing');
                      },
                    ),
                    _DrawerItemClair(
                      icone: Icons.work_outline_rounded,
                      titre: 'Offres d\'emploi',
                      badge: 'Nouveau',
                      couleur: const Color(0xFF1A56DB),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed(PublicRoutes.listPath);
                      },
                    ),
                    _DrawerItemClair(
                      icone: Icons.business_outlined,
                      titre: 'Entreprises',
                      onTap: () => Navigator.pop(context),
                    ),
                    _DrawerItemClair(
                      icone: Icons.school_outlined,
                      titre: 'Parcours Carrière',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed('/parcours');
                      },
                    ),
                    _DrawerItemClair(
                      icone: Icons.info_outline_rounded,
                      titre: 'À propos',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed('/a-propos');
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 20, 8, 6),
                      child: Text(
                        'OUTILS IA',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    _DrawerItemClair(
                      icone: Icons.psychology_rounded,
                      titre: 'Simulateur entretien',
                      couleur: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed('/register');
                      },
                    ),
                    _DrawerItemClair(
                      icone: Icons.calculate_rounded,
                      titre: 'Calculateur salaire',
                      couleur: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).pushNamed('/register');
                      },
                    ),
                    const SizedBox(height: 8),
                    Divider(color: ext.cardBorder),
                    const SizedBox(height: 4),
                    const _DrawerItemToggleClair(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: ext.cardBorder)),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF1A56DB)),
                          foregroundColor: const Color(0xFF1A56DB),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.of(context).pushNamed('/login');
                        },
                        child: Text(
                          'Se connecter',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A56DB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.of(context).pushNamed('/register');
                        },
                        child: Text(
                          'S\'inscrire',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      drawer: _buildMenuMobile(context),
      body: HomePage(onOpenMenu: () => _scaffoldKey.currentState?.openDrawer()),
    );
  }
}

class _DrawerItemClair extends StatelessWidget {
  const _DrawerItemClair({
    required this.icone,
    required this.titre,
    required this.onTap,
    this.badge,
    this.couleur,
  });

  final IconData icone;
  final String titre;
  final String? badge;
  final Color? couleur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 360;
    final cs = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    final c = couleur ?? cs.onSurfaceVariant;
    return ListTile(
      dense: true,
      minLeadingWidth: isNarrow ? 30 : 34,
      contentPadding: EdgeInsets.symmetric(horizontal: isNarrow ? 6 : 8, vertical: 1),
      leading: Container(
        width: isNarrow ? 30 : 34,
        height: isNarrow ? 30 : 34,
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icone, color: c, size: isNarrow ? 16 : 18),
      ),
      title: Text(
        titre,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(fontSize: isNarrow ? 13 : 14, color: cs.onSurface, fontWeight: FontWeight.w500),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                badge!,
                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            )
          : Icon(Icons.arrow_forward_ios_rounded, color: cs.outline.withValues(alpha: 0.6), size: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor: Colors.transparent,
      hoverColor: ext.sectionBg.withValues(alpha: 0.6),
      onTap: onTap,
    );
  }
}

class _DrawerItemToggleClair extends StatelessWidget {
  const _DrawerItemToggleClair();

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 360;
    final isDark = context.watch<ThemeProvider>().isDark(context);
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      minLeadingWidth: isNarrow ? 30 : 34,
      contentPadding: EdgeInsets.symmetric(horizontal: isNarrow ? 6 : 8, vertical: 1),
      leading: Container(
        width: isNarrow ? 30 : 34,
        height: isNarrow ? 30 : 34,
        decoration: BoxDecoration(
          color: const Color(0xFF1A56DB).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          color: const Color(0xFF1A56DB),
          size: isNarrow ? 16 : 18,
        ),
      ),
      title: Text(
        isDark ? 'Mode clair' : 'Mode sombre',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(fontSize: isNarrow ? 13 : 14, color: cs.onSurface, fontWeight: FontWeight.w500),
      ),
      trailing: Switch(
        value: isDark,
        activeThumbColor: const Color(0xFF1A56DB),
        activeTrackColor: const Color(0xFF1A56DB).withValues(alpha: 0.3),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onChanged: (_) => context.read<ThemeProvider>().toggleTheme(context),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () => context.read<ThemeProvider>().toggleTheme(context),
    );
  }
}

