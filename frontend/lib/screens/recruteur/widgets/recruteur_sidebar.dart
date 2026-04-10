import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_config_provider.dart';
import '../../../providers/recruteur_provider.dart';

class RecruteurSidebar extends StatelessWidget {
  const RecruteurSidebar({
    super.key,
    required this.currentRoute,
    required this.onRouteSelected,
    required this.onLogout,
    this.isDrawer = false,
  });

  final String currentRoute;
  final ValueChanged<String> onRouteSelected;
  final Future<void> Function() onLogout;
  final bool isDrawer;

  static const _inactive = Color(0xFFEAF2FF);
  static const _activeBg = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecruteurProvider>();
    final sections = _buildSections(provider);
    return Container(
      width: 240,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D1B3E),
            Color(0xFF1A2F5E),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x2A1E3A8A),
            blurRadius: 16,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCompanyHeader(context, provider.profil),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sections
                    .map(
                      (s) => _buildSection(
                        context,
                        s,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  List<_SidebarSection> _buildSections(RecruteurProvider provider) {
    return [
      _SidebarSection(
        title: 'PRINCIPAL',
        items: [
          const _SidebarItem(
            'Vue d\'ensemble',
            Icons.dashboard_outlined,
            Icons.dashboard_rounded,
            '/dashboard-recruteur',
          ),
          _SidebarItem(
            'Mes offres',
            Icons.work_outline,
            Icons.work_rounded,
            '/dashboard-recruteur/offres',
            badgeCount: provider.nbOffresActives > 0 ? provider.nbOffresActives : null,
            badgeColor: const Color(0xFF3B82F6),
          ),
          _SidebarItem(
            'Candidatures',
            Icons.people_outline,
            Icons.people_rounded,
            '/dashboard-recruteur/candidatures',
            badgeCount: provider.nbCandidEnAttente > 0 ? provider.nbCandidEnAttente : null,
            badgeColor: const Color(0xFF10B981),
          ),
          const _SidebarItem(
            'Recherche Talents',
            Icons.search_outlined,
            Icons.search_rounded,
            '/dashboard-recruteur/talents',
          ),
          const _SidebarItem(
            'Profil entreprise',
            Icons.business_outlined,
            Icons.business_rounded,
            '/dashboard-recruteur/profil',
          ),
        ],
      ),
      _SidebarSection(
        title: 'COMMUNICATION',
        items: [
          _SidebarItem(
            'Messagerie',
            Icons.chat_bubble_outline,
            Icons.chat_bubble_rounded,
            '/dashboard-recruteur/messages',
            badgeCount: provider.nbMessagesNonLus > 0 ? provider.nbMessagesNonLus : null,
            badgeColor: const Color(0xFF3B82F6),
          ),
          _SidebarItem(
            'Notifications',
            Icons.notifications_outlined,
            Icons.notifications_rounded,
            '/dashboard-recruteur/notifications',
            badgeCount: provider.nbNotificationsNonLues > 0 ? provider.nbNotificationsNonLues : null,
            badgeColor: const Color(0xFFEF4444),
          ),
        ],
      ),
      const _SidebarSection(
        title: 'ANALYSE',
        items: [
          _SidebarItem(
            'Statistiques',
            Icons.bar_chart_outlined,
            Icons.bar_chart_rounded,
            '/dashboard-recruteur/statistiques',
          ),
        ],
      ),
      const _SidebarSection(
        title: 'COMPTE',
        items: [
          _SidebarItem(
            'Paramètres',
            Icons.settings_outlined,
            Icons.settings_rounded,
            '/dashboard-recruteur/parametres',
          ),
        ],
      ),
    ];
  }

  Widget _logoText() => Text(
        'EmploiConnect',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      );

  Widget _buildCompanyHeader(BuildContext context, Map<String, dynamic>? profil) {
    final nom = profil?['nom_entreprise'] as String? ?? 'Mon entreprise';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x20FFFFFF))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<AppConfigProvider>(
            builder: (ctx, cfg, _) => cfg.logoUrl.isNotEmpty
                ? Image.network(
                    cfg.logoUrl,
                    height: 48,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                    errorBuilder: (context, error, stackTrace) => _logoText(),
                  )
                : _logoText(),
          ),
          const SizedBox(height: 10),
          Text(
            nom,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Espace Recruteur',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    _SidebarSection section,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
          child: Text(
            section.title,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _inactive,
              letterSpacing: 0.8,
            ),
          ),
        ),
        ...section.items.map((i) => _buildItem(context, i)),
      ],
    );
  }

  Widget _buildBadge(int count, {required Color color}) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    _SidebarItem item,
  ) {
    final isActive = currentRoute == item.route ||
        (item.route != '/dashboard-recruteur' && currentRoute.startsWith(item.route));
    return _HoverSidebarRow(
      isActive: isActive,
      activeBg: _activeBg,
      onTap: () => onRouteSelected(item.route),
      child: Row(
        children: [
          Icon(
            isActive ? item.activeIcon : item.icon,
            size: 18,
            color: isActive ? Colors.white : _inactive,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? Colors.white : const Color(0xFFEAF2FF),
              ),
            ),
          ),
          if (item.badgeCount != null && item.badgeCount! > 0)
            _buildBadge(
              item.badgeCount!,
              color: item.badgeColor ?? const Color(0xFFEF4444),
            ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Tooltip(
          message: 'Se déconnecter',
          child: InkWell(
            onTap: onLogout,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.logout_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    'Quitter',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

/// Effet survol (web/desktop) + fond item actif.
class _HoverSidebarRow extends StatefulWidget {
  const _HoverSidebarRow({
    required this.isActive,
    required this.activeBg,
    required this.onTap,
    required this.child,
  });

  final bool isActive;
  final Color activeBg;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_HoverSidebarRow> createState() => _HoverSidebarRowState();
}

class _HoverSidebarRowState extends State<_HoverSidebarRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: widget.isActive
                    ? widget.activeBg
                    : (_hover ? Colors.white.withValues(alpha: 0.07) : Colors.transparent),
                borderRadius: BorderRadius.circular(10),
                border: widget.isActive
                    ? Border.all(color: Colors.white.withValues(alpha: 0.12))
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarSection {
  const _SidebarSection({required this.title, required this.items});
  final String title;
  final List<_SidebarItem> items;
}

class _SidebarItem {
  const _SidebarItem(
    this.label,
    this.icon,
    this.activeIcon,
    this.route, {
    this.badgeCount,
    this.badgeColor,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final int? badgeCount;
  final Color? badgeColor;
}
