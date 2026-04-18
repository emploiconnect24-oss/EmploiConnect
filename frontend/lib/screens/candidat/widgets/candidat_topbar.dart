import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/candidat_provider.dart';
import '../../../shared/widgets/logo_widget.dart';
import '../../../shared/widgets/theme_toggle_button.dart';

class CandidatTopBar extends StatelessWidget {
  const CandidatTopBar({
    super.key,
    required this.currentRoute,
    required this.isMobile,
    this.onMenuPressed,
    this.onQuickApply,
    this.onNotifications,
    this.onProfile,
    this.unreadNotifications = 0,
    this.onJobSearchSubmit,
  });

  final String currentRoute;
  final bool isMobile;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onQuickApply;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;
  final int unreadNotifications;
  /// Lance la recherche offres (mot-clé) depuis la barre du haut.
  final ValueChanged<String>? onJobSearchSubmit;

  static const _titles = {
    '/dashboard': 'Mon tableau de bord',
    '/dashboard/profil': 'Mon Profil & CV',
    '/dashboard/offres': 'Rechercher des offres',
    '/dashboard/candidatures': 'Mes candidatures',
    '/dashboard/temoignage': 'Témoignage recrutement',
    '/dashboard/recommandations': 'Recommandations IA',
    '/dashboard/ia-demo': 'Démo IA & matching',
    '/dashboard/sauvegardes': 'Offres sauvegardées',
    '/dashboard/messages': 'Messagerie',
    '/dashboard/conseils': 'Conseils & Ressources',
    '/dashboard/parcours': 'Parcours Carrière',
    '/dashboard/parcours/simulation': 'Simulation d\'entretien',
    '/dashboard/alertes': 'Alertes emploi',
    '/dashboard/notifications': 'Notifications',
    '/dashboard/parametres': 'Paramètres',
    '/dashboard/cv/creer': 'Créer mon CV',
  };

  @override
  Widget build(BuildContext context) {
    final title = _titles[currentRoute] ?? 'Espace Candidat';
    final scheme = Theme.of(context).colorScheme;
    final user = context.watch<AuthProvider>().user;
    final photoUrl = (user?['photo_url'] ?? '').toString();
    final name = (user?['nom'] ?? '').toString();
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outline)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: Icon(Icons.menu_rounded, color: scheme.onSurfaceVariant),
              onPressed: onMenuPressed,
            ),
          if (isMobile) ...[
            const LogoWidget(height: 30),
            const SizedBox(width: 8),
          ],
          if (isMobile)
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            )
          else
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          if (!isMobile) const Spacer(),
          if (isMobile && onJobSearchSubmit != null)
            IconButton(
              tooltip: 'Rechercher une offre',
              icon: Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
              onPressed: () {
                final ctrl = TextEditingController();
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Rechercher une offre'),
                    content: TextField(
                      controller: ctrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Mots-clés, entreprise…',
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (v) {
                        Navigator.pop(ctx);
                        onJobSearchSubmit!(v.trim());
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Annuler'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onJobSearchSubmit!(ctrl.text.trim());
                        },
                        child: const Text('Rechercher'),
                      ),
                    ],
                  ),
                );
              },
            ),
          const ThemeToggleButton(),
          const SizedBox(width: 10),
          if (!isMobile) ...[
            _QuickSearchBar(onSubmit: onJobSearchSubmit),
            const SizedBox(width: 12),
            Consumer<CandidatProvider>(
              builder: (ctx, cand, _) {
                final p = cand.profileCompletionPercent;
                if (p >= 80) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onProfile,
                      borderRadius: BorderRadius.circular(8),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Profil $p%',
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
                );
              },
            ),
            TextButton.icon(
              onPressed: onQuickApply,
              icon: const Icon(Icons.bolt_rounded, size: 16),
              label: const Text('Postuler vite'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1A56DB),
                backgroundColor: const Color(0xFFEFF6FF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF64748B),
                ),
                onPressed: onNotifications,
              ),
              if (unreadNotifications > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                    child: Text(
                      unreadNotifications > 99 ? '99+' : '$unreadNotifications',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          GestureDetector(
            onTap: onProfile,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1A56DB).withValues(alpha: 0.35),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF1A56DB).withValues(alpha: 0.12),
                backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isNotEmpty
                    ? null
                    : Text(
                        (name.isNotEmpty ? name.trim()[0] : 'C').toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A56DB),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickSearchBar extends StatefulWidget {
  const _QuickSearchBar({this.onSubmit});

  final ValueChanged<String>? onSubmit;

  @override
  State<_QuickSearchBar> createState() => _QuickSearchBarState();
}

class _QuickSearchBarState extends State<_QuickSearchBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _go() {
    final q = _ctrl.text.trim();
    widget.onSubmit?.call(q);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 38,
      child: TextField(
        controller: _ctrl,
        style: const TextStyle(fontSize: 13),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _go(),
        decoration: InputDecoration(
          hintText: 'Rechercher une offre…',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1A56DB)),
          ),
        ),
      ),
    );
  }
}
