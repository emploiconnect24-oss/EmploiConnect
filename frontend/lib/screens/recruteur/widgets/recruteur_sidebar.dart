import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
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

  static const _inactive = Color(0xFF94A3B8);
  static const _activeBg = Color(0xFF1A56DB);
  static const _borderSubtle = Color(0x25FFFFFF);

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
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x30000000),
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
          _buildPublishCta(context),
          _buildAccountFooter(context),
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
            badge: provider.nbOffresActives > 0 ? '${provider.nbOffresActives}' : null,
            badgeColor: const Color(0xFF3B82F6),
          ),
          _SidebarItem(
            'Candidatures',
            Icons.people_outline,
            Icons.people_rounded,
            '/dashboard-recruteur/candidatures',
            badge: provider.nbCandidEnAttente > 0 ? '${provider.nbCandidEnAttente}' : null,
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
            badge: provider.nbMessagesNonLus > 0 ? '${provider.nbMessagesNonLus}' : null,
            badgeColor: const Color(0xFF1A56DB),
          ),
          _SidebarItem(
            'Notifications',
            Icons.notifications_outlined,
            Icons.notifications_rounded,
            '/dashboard-recruteur/notifications',
            badge: provider.nbNotificationsNonLues > 0 ? '${provider.nbNotificationsNonLues}' : null,
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

  Widget _buildCompanyHeader(BuildContext context, Map<String, dynamic>? profil) {
    final companyName = (profil?['nom_entreprise'] ?? 'Mon entreprise').toString();
    final email = (profil?['utilisateur']?['email'] ?? '').toString();
    final logoUrl = profil?['logo_url']?.toString();
    final initial = companyName.trim().isEmpty ? 'E' : companyName.trim()[0].toUpperCase();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 14, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderSubtle)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1A56DB).withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1A56DB).withValues(alpha: 0.55)),
            ),
            clipBehavior: Clip.antiAlias,
            child: logoUrl != null && logoUrl.isNotEmpty
                ? Image.network(logoUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _logoFallback(initial))
                : _logoFallback(initial),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                Text(
                  email.isNotEmpty ? email : 'Espace Recruteur',
                  style: GoogleFonts.inter(fontSize: 10, color: _inactive),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.45)),
            ),
            child: Text(
              'Pro',
              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFF34D399)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoFallback(String initial) => Center(
        child: Text(
          initial,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF60A5FA)),
        ),
      );

  Widget _buildAccountFooter(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final nom = user?['nom']?.toString() ?? 'Mon compte';
    final photo = user?['photo_url']?.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onRouteSelected('/dashboard-recruteur/parametres'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    backgroundImage: photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
                    child: photo == null || photo.isEmpty
                        ? Text(
                            nom.trim().isEmpty ? '?' : nom.trim()[0].toUpperCase(),
                            style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nom,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                        ),
                        Text(
                          'Paramètres du compte',
                          style: GoogleFonts.inter(fontSize: 11, color: _inactive),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 20, color: _inactive),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
          child: TextButton.icon(
            onPressed: () => onRouteSelected('/dashboard-recruteur/profil'),
            icon: const Icon(Icons.business_outlined, size: 18),
            label: const Text('Profil entreprise'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF93C5FD),
              textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
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

  Widget _buildItem(
    BuildContext context,
    _SidebarItem item,
  ) {
    final isActive =
        currentRoute == item.route ||
        (item.route != '/dashboard-recruteur' &&
            currentRoute.startsWith(item.route));
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isActive ? _activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: Colors.white.withValues(alpha: 0.12)) : null,
        ),
        child: InkWell(
          onTap: () => onRouteSelected(item.route),
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.white.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      color: isActive ? Colors.white : _inactive,
                    ),
                  ),
                ),
                if (item.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.2)
                          : (item.badgeColor ?? const Color(0xFF1A56DB)).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      item.badge!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : (item.badgeColor ?? const Color(0xFF60A5FA)),
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
        border: Border(top: BorderSide(color: _borderSubtle)),
      ),
      child: ElevatedButton.icon(
        onPressed: () =>
            onRouteSelected('/dashboard-recruteur/offres/nouvelle'),
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
              Text(
                'Déconnexion',
                style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
              ),
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
