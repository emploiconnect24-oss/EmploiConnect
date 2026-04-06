# PRD — EmploiConnect · Connexion Backend Complète — Espace Recruteur
## Product Requirements Document v5.1 — Backend Connect Recruteur
**Stack : Flutter + Node.js/Express + PostgreSQL/Supabase**
**Outil : Cursor / Kirsoft AI**
**Objectif : Remplacer TOUTES les données fictives par de vraies données**
**Statut : Phase 9.1 — Connexion réelle après backend validé**
**Date : Mars 2026**

---

> ### ⚠️ INSTRUCTIONS CRITIQUES POUR CURSOR
>
> Ce PRD remplace TOUTES les données hardcodées/fictives
> de l'espace recruteur par de vraies données venant de l'API.
> Zéro donnée fictive autorisée après ce PRD.
> Implémenter dans l'ordre exact des sections.
> Chaque section = une page ou un composant à connecter.

---

## Table des Matières

1. [RecruteurProvider — Chargement global](#1-recruteurprovider--chargement-global)
2. [Sidebar — Badges dynamiques](#2-sidebar--badges-dynamiques)
3. [Page Vue d'ensemble — Données réelles](#3-page-vue-densemble--données-réelles)
4. [Page Mes Offres — Données réelles](#4-page-mes-offres--données-réelles)
5. [Page Candidatures — Fix + Données réelles](#5-page-candidatures--fix--données-réelles)
6. [Page Recherche Talents — Données réelles](#6-page-recherche-talents--données-réelles)
7. [Page Profil Entreprise — Upload + Données réelles](#7-page-profil-entreprise--upload--données-réelles)
8. [Page Messagerie — Données réelles](#8-page-messagerie--données-réelles)
9. [Page Statistiques — Données réelles](#9-page-statistiques--données-réelles)
10. [Page Notifications — Données réelles](#10-page-notifications--données-réelles)
11. [Page Paramètres Recruteur](#11-page-paramètres-recruteur)
12. [Critères d'Acceptation](#12-critères-dacceptation)

---

## 1. RecruteurProvider — Chargement global

### Créer `frontend/lib/providers/recruteur_provider.dart`

```dart
import 'package:flutter/material.dart';
import '../services/recruteur_service.dart';

class RecruteurProvider extends ChangeNotifier {
  final RecruteurService _svc = RecruteurService();

  // ── Données globales ──────────────────────────────────────
  Map<String, dynamic>? dashboardData;
  Map<String, dynamic>? profil;

  // ── Compteurs sidebar ─────────────────────────────────────
  int nbOffresActives     = 0;
  int nbCandidatures      = 0;
  int nbCandidEnAttente   = 0;
  int nbMessagesNonLus    = 0;
  int nbNotificationsNonLues = 0;

  bool isLoading = false;
  String? error;

  // ── Charger toutes les données au démarrage ───────────────
  Future<void> loadAll(String token) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _svc.getDashboard(token),
        _svc.getProfil(token),
        _svc.getNotifications(token),
      ]);

      final dash    = results[0]['data'] as Map<String, dynamic>? ?? {};
      final profilD = results[1]['data'] as Map<String, dynamic>? ?? {};
      final notifs  = results[2]['data'] as Map<String, dynamic>? ?? {};

      dashboardData = dash;
      profil        = profilD;

      // Mettre à jour les compteurs sidebar
      final stats = dash['stats'] as Map<String, dynamic>? ?? {};
      nbOffresActives      = stats['offres_actives'] ?? 0;
      nbCandidatures       = stats['total_candidatures'] ?? 0;
      nbCandidEnAttente    = stats['candidatures_en_attente'] ?? 0;
      nbMessagesNonLus     = stats['messages_non_lus'] ?? 0;
      nbNotificationsNonLues = notifs['nb_non_lues'] ?? 0;

    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Rafraîchir les compteurs seulement ────────────────────
  Future<void> refreshCounts(String token) async {
    try {
      final dash = await _svc.getDashboard(token);
      final stats = dash['data']?['stats'] as Map<String, dynamic>? ?? {};
      nbOffresActives      = stats['offres_actives'] ?? 0;
      nbCandidatures       = stats['total_candidatures'] ?? 0;
      nbCandidEnAttente    = stats['candidatures_en_attente'] ?? 0;
      nbMessagesNonLus     = stats['messages_non_lus'] ?? 0;
      notifyListeners();
    } catch (_) {}
  }

  // ── Mise à jour ponctuelle ────────────────────────────────
  void updateNbMessages(int n) {
    nbMessagesNonLus = n;
    notifyListeners();
  }

  void updateNbNotifications(int n) {
    nbNotificationsNonLues = n;
    notifyListeners();
  }

  void updateProfil(Map<String, dynamic> data) {
    profil = { ...?profil, ...data };
    notifyListeners();
  }
}
```

### Enregistrer dans `main.dart`

```dart
// Dans MultiProvider, ajouter :
ChangeNotifierProvider(create: (_) => RecruteurProvider()),
```

### Charger dans `recruteur_shell.dart`

```dart
class _RecruteurShellState extends State<RecruteurShell> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token ?? '';
      // Charger toutes les données au démarrage
      context.read<RecruteurProvider>().loadAll(token);
    });
  }
}
```

---

## 2. Sidebar — Badges dynamiques

### Mettre à jour `recruteur_sidebar.dart`

```dart
// Remplacer TOUS les badges hardcodés par des données du Provider

class RecruteurSidebar extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    // Écouter le RecruteurProvider
    final provider = context.watch<RecruteurProvider>();
    final currentRoute = GoRouterState.of(context).uri.path;

    return Container(
      width: 240,
      // ... décoration existante ...
      child: Column(children: [

        // Header entreprise (logo + nom dynamiques)
        _buildCompanyHeader(provider.profil),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(children: [

            _buildSection('PRINCIPAL', [
              _Item('Vue d\'ensemble',
                Icons.dashboard_outlined, Icons.dashboard_rounded,
                '/dashboard-recruteur'),

              _Item('Mes offres',
                Icons.work_outline, Icons.work_rounded,
                '/dashboard-recruteur/offres',
                // Badge = nb offres actives RÉEL
                badge: provider.nbOffresActives > 0
                    ? '${provider.nbOffresActives}' : null,
                badgeColor: const Color(0xFF1A56DB)),

              _Item('Candidatures',
                Icons.people_outline, Icons.people_rounded,
                '/dashboard-recruteur/candidatures',
                // Badge = candidatures en attente RÉEL
                badge: provider.nbCandidEnAttente > 0
                    ? '${provider.nbCandidEnAttente}' : null,
                badgeColor: const Color(0xFF10B981)),

              _Item('Recherche Talents',
                Icons.search_outlined, Icons.search_rounded,
                '/dashboard-recruteur/talents'),

              _Item('Profil entreprise',
                Icons.business_outlined, Icons.business_rounded,
                '/dashboard-recruteur/profil'),
            ]),

            _buildSection('COMMUNICATION', [
              _Item('Messagerie',
                Icons.chat_bubble_outline, Icons.chat_bubble_rounded,
                '/dashboard-recruteur/messages',
                // Badge = messages non lus RÉEL
                badge: provider.nbMessagesNonLus > 0
                    ? '${provider.nbMessagesNonLus}' : null,
                badgeColor: const Color(0xFF1A56DB)),

              _Item('Notifications',
                Icons.notifications_outlined, Icons.notifications_rounded,
                '/dashboard-recruteur/notifications',
                // Badge = notifications non lues RÉEL
                badge: provider.nbNotificationsNonLues > 0
                    ? '${provider.nbNotificationsNonLues}' : null),
            ]),

            _buildSection('ANALYSE', [
              _Item('Statistiques',
                Icons.bar_chart_outlined, Icons.bar_chart_rounded,
                '/dashboard-recruteur/statistiques'),
            ]),

            _buildSection('COMPTE', [
              _Item('Paramètres',
                Icons.settings_outlined, Icons.settings_rounded,
                '/dashboard-recruteur/parametres'),
            ]),
          ]),
        )),

        // CTA Publier une offre
        _buildPublishCTA(context),
        _buildLogoutButton(context),
      ]),
    );
  }

  // Header avec logo et nom dynamiques depuis le profil
  Widget _buildCompanyHeader(Map<String, dynamic>? profil) {
    final logoUrl = profil?['logo_url'] as String? ?? '';
    final nomEntreprise = profil?['nom_entreprise'] as String? ?? 'Mon entreprise';
    final email = profil?['utilisateur']?['email'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
      child: Row(children: [
        // Logo entreprise
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: logoUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    logoUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _initiale(nomEntreprise),
                  ))
              : _initiale(nomEntreprise),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nomEntreprise,
            style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A)),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('Espace Recruteur', style: GoogleFonts.inter(
            fontSize: 11, color: const Color(0xFF64748B))),
        ])),
      ]),
    );
  }

  Widget _initiale(String nom) => Center(child: Text(
    nom.isNotEmpty ? nom[0].toUpperCase() : 'E',
    style: GoogleFonts.poppins(
      fontSize: 18, fontWeight: FontWeight.w700,
      color: const Color(0xFF1A56DB))));
}
```

---

## 3. Page Vue d'ensemble — Données réelles

### Remplacer `recruteur_dashboard_page.dart` entièrement

```dart
class RecruteurDashboardPage extends StatefulWidget {
  const RecruteurDashboardPage({super.key});
  @override
  State<RecruteurDashboardPage> createState() => _RecruteurDashboardPageState();
}

class _RecruteurDashboardPageState extends State<RecruteurDashboardPage> {
  final RecruteurService _svc = RecruteurService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res   = await _svc.getDashboard(token);
      setState(() { _data = res['data']; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(
      child: CircularProgressIndicator(color: Color(0xFF1A56DB)));
    if (_error != null) return _buildError();

    final stats       = _data?['stats'] as Map<String, dynamic>? ?? {};
    final offres      = List<Map<String, dynamic>>.from(
      _data?['offres_actives'] ?? []);
    final candidatures = List<Map<String, dynamic>>.from(
      _data?['candidatures_recentes'] ?? []);
    final urgentes    = List<Map<String, dynamic>>.from(
      _data?['candidatures_urgentes'] ?? []);
    final entreprise  = _data?['entreprise'] as Map<String, dynamic>? ?? {};

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF1A56DB),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Bienvenue ──────────────────────────────────────
          _buildWelcome(entreprise, urgentes),
          const SizedBox(height: 20),

          // ── 4 Stat Cards ───────────────────────────────────
          _buildStatsCards(stats),
          const SizedBox(height: 24),

          // ── Candidatures urgentes ──────────────────────────
          if (urgentes.isNotEmpty) ...[
            _buildUrgentAlert(urgentes),
            const SizedBox(height: 20),
          ],

          // ── Candidatures récentes ──────────────────────────
          _buildRecentCandidatures(candidatures),
          const SizedBox(height: 24),

          // ── Mes offres actives ─────────────────────────────
          _buildActiveOffers(offres),
        ]),
      ),
    );
  }

  Widget _buildWelcome(
    Map<String, dynamic> entreprise,
    List<Map<String, dynamic>> urgentes,
  ) {
    final nom = entreprise['nom'] as String? ?? 'Mon entreprise';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Bonjour' :
                     hour < 18 ? 'Bon après-midi' : 'Bonsoir';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$greeting, $nom 👋',
            style: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A))),
          if (urgentes.isNotEmpty)
            Text(
              '${urgentes.length} candidature(s) en attente depuis +7 jours',
              style: GoogleFonts.inter(
                fontSize: 14, color: const Color(0xFFF59E0B),
                fontWeight: FontWeight.w500)),
        ])),
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: Text('Nouvelle offre', style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8))),
          onPressed: () =>
            context.push('/dashboard-recruteur/offres/nouvelle'),
        ),
      ],
    );
  }

  Widget _buildStatsCards(Map<String, dynamic> stats) {
    final cards = [
      _StatData(
        'Offres actives',
        '${stats['offres_actives'] ?? 0}',
        Icons.work_rounded,
        const Color(0xFF1A56DB), const Color(0xFFEFF6FF)),
      _StatData(
        'Candidatures',
        '${stats['total_candidatures'] ?? 0}',
        Icons.people_rounded,
        const Color(0xFF10B981), const Color(0xFFECFDF5)),
      _StatData(
        'Vues ce mois',
        '${stats['vues_ce_mois'] ?? 0}',
        Icons.visibility_rounded,
        const Color(0xFF8B5CF6), const Color(0xFFF5F3FF)),
      _StatData(
        'Taux réponse',
        '${stats['taux_reponse'] ?? 0}%',
        Icons.star_rounded,
        const Color(0xFFF59E0B), const Color(0xFFFEF3C7)),
    ];

    return LayoutBuilder(builder: (ctx, c) {
      final cols = c.maxWidth < 600 ? 2 : 4;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 14, mainAxisSpacing: 14,
        childAspectRatio: c.maxWidth < 600 ? 1.6 : 2.2,
        children: cards.asMap().entries.map((e) =>
          FadeInUp(
            delay: Duration(milliseconds: e.key * 80),
            child: _StatCard(stat: e.value),
          )
        ).toList(),
      );
    });
  }

  Widget _buildUrgentAlert(List<Map<String, dynamic>> urgentes) =>
    GestureDetector(
      onTap: () => context.push('/dashboard-recruteur/candidatures'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFDE68A))),
        child: Row(children: [
          const Icon(Icons.hourglass_empty_rounded,
            color: Color(0xFFF59E0B), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(
            '${urgentes.length} candidature(s) en attente de réponse depuis plus de 7 jours',
            style: GoogleFonts.inter(
              fontSize: 13, color: const Color(0xFF92400E),
              fontWeight: FontWeight.w500))),
          const Icon(Icons.arrow_forward_ios,
            color: Color(0xFF92400E), size: 14),
        ]),
      ),
    );

  Widget _buildRecentCandidatures(List<Map<String, dynamic>> cands) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Candidatures récentes', style: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A))),
        TextButton(
          onPressed: () =>
            context.push('/dashboard-recruteur/candidatures'),
          child: Text('Voir tout →', style: GoogleFonts.inter(
            fontSize: 13, color: const Color(0xFF1A56DB))),
        ),
      ]),
      const SizedBox(height: 12),
      if (cands.isEmpty)
        _EmptyState(
          icon: Icons.people_outline,
          message: 'Aucune candidature reçue pour le moment',
        )
      else
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            children: cands.map((c) => _CandidatureRow(c: c)).toList()),
        ),
    ]);

  Widget _buildActiveOffers(List<Map<String, dynamic>> offres) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Mes offres actives', style: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A))),
        TextButton(
          onPressed: () =>
            context.push('/dashboard-recruteur/offres'),
          child: Text('Gérer →', style: GoogleFonts.inter(
            fontSize: 13, color: const Color(0xFF1A56DB))),
        ),
      ]),
      const SizedBox(height: 12),
      if (offres.isEmpty)
        _EmptyState(
          icon: Icons.work_outline,
          message: 'Aucune offre active. Publiez votre première offre !',
          actionLabel: 'Publier une offre',
          onAction: () =>
            context.push('/dashboard-recruteur/offres/nouvelle'),
        )
      else
        ...offres.map((o) => _OffreActiveRow(o: o)),
    ]);

  Widget _buildError() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
      const SizedBox(height: 12),
      Text('Erreur de chargement', style: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w600)),
      Text(_error ?? '', style: GoogleFonts.inter(
        fontSize: 13, color: const Color(0xFF64748B))),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
    ]),
  );
}

// ── Widgets helpers ────────────────────────────────────────────

class _CandidatureRow extends StatelessWidget {
  final Map<String, dynamic> c;
  const _CandidatureRow({required this.c});

  @override
  Widget build(BuildContext context) {
    final nom = c['chercheur']?['utilisateur']?['nom'] ?? 'Candidat';
    final offre = c['offre']?['titre'] ?? 'Offre';
    final score = c['score_compatibilite'] as int?;
    final statut = c['statut'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(
          color: Color(0xFFE2E8F0)))),
      child: Row(children: [
        CircleAvatar(
          radius: 18, backgroundColor: const Color(0xFF1A56DB),
          backgroundImage: c['chercheur']?['utilisateur']?['photo_url'] != null
              ? NetworkImage(c['chercheur']['utilisateur']['photo_url'])
              : null,
          child: c['chercheur']?['utilisateur']?['photo_url'] == null
              ? Text(nom[0].toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.bold,
                    fontSize: 13))
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nom, style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A))),
          Text(offre, style: GoogleFonts.inter(
            fontSize: 12, color: const Color(0xFF64748B)),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        if (score != null && score > 0)
          IAScoreBadge(score: score),
        const SizedBox(width: 8),
        _StatusBadgeSmall(statut: statut),
      ]),
    );
  }
}

class _OffreActiveRow extends StatelessWidget {
  final Map<String, dynamic> o;
  const _OffreActiveRow({required this.o});

  @override
  Widget build(BuildContext context) {
    final titre    = o['titre'] as String? ?? 'Offre';
    final nbVues   = o['nb_vues'] as int? ?? 0;
    final nbCands  = o['nb_candidatures'] as int? ?? 0;
    final nonLues  = o['nb_non_lues'] as int? ?? 0;

    return GestureDetector(
      onTap: () => context.push(
        '/dashboard-recruteur/candidatures?offreId=${o['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titre, style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A)),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.visibility_outlined,
                size: 13, color: const Color(0xFF94A3B8)),
              Text(' $nbVues vues', style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFF94A3B8))),
              const SizedBox(width: 12),
              Icon(Icons.people_outline,
                size: 13, color: const Color(0xFF94A3B8)),
              Text(' $nbCands candidatures', style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFF94A3B8))),
              if (nonLues > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(100)),
                  child: Text('$nonLues nouvelles',
                    style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981))),
                ),
              ],
            ]),
          ])),
          const Icon(Icons.arrow_forward_ios,
            size: 14, color: Color(0xFF94A3B8)),
        ]),
      ),
    );
  }
}
```

---

## 4. Page Mes Offres — Données réelles

```dart
class _MesOffresPageState extends State<MesOffresPage>
    with SingleTickerProviderStateMixin {

  final RecruteurService _svc = RecruteurService();
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _offres = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String _selectedStatut = 'all';
  String _recherche = '';

  final _rechercheCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        final statuts = ['all', 'publiee', 'en_attente', 'expiree', 'brouillon'];
        setState(() => _selectedStatut = statuts[_tabCtrl.index]);
        _loadOffres();
      }
    });
    _loadOffres();
  }

  Future<void> _loadOffres() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await _svc.getOffres(
        token,
        statut: _selectedStatut == 'all' ? null : _selectedStatut,
        recherche: _recherche.isNotEmpty ? _recherche : null,
      );
      setState(() {
        _offres = List<Map<String, dynamic>>.from(
          res['data']?['offres'] ?? []);
        _stats  = res['data']?['stats'] as Map<String, dynamic>? ?? {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [

        // En-tête
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mes offres d\'emploi',
              style: GoogleFonts.poppins(
                fontSize: 22, fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A))),
            Text('Gérez toutes vos annonces de recrutement',
              style: GoogleFonts.inter(
                fontSize: 14, color: const Color(0xFF64748B))),
          ]),
          Row(children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.download_outlined, size: 16),
              label: const Text('Exporter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
              onPressed: _exportOffres,
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Publier une offre'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
              onPressed: () =>
                context.push('/dashboard-recruteur/offres/nouvelle'),
            ),
          ]),
        ]),
        const SizedBox(height: 20),

        // Card principale
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(children: [

            // Tabs avec chiffres réels
            TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              labelStyle: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
              labelColor: const Color(0xFF1A56DB),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF1A56DB),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: [
                Tab(text: 'Toutes (${_stats['total'] ?? 0})'),
                Tab(text: 'Actives (${_stats['publiees'] ?? 0})'),
                Tab(text: 'En attente (${_stats['en_attente'] ?? 0})'),
                Tab(text: 'Expirées (${_stats['expirees'] ?? 0})'),
                Tab(text: 'Brouillons (${_stats['brouillons'] ?? 0})'),
              ],
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Barre de recherche
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: _rechercheCtrl,
                  decoration: InputDecoration(
                    hintText: 'Rechercher une offre...',
                    prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF94A3B8), size: 18),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
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
                  onChanged: (v) {
                    _debounce?.cancel();
                    _debounce = Timer(
                      const Duration(milliseconds: 400), () {
                      setState(() => _recherche = v);
                      _loadOffres();
                    });
                  },
                )),
              ]),
            ),

            // Liste offres
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(
                  color: Color(0xFF1A56DB))))
            else if (_offres.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: _EmptyState(
                  icon: Icons.work_outline,
                  message: _selectedStatut == 'all'
                      ? 'Aucune offre publiée. Créez votre première offre !'
                      : 'Aucune offre dans cette catégorie',
                  actionLabel: 'Publier une offre',
                  onAction: () => context.push(
                    '/dashboard-recruteur/offres/nouvelle'),
                ))
            else
              ...(_offres.map((o) => _OffreCard(
                offre: o,
                onRefresh: _loadOffres,
              ))),
          ]),
        ),
      ]),
    );
  }

  Future<void> _exportOffres() async {
    // Télécharger CSV
    final token = context.read<AuthProvider>().token ?? '';
    final url = '${ApiConfig.baseUrl}/api/recruteur/offres/export/csv';
    await DownloadService.downloadCsv(
      url: url, token: token,
      fileName: 'mes_offres.csv', context: context);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _rechercheCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
```

---

## 5. Page Candidatures — Fix + Données réelles

### Fix de l'erreur "offre_id est requis"

```dart
// Le problème : la page Candidatures appelait l'API avec offre_id = null
// ce qui causait l'erreur backend.
// Solution : ne pas envoyer offre_id si non fourni

class _CandidaturesPageState extends State<CandidaturesPage> {
  final RecruteurService _svc = RecruteurService();

  // widget.offreId peut être null → dans ce cas, charger TOUTES les candidatures
  List<Map<String, dynamic>> _candidatures = [];
  Map<String, dynamic> _stats = {};
  Map<String, dynamic>? _kanban;
  bool _isLoading = true;
  bool _isKanbanView = false;
  String? _selectedStatut;

  @override
  void initState() {
    super.initState();
    _loadCandidatures();
  }

  Future<void> _loadCandidatures() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await _svc.getCandidatures(
        token,
        offreId: widget.offreId, // null = toutes les candidatures ✅
        statut:  _selectedStatut,
        vue:     _isKanbanView ? 'kanban' : 'liste',
      );

      final data = res['data'] as Map<String, dynamic>? ?? {};
      setState(() {
        _candidatures = List<Map<String, dynamic>>.from(
          data['candidatures'] ?? []);
        _stats  = data['stats'] as Map<String, dynamic>? ?? {};
        _kanban = data['kanban'] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [

        // En-tête
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Candidatures reçues',
              style: GoogleFonts.poppins(
                fontSize: 22, fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A))),
            // Afficher le filtre si vient d'une offre spécifique
            if (widget.offreId != null)
              Text('Filtrées par offre',
                style: GoogleFonts.inter(
                  fontSize: 14, color: const Color(0xFF1A56DB))),
          ]),
          // Switch vue Liste / Kanban
          Row(children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.download_outlined, size: 16),
              label: const Text('Exporter CSV'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
              onPressed: _exportCandidatures,
            ),
            const SizedBox(width: 10),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.list_rounded),
                  label: Text('Liste')),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.view_kanban_outlined),
                  label: Text('Kanban')),
              ],
              selected: {_isKanbanView},
              onSelectionChanged: (v) {
                setState(() => _isKanbanView = v.first);
                _loadCandidatures();
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact),
            ),
          ]),
        ]),
        const SizedBox(height: 16),

        // Stats chips
        if (!_isLoading)
          _buildStatsChips(_stats),
        const SizedBox(height: 16),

        // Contenu
        if (_isLoading)
          const Center(child: CircularProgressIndicator(
            color: Color(0xFF1A56DB)))
        else if (_isKanbanView && _kanban != null)
          _buildKanban(_kanban!)
        else
          _buildListe(_candidatures),
      ]),
    );
  }

  Widget _buildStatsChips(Map<String, dynamic> stats) => Wrap(
    spacing: 8, runSpacing: 8,
    children: [
      _StatChipFilter(
        'Toutes (${stats['total'] ?? 0})',
        null, _selectedStatut, (v) {
          setState(() => _selectedStatut = v);
          _loadCandidatures();
        }),
      _StatChipFilter(
        'En attente (${stats['en_attente'] ?? 0})',
        'en_attente', _selectedStatut, (v) {
          setState(() => _selectedStatut = v);
          _loadCandidatures();
        }),
      _StatChipFilter(
        'En examen (${stats['en_cours'] ?? 0})',
        'en_cours', _selectedStatut, (v) {
          setState(() => _selectedStatut = v);
          _loadCandidatures();
        }),
      _StatChipFilter(
        'Entretien (${stats['entretien'] ?? 0})',
        'entretien', _selectedStatut, (v) {
          setState(() => _selectedStatut = v);
          _loadCandidatures();
        }),
      _StatChipFilter(
        'Acceptées (${stats['acceptees'] ?? 0})',
        'acceptee', _selectedStatut, (v) {
          setState(() => _selectedStatut = v);
          _loadCandidatures();
        }),
    ],
  );

  Widget _buildListe(List<Map<String, dynamic>> cands) {
    if (cands.isEmpty) return _EmptyState(
      icon: Icons.people_outline,
      message: 'Aucune candidature reçue pour le moment');

    return Column(
      children: cands.map((c) => CandidatureCard(
        candidature: c,
        onAction: (action, {dateEntretien, lienVisio, raisonRefus}) async {
          final token = context.read<AuthProvider>().token ?? '';
          await _svc.actionCandidature(
            token, c['id'], action,
            dateEntretien: dateEntretien,
            lienVisio: lienVisio,
            raisonRefus: raisonRefus,
          );
          _loadCandidatures();
          // Rafraîchir les compteurs sidebar
          context.read<RecruteurProvider>().refreshCounts(token);
        },
      )).toList(),
    );
  }

  Widget _buildKanban(Map<String, dynamic> kanban) =>
    SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KanbanColonne(
            titre: 'Reçues',
            statut: 'en_attente',
            couleur: const Color(0xFF1A56DB),
            candidatures: List<Map<String, dynamic>>.from(
              kanban['en_attente'] ?? []),
            onDrop: (id) => _moveCandidat(id, 'en_attente'),
          ),
          _KanbanColonne(
            titre: 'En examen',
            statut: 'en_cours',
            couleur: const Color(0xFFF59E0B),
            candidatures: List<Map<String, dynamic>>.from(
              kanban['en_cours'] ?? []),
            onDrop: (id) => _moveCandidat(id, 'mettre_en_examen'),
          ),
          _KanbanColonne(
            titre: 'Entretien',
            statut: 'entretien',
            couleur: const Color(0xFF8B5CF6),
            candidatures: List<Map<String, dynamic>>.from(
              kanban['entretien'] ?? []),
            onDrop: (id) => _moveCandidat(id, 'planifier_entretien'),
          ),
          _KanbanColonne(
            titre: 'Acceptées',
            statut: 'acceptee',
            couleur: const Color(0xFF10B981),
            candidatures: List<Map<String, dynamic>>.from(
              kanban['acceptees'] ?? []),
            onDrop: (id) => _moveCandidat(id, 'accepter'),
          ),
          _KanbanColonne(
            titre: 'Refusées',
            statut: 'refusee',
            couleur: const Color(0xFFEF4444),
            candidatures: List<Map<String, dynamic>>.from(
              kanban['refusees'] ?? []),
            onDrop: (id) => _moveCandidat(id, 'refuser'),
          ),
        ],
      ),
    );

  Future<void> _moveCandidat(String candidatureId, String action) async {
    final token = context.read<AuthProvider>().token ?? '';
    await _svc.actionCandidature(token, candidatureId, action);
    _loadCandidatures();
  }

  Future<void> _exportCandidatures() async {
    final token = context.read<AuthProvider>().token ?? '';
    String url = '${ApiConfig.baseUrl}/api/recruteur/candidatures/export/csv';
    if (widget.offreId != null) url += '?offre_id=${widget.offreId}';
    await DownloadService.downloadCsv(
      url: url, token: token,
      fileName: 'candidatures.csv', context: context);
  }
}
```

---

## 6. Page Recherche Talents — Données réelles

```dart
class _TalentsSearchPageState extends State<TalentsSearchPage> {
  final RecruteurService _svc = RecruteurService();
  List<Map<String, dynamic>> _talents = [];
  bool _isLoading = false;
  String _recherche = '';
  String? _niveauEtude, _disponibilite, _ville, _offreId;
  final _rechercheCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadTalents();
  }

  Future<void> _loadTalents() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await _svc.getTalents(
        token,
        recherche:    _recherche.isNotEmpty ? _recherche : null,
        niveauEtude:  _niveauEtude,
        disponibilite: _disponibilite,
        ville:        _ville,
        offreId:      _offreId,
      );
      setState(() {
        _talents = List<Map<String, dynamic>>.from(
          res['data']?['talents'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [

        // En-tête
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)]),
              borderRadius: BorderRadius.circular(100)),
            child: Row(children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 13),
              const SizedBox(width: 4),
              Text('IA', style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: Colors.white)),
            ]),
          ),
          const SizedBox(width: 10),
          Text('Recherche de Talents', style: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A))),
        ]),
        const SizedBox(height: 4),
        Text(
          'Trouvez les candidats idéaux parmi les profils inscrits sur la plateforme.',
          style: GoogleFonts.inter(
            fontSize: 14, color: const Color(0xFF64748B))),
        const SizedBox(height: 20),

        // Barre de recherche
        Row(children: [
          Expanded(child: TextField(
            controller: _rechercheCtrl,
            decoration: InputDecoration(
              hintText: 'Compétence, titre, domaine...',
              prefixIcon: const Icon(Icons.search, size: 18,
                color: Color(0xFF94A3B8)),
              filled: true, fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 400), () {
                setState(() => _recherche = v);
                _loadTalents();
              });
            },
          )),
          const SizedBox(width: 10),
          // Matcher avec une offre pour scores IA
          _OffreMatcherDropdown(
            onSelected: (offreId) {
              setState(() => _offreId = offreId);
              _loadTalents();
            },
          ),
        ]),
        const SizedBox(height: 14),

        // Filtres
        _FiltersRow(
          onNiveauChanged: (v) { setState(() => _niveauEtude = v); _loadTalents(); },
          onDispoChanged:  (v) { setState(() => _disponibilite = v); _loadTalents(); },
          onVilleChanged:  (v) { setState(() => _ville = v); _loadTalents(); },
        ),
        const SizedBox(height: 20),

        // Info si matching actif
        if (_offreId != null)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBFDBFE))),
            child: Row(children: [
              const Icon(Icons.auto_awesome,
                color: Color(0xFF1A56DB), size: 16),
              const SizedBox(width: 8),
              Text(
                'Score IA activé : les profils sont triés par compatibilité avec votre offre',
                style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF1E40AF))),
            ]),
          ),

        // Résultats
        if (_isLoading)
          const Center(child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(color: Color(0xFF1A56DB))))
        else if (_talents.isEmpty)
          _EmptyState(
            icon: Icons.search_off_outlined,
            message: 'Aucun talent trouvé. Modifiez vos critères.')
        else
          Text(
            '${_talents.length} talent(s) trouvé(s)',
            style: GoogleFonts.inter(
              fontSize: 14, color: const Color(0xFF64748B))),
        const SizedBox(height: 12),

        // Grille talents
        if (!_isLoading && _talents.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                MediaQuery.of(context).size.width > 1200 ? 4 :
                MediaQuery.of(context).size.width > 768  ? 3 : 2,
              childAspectRatio: 0.78,
              crossAxisSpacing: 14, mainAxisSpacing: 14,
            ),
            itemCount: _talents.length,
            itemBuilder: (ctx, i) => TalentCard(
              talent: _talents[i],
              onContact: (msg) => _contacterTalent(
                _talents[i], msg),
            ),
          ),
      ]),
    );
  }

  Future<void> _contacterTalent(
    Map<String, dynamic> talent, String message) async {
    final token = context.read<AuthProvider>().token ?? '';
    final userId = talent['utilisateur']?['id'] as String?;
    if (userId == null) return;

    await _svc.contacterTalent(token, userId, message,
      offreId: _offreId);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Message envoyé avec succès !'),
      backgroundColor: Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// TalentCard avec données réelles
class TalentCard extends StatelessWidget {
  final Map<String, dynamic> talent;
  final void Function(String message) onContact;
  const TalentCard({super.key, required this.talent, required this.onContact});

  @override
  Widget build(BuildContext context) {
    final utilisateur = talent['utilisateur'] as Map<String, dynamic>? ?? {};
    final nom      = utilisateur['nom'] as String? ?? 'Candidat';
    final photoUrl = utilisateur['photo_url'] as String?;
    final adresse  = utilisateur['adresse'] as String? ?? '';
    final niveau   = talent['niveau_etude'] as String? ?? '';
    final dispo    = talent['disponibilite'] as String? ?? '';
    final score    = talent['score_matching'] as int?;

    // Compétences depuis CV ou profil
    final compsCV = (talent['cv'] as List?)
        ?.firstOrNull?['competences_extrait']?['competences'] as List?
        ?? [];
    final compsProfil = talent['competences'];
    final allComps = <String>{};
    for (final c in [...compsCV,
      ...(compsProfil is List ? compsProfil :
          (compsProfil as Map?)?.values ?? [])]) {
      allComps.add(c.toString());
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(
          color: Color(0x06000000), blurRadius: 8,
          offset: Offset(0, 2))]),
      padding: const EdgeInsets.all(16),
      child: Column(children: [

        // Score IA si disponible
        if (score != null && score > 0)
          Align(
            alignment: Alignment.topRight,
            child: IAScoreBadge(score: score)),
        if (score != null && score > 0)
          const SizedBox(height: 8),

        // Avatar
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF1A56DB),
          backgroundImage: photoUrl != null
              ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? Text(nom[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.w700,
                    color: Colors.white))
              : null,
        ),
        const SizedBox(height: 10),

        Text(nom, style: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A)),
          textAlign: TextAlign.center,
          maxLines: 1, overflow: TextOverflow.ellipsis),

        if (adresse.isNotEmpty)
          Text(adresse, style: GoogleFonts.inter(
            fontSize: 12, color: const Color(0xFF94A3B8)),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),

        // Disponibilité
        if (dispo.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(100)),
            child: Text(
              dispo == 'immediat' ? 'Disponible maintenant' :
              dispo == '1_mois' ? 'Dispo dans 1 mois' : dispo,
              style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w600,
                color: const Color(0xFF065F46)))),

        const SizedBox(height: 10),

        // Compétences (max 3)
        if (allComps.isNotEmpty)
          Wrap(spacing: 4, runSpacing: 4,
            children: allComps.take(3).map((s) =>
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(100)),
                child: Text(s, style: GoogleFonts.inter(
                  fontSize: 10, color: const Color(0xFF1E40AF))),
              )
            ).toList()),

        const Spacer(),
        const SizedBox(height: 10),

        // Bouton contacter
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.chat_outlined, size: 14),
            label: const Text('Contacter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56DB),
              foregroundColor: Colors.white, elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
              textStyle: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600)),
            onPressed: () => _showContactDialog(context),
          ),
        ),
      ]),
    );
  }

  void _showContactDialog(BuildContext context) {
    final ctrl = TextEditingController(
      text: 'Bonjour, votre profil correspond à l\'une de nos offres. '
            'Nous aimerions vous contacter.');
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16)),
      title: Text('Contacter ce candidat',
        style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w700)),
      content: TextFormField(
        controller: ctrl, maxLines: 4,
        decoration: InputDecoration(
          filled: true, fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB), elevation: 0),
          onPressed: () {
            Navigator.pop(context);
            onContact(ctrl.text);
          },
          child: Text('Envoyer', style: GoogleFonts.inter(
            color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ],
    ));
  }
}
```

---

## 7. Page Profil Entreprise — Upload + Données réelles

```dart
class _ProfilEntreprisePageState extends State<ProfilEntreprisePage> {
  final RecruteurService _svc = RecruteurService();
  Map<String, dynamic>? _profil;
  bool _isLoading = true, _isSaving = false;

  // Contrôleurs
  final _nomCtrl        = TextEditingController();
  final _descCtrl       = TextEditingController();
  final _secteurCtrl    = TextEditingController();
  final _tailleCtrl     = TextEditingController();
  final _siteCtrl       = TextEditingController();
  final _adresseCtrl    = TextEditingController();

  @override
  void initState() { super.initState(); _loadProfil(); }

  Future<void> _loadProfil() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await _svc.getProfil(token);
      final data = res['data'] as Map<String, dynamic>;
      setState(() {
        _profil = data;
        _nomCtrl.text      = data['nom_entreprise']    ?? '';
        _descCtrl.text     = data['description']       ?? '';
        _secteurCtrl.text  = data['secteur_activite']  ?? '';
        _tailleCtrl.text   = data['taille_entreprise'] ?? '';
        _siteCtrl.text     = data['site_web']          ?? '';
        _adresseCtrl.text  = data['adresse_siege']     ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfil() async {
    setState(() => _isSaving = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      await _svc.updateProfil(token, {
        'nom_entreprise':    _nomCtrl.text.trim(),
        'description':       _descCtrl.text.trim(),
        'secteur_activite':  _secteurCtrl.text.trim(),
        'taille_entreprise': _tailleCtrl.text.trim(),
        'site_web':          _siteCtrl.text.trim(),
        'adresse_siege':     _adresseCtrl.text.trim(),
      });

      // Mettre à jour le Provider global
      context.read<RecruteurProvider>().updateProfil({
        'nom_entreprise': _nomCtrl.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profil mis à jour avec succès !'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Colonne gauche — Photo/Logo
        Expanded(flex: 35, child: Column(children: [

          // Card Logo + Bannière
          _buildLogoCard(),
          const SizedBox(height: 16),
          _buildQuickStats(),
        ])),
        const SizedBox(width: 20),

        // Colonne droite — Formulaire
        Expanded(flex: 65, child: Column(children: [
          _buildInfosCard(),
          const SizedBox(height: 16),
          _buildSaveButton(),
        ])),
      ]),
    );
  }

  Widget _buildLogoCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Column(children: [
      Text('Logo de l\'entreprise', style: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A))),
      const SizedBox(height: 16),

      // Upload Logo — utiliser ImageUploadWidget
      ImageUploadWidget(
        currentImageUrl: _profil?['logo_url'],
        uploadUrl: '${ApiConfig.baseUrl}/api/recruteur/profil/logo',
        fieldName: 'logo',
        title: 'logo entreprise',
        dimensionsInfo: '200 × 200 px (carré)',
        acceptedFormats: 'PNG, JPG, WEBP',
        maxSizeMb: 3,
        previewHeight: 80,
        onUploaded: (url) {
          setState(() => _profil = { ...?_profil, 'logo_url': url });
          context.read<RecruteurProvider>().updateProfil({'logo_url': url});
        },
      ),
    ]),
  );

  Widget _buildQuickStats() {
    final stats = _profil?['stats'] as Map<String, dynamic>? ?? {};
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Statistiques rapides', style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A))),
        const SizedBox(height: 12),
        _QuickStat(Icons.work_outline,
          '${stats['nb_offres'] ?? 0}', 'Offres publiées'),
        const SizedBox(height: 8),
        _QuickStat(Icons.people_outline,
          '${stats['nb_candidatures'] ?? 0}', 'Candidatures reçues'),
      ]),
    );
  }

  Widget _buildInfosCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Informations de l\'entreprise', style: GoogleFonts.poppins(
        fontSize: 15, fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A))),
      const SizedBox(height: 20),
      _label('Nom de l\'entreprise *'),
      const SizedBox(height: 6),
      _field(_nomCtrl, 'Nom officiel'),
      const SizedBox(height: 14),
      _label('Description'),
      const SizedBox(height: 6),
      TextFormField(
        controller: _descCtrl, maxLines: 4,
        decoration: _inputDeco('Décrivez votre entreprise...'),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('Secteur d\'activité'),
          const SizedBox(height: 6),
          _field(_secteurCtrl, 'ex: Télécommunications'),
        ])),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('Taille de l\'entreprise'),
          const SizedBox(height: 6),
          _field(_tailleCtrl, 'ex: 50-200 employés'),
        ])),
      ]),
      const SizedBox(height: 14),
      _label('Site web'),
      const SizedBox(height: 6),
      _field(_siteCtrl, 'https://www.monentreprise.gn'),
      const SizedBox(height: 14),
      _label('Adresse du siège'),
      const SizedBox(height: 6),
      _field(_adresseCtrl, 'Conakry, Guinée'),
    ]),
  );

  Widget _buildSaveButton() => SizedBox(
    width: double.infinity, height: 50,
    child: ElevatedButton.icon(
      icon: _isSaving
          ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.save_outlined, size: 18),
      label: Text(_isSaving ? 'Sauvegarde...' : 'Sauvegarder le profil',
        style: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A56DB),
        foregroundColor: Colors.white, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10))),
      onPressed: _isSaving ? null : _saveProfil,
    ),
  );

  Widget _label(String t) => Text(t, style: GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w500,
    color: const Color(0xFF374151)));

  Widget _field(TextEditingController c, String hint) =>
    TextFormField(controller: c, decoration: _inputDeco(hint));

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(
      fontSize: 14, color: const Color(0xFFCBD5E1)),
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
        color: Color(0xFF1A56DB), width: 1.5)),
  );
}
```

---

## 8. Page Messagerie — Données réelles

```dart
class _MessageriePageState extends State<MessageriePage> {
  final RecruteurService _svc = RecruteurService();
  List<Map<String, dynamic>> _conversations = [];
  Map<String, dynamic>? _convActive;
  List<Map<String, dynamic>> _messages = [];
  bool _loadingConvs = true, _loadingMsgs = false;
  final _msgCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    // Si on a un destinataire direct (depuis Talents)
    if (widget.candidatId != null) {
      _openConversation(widget.candidatId!);
    }
    // Rafraîchir toutes les 15 secondes
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15), (_) => _loadConversations());
  }

  Future<void> _loadConversations() async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await _svc.getConversations(token);
      setState(() {
        _conversations = List<Map<String, dynamic>>.from(
          res['data'] ?? []);
        _loadingConvs = false;
      });
      // Mettre à jour le badge sidebar
      final nbNonLus = _conversations.fold<int>(
        0, (sum, c) => sum + ((c['nb_non_lus'] as int?) ?? 0));
      context.read<RecruteurProvider>().updateNbMessages(nbNonLus);
    } catch (_) {
      setState(() => _loadingConvs = false);
    }
  }

  Future<void> _openConversation(String destinataireId) async {
    setState(() { _loadingMsgs = true; });
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await _svc.getMessages(token, destinataireId);
      final data = res['data'] as Map<String, dynamic>;
      setState(() {
        _convActive = data['interlocuteur'];
        _messages   = List<Map<String, dynamic>>.from(
          data['messages'] ?? []);
        _loadingMsgs = false;
      });
      // Scroll vers le bas
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        }
      });
    } catch (_) {
      setState(() => _loadingMsgs = false);
    }
  }

  Future<void> _sendMessage() async {
    final txt = _msgCtrl.text.trim();
    if (txt.isEmpty || _convActive == null) return;
    _msgCtrl.clear();

    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await _svc.envoyerMessage(
        token, _convActive!['id'], txt);
      final newMsg = res['data'] as Map<String, dynamic>;
      setState(() => _messages.add(newMsg));
      // Scroll vers le bas
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
        }
      });
    } catch (e) {
      _msgCtrl.text = txt; // Restaurer
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      color: const Color(0xFFF8FAFC),
      child: isMobile
          ? _buildMobile()
          : Row(children: [
              SizedBox(width: 320, child: _buildConvsList()),
              const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
              Expanded(child: _buildConvView()),
            ]),
    );
  }

  Widget _buildConvsList() => Column(children: [
    // En-tête
    Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(children: [
        Text('Messagerie', style: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A))),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.refresh_outlined, size: 18,
            color: Color(0xFF64748B)),
          onPressed: _loadConversations),
      ]),
    ),
    const Divider(height: 1, color: Color(0xFFE2E8F0)),

    // Liste conversations
    Expanded(child: _loadingConvs
        ? const Center(child: CircularProgressIndicator(
            color: Color(0xFF1A56DB)))
        : _conversations.isEmpty
            ? _EmptyState(
                icon: Icons.chat_bubble_outline,
                message: 'Aucune conversation')
            : ListView.builder(
                itemCount: _conversations.length,
                itemBuilder: (ctx, i) {
                  final c = _conversations[i];
                  final interlocuteur = c['expediteur_id'] == context.read<AuthProvider>().userId
                      ? c['destinataire'] : c['expediteur'];
                  final nbNonLus = c['nb_non_lus'] as int? ?? 0;

                  return ListTile(
                    onTap: () => _openConversation(
                      interlocuteur?['id'] ?? ''),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF1A56DB),
                      backgroundImage: interlocuteur?['photo_url'] != null
                          ? NetworkImage(interlocuteur['photo_url'])
                          : null,
                      child: interlocuteur?['photo_url'] == null
                          ? Text(
                              (interlocuteur?['nom'] ?? 'C')[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))
                          : null,
                    ),
                    title: Text(
                      interlocuteur?['nom'] ?? 'Candidat',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: nbNonLus > 0
                            ? FontWeight.w700 : FontWeight.w400,
                        color: const Color(0xFF0F172A))),
                    subtitle: Text(
                      c['dernier_message'] ?? '',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12, color: const Color(0xFF64748B))),
                    trailing: nbNonLus > 0
                        ? Container(
                            width: 20, height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1A56DB),
                              shape: BoxShape.circle),
                            child: Center(child: Text('$nbNonLus',
                              style: GoogleFonts.inter(
                                fontSize: 10, color: Colors.white,
                                fontWeight: FontWeight.w700))))
                        : null,
                  );
                },
              )),
  ]);

  Widget _buildConvView() {
    if (_convActive == null) return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.chat_bubble_outline,
          color: Color(0xFFE2E8F0), size: 64),
        const SizedBox(height: 12),
        Text('Sélectionnez une conversation',
          style: GoogleFonts.inter(
            fontSize: 16, color: const Color(0xFF94A3B8))),
      ]),
    );

    return Column(children: [
      // En-tête conversation
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 14),
        color: Colors.white,
        child: Row(children: [
          CircleAvatar(
            radius: 18, backgroundColor: const Color(0xFF1A56DB),
            backgroundImage: _convActive!['photo_url'] != null
                ? NetworkImage(_convActive!['photo_url']) : null,
            child: _convActive!['photo_url'] == null
                ? Text((_convActive!['nom'] ?? 'C')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 10),
          Text(_convActive!['nom'] ?? '',
            style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A))),
        ]),
      ),
      const Divider(height: 1, color: Color(0xFFE2E8F0)),

      // Messages
      Expanded(child: _loadingMsgs
          ? const Center(child: CircularProgressIndicator(
              color: Color(0xFF1A56DB)))
          : ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final msg = _messages[i];
                final myId = context.read<AuthProvider>().userId;
                final isMe = msg['expediteur_id'] == myId;

                return Align(
                  alignment: isMe
                      ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth:
                        MediaQuery.of(context).size.width * 0.55),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFF1A56DB)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12).copyWith(
                        bottomRight: isMe
                            ? const Radius.circular(2) : null,
                        bottomLeft: !isMe
                            ? const Radius.circular(2) : null),
                      boxShadow: const [BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 4, offset: Offset(0, 2))]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                      Text(msg['contenu'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isMe
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          height: 1.4)),
                      const SizedBox(height: 2),
                      Text(
                        _formatTime(msg['date_envoi']),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isMe
                              ? Colors.white60
                              : const Color(0xFF94A3B8))),
                    ]),
                  ),
                );
              },
            )),

      // Zone de saisie
      Container(
        padding: const EdgeInsets.all(12),
        color: Colors.white,
        child: Row(children: [
          Expanded(child: TextField(
            controller: _msgCtrl,
            maxLines: null,
            decoration: InputDecoration(
              hintText: 'Écrire un message...',
              hintStyle: GoogleFonts.inter(
                fontSize: 14, color: const Color(0xFFCBD5E1)),
              filled: true, fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: const BorderSide(
                  color: Color(0xFF1A56DB), width: 1.5)),
            ),
            onSubmitted: (_) => _sendMessage(),
          )),
          const SizedBox(width: 8),
          InkWell(
            onTap: _sendMessage,
            borderRadius: BorderRadius.circular(100),
            child: Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF1A56DB),
                shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded,
                color: Colors.white, size: 20),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildMobile() {
    if (_convActive != null) return _buildConvView();
    return _buildConvsList();
  }

  String _formatTime(String? d) {
    if (d == null) return '';
    try {
      final dt = DateTime.parse(d).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
      if (diff.inHours < 24)   return 'Il y a ${diff.inHours}h';
      return '${dt.day}/${dt.month}';
    } catch (_) { return ''; }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
```

---

## 9. Page Statistiques — Données réelles

```dart
class _StatistiquesPageState extends State<StatistiquesRecruteurPage> {
  final RecruteurService _svc = RecruteurService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String _periode = '30d';

  @override
  void initState() { super.initState(); _loadStats(); }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await _svc.getStats(token, periode: _periode);
      setState(() { _stats = res['data']; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [

        // En-tête + sélecteur période
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Statistiques & Analytiques',
            style: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A))),
          Row(children: [
            for (final p in ['7d', '30d', '3m'])
              GestureDetector(
                onTap: () {
                  setState(() => _periode = p);
                  _loadStats();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _periode == p
                        ? const Color(0xFF1A56DB)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8)),
                  child: Text(p, style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500,
                    color: _periode == p
                        ? Colors.white
                        : const Color(0xFF64748B))),
                ),
              ),
          ]),
        ]),
        const SizedBox(height: 24),

        if (_isLoading)
          const Center(child: CircularProgressIndicator(
            color: Color(0xFF1A56DB)))
        else if (_stats != null) ...[

          // KPIs
          _buildKPIs(_stats!['kpis'] ?? {}),
          const SizedBox(height: 24),

          // Graphique évolution
          _buildEvolutionChart(
            List<Map<String, dynamic>>.from(
              _stats!['evolution_par_jour'] ?? [])),
          const SizedBox(height: 24),

          // Répartition statuts
          _buildRepartitionStatuts(
            _stats!['repartition_statuts'] as Map<String, dynamic>? ?? {}),
          const SizedBox(height: 24),

          // Performance par offre
          _buildPerfParOffre(
            List<Map<String, dynamic>>.from(
              _stats!['performance_par_offre'] ?? [])),
        ],
      ]),
    );
  }

  Widget _buildKPIs(Map<String, dynamic> kpis) {
    return LayoutBuilder(builder: (ctx, c) {
      final cols = c.maxWidth < 600 ? 2 : 4;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 14, mainAxisSpacing: 14,
        childAspectRatio: c.maxWidth < 600 ? 1.5 : 2.0,
        children: [
          _KpiCard('Candidatures',
            '${kpis['candidatures']?['valeur'] ?? 0}',
            Icons.people_rounded,
            const Color(0xFF10B981), const Color(0xFFECFDF5)),
          _KpiCard('Vues des offres',
            '${kpis['vues']?['valeur'] ?? 0}',
            Icons.visibility_rounded,
            const Color(0xFF1A56DB), const Color(0xFFEFF6FF)),
          _KpiCard('Taux de réponse',
            '${kpis['taux_reponse']?['valeur'] ?? 0}%',
            Icons.reply_rounded,
            const Color(0xFFF59E0B), const Color(0xFFFEF3C7)),
          _KpiCard('Score IA moyen',
            '${kpis['score_ia_moyen']?['valeur'] ?? 0}%',
            Icons.auto_awesome_rounded,
            const Color(0xFF8B5CF6), const Color(0xFFF5F3FF)),
        ],
      );
    });
  }

  Widget _buildEvolutionChart(List<Map<String, dynamic>> evolution) {
    if (evolution.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Évolution des candidatures',
          style: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A))),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: LineChart(LineChartData(
            gridData: FlGridData(
              show: true,
              getDrawingHorizontalLine: (_) => FlLine(
                color: const Color(0xFFE2E8F0), strokeWidth: 1),
              drawVerticalLine: false,
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true, reservedSize: 30,
                  getTitlesWidget: (v, _) => Text(
                    '${v.toInt()}',
                    style: GoogleFonts.inter(
                      fontSize: 10, color: const Color(0xFF94A3B8))))),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: evolution.asMap().entries.map((e) =>
                  FlSpot(e.key.toDouble(),
                    (e.value['candidatures'] as num?)?.toDouble() ?? 0)
                ).toList(),
                isCurved: true,
                color: const Color(0xFF1A56DB),
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFF1A56DB).withOpacity(0.08)),
              ),
            ],
          )),
        ),
      ]),
    );
  }

  Widget _buildPerfParOffre(List<Map<String, dynamic>> offres) {
    if (offres.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Performance par offre',
          style: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A))),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 24,
            headingRowColor: MaterialStateProperty.all(
              const Color(0xFFF8FAFC)),
            columns: [
              DataColumn(label: Text('Offre', style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Vues', style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Candidatures', style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Score IA moy.', style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Taux réponse', style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600))),
            ],
            rows: offres.map((o) => DataRow(cells: [
              DataCell(Text(
                (o['titre'] as String? ?? '').length > 25
                    ? '${(o['titre'] as String).substring(0, 25)}...'
                    : o['titre'] ?? '',
                style: GoogleFonts.inter(fontSize: 13))),
              DataCell(Text('${o['nb_vues'] ?? 0}',
                style: GoogleFonts.inter(fontSize: 13))),
              DataCell(Text('${o['nb_candidatures'] ?? 0}',
                style: GoogleFonts.inter(fontSize: 13))),
              DataCell(IAScoreBadge(
                score: o['score_ia_moyen'] as int? ?? 0)),
              DataCell(Text('${o['taux_reponse'] ?? 0}%',
                style: GoogleFonts.inter(fontSize: 13))),
            ])).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _buildRepartitionStatuts(Map<String, dynamic> repartition) =>
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Entonnoir de recrutement',
          style: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A))),
        const SizedBox(height: 14),
        _FunnelBar('Reçues',    repartition['en_attente'] ?? 0, const Color(0xFF1A56DB)),
        _FunnelBar('En examen', repartition['en_cours']   ?? 0, const Color(0xFFF59E0B)),
        _FunnelBar('Entretien', repartition['entretien']  ?? 0, const Color(0xFF8B5CF6)),
        _FunnelBar('Acceptées', repartition['acceptees']  ?? 0, const Color(0xFF10B981)),
        _FunnelBar('Refusées',  repartition['refusees']   ?? 0, const Color(0xFFEF4444)),
      ]),
    );
}

// Barre d'entonnoir
class _FunnelBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _FunnelBar(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      SizedBox(width: 90, child: Text(label, style: GoogleFonts.inter(
        fontSize: 13, color: const Color(0xFF64748B)))),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: LinearProgressIndicator(
          value: value > 0 ? value / 100.0 : 0,
          backgroundColor: const Color(0xFFE2E8F0),
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 8,
        ),
      )),
      const SizedBox(width: 10),
      Text('$value', style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w600,
        color: const Color(0xFF334155))),
    ]),
  );
}
```

---

## 10. Page Notifications — Données réelles

```dart
class _NotificationsPageState extends State<NotificationsRecruteurPage> {
  final RecruteurService _svc = RecruteurService();
  List<Map<String, dynamic>> _notifs = [];
  int _nbNonLues = 0;
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _loadNotifs(); }

  Future<void> _loadNotifs() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await _svc.getNotifications(token);
      final data = res['data'] as Map<String, dynamic>? ?? {};
      setState(() {
        _notifs    = List<Map<String, dynamic>>.from(
          data['notifications'] ?? []);
        _nbNonLues = data['nb_non_lues'] as int? ?? 0;
        _isLoading = false;
      });
      // Mettre à jour badge sidebar
      context.read<RecruteurProvider>()
        .updateNbNotifications(_nbNonLues);
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _marquerToutLu() async {
    final token = context.read<AuthProvider>().token ?? '';
    await _svc.marquerToutesLues(token);
    context.read<RecruteurProvider>().updateNbNotifications(0);
    _loadNotifs();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Notifications', style: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A))),
          if (_nbNonLues > 0)
            Text('$_nbNonLues non lue(s)',
              style: GoogleFonts.inter(
                fontSize: 14, color: const Color(0xFF1A56DB))),
        ]),
        if (_nbNonLues > 0)
          TextButton.icon(
            icon: const Icon(Icons.done_all, size: 16),
            label: const Text('Tout marquer comme lu'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1A56DB)),
            onPressed: _marquerToutLu),
      ]),
      const SizedBox(height: 20),

      if (_isLoading)
        const Center(child: CircularProgressIndicator(
          color: Color(0xFF1A56DB)))
      else if (_notifs.isEmpty)
        _EmptyState(
          icon: Icons.notifications_none_outlined,
          message: 'Aucune notification pour le moment')
      else
        ..._notifs.map((n) => _NotifTile(
          notif: n,
          onMarkRead: () async {
            final token = context.read<AuthProvider>().token ?? '';
            await _svc.marquerNotifLue(token, n['id']);
            _loadNotifs();
          },
        )),
    ]),
  );
}

class _NotifTile extends StatelessWidget {
  final Map<String, dynamic> notif;
  final VoidCallback onMarkRead;
  const _NotifTile({required this.notif, required this.onMarkRead});

  @override
  Widget build(BuildContext context) {
    final estLue = notif['est_lue'] == true;
    final type   = notif['type'] as String? ?? 'systeme';

    return GestureDetector(
      onTap: () {
        if (!estLue) onMarkRead();
        if (notif['lien'] != null) context.push(notif['lien']);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: estLue ? Colors.white : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: estLue
                ? const Color(0xFFE2E8F0)
                : const Color(0xFF1A56DB).withOpacity(0.2))),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: _typeColor(type).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8)),
            child: Icon(_typeIcon(type),
              color: _typeColor(type), size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(notif['titre'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: estLue
                    ? FontWeight.w400 : FontWeight.w600,
                color: const Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text(notif['message'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFF64748B)),
              maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(_formatDate(notif['date_creation']),
              style: GoogleFonts.inter(
                fontSize: 11, color: const Color(0xFF94A3B8))),
          ])),
          if (!estLue)
            Container(width: 8, height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF1A56DB), shape: BoxShape.circle)),
        ]),
      ),
    );
  }

  IconData _typeIcon(String t) {
    switch (t) {
      case 'candidature': return Icons.assignment_outlined;
      case 'offre':       return Icons.work_outline;
      case 'message':     return Icons.chat_bubble_outline;
      default:            return Icons.notifications_outlined;
    }
  }

  Color _typeColor(String t) {
    switch (t) {
      case 'candidature': return const Color(0xFF10B981);
      case 'offre':       return const Color(0xFF1A56DB);
      case 'message':     return const Color(0xFF8B5CF6);
      default:            return const Color(0xFFF59E0B);
    }
  }

  String _formatDate(String? d) {
    if (d == null) return '';
    try {
      final dt = DateTime.parse(d).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
      if (diff.inHours < 24)   return 'Il y a ${diff.inHours}h';
      return 'Il y a ${diff.inDays}j';
    } catch (_) { return ''; }
  }
}
```

---

## 11. Page Paramètres Recruteur

```dart
// lib/screens/recruteur/pages/parametres_recruteur_page.dart

class ParametresRecruteurPage extends StatefulWidget {
  const ParametresRecruteurPage({super.key});
  @override
  State<ParametresRecruteurPage> createState() =>
    _ParametresRecruteurPageState();
}

class _ParametresRecruteurPageState extends State<ParametresRecruteurPage> {
  final ancienMdpCtrl = TextEditingController();
  final nvMdpCtrl     = TextEditingController();
  final confirmCtrl   = TextEditingController();
  bool _isSaving = false;
  bool _notifCandidature = true;
  bool _notifMessage     = true;

  @override
  Widget build(BuildContext context) =>
    SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Text('Paramètres', style: GoogleFonts.poppins(
          fontSize: 22, fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A))),
        const SizedBox(height: 24),

        // Apparence
        _SettingsCard(title: '🎨 Apparence', children: [
          const ThemeSelectorTile(),
        ]),
        const SizedBox(height: 16),

        // Notifications
        _SettingsCard(title: '🔔 Notifications', children: [
          _ToggleRow(
            'Email à chaque candidature',
            'Recevoir un email quand quelqu\'un postule',
            _notifCandidature,
            (v) => setState(() => _notifCandidature = v)),
          const Divider(height: 20),
          _ToggleRow(
            'Email à chaque message',
            'Recevoir un email pour les nouveaux messages',
            _notifMessage,
            (v) => setState(() => _notifMessage = v)),
        ]),
        const SizedBox(height: 16),

        // Mot de passe
        _SettingsCard(title: '🔒 Changer le mot de passe', children: [
          _PwdField(ancienMdpCtrl, 'Mot de passe actuel'),
          const SizedBox(height: 12),
          _PwdField(nvMdpCtrl, 'Nouveau mot de passe'),
          const SizedBox(height: 12),
          _PwdField(confirmCtrl, 'Confirmer le nouveau mot de passe'),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56DB),
              foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8))),
            onPressed: _changerMdp,
            child: Text('Modifier le mot de passe',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 16),

        // Danger zone
        _SettingsCard(title: '⚠️ Zone de danger', children: [
          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Désactiver le compte',
                style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w500,
                  color: const Color(0xFF0F172A))),
              Text('Votre compte sera temporairement désactivé',
                style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF64748B))),
            ])),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
              onPressed: () {},
              child: const Text('Désactiver')),
          ]),
        ]),
      ]),
    );

  Future<void> _changerMdp() async {
    if (nvMdpCtrl.text != confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Les mots de passe ne correspondent pas'),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    // Appel API changement mdp
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Mot de passe modifié avec succès'),
      backgroundColor: Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
    ));
    ancienMdpCtrl.clear();
    nvMdpCtrl.clear();
    confirmCtrl.clear();
  }
}
```

---

## 12. Critères d'Acceptation

### ✅ RecruteurProvider
- [ ] Chargé au démarrage de RecruteurShell
- [ ] `nbOffresActives`, `nbCandidEnAttente`, `nbMessagesNonLus`,
      `nbNotificationsNonLues` → données réelles depuis l'API

### ✅ Sidebar
- [ ] Badge "Mes offres" = nb offres actives RÉEL (0 si aucune)
- [ ] Badge "Candidatures" = nb candidatures en attente RÉEL
- [ ] Badge "Messagerie" = messages non lus RÉEL
- [ ] Badge "Notifications" = notifications non lues RÉEL
- [ ] Logo et nom entreprise dynamiques depuis le profil

### ✅ Vue d'ensemble
- [ ] Salutation avec nom entreprise réel
- [ ] 4 stat cards : données réelles (offres, candidatures, vues, taux)
- [ ] Alerte jaune si candidatures urgentes (>7j sans réponse)
- [ ] Liste candidatures récentes : vraies données + score IA
- [ ] Liste offres actives : vraies données (vues, candidatures, non lues)
- [ ] Pull-to-refresh fonctionnel

### ✅ Mes Offres
- [ ] Tabs avec chiffres réels (Toutes/Actives/En attente/Expirées/Brouillons)
- [ ] Recherche par titre fonctionnelle (debounce 400ms)
- [ ] Nb vues et nb candidatures par offre : données réelles
- [ ] Actions dupliquer/clôturer/supprimer fonctionnelles
- [ ] Export CSV téléchargeable

### ✅ Candidatures
- [ ] Erreur "offre_id requis" corrigée (offre_id optionnel)
- [ ] Vue liste ET vue kanban avec données réelles
- [ ] Filtres par statut fonctionnels avec compteurs réels
- [ ] Actions (examiner/entretien/accepter/refuser) envoient notification au candidat
- [ ] Export CSV fonctionnel

### ✅ Recherche Talents
- [ ] Vrais candidats depuis la BDD (pas de noms fictifs)
- [ ] Score IA réel quand une offre est sélectionnée
- [ ] Bouton "Contacter" ouvre un dialog et envoie un vrai message
- [ ] Filtres (niveau, disponibilité, ville) fonctionnels

### ✅ Profil Entreprise
- [ ] Données chargées depuis l'API
- [ ] Upload logo via ImageUploadWidget (pas champ URL)
- [ ] Sauvegarde met à jour la BDD ET le Provider (sidebar se met à jour)

### ✅ Messagerie
- [ ] Vraies conversations depuis la BDD
- [ ] Envoi de message sauvegardé en BDD + notification
- [ ] Scroll automatique vers le dernier message
- [ ] Badge non lus mis à jour après lecture
- [ ] Rafraîchissement automatique toutes les 15 secondes

### ✅ Statistiques
- [ ] KPIs (candidatures, vues, taux réponse, score IA moyen) : données réelles
- [ ] Graphique courbes avec vraies données
- [ ] Tableau performance par offre : données réelles
- [ ] Sélecteur période (7d/30d/3m) recharge les données

### ✅ Notifications
- [ ] Vraies notifications depuis la BDD
- [ ] Marquer comme lu : badge sidebar diminue
- [ ] Marquer tout lu : badge sidebar → 0
- [ ] Clic sur notification → navigation vers la page liée

---

*PRD EmploiConnect v5.1 — Connexion Backend Recruteur*
*Cursor / Kirsoft AI — Phase 9.1*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
