import 'package:flutter/material.dart';

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

  static const List<_SidebarSection> _sections = [
    _SidebarSection(
      title: 'PRINCIPAL',
      items: [
        _SidebarItem('Vue d\'ensemble', Icons.dashboard_outlined, Icons.dashboard_rounded, '/dashboard-recruteur'),
        _SidebarItem('Mes offres', Icons.work_outline, Icons.work_rounded, '/dashboard-recruteur/offres',
            badge: '12'),
        _SidebarItem('Candidatures', Icons.people_outline, Icons.people_rounded, '/dashboard-recruteur/candidatures',
            badge: '47', badgeColor: Color(0xFF10B981)),
        _SidebarItem(
            'Recherche Talents', Icons.search_outlined, Icons.search_rounded, '/dashboard-recruteur/talents'),
        _SidebarItem(
            'Profil entreprise', Icons.business_outlined, Icons.business_rounded, '/dashboard-recruteur/profil'),
      ],
    ),
    _SidebarSection(
      title: 'COMMUNICATION',
      items: [
        _SidebarItem('Messagerie', Icons.chat_bubble_outline, Icons.chat_bubble_rounded,
            '/dashboard-recruteur/messages',
            badge: '3', badgeColor: Color(0xFF1A56DB)),
        _SidebarItem('Notifications', Icons.notifications_outlined, Icons.notifications_rounded,
            '/dashboard-recruteur/notifications',
            badge: '5'),
      ],
    ),
    _SidebarSection(
      title: 'ANALYSE',
      items: [
        _SidebarItem('Statistiques', Icons.bar_chart_outlined, Icons.bar_chart_rounded,
            '/dashboard-recruteur/statistiques'),
      ],
    ),
    _SidebarSection(
      title: 'COMPTE',
      items: [
        _SidebarItem('Paramètres', Icons.settings_outlined, Icons.settings_rounded, '/dashboard-recruteur/parametres'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          _buildCompanyHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _sections.map(_buildSection).toList(),
              ),
            ),
          ),
          _buildPublishCta(context),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildCompanyHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFEFF6FF),
            child: Text(
              'E',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A56DB),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mon entreprise',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
                Text('Espace Recruteur', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(_SidebarSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
          child: Text(
            section.title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
        ),
        ...section.items.map(_buildItem),
      ],
    );
  }

  Widget _buildItem(_SidebarItem item) {
    final isActive = currentRoute == item.route ||
        (item.route != '/dashboard-recruteur' && currentRoute.startsWith(item.route));
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () => onRouteSelected(item.route),
          borderRadius: BorderRadius.circular(8),
          hoverColor: const Color(0xFFF8FAFC),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: 18,
                  color: isActive ? const Color(0xFF1A56DB) : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? const Color(0xFF1A56DB) : const Color(0xFF64748B),
                    ),
                  ),
                ),
                if (item.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: (item.badgeColor ?? const Color(0xFF1A56DB)).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      item.badge!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: item.badgeColor ?? const Color(0xFF1A56DB),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPublishCta(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: ElevatedButton.icon(
        onPressed: () => onRouteSelected('/dashboard-recruteur/offres/nouvelle'),
        icon: const Icon(Icons.add_circle_outline, size: 18),
        label: const Text('Publier une offre'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A56DB),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      child: InkWell(
        onTap: onLogout,
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.logout_outlined, size: 18, color: Color(0xFF94A3B8)),
              SizedBox(width: 10),
              Text('Déconnexion', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
            ],
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
    this.badge,
    this.badgeColor,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final String? badge;
  final Color? badgeColor;
}
