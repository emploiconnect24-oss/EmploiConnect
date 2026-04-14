import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/public_routes.dart';
import '../../core/theme/theme_extension.dart';
import '../../screens/auth/auth_widgets.dart';
import '../../services/offres_service.dart';

/// Liste publique offres — vitrine (PRD §1).
class OffresPage extends StatefulWidget {
  const OffresPage({
    super.key,
    this.initialSearch,
    this.entrepriseId,
    this.entrepriseNom,
  });

  final String? initialSearch;
  final String? entrepriseId;
  final String? entrepriseNom;

  @override
  State<OffresPage> createState() => _OffresPageState();
}

class _OffresPageState extends State<OffresPage> {
  final _svc = OffresService();
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<Map<String, dynamic>> _offres = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _page = 1;
  int _totalPages = 1;
  int _total = 0;
  String _recherche = '';
  String? _typeContrat;
  String? _ville;
  String _vue = 'grille';

  static const _limit = 12;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null && widget.initialSearch!.trim().isNotEmpty) {
      _searchCtrl.text = widget.initialSearch!.trim();
      _recherche = widget.initialSearch!.trim();
    }
    _charger();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _page < _totalPages) {
      _chargerPlus();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _page = 1;
      });
    }
    final eid = widget.entrepriseId?.trim();
    try {
      final r = await _svc.getOffresPublic(
        page: _page,
        limit: _limit,
        q: _recherche.isEmpty ? null : _recherche,
        typeContrat: _typeContrat,
        ville: _ville,
        entrepriseId: (eid == null || eid.isEmpty) ? null : eid,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _offres = List<Map<String, dynamic>>.from(r.offres);
        } else {
          _offres.addAll(r.offres);
        }
        _total = r.total;
        _totalPages = r.totalPages;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _chargerPlus() async {
    if (_isLoadingMore || _page >= _totalPages) return;
    setState(() {
      _isLoadingMore = true;
      _page += 1;
    });
    await _charger(reset: false);
  }

  List<String> _skills(dynamic v) {
    if (v == null) return [];
    if (v is List) {
      return v.map((e) => e is String ? e : e.toString()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  /// Grille desktop (cartes larges) vs mobile (2 colonnes plus hautes, ou 1 si très étroit).
  SliverGridDelegate _gridDelegateOffres(bool isMobile, double width) {
    if (!isMobile) {
      return SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.45,
      );
    }
    if (width < 360) {
      return const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.58,
      );
    }
    return const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.78,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final nomEnt = widget.entrepriseNom?.trim();
    final cs = Theme.of(context).colorScheme;
    final ext = context.themeExt;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: cs.surface,
            toolbarHeight: 64,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: cs.surface,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/'),
                      child: AuthLogoHeader(couleurTexte: cs.onSurface),
                    ),
                    const Spacer(),
                    if (!isMobile) ...[
                      TextButton(
                        onPressed: () => Navigator.of(context).pushNamed('/landing'),
                        child: Text('Accueil', style: TextStyle(color: cs.onSurfaceVariant)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushNamed('/public/offres'),
                        child: Text('Offres', style: TextStyle(color: cs.onSurfaceVariant)),
                      ),
                    ],
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A56DB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.of(context).pushNamed('/login'),
                      child: Text(
                        'Se connecter',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 60, vertical: isMobile ? 32 : 48),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A56DB), Color(0xFF4F46E5)],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    (nomEnt != null && nomEnt.isNotEmpty) ? 'Offres — $nomEnt' : 'Offres d\'emploi en Guinée',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 24 : 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_total offre${_total > 1 ? 's' : ''} disponible${_total > 1 ? 's' : ''}',
                    style: GoogleFonts.inter(fontSize: 15, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: 'Titre du poste, compétence, entreprise...',
                              hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFCBD5E1)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onSubmitted: (v) {
                              setState(() => _recherche = v.trim());
                              _charger();
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A56DB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              setState(() => _recherche = _searchCtrl.text.trim());
                              _charger();
                            },
                            child: Text('Rechercher', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 60, vertical: 16),
              color: cs.surface,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _FiltreChip(
                                label: 'Tout',
                                isActive: _typeContrat == null,
                                onTap: () {
                                  setState(() => _typeContrat = null);
                                  _charger();
                                },
                              ),
                              _FiltreChip(
                                label: 'CDI',
                                isActive: _typeContrat == 'CDI',
                                onTap: () {
                                  setState(() => _typeContrat = 'CDI');
                                  _charger();
                                },
                              ),
                              _FiltreChip(
                                label: 'CDD',
                                isActive: _typeContrat == 'CDD',
                                onTap: () {
                                  setState(() => _typeContrat = 'CDD');
                                  _charger();
                                },
                              ),
                              _FiltreChip(
                                label: 'Stage',
                                isActive: _typeContrat == 'Stage',
                                onTap: () {
                                  setState(() => _typeContrat = 'Stage');
                                  _charger();
                                },
                              ),
                              _FiltreChip(
                                label: 'Freelance',
                                isActive: _typeContrat == 'Freelance',
                                onTap: () {
                                  setState(() => _typeContrat = 'Freelance');
                                  _charger();
                                },
                              ),
                              _FiltreChip(
                                label: 'Conakry',
                                isActive: _ville == 'Conakry',
                                onTap: () {
                                  setState(() => _ville = _ville == 'Conakry' ? null : 'Conakry');
                                  _charger();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _vue = 'grille'),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _vue == 'grille' ? cs.primary : ext.sectionBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.grid_view_rounded,
                                size: 16,
                                color: _vue == 'grille' ? Colors.white : cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(() => _vue = 'liste'),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _vue == 'liste' ? cs.primary : ext.sectionBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.list_rounded,
                                size: 16,
                                color: _vue == 'liste' ? Colors.white : cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: Divider(height: 1, color: ext.cardBorder)),
          if (_isLoading)
            SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: cs.primary)),
            )
          else if (_offres.isEmpty)
            SliverFillRemaining(child: _buildVide())
          else if (_vue == 'grille')
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 60,
                vertical: isMobile ? 16 : 24,
              ),
              sliver: SliverGrid(
                gridDelegate: _gridDelegateOffres(isMobile, MediaQuery.sizeOf(context).width),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _CarteOffreGrille(
                    offre: _offres[i],
                    skillsParser: _skills,
                    compact: isMobile,
                  ),
                  childCount: _offres.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 60, vertical: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _CarteOffreListe(offre: _offres[i]),
                  childCount: _offres.length,
                ),
              ),
            ),
          if (_isLoadingMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator(color: cs.primary)),
              ),
            ),
          SliverToBoxAdapter(child: _buildFooterCompact(context)),
        ],
      ),
    );
  }

  Widget _buildVide() {
    final cs = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off_outlined, color: ext.cardBorder, size: 64),
            const SizedBox(height: 16),
            Text(
              'Aucune offre trouvée',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez avec d\'autres critères de recherche',
              style: GoogleFonts.inter(fontSize: 14, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                _searchCtrl.clear();
                setState(() {
                  _recherche = '';
                  _typeContrat = null;
                  _ville = null;
                });
                _charger();
              },
              child: const Text('Réinitialiser les filtres'),
            ),
          ],
        ),
      );
  }

  Widget _buildFooterCompact(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        color: const Color(0xFF0D1B3E),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '© 2026 EmploiConnect · Guinée',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/landing'),
              child: Text(
                'Retour à l\'accueil',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF60A5FA)),
              ),
            ),
          ],
        ),
      );
}

