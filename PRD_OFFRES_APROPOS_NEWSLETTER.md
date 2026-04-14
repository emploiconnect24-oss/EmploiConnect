# PRD — EmploiConnect · Offres + À propos + Newsletter
## Product Requirements Document v9.5
**Stack : Flutter + Node.js/Express + Supabase**
**Outil : Cursor / Kirsoft AI**
**Date : Avril 2026**

---

## Table des Matières

1. [Page Offres d'emploi — Redesign complet](#1-page-offres-demploi)
2. [Page À propos — Configurable depuis l'admin](#2-page-à-propos)
3. [Newsletter — Inscription + gestion admin](#3-newsletter)

---

## 1. Page Offres d'emploi

### Backend — Route offres publiques enrichie

```javascript
// backend/src/routes/offres.routes.js
// Enrichir la route GET /api/offres

router.get('/', async (req, res) => {
  try {
    const {
      q, categorie, type_contrat, ville,
      niveau, page = 1, limit = 12,
    } = req.query;

    let query = supabase
      .from('offres_emploi')
      .select(`
        id, titre, description, type_contrat,
        localisation, salaire_min, salaire_max,
        date_publication, date_expiration,
        competences_requises, niveau_experience,
        statut, nb_candidatures,
        entreprise:entreprises!inner (
          id, nom_entreprise, logo_url,
          secteur_activite, ville
        )
      `, { count: 'exact' })
      .eq('statut', 'publiee')
      .order('date_publication', { ascending: false });

    // Filtres
    if (q) {
      query = query.or(
        `titre.ilike.%${q}%,description.ilike.%${q}%`);
    }
    if (type_contrat) query = query.eq('type_contrat', type_contrat);
    if (ville)        query = query.ilike('localisation', `%${ville}%`);
    if (niveau)       query = query.eq('niveau_experience', niveau);

    // Pagination
    const from = (parseInt(page) - 1) * parseInt(limit);
    const to   = from + parseInt(limit) - 1;
    query      = query.range(from, to);

    const { data, error, count } = await query;
    if (error) throw error;

    return res.json({
      success: true,
      data: {
        offres:      data || [],
        total:       count || 0,
        page:        parseInt(page),
        limit:       parseInt(limit),
        total_pages: Math.ceil((count || 0) / parseInt(limit)),
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});
```

### Flutter — Page offres redesignée

```dart
// frontend/lib/screens/offres/offres_page.dart

class OffresPage extends StatefulWidget {
  const OffresPage({super.key});
  @override
  State<OffresPage> createState() => _OffresPageState();
}

class _OffresPageState extends State<OffresPage> {

  List<Map<String, dynamic>> _offres      = [];
  bool    _isLoading    = true;
  bool    _isLoadingMore = false;
  int     _page         = 1;
  int     _totalPages   = 1;
  int     _total        = 0;
  String  _recherche    = '';
  String? _typeContrat;
  String? _ville;
  String? _niveau;
  String  _vue          = 'grille'; // 'grille' | 'liste'

  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _charger();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200 &&
          !_isLoadingMore && _page < _totalPages) {
        _chargerPlus();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger({bool reset = true}) async {
    if (reset) {
      setState(() { _isLoading = true; _page = 1; });
    }
    try {
      final params = <String, String>{
        'page':  '$_page',
        'limit': '12',
      };
      if (_recherche.isNotEmpty) params['q']           = _recherche;
      if (_typeContrat != null)  params['type_contrat'] = _typeContrat!;
      if (_ville != null)        params['ville']        = _ville!;
      if (_niveau != null)       params['niveau']       = _niveau!;

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/offres')
        .replace(queryParameters: params);
      final res  = await http.get(uri);
      final body = jsonDecode(res.body);

      if (body['success'] == true) {
        final d = body['data'];
        setState(() {
          if (reset) {
            _offres = List<Map<String, dynamic>>.from(
              d['offres'] ?? []);
          } else {
            _offres.addAll(List<Map<String, dynamic>>.from(
              d['offres'] ?? []));
          }
          _total      = d['total']       as int? ?? 0;
          _totalPages = d['total_pages'] as int? ?? 1;
          _isLoading  = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _chargerPlus() async {
    setState(() { _isLoadingMore = true; _page++; });
    await _charger(reset: false);
    setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [

          // ── Header fixe ────────────────────────
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            toolbarHeight: 64,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 40),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => context.go('/'),
                    child: const AuthLogoHeader()),
                  const Spacer(),
                  if (!isMobile) ...[
                    TextButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Accueil')),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Entreprises')),
                  ],
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A56DB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                    onPressed: () => context.push('/login'),
                    child: Text('Se connecter',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600))),
                ])))),

          // ── Hero section ────────────────────────
          SliverToBoxAdapter(child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 60,
              vertical:   isMobile ? 32 : 48),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A56DB), Color(0xFF4F46E5)])),
            child: Column(children: [
              Text('Offres d\'emploi en Guinée',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 24 : 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white),
                textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                '$_total offre${_total > 1 ? 's' : ''} '
                'disponible${_total > 1 ? 's' : ''}',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.white70),
                textAlign: TextAlign.center),
              const SizedBox(height: 24),

              // Barre de recherche
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20, offset: const Offset(0, 8))]),
                child: Row(children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.search_rounded,
                    color: Color(0xFF94A3B8), size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText:
                        'Titre du poste, compétence, entreprise...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFFCBD5E1)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16)),
                    onSubmitted: (v) {
                      setState(() => _recherche = v.trim());
                      _charger();
                    })),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A56DB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                      onPressed: () {
                        setState(() =>
                          _recherche = _searchCtrl.text.trim());
                        _charger();
                      },
                      child: Text('Rechercher',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700)))),
                ])),
            ]))),

          // ── Filtres ─────────────────────────────
          SliverToBoxAdapter(child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 60,
              vertical: 16),
            color: Colors.white,
            child: Column(children: [
              Row(children: [
                Expanded(child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _FiltreChip(
                      label: 'Tout',
                      isActive: _typeContrat == null,
                      onTap: () {
                        setState(() => _typeContrat = null);
                        _charger();
                      }),
                    _FiltreChip(
                      label: 'CDI',
                      isActive: _typeContrat == 'CDI',
                      onTap: () {
                        setState(() => _typeContrat = 'CDI');
                        _charger();
                      }),
                    _FiltreChip(
                      label: 'CDD',
                      isActive: _typeContrat == 'CDD',
                      onTap: () {
                        setState(() => _typeContrat = 'CDD');
                        _charger();
                      }),
                    _FiltreChip(
                      label: 'Stage',
                      isActive: _typeContrat == 'stage',
                      onTap: () {
                        setState(() => _typeContrat = 'stage');
                        _charger();
                      }),
                    _FiltreChip(
                      label: 'Freelance',
                      isActive: _typeContrat == 'freelance',
                      onTap: () {
                        setState(() => _typeContrat = 'freelance');
                        _charger();
                      }),
                    _FiltreChip(
                      label: 'Conakry',
                      isActive: _ville == 'Conakry',
                      onTap: () {
                        setState(() => _ville =
                          _ville == 'Conakry' ? null : 'Conakry');
                        _charger();
                      }),
                  ]))),
                const SizedBox(width: 12),
                // Toggle vue grille/liste
                Row(children: [
                  GestureDetector(
                    onTap: () =>
                      setState(() => _vue = 'grille'),
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: _vue == 'grille'
                            ? const Color(0xFF1A56DB)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.grid_view_rounded,
                        size: 16,
                        color: _vue == 'grille'
                            ? Colors.white
                            : const Color(0xFF94A3B8)))),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () =>
                      setState(() => _vue = 'liste'),
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: _vue == 'liste'
                            ? const Color(0xFF1A56DB)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.list_rounded,
                        size: 16,
                        color: _vue == 'liste'
                            ? Colors.white
                            : const Color(0xFF94A3B8)))),
                ]),
              ]),
            ]))),
          const SliverToBoxAdapter(
            child: Divider(height: 1, color: Color(0xFFE2E8F0))),

          // ── Corps principal ──────────────────────
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(
                color: Color(0xFF1A56DB))))
          else if (_offres.isEmpty)
            SliverFillRemaining(child: _buildVide())
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 60,
                vertical: 24),
              sliver: _vue == 'grille'
                  ? _buildGrille()
                  : _buildListe()),

          // ── Loader fin de liste ──────────────────
          if (_isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child:
                  CircularProgressIndicator(
                    color: Color(0xFF1A56DB))))),

          // Footer compact
          SliverToBoxAdapter(child: _buildFooterCompact()),
        ]));
  }

  SliverGrid _buildGrille() => SliverGrid(
    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 380,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.45),
    delegate: SliverChildBuilderDelegate(
      (ctx, i) => _CarteOffreGrille(offre: _offres[i]),
      childCount: _offres.length));

  SliverList _buildListe() => SliverList(
    delegate: SliverChildBuilderDelegate(
      (ctx, i) => _CarteOffreListe(offre: _offres[i]),
      childCount: _offres.length));

  Widget _buildVide() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.work_off_outlined,
        color: Color(0xFFE2E8F0), size: 64),
      const SizedBox(height: 16),
      Text('Aucune offre trouvée',
        style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A))),
      const SizedBox(height: 8),
      Text('Essayez avec d\'autres critères de recherche',
        style: GoogleFonts.inter(
          fontSize: 14, color: const Color(0xFF64748B))),
      const SizedBox(height: 20),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A56DB),
          foregroundColor: Colors.white, elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10))),
        onPressed: () {
          _searchCtrl.clear();
          setState(() {
            _recherche   = '';
            _typeContrat = null;
            _ville       = null;
          });
          _charger();
        },
        child: const Text('Réinitialiser les filtres')),
    ]));

  Widget _buildFooterCompact() => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 60, vertical: 24),
    color: const Color(0xFF0D1B3E),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
      Text('© 2025 EmploiConnect · Guinée',
        style: GoogleFonts.inter(
          fontSize: 12, color: Colors.white38)),
      GestureDetector(
        onTap: () => context.go('/'),
        child: Text('Retour à l\'accueil',
          style: GoogleFonts.inter(
            fontSize: 12, color: const Color(0xFF1A56DB)))),
    ]));
}

// ── Carte offre grille ────────────────────────────────────
class _CarteOffreGrille extends StatefulWidget {
  final Map<String, dynamic> offre;
  const _CarteOffreGrille({required this.offre});
  @override
  State<_CarteOffreGrille> createState() =>
    _CarteOffreGrilleState();
}

class _CarteOffreGrilleState extends State<_CarteOffreGrille> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final o          = widget.offre;
    final entreprise = o['entreprise'] as Map<String, dynamic>?;
    final logo       = entreprise?['logo_url'] as String?;
    final nomEnt     = entreprise?['nom_entreprise']
        as String? ?? 'Entreprise';
    final titre      = o['titre']        as String? ?? '';
    final contrat    = o['type_contrat'] as String? ?? '';
    final lieu       = o['localisation'] as String? ?? 'Guinée';
    final salMin     = o['salaire_min']  as int?;
    final salMax     = o['salaire_max']  as int?;
    final comps      = List<String>.from(
      o['competences_requises'] ?? []);
    final date       = o['date_publication'] as String?;
    final isNouveau  = _isNouveau(date);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push('/offres/${o['id']}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..translate(0.0, _hovered ? -4.0 : 0.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered
                  ? const Color(0xFF1A56DB).withOpacity(0.3)
                  : const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(
              color: _hovered
                  ? const Color(0xFF1A56DB).withOpacity(0.1)
                  : Colors.black.withOpacity(0.04),
              blurRadius: _hovered ? 20 : 8,
              offset: const Offset(0, 4))]),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

              // Header : logo + nom entreprise + badge
              Row(children: [
                // Logo entreprise
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A56DB)
                      .withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10)),
                  child: logo != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(logo,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                              _initiale(nomEnt)))
                      : _initiale(nomEnt)),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(nomEnt,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                  Text(titre,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                ])),
                if (isNouveau) Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(100)),
                  child: Text('Nouveau',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white))),
              ]),
              const SizedBox(height: 12),

              // Infos
              Wrap(spacing: 6, runSpacing: 6, children: [
                _InfoBadge(
                  Icons.location_on_outlined, lieu,
                  const Color(0xFF64748B)),
                _InfoBadge(
                  Icons.work_outline_rounded, contrat,
                  const Color(0xFF1A56DB)),
              ]),
              const SizedBox(height: 10),

              // Salaire
              if (salMin != null || salMax != null)
                Text(
                  salMin != null && salMax != null
                      ? '${_fmt(salMin)} – ${_fmt(salMax)} GNF'
                      : salMin != null
                          ? 'À partir de ${_fmt(salMin)} GNF'
                          : 'Jusqu\'à ${_fmt(salMax!)} GNF',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981))),

              const Spacer(),

              // Compétences
              if (comps.isNotEmpty)
                Wrap(spacing: 4, children:
                  comps.take(3).map((c) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(100)),
                    child: Text(c, style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A56DB))))).toList()),
            ])))));
  }

  Widget _initiale(String nom) => Center(child: Text(
    nom.isNotEmpty ? nom[0].toUpperCase() : '?',
    style: GoogleFonts.poppins(
      fontSize: 18, fontWeight: FontWeight.w700,
      color: const Color(0xFF1A56DB))));

  bool _isNouveau(String? d) {
    if (d == null) return false;
    try {
      return DateTime.now()
        .difference(DateTime.parse(d)).inHours < 24;
    } catch (_) { return false; }
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]} ');
}

// ── Carte offre liste ─────────────────────────────────────
class _CarteOffreListe extends StatelessWidget {
  final Map<String, dynamic> offre;
  const _CarteOffreListe({required this.offre});

  @override
  Widget build(BuildContext context) {
    final o          = offre;
    final entreprise = o['entreprise'] as Map<String, dynamic>?;
    final logo       = entreprise?['logo_url'] as String?;
    final nomEnt     = entreprise?['nom_entreprise']
        as String? ?? '';
    final titre      = o['titre']        as String? ?? '';
    final contrat    = o['type_contrat'] as String? ?? '';
    final lieu       = o['localisation'] as String? ?? '';
    final desc       = o['description']  as String? ?? '';

    return GestureDetector(
      onTap: () => context.push('/offres/${o['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6, offset: const Offset(0, 2))]),
        child: Row(children: [
          // Logo
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF1A56DB).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12)),
            child: logo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(logo, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          nomEnt.isNotEmpty ? nomEnt[0] : '?',
                          style: GoogleFonts.poppins(
                            fontSize: 20, fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A56DB))))))
                : Center(child: Text(
                    nomEnt.isNotEmpty ? nomEnt[0] : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A56DB))))),
          const SizedBox(width: 14),

          // Infos
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(titre, style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Text(nomEnt, style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFF64748B))),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              _InfoBadge(Icons.location_on_outlined,
                lieu, const Color(0xFF64748B)),
              _InfoBadge(Icons.work_outline_rounded,
                contrat, const Color(0xFF1A56DB)),
            ]),
            const SizedBox(height: 6),
            Text(desc, style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFF94A3B8)),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),

          // Flèche
          const Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: Color(0xFFCBD5E1)),
        ])));
  }
}

// ── Filtre chip ───────────────────────────────────────────
class _FiltreChip extends StatelessWidget {
  final String label; final bool isActive;
  final VoidCallback onTap;
  const _FiltreChip({required this.label,
    required this.isActive, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF1A56DB)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isActive
              ? const Color(0xFF1A56DB)
              : const Color(0xFFE2E8F0))),
      child: Text(label, style: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: isActive ? Colors.white
            : const Color(0xFF374151)))));
}

// ── Info badge ────────────────────────────────────────────
class _InfoBadge extends StatelessWidget {
  final IconData icone; final String texte; final Color c;
  const _InfoBadge(this.icone, this.texte, this.c);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min, children: [
    Icon(icone, size: 12, color: c),
    const SizedBox(width: 4),
    Text(texte, style: GoogleFonts.inter(
      fontSize: 11, color: c)),
  ]);
}
```

---

## 2. Page À propos

### Migration SQL

```sql
-- Supabase SQL Editor
CREATE TABLE IF NOT EXISTS page_a_propos (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  section     TEXT NOT NULL UNIQUE,
  titre       TEXT,
  contenu     TEXT,
  icone       TEXT,
  ordre       INTEGER DEFAULT 0,
  est_actif   BOOLEAN DEFAULT TRUE,
  meta_donnees JSONB
);

-- Insérer les sections par défaut
INSERT INTO page_a_propos (section, titre, contenu, icone, ordre)
VALUES
  ('hero',    'À propos d''EmploiConnect',
   'La première plateforme intelligente de l''emploi en Guinée, '
   'connectant les talents aux meilleures opportunités.',
   '🏢', 1),
  ('mission', 'Notre Mission',
   'EmploiConnect a pour mission de révolutionner le marché '
   'de l''emploi en Guinée en utilisant l''intelligence '
   'artificielle pour connecter efficacement les candidats '
   'qualifiés aux entreprises qui recrutent.',
   '🎯', 2),
  ('vision',  'Notre Vision',
   'Devenir la référence incontournable de l''emploi en '
   'Afrique de l''Ouest, en offrant une plateforme '
   'technologique qui valorise les talents locaux.',
   '🔭', 3),
  ('valeurs', 'Nos Valeurs',
   'Innovation · Excellence · Intégrité · Inclusion · Impact',
   '💎', 4),
  ('equipe',  'Notre Équipe',
   'Fondée par des professionnels guinéens passionnés, '
   'notre équipe combine expertise technologique et '
   'connaissance approfondie du marché local.',
   '👥', 5),
  ('contact', 'Nous Contacter',
   'Conakry, Guinée · contact@emploiconnect.gn · +224 XX XX XX XX',
   '📞', 6)
ON CONFLICT (section) DO NOTHING;
```

### Backend — Routes À propos

```javascript
// backend/src/routes/apropos.routes.js

const express = require('express');
const router  = express.Router();

// GET /api/apropos — Public
router.get('/', async (req, res) => {
  try {
    const { data } = await supabase
      .from('page_a_propos')
      .select('*')
      .eq('est_actif', true)
      .order('ordre', { ascending: true });
    return res.json({ success: true, data: data || [] });
  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});

// PUT /api/admin/apropos/:id — Admin
router.put('/:id', auth, requireAdmin, async (req, res) => {
  try {
    const { titre, contenu, icone, est_actif } = req.body;
    const { data, error } = await supabase
      .from('page_a_propos')
      .update({ titre, contenu, icone, est_actif })
      .eq('id', req.params.id)
      .select()
      .single();
    if (error) throw error;
    return res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});

module.exports = router;
```

### Flutter — Page À propos

```dart
// frontend/lib/screens/about/about_page.dart

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});
  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  List<Map<String, dynamic>> _sections = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/apropos'));
      final body = jsonDecode(res.body);
      setState(() {
        _sections = List<Map<String, dynamic>>.from(
          body['data'] ?? []);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? _section(String s) =>
    _sections.where((x) => x['section'] == s)
      .firstOrNull;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final hero = _section('hero');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(
              color: Color(0xFF1A56DB)))
          : CustomScrollView(slivers: [

          // ── Header ─────────────────────────────
          SliverAppBar(
            pinned: true, elevation: 0,
            backgroundColor: Colors.white,
            toolbarHeight: 64,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                color: Color(0xFF374151)),
              onPressed: () => context.go('/')),
            title: const AuthLogoHeader()),

          // ── Hero ───────────────────────────────
          SliverToBoxAdapter(child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 80,
              vertical: isMobile ? 48 : 80),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A56DB), Color(0xFF4F46E5)])),
            child: Column(children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle),
                child: Center(child: Text(
                  hero?['icone'] as String? ?? '🏢',
                  style: const TextStyle(fontSize: 40)))),
              const SizedBox(height: 20),
              Text(
                hero?['titre'] as String?
                    ?? 'À propos d\'EmploiConnect',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 28 : 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1),
                textAlign: TextAlign.center),
              const SizedBox(height: 14),
              Text(
                hero?['contenu'] as String? ?? '',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 14 : 17,
                  color: Colors.white.withOpacity(0.8),
                  height: 1.6),
                textAlign: TextAlign.center),
            ]))),

          // ── Sections ───────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 80,
              vertical: 60),
            child: Column(children: [

            // Mission + Vision côte à côte (desktop)
            isMobile
                ? Column(children: [
                    _buildSection('mission'),
                    const SizedBox(height: 20),
                    _buildSection('vision'),
                  ])
                : Row(children: [
                    Expanded(child: _buildSection('mission')),
                    const SizedBox(width: 20),
                    Expanded(child: _buildSection('vision')),
                  ]),
            const SizedBox(height: 20),

            // Valeurs pleine largeur
            _buildSection('valeurs', pleineLargeur: true),
            const SizedBox(height: 20),

            // Équipe
            _buildSection('equipe', pleineLargeur: true),
            const SizedBox(height: 20),

            // Stats de la plateforme
            _buildStats(isMobile),
            const SizedBox(height: 20),

            // Contact
            _buildContact(),
          ]))),

          // Footer
          SliverToBoxAdapter(child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 60, vertical: 20),
            color: const Color(0xFF0D1B3E),
            child: Text('© 2025 EmploiConnect · Guinée',
              style: GoogleFonts.inter(
                fontSize: 12, color: Colors.white38),
              textAlign: TextAlign.center))),
        ]));
  }

  Widget _buildSection(String section,
      {bool pleineLargeur = false}) {
    final s = _section(section);
    if (s == null) return const SizedBox();
    return Container(
      width: pleineLargeur ? double.infinity : null,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(children: [
          Text(s['icone'] as String? ?? '📌',
            style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(child: Text(
            s['titre'] as String? ?? '',
            style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A)))),
        ]),
        const SizedBox(height: 12),
        Text(s['contenu'] as String? ?? '',
          style: GoogleFonts.inter(
            fontSize: 14, color: const Color(0xFF64748B),
            height: 1.7)),
      ]));
  }

  Widget _buildStats(bool isMobile) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1A56DB), Color(0xFF4F46E5)]),
      borderRadius: BorderRadius.circular(16)),
    child: Column(children: [
      Text('EmploiConnect en chiffres',
        style: GoogleFonts.poppins(
          fontSize: 20, fontWeight: FontWeight.w800,
          color: Colors.white),
        textAlign: TextAlign.center),
      const SizedBox(height: 24),
      Wrap(
        spacing: 24, runSpacing: 16,
        alignment: WrapAlignment.center,
        children: [
        _StatAbout('🏢', '500+', 'Entreprises'),
        _StatAbout('👥', '2000+', 'Candidats'),
        _StatAbout('💼', '150+', 'Offres actives'),
        _StatAbout('⭐', '98%', 'Satisfaction'),
      ]),
    ]));

  Widget _buildContact() {
    final s = _section('contact');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1A56DB).withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(children: [
          Text(s?['icone'] as String? ?? '📞',
            style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Text(s?['titre'] as String? ?? 'Contact',
            style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A))),
        ]),
        const SizedBox(height: 12),
        Text(s?['contenu'] as String? ?? '',
          style: GoogleFonts.inter(
            fontSize: 14, color: const Color(0xFF64748B),
            height: 1.7)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.email_outlined, size: 16),
          label: const Text('Nous écrire'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10))),
          onPressed: () {}),
      ]));
  }
}

class _StatAbout extends StatelessWidget {
  final String emoji, val, label;
  const _StatAbout(this.emoji, this.val, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 28)),
    Text(val, style: GoogleFonts.poppins(
      fontSize: 28, fontWeight: FontWeight.w900,
      color: Colors.white)),
    Text(label, style: GoogleFonts.inter(
      fontSize: 12, color: Colors.white60)),
  ]);
}
```

### Admin — Gestion page À propos

```dart
// Dans admin settings ou page dédiée
// frontend/lib/screens/admin/pages/apropos_admin_page.dart

class AProposAdminPage extends StatefulWidget {
  const AProposAdminPage({super.key});
  @override
  State<AProposAdminPage> createState() =>
    _AProposAdminState();
}

class _AProposAdminState extends State<AProposAdminPage> {
  List<Map<String, dynamic>> _sections = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  @override
  Widget build(BuildContext context) => Column(children: [
    // Header
    Padding(
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text('Page "À propos"', style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w800)),
          Text('Personnalisez les sections de la page',
            style: GoogleFonts.inter(
              fontSize: 13, color: const Color(0xFF64748B))),
        ])),
        OutlinedButton.icon(
          icon: const Icon(Icons.visibility_rounded, size: 14),
          label: const Text('Voir la page'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(
              color: Color(0xFF1A56DB)),
            foregroundColor: const Color(0xFF1A56DB)),
          onPressed: () => context.push('/a-propos')),
      ])),

    Expanded(child: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _sections.length,
            itemBuilder: (ctx, i) => _SectionCard(
              section: _sections[i],
              onSaved: _load))),
  ]);

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/apropos'),
        headers: {'Authorization': 'Bearer $token'});
      final body = jsonDecode(res.body);
      setState(() {
        _sections = List<Map<String, dynamic>>.from(
          body['data'] ?? []);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }
}

class _SectionCard extends StatefulWidget {
  final Map<String, dynamic> section;
  final VoidCallback onSaved;
  const _SectionCard({required this.section,
    required this.onSaved});
  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _expanded = false;
  late TextEditingController _titreCtrl;
  late TextEditingController _contenuCtrl;
  late TextEditingController _iconeCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titreCtrl   = TextEditingController(
      text: widget.section['titre']   as String? ?? '');
    _contenuCtrl = TextEditingController(
      text: widget.section['contenu'] as String? ?? '');
    _iconeCtrl   = TextEditingController(
      text: widget.section['icone']   as String? ?? '');
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _contenuCtrl.dispose();
    _iconeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Column(children: [
      // Header carte
      GestureDetector(
        onTap: () =>
          setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Text(widget.section['icone'] as String? ?? '📌',
              style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(child: Text(
              widget.section['titre'] as String? ?? '',
              style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w700))),
            Icon(_expanded
                ? Icons.expand_less_rounded
                : Icons.expand_more_rounded,
              color: const Color(0xFF94A3B8)),
          ]))),

      // Formulaire édition
      if (_expanded) Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          // Icône
          Row(children: [
            Expanded(child: _champAdmin(
              _iconeCtrl, 'Icône (emoji)', '🎯')),
            const SizedBox(width: 10),
            // Preview
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(
                _iconeCtrl.text.isEmpty
                    ? '?' : _iconeCtrl.text,
                style: const TextStyle(fontSize: 24)))),
          ]),
          const SizedBox(height: 10),
          _champAdmin(_titreCtrl, 'Titre', 'Ex: Notre Mission'),
          const SizedBox(height: 10),
          _champAdmin(_contenuCtrl, 'Contenu',
            'Texte de la section...', maxLines: 5),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isSaving
                  ? const SizedBox(width: 12, height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 14),
              label: Text(
                _isSaving ? 'Sauvegarde...' : 'Sauvegarder',
                style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
              onPressed: _isSaving ? null : _sauvegarder)),
        ]));
    ]));

  Widget _champAdmin(TextEditingController ctrl,
      String label, String hint, {int maxLines = 1}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      Text(label, style: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w600,
        color: const Color(0xFF374151))),
      const SizedBox(height: 5),
      TextFormField(
        controller: ctrl,
        maxLines:   maxLines,
        onChanged:  (v) {
          if (label.contains('Icône')) setState(() {});
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 12, color: const Color(0xFFCBD5E1)),
          filled: true, fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0))))),
    ]);

  Future<void> _sauvegarder() async {
    setState(() => _isSaving = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res   = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/apropos/'
          '${widget.section['id']}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'titre':   _titreCtrl.text.trim(),
          'contenu': _contenuCtrl.text.trim(),
          'icone':   _iconeCtrl.text.trim(),
        }));
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Section sauvegardée !'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating));
        widget.onSaved();
        setState(() => _expanded = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
```

---

## 3. Newsletter

### Migration SQL

```sql
-- Supabase SQL Editor
CREATE TABLE IF NOT EXISTS newsletter_abonnes (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email         TEXT NOT NULL UNIQUE,
  nom           TEXT,
  est_actif     BOOLEAN DEFAULT TRUE,
  date_inscription TIMESTAMPTZ DEFAULT NOW(),
  source        TEXT DEFAULT 'footer',
  token_desabo  TEXT DEFAULT gen_random_uuid()::TEXT
);

-- Index
CREATE INDEX IF NOT EXISTS idx_newsletter_email
  ON newsletter_abonnes(email);
CREATE INDEX IF NOT EXISTS idx_newsletter_actif
  ON newsletter_abonnes(est_actif);

-- Paramètres newsletter
INSERT INTO parametres_plateforme (cle, valeur, type_valeur, description, categorie)
VALUES
  ('newsletter_actif',       'true',  'boolean',
   'Activer l''inscription newsletter', 'email'),
  ('newsletter_sujet_defaut', 'Nouvelles offres EmploiConnect', 'string',
   'Sujet par défaut des newsletters', 'email'),
  ('newsletter_nb_abonnes',  '0', 'string',
   'Nombre d''abonnés (cache)', 'email')
ON CONFLICT (cle) DO NOTHING;
```

### Backend — Routes newsletter

```javascript
// backend/src/routes/newsletter.routes.js

const express = require('express');
const router  = express.Router();

// POST /api/newsletter/subscribe — Public
router.post('/subscribe', async (req, res) => {
  try {
    const { email, nom } = req.body;

    if (!email || !email.includes('@')) {
      return res.status(400).json({
        success: false,
        message: 'Email invalide'
      });
    }

    // Vérifier que newsletter est actif
    const { data: param } = await supabase
      .from('parametres_plateforme')
      .select('valeur')
      .eq('cle', 'newsletter_actif')
      .single();

    if (param?.valeur === 'false') {
      return res.status(403).json({
        success: false,
        message: 'Newsletter non disponible'
      });
    }

    // Insérer ou réactiver
    const { data: existing } = await supabase
      .from('newsletter_abonnes')
      .select('id, est_actif')
      .eq('email', email.toLowerCase().trim())
      .single();

    if (existing) {
      if (existing.est_actif) {
        return res.json({
          success: true,
          message: 'Vous êtes déjà abonné à notre newsletter !',
          deja_abonne: true,
        });
      }
      // Réactiver
      await supabase.from('newsletter_abonnes')
        .update({ est_actif: true, nom })
        .eq('id', existing.id);
    } else {
      // Nouvel abonné
      await supabase.from('newsletter_abonnes').insert({
        email:  email.toLowerCase().trim(),
        nom:    nom || null,
        source: req.body.source || 'footer',
      });
    }

    // Envoyer email de confirmation
    await _envoyerConfirmation(email, nom);

    console.log('[newsletter] ✅ Nouvel abonné:', email);

    return res.json({
      success: true,
      message: 'Inscription réussie ! Merci de vous abonner.',
    });

  } catch (err) {
    if (err.code === '23505') {
      return res.json({
        success: true,
        message: 'Vous êtes déjà abonné à notre newsletter !',
        deja_abonne: true,
      });
    }
    res.status(500).json({
      success: false, message: err.message });
  }
});

// GET /api/newsletter/unsubscribe?token=xxx — Public
router.get('/unsubscribe', async (req, res) => {
  try {
    const { token } = req.query;
    if (!token) {
      return res.status(400).json({
        success: false, message: 'Token manquant' });
    }
    await supabase.from('newsletter_abonnes')
      .update({ est_actif: false })
      .eq('token_desabo', token);
    return res.json({
      success: true,
      message: 'Désinscription effectuée avec succès.'
    });
  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});

// GET /api/admin/newsletter — Admin
router.get('/admin', auth, requireAdmin, async (req, res) => {
  try {
    const { data, count } = await supabase
      .from('newsletter_abonnes')
      .select('*', { count: 'exact' })
      .eq('est_actif', true)
      .order('date_inscription', { ascending: false });
    return res.json({
      success: true,
      data: { abonnes: data || [], total: count || 0 }
    });
  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});

// POST /api/admin/newsletter/envoyer — Admin
router.post('/admin/envoyer', auth, requireAdmin,
  async (req, res) => {
  try {
    const { sujet, contenu } = req.body;

    const { data: abonnes } = await supabase
      .from('newsletter_abonnes')
      .select('email, nom, token_desabo')
      .eq('est_actif', true);

    if (!abonnes?.length) {
      return res.json({
        success: false,
        message: 'Aucun abonné actif'
      });
    }

    // Envoyer via le service email existant
    let nbEnvois = 0;
    for (const ab of abonnes) {
      try {
        await envoyerEmail({
          to:      ab.email,
          subject: sujet,
          html:    `
            <div style="font-family: sans-serif; max-width: 600px;">
              <h2 style="color: #1A56DB;">EmploiConnect</h2>
              ${contenu}
              <hr />
              <p style="color: #94A3B8; font-size: 12px;">
                <a href="${process.env.APP_URL}/api/newsletter/unsubscribe?token=${ab.token_desabo}">
                  Se désabonner
                </a>
              </p>
            </div>`,
        });
        nbEnvois++;
      } catch (_) {}
    }

    return res.json({
      success: true,
      message: `Newsletter envoyée à ${nbEnvois} abonnés ✅`,
      nb_envois: nbEnvois,
    });
  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});

async function _envoyerConfirmation(email, nom) {
  try {
    await envoyerEmail({
      to:      email,
      subject: '✅ Bienvenue dans la newsletter EmploiConnect !',
      html: `
        <div style="font-family: sans-serif; max-width: 600px;">
          <h2 style="color: #1A56DB;">🎉 Bienvenue${nom ? ` ${nom}` : ''} !</h2>
          <p>Vous êtes maintenant abonné à la newsletter EmploiConnect.</p>
          <p>Vous recevrez :</p>
          <ul>
            <li>Les nouvelles offres d'emploi en Guinée</li>
            <li>Les tendances du marché de l'emploi</li>
            <li>Des conseils pour booster votre carrière</li>
          </ul>
          <a href="${process.env.APP_URL}/offres"
             style="background: #1A56DB; color: white;
                    padding: 12px 24px; text-decoration: none;
                    border-radius: 8px; display: inline-block;">
            Voir les offres →
          </a>
        </div>`,
    });
  } catch (e) {
    console.warn('[newsletter] Email confirmation:', e.message);
  }
}

module.exports = router;
```

### Flutter — Widget newsletter dans le footer

```dart
// Dans footer_widget.dart
// Remplacer la section "Rester connecté"

Widget _buildNewsletter() => Container(
  padding: const EdgeInsets.all(24),
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.06),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: Colors.white.withOpacity(0.1))),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(children: [
      const Icon(Icons.email_outlined,
        color: Color(0xFF1A56DB), size: 20),
      const SizedBox(width: 8),
      Text('Restez informé !',
        style: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w700,
          color: Colors.white)),
    ]),
    const SizedBox(height: 6),
    Text(
      'Recevez les nouvelles offres et les tendances '
      'du marché de l\'emploi en Guinée.',
      style: GoogleFonts.inter(
        fontSize: 12, color: Colors.white60, height: 1.5)),
    const SizedBox(height: 14),
    _NewsletterForm(),
  ]));

class _NewsletterForm extends StatefulWidget {
  @override
  State<_NewsletterForm> createState() => _NewsletterFormState();
}

class _NewsletterFormState extends State<_NewsletterForm> {
  final _emailCtrl = TextEditingController();
  bool  _isLoading = false;
  bool  _succes    = false;
  String? _message;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_succes) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.15),
          borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          const Icon(Icons.check_circle_rounded,
            color: Color(0xFF10B981), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(
            _message ?? 'Inscription réussie ! ✅',
            style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFF10B981),
              fontWeight: FontWeight.w600))),
        ]));
    }

    return Row(children: [
      Expanded(child: TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        style: GoogleFonts.inter(
          fontSize: 13, color: Colors.white),
        decoration: InputDecoration(
          hintText: 'votre@email.com',
          hintStyle: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white.withOpacity(0.4)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.2))),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.2))),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color(0xFF1A56DB), width: 1.5))),
        onSubmitted: (_) => _sInscrire())),
      const SizedBox(width: 8),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A56DB),
          foregroundColor: Colors.white, elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8))),
        onPressed: _isLoading ? null : _sInscrire,
        child: _isLoading
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
            : Text('S\'abonner',
                style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w700))),
    ]);
  }

  Future<void> _sInscrire() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@')) {
      setState(() => _message = 'Email invalide');
      return;
    }
    setState(() { _isLoading = true; _message = null; });
    try {
      final res = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/newsletter/subscribe'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({ 'email': email }));
      final body = jsonDecode(res.body);
      setState(() {
        _succes  = body['success'] == true;
        _message = body['message'];
      });
    } catch (_) {
      setState(() => _message = 'Erreur. Réessayez.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
```

### Admin — Gestion newsletter

```dart
// Dans admin menu → ajouter "Newsletter"
// Page : frontend/lib/screens/admin/pages/newsletter_page.dart

// Afficher :
// → Nombre d'abonnés actifs
// → Liste des abonnés (email + date)
// → Formulaire envoi newsletter
// → Toggle activer/désactiver

// Résumé fonctionnel :
// GET /api/admin/newsletter → liste abonnés
// POST /api/admin/newsletter/envoyer → envoyer newsletter
```

---

## Ajouter les routes dans index.js

```javascript
// backend/src/routes/index.js
const aproposRoutes     = require('./apropos.routes');
const newsletterRoutes  = require('./newsletter.routes');

router.use('/apropos',     aproposRoutes);
router.use('/newsletter',  newsletterRoutes);

// Routes admin newsletter
router.use('/admin/newsletter', requireAdmin, newsletterRoutes);
```

## Ajouter les routes Flutter dans main.dart / router

```dart
// Ajouter :
GoRoute(path: '/a-propos',
  builder: (_, __) => const AboutPage()),
GoRoute(path: '/offres',
  builder: (_, __) => const OffresPage()),
```

## Fixer le lien "À propos" dans le header

```dart
// Dans home_header_widget.dart
// Remplacer le popup par une navigation :

// AVANT ❌
_NavItem('À propos', () => _showPopupAPropos()),

// APRÈS ✅
_NavItem('À propos', () => context.push('/a-propos')),
```

---

## Critères d'Acceptation

### Page Offres
- [ ] Barre de recherche fonctionnelle
- [ ] Filtres (CDI, CDD, Stage, Ville)
- [ ] Vue grille / liste
- [ ] Cards avec logo entreprise + infos
- [ ] Badge "Nouveau" si < 24h
- [ ] Pagination infinie au scroll
- [ ] État vide avec bouton réinitialiser

### Page À propos
- [ ] Accessible via `/a-propos` (pas de popup)
- [ ] Sections configurables depuis l'admin
- [ ] Admin peut modifier titre + contenu + icône
- [ ] Stats dynamiques affichées
- [ ] Section contact avec bouton

### Newsletter
- [ ] Formulaire dans le footer fonctionnel
- [ ] Email de confirmation envoyé
- [ ] Admin voit la liste des abonnés
- [ ] Admin peut envoyer une newsletter
- [ ] Désinscription via lien dans l'email

---

*PRD EmploiConnect v9.5 — Offres + À propos + Newsletter*
*Cursor / Kirsoft AI — Phase 28*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
