import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_config_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/candidat_provider.dart';
import '../../../shared/widgets/logo_widget.dart';

class CandidatSidebar extends StatelessWidget {
  const CandidatSidebar({
    super.key,
    required this.currentRoute,
    required this.onRouteSelected,
    required this.onLogout,
    this.isDrawer = false,
  });

  final String currentRoute;
  final ValueChanged<String> onRouteSelected;
  final VoidCallback onLogout;
  final bool isDrawer;

  static const _items = <_CandidatMenuSection>[
    _CandidatMenuSection(
      title: 'PRINCIPAL',
      items: [
        _CandidatMenuItem(
          label: 'Vue d\'ensemble',
          route: '/dashboard',
          icon: Icons.dashboard_rounded,
        ),
        _CandidatMenuItem(
          label: 'Recherche d\'offres',
          route: '/dashboard/offres',
          icon: Icons.search_rounded,
        ),
        _CandidatMenuItem(
          label: 'Recommandations IA',
          route: '/dashboard/recommandations',
          icon: Icons.auto_awesome_rounded,
        ),
        _CandidatMenuItem(
          label: 'Mes candidatures',
          route: '/dashboard/candidatures',
          icon: Icons.assignment_outlined,
        ),
        _CandidatMenuItem(
          label: 'Offres sauvegardées',
          route: '/dashboard/sauvegardes',
          icon: Icons.bookmark_outline_rounded,
        ),
        _CandidatMenuItem(
          label: 'Parcours Carrière',
          route: '/dashboard/parcours',
          icon: Icons.school_outlined,
        ),
      ],
    ),
    _CandidatMenuSection(
      title: 'MON PROFIL',
      items: [
        _CandidatMenuItem(
          label: 'Mon Profil & CV',
          route: '/dashboard/profil',
          icon: Icons.person_outline_rounded,
        ),
        _CandidatMenuItem(
          label: 'Témoignages',
          route: '/dashboard/temoignage',
          icon: Icons.star_outline_rounded,
        ),
      ],
    ),
    _CandidatMenuSection(
      title: 'COMMUNICATION',
      items: [
        _CandidatMenuItem(
          label: 'Messagerie',
          route: '/dashboard/messages',
          icon: Icons.chat_bubble_outline_rounded,
        ),
        _CandidatMenuItem(
          label: 'Notifications',
          route: '/dashboard/notifications',
          icon: Icons.notifications_outlined,
        ),
      ],
    ),
    _CandidatMenuSection(
      title: 'COMPTE',
      items: [
        _CandidatMenuItem(
          label: 'Paramètres',
          route: '/dashboard/parametres',
          icon: Icons.settings_outlined,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isDrawer ? double.infinity : 240,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E40AF), Color(0xFF1D4ED8), Color(0xFF2563EB)],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 16,
            offset: Offset(3, 0),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildLogoSection(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final section in _items) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
                        child: Text(
                          section.title,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                      ...section.items.map((item) => _buildItem(context, item)),
                    ],
                  ],
                ),
              ),
            ),
            _buildProfilBas(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection(BuildContext context) {
    return Consumer2<CandidatProvider, AuthProvider>(
      builder: (ctx, provider, auth, _) {
        final profile = provider.profile;
        final nom = (profile['nom'] ?? auth.user?['nom'] ?? '').toString();
        final photo = (profile['photo_url'] ?? auth.user?['photo_url'] ?? '').toString();
        final titre = (profile['titre_poste'] ?? '').toString();
        final completion = provider.profileCompletionPercent.clamp(0, 100);

        return Container(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
          decoration: BoxDecoration(
            border: const Border(bottom: BorderSide(color: Color(0x20FFFFFF))),
            color: Colors.black.withValues(alpha: 0.08),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Consumer<AppConfigProvider>(
                    builder: (ctx, cfg, _) => cfg.logoUrl.isNotEmpty
                        ? Image.network(
                            cfg.logoUrl,
                            height: 32,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Text(
                              'EmploiConnect',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const LogoWidget(
                            height: 32,
                            fallbackTextColor: Colors.white,
                            fallbackAccentColor: Color(0xFFBAE6FD),
                          ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      'Candidat',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF34D399),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                          child: photo.isEmpty
                              ? Text(
                                  nom.isNotEmpty ? nom.trim()[0].toUpperCase() : 'C',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nom.isNotEmpty ? nom : 'Mon compte',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                titre.isNotEmpty ? titre : 'Compléter le profil',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: Colors.white.withValues(alpha: 0.55),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => onRouteSelected('/dashboard/profil'),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                              size: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: LinearProgressIndicator(
                              value: completion / 100,
                              minHeight: 4,
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                completion >= 70
                                    ? const Color(0xFF34D399)
                                    : completion >= 40
                                        ? const Color(0xFF60A5FA)
                                        : const Color(0xFFFBBF24),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$completion%',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: completion >= 70
                                ? const Color(0xFF34D399)
                                : const Color(0xFFFBBF24),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfilBas(BuildContext context) {
    return Consumer2<CandidatProvider, AuthProvider>(
      builder: (ctx, provider, auth, _) {
        final profile = provider.profile;
        final nom = (profile['nom'] ?? auth.user?['nom'] ?? 'Candidat').toString();
        final photo = (profile['photo_url'] ?? auth.user?['photo_url'] ?? '').toString();

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          decoration: BoxDecoration(
            border: const Border(top: BorderSide(color: Color(0x20FFFFFF))),
            color: Colors.black.withValues(alpha: 0.12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo.isEmpty
                    ? Text(
                        nom.isNotEmpty ? nom.trim()[0].toUpperCase() : 'C',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nom,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Tooltip(
                message: 'Se déconnecter',
                child: GestureDetector(
                  onTap: onLogout,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFEF4444),
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItem(BuildContext context, _CandidatMenuItem item) {
    final stats = context.watch<CandidatProvider>();
    String? dynamicBadge;
    switch (item.route) {
      case '/dashboard/candidatures':
        dynamicBadge = '${stats.badge('candidatures')}';
        break;
      case '/dashboard/sauvegardes':
        dynamicBadge = '${stats.badge('sauvegardes')}';
        break;
      case '/dashboard/recommandations':
        dynamicBadge = '${stats.badge('recommandations')}';
        break;
      case '/dashboard/messages':
        dynamicBadge = '${stats.badge('messages')}';
        break;
      case '/dashboard/notifications':
        dynamicBadge = '${stats.badge('notifications')}';
        break;
      default:
        dynamicBadge = null;
    }
    if (dynamicBadge == '0') dynamicBadge = null;

    final isActive =
        currentRoute == item.route ||
        (item.route != '/dashboard' && currentRoute.startsWith(item.route));

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.30)
                  : Colors.transparent,
            ),
          ),
          child: InkWell(
            onTap: () => onRouteSelected(item.route),
            borderRadius: BorderRadius.circular(10),
            hoverColor: const Color(0x121A56DB),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 18,
                    color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.70),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  if (dynamicBadge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white.withValues(alpha: 0.25)
                            : const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        (int.tryParse(dynamicBadge) ?? 0) > 99
                            ? '99+'
                            : dynamicBadge,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CandidatMenuSection {
  const _CandidatMenuSection({required this.title, required this.items});
  final String title;
  final List<_CandidatMenuItem> items;
}

class _CandidatMenuItem {
  const _CandidatMenuItem({
    required this.label,
    required this.route,
    required this.icon,
  });

  final String label;
  final String route;
  final IconData icon;
}
