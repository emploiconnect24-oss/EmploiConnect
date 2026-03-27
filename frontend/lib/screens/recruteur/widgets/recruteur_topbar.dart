import 'package:flutter/material.dart';

class RecruteurTopBar extends StatelessWidget {
  const RecruteurTopBar({
    super.key,
    required this.currentRoute,
    required this.onMenuPressed,
    required this.onQuickOffer,
    required this.onNotifications,
  });

  final String currentRoute;
  final VoidCallback? onMenuPressed;
  final VoidCallback onQuickOffer;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1024;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF64748B)),
            onPressed: isMobile ? onMenuPressed : null,
          ),
          const SizedBox(width: 8),
          if (!isMobile) ...[
            Expanded(child: _Breadcrumb(route: currentRoute)),
            const SizedBox(width: 12),
          ] else
            Expanded(
              child: Text(
                _titleForMobile(currentRoute),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ),
          if (!isMobile)
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nouvelle offre'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: onQuickOffer,
            ),
          const SizedBox(width: 10),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Color(0xFF64748B)),
                onPressed: onNotifications,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFEFF6FF),
            child: Text(
              'E',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A56DB)),
            ),
          ),
        ],
      ),
    );
  }

  String _titleForMobile(String route) {
    final parts = _getBreadcrumb(route);
    return parts.isEmpty ? 'Espace Recruteur' : parts.last;
  }

  List<String> _getBreadcrumb(String route) {
    final map = {
      '/dashboard-recruteur': ['Accueil'],
      '/dashboard-recruteur/offres': ['Accueil', 'Mes offres'],
      '/dashboard-recruteur/offres/nouvelle': ['Mes offres', 'Nouvelle offre'],
      '/dashboard-recruteur/candidatures': ['Accueil', 'Candidatures'],
      '/dashboard-recruteur/talents': ['Accueil', 'Recherche Talents'],
      '/dashboard-recruteur/profil': ['Accueil', 'Profil entreprise'],
      '/dashboard-recruteur/messages': ['Accueil', 'Messagerie'],
      '/dashboard-recruteur/statistiques': ['Accueil', 'Statistiques'],
      '/dashboard-recruteur/notifications': ['Accueil', 'Notifications'],
      '/dashboard-recruteur/parametres': ['Accueil', 'Paramètres'],
    };
    return map[route] ?? ['Accueil'];
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.route});
  final String route;

  @override
  Widget build(BuildContext context) {
    final parts = _parts(route);
    return Row(
      children: parts.asMap().entries.map((entry) {
        final i = entry.key;
        final text = entry.value;
        final isLast = i == parts.length - 1;
        return Row(
          children: [
            if (i > 0) ...[
              const Icon(Icons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
                color: isLast ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 4),
          ],
        );
      }).toList(),
    );
  }

  List<String> _parts(String route) {
    final map = {
      '/dashboard-recruteur': ['Accueil'],
      '/dashboard-recruteur/offres': ['Accueil', 'Mes offres'],
      '/dashboard-recruteur/offres/nouvelle': ['Mes offres', 'Nouvelle offre'],
      '/dashboard-recruteur/candidatures': ['Accueil', 'Candidatures'],
      '/dashboard-recruteur/talents': ['Accueil', 'Recherche Talents'],
      '/dashboard-recruteur/profil': ['Accueil', 'Profil entreprise'],
      '/dashboard-recruteur/messages': ['Accueil', 'Messagerie'],
      '/dashboard-recruteur/statistiques': ['Accueil', 'Statistiques'],
      '/dashboard-recruteur/notifications': ['Accueil', 'Notifications'],
      '/dashboard-recruteur/parametres': ['Accueil', 'Paramètres'],
    };
    return map[route] ?? ['Accueil'];
  }
}
