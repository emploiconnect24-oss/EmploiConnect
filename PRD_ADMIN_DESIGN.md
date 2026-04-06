# PRD — EmploiConnect · Amélioration Design Admin
## Product Requirements Document v7.0 — Admin Design Polish
**Stack : Flutter + Node.js/Express**
**Outil : Cursor / Kirsoft AI**
**Objectif : Peaufinage design complet de l'espace administrateur**
**Date : Mars 2026**

---

> ### ⚠️ INSTRUCTIONS POUR CURSOR
>
> Ce PRD améliore le design existant. NE PAS recréer depuis zéro.
> Modifier ce qui existe, améliorer les couleurs, corriger les débordements.
> Ordre : Sidebar → Topbar → Tables → Pages détail → Mobile → Recherche.

---

## Table des Matières

1. [Fix Overflow "Bottom overflowed by 9px"](#1-fix-overflow)
2. [Sidebar Admin — Nouveau design coloré](#2-sidebar-admin--nouveau-design)
3. [Topbar Admin — Design amélioré](#3-topbar-admin--design-amélioré)
4. [Table Utilisateurs — Colonnes manquantes + Design](#4-table-utilisateurs)
5. [Page Détail Utilisateur — Design extraordinaire](#5-page-détail-utilisateur)
6. [Page Détails Offre — Design extraordinaire](#6-page-détails-offre)
7. [Responsivité Mobile Admin](#7-responsivité-mobile-admin)
8. [Recherche Globale Admin](#8-recherche-globale-admin)
9. [Critères d'Acceptation](#9-critères-dacceptation)

---

## 1. Fix Overflow

### Trouver et corriger TOUS les overflows

```bash
# Chercher dans tous les fichiers admin Flutter :
grep -rn "overflow\|Expanded\|Column\|ListView" \
  frontend/lib/screens/admin --include="*.dart" -l
```

### Fix général — Envelopper les Columns problématiques

```dart
// RÈGLE : Dans l'espace admin, tout Column dans un Row ou dans
// un Container sans hauteur fixe doit avoir mainAxisSize ou
// être dans un Flexible/Expanded.

// AVANT ❌ — cause "bottom overflowed by 9px"
Column(children: [
  Text('...'),
  DataTable(...), // Table trop haute
])

// APRÈS ✅
Column(children: [
  Text('...'),
  Flexible(  // ← Envelopper le DataTable
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(...),
    ),
  ),
])

// Pour les pages complètes admin :
// Remplacer Column → SingleChildScrollView > Column
// OU utiliser ListView au lieu de Column

// Fix spécifique pour la page Offres Emploi Admin :
// Trouver dans admin/pages/jobs_page.dart ou offres_page.dart
// Remplacer la structure de base par :

class _OffresAdminPageState extends State<OffresAdminPage> {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Header fixe
      _buildHeader(),
      // Filtres fixes
      _buildFiltres(),
      // Table scrollable
      Expanded(  // ← CRUCIAL : Expanded pour la table
        child: SingleChildScrollView(
          child: _buildTable(),
        ),
      ),
    ]);
  }
}
```

---

## 2. Sidebar Admin — Nouveau Design

### Remplacer le fond noir par un design moderne

```dart
// frontend/lib/screens/admin/admin_sidebar.dart
// Remplacer complètement le design de la sidebar

class AdminSidebar extends StatelessWidget {
  final String currentRoute;
  const AdminSidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      height: double.infinity,
      decoration: const BoxDecoration(
        // Remplacer le fond noir par un dégradé bleu profond élégant
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A), // Bleu nuit profond
            Color(0xFF1E293B), // Bleu ardoise
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 20,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(children: [

        // ── Logo + Titre ──────────────────────────────
        _buildLogoSection(context),

        // ── Menu items ───────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 8),
            children: [
              _buildSection('TABLEAU DE BORD', [
                _buildMenuItem(
                  context, Icons.dashboard_rounded,
                  'Vue d\'ensemble', '/admin/dashboard',
                  currentRoute),
              ]),
              _buildSection('GESTION', [
                _buildMenuItem(
                  context, Icons.people_rounded,
                  'Utilisateurs', '/admin/utilisateurs',
                  currentRoute,
                  badgeCount: _getBadge(context, 'users')),
                _buildMenuItem(
                  context, Icons.work_rounded,
                  'Offres d\'emploi', '/admin/offres',
                  currentRoute,
                  badgeCount: _getBadge(context, 'offres')),
                _buildMenuItem(
                  context, Icons.business_rounded,
                  'Entreprises', '/admin/entreprises',
                  currentRoute),
                _buildMenuItem(
                  context, Icons.assignment_rounded,
                  'Candidatures', '/admin/candidatures',
                  currentRoute),
                _buildMenuItem(
                  context, Icons.flag_rounded,
                  'Signalements', '/admin/signalements',
                  currentRoute,
                  badgeCount: _getBadge(context, 'signalements')),
              ]),
              _buildSection('COMMUNICATION', [
                _buildMenuItem(
                  context, Icons.notifications_rounded,
                  'Notifications', '/admin/notifications',
                  currentRoute),
                _buildMenuItem(
                  context, Icons.image_rounded,
                  'Bannières', '/admin/bannieres',
                  currentRoute),
              ]),
              _buildSection('SYSTÈME', [
                _buildMenuItem(
                  context, Icons.search_rounded,
                  'Recherche globale', '/admin/recherche',
                  currentRoute),
                _buildMenuItem(
                  context, Icons.settings_rounded,
                  'Paramètres', '/admin/parametres',
                  currentRoute),
              ]),
            ],
          ),
        ),

        // ── Profil Admin en bas ───────────────────────
        _buildAdminProfile(context),
      ]),
    );
  }

  Widget _buildLogoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0x20FFFFFF), width: 1))),
      child: Row(children: [
        // Logo
        Consumer<AppConfigProvider>(
          builder: (ctx, cfg, _) =>
            cfg.logoUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    cfg.logoUrl, width: 36, height: 36,
                    fit: BoxFit.cover))
              : Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A56DB),
                    borderRadius: BorderRadius.circular(8)),
                  child: const Icon(
                    Icons.work_rounded,
                    color: Colors.white, size: 20)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('EmploiConnect', style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: Colors.white)),
          Text('Administration', style: GoogleFonts.inter(
            fontSize: 11, color: const Color(0xFF94A3B8))),
        ])),
        // Badge "Admin"
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF1A56DB).withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: const Color(0xFF1A56DB).withOpacity(0.5))),
          child: Text('Admin', style: GoogleFonts.inter(
            fontSize: 9, fontWeight: FontWeight.w700,
            color: const Color(0xFF60A5FA)))),
      ]),
    );
  }

  Widget _buildSection(String titre, List<Widget> items) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
        child: Text(titre, style: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w600,
          color: const Color(0xFF475569),
          letterSpacing: 0.8))),
      ...items,
    ]);

  Widget _buildMenuItem(
    BuildContext context, IconData icon, String label,
    String route, String currentRoute, {int? badgeCount}
  ) {
    final isActive = currentRoute.startsWith(route) &&
        route != '/admin/dashboard' ||
        currentRoute == route;

    return GestureDetector(
      onTap: () => context.go(route),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          // Fond actif : bleu lumineux
          color: isActive
              ? const Color(0xFF1A56DB)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          // Effet hover simulé
          border: Border.all(
            color: isActive
                ? const Color(0xFF3B82F6).withOpacity(0.5)
                : Colors.transparent),
        ),
        child: Row(children: [
          // Icône
          Icon(icon, size: 18,
            color: isActive
                ? Colors.white
                : const Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          // Label
          Expanded(child: Text(label, style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isActive
                ? FontWeight.w600 : FontWeight.w400,
            color: isActive
                ? Colors.white
                : const Color(0xFFCBD5E1)))),
          // Badge
          if (badgeCount != null && badgeCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withOpacity(0.25)
                    : const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(100)),
              child: Text('$badgeCount', style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: isActive
                    ? Colors.white
                    : Colors.white))),
        ]),
      ),
    );
  }

  Widget _buildAdminProfile(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (ctx, admin, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0x20FFFFFF)))),
        child: Row(children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF1A56DB),
            backgroundImage: admin.photoUrl != null
                ? NetworkImage(admin.photoUrl!) : null,
            child: admin.photoUrl == null
                ? Text(
                    (admin.nomAdmin?.isNotEmpty == true
                      ? admin.nomAdmin![0] : 'A').toUpperCase(),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(admin.nomAdmin ?? 'Administrateur',
              style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: Colors.white),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('Super Admin', style: GoogleFonts.inter(
              fontSize: 10, color: const Color(0xFF64748B))),
          ])),
          // Bouton déconnexion
          GestureDetector(
            onTap: () {
              context.read<AuthProvider>().logout();
              context.go('/connexion');
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.logout_rounded,
                color: Color(0xFFEF4444), size: 14))),
        ]),
      ),
    );
  }

  int? _getBadge(BuildContext context, String type) {
    final admin = context.watch<AdminProvider>();
    switch (type) {
      case 'offres':       return admin.nbOffresEnAttente > 0 ? admin.nbOffresEnAttente : null;
      case 'signalements': return admin.nbSignalementsUrgents > 0 ? admin.nbSignalementsUrgents : null;
      default:             return null;
    }
  }
}
```

---

## 3. Topbar Admin — Design amélioré

```dart
// frontend/lib/screens/admin/admin_topbar.dart
// Topbar moderne avec fond blanc, shadow douce

class AdminTopbar extends StatelessWidget implements PreferredSizeWidget {
  final String pageTitle;
  const AdminTopbar({super.key, required this.pageTitle});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [BoxShadow(
          color: Color(0x08000000), blurRadius: 8,
          offset: Offset(0, 2))]),
      child: Row(children: [

        // Titre de la page
        Expanded(child: Text(pageTitle, style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A)))),

        // Barre de recherche rapide
        GestureDetector(
          onTap: () => context.push('/admin/recherche'),
          child: Container(
            width: 220,
            padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(children: [
              const Icon(Icons.search_rounded,
                color: Color(0xFF94A3B8), size: 16),
              const SizedBox(width: 8),
              Text('Recherche globale...',
                style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFFCBD5E1))),
            ]),
          )),
        const SizedBox(width: 12),

        // Bouton notifications
        Consumer<AdminProvider>(
          builder: (ctx, admin, _) => Stack(children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                color: Color(0xFF64748B), size: 22),
              onPressed: () =>
                context.push('/admin/notifications')),
            if ((admin.nbNotificationsNonLues ?? 0) > 0)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle),
                  child: Center(child: Text(
                    '${admin.nbNotificationsNonLues}',
                    style: GoogleFonts.inter(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      color: Colors.white))))),
          ]),
        ),
        const SizedBox(width: 4),

        // Avatar admin
        Consumer<AdminProvider>(
          builder: (ctx, admin, _) => GestureDetector(
            onTap: () => context.push('/admin/profil'),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1A56DB).withOpacity(0.3),
                  width: 2)),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF1A56DB),
                backgroundImage: admin.photoUrl != null
                    ? NetworkImage(admin.photoUrl!) : null,
                child: admin.photoUrl == null
                    ? Text(
                        (admin.nomAdmin?.isNotEmpty == true
                          ? admin.nomAdmin![0] : 'A').toUpperCase(),
                        style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w700))
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Mode thème
        Consumer<ThemeProvider>(
          builder: (ctx, tp, _) => IconButton(
            icon: Icon(
              tp.isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_outlined,
              color: const Color(0xFF64748B), size: 20),
            onPressed: () => tp.toggleTheme())),
      ]),
    );
  }
}
```

---

## 4. Table Utilisateurs

### 4.1 Fix colonnes ville et date vides

```javascript
// Dans backend/src/routes/admin/utilisateurs.routes.js
// Vérifier que la query inclut adresse et date_creation

const { data, count, error } = await supabase
  .from('utilisateurs')
  .select(`
    id,
    nom,
    email,
    role,
    est_actif,
    est_valide,
    adresse,          ← S'assurer que ce champ est sélectionné
    date_creation,    ← S'assurer que ce champ est sélectionné
    derniere_connexion,
    photo_url,
    telephone
  `, { count: 'exact' })
  .order('date_creation', { ascending: false })
  .range(offset, offset + parseInt(limite) - 1);
```

### 4.2 Flutter — Table utilisateurs améliorée

```dart
// Dans admin/pages/utilisateurs_page.dart
// Remplacer le DataTable par une liste de Cards modernes

class _UtilisateursPageState extends State<UtilisateursPage> {

  @override
  Widget build(BuildContext context) {
    return Column(children: [

      // ── Header ──────────────────────────────────────
      Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        color: Colors.white,
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Utilisateurs', style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A))),
            Text('${_total} utilisateurs inscrits',
              style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF64748B))),
          ])),
          // Export
          OutlinedButton.icon(
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('Exporter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8))),
            onPressed: _exportCSV),
        ]),
      ),

      // ── Stats rapides ────────────────────────────────
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Row(children: [
          _StatChip('Total', '$_total', const Color(0xFF1A56DB)),
          _StatChip('Candidats', '$_nbCandidats', const Color(0xFF10B981)),
          _StatChip('Recruteurs', '$_nbRecruteurs', const Color(0xFF8B5CF6)),
          _StatChip('Actifs', '$_nbActifs', const Color(0xFF10B981)),
          _StatChip('Bloqués', '$_nbBloques', const Color(0xFFEF4444)),
        ]),
      ),
      const Divider(height: 1, color: Color(0xFFE2E8F0)),

      // ── Filtres + Recherche ──────────────────────────
      Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        color: Colors.white,
        child: Row(children: [
          // Recherche
          Expanded(child: TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un utilisateur...',
              hintStyle: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFFCBD5E1)),
              prefixIcon: const Icon(Icons.search_rounded,
                size: 18, color: Color(0xFF94A3B8)),
              filled: true, fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0))),
            ),
            onChanged: (v) => _onSearch(v),
          )),
          const SizedBox(width: 10),
          // Filtre rôle
          _RoleDropdown(
            value: _filtreRole,
            onChanged: (v) => setState(() { _filtreRole = v; _load(); })),
          const SizedBox(width: 10),
          // Filtre statut
          _StatutDropdown(
            value: _filtreStatut,
            onChanged: (v) => setState(() { _filtreStatut = v; _load(); })),
        ]),
      ),
      const Divider(height: 1, color: Color(0xFFE2E8F0)),

      // ── Table ────────────────────────────────────────
      Expanded(child: _isLoading
        ? const Center(child: CircularProgressIndicator(
            color: Color(0xFF1A56DB)))
        : _users.isEmpty
            ? _buildEmpty()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(children: [

                  // En-têtes de colonnes
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(10))),
                    child: Row(children: [
                      Expanded(flex: 3, child: Text('Utilisateur',
                        style: GoogleFonts.inter(fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151)))),
                      Expanded(flex: 2, child: Text('Email',
                        style: GoogleFonts.inter(fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151)))),
                      Expanded(flex: 1, child: Text('Rôle',
                        style: GoogleFonts.inter(fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151)))),
                      Expanded(flex: 1, child: Text('Statut',
                        style: GoogleFonts.inter(fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151)))),
                      Expanded(flex: 2, child: Text('Ville',
                        style: GoogleFonts.inter(fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151)))),
                      Expanded(flex: 2, child: Text('Inscription',
                        style: GoogleFonts.inter(fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151)))),
                      SizedBox(width: 80,
                        child: Text('Actions',
                          style: GoogleFonts.inter(fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF374151)),
                          textAlign: TextAlign.center)),
                    ]),
                  ),

                  // Rows
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFFE2E8F0)),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(10))),
                    child: Column(
                      children: _users.asMap().entries.map((e) =>
                        _UserRow(
                          user: e.value,
                          isEven: e.key.isEven,
                          onAction: _handleAction,
                          onVoirProfil: () => _voirProfil(e.value),
                        )
                      ).toList(),
                    ),
                  ),
                ]),
              )),
    ]);
  }
}

class _UserRow extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isEven;
  final Function(String, String) onAction;
  final VoidCallback onVoirProfil;
  const _UserRow({
    required this.user, required this.isEven,
    required this.onAction, required this.onVoirProfil,
  });

  @override
  Widget build(BuildContext context) {
    final nom    = user['nom']   as String? ?? '';
    final email  = user['email'] as String? ?? '';
    final role   = user['role']  as String? ?? '';
    final actif  = user['est_actif'] == true;
    final valide = user['est_valide'] == true;
    final photo  = user['photo_url'] as String?;
    // ← Récupérer ville et date depuis la BDD
    final ville  = user['adresse'] as String? ?? '—';
    final dateC  = user['date_creation'] as String?;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isEven
            ? Colors.white
            : const Color(0xFFFAFAFA),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(children: [

        // Utilisateur (avatar + nom)
        Expanded(flex: 3, child: Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _roleColor(role).withOpacity(0.15),
            backgroundImage: photo != null
                ? NetworkImage(photo) : null,
            child: photo == null
                ? Text(nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: _roleColor(role)))
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(nom,
            style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A)),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
        ])),

        // Email
        Expanded(flex: 2, child: Text(email,
          style: GoogleFonts.inter(
            fontSize: 12, color: const Color(0xFF64748B)),
          maxLines: 1, overflow: TextOverflow.ellipsis)),

        // Rôle
        Expanded(flex: 1, child: _RoleBadge(role: role)),

        // Statut
        Expanded(flex: 1, child: _StatutBadge(
          actif: actif, valide: valide)),

        // Ville ← MAINTENANT AFFICHÉE
        Expanded(flex: 2, child: Text(
          ville.isNotEmpty && ville != '—'
              ? ville.split(',').first.trim()
              : '—',
          style: GoogleFonts.inter(
            fontSize: 12, color: const Color(0xFF64748B)),
          maxLines: 1, overflow: TextOverflow.ellipsis)),

        // Date inscription ← MAINTENANT AFFICHÉE
        Expanded(flex: 2, child: Text(
          dateC != null ? _formatDate(dateC) : '—',
          style: GoogleFonts.inter(
            fontSize: 12, color: const Color(0xFF64748B)))),

        // Actions
        SizedBox(width: 80, child: Row(
          mainAxisAlignment: MainAxisAlignment.center, children: [
          // Voir profil
          _ActionIcon(
            Icons.visibility_outlined,
            const Color(0xFF1A56DB),
            onVoirProfil),
          // Menu actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
              size: 16, color: Color(0xFF94A3B8)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
            itemBuilder: (_) => [
              if (!actif)
                _popItem('activer', Icons.check_circle_outline,
                  'Activer', const Color(0xFF10B981))
              else
                _popItem('bloquer', Icons.block_rounded,
                  'Bloquer', const Color(0xFFF59E0B)),
              if (!valide)
                _popItem('valider', Icons.verified_outlined,
                  'Valider', const Color(0xFF1A56DB)),
              _popItem('supprimer', Icons.delete_outline_rounded,
                'Supprimer', const Color(0xFFEF4444)),
            ],
            onSelected: (action) =>
              onAction(action, user['id']),
          ),
        ])),
      ]),
    );
  }

  PopupMenuItem<String> _popItem(
    String val, IconData icon, String label, Color color,
  ) => PopupMenuItem(
    value: val,
    child: Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Text(label, style: GoogleFonts.inter(
        fontSize: 13, color: color)),
    ]));

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':     return const Color(0xFF8B5CF6);
      case 'entreprise': return const Color(0xFF1A56DB);
      default:          return const Color(0xFF10B981);
    }
  }

  String _formatDate(String d) {
    try {
      final dt = DateTime.parse(d).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
             '${dt.month.toString().padLeft(2, '0')}/'
             '${dt.year}';
    } catch (_) { return '—'; }
  }
}
```

---

## 5. Page Détail Utilisateur

### Correspondance implémentation

| Élément | Détail |
|--------|--------|
| **Fichier** | `frontend/lib/screens/admin/pages/user_detail_page.dart` |
| **Widget** | `UserDetailPage` — **StatefulWidget** ; prop `userId` ; chargement via `AdminService.getUtilisateur` |
| **Bannière** | Dégradé selon rôle (`admin` / `entreprise` / `chercheur`) ; retour + **actions rapides** dans la bannière (`SingleChildScrollView` horizontal si besoin) : Valider (si non validé), Activer / Bloquer, Supprimer |
| **Avatar** | Chevauchement sous la bannière, bordure blanche |
| **Corps** | Nom, badges rôle / statut ; **grille d’infos** (email, téléphone, ville ou adresse, inscrit le, dernière connexion, validé) |
| **Blocage** | Bloc dédié si `raison_blocage` est renseigné |
| **Données rôle** | Candidat / entreprise : lecture API (`chercheurs_emploi`, `entreprises`, listes associées) — pas seulement `user['chercheur']` |

Le bloc Dart ci-dessous reste une **référence de maquette** ; la structure réelle inclut chargement async, menus d’actions et colonnes droite (cartes actions, etc.).

```dart
// Page affichée quand on clique "Voir le profil complet"
// Design extraordinaire avec sections colorées

class UserDetailPage extends StatelessWidget {
  final Map<String, dynamic> user;
  const UserDetailPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final nom    = user['nom']    as String? ?? '';
    final email  = user['email'] as String? ?? '';
    final role   = user['role']   as String? ?? '';
    final photo  = user['photo_url'] as String?;
    final ville  = user['adresse'] as String? ?? '';
    final tel    = user['telephone'] as String? ?? '';
    final actif  = user['est_actif'] == true;
    final valide = user['est_valide'] == true;
    final dateC  = user['date_creation'] as String?;
    final dateCo = user['derniere_connexion'] as String?;

    final roleColor = role == 'admin'
        ? const Color(0xFF8B5CF6)
        : role == 'entreprise'
            ? const Color(0xFF1A56DB)
            : const Color(0xFF10B981);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(children: [

          // ── Bannière + Avatar ─────────────────────────
          Stack(children: [
            // Bannière dégradée selon le rôle
            Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    roleColor,
                    roleColor.withOpacity(0.6),
                  ]),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white),
                    onPressed: () => Navigator.pop(context)),
                  const Spacer(),
                  // Actions rapides
                  if (!actif)
                    _TopAction(
                      Icons.check_circle_outline, 'Activer',
                      Colors.white, () {}),
                  if (actif)
                    _TopAction(
                      Icons.block_rounded, 'Bloquer',
                      Colors.white, () {}),
                  const SizedBox(width: 8),
                  _TopAction(
                    Icons.delete_outline_rounded, 'Supprimer',
                    Colors.white.withOpacity(0.8), () {}),
                ]),
              ),
            ),

            // Avatar en bas de la bannière
            Positioned(
              bottom: -40, left: 32,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [BoxShadow(
                    color: Color(0x20000000), blurRadius: 16,
                    offset: Offset(0, 4))]),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: roleColor.withOpacity(0.1),
                  backgroundImage: photo != null
                      ? NetworkImage(photo) : null,
                  child: photo == null
                      ? Text(nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                          style: GoogleFonts.poppins(
                            fontSize: 36, fontWeight: FontWeight.w800,
                            color: roleColor))
                      : null,
                ),
              )),
          ]),

          // ── Infos principales ─────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 52, 32, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(nom, style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Row(children: [
                    _RoleBadgeLarge(role: role),
                    const SizedBox(width: 8),
                    _StatusPill(actif: actif, valide: valide),
                  ]),
                ])),
              ]),
              const SizedBox(height: 24),

              // Cards infos
              _InfoGrid(infos: [
                _InfoItem(Icons.email_outlined, 'Email', email),
                _InfoItem(Icons.phone_outlined, 'Téléphone',
                  tel.isNotEmpty ? tel : '—'),
                _InfoItem(Icons.location_on_outlined, 'Ville',
                  ville.isNotEmpty ? ville : '—'),
                _InfoItem(Icons.calendar_today_outlined, 'Inscrit le',
                  dateC != null ? _formatDate(dateC) : '—'),
                _InfoItem(Icons.access_time_rounded,
                  'Dernière connexion',
                  dateCo != null ? _formatDate(dateCo) : 'Jamais'),
                _InfoItem(Icons.verified_outlined, 'Validé',
                  valide ? 'Oui ✅' : 'Non ❌'),
              ]),

              // Données spécifiques au rôle
              const SizedBox(height: 20),
              if (role == 'chercheur')
                _buildChercheurSection(context)
              else if (role == 'entreprise')
                _buildEntrepriseSection(context),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildChercheurSection(BuildContext context) =>
    _SectionCard(
      titre: '👤 Profil candidat',
      couleur: const Color(0xFF10B981),
      children: [
        // Données de chercheurs_emploi si disponibles
        _InfoRow('Disponibilité',
          user['chercheur']?['disponibilite'] ?? '—'),
        _InfoRow('Niveau d\'étude',
          user['chercheur']?['niveau_etude'] ?? '—'),
        _InfoRow('CV uploadé',
          user['chercheur']?['cv'] != null ? 'Oui ✅' : 'Non'),
        _InfoRow('Candidatures',
          '${user['chercheur']?['nb_candidatures'] ?? 0}'),
      ]);

  Widget _buildEntrepriseSection(BuildContext context) =>
    _SectionCard(
      titre: '🏢 Profil entreprise',
      couleur: const Color(0xFF1A56DB),
      children: [
        _InfoRow('Entreprise',
          user['entreprise']?['nom_entreprise'] ?? '—'),
        _InfoRow('Secteur',
          user['entreprise']?['secteur_activite'] ?? '—'),
        _InfoRow('Site web',
          user['entreprise']?['site_web'] ?? '—'),
        _InfoRow('Offres publiées',
          '${user['entreprise']?['nb_offres'] ?? 0}'),
      ]);

  String _formatDate(String d) {
    try {
      final dt = DateTime.parse(d).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return '—'; }
  }
}

// Widgets helpers

class _InfoGrid extends StatelessWidget {
  final List<_InfoItem> infos;
  const _InfoGrid({required this.infos});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (ctx, c) => GridView.count(
      crossAxisCount: c.maxWidth > 600 ? 3 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: infos.map((info) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(children: [
            Icon(info.icon, size: 14,
              color: const Color(0xFF94A3B8)),
            const SizedBox(width: 6),
            Text(info.label, style: GoogleFonts.inter(
              fontSize: 11, color: const Color(0xFF94A3B8))),
          ]),
          const SizedBox(height: 4),
          Text(info.value, style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A)),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      )).toList(),
    ),
  );
}

class _InfoItem {
  final IconData icon; final String label, value;
  const _InfoItem(this.icon, this.label, this.value);
}

class _SectionCard extends StatelessWidget {
  final String titre; final Color couleur;
  final List<Widget> children;
  const _SectionCard({required this.titre,
    required this.couleur, required this.children});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titre, style: GoogleFonts.poppins(
        fontSize: 15, fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A))),
      const SizedBox(height: 12),
      ...children,
    ]),
  );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Text(label, style: GoogleFonts.inter(
        fontSize: 13, color: const Color(0xFF64748B))),
      const Spacer(),
      Text(value, style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w500,
        color: const Color(0xFF0F172A))),
    ]),
  );
}
```

---

## 6. Page Détails Offre Admin

### Correspondance implémentation

| Élément | Détail |
|--------|--------|
| **Fichier** | `frontend/lib/screens/admin/admin_offre_detail_screen.dart` |
| **Widget** | `AdminOffreDetailScreen` — **StatefulWidget** ; prop `offreId` ; `AdminService.getOffreAdmin` puis rechargement après actions |
| **Statut** | Normalisation interne : `publiee`, `en_attente`, `refusee`, `expiree`, etc. (synonymes API gérés : `publiée`, `active`, `brouillon`, `suspendue`…) |
| **AppBar** | **Valider** / **Refuser** visibles si statut normalisé = en attente ; `patchOffreAdmin` (`action: valider` ou `refuser` + motif en dialog) |
| **En-tête** | Carte : badges statut + vedette, entreprise (logo / nom), tags (lieu, contrat, domaine, salaire, vues, candidatures), dates, encart **motif de refus** si refusée |
| **Corps** | Sections description, exigences, compétences en **chips** |

Le bloc Dart ci-dessous illustre l’intention UX ; les noms de classe et le flux réseau sont ceux du fichier ci-dessus.

```dart
// Page détails offre dans l'espace admin
// Design extraordinaire

class OffreDetailAdminPage extends StatelessWidget {
  final Map<String, dynamic> offre;
  const OffreDetailAdminPage({super.key, required this.offre});

  @override
  Widget build(BuildContext context) {
    final titre    = offre['titre']       as String? ?? '';
    final statut   = offre['statut']      as String? ?? '';
    final desc     = offre['description'] as String? ?? '';
    final exig     = offre['exigences']   as String? ?? '';
    final loc      = offre['localisation'] as String? ?? '';
    final contrat  = offre['type_contrat'] as String? ?? '';
    final domaine  = offre['domaine']     as String? ?? '';
    final nbVues   = offre['nb_vues']     as int?    ?? 0;
    final nbCands  = offre['nb_candidatures'] as int? ?? 0;
    final dateP    = offre['date_publication'] as String?;
    final dateLim  = offre['date_limite'] as String?;
    final sMin     = offre['salaire_min'] as int?;
    final sMax     = offre['salaire_max'] as int?;
    final devise   = offre['devise']      as String? ?? 'GNF';
    final raison   = offre['raison_refus'] as String?;
    final entreprise = offre['entreprise'] as Map<String, dynamic>? ?? {};
    final comps    = (offre['competences_requises'] as List?)
        ?.cast<String>() ?? [];

    Color statutColor; IconData statutIcon; String statutLabel;
    switch (statut) {
      case 'publiee':
        statutColor = const Color(0xFF10B981);
        statutIcon  = Icons.check_circle_rounded;
        statutLabel = 'Publiée';
        break;
      case 'en_attente':
        statutColor = const Color(0xFFF59E0B);
        statutIcon  = Icons.hourglass_empty_rounded;
        statutLabel = 'En attente de validation';
        break;
      case 'refusee':
        statutColor = const Color(0xFFEF4444);
        statutIcon  = Icons.cancel_rounded;
        statutLabel = 'Refusée';
        break;
      default:
        statutColor = const Color(0xFF94A3B8);
        statutIcon  = Icons.circle_outlined;
        statutLabel = statut;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0, backgroundColor: Colors.white,
        title: Text('Détails de l\'offre',
          style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A))),
        iconTheme: const IconThemeData(
          color: Color(0xFF64748B)),
        actions: [
          // Valider
          if (statut == 'en_attente')
            TextButton.icon(
              icon: const Icon(Icons.check_circle_outline,
                color: Color(0xFF10B981), size: 16),
              label: Text('Valider', style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF10B981),
                fontWeight: FontWeight.w600)),
              onPressed: () => _valider(context)),
          // Refuser
          if (statut == 'en_attente')
            TextButton.icon(
              icon: const Icon(Icons.cancel_outlined,
                color: Color(0xFFEF4444), size: 16),
              label: Text('Refuser', style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFFEF4444),
                fontWeight: FontWeight.w600)),
              onPressed: () => _refuser(context)),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Header offre ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: statutColor.withOpacity(0.3)),
              boxShadow: const [BoxShadow(
                color: Color(0x05000000), blurRadius: 10,
                offset: Offset(0, 2))]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Statut + vedette
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: statutColor.withOpacity(0.3))),
                  child: Row(children: [
                    Icon(statutIcon, size: 13, color: statutColor),
                    const SizedBox(width: 5),
                    Text(statutLabel, style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: statutColor)),
                  ])),
                if (offre['en_vedette'] == true) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(100)),
                    child: Row(children: [
                      const Icon(Icons.star_rounded,
                        size: 12, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text('En vedette', style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: const Color(0xFF92400E))),
                    ])),
                ],
              ]),
              const SizedBox(height: 14),

              // Titre
              Text(titre, style: GoogleFonts.poppins(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A))),
              const SizedBox(height: 10),

              // Entreprise
              Row(children: [
                if (entreprise['logo_url'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      entreprise['logo_url'],
                      width: 28, height: 28, fit: BoxFit.cover)),
                const SizedBox(width: 8),
                Text(entreprise['nom_entreprise'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A56DB))),
              ]),
              const SizedBox(height: 14),

              // Tags infos
              Wrap(spacing: 8, runSpacing: 8, children: [
                _InfoTag(Icons.location_on_outlined, loc),
                _InfoTag(Icons.work_outline_rounded, contrat),
                if (domaine.isNotEmpty)
                  _InfoTag(Icons.category_outlined, domaine),
                if (sMin != null)
                  _InfoTag(Icons.payments_outlined,
                    '${_fmt(sMin)} - ${_fmt(sMax ?? 0)} $devise'),
                _InfoTag(Icons.visibility_outlined, '$nbVues vues'),
                _InfoTag(Icons.people_outline_rounded,
                  '$nbCands candidats'),
              ]),

              if (dateP != null || dateLim != null) ...[
                const SizedBox(height: 12),
                Row(children: [
                  if (dateP != null)
                    Text('Publié le ${_formatDate(dateP)}',
                      style: GoogleFonts.inter(
                        fontSize: 12, color: const Color(0xFF94A3B8))),
                  if (dateLim != null) ...[
                    const SizedBox(width: 16),
                    Text('Expire le ${_formatDate(dateLim)}',
                      style: GoogleFonts.inter(
                        fontSize: 12, color: const Color(0xFF94A3B8))),
                  ],
                ]),
              ],

              // Motif refus si applicable
              if (statut == 'refusee' && raison != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded,
                      color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'Motif du refus : $raison',
                      style: GoogleFonts.inter(
                        fontSize: 12, color: const Color(0xFF991B1B)))),
                  ])),
              ],
            ]),
          ),
          const SizedBox(height: 20),

          // ── Description ─────────────────────────────────
          _DetailSection(
            titre: '📋 Description du poste',
            couleur: const Color(0xFF1A56DB),
            child: Text(desc, style: GoogleFonts.inter(
              fontSize: 14, color: const Color(0xFF374151),
              height: 1.6))),
          const SizedBox(height: 14),

          // ── Exigences ────────────────────────────────────
          if (exig.isNotEmpty) ...[
            _DetailSection(
              titre: '✅ Exigences & Profil recherché',
              couleur: const Color(0xFF10B981),
              child: Text(exig, style: GoogleFonts.inter(
                fontSize: 14, color: const Color(0xFF374151),
                height: 1.6))),
            const SizedBox(height: 14),
          ],

          // ── Compétences requises ─────────────────────────
          if (comps.isNotEmpty)
            _DetailSection(
              titre: '🔧 Compétences requises',
              couleur: const Color(0xFF8B5CF6),
              child: Wrap(spacing: 8, runSpacing: 8,
                children: comps.map((c) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: const Color(0xFFDDD6FE))),
                  child: Text(c, style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w500,
                    color: const Color(0xFF6D28D9))),
                )).toList())),
        ]),
      ),
    );
  }

  void _valider(BuildContext context) {/* appeler l'API admin */}
  void _refuser(BuildContext context) {/* dialog motif */}

  String _fmt(int n) {
    if (n >= 1000000) return '${(n/1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n/1000).toStringAsFixed(0)}K';
    return '$n';
  }

  String _formatDate(String d) {
    try {
      final dt = DateTime.parse(d);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return d; }
  }
}

class _DetailSection extends StatelessWidget {
  final String titre; final Color couleur; final Widget child;
  const _DetailSection({required this.titre,
    required this.couleur, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 4, height: 18,
          decoration: BoxDecoration(
            color: couleur,
            borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(titre, style: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A))),
      ]),
      const SizedBox(height: 14),
      child,
    ]),
  );
}

class _InfoTag extends StatelessWidget {
  final IconData icon; final String text;
  const _InfoTag(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: const Color(0xFF64748B)),
      const SizedBox(width: 5),
      Text(text, style: GoogleFonts.inter(
        fontSize: 12, color: const Color(0xFF374151))),
    ]));
}
```

---

## 7. Responsivité Mobile Admin

### Correspondance implémentation

| Élément | Détail |
|--------|--------|
| **Shell** | `frontend/lib/screens/admin/admin_shell_screen.dart` — **StatefulWidget** `AdminShellScreen` (pas GoRouter dans ce fichier : navigation par `_currentRoute`) |
| **Seuil mobile** | **Largeur &lt; 900 px** : `Drawer` + `AdminSidebar(isDrawer: true)` ; menu hamburger via `AdminTopBar` |
| **Tablette** | **900 px ≤ largeur &lt; 1200 px** : sidebar **rétractable** (`useCollapsedSidebar`) |
| **Desktop** | **≥ 1200 px** : sidebar étendue par défaut (toggle collapse manuel) |
| **Tableaux** | `admin_users_screen.dart` et `admin_jobs_screen.dart` : `LayoutBuilder` → `SingleChildScrollView(scrollDirection: horizontal)` → `ConstrainedBox(minWidth: maxWidth parent ou 900)` → `DataTable` |

```dart
// Appliquer dans TOUS les fichiers admin
// Stratégie : drawer sur mobile, sidebar sur desktop
// RÉEL : AdminShellScreen — isMobile = width < 900, isTablet = 900..1200

// Dans admin_shell.dart ou layout principal :

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile) {
      // ── MOBILE : Drawer ────────────────────────────
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0, backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
          title: Text('Admin', style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A))),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                color: Color(0xFF64748B)),
              onPressed: () => context.push('/admin/notifications')),
          ],
        ),
        drawer: Drawer(
          child: AdminSidebar(
            currentRoute: GoRouterState.of(context).uri.path)),
        body: child,
      );
    }

    // ── DESKTOP : Layout avec sidebar ──────────────
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(children: [
        // Sidebar fixe
        SizedBox(
          width: 256,
          child: AdminSidebar(
            currentRoute: GoRouterState.of(context).uri.path)),
        // Contenu
        Expanded(
          child: Column(children: [
            AdminTopbar(pageTitle: _getPageTitle(context)),
            Expanded(child: child),
          ])),
      ]),
    );
  }
}

// Fix débordements horizontaux sur mobile (implémenté utilisateurs + offres) :
LayoutBuilder(
  builder: (context, tableBc) {
    final minW = tableBc.hasBoundedWidth && tableBc.maxWidth > 0
        ? tableBc.maxWidth
        : 900.0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minW),
        child: DataTable(/* ... */),
      ),
    );
  },
)

// Pour les Cards et layouts en Row sur mobile :
// Remplacer Row → Wrap pour éviter les débordements :
// AVANT ❌
Row(children: [Card1(), Card2(), Card3(), Card4()])
// APRÈS ✅
Wrap(
  spacing: 10, runSpacing: 10,
  children: [Card1(), Card2(), Card3(), Card4()])
```

---

## 8. Recherche Globale Admin

### Correspondance implémentation

| Élément | Détail |
|--------|--------|
| **Page** | `frontend/lib/screens/admin/pages/admin_recherche_globale_page.dart` — `AdminRechercheGlobalePage` |
| **Service** | `AdminService().rechercheGlobale(query)` (auth comme les autres appels admin) |
| **API** | `GET /api/admin/recherche?q=` — réponse typique : `{ data: { resultats: [ ... ] } }` |
| **Forme des résultats** | Liste **plate** : chaque entrée a un champ **`type`** : `utilisateur` \| `offre` \| `entreprise` (+ champs `id`, `titre`, `sous_titre`, etc. selon le backend) — **pas** trois clés séparées `utilisateurs` / `offres` / `entreprises` au premier niveau de `data` |
| **UI** | Hero dégradé sombre, champ de recherche, **debounce ~400 ms**, états accueil / chargement / vide / résultats ; groupement **côté client** par `type` |
| **Navigation** | Clic sur une ligne : `AdminSearchDelegate.openResult(context, map)` (réutilise la même logique que la recherche overlay) |
| **Intégration shell** | Route interne **`/admin/recherche`** dans `admin_shell_screen.dart` ; entrée sidebar **CONFIGURATION** ; `AdminTopBar(onOpenFullSearch: …)` ouvre cette page au lieu de `showSearch` seul |

### Comportement attendu (résumé)

- Minimum **2 caractères** avant appel réseau ; en dessous : liste vide + message d’aide si pertinent.
- **Suggestions** (chips) sur l’écran d’accueil pour préremplir la requête.
- **Aucun résultat** : état dédié avec la requête affichée.

### Extrait indicatif (forme des données)

```dart
// Après rechercheGlobale(q) — pseudo-code
final data = body['data'];
final raw = (data is Map ? data['resultats'] : null) as List<dynamic>? ?? [];
final list = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

final users = list.where((r) => r['type'] == 'utilisateur').toList();
final offres = list.where((r) => r['type'] == 'offre').toList();
final entrs = list.where((r) => r['type'] == 'entreprise').toList();
```

L’overlay **`AdminSearchDelegate`** (`admin_search_delegate.dart`) reste disponible pour une recherche rapide depuis la topbar lorsque `onOpenFullSearch` n’est pas utilisé.

---

## 9. Critères d'Acceptation

### ✅ Corrections bugs
- [ ] Overflow "Bottom overflowed by 9px" corrigé dans la page offres
- [ ] Aucun débordement `over the web by XXX pixels` sur mobile
- [ ] Colonnes "Ville" et "Date inscription" affichent les vraies données

### ✅ Sidebar Admin
- [ ] Fond : dégradé bleu nuit (pas noir)
- [ ] Items actifs : fond bleu #1A56DB avec texte blanc
- [ ] Hover : feedback visuel sur survol
- [ ] Badges rouges sur Offres en attente + Signalements urgents
- [ ] Logo/nom en haut + profil admin en bas
- [ ] Sections séparées par labels GESTION / COMMUNICATION / SYSTÈME

### ✅ Topbar Admin
- [ ] Fond blanc avec bordure douce
- [ ] Raccourci recherche globale au centre
- [ ] Badge rouge sur le bouton notifications
- [ ] Avatar admin cliquable → page profil
- [ ] Toggle thème clair/sombre

### ✅ Table Utilisateurs
- [ ] Colonne Ville = `adresse` depuis la BDD
- [ ] Colonne Inscription = `date_creation` formatée DD/MM/YYYY
- [ ] Alternance couleurs lignes (blanc / gris très léger)
- [ ] Stats chips : Total / Candidats / Recruteurs / Actifs / Bloqués

### ✅ Page Détail Utilisateur
- [x] Bannière colorée selon le rôle
- [x] Avatar centré sur la bannière
- [x] Grid d'infos : email, tel, ville, dates
- [x] Section spécifique : candidat OU entreprise
- [x] Boutons action en haut à droite

### ✅ Page Détail Offre
- [x] Badge statut coloré (vert/orange/rouge)
- [x] Toutes les infos : titre, entreprise, localisation, contrat
- [x] Section description avec barre colorée gauche
- [x] Section exigences
- [x] Chips compétences requises
- [x] Boutons Valider/Refuser si statut en_attente

### ✅ Mobile Admin
- [x] Sidebar remplacée par Drawer sur mobile (<900px)
- [x] Barre supérieure (`AdminTopBar`) avec menu hamburger sur mobile
- [x] Tables avec scroll horizontal + `ConstrainedBox` (utilisateurs, offres)
- [ ] Row → Wrap pour éviter les débordements (à appliquer au cas par cas sur les autres écrans)

### ✅ Recherche Globale
- [x] Page avec hero section dégradé sombre
- [x] Barre de recherche prominente au centre
- [x] Message "2 caractères minimum" si trop court
- [x] Suggestions rapides sur la page d'accueil
- [x] Résultats groupés par catégorie avec compteurs
- [x] Page "Aucun résultat" élégante

---

*PRD EmploiConnect v7.0 — Admin Design Polish*
*Cursor / Kirsoft AI — Phase 11*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
