import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/logo_widget.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.currentRoute,
    required this.onRouteSelected,
    required this.onLogout,
    this.collapsed = false,
    this.isDrawer = false,
  });

  final String currentRoute;
  final ValueChanged<String> onRouteSelected;
  final Future<void> Function() onLogout;
  final bool collapsed;
  final bool isDrawer;

  static const List<_SidebarSection> _sections = [
    _SidebarSection(
      title: null,
      items: [
        _SidebarItem(
          label: 'Vue d\'ensemble',
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          route: '/admin',
          permissionSection: 'dashboard',
        ),
      ],
    ),
    _SidebarSection(
      title: 'GESTION',
      items: [
        _SidebarItem(
          label: 'Utilisateurs',
          icon: Icons.people_outline_rounded,
          activeIcon: Icons.people_rounded,
          route: '/admin/utilisateurs',
          permissionSection: 'utilisateurs',
          badgeKey: 'pending_users',
        ),
        _SidebarItem(
          label: 'Offres d\'emploi',
          icon: Icons.work_outline_rounded,
          activeIcon: Icons.work_rounded,
          route: '/admin/offres',
          permissionSection: 'offres',
          badgeKey: 'pending_jobs',
        ),
        _SidebarItem(
          label: 'Entreprises',
          icon: Icons.business_outlined,
          activeIcon: Icons.business_rounded,
          route: '/admin/entreprises',
          permissionSection: 'entreprises',
        ),
        _SidebarItem(
          label: 'Candidatures',
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment_rounded,
          route: '/admin/candidatures',
          permissionSection: 'candidatures',
        ),
        _SidebarItem(
          label: 'Moderation',
          icon: Icons.shield_outlined,
          activeIcon: Icons.shield_rounded,
          route: '/admin/moderation',
          permissionSection: 'signalements',
          badgeKey: 'reports',
          badgeColor: Color(0xFFEF4444),
        ),
        _SidebarItem(
          label: 'Témoignages',
          icon: Icons.format_quote_outlined,
          activeIcon: Icons.format_quote_rounded,
          route: '/admin/temoignages',
          permissionSection: 'temoignages',
          badgeKey: 'pending_testimonials',
          badgeColor: Color(0xFFF59E0B),
        ),
        _SidebarItem(
          label: 'Parcours Carrière',
          icon: Icons.school_outlined,
          activeIcon: Icons.school_rounded,
          route: '/admin/parcours-carriere',
          permissionSection: 'parcours',
        ),
      ],
    ),
    _SidebarSection(
      title: 'ANALYSE',
      items: [
        _SidebarItem(
          label: 'Statistiques',
          icon: Icons.bar_chart_outlined,
          activeIcon: Icons.bar_chart_rounded,
          route: '/admin/statistiques',
          permissionSection: 'statistiques',
        ),
      ],
    ),
    _SidebarSection(
      title: 'CONTENU',
      items: [
        _SidebarItem(
          label: 'Newsletter',
          icon: Icons.campaign_outlined,
          activeIcon: Icons.campaign_rounded,
          route: '/admin/newsletter',
          permissionSection: 'newsletter',
        ),
        _SidebarItem(
          label: 'Messages Contact',
          icon: Icons.mail_outlined,
          activeIcon: Icons.mail_rounded,
          route: '/admin/messages-contact',
          permissionSection: 'messages_contact',
          badgeKey: 'contact_messages_unread',
          badgeColor: Color(0xFFEF4444),
        ),
      ],
    ),
    _SidebarSection(
      title: 'CONFIGURATION',
      items: [
        _SidebarItem(
          label: 'Recherche globale',
          icon: Icons.search_outlined,
          activeIcon: Icons.search_rounded,
          route: '/admin/recherche',
          permissionSection: 'recherche',
        ),
        _SidebarItem(
          label: 'Notifications',
          icon: Icons.notifications_none_rounded,
          activeIcon: Icons.notifications_rounded,
          route: '/admin/notifications',
          permissionSection: 'messages',
        ),
        _SidebarItem(
          label: 'Parametres',
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings_rounded,
          route: '/admin/parametres',
          superOnly: true,
        ),
        _SidebarItem(
          label: 'Gestion des accès',
          icon: Icons.admin_panel_settings_outlined,
          activeIcon: Icons.admin_panel_settings_rounded,
          route: '/admin/acces',
          superOnly: true,
        ),
      ],
    ),
  ];

  static bool _itemVisible(AdminProvider admin, _SidebarItem item) {
    if (!admin.adminAccessLoaded) return true;
    if (item.superOnly) return admin.adminEstSuper;
    final key = item.permissionSection;
    if (key == null || key.isEmpty) return true;
    return admin.peutVoirSection(key);
  }

  int _badgeFor(AdminProvider admin, String? key) {
    switch (key) {
      case 'pending_users':
        return admin.usersEnAttente;
      case 'pending_jobs':
        return admin.offresEnAttente;
      case 'reports':
        return admin.signalementsEnAttente;
      case 'pending_testimonials':
        return admin.temoignagesEnAttente;
      case 'contact_messages_unread':
        return admin.nbMessagesContactNonLus;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: isDrawer ? 280 : (collapsed ? 64 : 256),
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 20,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLogo(),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<AdminProvider>(
              builder: (context, admin, _) {
                final visibleSections = _sections
                    .map((sec) {
                      final items = sec.items.where((it) => _itemVisible(admin, it)).toList();
                      if (items.isEmpty) return null;
                      return _SidebarSection(title: sec.title, items: items);
                    })
                    .whereType<_SidebarSection>()
                    .toList();
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: visibleSections
                        .map(
                          (section) => _buildSection(section, collapsed && !isDrawer),
                        )
                        .toList(),
                  ),
                );
              },
            ),
          ),
          _buildAdminProfile(collapsed && !isDrawer),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    final hideText = collapsed && !isDrawer;
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: hideText ? 0 : 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0x20FFFFFF), width: 1),
        ),
      ),
      child: hideText
          ? Tooltip(
              message: 'EmploiConnect - Administration',
              child: Center(
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 26,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: LogoWidget(
                      height: 30,
                      fallbackTextColor: Colors.white,
                      fallbackAccentColor: const Color(0xFF60A5FA),
                    ),
                  ),
                ),
                if (!hideText) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EmploiConnect',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.15,
                            ),
                          ),
                          Text(
                            'Administration',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Consumer<AdminProvider>(
                    builder: (context, admin, _) {
                      final c = admin.couleurRole;
                      final titre = admin.libelleRoleCourt;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: c.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          titre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildSection(_SidebarSection section, bool hideText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title != null && !hideText)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
            child: Text(
              section.title!,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
                letterSpacing: 0.8,
              ),
            ),
          ),
        ...section.items.map((item) => _buildItem(item, hideText)),
      ],
    );
  }

  Widget _buildItem(_SidebarItem item, bool hideText) {
    final isActive =
        currentRoute == item.route ||
        (item.route != '/admin' && currentRoute.startsWith(item.route));
    if (hideText) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Tooltip(
          message: item.label,
          child: Consumer<AdminProvider>(
            builder: (context, admin, _) {
              final n = _badgeFor(admin, item.badgeKey);
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onRouteSelected(item.route),
                  borderRadius: BorderRadius.circular(10),
                  hoverColor: const Color(0xFF1E293B),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF1A56DB) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
                            : Colors.transparent,
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          isActive ? item.activeIcon : item.icon,
                          size: 20,
                          color: isActive ? Colors.white : const Color(0xFF94A3B8),
                        ),
                        if (n > 0)
                          Positioned(
                            right: 2,
                            top: 2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: item.badgeColor ?? const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF0F172A), width: 1),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Tooltip(
        message: '',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1A56DB) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: InkWell(
            onTap: () => onRouteSelected(item.route),
            borderRadius: BorderRadius.circular(10),
            hoverColor: const Color(0xFF1E293B),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    isActive ? item.activeIcon : item.icon,
                    size: 18,
                    color: isActive ? Colors.white : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? Colors.white : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                  if (item.badgeKey != null)
                    Consumer<AdminProvider>(
                      builder: (context, admin, _) {
                        final n = _badgeFor(admin, item.badgeKey);
                        if (n <= 0) return const SizedBox.shrink();
                        return _NotificationBadge(
                          value: n,
                          color: item.badgeColor,
                          onActiveBackground: isActive,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminProfile(bool hideText) {
    if (hideText) {
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0x20FFFFFF))),
        ),
        child: Tooltip(
          message: 'Appui long pour se déconnecter.',
          child: Center(
            child: Consumer2<AdminProvider, AuthProvider>(
              builder: (context, admin, auth, _) {
                final photo = admin.adminPhotoUrl?.trim();
                final nomStr =
                    (admin.adminNom ?? auth.user?['nom']?.toString() ?? '')
                        .trim();
                final emailStr =
                    (admin.adminEmail ?? auth.user?['email']?.toString() ?? '')
                        .trim();
                final initial = nomStr.isNotEmpty
                    ? nomStr[0].toUpperCase()
                    : (emailStr.isNotEmpty
                        ? emailStr[0].toUpperCase()
                        : '?');
                final hasPhoto = photo != null && photo.isNotEmpty;
                final c = admin.couleurRole;
                return GestureDetector(
                  onLongPress: () => onLogout(),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: c,
                    backgroundImage: hasPhoto ? NetworkImage(photo) : null,
                    child: hasPhoto
                        ? null
                        : Text(
                            initial,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x20FFFFFF))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Consumer2<AdminProvider, AuthProvider>(
            builder: (context, admin, auth, _) {
              final photo = admin.adminPhotoUrl?.trim();
              final nomStr =
                  (admin.adminNom ?? auth.user?['nom']?.toString() ?? '')
                      .trim();
              final emailStr =
                  (admin.adminEmail ?? auth.user?['email']?.toString() ?? '')
                      .trim();
              final initial = nomStr.isNotEmpty
                  ? nomStr[0].toUpperCase()
                  : (emailStr.isNotEmpty
                      ? emailStr[0].toUpperCase()
                      : '?');
              final hasPhoto = photo != null && photo.isNotEmpty;
              final c = admin.couleurRole;
              return CircleAvatar(
                radius: 18,
                backgroundColor: c,
                backgroundImage: hasPhoto ? NetworkImage(photo) : null,
                child: hasPhoto
                    ? null
                    : Text(
                        initial,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
              );
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Consumer2<AdminProvider, AuthProvider>(
              builder: (context, admin, auth, _) {
                final nom = (admin.adminNom ?? auth.user?['nom']?.toString() ?? '')
                    .trim();
                final email = (admin.adminEmail ?? auth.user?['email']?.toString() ?? '')
                    .trim();
                final displayNom = nom.isNotEmpty
                    ? nom
                    : (email.isNotEmpty ? email.split('@').first : 'Profil');
                final titreRole = admin.libelleRoleCourt;
                final couleurRole = admin.couleurRole;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayNom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: couleurRole.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        titreRole,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: couleurRole,
                          height: 1.1,
                        ),
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: const Color(0xFF94A3B8),
                          height: 1.1,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          GestureDetector(
            onTap: () => onLogout(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFEF4444),
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge({
    required this.value,
    this.color,
    this.onActiveBackground = false,
  });

  final int value;
  final Color? color;
  final bool onActiveBackground;

  @override
  Widget build(BuildContext context) {
    final bg = onActiveBackground
        ? Colors.white.withValues(alpha: 0.25)
        : (color ?? const Color(0xFFEF4444));
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        value.toString(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SidebarSection {
  const _SidebarSection({required this.title, required this.items});

  final String? title;
  final List<_SidebarItem> items;
}

class _SidebarItem {
  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
    this.permissionSection,
    this.superOnly = false,
    this.badgeKey,
    this.badgeColor,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  /// Section alignée sur le backend (`mes-permissions`).
  final String? permissionSection;
  /// Réservé au super admin (paramètres, gestion des accès).
  final bool superOnly;
  final String? badgeKey;
  final Color? badgeColor;
}
