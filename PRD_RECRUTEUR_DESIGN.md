# PRD — EmploiConnect · Amélioration Design Espace Recruteur
## Product Requirements Document v7.1 — Recruteur Design Polish
**Stack : Flutter + Node.js/Express**
**Outil : Cursor / Kirsoft AI**
**Objectif : Peaufinage design complet de l'espace recruteur**
**Date : Mars 2026**

---

> ### ⚠️ INSTRUCTIONS POUR CURSOR
>
> Ce PRD améliore le design EXISTANT. Ne pas recréer depuis zéro.
> Palette obligatoire : #1A56DB · #10B981 · #8B5CF6 · #F59E0B · #EF4444
> Cohérence totale entre toutes les pages de l'espace recruteur.

---

## Table des Matières

1. [Sidebar + Topbar Recruteur](#1-sidebar--topbar-recruteur)
2. [Page Mes Offres — Couleurs remarquables](#2-page-mes-offres--couleurs-remarquables)
3. [Page Détail Candidature — Design complet](#3-page-détail-candidature--design-complet)
4. [Dialog Planifier Entretien — Formulaire amélioré](#4-dialog-planifier-entretien--formulaire-amélioré)
5. [Page Recherche Talents — Design extraordinaire](#5-page-recherche-talents--design-extraordinaire)
6. [Dialog Contacter un Talent — Options enrichies](#6-dialog-contacter-un-talent--options-enrichies)
7. [Page Profil Entreprise — Aperçu + Design](#7-page-profil-entreprise--aperçu--design)
8. [Messagerie — Nouveau message + Pièces jointes](#8-messagerie--nouveau-message--pièces-jointes)
9. [Page Paramètres Recruteur — Design amélioré](#9-page-paramètres-recruteur--design-amélioré)
10. [Page Publier une Offre — Formulaire amélioré](#10-page-publier-une-offre--formulaire-amélioré)
11. [Critères d'Acceptation](#11-critères-dacceptation)

---

## 1. Sidebar + Topbar Recruteur

### 1.1 Sidebar recruteur — Design modernisé

```dart
// frontend/lib/screens/recruteur/recruteur_sidebar.dart

class RecruteurSidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecruteurProvider>();
    final route    = GoRouterState.of(context).uri.path;

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        // Dégradé bleu professionnel — cohérent avec admin
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        boxShadow: [BoxShadow(
          color: Color(0x30000000), blurRadius: 16,
          offset: Offset(4, 0))],
      ),
      child: Column(children: [

        // ── Header entreprise ──────────────────────────
        _buildHeader(provider.profil),

        // ── Navigation ────────────────────────────────
        Expanded(child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 8),
          children: [
            _section('PRINCIPAL', [
              _item(context, Icons.dashboard_rounded,
                'Vue d\'ensemble',
                '/dashboard-recruteur', route),
              _item(context, Icons.work_rounded,
                'Mes offres',
                '/dashboard-recruteur/offres', route,
                badge: provider.nbOffresActives > 0
                    ? '${provider.nbOffresActives}' : null,
                badgeColor: const Color(0xFF3B82F6)),
              _item(context, Icons.people_rounded,
                'Candidatures',
                '/dashboard-recruteur/candidatures', route,
                badge: provider.nbCandidEnAttente > 0
                    ? '${provider.nbCandidEnAttente}' : null,
                badgeColor: const Color(0xFF10B981)),
              _item(context, Icons.search_rounded,
                'Recherche Talents',
                '/dashboard-recruteur/talents', route),
              _item(context, Icons.business_rounded,
                'Profil entreprise',
                '/dashboard-recruteur/profil', route),
            ]),
            _section('COMMUNICATION', [
              _item(context, Icons.chat_bubble_rounded,
                'Messagerie',
                '/dashboard-recruteur/messages', route,
                badge: provider.nbMessagesNonLus > 0
                    ? '${provider.nbMessagesNonLus}' : null,
                badgeColor: const Color(0xFF3B82F6)),
              _item(context, Icons.notifications_rounded,
                'Notifications',
                '/dashboard-recruteur/notifications', route,
                badge: provider.nbNotificationsNonLues > 0
                    ? '${provider.nbNotificationsNonLues}' : null,
                badgeColor: const Color(0xFFEF4444)),
            ]),
            _section('ANALYSE', [
              _item(context, Icons.bar_chart_rounded,
                'Statistiques',
                '/dashboard-recruteur/statistiques', route),
            ]),
            _section('COMPTE', [
              _item(context, Icons.settings_rounded,
                'Paramètres',
                '/dashboard-recruteur/parametres', route),
            ]),
          ],
        )),

        // ── CTA Publier offre ──────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text('Publier une offre',
                style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
              onPressed: () => context.push(
                '/dashboard-recruteur/offres/nouvelle')))),

        // ── Profil recruteur bas ───────────────────────
        _buildBottomProfile(context, provider.profil),
      ]),
    );
  }

  Widget _buildHeader(Map<String, dynamic>? profil) {
    final nom  = profil?['nom_entreprise'] as String? ?? 'Mon entreprise';
    final logo = profil?['logo_url']       as String?;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(
          color: Color(0x25FFFFFF)))),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1A56DB).withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF1A56DB).withOpacity(0.4))),
          child: logo != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(logo, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                      _initLogo(nom)))
              : _initLogo(nom),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nom, style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: Colors.white),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('Espace Recruteur', style: GoogleFonts.inter(
            fontSize: 10, color: const Color(0xFF94A3B8))),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: const Color(0xFF10B981).withOpacity(0.4))),
          child: Text('Pro', style: GoogleFonts.inter(
            fontSize: 9, fontWeight: FontWeight.w700,
            color: const Color(0xFF34D399)))),
      ]),
    );
  }

  Widget _initLogo(String nom) => Center(child: Text(
    nom.isNotEmpty ? nom[0].toUpperCase() : 'E',
    style: GoogleFonts.poppins(
      fontSize: 18, fontWeight: FontWeight.w700,
      color: const Color(0xFF60A5FA))));

  Widget _section(String titre, List<Widget> items) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
        child: Text(titre, style: GoogleFonts.inter(
          fontSize: 9, fontWeight: FontWeight.w700,
          color: const Color(0xFF475569),
          letterSpacing: 1.0))),
      ...items,
    ]);

  Widget _item(
    BuildContext ctx, IconData icon, String label,
    String route, String currentRoute, {
    String? badge, Color? badgeColor,
  }) {
    final isActive = currentRoute == route ||
        (route != '/dashboard-recruteur' &&
         currentRoute.startsWith(route));

    return GestureDetector(
      onTap: () => ctx.go(route),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF1A56DB)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? const Color(0xFF3B82F6).withOpacity(0.4)
                : Colors.transparent)),
        child: Row(children: [
          Icon(icon, size: 17,
            color: isActive
                ? Colors.white : const Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isActive
                ? FontWeight.w600 : FontWeight.w400,
            color: isActive
                ? Colors.white : const Color(0xFFCBD5E1)))),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withOpacity(0.25)
                    : (badgeColor ?? const Color(0xFF1A56DB)),
                borderRadius: BorderRadius.circular(100)),
              child: Text(badge, style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: Colors.white))),
        ]),
      ),
    );
  }

  Widget _buildBottomProfile(
    BuildContext ctx, Map<String, dynamic>? profil,
  ) {
    final nom   = profil?['utilisateur']?['nom'] as String? ?? '';
    final email = profil?['utilisateur']?['email'] as String? ?? '';
    final photo = profil?['utilisateur']?['photo_url'] as String?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(
          color: Color(0x25FFFFFF)))),
      child: Row(children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFF1A56DB),
          backgroundImage: photo != null
              ? NetworkImage(photo) : null,
          child: photo == null
              ? Text(nom.isNotEmpty ? nom[0].toUpperCase() : 'R',
                  style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 12,
                    fontWeight: FontWeight.w700))
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nom.isNotEmpty ? nom : 'Recruteur',
            style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: Colors.white),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(email, style: GoogleFonts.inter(
            fontSize: 9, color: const Color(0xFF64748B)),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        GestureDetector(
          onTap: () {
            ctx.read<AuthProvider>().logout();
            ctx.go('/connexion');
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.logout_rounded,
              color: Color(0xFFEF4444), size: 14))),
      ]),
    );
  }
}
```

### 1.2 Topbar recruteur

```dart
// frontend/lib/screens/recruteur/recruteur_topbar.dart

class RecruteurTopbar extends StatelessWidget
    implements PreferredSizeWidget {
  final String pageTitle;
  const RecruteurTopbar({super.key, required this.pageTitle});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecruteurProvider>();

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(
          color: Color(0xFFE2E8F0))),
        boxShadow: [BoxShadow(
          color: Color(0x06000000), blurRadius: 8,
          offset: Offset(0, 2))]),
      child: Row(children: [
        // Titre
        Text(pageTitle, style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A))),
        const Spacer(),

        // Bouton Nouvelle offre (CTA principal)
        ElevatedButton.icon(
          icon: const Icon(Icons.add_rounded, size: 16),
          label: Text('Nouvelle offre', style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8))),
          onPressed: () => context.push(
            '/dashboard-recruteur/offres/nouvelle')),
        const SizedBox(width: 12),

        // Notifications
        Stack(children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
              color: Color(0xFF64748B), size: 22),
            onPressed: () => context.push(
              '/dashboard-recruteur/notifications')),
          if (provider.nbNotificationsNonLues > 0)
            Positioned(
              top: 6, right: 6,
              child: Container(
                width: 16, height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle),
                child: Center(child: Text(
                  '${provider.nbNotificationsNonLues}',
                  style: GoogleFonts.inter(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: Colors.white))))),
        ]),

        // Avatar
        Consumer<RecruteurProvider>(
          builder: (ctx, p, _) {
            final photo = p.profil?['logo_url'] as String?;
            final nom   = p.profil?['nom_entreprise']
                as String? ?? 'E';
            return GestureDetector(
              onTap: () => context.push(
                '/dashboard-recruteur/profil'),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF1A56DB).withOpacity(0.3),
                    width: 2)),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFEFF6FF),
                  backgroundImage: photo != null
                      ? NetworkImage(photo) : null,
                  child: photo == null ? Text(
                    nom[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A56DB)))
                    : null)));
          }),
        const SizedBox(width: 4),
        // Thème
        Consumer<ThemeProvider>(
          builder: (ctx, tp, _) => IconButton(
            icon: Icon(
              tp.isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_outlined,
              color: const Color(0xFF64748B), size: 20),
            onPressed: tp.toggleTheme)),
      ]),
    );
  }
}
```

---

## 2. Page Mes Offres — Couleurs remarquables

```dart
// Dans mes_offres_page.dart
// Améliorer _OffreListItem avec des couleurs vives

class _OffreListItem extends StatelessWidget {
  // Couleur gauche selon statut — très remarquable
  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'publiee':    return const Color(0xFF10B981); // Vert vif
      case 'en_attente': return const Color(0xFFF59E0B); // Orange
      case 'refusee':    return const Color(0xFFEF4444); // Rouge
      case 'expiree':    return const Color(0xFF94A3B8); // Gris
      case 'brouillon':  return const Color(0xFF8B5CF6); // Violet
      default:           return const Color(0xFFE2E8F0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statut = offre['statut'] as String? ?? '';
    final color  = _getStatusColor(statut);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(
          color: color.withOpacity(0.08),
          blurRadius: 12, offset: const Offset(0, 3))]),
      child: IntrinsicHeight(
        child: Row(children: [
          // Barre colorée gauche — 5px
          Container(
            width: 5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12)))),

          // Contenu
          Expanded(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

              // Ligne 1 : titre + badge statut + menu
              Row(children: [
                if (offre['en_vedette'] == true)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFFF59E0B), Color(0xFFEF4444)]),
                      borderRadius: BorderRadius.circular(100)),
                    child: Row(children: [
                      const Icon(Icons.star_rounded,
                        size: 10, color: Colors.white),
                      const SizedBox(width: 2),
                      Text('Vedette', style: GoogleFonts.inter(
                        fontSize: 9, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                    ])),
                Expanded(child: Text(
                  offre['titre'] as String? ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A)),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                // Badge statut coloré
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: color.withOpacity(0.3))),
                  child: Text(_statutLabel(statut),
                    style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: color))),
                _OffreActionsMenu(offre: offre, onRefresh: onRefresh),
              ]),
              const SizedBox(height: 8),

              // Ligne 2 : localisation + contrat
              Row(children: [
                const Icon(Icons.location_on_outlined,
                  size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(offre['localisation'] as String? ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF64748B))),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(100)),
                  child: Text(
                    offre['type_contrat'] as String? ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 11, color: const Color(0xFF1A56DB),
                      fontWeight: FontWeight.w500))),
              ]),
              const SizedBox(height: 10),

              // Ligne 3 : métriques
              Row(children: [
                _Metric(Icons.visibility_outlined,
                  '${offre['nb_vues'] ?? 0}',
                  'vues', const Color(0xFF8B5CF6)),
                const SizedBox(width: 16),
                _Metric(Icons.people_outline_rounded,
                  '${offre['nb_candidatures'] ?? 0}',
                  'candidats', const Color(0xFF1A56DB)),
                if ((offre['nb_non_lues'] as int? ?? 0) > 0) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFF10B981), Color(0xFF059669)]),
                      borderRadius: BorderRadius.circular(100)),
                    child: Row(children: [
                      const Icon(Icons.notifications_active_rounded,
                        size: 11, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '${offre['nb_non_lues']} nouvelle(s)',
                        style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                    ])),
                ],
                const Spacer(),
                // Voir les candidatures
                GestureDetector(
                  onTap: () => context.push(
                    '/dashboard-recruteur/candidatures?offre_id=${offre['id']}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A56DB).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF1A56DB).withOpacity(0.2))),
                    child: Row(children: [
                      const Icon(Icons.people_rounded,
                        size: 13, color: Color(0xFF1A56DB)),
                      const SizedBox(width: 5),
                      Text('Voir candidatures',
                        style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A56DB))),
                    ]))),
              ]),

              // Motif refus si refusée
              if (statut == 'refusee' &&
                  offre['raison_refus'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded,
                      size: 13, color: Color(0xFFEF4444)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(
                      'Motif : ${offre['raison_refus']}',
                      style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xFF991B1B),
                        fontStyle: FontStyle.italic),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ])),
              ],
            ]),
          )),
        ]),
      ),
    );
  }

  String _statutLabel(String s) {
    switch (s) {
      case 'publiee':    return 'Publiée ✓';
      case 'en_attente': return 'En validation';
      case 'refusee':    return 'Refusée';
      case 'expiree':    return 'Expirée';
      case 'brouillon':  return 'Brouillon';
      default:           return s;
    }
  }
}

class _Metric extends StatelessWidget {
  final IconData icon; final String value, label; final Color color;
  const _Metric(this.icon, this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min, children: [
    Container(
      width: 26, height: 26,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6)),
      child: Icon(icon, size: 13, color: color)),
    const SizedBox(width: 6),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: GoogleFonts.poppins(
        fontSize: 13, fontWeight: FontWeight.w800,
        color: const Color(0xFF0F172A))),
      Text(label, style: GoogleFonts.inter(
        fontSize: 10, color: const Color(0xFF94A3B8))),
    ]),
  ]);
}
```

---

## 3. Page Détail Candidature — Design complet

```dart
// frontend/lib/screens/recruteur/pages/candidature_detail_page.dart

class CandidatureDetailPage extends StatefulWidget {
  final String candidatureId;
  const CandidatureDetailPage({super.key, required this.candidatureId});
  @override
  State<CandidatureDetailPage> createState() =>
    _CandidatureDetailPageState();
}

class _CandidatureDetailPageState extends State<CandidatureDetailPage> {
  final RecruteurService _svc = RecruteurService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res   = await _svc.getCandidatureDetail(
        token, widget.candidatureId);
      setState(() {
        _data      = res['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(
      body: Center(child: CircularProgressIndicator(
        color: Color(0xFF1A56DB))));

    final cand     = _data ?? {};
    final chercheur = cand['chercheur'] as Map? ?? {};
    final user     = chercheur['utilisateur'] as Map? ?? {};
    final offre    = cand['offre']    as Map? ?? {};
    final cv       = cand['cv']       as Map?;
    final statut   = cand['statut']   as String? ?? '';
    final score    = cand['score_compatibilite'] as int?;
    final nom      = user['nom']      as String? ?? 'Candidat';
    final email    = user['email']    as String? ?? '';
    final tel      = user['telephone'] as String? ?? '';
    final ville    = user['adresse']  as String? ?? '';
    final photo    = user['photo_url'] as String?;
    final lettre   = cand['lettre_motivation'] as String? ?? '';

    Color statusColor; String statusLabel; IconData statusIcon;
    switch (statut) {
      case 'en_attente':
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'En attente de réponse';
        statusIcon  = Icons.hourglass_empty_rounded;
        break;
      case 'en_cours':
        statusColor = const Color(0xFF1A56DB);
        statusLabel = 'Candidature en examen';
        statusIcon  = Icons.search_rounded;
        break;
      case 'entretien':
        statusColor = const Color(0xFF8B5CF6);
        statusLabel = 'Entretien planifié';
        statusIcon  = Icons.event_available_rounded;
        break;
      case 'acceptee':
        statusColor = const Color(0xFF10B981);
        statusLabel = 'Candidature acceptée ✓';
        statusIcon  = Icons.check_circle_rounded;
        break;
      case 'refusee':
        statusColor = const Color(0xFFEF4444);
        statusLabel = 'Candidature refusée';
        statusIcon  = Icons.cancel_rounded;
        break;
      default:
        statusColor = const Color(0xFF94A3B8);
        statusLabel = statut;
        statusIcon  = Icons.circle_outlined;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0, backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text('Détail candidature', style: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // ── Colonne gauche ────────────────────────────
          Expanded(flex: 38, child: Column(children: [

            // Card candidat
            _ProfileCard(
              nom: nom, email: email, tel: tel, ville: ville,
              photo: photo, score: score,
              statusColor: statusColor,
              statusLabel: statusLabel,
              statusIcon: statusIcon,
            ),
            const SizedBox(height: 14),

            // Actions
            _ActionsCard(
              statut: statut,
              candidatureId: cand['id'] as String? ?? '',
              onAction: (action, {dateEntretien, lienVisio, raisonRefus}) async {
                final token = context.read<AuthProvider>().token ?? '';
                await _svc.actionCandidature(
                  token, cand['id'], action,
                  dateEntretien: dateEntretien,
                  lienVisio:     lienVisio,
                  raisonRefus:   raisonRefus);
                _load();
              },
            ),

            // CV
            if (cv != null) ...[
              const SizedBox(height: 14),
              _CVCard(cv: cv),
            ],
          ])),
          const SizedBox(width: 16),

          // ── Colonne droite ────────────────────────────
          Expanded(flex: 62, child: Column(children: [

            // Offre concernée
            _OffreConcerneeCard(offre: offre),
            const SizedBox(height: 14),

            // Lettre de motivation
            if (lettre.isNotEmpty) ...[
              _LettreCard(lettre: lettre),
              const SizedBox(height: 14),
            ],

            // Compétences
            _CompetencesCard(chercheur: chercheur, cv: cv),
          ])),
        ]),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String nom, email, tel, ville, statusLabel;
  final String? photo;
  final int? score;
  final Color statusColor;
  final IconData statusIcon;

  const _ProfileCard({
    required this.nom, required this.email, required this.tel,
    required this.ville, required this.statusLabel,
    required this.statusColor, required this.statusIcon,
    this.photo, this.score,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: const [BoxShadow(
        color: Color(0x06000000), blurRadius: 10,
        offset: Offset(0, 3))]),
    child: Column(children: [
      // Avatar + Score IA
      Stack(alignment: Alignment.topRight, children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: const Color(0xFF1A56DB).withOpacity(0.1),
          backgroundImage: photo != null ? NetworkImage(photo!) : null,
          child: photo == null ? Text(
            nom.isNotEmpty ? nom[0].toUpperCase() : '?',
            style: GoogleFonts.poppins(
              fontSize: 32, fontWeight: FontWeight.w800,
              color: const Color(0xFF1A56DB))) : null,
        ),
        if (score != null && score! > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _scoreColor(score!),
                _scoreColor(score!).withOpacity(0.7),
              ]),
              borderRadius: BorderRadius.circular(100)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.auto_awesome_rounded,
                size: 10, color: Colors.white),
              const SizedBox(width: 3),
              Text('$score%', style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: Colors.white)),
            ])),
      ]),
      const SizedBox(height: 12),

      // Nom
      Text(nom, style: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w800,
        color: const Color(0xFF0F172A)),
        textAlign: TextAlign.center),

      // Statut
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: statusColor.withOpacity(0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(statusIcon, size: 13, color: statusColor),
          const SizedBox(width: 5),
          Text(statusLabel, style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: statusColor)),
        ])),
      const SizedBox(height: 16),

      // Infos contact
      if (email.isNotEmpty) _ContactRow(Icons.email_outlined, email),
      if (tel.isNotEmpty)   _ContactRow(Icons.phone_outlined, tel),
      if (ville.isNotEmpty) _ContactRow(
        Icons.location_on_outlined, ville),

      // Bouton envoyer message
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.chat_bubble_outline, size: 15),
          label: const Text('Envoyer un message'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
            textStyle: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600)),
          onPressed: () {})),
    ]),
  );

  Color _scoreColor(int s) {
    if (s >= 80) return const Color(0xFF10B981);
    if (s >= 60) return const Color(0xFF1A56DB);
    if (s >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon; final String text;
  const _ContactRow(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
      const SizedBox(width: 8),
      Flexible(child: Text(text, style: GoogleFonts.inter(
        fontSize: 13, color: const Color(0xFF374151)),
        maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]));
}
```

---

## 4. Dialog Planifier Entretien — Formulaire amélioré

```dart
// Remplacer le dialog "AAMMJJTTHHMM" par des champs séparés
// clairs et intuitifs

class PlanifierEntretienDialog extends StatefulWidget {
  final String candidatureId;
  final Future<void> Function({
    required String dateEntretien,
    String? lienVisio,
    String? lieuPhysique,
    String? notes,
  }) onConfirm;

  const PlanifierEntretienDialog({
    super.key, required this.candidatureId,
    required this.onConfirm});
  @override
  State<PlanifierEntretienDialog> createState() =>
    _PlanifierEntretienDialogState();
}

class _PlanifierEntretienDialogState
    extends State<PlanifierEntretienDialog> {

  // Champs séparés — faciles à comprendre
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _typeEntretien = 'visio'; // visio | presentiel | telephone
  final _lienVisioCtrl  = TextEditingController();
  final _lieuCtrl       = TextEditingController();
  final _notesCtrl      = TextEditingController();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Container(
      width: 520,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [
              Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20))),
          child: Row(children: [
            const Icon(Icons.event_available_rounded,
              color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Planifier un entretien', style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: Colors.white)),
              Text('Le candidat sera notifié automatiquement',
                style: GoogleFonts.inter(
                  fontSize: 12, color: Colors.white70)),
            ])),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
          ]),
        ),

        // Contenu scrollable
        Flexible(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Étape 1 : Date ────────────────────────
            _StepLabel('1', 'Date de l\'entretien', const Color(0xFF8B5CF6)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now()
                      .add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now()
                      .add(const Duration(days: 90)),
                    locale: const Locale('fr', 'FR'),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _selectedDate != null
                        ? const Color(0xFFF5F3FF)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedDate != null
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFFE2E8F0))),
                  child: Row(children: [
                    Icon(Icons.calendar_today_rounded,
                      size: 16,
                      color: _selectedDate != null
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF94A3B8)),
                    const SizedBox(width: 8),
                    Text(
                      _selectedDate != null
                          ? '${_selectedDate!.day.toString().padLeft(2, '0')}/'
                            '${_selectedDate!.month.toString().padLeft(2, '0')}/'
                            '${_selectedDate!.year}'
                          : 'Choisir une date',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _selectedDate != null
                            ? const Color(0xFF6D28D9)
                            : const Color(0xFFCBD5E1),
                        fontWeight: _selectedDate != null
                            ? FontWeight.w600 : FontWeight.w400)),
                  ]),
                ),
              )),
              const SizedBox(width: 12),
              Expanded(child: GestureDetector(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 9, minute: 0),
                  );
                  if (time != null) {
                    setState(() => _selectedTime = time);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _selectedTime != null
                        ? const Color(0xFFF5F3FF)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedTime != null
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFFE2E8F0))),
                  child: Row(children: [
                    Icon(Icons.access_time_rounded, size: 16,
                      color: _selectedTime != null
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF94A3B8)),
                    const SizedBox(width: 8),
                    Text(
                      _selectedTime != null
                          ? _selectedTime!.format(context)
                          : 'Choisir l\'heure',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _selectedTime != null
                            ? const Color(0xFF6D28D9)
                            : const Color(0xFFCBD5E1),
                        fontWeight: _selectedTime != null
                            ? FontWeight.w600 : FontWeight.w400)),
                  ]),
                ),
              )),
            ]),
            const SizedBox(height: 20),

            // ── Étape 2 : Type d'entretien ────────────
            _StepLabel('2', 'Format de l\'entretien',
              const Color(0xFF8B5CF6)),
            const SizedBox(height: 10),
            Row(children: [
              _TypeOption('visio', Icons.video_call_rounded,
                'Visioconférence', _typeEntretien,
                (v) => setState(() => _typeEntretien = v)),
              const SizedBox(width: 8),
              _TypeOption('presentiel', Icons.location_on_rounded,
                'Présentiel', _typeEntretien,
                (v) => setState(() => _typeEntretien = v)),
              const SizedBox(width: 8),
              _TypeOption('telephone', Icons.phone_rounded,
                'Téléphone', _typeEntretien,
                (v) => setState(() => _typeEntretien = v)),
            ]),
            const SizedBox(height: 16),

            // ── Étape 3 : Lien ou lieu ────────────────
            if (_typeEntretien == 'visio') ...[
              _StepLabel('3', 'Lien de visioconférence',
                const Color(0xFF8B5CF6)),
              const SizedBox(height: 8),
              _InputField(
                ctrl: _lienVisioCtrl,
                hint: 'https://meet.google.com/xxx-xxxx',
                icon: Icons.link_rounded,
              ),
            ] else if (_typeEntretien == 'presentiel') ...[
              _StepLabel('3', 'Lieu de l\'entretien',
                const Color(0xFF8B5CF6)),
              const SizedBox(height: 8),
              _InputField(
                ctrl: _lieuCtrl,
                hint: 'Ex: Bureau Almamya, Conakry',
                icon: Icons.location_on_outlined,
              ),
            ] else ...[
              _StepLabel('3', 'Numéro de téléphone à appeler',
                const Color(0xFF8B5CF6)),
              const SizedBox(height: 8),
              _InputField(
                ctrl: _lieuCtrl,
                hint: '+224 620 00 00 00',
                icon: Icons.phone_outlined,
              ),
            ],
            const SizedBox(height: 16),

            // ── Étape 4 : Notes (optionnel) ───────────
            _StepLabel('4', 'Notes pour le candidat (optionnel)',
              const Color(0xFF94A3B8)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl, maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ex: Préparez une présentation de 5 min...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFFCBD5E1)),
                filled: true, fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0))),
              ),
            ),

            // Résumé si date choisie
            if (_selectedDate != null && _selectedTime != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3))),
                child: Row(children: [
                  const Icon(Icons.event_available_rounded,
                    color: Color(0xFF8B5CF6), size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    'Entretien le ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                    ' à ${_selectedTime!.format(context)}'
                    ' (${_typeLabel(_typeEntretien)})',
                    style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: const Color(0xFF6D28D9)))),
                ])),
            ],
          ])),
        )),

        // Boutons
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Row(children: [
            Expanded(child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler', style: GoogleFonts.inter(
                color: const Color(0xFF64748B))))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(
                _isSaving ? 'Envoi...' : 'Confirmer l\'entretien',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedDate != null
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFFE2E8F0),
                foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
              onPressed: (_selectedDate == null || _isSaving)
                  ? null : _confirmer)),
          ]),
        ),
      ]),
    ),
  );

  Future<void> _confirmer() async {
    if (_selectedDate == null || _selectedTime == null) return;
    setState(() => _isSaving = true);
    final dt = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
      _selectedTime!.hour, _selectedTime!.minute);
    await widget.onConfirm(
      dateEntretien: dt.toIso8601String(),
      lienVisio: _lienVisioCtrl.text.isNotEmpty
          ? _lienVisioCtrl.text : null,
      lieuPhysique: _lieuCtrl.text.isNotEmpty
          ? _lieuCtrl.text : null,
      notes: _notesCtrl.text.isNotEmpty
          ? _notesCtrl.text : null,
    );
    if (mounted) Navigator.pop(context);
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'visio':       return 'Visioconférence';
      case 'presentiel':  return 'Présentiel';
      case 'telephone':   return 'Téléphone';
      default:            return t;
    }
  }
}

class _TypeOption extends StatelessWidget {
  final String value, label; final IconData icon;
  final String selected; final void Function(String) onTap;
  const _TypeOption(this.value, this.icon, this.label,
    this.selected, this.onTap);
  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Expanded(child: GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF5F3FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8B5CF6)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1)),
        child: Column(children: [
          Icon(icon, size: 20,
            color: isSelected
                ? const Color(0xFF8B5CF6)
                : const Color(0xFF94A3B8)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(
            fontSize: 11, fontWeight: isSelected
                ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? const Color(0xFF6D28D9)
                : const Color(0xFF64748B)),
            textAlign: TextAlign.center),
        ]),
      ),
    ));
  }
}

class _StepLabel extends StatelessWidget {
  final String num, label; final Color color;
  const _StepLabel(this.num, this.label, this.color);
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 22, height: 22,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(child: Text(num, style: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w800,
        color: Colors.white)))),
    const SizedBox(width: 8),
    Text(label, style: GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w600,
      color: const Color(0xFF374151))),
  ]);
}

class _InputField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint; final IconData icon;
  const _InputField({required this.ctrl,
    required this.hint, required this.icon});
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 13, color: const Color(0xFFCBD5E1)),
      prefixIcon: Icon(icon, size: 18,
        color: const Color(0xFF94A3B8)),
      filled: true, fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFF8B5CF6), width: 1.5)),
    ),
  );
}
```

---

## 5. Page Recherche Talents — Design extraordinaire

```dart
// Améliorer la grille des cartes talents
// Cartes redesignées avec toutes les infos visibles

class _TalentCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ... (garder la logique existante)
    // Améliorer uniquement le design des cards

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(
          color: Color(0x08000000), blurRadius: 12,
          offset: Offset(0, 4))]),
      child: Column(children: [

        // ── Zone supérieure dégradée ──────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFEFF6FF),
                score != null && score! >= 70
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFF0F9FF),
              ]),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16))),
          child: Column(children: [
            // Score IA en haut à droite
            if (score != null && score! > 0)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _scoreColor(score!),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [BoxShadow(
                      color: _scoreColor(score!).withOpacity(0.3),
                      blurRadius: 6)]),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.auto_awesome_rounded,
                      size: 10, color: Colors.white),
                    const SizedBox(width: 3),
                    Text('$score%', style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w800,
                      color: Colors.white)),
                  ]))),
            if (score != null) const SizedBox(height: 6),

            // Avatar
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFF1A56DB).withOpacity(0.1),
              backgroundImage: photo != null ? NetworkImage(photo!) : null,
              child: photo == null ? Text(
                nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(
                  fontSize: 24, fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A56DB))) : null,
            ),
            const SizedBox(height: 8),
            Text(nom, style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A)),
              textAlign: TextAlign.center,
              maxLines: 1, overflow: TextOverflow.ellipsis),
            if (titre.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(titre, style: GoogleFonts.inter(
                fontSize: 11, color: const Color(0xFF64748B)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
            if (ville.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.location_on_outlined,
                  size: 11, color: Color(0xFF94A3B8)),
                const SizedBox(width: 3),
                Flexible(child: Text(ville, style: GoogleFonts.inter(
                  fontSize: 11, color: const Color(0xFF94A3B8)),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ],
          ]),
        ),

        // ── Zone inférieure ───────────────────────────
        Expanded(child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(children: [

            // Disponibilité
            if (dispo.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 5),
                decoration: BoxDecoration(
                  color: _dispoColor(dispo).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _dispoColor(dispo).withOpacity(0.3))),
                child: Text(_dispoLabel(dispo),
                  style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: _dispoColor(dispo)),
                  textAlign: TextAlign.center)),
            const SizedBox(height: 8),

            // Compétences
            if (comps.isNotEmpty)
              Wrap(spacing: 4, runSpacing: 4,
                alignment: WrapAlignment.center,
                children: comps.take(3).map((s) =>
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: const Color(0xFFBFDBFE))),
                    child: Text(s.toString(), style: GoogleFonts.inter(
                      fontSize: 9, fontWeight: FontWeight.w500,
                      color: const Color(0xFF1E40AF))))
                ).toList()),

            const Spacer(),

            // Boutons action
            Row(children: [
              // Signaler
              Tooltip(
                message: 'Signaler ce profil',
                child: GestureDetector(
                  onTap: () => _signaler(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.flag_outlined,
                      size: 14, color: Color(0xFFEF4444))))),
              const SizedBox(width: 6),
              // Contacter
              Expanded(child: ElevatedButton.icon(
                icon: const Icon(Icons.chat_rounded, size: 13),
                label: const Text('Contacter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56DB),
                  foregroundColor: Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                  textStyle: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600)),
                onPressed: () => _showContactDialog(context))),
            ]),
          ]),
        )),
      ]),
    );
  }

  Color _scoreColor(int s) {
    if (s >= 80) return const Color(0xFF10B981);
    if (s >= 60) return const Color(0xFF1A56DB);
    if (s >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Color _dispoColor(String d) {
    switch (d) {
      case 'immediat': return const Color(0xFF10B981);
      case '1_mois':   return const Color(0xFFF59E0B);
      default:         return const Color(0xFF94A3B8);
    }
  }

  String _dispoLabel(String d) {
    switch (d) {
      case 'immediat':  return '🟢 Disponible maintenant';
      case '1_mois':    return '🟡 Disponible dans 1 mois';
      case '3_mois':    return '🔵 Disponible dans 3 mois';
      default:          return d;
    }
  }

  void _signaler(BuildContext ctx) {
    // Dialog signalement rapide
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: Text('Signaler ce profil', style: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w700)),
      content: Text('Voulez-vous signaler ce profil pour contenu inapproprié ?',
        style: GoogleFonts.inter(fontSize: 14)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444), elevation: 0),
          onPressed: () => Navigator.pop(ctx),
          child: Text('Signaler', style: GoogleFonts.inter(
            color: Colors.white, fontWeight: FontWeight.w600))),
      ],
    ));
  }
}
```

---

## 6. Dialog Contacter un Talent — Options enrichies

```dart
// Améliorer le dialog d'envoi de message à un talent

void _showContactDialog(BuildContext context) {
  final ctrl = TextEditingController(
    text: 'Bonjour $nom,\n\n'
          'Votre profil a retenu toute notre attention. '
          'Nous serions ravis de discuter avec vous d\'une '
          'opportunité correspondant à vos compétences.\n\n'
          'Seriez-vous disponible pour un entretien ?');
  String _objet = 'opportunite'; // opportunite | entretien | info

  showDialog(context: context, builder: (ctx) =>
    StatefulBuilder(builder: (ctx, setDialogState) =>
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [

            // Header
            Row(children: [
              CircleAvatar(
                radius: 20, backgroundColor: const Color(0xFF1A56DB),
                backgroundImage: photo != null
                    ? NetworkImage(photo!) : null,
                child: photo == null ? Text(nom[0].toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.bold))
                    : null),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Contacter $nom', style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A))),
                Text('Message envoyé dans sa messagerie',
                  style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF64748B))),
              ])),
              IconButton(
                icon: const Icon(Icons.close, size: 18,
                  color: Color(0xFF94A3B8)),
                onPressed: () => Navigator.pop(ctx)),
            ]),
            const SizedBox(height: 16),

            // Type de message
            Text('Objet du message', style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500,
              color: const Color(0xFF374151))),
            const SizedBox(height: 8),
            Row(children: [
              _ObjChip('💼 Opportunité', 'opportunite', _objet,
                (v) => setDialogState(() => _objet = v)),
              const SizedBox(width: 8),
              _ObjChip('📅 Entretien', 'entretien', _objet,
                (v) => setDialogState(() => _objet = v)),
              const SizedBox(width: 8),
              _ObjChip('ℹ️ Info', 'info', _objet,
                (v) => setDialogState(() => _objet = v)),
            ]),
            const SizedBox(height: 14),

            // Message
            Text('Message', style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500,
              color: const Color(0xFF374151))),
            const SizedBox(height: 6),
            TextFormField(
              controller: ctrl, maxLines: 5,
              decoration: InputDecoration(
                filled: true, fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0))),
              ),
            ),
            const SizedBox(height: 16),

            // Boutons
            Row(children: [
              Expanded(child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
                onPressed: () => Navigator.pop(ctx),
                child: Text('Annuler', style: GoogleFonts.inter(
                  color: const Color(0xFF64748B))))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(
                icon: const Icon(Icons.send_rounded, size: 15),
                label: const Text('Envoyer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56DB),
                  foregroundColor: Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                  textStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w600)),
                onPressed: () {
                  Navigator.pop(ctx);
                  onContact(userId, ctrl.text);
                })),
            ]),
          ]),
        ),
      )));
}

class _ObjChip extends StatelessWidget {
  final String label, value, selected;
  final void Function(String) onTap;
  const _ObjChip(this.label, this.value, this.selected, this.onTap);
  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Expanded(child: GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1A56DB) : const Color(0xFFE2E8F0))),
        child: Text(label, style: GoogleFonts.inter(
          fontSize: 11, fontWeight: isSelected
              ? FontWeight.w600 : FontWeight.w400,
          color: isSelected
              ? const Color(0xFF1A56DB) : const Color(0xFF64748B)),
          textAlign: TextAlign.center))));
  }
}
```

---

## 7. Page Profil Entreprise — Aperçu + Design

```dart
// Dans profil_entreprise_page.dart
// Remplacer la section "Aperçu" statique par un bouton

// ── Bouton Aperçu (en bas du formulaire) ──────────────────
Container(
  margin: const EdgeInsets.only(top: 16),
  decoration: BoxDecoration(
    gradient: const LinearGradient(colors: [
      Color(0xFFEFF6FF), Color(0xFFF0F9FF)]),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: const Color(0xFF1A56DB).withOpacity(0.2))),
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showApercu(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1A56DB),
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.preview_rounded,
              color: Colors.white, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Aperçu du profil public',
              style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A))),
            Text(
              'Voir comment les candidats voient votre profil',
              style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFF64748B))),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: Color(0xFF94A3B8)),
        ]),
      ),
    ),
  ),
),

// Dialog Aperçu du profil public
void _showApercu(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Header dialog
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF1A56DB),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20))),
            child: Row(children: [
              const Icon(Icons.preview_rounded,
                color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text('Aperçu public de votre entreprise',
                style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: Colors.white)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context)),
            ])),

          // Contenu : simuler la vue candidat
          Flexible(child: SingleChildScrollView(
            child: Column(children: [
              // Bannière
              Stack(children: [
                Container(
                  height: 140, width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    image: _profil?['banniere_url'] != null
                        ? DecorationImage(
                            image: NetworkImage(
                              _profil!['banniere_url']),
                            fit: BoxFit.cover)
                        : null),
                  child: _profil?['banniere_url'] == null
                      ? Container(decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Color(0xFF1E3A8A), Color(0xFF1A56DB)])))
                      : null),
                Positioned(
                  bottom: -28, left: 20,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [BoxShadow(
                        color: Color(0x20000000),
                        blurRadius: 8)]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _profil?['logo_url'] != null
                          ? Image.network(
                              _profil!['logo_url'],
                              width: 52, height: 52,
                              fit: BoxFit.cover)
                          : Container(
                              width: 52, height: 52,
                              color: const Color(0xFFEFF6FF),
                              child: Center(child: Text(
                                (_profil?['nom_entreprise'] ?? 'E')[0],
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1A56DB)))))),
                    )),
              ]),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    _profil?['nom_entreprise'] ?? 'Mon Entreprise',
                    style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A))),
                  if (_profil?['slogan']?.isNotEmpty == true)
                    Text(_profil!['slogan'], style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    if (_profil?['secteur_activite'] != null)
                      _AperçuTag(_profil!['secteur_activite']),
                    if (_profil?['taille_entreprise'] != null)
                      _AperçuTag(_profil!['taille_entreprise']),
                    if (_profil?['adresse_siege'] != null)
                      _AperçuTag(_profil!['adresse_siege']),
                  ]),
                  if (_profil?['description']?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    Text('À propos', style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A))),
                    const SizedBox(height: 6),
                    Text(_profil!['description'],
                      style: GoogleFonts.inter(
                        fontSize: 13, color: const Color(0xFF374151),
                        height: 1.5)),
                  ],
                ]),
              ),
            ])),
          )),

          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56DB),
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
                onPressed: () => Navigator.pop(context),
                child: Text('Fermer l\'aperçu',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600))))),
        ]),
      )));
}

class _AperçuTag extends StatelessWidget {
  final String text;
  const _AperçuTag(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(100)),
    child: Text(text, style: GoogleFonts.inter(
      fontSize: 12, color: const Color(0xFF374151))));
}
```

---

## 8. Messagerie — Nouveau Message + Pièces jointes

### 8.1 Fix recherche candidat dans "Nouveau message"

```javascript
// Dans backend/src/routes/recruteur/messages.routes.js
// Route de recherche candidats

router.get('/rechercher-destinataire', auth, requireRecruteur,
  async (req, res) => {
  try {
    const { q, type = 'tous' } = req.query;
    if (!q || q.trim().length < 2) {
      return res.json({ success: true, data: [] });
    }

    const terme = `%${q.trim()}%`;
    let resultats = [];

    // Candidats ayant postulé aux offres de ce recruteur
    if (type === 'tous' || type === 'postule') {
      const { data: offres } = await supabase
        .from('offres_emploi')
        .select('id')
        .eq('entreprise_id', req.entreprise.id);

      const offresIds = (offres || []).map(o => o.id);

      if (offresIds.length > 0) {
        const { data: cands } = await supabase
          .from('candidatures')
          .select(`
            chercheur:chercheur_id (
              utilisateur:utilisateur_id (
                id, nom, email, photo_url
              )
            )
          `)
          .in('offre_id', offresIds)
          .or(`chercheur.utilisateur.nom.ilike.${terme},chercheur.utilisateur.email.ilike.${terme}`);

        const users = [];
        (cands || []).forEach(c => {
          const u = c.chercheur?.utilisateur;
          if (u && !users.find(x => x.id === u.id)) {
            users.push({ ...u, type: 'postule' });
          }
        });
        resultats.push(...users);
      }
    }

    // Tous les candidats si pas de résultat
    if (resultats.length === 0 && type !== 'postule') {
      const { data: users } = await supabase
        .from('utilisateurs')
        .select('id, nom, email, photo_url, role')
        .or(`nom.ilike.${terme},email.ilike.${terme}`)
        .in('role', ['chercheur'])
        .limit(10);
      resultats = (users || []).map(u => ({ ...u, type: 'talent' }));
    }

    return res.json({ success: true, data: resultats.slice(0, 10) });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});
```

### 8.2 Flutter — Upload pièces jointes dans messagerie

```dart
// Dans la zone de saisie de message de la messagerie
// Ajouter le bouton pièce jointe

Widget _buildMessageInput() => Container(
  padding: const EdgeInsets.all(12),
  color: Colors.white,
  child: Column(children: [

    // Fichier en cours d'envoi
    if (_fichierEnAttente != null)
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF1A56DB).withOpacity(0.3))),
        child: Row(children: [
          const Icon(Icons.attach_file_rounded,
            color: Color(0xFF1A56DB), size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(
            _fichierEnAttente!.name,
            style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFF1A56DB)))),
          GestureDetector(
            onTap: () => setState(() => _fichierEnAttente = null),
            child: const Icon(Icons.close, size: 16,
              color: Color(0xFF94A3B8))),
        ])),

    Row(children: [
      // Bouton pièce jointe
      GestureDetector(
        onTap: _choisirFichier,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.attach_file_rounded,
            color: Color(0xFF64748B), size: 20))),
      const SizedBox(width: 8),

      // Bouton image
      GestureDetector(
        onTap: _choisirImage,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.image_outlined,
            color: Color(0xFF64748B), size: 20))),
      const SizedBox(width: 8),

      // Champ texte
      Expanded(child: TextField(
        controller: _msgCtrl, maxLines: null,
        textInputAction: TextInputAction.send,
        decoration: InputDecoration(
          hintText: 'Écrire un message...',
          hintStyle: GoogleFonts.inter(
            fontSize: 14, color: const Color(0xFFCBD5E1)),
          filled: true, fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: const BorderSide(
              color: Color(0xFF1A56DB), width: 1.5)),
        ),
        onSubmitted: (_) => _sendMessage(),
      )),
      const SizedBox(width: 8),

      // Bouton envoyer
      GestureDetector(
        onTap: _sendMessage,
        child: Container(
          width: 44, height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFF1A56DB),
            shape: BoxShape.circle),
          child: const Icon(Icons.send_rounded,
            color: Colors.white, size: 20))),
    ]),
  ]),
);

Future<void> _choisirFichier() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _fichierEnAttente = result.files.first);
    }
  } catch (e) {
    print('[messagerie] FilePicker error: $e');
  }
}

Future<void> _choisirImage() async {
  final picker = ImagePicker();
  final file   = await picker.pickImage(source: ImageSource.gallery);
  if (file != null) {
    // Créer un PlatformFile depuis XFile
    final bytes = await file.readAsBytes();
    setState(() => _fichierEnAttente = PlatformFile(
      name: file.name, size: bytes.length, bytes: bytes));
  }
}
```

---

## 9. Page Paramètres Recruteur — Design amélioré

```dart
// Enlever "Entreprise ID" (inutile pour l'utilisateur)
// Améliorer les sections

class _SectionComptePlatform extends StatelessWidget {
  final Map<String, dynamic>? data;
  @override
  Widget build(BuildContext context) {
    final email   = data?['profil']?['email']   as String? ?? '';
    final role    = data?['profil']?['role']    as String? ?? '';

    return _ParamCard(title: 'Informations du compte', children: [

      // Email (lecture seule)
      _ReadOnlyField(
        icon: Icons.email_outlined,
        label: 'Adresse email',
        value: email,
        note: 'Non modifiable'),

      const SizedBox(height: 12),

      // Rôle (lecture seule, stylisé)
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Row(children: [
          const Icon(Icons.business_center_outlined,
            color: Color(0xFF94A3B8), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Rôle', style: GoogleFonts.inter(
              fontSize: 11, color: const Color(0xFF94A3B8))),
            Text('Recruteur / Entreprise', style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A))),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(100)),
            child: Text('Vérifié ✓', style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: const Color(0xFF1A56DB)))),
          // NOTE : NE PAS afficher "Entreprise ID" — inutile
        ])),

      const SizedBox(height: 12),

      // Lien vers profil entreprise
      GestureDetector(
        onTap: () =>
          context.push('/dashboard-recruteur/profil'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              const Color(0xFF1A56DB).withOpacity(0.05),
              const Color(0xFF0EA5E9).withOpacity(0.02),
            ]),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF1A56DB).withOpacity(0.2))),
          child: Row(children: [
            const Icon(Icons.business_rounded,
              color: Color(0xFF1A56DB), size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'Gérer le profil de votre entreprise',
              style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w500,
                color: const Color(0xFF1A56DB)))),
            const Icon(Icons.arrow_forward_ios_rounded,
              size: 13, color: Color(0xFF1A56DB)),
          ])),
      ),
    ]);
  }
}

class _ReadOnlyField extends StatelessWidget {
  final IconData icon; final String label, value; final String? note;
  const _ReadOnlyField({required this.icon, required this.label,
    required this.value, this.note});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Row(children: [
      Icon(icon, color: const Color(0xFF94A3B8), size: 18),
      const SizedBox(width: 10),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(
          fontSize: 11, color: const Color(0xFF94A3B8))),
        Text(value, style: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A))),
      ])),
      if (note != null)
        Text(note!, style: GoogleFonts.inter(
          fontSize: 11, color: const Color(0xFF94A3B8),
          fontStyle: FontStyle.italic)),
    ]));
}
```

---

## 10. Page Publier une Offre — Formulaire amélioré

```dart
// Ajouter des touches design au formulaire existant
// Sans tout recréer — améliorer les sections

// En-tête du formulaire
Container(
  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)]),
    borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
  child: Row(children: [
    const Icon(Icons.work_outline_rounded,
      color: Colors.white, size: 24),
    const SizedBox(width: 12),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Publier une offre d\'emploi',
        style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: Colors.white)),
      Text('Remplissez les informations ci-dessous',
        style: GoogleFonts.inter(
          fontSize: 12, color: Colors.white70)),
    ]),
    const Spacer(),
    // Badge IA
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(100)),
      child: Row(children: [
        const Icon(Icons.auto_awesome_rounded,
          size: 12, color: Colors.white),
        const SizedBox(width: 4),
        Text('IA activée', style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: Colors.white)),
      ])),
  ]),
),

// Indicateur d'étapes
Container(
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  child: Row(children: [
    _FormulaireStep(1, 'Infos générales', true),
    _StepConnector(),
    _FormulaireStep(2, 'Compétences', _currentStep >= 2),
    _StepConnector(),
    _FormulaireStep(3, 'Salaire & Contrat', _currentStep >= 3),
  ]),
),
```

---

## 11. Critères d'Acceptation

### ✅ Sidebar + Topbar
- [ ] Fond sidebar : dégradé bleu nuit #0F172A → #1E293B
- [ ] Item actif : fond bleu #1A56DB, texte blanc, bordure subtile
- [ ] Badges colorés (vert candidatures, rouge notifications, bleu offres)
- [ ] Logo entreprise + badge "Pro" dans le header
- [ ] Profil recruteur + bouton déconnexion en bas
- [ ] Topbar : bouton "Nouvelle offre" bleu + badge notifications

### ✅ Mes Offres
- [ ] Barre gauche colorée selon statut (vert/orange/rouge/violet/gris)
- [ ] Badge statut avec couleur + label clair
- [ ] Métriques : vues et candidats avec icônes colorées
- [ ] Badge gradient vert "X nouvelles" si candidatures non traitées
- [ ] Bouton "Voir candidatures" en bas de chaque carte

### ✅ Détail Candidature
- [ ] Page plein écran avec 2 colonnes (profil/CV gauche, offre/lettre droite)
- [ ] Avatar avec overlay score IA
- [ ] Badge statut coloré centré
- [ ] Infos contact (email, tel, ville)
- [ ] Bouton envoyer message
- [ ] Section compétences extraites du CV

### ✅ Dialog Planifier Entretien
- [ ] Date picker natif Flutter (plus de "AAMMJJHHMM")
- [ ] Time picker natif Flutter
- [ ] 3 types : Visioconférence / Présentiel / Téléphone
- [ ] Champ adapté selon le type (lien / lieu / numéro)
- [ ] Résumé récapitulatif avant confirmation
- [ ] Notes optionnelles pour le candidat

### ✅ Recherche Talents
- [ ] Cartes avec zone supérieure dégradée
- [ ] Score IA avec couleur + glow shadow
- [ ] Disponibilité colorée et claire
- [ ] Bouton signaler + bouton contacter
- [ ] Dialog contact avec type de message

### ✅ Profil Entreprise
- [ ] Section aperçu remplacée par bouton "Voir l'aperçu public"
- [ ] Dialog aperçu avec bannière + logo + infos

### ✅ Messagerie
- [ ] Recherche candidat fonctionnelle (min 2 caractères)
- [ ] Bouton pièce jointe (fichiers PDF/DOC)
- [ ] Bouton image (galerie)
- [ ] Aperçu fichier avant envoi

### ✅ Paramètres
- [ ] "Entreprise ID" supprimé (inutile)
- [ ] Lien vers profil entreprise
- [ ] Champs lecture seule stylisés
- [ ] Design cohérent avec le reste

---

*PRD EmploiConnect v7.1 — Recruteur Design Polish*
*Cursor / Kirsoft AI — Phase 12*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