class _FiltreChip extends StatelessWidget {
  const _FiltreChip({required this.label, required this.isActive, required this.onTap});
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    return GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? cs.primary : ext.sectionBg,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: isActive ? cs.primary : ext.cardBorder),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : cs.onSurface,
            ),
          ),
        ),
      );
  }
}

class _CarteOffreGrille extends StatefulWidget {
  const _CarteOffreGrille({
    required this.offre,
    required this.skillsParser,
    this.compact = false,
  });

  final Map<String, dynamic> offre;
  final List<String> Function(dynamic) skillsParser;
  /// Réduit padding / typo et supprime l’expansion verticale (évite overflow grille mobile).
  final bool compact;

  @override
  State<_CarteOffreGrille> createState() => _CarteOffreGrilleState();
}

class _CarteOffreGrilleState extends State<_CarteOffreGrille> {
  bool _hovered = false;

  int? _sal(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    final c = widget.compact;
    final o = widget.offre;
    final entreprise = o['entreprise'] as Map<String, dynamic>?;
    final logo = entreprise?['logo_url'] as String?;
    final nomEnt = entreprise?['nom_entreprise'] as String? ?? 'Entreprise';
    final titre = o['titre'] as String? ?? '';
    final contrat = o['type_contrat'] as String? ?? '';
    final lieu = o['localisation'] as String? ?? 'Guinée';
    final salMin = _sal(o['salaire_min']);
    final salMax = _sal(o['salaire_max']);
    final comps = widget.skillsParser(o['competences_requises']).take(c ? 2 : 3).toList();
    final date = o['date_publication'] as String?;
    final isNouveau = _isNouveau(date);

    final logoSize = c ? 36.0 : 44.0;
    final logoRad = c ? 8.0 : 10.0;
    final pad = c ? 12.0 : 18.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed(PublicRoutes.offre('${o['id']}')),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, _hovered ? -4.0 : 0.0, 0),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? cs.primary.withValues(alpha: 0.35) : ext.cardBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered ? const Color(0xFF1A56DB).withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.04),
                blurRadius: _hovered ? 20 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(pad),
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(logoRad),
                        ),
                        child: logo != null && logo.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(logoRad),
                                child: Image.network(
                                  logo,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => _initiale(nomEnt, compact: c),
                                ),
                              )
                            : _initiale(nomEnt, compact: c),
                      ),
                      SizedBox(width: c ? 8 : 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              nomEnt,
                              style: GoogleFonts.inter(
                                fontSize: c ? 10 : 11,
                                color: cs.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              titre,
                              style: GoogleFonts.inter(
                                fontSize: c ? 13 : 14,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                              maxLines: c ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isNouveau)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: c ? 5 : 7,
                            vertical: c ? 2 : 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'Nouveau',
                            style: GoogleFonts.inter(
                              fontSize: c ? 8 : 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: c ? 8 : 12),
                  Wrap(
                    spacing: c ? 4 : 6,
                    runSpacing: c ? 4 : 6,
                    children: [
                      _InfoBadge(Icons.location_on_outlined, lieu, cs.onSurfaceVariant, compact: c),
                      _InfoBadge(Icons.work_outline_rounded, contrat, cs.primary, compact: c),
                    ],
                  ),
                  if (salMin != null || salMax != null) ...[
                    SizedBox(height: c ? 6 : 10),
                    Text(
                      salMin != null && salMax != null
                          ? '${_fmt(salMin)} – ${_fmt(salMax)} GNF'
                          : salMin != null
                              ? 'À partir de ${_fmt(salMin)} GNF'
                              : 'Jusqu\'à ${_fmt(salMax!)} GNF',
                      style: GoogleFonts.inter(
                        fontSize: c ? 11 : 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: c ? 6 : 8),
                  if (comps.isNotEmpty)
                    Wrap(
                      spacing: c ? 3 : 4,
                      runSpacing: c ? 3 : 4,
                      children: comps
                          .map(
                            (e) => Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: c ? 6 : 7,
                                vertical: c ? 2 : 3,
                              ),
                              decoration: BoxDecoration(
                                color: ext.infoBg,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                e,
                                style: GoogleFonts.inter(
                                  fontSize: c ? 8 : 9,
                                  fontWeight: FontWeight.w600,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _initiale(String nom, {required bool compact}) => Center(
        child: Text(
          nom.isNotEmpty ? nom[0].toUpperCase() : '?',
          style: GoogleFonts.poppins(
            fontSize: compact ? 14 : 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );

  bool _isNouveau(String? d) {
    if (d == null) return false;
    try {
      return DateTime.now().difference(DateTime.parse(d)).inHours < 24;
    } catch (_) {
      return false;
    }
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]} ',
      );
}

class _CarteOffreListe extends StatelessWidget {
  const _CarteOffreListe({required this.offre});
  final Map<String, dynamic> offre;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    final o = offre;
    final entreprise = o['entreprise'] as Map<String, dynamic>?;
    final logo = entreprise?['logo_url'] as String?;
    final nomEnt = entreprise?['nom_entreprise'] as String? ?? '';
    final titre = o['titre'] as String? ?? '';
    final contrat = o['type_contrat'] as String? ?? '';
    final lieu = o['localisation'] as String? ?? '';
    final desc = o['description'] as String? ?? '';

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(PublicRoutes.offre('${o['id']}')),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ext.cardBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: logo != null && logo.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        logo,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Center(
                          child: Text(
                            nomEnt.isNotEmpty ? nomEnt[0] : '?',
                            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: cs.primary),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        nomEnt.isNotEmpty ? nomEnt[0] : '?',
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: cs.primary),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(nomEnt, style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      _InfoBadge(Icons.location_on_outlined, lieu, cs.onSurfaceVariant),
                      _InfoBadge(Icons.work_outline_rounded, contrat, cs.primary),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: cs.outline.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge(this.icone, this.texte, this.c, {this.compact = false});

  final IconData icone;
  final String texte;
  final Color c;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 11.0 : 12.0;
    final fontSize = compact ? 10.0 : 11.0;
    final maxText = compact ? 92.0 : 200.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: iconSize, color: c),
        SizedBox(width: compact ? 3 : 4),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxText),
          child: Text(
            texte,
            style: GoogleFonts.inter(fontSize: fontSize, color: c),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
