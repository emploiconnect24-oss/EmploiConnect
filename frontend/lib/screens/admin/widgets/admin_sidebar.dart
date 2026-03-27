import 'package:flutter/material.dart';

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
          badgeKey: 'pending_users',
        ),
        _SidebarItem(
          label: 'Offres d\'emploi',
          icon: Icons.work_outline_rounded,
          activeIcon: Icons.work_rounded,
          route: '/admin/offres',
          badgeKey: 'pending_jobs',
        ),
        _SidebarItem(
          label: 'Entreprises',
          icon: Icons.business_outlined,
          activeIcon: Icons.business_rounded,
          route: '/admin/entreprises',
        ),
        _SidebarItem(
          label: 'Candidatures',
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment_rounded,
          route: '/admin/candidatures',
        ),
        _SidebarItem(
          label: 'Moderation',
          icon: Icons.shield_outlined,
          activeIcon: Icons.shield_rounded,
          route: '/admin/moderation',
          badgeKey: 'reports',
          badgeColor: Color(0xFFEF4444),
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
        ),
      ],
    ),
    _SidebarSection(
      title: 'CONFIGURATION',
      items: [
        _SidebarItem(
          label: 'Notifications',
          icon: Icons.notifications_none_rounded,
          activeIcon: Icons.notifications_rounded,
          route: '/admin/notifications',
        ),
        _SidebarItem(
          label: 'Parametres',
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings_rounded,
          route: '/admin/parametres',
        ),
      ],
    ),
  ];

  static const Map<String, int> _badges = {
    'pending_users': 23,
    'pending_jobs': 23,
    'reports': 7,
  };

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: isDrawer ? 280 : (collapsed ? 64 : 240),
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(
          right: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildLogo(),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _sections
                    .map((section) => _buildSection(section, collapsed && !isDrawer))
                    .toList(),
              ),
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
      padding: EdgeInsets.symmetric(horizontal: hideText ? 12 : 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.work_outline, color: Colors.white, size: 18),
          ),
          if (!hideText) ...[
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'EmploiConnect',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Administration',
                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
              ],
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
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
                letterSpacing: 0.8,
              ),
            ),
          ),
        ...section.items.map((item) => _buildItem(item, hideText)),
      ],
    );
  }

  Widget _buildItem(_SidebarItem item, bool hideText) {
    final isActive = currentRoute == item.route ||
        (item.route != '/admin' && currentRoute.startsWith(item.route));
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Tooltip(
        message: hideText ? item.label : '',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isActive ? const Color(0x1A1A56DB) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () => onRouteSelected(item.route),
            borderRadius: BorderRadius.circular(8),
            hoverColor: const Color(0xFF1E293B),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hideText ? 16 : 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    isActive ? item.activeIcon : item.icon,
                    size: 20,
                    color: isActive ? const Color(0xFF60A5FA) : const Color(0xFF94A3B8),
                  ),
                  if (!hideText) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? Colors.white : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    if (item.badgeKey != null && (_badges[item.badgeKey] ?? 0) > 0)
                      _NotificationBadge(
                        value: _badges[item.badgeKey]!,
                        color: item.badgeColor,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminProfile(bool hideText) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hideText ? 12 : 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF1A56DB),
            child: Text(
              'A',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          if (!hideText) ...[
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Administrateur',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Super Admin',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onLogout,
              tooltip: 'Deconnexion',
              icon: const Icon(
                Icons.logout_outlined,
                color: Color(0xFF64748B),
                size: 18,
              ),
            ),
          ] else
            IconButton(
              onPressed: onLogout,
              tooltip: 'Deconnexion',
              icon: const Icon(Icons.logout_outlined, color: Color(0xFF64748B), size: 18),
            ),
        ],
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge({required this.value, this.color});

  final int value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? const Color(0xFF1A56DB),
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
    this.badgeKey,
    this.badgeColor,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final String? badgeKey;
  final Color? badgeColor;
}
