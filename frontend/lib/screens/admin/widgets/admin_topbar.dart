import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/admin_service.dart';
import '../../../shared/widgets/logo_widget.dart';
import 'admin_search_delegate.dart';

class AdminTopBar extends StatelessWidget {
  const AdminTopBar({
    super.key,
    required this.title,
    required this.onMenuPressed,
    required this.isMobile,
    required this.onLogout,
    this.onOpenProfile,
    this.onOpenNotifications,
    this.onOpenFullSearch,
  });

  final String title;
  final VoidCallback onMenuPressed;
  final bool isMobile;
  final Future<void> Function() onLogout;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenNotifications;
  /// Si renseigné, la barre « Recherche globale » ouvre cette page au lieu du overlay.
  final VoidCallback? onOpenFullSearch;

  void _openSearch(BuildContext context) {
    if (onOpenFullSearch != null) {
      onOpenFullSearch!();
      return;
    }
    showSearch<void>(
      context: context,
      delegate: AdminSearchDelegate(AdminService(), resultsContext: context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: isLight ? const Color(0xFFE2E8F0) : scheme.outline,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenuPressed,
            tooltip: isMobile ? 'Ouvrir le menu' : 'Réduire la sidebar',
            icon: Icon(Icons.menu_rounded, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 8),
          if (isMobile) ...[
            const LogoWidget(height: 30),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Consumer2<AdminProvider, AuthProvider>(
                  builder: (context, admin, auth, _) {
                    final nom = (admin.adminNom ??
                            auth.user?['nom']?.toString() ??
                            '')
                        .trim();
                    final email = (admin.adminEmail ??
                            auth.user?['email']?.toString() ??
                            '')
                        .trim();
                    final displayNom = nom.isNotEmpty
                        ? nom
                        : (email.isNotEmpty
                            ? email.split('@').first
                            : 'Profil');
                    final titreRole =
                        isMobile ? admin.libelleRoleCourt : admin.libelleRoleLong;
                    final desc = admin.descriptionAcces;
                    final couleurBadge = admin.couleurRole;
                    if (isMobile) {
                      return Row(
                        children: [
                          Flexible(
                            flex: 2,
                            child: Text(
                              displayNom,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            flex: 3,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: couleurBadge.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  titreRole,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: couleurBadge,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayNom,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: couleurBadge.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                titreRole,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: couleurBadge,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          if (!isMobile)
            GestureDetector(
              onTap: () => _openSearch(context),
              child: Container(
                width: 220,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded,
                        color: scheme.onSurfaceVariant, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Recherche globale…',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            IconButton(
              onPressed: () => _openSearch(context),
              icon: Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
            ),
          const SizedBox(width: 12),
          Consumer<AdminProvider>(
            builder: (context, admin, _) {
              final n = admin.nbNotificationsNonLues;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: onOpenNotifications,
                    tooltip: 'Notifications',
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF64748B),
                      size: 22,
                    ),
                  ),
                  if (n > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          n > 9 ? '9+' : '$n',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => onOpenProfile?.call(),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1A56DB).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Consumer2<AdminProvider, AuthProvider>(
                builder: (context, admin, auth, _) {
                  final photo = admin.adminPhotoUrl?.trim();
                  final nom =
                      (admin.adminNom ?? auth.user?['nom']?.toString() ?? '')
                          .trim();
                  final email =
                      (admin.adminEmail ?? auth.user?['email']?.toString() ?? '')
                          .trim();
                  var initial = '?';
                  if (nom.isNotEmpty) {
                    initial = nom[0].toUpperCase();
                  } else if (email.isNotEmpty) {
                    initial = email[0].toUpperCase();
                  }
                  final hasPhoto = photo != null && photo.isNotEmpty;
                  return CircleAvatar(
                    radius: 16,
                    backgroundColor: admin.couleurRole,
                    backgroundImage: hasPhoto ? NetworkImage(photo) : null,
                    child: hasPhoto
                        ? null
                        : Text(
                            initial,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  );
                },
              ),
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.more_vert_rounded,
                color: Color(0xFF64748B), size: 22),
            onSelected: (value) async {
              if (value == 'logout') await onLogout();
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'logout',
                child: Text('Déconnexion'),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Consumer<ThemeProvider>(
            builder: (context, tp, _) => IconButton(
              tooltip: tp.isDark(context) ? 'Mode clair' : 'Mode sombre',
              icon: Icon(
                tp.isDark(context)
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_outlined,
                color: const Color(0xFF64748B),
                size: 20,
              ),
              onPressed: () => tp.toggleTheme(context),
            ),
          ),
        ],
      ),
    );
  }
}
