import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/candidat_provider.dart';
import '../../../shared/widgets/logo_widget.dart';

class CandidatSidebar extends StatefulWidget {
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

  @override
  State<CandidatSidebar> createState() => _CandidatSidebarState();
}

class _CandidatSidebarState extends State<CandidatSidebar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;

  static const _items = <_CandidatMenuSection>[
    _CandidatMenuSection(
      title: 'MON ESPACE',
      items: [
        _CandidatMenuItem(
          label: 'Vue d\'ensemble',
          route: '/dashboard',
          icon: Icons.dashboard_outlined,
        ),
        _CandidatMenuItem(
          label: 'Mon Profil & CV',
          route: '/dashboard/profil',
          icon: Icons.person_outline,
        ),
        _CandidatMenuItem(
          label: 'Mes candidatures',
          route: '/dashboard/candidatures',
          icon: Icons.assignment_outlined,
        ),
        _CandidatMenuItem(
          label: 'Témoignage recrutement',
          route: '/dashboard/temoignage',
          icon: Icons.format_quote_outlined,
        ),
        _CandidatMenuItem(
          label: 'Offres sauvegardées',
          route: '/dashboard/sauvegardes',
          icon: Icons.bookmark_outline,
        ),
      ],
    ),
    _CandidatMenuSection(
      title: 'EXPLORER',
      items: [
        _CandidatMenuItem(
          label: 'Rechercher des offres',
          route: '/dashboard/offres',
          icon: Icons.search_outlined,
        ),
        _CandidatMenuItem(
          label: 'Recommandations IA',
          route: '/dashboard/recommandations',
          icon: Icons.auto_awesome_outlined,
        ),
        _CandidatMenuItem(
          label: 'Démo IA & matching',
          route: '/dashboard/ia-demo',
          icon: Icons.psychology_outlined,
        ),
        _CandidatMenuItem(
          label: 'Alertes emploi',
          route: '/dashboard/alertes',
          icon: Icons.notifications_active_outlined,
        ),
      ],
    ),
    _CandidatMenuSection(
      title: 'COMMUNICATION',
      items: [
        _CandidatMenuItem(
          label: 'Messagerie',
          route: '/dashboard/messages',
          icon: Icons.chat_bubble_outline,
        ),
        _CandidatMenuItem(
          label: 'Notifications',
          route: '/dashboard/notifications',
          icon: Icons.notifications_outlined,
        ),
      ],
    ),
    _CandidatMenuSection(
      title: 'RESSOURCES',
      items: [
        _CandidatMenuItem(
          label: 'Conseils carrière',
          route: '/dashboard/conseils',
          icon: Icons.lightbulb_outline,
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
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<CandidatProvider>();
    final auth = context.watch<AuthProvider>();
    final completion = stats.profileCompletionPercent;
    final nom = (stats.profile['nom'] ?? auth.user?['nom'] ?? 'Mon profil')
        .toString();
    final titre = (stats.profile['titre_professionnel'] ?? '')
        .toString()
        .trim();
    final photoUrl =
        (stats.profile['photo_url'] ?? auth.user?['photo_url'] ?? '')
            .toString();
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, _) {
        final t = _animCtrl.value;
        final begin = Alignment(-0.2 + (t * 0.4), -1);
        final end = Alignment(0.2 - (t * 0.4), 1);
        return Container(
          width: widget.isDrawer ? double.infinity : 240,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: const [Color(0xFF1E3A8A), Color(0xFF1A56DB)],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: LogoWidget(
                      height: 32,
                      fallbackTextColor: Colors.white,
                      fallbackAccentColor: Color(0xFFBAE6FD),
                    ),
                  ),
                ),
                _buildHeader(completion, nom, titre, photoUrl),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final section in _items) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
                            child: Text(
                              section.title,
                              style: const TextStyle(
                                fontSize: 10,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w600,
                                color: Color(0x80FFFFFF),
                              ),
                            ),
                          ),
                          ...section.items.map(_buildItem),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0x1AFFFFFF))),
                  ),
                  child: InkWell(
                    onTap: widget.onLogout,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_outlined,
                            size: 18,
                            color: Color(0xCCFFFFFF),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Déconnexion',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xCCFFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    int completion,
    String nom,
    String titre,
    String photoUrl,
  ) {
    final color = completion < 40
        ? const Color(0xFFEF4444)
        : completion < 70
        ? const Color(0xFFF59E0B)
        : const Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
        color: Color(0x14000000),
      ),
      child: Column(
        children: [
          FadeTransition(
            opacity: completion < 100
                ? Tween<double>(begin: 0.7, end: 1).animate(
                    CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
                  )
                : const AlwaysStoppedAnimation<double>(1),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0x33FFFFFF),
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl.isNotEmpty
                      ? null
                      : Text(
                          (nom.isNotEmpty ? nom.trim()[0] : 'C').toUpperCase(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.add, size: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            nom.isEmpty ? 'Mon profil' : nom,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            titre.isEmpty ? 'Ajouter un titre professionnel' : titre,
            style: TextStyle(fontSize: 11, color: Color(0xCCFFFFFF)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Complétion du profil',
                  style: TextStyle(fontSize: 10, color: Color(0xB3FFFFFF)),
                ),
              ),
              Text(
                '$completion%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: completion / 100),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: const Color(0x33FFFFFF),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => widget.onRouteSelected('/dashboard/profil'),
            child: const Text(
              'Améliorer mon profil →',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xCCFFFFFF),
                decoration: TextDecoration.underline,
                decorationColor: Color(0xCCFFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(_CandidatMenuItem item) {
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
      case '/dashboard/alertes':
        dynamicBadge = '${stats.badge('alertes')}';
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
        widget.currentRoute == item.route ||
        (item.route != '/dashboard' &&
            widget.currentRoute.startsWith(item.route));
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isActive ? const Color(0x1FFFFFFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () => widget.onRouteSelected(item.route),
          borderRadius: BorderRadius.circular(8),
          hoverColor: const Color(0x1AFFFFFF),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: isActive ? Colors.white : const Color(0xCCFFFFFF),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      color: isActive ? Colors.white : const Color(0xCCFFFFFF),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (dynamicBadge != null)
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.9, end: 1),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x33FFFFFF),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: const Color(0x66FFFFFF)),
                      ),
                      child: Text(
                        dynamicBadge,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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
