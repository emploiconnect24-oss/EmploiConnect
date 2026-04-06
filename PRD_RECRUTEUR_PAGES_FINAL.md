# PRD — EmploiConnect · Candidatures + Mes Offres + Talents Recruteur
## Product Requirements Document v5.4 — Design & Backend Complet
**Stack : Flutter + Node.js/Express + PostgreSQL/Supabase**
**Outil : Cursor / Kirsoft AI**
**Objectif : Design parfait + Backend solide — 3 pages recruteur**
**Date : Mars 2026**

---

> ### ⚠️ INSTRUCTIONS POUR CURSOR
> Ce PRD améliore le design ET le backend de 3 pages recruteur.
> Implémenter dans l'ordre : Backend → Flutter.
> Référencer PRD_BACKEND_RECRUTEUR.md pour les routes existantes.

---

## Table des Matières

1. [Backend — Export CSV Candidatures](#1-backend--export-csv-candidatures)
2. [Backend — Modification d'offre + Actions](#2-backend--modification-doffre--actions)
3. [Flutter — Page Candidatures redesign complet](#3-flutter--page-candidatures-redesign-complet)
4. [Flutter — Page Mes Offres redesign complet](#4-flutter--page-mes-offres-redesign-complet)
5. [Flutter — Page Détail Offre + Candidatures de l'offre](#5-flutter--page-détail-offre--candidatures-de-loffre)
6. [Flutter — Dialog Modifier Offre](#6-flutter--dialog-modifier-offre)
7. [Flutter — Page Recherche Talents redesign](#7-flutter--page-recherche-talents-redesign)
8. [Critères d'Acceptation](#8-critères-dacceptation)

---

## 1. Backend — Export CSV Candidatures

```javascript
// Dans backend/src/routes/recruteur/candidatures.routes.js
// Ajouter la route export CSV

router.get('/export/csv', async (req, res) => {
  try {
    const { offre_id, statut } = req.query;
    const entrepriseId = req.entreprise.id;

    // Mes offres
    const { data: mesOffres } = await supabase
      .from('offres_emploi')
      .select('id, titre')
      .eq('entreprise_id', entrepriseId);

    const mesOffresIds = (mesOffres || []).map(o => o.id);
    if (mesOffresIds.length === 0) {
      return res.json({ success: true, data: [] });
    }

    let filtreIds = mesOffresIds;
    if (offre_id && mesOffresIds.includes(offre_id)) {
      filtreIds = [offre_id];
    }

    let query = supabase
      .from('candidatures')
      .select(`
        id, statut, score_compatibilite, date_candidature,
        lettre_motivation,
        chercheur:chercheur_id (
          utilisateur:utilisateur_id (
            nom, email, telephone, adresse
          ),
          niveau_etude, disponibilite
        ),
        offre:offre_id ( titre ),
        cv:cv_id ( nom_fichier )
      `)
      .in('offre_id', filtreIds)
      .order('date_candidature', { ascending: false });

    if (statut && statut !== 'all') query = query.eq('statut', statut);

    const { data, error } = await query;
    if (error) throw error;

    // Construire le CSV
    const headers = [
      'ID Candidature',
      'Nom Candidat',
      'Email',
      'Téléphone',
      'Poste candidaté',
      'Statut',
      'Score IA (%)',
      'Niveau d\'étude',
      'Disponibilité',
      'Date candidature',
    ].join(',');

    const rows = (data || []).map(c => [
      `"${c.id}"`,
      `"${c.chercheur?.utilisateur?.nom || ''}"`,
      `"${c.chercheur?.utilisateur?.email || ''}"`,
      `"${c.chercheur?.utilisateur?.telephone || ''}"`,
      `"${c.offre?.titre || ''}"`,
      `"${_labelStatut(c.statut)}"`,
      c.score_compatibilite || '',
      `"${_labelNiveau(c.chercheur?.niveau_etude)}"`,
      `"${_labelDispo(c.chercheur?.disponibilite)}"`,
      `"${c.date_candidature?.split('T')[0] || ''}"`,
    ].join(','));

    const csv = [headers, ...rows].join('\n');

    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition',
      `attachment; filename="candidatures_${req.entreprise.nom_entreprise}_${new Date().toISOString().split('T')[0]}.csv"`);
    return res.send('\uFEFF' + csv); // BOM pour Excel

  } catch (err) {
    console.error('[export candidatures]', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});

// Helpers labels
const _labelStatut = (s) => {
  const map = {
    en_attente: 'En attente', en_cours: 'En examen',
    entretien: 'Entretien', acceptee: 'Acceptée',
    refusee: 'Refusée',
  };
  return map[s] || s || '';
};

const _labelNiveau = (n) => {
  const map = {
    bac: 'Bac', bac2: 'Bac+2', licence: 'Licence (Bac+3)',
    master: 'Master (Bac+5)', doctorat: 'Doctorat',
  };
  return map[n] || n || 'Non précisé';
};

const _labelDispo = (d) => {
  const map = {
    immediat: 'Disponible immédiatement',
    '1_mois': 'Dans 1 mois',
    '3_mois': 'Dans 3 mois',
  };
  return map[d] || d || 'Non précisé';
};
```

---

## 2. Backend — Modification d'offre + Actions

```javascript
// PATCH /api/recruteur/offres/:id — Modification complète

router.patch('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Vérifier propriété
    const { data: offre, error: findErr } = await supabase
      .from('offres_emploi')
      .select('id, statut, entreprise_id, titre')
      .eq('id', id)
      .single();

    if (findErr || !offre) {
      return res.status(404).json({
        success: false, message: 'Offre non trouvée'
      });
    }

    if (offre.entreprise_id !== req.entreprise.id) {
      return res.status(403).json({
        success: false,
        message: 'Vous ne pouvez modifier que vos propres offres'
      });
    }

    // Champs modifiables
    const champs = [
      'titre', 'description', 'exigences',
      'competences_requises', 'localisation', 'type_contrat',
      'niveau_experience_requis', 'domaine',
      'salaire_min', 'salaire_max', 'devise',
      'nombre_postes', 'date_limite',
    ];

    const updates = {};
    champs.forEach(c => {
      if (req.body[c] !== undefined) updates[c] = req.body[c];
    });
    updates.date_modification = new Date().toISOString();

    const { data: updated, error } = await supabase
      .from('offres_emploi')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    return res.json({
      success: true,
      message: 'Offre mise à jour avec succès',
      data: updated
    });

  } catch (err) {
    console.error('[PATCH offre recruteur]', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/recruteur/offres/:id/dupliquer
router.post('/:id/dupliquer', async (req, res) => {
  try {
    const { data: src } = await supabase
      .from('offres_emploi')
      .select('*')
      .eq('id', req.params.id)
      .eq('entreprise_id', req.entreprise.id)
      .single();

    if (!src) return res.status(404).json({
      success: false, message: 'Offre non trouvée'
    });

    const dateLimite = new Date();
    dateLimite.setDate(dateLimite.getDate() + 30);

    const { data: copie, error } = await supabase
      .from('offres_emploi')
      .insert({
        entreprise_id:            src.entreprise_id,
        titre:                    `${src.titre} (copie)`,
        description:              src.description,
        exigences:                src.exigences,
        competences_requises:     src.competences_requises,
        localisation:             src.localisation,
        type_contrat:             src.type_contrat,
        niveau_experience_requis: src.niveau_experience_requis,
        domaine:                  src.domaine,
        salaire_min:              src.salaire_min,
        salaire_max:              src.salaire_max,
        devise:                   src.devise,
        nombre_postes:            src.nombre_postes,
        date_limite:              dateLimite.toISOString(),
        statut:                   'brouillon',
        nb_vues:                  0,
        date_creation:            new Date().toISOString(),
      })
      .select().single();

    if (error) throw error;

    return res.status(201).json({
      success: true,
      message: 'Offre dupliquée en brouillon',
      data: copie
    });

  } catch (err) {
    console.error('[dupliquer offre]', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});

// PATCH /api/recruteur/offres/:id/cloturer
router.patch('/:id/cloturer', async (req, res) => {
  try {
    const { data: offre } = await supabase
      .from('offres_emploi')
      .select('id, titre')
      .eq('id', req.params.id)
      .eq('entreprise_id', req.entreprise.id)
      .single();

    if (!offre) return res.status(404).json({
      success: false, message: 'Offre non trouvée'
    });

    await supabase.from('offres_emploi')
      .update({ statut: 'expiree', date_modification: new Date().toISOString() })
      .eq('id', req.params.id);

    return res.json({
      success: true,
      message: `Offre "${offre.titre}" clôturée`
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE /api/recruteur/offres/:id
router.delete('/:id', async (req, res) => {
  try {
    const { data: offre } = await supabase
      .from('offres_emploi')
      .select('id, titre')
      .eq('id', req.params.id)
      .eq('entreprise_id', req.entreprise.id)
      .single();

    if (!offre) return res.status(404).json({
      success: false, message: 'Offre non trouvée'
    });

    await supabase.from('offres_emploi')
      .delete().eq('id', req.params.id);

    return res.json({
      success: true,
      message: `Offre "${offre.titre}" supprimée`
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});
```

---

## 3. Flutter — Page Candidatures redesign complet

```dart
// frontend/lib/screens/recruteur/pages/candidatures_page.dart
// DESIGN COMPLET + EXPORT CSV + LISTE + KANBAN

class CandidaturesPage extends StatefulWidget {
  final String? offreId;
  const CandidaturesPage({super.key, this.offreId});
  @override
  State<CandidaturesPage> createState() => _CandidaturesPageState();
}

class _CandidaturesPageState extends State<CandidaturesPage> {
  final RecruteurService _svc = RecruteurService();
  List<Map<String, dynamic>> _candidatures = [];
  Map<String, dynamic>  _stats  = {};
  Map<String, dynamic>? _kanban;
  bool _isLoading    = true;
  bool _isKanbanView = false;
  bool _isExporting  = false;
  String? _selectedStatut;
  final _searchCtrl = TextEditingController();
  String _recherche = '';
  Timer? _debounce;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await _svc.getCandidatures(
        token,
        offreId:  widget.offreId,
        statut:   _selectedStatut,
        recherche: _recherche.isNotEmpty ? _recherche : null,
        vue:      _isKanbanView ? 'kanban' : 'liste',
      );
      if (res['success'] == true) {
        final d = res['data'] as Map<String, dynamic>;
        setState(() {
          _candidatures = List<Map<String, dynamic>>.from(d['candidatures'] ?? []);
          _stats  = d['stats'] as Map<String, dynamic>? ?? {};
          _kanban = d['kanban'] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Header fixe ──────────────────────────────────────
      _buildHeader(),

      // ── Contenu scrollable ────────────────────────────────
      Expanded(child: RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFF1A56DB),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(children: [
            const SizedBox(height: 16),

            // Stats chips
            if (!_isLoading) _buildStatChips(),
            const SizedBox(height: 16),

            // Barre de recherche
            _buildSearchBar(),
            const SizedBox(height: 16),

            // Contenu
            if (_isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(60),
                child: CircularProgressIndicator(color: Color(0xFF1A56DB))))
            else if (_isKanbanView && _kanban != null)
              _buildKanban()
            else
              _buildListe(),
          ]),
        ),
      )),
    ]);
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
    color: const Color(0xFFF8FAFC),
    child: Column(children: [
      Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Candidatures reçues', style: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A))),
          if (_stats['total'] != null)
            Text('${_stats['total']} candidature(s) au total',
              style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF64748B))),
        ])),
        // Bouton export
        OutlinedButton.icon(
          icon: _isExporting
            ? const SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.download_outlined, size: 16),
          label: Text(_isExporting ? 'Export...' : 'Exporter CSV',
            style: GoogleFonts.inter(fontSize: 13)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF64748B),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8))),
          onPressed: _isExporting ? null : _exportCSV,
        ),
        const SizedBox(width: 10),
        // Switch vue
        _buildViewSwitch(),
      ]),
      const SizedBox(height: 12),
    ]),
  );

  Widget _buildViewSwitch() => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(8)),
    padding: const EdgeInsets.all(3),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      _ViewBtn(
        icon: Icons.list_rounded,
        label: 'Liste',
        selected: !_isKanbanView,
        onTap: () {
          setState(() => _isKanbanView = false);
          _load();
        }),
      _ViewBtn(
        icon: Icons.view_kanban_outlined,
        label: 'Kanban',
        selected: _isKanbanView,
        onTap: () {
          setState(() => _isKanbanView = true);
          _load();
        }),
    ]),
  );

  Widget _buildStatChips() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: [
      _StatChip('Toutes', null,         _stats['total'],     _selectedStatut, _setStatut),
      _StatChip('En attente', 'en_attente', _stats['en_attente'], _selectedStatut, _setStatut,
        color: const Color(0xFF1A56DB)),
      _StatChip('En examen',  'en_cours',   _stats['en_cours'],   _selectedStatut, _setStatut,
        color: const Color(0xFFF59E0B)),
      _StatChip('Entretien',  'entretien',  _stats['entretien'],  _selectedStatut, _setStatut,
        color: const Color(0xFF8B5CF6)),
      _StatChip('Acceptées',  'acceptee',   _stats['acceptees'],  _selectedStatut, _setStatut,
        color: const Color(0xFF10B981)),
      _StatChip('Refusées',   'refusee',    _stats['refusees'],   _selectedStatut, _setStatut,
        color: const Color(0xFFEF4444)),
    ]),
  );

  Widget _buildSearchBar() => TextField(
    controller: _searchCtrl,
    decoration: InputDecoration(
      hintText: 'Rechercher un candidat...',
      hintStyle: GoogleFonts.inter(
        fontSize: 14, color: const Color(0xFFCBD5E1)),
      prefixIcon: const Icon(Icons.search_rounded,
        color: Color(0xFF94A3B8), size: 18),
      suffixIcon: _recherche.isNotEmpty
        ? IconButton(
            icon: const Icon(Icons.clear, size: 16,
              color: Color(0xFF94A3B8)),
            onPressed: () {
              _searchCtrl.clear();
              setState(() => _recherche = '');
              _load();
            })
        : null,
      filled: true, fillColor: Colors.white,
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
    ),
    onChanged: (v) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), () {
        setState(() => _recherche = v);
        _load();
      });
    },
  );

  Widget _buildListe() {
    if (_candidatures.isEmpty) {
      return _buildEmptyState();
    }
    return Column(
      children: _candidatures.map((c) =>
        _CandidatureListCard(
          candidature: c,
          onAction: _handleAction,
        )).toList(),
    );
  }

  Widget _buildEmptyState() => Container(
    margin: const EdgeInsets.only(top: 40),
    child: Column(children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          shape: BoxShape.circle),
        child: const Icon(Icons.people_outline_rounded,
          color: Color(0xFF1A56DB), size: 40)),
      const SizedBox(height: 16),
      Text('Aucune candidature',
        style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A))),
      const SizedBox(height: 8),
      Text(
        _selectedStatut == null
          ? 'Vous n\'avez pas encore reçu de candidatures.\nPubliez des offres pour attirer des talents !'
          : 'Aucune candidature avec ce statut.',
        style: GoogleFonts.inter(
          fontSize: 14, color: const Color(0xFF64748B),
          height: 1.5),
        textAlign: TextAlign.center),
      if (_selectedStatut == null) ...[
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Publier une offre'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10))),
          onPressed: () =>
            context.push('/dashboard-recruteur/offres/nouvelle'),
        ),
      ],
    ]),
  );

  Widget _buildKanban() {
    if (_kanban == null) return _buildEmptyState();

    final colonnes = [
      _KanbanCol('Reçues',    'en_attente', const Color(0xFF1A56DB)),
      _KanbanCol('Examen',    'en_cours',   const Color(0xFFF59E0B)),
      _KanbanCol('Entretien', 'entretien',  const Color(0xFF8B5CF6)),
      _KanbanCol('Acceptées', 'acceptees',  const Color(0xFF10B981)),
      _KanbanCol('Refusées',  'refusees',   const Color(0xFFEF4444)),
    ];

    return SizedBox(
      height: 600,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: colonnes.map((col) {
          final items = List<Map<String, dynamic>>.from(
            _kanban![col.key] ?? []);
          return _KanbanColumn(
            col: col,
            items: items,
            onAction: _handleAction,
          );
        }).toList(),
      ),
    );
  }

  Future<void> _exportCSV() async {
    setState(() => _isExporting = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      String url = '${ApiConfig.baseUrl}/api/recruteur/candidatures/export/csv';
      final params = <String>[];
      if (widget.offreId != null) params.add('offre_id=${widget.offreId}');
      if (_selectedStatut != null) params.add('statut=$_selectedStatut');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      await DownloadService.downloadCsv(
        url: url, token: token,
        fileName: 'candidatures_${DateTime.now().toIso8601String().split('T')[0]}.csv',
        context: context,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur export: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _handleAction(
    String id, String action, {
    String? dateEntretien, String? lienVisio, String? raisonRefus,
  }) async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await _svc.actionCandidature(
        token, id, action,
        dateEntretien: dateEntretien,
        lienVisio: lienVisio,
        raisonRefus: raisonRefus,
      );
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_outline,
              color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(res['message'] ?? 'Action effectuée',
              style: GoogleFonts.inter(color: Colors.white)),
          ]),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
        _load();
        final token2 = context.read<AuthProvider>().token ?? '';
        context.read<RecruteurProvider>().refreshCounts(token2);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _setStatut(String? v) {
    setState(() => _selectedStatut = v);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}

// ── Card Candidature vue liste ────────────────────────────────
class _CandidatureListCard extends StatelessWidget {
  final Map<String, dynamic> candidature;
  final Future<void> Function(String, String, {
    String? dateEntretien, String? lienVisio, String? raisonRefus,
  }) onAction;

  const _CandidatureListCard({required this.candidature, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final nom    = candidature['chercheur']?['utilisateur']?['nom'] ?? 'Candidat';
    final email  = candidature['chercheur']?['utilisateur']?['email'] ?? '';
    final photo  = candidature['chercheur']?['utilisateur']?['photo_url'];
    final poste  = candidature['offre']?['titre'] ?? '';
    final statut = candidature['statut'] as String? ?? '';
    final score  = candidature['score_compatibilite'] as int?;
    final date   = _fmtDate(candidature['date_candidature']);
    final id     = candidature['id'] as String;
    final niveau = candidature['chercheur']?['niveau_etude'] as String?;

    // Couleur fond selon statut
    Color cardBg = Colors.white;
    if (statut == 'en_attente') cardBg = const Color(0xFFFAFAFF);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statut == 'en_attente'
            ? const Color(0xFF1A56DB).withOpacity(0.15)
            : const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2))]),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [

          // Ligne principale
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Avatar
            Stack(children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF1A56DB),
                backgroundImage: photo != null
                    ? NetworkImage(photo) : null,
                child: photo == null ? Text(nom[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: Colors.white)) : null,
              ),
              // Indicateur statut
              Positioned(bottom: 0, right: 0,
                child: Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: _statusColor(statut),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white, width: 2)),
                )),
            ]),
            const SizedBox(width: 14),

            // Infos candidat
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(nom, style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A)))),
                StatusBadge(label: statut),
              ]),
              const SizedBox(height: 3),
              Text(email, style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFF64748B))),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.work_outline_rounded,
                  size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Expanded(child: Text(poste, style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF475569)),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                const Icon(Icons.access_time_rounded,
                  size: 12, color: Color(0xFF94A3B8)),
                const SizedBox(width: 3),
                Text(date, style: GoogleFonts.inter(
                  fontSize: 11, color: const Color(0xFF94A3B8))),
              ]),
              if (niveau != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.school_outlined,
                    size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(_labelNiveau(niveau), style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF64748B))),
                ]),
              ],
            ])),
          ]),

          const SizedBox(height: 12),

          // Score IA + boutons actions
          Row(children: [
            if (score != null && score > 0) ...[
              IAScoreBadge(score: score),
              const SizedBox(width: 8),
            ],
            const Spacer(),
            ..._buildActions(context, id, statut),
          ]),
        ]),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext ctx, String id, String statut) {
    switch (statut) {
      case 'en_attente':
        return [
          _ActionButton(
            label: 'Examiner',
            icon: Icons.visibility_outlined,
            color: const Color(0xFF1A56DB),
            onTap: () => onAction(id, 'mettre_en_examen'),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            label: 'Refuser',
            icon: Icons.close_rounded,
            color: const Color(0xFFEF4444),
            outlined: true,
            onTap: () => _showRefuserDialog(ctx, id),
          ),
        ];
      case 'en_cours':
        return [
          _ActionButton(
            label: 'Entretien',
            icon: Icons.event_outlined,
            color: const Color(0xFF8B5CF6),
            onTap: () => _showEntretienDialog(ctx, id),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            label: 'Refuser',
            icon: Icons.close_rounded,
            color: const Color(0xFFEF4444),
            outlined: true,
            onTap: () => _showRefuserDialog(ctx, id),
          ),
        ];
      case 'entretien':
        return [
          _ActionButton(
            label: 'Accepter',
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF10B981),
            onTap: () => onAction(id, 'accepter'),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            label: 'Refuser',
            icon: Icons.close_rounded,
            color: const Color(0xFFEF4444),
            outlined: true,
            onTap: () => _showRefuserDialog(ctx, id),
          ),
        ];
      default:
        return [];
    }
  }

  void _showRefuserDialog(BuildContext ctx, String id) {
    final ctrl = TextEditingController();
    showDialog(context: ctx, builder: (_) => _ActionDialog(
      title: 'Motif du refus',
      subtitle: 'Expliquez pourquoi vous refusez cette candidature.',
      icon: Icons.cancel_outlined,
      iconColor: const Color(0xFFEF4444),
      controller: ctrl,
      hint: 'Ex: Profil ne correspond pas au poste requis...',
      confirmLabel: 'Refuser la candidature',
      confirmColor: const Color(0xFFEF4444),
      onConfirm: () {
        Navigator.pop(ctx);
        onAction(id, 'refuser', raisonRefus: ctrl.text);
      },
    ));
  }

  void _showEntretienDialog(BuildContext ctx, String id) {
    final dateCtrl = TextEditingController();
    final lienCtrl = TextEditingController();
    showDialog(context: ctx, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.event_outlined,
            color: Color(0xFF8B5CF6), size: 20)),
        const SizedBox(width: 12),
        Text('Planifier un entretien',
          style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A))),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: dateCtrl,
          decoration: InputDecoration(
            labelText: 'Date et heure *',
            hintText: 'AAAA-MM-JJThh:mm',
            prefixIcon: const Icon(Icons.calendar_today_outlined,
              size: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0))),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: lienCtrl,
          decoration: InputDecoration(
            labelText: 'Lien de visioconférence (optionnel)',
            hintText: 'https://meet.google.com/...',
            prefixIcon: const Icon(Icons.video_call_outlined, size: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Annuler', style: GoogleFonts.inter(
            color: const Color(0xFF64748B)))),
        ElevatedButton.icon(
          icon: const Icon(Icons.event_available_outlined, size: 16),
          label: Text('Planifier', style: GoogleFonts.inter(
            fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8))),
          onPressed: () {
            Navigator.pop(ctx);
            onAction(id, 'planifier_entretien',
              dateEntretien: dateCtrl.text.isNotEmpty
                  ? dateCtrl.text : null,
              lienVisio: lienCtrl.text.isNotEmpty
                  ? lienCtrl.text : null);
          }),
      ],
    ));
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'acceptee':  return const Color(0xFF10B981);
      case 'refusee':   return const Color(0xFFEF4444);
      case 'entretien': return const Color(0xFF8B5CF6);
      case 'en_cours':  return const Color(0xFFF59E0B);
      default:          return const Color(0xFF1A56DB);
    }
  }

  String _fmtDate(String? d) {
    if (d == null) return '';
    try {
      final dt = DateTime.parse(d).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays == 0) return 'Aujourd\'hui';
      if (diff.inDays == 1) return 'Hier';
      if (diff.inDays < 7)  return 'Il y a ${diff.inDays}j';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return ''; }
  }

  String _labelNiveau(String? n) {
    const map = {
      'bac': 'Baccalauréat', 'bac2': 'Bac+2',
      'licence': 'Licence (Bac+3)', 'master': 'Master (Bac+5)',
      'doctorat': 'Doctorat',
    };
    return map[n] ?? n ?? '';
  }
}

// ── Kanban ───────────────────────────────────────────────────
class _KanbanCol {
  final String label, key;
  final Color color;
  const _KanbanCol(this.label, this.key, this.color);
}

class _KanbanColumn extends StatelessWidget {
  final _KanbanCol col;
  final List<Map<String, dynamic>> items;
  final Future<void> Function(String, String, {
    String? dateEntretien, String? lienVisio, String? raisonRefus,
  }) onAction;

  const _KanbanColumn({
    required this.col, required this.items, required this.onAction});

  @override
  Widget build(BuildContext context) => Container(
    width: 240,
    margin: const EdgeInsets.only(right: 12),
    child: Column(children: [
      // Header colonne
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: col.color.withOpacity(0.1),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(12))),
        child: Row(children: [
          Container(width: 10, height: 10,
            decoration: BoxDecoration(
              color: col.color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(col.label, style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: col.color)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: col.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(100)),
            child: Text('${items.length}', style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: col.color))),
        ]),
      ),

      // Corps
      Container(
        constraints: const BoxConstraints(minHeight: 400),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(12)),
          border: Border.all(color: const Color(0xFFE2E8F0))),
        padding: const EdgeInsets.all(8),
        child: items.isEmpty
          ? Center(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Icon(Icons.inbox_outlined,
                  color: const Color(0xFFCBD5E1), size: 36),
                const SizedBox(height: 8),
                Text('Aucune candidature',
                  style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF94A3B8)),
                  textAlign: TextAlign.center),
              ])))
          : Column(children: items.map((c) =>
              _KanbanCard(c: c, color: col.color)).toList()),
      ),
    ]),
  );
}

class _KanbanCard extends StatelessWidget {
  final Map<String, dynamic> c;
  final Color color;
  const _KanbanCard({required this.c, required this.color});

  @override
  Widget build(BuildContext context) {
    final nom   = c['chercheur']?['utilisateur']?['nom'] ?? 'Candidat';
    final photo = c['chercheur']?['utilisateur']?['photo_url'];
    final poste = c['offre']?['titre'] ?? '';
    final score = c['score_compatibilite'] as int?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(
          color: Color(0x05000000), blurRadius: 4,
          offset: Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 16, backgroundColor: color.withOpacity(0.15),
            backgroundImage: photo != null ? NetworkImage(photo) : null,
            child: photo == null ? Text(nom[0].toUpperCase(),
              style: GoogleFonts.inter(
                color: color, fontWeight: FontWeight.w700,
                fontSize: 12)) : null,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(nom, style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A)),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        if (poste.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(poste, style: GoogleFonts.inter(
            fontSize: 11, color: const Color(0xFF94A3B8)),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
        if (score != null && score > 0) ...[
          const SizedBox(height: 7),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _scoreColor(score).withOpacity(0.1),
                borderRadius: BorderRadius.circular(100)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.auto_awesome,
                  size: 10, color: Color(0xFF1A56DB)),
                const SizedBox(width: 3),
                Text('$score%', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: _scoreColor(score))),
              ]),
            ),
          ]),
        ],
      ]),
    );
  }

  Color _scoreColor(int s) {
    if (s >= 80) return const Color(0xFF10B981);
    if (s >= 60) return const Color(0xFF1A56DB);
    if (s >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

// ── Widgets communs ──────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String? value, selected;
  final int? count;
  final Color? color;
  final void Function(String?) onTap;
  const _StatChip(this.label, this.value, this.count,
      this.selected, this.onTap, {this.color});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    final c = color ?? const Color(0xFF1A56DB);
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? c : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? c : const Color(0xFFE2E8F0)),
          boxShadow: isSelected ? null : [const BoxShadow(
            color: Color(0x05000000), blurRadius: 4,
            offset: Offset(0, 1))]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B))),
          if (count != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.25)
                    : c.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100)),
              child: Text('$count', style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : c))),
          ],
        ]),
      ),
    );
  }
}

class _ViewBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ViewBtn({required this.icon, required this.label,
    required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        boxShadow: selected ? [const BoxShadow(
          color: Color(0x0F000000), blurRadius: 4,
          offset: Offset(0, 1))] : null),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15,
          color: selected
              ? const Color(0xFF1A56DB) : const Color(0xFF94A3B8)),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w500,
          color: selected
              ? const Color(0xFF1A56DB) : const Color(0xFF94A3B8))),
      ]),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label, required this.icon, required this.color,
    this.outlined = false, required this.onTap});

  @override
  Widget build(BuildContext context) => outlined
    ? OutlinedButton.icon(
        icon: Icon(icon, size: 14),
        label: Text(label, style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w500)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.4)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8))),
        onPressed: onTap)
    : ElevatedButton.icon(
        icon: Icon(icon, size: 14),
        label: Text(label, style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w500)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color, foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8))),
        onPressed: onTap);
}

// Dialog générique pour actions
class _ActionDialog extends StatelessWidget {
  final String title, subtitle, confirmLabel, hint;
  final IconData icon;
  final Color iconColor, confirmColor;
  final TextEditingController controller;
  final VoidCallback onConfirm;
  const _ActionDialog({
    required this.title, required this.subtitle,
    required this.icon, required this.iconColor,
    required this.controller, required this.hint,
    required this.confirmLabel, required this.confirmColor,
    required this.onConfirm});

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: Row(children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A))),
        Text(subtitle, style: GoogleFonts.inter(
          fontSize: 11, color: const Color(0xFF64748B))),
      ])),
    ]),
    content: TextFormField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 13, color: const Color(0xFFCBD5E1)),
        filled: true, fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Annuler', style: GoogleFonts.inter(
          color: const Color(0xFF64748B)))),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: confirmColor,
          foregroundColor: Colors.white, elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8))),
        onPressed: onConfirm,
        child: Text(confirmLabel, style: GoogleFonts.inter(
          fontWeight: FontWeight.w600))),
    ],
  );
}
```

---

## 4. Flutter — Page Mes Offres redesign complet

```dart
// frontend/lib/screens/recruteur/pages/mes_offres_page.dart

// ── Card offre dans la liste ─────────────────────────────────
class _OffreCard extends StatelessWidget {
  final Map<String, dynamic> offre;
  final VoidCallback onRefresh;
  const _OffreCard({required this.offre, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final titre    = offre['titre']   as String? ?? '';
    final statut   = offre['statut']  as String? ?? '';
    final localisa = offre['localisation'] as String? ?? '';
    final contrat  = offre['type_contrat'] as String? ?? '';
    final nbVues   = offre['nb_vues'] as int? ?? 0;
    final nbCands  = offre['nb_candidatures'] as int? ?? 0;
    final nonLues  = offre['nb_non_lues'] as int? ?? 0;
    final enVedett = offre['en_vedette'] == true;
    final raison   = offre['raison_refus'] as String?;
    final dateLim  = offre['date_limite'] as String?;

    // Couleur de la card selon statut
    Color borderColor = const Color(0xFFE2E8F0);
    Color bgColor     = Colors.white;
    if (statut == 'publiee') {
      borderColor = const Color(0xFF10B981).withOpacity(0.3);
      bgColor     = const Color(0xFFF0FDF4);
    } else if (statut == 'en_attente') {
      borderColor = const Color(0xFFF59E0B).withOpacity(0.3);
      bgColor     = const Color(0xFFFFFBEB);
    } else if (statut == 'refusee') {
      borderColor = const Color(0xFFEF4444).withOpacity(0.3);
      bgColor     = const Color(0xFFFFF5F5);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: [

        // Contenu principal
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Ligne 1 : Titre + Badges
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Icône domaine
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A56DB).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.work_outline_rounded,
                  color: Color(0xFF1A56DB), size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titre, style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Wrap(spacing: 6, children: [
                  StatusBadge(label: statut),
                  if (enVedett)
                    _TagBadge('⭐ En vedette',
                      const Color(0xFFF59E0B),
                      const Color(0xFFFEF3C7)),
                ]),
              ])),
            ]),
            const SizedBox(height: 12),

            // Ligne 2 : Localisation + Contrat + Date limite
            Wrap(spacing: 16, runSpacing: 6, children: [
              if (localisa.isNotEmpty)
                _InfoChip(Icons.location_on_outlined, localisa),
              if (contrat.isNotEmpty)
                _InfoChip(Icons.badge_outlined, _labelContrat(contrat)),
              if (dateLim != null)
                _InfoChip(Icons.calendar_today_outlined,
                  'Jusqu\'au ${_fmtDate(dateLim)}'),
            ]),
            const SizedBox(height: 14),

            // Ligne 3 : Stats vues / candidatures / non lus
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFE2E8F0))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                _StatMini(
                  Icons.visibility_outlined,
                  '$nbVues',
                  'Vues',
                  const Color(0xFF8B5CF6)),
                _Divider(),
                _StatMini(
                  Icons.people_outline,
                  '$nbCands',
                  'Candidats',
                  const Color(0xFF1A56DB)),
                _Divider(),
                _StatMini(
                  Icons.mark_email_unread_outlined,
                  '$nonLues',
                  'Non lus',
                  nonLues > 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFF94A3B8)),
              ]),
            ),

            // Motif refus si applicable
            if (statut == 'refusee' && raison != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.info_outline,
                    color: Color(0xFFEF4444), size: 14),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'Motif du refus : $raison',
                    style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF991B1B)),
                    maxLines: 2, overflow: TextOverflow.ellipsis)),
                ]),
              ),
            ],
          ]),
        ),

        // Barre d'actions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(14)),
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
          child: Row(children: [
            // Voir candidatures
            _OffreActionBtn(
              icon: Icons.people_outline_rounded,
              label: 'Candidatures',
              color: const Color(0xFF1A56DB),
              onTap: () => context.push(
                '/dashboard-recruteur/candidatures?offre_id=${offre['id']}'),
            ),
            const SizedBox(width: 8),
            // Modifier
            _OffreActionBtn(
              icon: Icons.edit_outlined,
              label: 'Modifier',
              color: const Color(0xFF64748B),
              onTap: () => _showModifierDialog(context),
            ),
            const Spacer(),
            // Menu plus d'actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded,
                color: Color(0xFF94A3B8), size: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
              elevation: 8,
              onSelected: (v) => _handleMenuAction(context, v),
              itemBuilder: (_) => [
                _MenuItem('voir_candidatures',
                  Icons.people_outline, 'Voir les candidatures',
                  const Color(0xFF1A56DB)),
                _MenuItem('dupliquer',
                  Icons.copy_outlined, 'Dupliquer l\'offre',
                  const Color(0xFF64748B)),
                if (statut == 'publiee')
                  _MenuItem('cloturer',
                    Icons.lock_outline, 'Clôturer l\'offre',
                    const Color(0xFFF59E0B)),
                _MenuItem('supprimer',
                  Icons.delete_outline, 'Supprimer',
                  const Color(0xFFEF4444)),
              ],
            ),
          ]),
        ),
      ]),
    );
  }

  void _showModifierDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ModifierOffreDialog(
        offre: offre,
        onSaved: onRefresh,
      ),
    );
  }

  Future<void> _handleMenuAction(BuildContext ctx, String action) async {
    final token = ctx.read<AuthProvider>().token ?? '';
    final svc   = RecruteurService();
    final id    = offre['id'] as String;

    switch (action) {
      case 'voir_candidatures':
        ctx.push('/dashboard-recruteur/candidatures?offre_id=$id');
        break;
      case 'dupliquer':
        try {
          final res = await svc.dupliquerOffre(token, id);
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(res['message'] ?? 'Offre dupliquée'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ));
            onRefresh();
          }
        } catch (e) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ));
        }
        break;
      case 'cloturer':
        _confirmAction(ctx, 'Clôturer cette offre ?',
          'L\'offre sera archivée et n\'acceptera plus de candidatures.',
          const Color(0xFFF59E0B), 'Clôturer', () async {
          await svc.cloturerOffre(token, id);
          onRefresh();
        });
        break;
      case 'supprimer':
        _confirmAction(ctx, 'Supprimer cette offre ?',
          'Cette action est irréversible. Toutes les candidatures seront supprimées.',
          const Color(0xFFEF4444), 'Supprimer', () async {
          await svc.deleteOffre(token, id);
          onRefresh();
        });
        break;
    }
  }

  void _confirmAction(BuildContext ctx, String title, String subtitle,
      Color color, String label, VoidCallback onConfirm) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w700)),
      content: Text(subtitle, style: GoogleFonts.inter(
        fontSize: 13, color: const Color(0xFF64748B), height: 1.5)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color, foregroundColor: Colors.white,
            elevation: 0, shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8))),
          onPressed: () { Navigator.pop(ctx); onConfirm(); },
          child: Text(label, style: GoogleFonts.inter(
            fontWeight: FontWeight.w600))),
      ],
    ));
  }

  String _labelContrat(String c) {
    const map = {
      'CDI': 'CDI', 'CDD': 'CDD', 'stage': 'Stage',
      'freelance': 'Freelance', 'temps_partiel': 'Temps partiel',
    };
    return map[c] ?? c;
  }

  String _fmtDate(String d) {
    try {
      final dt = DateTime.parse(d);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return d; }
  }
}

// Widgets helpers offre
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
    const SizedBox(width: 4),
    Text(text, style: GoogleFonts.inter(
      fontSize: 12, color: const Color(0xFF64748B))),
  ]);
}

class _StatMini extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _StatMini(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, size: 18, color: color),
    const SizedBox(height: 3),
    Text(value, style: GoogleFonts.poppins(
      fontSize: 16, fontWeight: FontWeight.w700,
      color: const Color(0xFF0F172A))),
    Text(label, style: GoogleFonts.inter(
      fontSize: 11, color: const Color(0xFF94A3B8))),
  ]);
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 36,
    color: const Color(0xFFE2E8F0));
}

class _TagBadge extends StatelessWidget {
  final String label;
  final Color text, bg;
  const _TagBadge(this.label, this.text, this.bg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
    child: Text(label, style: GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w600, color: text)));
}

class _OffreActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OffreActionBtn({required this.icon, required this.label,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 5),
      Text(label, style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w500, color: color)),
    ]),
  );
}

PopupMenuItem<String> _MenuItem(
    String value, IconData icon, String label, Color color) =>
  PopupMenuItem(
    value: value,
    child: Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 10),
      Text(label, style: GoogleFonts.inter(
        fontSize: 13, color: color,
        fontWeight: value == 'supprimer'
            ? FontWeight.w600 : FontWeight.w400)),
    ]),
  );
```

---

## 5. Flutter — Dialog Modifier Offre

```dart
// frontend/lib/screens/recruteur/widgets/modifier_offre_dialog.dart

class ModifierOffreDialog extends StatefulWidget {
  final Map<String, dynamic> offre;
  final VoidCallback onSaved;
  const ModifierOffreDialog({super.key, required this.offre, required this.onSaved});
  @override
  State<ModifierOffreDialog> createState() => _ModifierOffreDialogState();
}

class _ModifierOffreDialogState extends State<ModifierOffreDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late TextEditingController _titreCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _exigCtrl;
  late TextEditingController _locaCtrl;
  late TextEditingController _salaireMinCtrl;
  late TextEditingController _salaireMaxCtrl;
  String? _typeContrat;
  String? _niveauExp;
  int _nbPostes = 1;

  static const _contrats = ['CDI', 'CDD', 'stage', 'freelance', 'temps_partiel'];
  static const _niveaux = [
    'sans_experience', '1_2_ans', '3_5_ans', '5_10_ans', '10_ans_plus'
  ];
  static const _niveauxLabels = {
    'sans_experience': 'Sans expérience',
    '1_2_ans': '1 à 2 ans',
    '3_5_ans': '3 à 5 ans',
    '5_10_ans': '5 à 10 ans',
    '10_ans_plus': '10 ans et plus',
  };

  @override
  void initState() {
    super.initState();
    _titreCtrl     = TextEditingController(text: widget.offre['titre'] ?? '');
    _descCtrl      = TextEditingController(text: widget.offre['description'] ?? '');
    _exigCtrl      = TextEditingController(text: widget.offre['exigences'] ?? '');
    _locaCtrl      = TextEditingController(text: widget.offre['localisation'] ?? '');
    _salaireMinCtrl = TextEditingController(
      text: widget.offre['salaire_min']?.toString() ?? '');
    _salaireMaxCtrl = TextEditingController(
      text: widget.offre['salaire_max']?.toString() ?? '');
    _typeContrat   = widget.offre['type_contrat'];
    _niveauExp     = widget.offre['niveau_experience_requis'];
    _nbPostes      = widget.offre['nombre_postes'] as int? ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 680,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: Column(children: [

          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.edit_outlined,
                  color: Color(0xFF1A56DB), size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Modifier l\'offre', style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A))),
                Text(widget.offre['titre'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF64748B)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                  color: Color(0xFF94A3B8)),
                onPressed: () => Navigator.pop(context)),
            ]),
          ),

          // Formulaire scrollable
          Flexible(child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Titre
                _label('Titre du poste *'),
                const SizedBox(height: 6),
                _field(_titreCtrl, 'Ex: Développeur Flutter Senior',
                  validator: (v) => v!.isEmpty ? 'Titre requis' : null),
                const SizedBox(height: 16),

                // Description
                _label('Description du poste *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descCtrl, maxLines: 5,
                  validator: (v) => v!.isEmpty ? 'Description requise' : null,
                  decoration: _deco('Décrivez les responsabilités, l\'environnement de travail...'),
                ),
                const SizedBox(height: 16),

                // Exigences
                _label('Prérequis et compétences'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _exigCtrl, maxLines: 3,
                  decoration: _deco('Ex: 3 ans d\'expérience, maîtrise de Flutter...'),
                ),
                const SizedBox(height: 16),

                // Localisation + Type contrat
                Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Localisation *'),
                    const SizedBox(height: 6),
                    _field(_locaCtrl, 'Ex: Conakry',
                      validator: (v) => v!.isEmpty ? 'Requis' : null),
                  ])),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Type de contrat *'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _typeContrat,
                      decoration: _deco('Choisir...'),
                      borderRadius: BorderRadius.circular(10),
                      items: _contrats.map((c) => DropdownMenuItem(
                        value: c, child: Text(c.toUpperCase(),
                          style: GoogleFonts.inter(fontSize: 13)))).toList(),
                      onChanged: (v) => setState(() => _typeContrat = v),
                      validator: (v) => v == null ? 'Requis' : null,
                    ),
                  ])),
                ]),
                const SizedBox(height: 16),

                // Expérience + Nb postes
                Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Expérience requise'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _niveauExp,
                      decoration: _deco('Sélectionner...'),
                      borderRadius: BorderRadius.circular(10),
                      items: _niveaux.map((n) => DropdownMenuItem(
                        value: n, child: Text(_niveauxLabels[n] ?? n,
                          style: GoogleFonts.inter(fontSize: 13)))).toList(),
                      onChanged: (v) => setState(() => _niveauExp = v),
                    ),
                  ])),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Nombre de postes'),
                    const SizedBox(height: 6),
                    Row(children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: const Color(0xFF64748B),
                        onPressed: _nbPostes > 1
                            ? () => setState(() => _nbPostes--)
                            : null),
                      Expanded(child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0))),
                        child: Text('$_nbPostes',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A))))),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFF1A56DB),
                        onPressed: () => setState(() => _nbPostes++)),
                    ]),
                  ])),
                ]),
                const SizedBox(height: 16),

                // Salaire
                _label('Fourchette salariale (optionnel)'),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: _field(
                    _salaireMinCtrl, 'Min (ex: 2 000 000)',
                    keyboardType: TextInputType.number)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('—', style: GoogleFonts.inter(
                      fontSize: 16, color: const Color(0xFF94A3B8)))),
                  Expanded(child: _field(
                    _salaireMaxCtrl, 'Max (ex: 3 500 000)',
                    keyboardType: TextInputType.number)),
                ]),
              ]),
            ),
          )),

          // Boutons actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
            child: Row(children: [
              Expanded(child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler', style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w500)))),
              const SizedBox(width: 14),
              Expanded(flex: 2, child: ElevatedButton.icon(
                icon: _isSaving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined, size: 18),
                label: Text(_isSaving ? 'Sauvegarde...' : 'Enregistrer les modifications',
                  style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56DB),
                  foregroundColor: Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
                onPressed: _isSaving ? null : _save)),
            ]),
          ),
        ]),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final token = context.read<AuthProvider>().token ?? '';
      final id    = widget.offre['id'] as String;

      final res = await RecruteurService().updateOffre(token, id, {
        'titre':                    _titreCtrl.text.trim(),
        'description':              _descCtrl.text.trim(),
        'exigences':                _exigCtrl.text.trim(),
        'localisation':             _locaCtrl.text.trim(),
        'type_contrat':             _typeContrat,
        'niveau_experience_requis': _niveauExp,
        'nombre_postes':            _nbPostes,
        if (_salaireMinCtrl.text.isNotEmpty)
          'salaire_min': int.tryParse(
            _salaireMinCtrl.text.replaceAll(' ', '')),
        if (_salaireMaxCtrl.text.isNotEmpty)
          'salaire_max': int.tryParse(
            _salaireMaxCtrl.text.replaceAll(' ', '')),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_outline,
              color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(res['message'] ?? 'Offre modifiée avec succès',
              style: GoogleFonts.inter(color: Colors.white)),
          ]),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _label(String t) => Text(t, style: GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w500,
    color: const Color(0xFF374151)));

  Widget _field(TextEditingController c, String hint, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) => TextFormField(
    controller: c, validator: validator,
    keyboardType: keyboardType,
    decoration: _deco(hint));

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1)),
    filled: true, fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF1A56DB), width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFEF4444))),
  );

  @override
  void dispose() {
    _titreCtrl.dispose(); _descCtrl.dispose();
    _exigCtrl.dispose();  _locaCtrl.dispose();
    _salaireMinCtrl.dispose(); _salaireMaxCtrl.dispose();
    super.dispose();
  }
}
```

---

## 6. Flutter — Page Recherche Talents redesign

```dart
// frontend/lib/screens/recruteur/pages/talents_page.dart
// DESIGN PREMIUM + BACKEND CONNECTÉ

class _TalentsPageState extends State<TalentsPage> {
  final RecruteurService _svc = RecruteurService();
  List<Map<String, dynamic>> _talents = [];
  bool _isLoading = false;
  String? _offreSelectee;
  String? _offreSelecteeTitre;
  String _recherche = '';
  String? _niveauEtude;
  String? _disponibilite;
  List<Map<String, dynamic>> _mesOffres = [];
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadMesOffres();
    _loadTalents();
  }

  Future<void> _loadMesOffres() async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await _svc.getOffres(token, statut: 'publiee');
      setState(() {
        _mesOffres = List<Map<String, dynamic>>.from(
          res['data']?['offres'] ?? []);
      });
    } catch (_) {}
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
        offreId:      _offreSelectee,
      );
      setState(() {
        _talents = List<Map<String, dynamic>>.from(
          res['data']?['talents'] ?? []);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildHeader(),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(children: [
          const SizedBox(height: 16),
          _buildSearchAndFilters(),
          const SizedBox(height: 16),
          if (_offreSelectee != null) _buildMatchingBanner(),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(60),
              child: CircularProgressIndicator(color: Color(0xFF1A56DB))))
          else if (_talents.isEmpty)
            _buildEmptyTalents()
          else
            _buildTalentsGrid(),
        ]),
      )),
    ]);
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
    color: const Color(0xFFF8FAFC),
    child: Row(children: [
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)]),
              borderRadius: BorderRadius.circular(100)),
            child: Row(children: [
              const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 13),
              const SizedBox(width: 4),
              Text('IA', style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: Colors.white)),
            ])),
          const SizedBox(width: 10),
          Text('Recherche de Talents', style: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A))),
        ]),
        const SizedBox(height: 4),
        Text(
          '${_talents.length} profil(s) disponible(s) sur la plateforme',
          style: GoogleFonts.inter(
            fontSize: 13, color: const Color(0xFF64748B))),
      ])),
    ]),
  );

  Widget _buildSearchAndFilters() => Column(children: [
    // Barre de recherche
    TextField(
      controller: _searchCtrl,
      decoration: InputDecoration(
        hintText: 'Rechercher par compétence, nom...',
        hintStyle: GoogleFonts.inter(
          fontSize: 14, color: const Color(0xFFCBD5E1)),
        prefixIcon: const Icon(Icons.search_rounded,
          color: Color(0xFF94A3B8), size: 20),
        suffixIcon: _recherche.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear, size: 16),
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _recherche = '');
                _loadTalents();
              })
          : null,
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF1A56DB), width: 1.5)),
      ),
      onChanged: (v) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 400), () {
          setState(() => _recherche = v);
          _loadTalents();
        });
      },
    ),
    const SizedBox(height: 12),

    // Filtres en ligne
    SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        // Matcher avec une offre (IA)
        if (_mesOffres.isNotEmpty) ...[
          _FilterChip(
            label: _offreSelecteeTitre ?? 'Matcher avec une offre (IA)',
            isActive: _offreSelectee != null,
            icon: Icons.auto_awesome_outlined,
            color: const Color(0xFF8B5CF6),
            onTap: () => _showOffreMatcherBottomSheet(),
          ),
          const SizedBox(width: 8),
        ],

        // Niveau d'étude
        _FilterChip(
          label: _niveauEtude != null
              ? _labelNiveau(_niveauEtude!) : 'Niveau d\'étude',
          isActive: _niveauEtude != null,
          icon: Icons.school_outlined,
          color: const Color(0xFF1A56DB),
          onTap: () => _showNiveauPicker(),
        ),
        const SizedBox(width: 8),

        // Disponibilité
        _FilterChip(
          label: _disponibilite != null
              ? _labelDispo(_disponibilite!) : 'Disponibilité',
          isActive: _disponibilite != null,
          icon: Icons.schedule_outlined,
          color: const Color(0xFF10B981),
          onTap: () => _showDispoPicker(),
        ),

        // Reset filtres
        if (_offreSelectee != null || _niveauEtude != null ||
            _disponibilite != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _offreSelectee = null;
                _offreSelecteeTitre = null;
                _niveauEtude = null;
                _disponibilite = null;
              });
              _loadTalents();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(100)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.close_rounded,
                  size: 14, color: Color(0xFFEF4444)),
                const SizedBox(width: 4),
                Text('Réinitialiser', style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w500,
                  color: const Color(0xFFEF4444))),
              ]),
            ),
          ),
        ],
      ]),
    ),
  ]);

  Widget _buildMatchingBanner() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1A56DB), Color(0xFF8B5CF6)]),
      borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      const Icon(Icons.auto_awesome_rounded,
        color: Colors.white, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Score IA activé', style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: Colors.white)),
        Text(
          'Les profils sont triés par compatibilité avec : '
          '"${_offreSelecteeTitre ?? ''}"',
          style: GoogleFonts.inter(
            fontSize: 11, color: Colors.white70)),
      ])),
      GestureDetector(
        onTap: () {
          setState(() {
            _offreSelectee = null;
            _offreSelecteeTitre = null;
          });
          _loadTalents();
        },
        child: const Icon(Icons.close_rounded,
          color: Colors.white70, size: 18)),
    ]),
  );

  Widget _buildTalentsGrid() {
    return LayoutBuilder(builder: (ctx, c) {
      final cols = c.maxWidth > 1200 ? 4 :
                   c.maxWidth > 900  ? 3 :
                   c.maxWidth > 600  ? 2 : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          childAspectRatio: 0.75,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: _talents.length,
        itemBuilder: (ctx, i) => _TalentCard(
          talent: _talents[i],
          onContact: (msg, offreId) =>
            _contacter(_talents[i], msg, offreId),
        ),
      );
    });
  }

  Widget _buildEmptyTalents() => Center(
    child: Column(children: [
      const SizedBox(height: 40),
      Container(
        width: 80, height: 80,
        decoration: const BoxDecoration(
          color: Color(0xFFEFF6FF), shape: BoxShape.circle),
        child: const Icon(Icons.search_off_outlined,
          color: Color(0xFF1A56DB), size: 40)),
      const SizedBox(height: 16),
      Text('Aucun talent trouvé', style: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A))),
      const SizedBox(height: 8),
      Text('Modifiez vos critères de recherche',
        style: GoogleFonts.inter(
          fontSize: 14, color: const Color(0xFF64748B))),
    ]),
  );

  Future<void> _contacter(
    Map<String, dynamic> talent, String message, String? offreId) async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final userId = talent['utilisateur']?['id'] as String?;
      if (userId == null) return;

      await _svc.contacterTalent(token, userId, message,
        offreId: offreId ?? _offreSelectee);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.send_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('Message envoyé à ${talent['utilisateur']?['nom'] ?? ''}',
              style: GoogleFonts.inter(color: Colors.white)),
          ]),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showOffreMatcherBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(100))),
          const SizedBox(height: 16),
          Text('Sélectionner une offre pour le matching IA',
            style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ..._mesOffres.map((o) => ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.work_outline,
                color: Color(0xFF1A56DB), size: 18)),
            title: Text(o['titre'] ?? '',
              style: GoogleFonts.inter(fontSize: 14)),
            trailing: _offreSelectee == o['id']
                ? const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF10B981)) : null,
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _offreSelectee = o['id'];
                _offreSelecteeTitre = o['titre'];
              });
              _loadTalents();
            },
          )),
        ]),
      ),
    );
  }

  void _showNiveauPicker() {
    const niveaux = {
      'bac': 'Baccalauréat',
      'bac2': 'Bac+2',
      'licence': 'Licence (Bac+3)',
      'master': 'Master (Bac+5)',
      'doctorat': 'Doctorat',
    };
    _showPickerSheet('Niveau d\'étude', niveaux, _niveauEtude, (v) {
      setState(() => _niveauEtude = v);
      _loadTalents();
    });
  }

  void _showDispoPicker() {
    const dispos = {
      'immediat': 'Disponible immédiatement',
      '1_mois':   'Dans 1 mois',
      '3_mois':   'Dans 3 mois',
    };
    _showPickerSheet('Disponibilité', dispos, _disponibilite, (v) {
      setState(() => _disponibilite = v);
      _loadTalents();
    });
  }

  void _showPickerSheet(String title, Map<String, String> options,
      String? selected, void Function(String?) onSelect) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(100))),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (selected != null)
            TextButton(
              onPressed: () { Navigator.pop(context); onSelect(null); },
              child: const Text('Réinitialiser ce filtre')),
          ...options.entries.map((e) => ListTile(
            title: Text(e.value,
              style: GoogleFonts.inter(fontSize: 14)),
            trailing: selected == e.key
                ? const Icon(Icons.check_rounded,
                    color: Color(0xFF1A56DB)) : null,
            onTap: () { Navigator.pop(context); onSelect(e.key); },
          )),
        ]),
      ),
    );
  }

  String _labelNiveau(String n) {
    const map = {
      'bac': 'Bac', 'bac2': 'Bac+2', 'licence': 'Licence',
      'master': 'Master', 'doctorat': 'Doctorat',
    };
    return map[n] ?? n;
  }

  String _labelDispo(String d) {
    const map = {
      'immediat': 'Disponible', '1_mois': '1 mois', '3_mois': '3 mois',
    };
    return map[d] ?? d;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}

// ── Card Talent ───────────────────────────────────────────────
class _TalentCard extends StatelessWidget {
  final Map<String, dynamic> talent;
  final void Function(String message, String? offreId) onContact;
  const _TalentCard({required this.talent, required this.onContact});

  @override
  Widget build(BuildContext context) {
    final u       = talent['utilisateur'] as Map<String, dynamic>? ?? {};
    final nom     = u['nom'] as String? ?? 'Candidat';
    final photo   = u['photo_url'] as String?;
    final adresse = u['adresse'] as String? ?? '';
    final niveau  = talent['niveau_etude'] as String? ?? '';
    final dispo   = talent['disponibilite'] as String? ?? '';
    final score   = talent['score_matching'] as int?;
    final comps   = List<String>.from(
      talent['toutes_competences'] as List? ?? []);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(children: [

        // En-tête avec photo + score IA
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFF),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16))),
          child: Column(children: [
            // Score IA en haut à droite
            if (score != null && score > 0)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _scoreColor(score).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: _scoreColor(score).withOpacity(0.3))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.auto_awesome_rounded,
                      size: 12, color: Color(0xFF1A56DB)),
                    const SizedBox(width: 4),
                    Text('$score% match', style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: _scoreColor(score))),
                  ]),
                ),
              ),
            if (score != null && score > 0) const SizedBox(height: 10),

            // Avatar
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFF1A56DB),
              backgroundImage: photo != null ? NetworkImage(photo) : null,
              child: photo == null ? Text(nom[0].toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 24, fontWeight: FontWeight.w700,
                  color: Colors.white)) : null,
            ),
            const SizedBox(height: 12),
            Text(nom, style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A)),
              textAlign: TextAlign.center,
              maxLines: 1, overflow: TextOverflow.ellipsis),
            if (adresse.isNotEmpty) ...[
              const SizedBox(height: 3),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.location_on_outlined,
                  size: 12, color: Color(0xFF94A3B8)),
                const SizedBox(width: 3),
                Flexible(child: Text(adresse, style: GoogleFonts.inter(
                  fontSize: 11, color: const Color(0xFF94A3B8)),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ],
          ]),
        ),

        // Corps
        Expanded(child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Disponibilité
            if (dispo.isNotEmpty) ...[
              _DispoChip(dispo),
              const SizedBox(height: 8),
            ],

            // Niveau
            if (niveau.isNotEmpty)
              Row(children: [
                const Icon(Icons.school_outlined,
                  size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(_labelNiveau(niveau), style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF64748B))),
              ]),
            const SizedBox(height: 8),

            // Compétences
            if (comps.isNotEmpty) ...[
              Wrap(spacing: 5, runSpacing: 5,
                children: comps.take(4).map((c) =>
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: const Color(0xFFBFDBFE))),
                    child: Text(c, style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w500,
                      color: const Color(0xFF1E40AF))),
                  )).toList()),
              if (comps.length > 4)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('+${comps.length - 4} compétences',
                    style: GoogleFonts.inter(
                      fontSize: 10, color: const Color(0xFF94A3B8)))),
            ],
          ]),
        )),

        // Bouton contacter
        Padding(
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.chat_outlined, size: 16),
              label: Text('Contacter', style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
              onPressed: () => _showContactDialog(context),
            ),
          ),
        ),
      ]),
    );
  }

  void _showContactDialog(BuildContext context) {
    final ctrl = TextEditingController(
      text: 'Bonjour, votre profil correspond à nos besoins. '
            'Nous aimerions vous proposer une opportunité.');

    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        CircleAvatar(
          radius: 18, backgroundColor: const Color(0xFF1A56DB),
          backgroundImage: (talent['utilisateur']?['photo_url'] != null)
              ? NetworkImage(talent['utilisateur']['photo_url']) : null,
          child: talent['utilisateur']?['photo_url'] == null
              ? Text((talent['utilisateur']?['nom'] ?? 'C')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold))
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Contacter', style: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w700)),
          Text(talent['utilisateur']?['nom'] ?? '',
            style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFF64748B))),
        ])),
      ]),
      content: TextFormField(
        controller: ctrl, maxLines: 5,
        decoration: InputDecoration(
          filled: true, fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          hintText: 'Rédigez votre message...',
          hintStyle: GoogleFonts.inter(
            fontSize: 13, color: const Color(0xFFCBD5E1)),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: Text('Annuler', style: GoogleFonts.inter(
            color: const Color(0xFF64748B)))),
        ElevatedButton.icon(
          icon: const Icon(Icons.send_rounded, size: 16),
          label: Text('Envoyer', style: GoogleFonts.inter(
            fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8))),
          onPressed: () {
            Navigator.pop(context);
            onContact(ctrl.text, null);
          }),
      ],
    ));
  }

  Color _scoreColor(int s) {
    if (s >= 80) return const Color(0xFF10B981);
    if (s >= 60) return const Color(0xFF1A56DB);
    if (s >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _labelNiveau(String n) {
    const map = {
      'bac': 'Baccalauréat', 'bac2': 'Bac+2',
      'licence': 'Licence', 'master': 'Master',
      'doctorat': 'Doctorat',
    };
    return map[n] ?? n;
  }
}

// Chip disponibilité
class _DispoChip extends StatelessWidget {
  final String dispo;
  const _DispoChip(this.dispo);

  @override
  Widget build(BuildContext context) {
    Color bg, text;
    String label;

    switch (dispo) {
      case 'immediat':
        bg = const Color(0xFFD1FAE5); text = const Color(0xFF065F46);
        label = '🟢 Disponible maintenant';
        break;
      case '1_mois':
        bg = const Color(0xFFFEF3C7); text = const Color(0xFF92400E);
        label = '🟡 Disponible dans 1 mois';
        break;
      default:
        bg = const Color(0xFFF1F5F9); text = const Color(0xFF64748B);
        label = '⬜ $dispo';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(label, style: GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w600, color: text)));
  }
}

// Chip filtre
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isActive,
    required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isActive ? color : const Color(0xFFE2E8F0)),
        boxShadow: [const BoxShadow(
          color: Color(0x05000000), blurRadius: 4,
          offset: Offset(0, 1))]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14,
          color: isActive ? color : const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w500,
          color: isActive ? color : const Color(0xFF64748B))),
        if (isActive) ...[
          const SizedBox(width: 4),
          Icon(Icons.expand_more_rounded,
            size: 14, color: color),
        ],
      ]),
    ),
  );
}
```

---

## 7. Ajouter méthodes manquantes dans RecruteurService

```dart
// Dans frontend/lib/services/recruteur_service.dart

// Exporter CSV candidatures
Future<void> exportCandidaturesCSV(String token, {
  String? offreId, String? statut
}) async {
  String url = '$_base/candidatures/export/csv';
  final params = <String>[];
  if (offreId != null) params.add('offre_id=$offreId');
  if (statut != null) params.add('statut=$statut');
  if (params.isNotEmpty) url += '?${params.join('&')}';

  await DownloadService.downloadCsv(
    url: url, token: token,
    fileName: 'candidatures_${DateTime.now().toIso8601String().split('T')[0]}.csv',
    context: navigatorKey.currentContext!,
  );
}

// Clôturer une offre
Future<Map<String, dynamic>> cloturerOffre(
  String token, String id) async {
  final res = await http.patch(
    Uri.parse('$_base/offres/$id/cloturer'),
    headers: _headers(token),
  );
  return _handle(res);
}
```

---

## 8. Critères d'Acceptation

### ✅ Page Candidatures
- [ ] Export CSV : téléchargement fichier avec nom + statut + score IA
- [ ] Vue liste : cards avec avatar, nom, poste, score IA, statut, date
- [ ] Vue kanban : 5 colonnes colorées, cartes déplaçables
- [ ] Filtres statuts avec vrais chiffres par statut
- [ ] Recherche candidat fonctionnelle
- [ ] Dialog "Examiner" → statut en_cours + notif candidat
- [ ] Dialog "Entretien" avec champs date + lien visio
- [ ] Dialog "Refuser" avec champ motif obligatoire
- [ ] Bouton "Accepter" direct sans dialog
- [ ] Empty state avec illustration et CTA "Publier une offre"

### ✅ Page Mes Offres
- [ ] Cards colorées selon statut (vert/orange/rouge)
- [ ] Stat bloc : vues / candidatures / non lus par offre
- [ ] Motif refus affiché si offre refusée
- [ ] Menu 3 points : voir candidatures / modifier / dupliquer / clôturer / supprimer
- [ ] Toutes les actions fonctionnent avec confirmation

### ✅ Dialog Modifier Offre
- [ ] S'ouvre avec les données actuelles pré-remplies
- [ ] Validation des champs obligatoires
- [ ] Bouton "Enregistrer" → PATCH API → snackbar succès
- [ ] Liste se rafraîchit après modification

### ✅ Page Recherche Talents
- [ ] Grille responsive (1/2/3/4 cols selon écran)
- [ ] Cards avec avatar, nom, ville, dispo, compétences, score IA
- [ ] Chip disponibilité coloré (vert/jaune/gris)
- [ ] Filtrer par offre → scores IA calculés et affichés
- [ ] Filtres niveau étude + disponibilité via bottom sheet
- [ ] Dialog contacter avec message pré-rempli professionnel
- [ ] Empty state illustré si aucun résultat

---

*PRD EmploiConnect v5.4 — Candidatures + Mes Offres + Talents*
*Cursor / Kirsoft AI — Phase 9.4*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
