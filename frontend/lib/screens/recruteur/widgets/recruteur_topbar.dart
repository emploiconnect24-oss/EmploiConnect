import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/recruteur_provider.dart';
import '../../../shared/widgets/theme_toggle_button.dart';

class RecruteurTopBar extends StatelessWidget {
  const RecruteurTopBar({
    super.key,
    required this.currentRoute,
    required this.onMenuPressed,
    required this.onQuickOffer,
    required this.onNotifications,
    this.onOpenProfil,
  });

  final String currentRoute;
  final VoidCallback? onMenuPressed;
  final VoidCallback onQuickOffer;
  final VoidCallback onNotifications;
  final VoidCallback? onOpenProfil;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1024;
    final scheme = Theme.of(context).colorScheme;
    final nbNotifs = context.watch<RecruteurProvider>().nbNotificationsNonLues;
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.surface,
            Color.lerp(scheme.surface, scheme.primaryContainer, 0.12) ?? scheme.surface,
          ],
        ),
        border: Border(bottom: BorderSide(color: scheme.outline)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.menu_rounded, color: scheme.onSurfaceVariant),
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
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: scheme.onSurface),
              ),
            ),
          const ThemeToggleButton(),
          const SizedBox(width: 8),
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
              if (nbNotifs > 0)
                Positioned(
                  top: 6,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: const BoxDecoration(color: Color(0xFFEF4444), borderRadius: BorderRadius.all(Radius.circular(20))),
                    child: Text(
                      nbNotifs > 99 ? '99+' : '$nbNotifs',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
          Consumer<RecruteurProvider>(
            builder: (context, p, _) {
              final logo = p.profil?['logo_url']?.toString();
              final nom = (p.profil?['nom_entreprise'] ?? 'E').toString();
              final initial = nom.trim().isEmpty ? 'E' : nom.trim()[0].toUpperCase();
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onOpenProfil,
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1A56DB).withValues(alpha: 0.35), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFEFF6FF),
                      backgroundImage: logo != null && logo.isNotEmpty ? NetworkImage(logo) : null,
                      child: logo == null || logo.isEmpty
                          ? Text(initial, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1A56DB)))
                          : null,
                    ),
                  ),
                ),
              );
            },
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
