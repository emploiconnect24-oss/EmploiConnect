# PRD — EmploiConnect · Parcours Carrière IA
## Product Requirements Document v8.7
**Stack : Flutter + Node.js/Express + Supabase + Claude IA**
**Outil : Cursor / Kirsoft AI**
**Date : Avril 2026**

---

## Vision

Le **Parcours Carrière** est le centre de développement professionnel
de la plateforme. Il combine :
- Des ressources (guides, vidéos, astuces) gérées par l'admin
- Des outils IA interactifs (simulateur entretien, calculateur salaire)
- Le générateur de CV déjà existant

---

## Table des Matières

1. [Architecture & Logique des contenus](#1-architecture--logique-des-contenus)
2. [Base de données — Tables nécessaires](#2-base-de-données--tables-nécessaires)
3. [Administration — Gérer les ressources](#3-administration--gérer-les-ressources)
4. [Page Parcours Carrière candidat](#4-page-parcours-carrière-candidat)
5. [Simulateur d'entretien IA](#5-simulateur-dentretien-ia)
6. [Calculateur de salaire](#6-calculateur-de-salaire)
7. [Notifications nouvelles ressources](#7-notifications-nouvelles-ressources)

---

## 1. Architecture & Logique des contenus

### Comment gérer les contenus ?

```
ADMIN crée le contenu :
→ Titre, description, catégorie
→ Type : Guide PDF | Vidéo YouTube | Vidéo uploadée | Article
→ Niveau : Débutant | Intermédiaire | Avancé
→ Tags : CV, Entretien, Salaire, Reconversion...

CANDIDAT consomme :
→ Voit les ressources classées par catégorie
→ Filtre par type/niveau/tag
→ Reçoit notification si nouveau contenu
→ Marque comme "lu/vu"
→ Accède aux outils IA
```

### Types de contenu supportés

```
1. ARTICLE    → Texte riche écrit dans l'admin
2. GUIDE PDF  → Fichier PDF uploadé dans Supabase Storage
3. VIDÉO YOUTUBE → URL YouTube embarquée (gratuit, illimité)
4. VIDÉO INTERNE → Vidéo uploadée dans Supabase Storage
5. CONSEIL IA → Généré par Claude selon le profil du candidat
```

### Pourquoi YouTube pour les vidéos ?

```
✅ Gratuit et illimité
✅ Pas de coût de stockage
✅ Bonne qualité de streaming
✅ Peut être intégré dans Flutter via webview
✅ L'admin colle juste l'URL YouTube
✅ Vidéos privées/non listées possibles
   → La vidéo n'apparaît pas sur YouTube public
   → Accessible uniquement via le lien
```

---

## 2. Base de données — Tables nécessaires

```sql
-- Table principale des ressources
CREATE TABLE IF NOT EXISTS ressources_carrieres (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  titre           TEXT NOT NULL,
  description     TEXT,
  contenu         TEXT,           -- Pour les articles
  type_ressource  TEXT NOT NULL   -- 'article'|'pdf'|'video_youtube'|'video_interne'
    CHECK (type_ressource IN (
      'article', 'pdf', 'video_youtube', 'video_interne', 'conseil_ia')),
  categorie       TEXT NOT NULL   -- 'cv'|'entretien'|'salaire'|'reconversion'|'entrepreneuriat'
    CHECK (categorie IN (
      'cv', 'entretien', 'salaire',
      'reconversion', 'entrepreneuriat', 'general')),
  niveau          TEXT DEFAULT 'tous'
    CHECK (niveau IN ('debutant', 'intermediaire', 'avance', 'tous')),
  url_externe     TEXT,           -- URL YouTube ou lien externe
  fichier_url     TEXT,           -- URL Supabase Storage pour PDF/vidéo
  image_couverture TEXT,          -- Image de couverture
  duree_minutes   INTEGER,        -- Pour les vidéos
  tags            TEXT[],         -- ['cv', 'recrutement', 'guinee']
  est_publie      BOOLEAN DEFAULT FALSE,
  est_mis_en_avant BOOLEAN DEFAULT FALSE,
  nb_vues         INTEGER DEFAULT 0,
  auteur_id       UUID REFERENCES utilisateurs(id),
  date_creation   TIMESTAMPTZ DEFAULT NOW(),
  date_publication TIMESTAMPTZ,
  ordre_affichage INTEGER DEFAULT 0
);

-- Suivi de lecture par candidat
CREATE TABLE IF NOT EXISTS ressources_vues (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  ressource_id    UUID REFERENCES ressources_carrieres(id) ON DELETE CASCADE,
  utilisateur_id  UUID REFERENCES utilisateurs(id) ON DELETE CASCADE,
  date_vue        TIMESTAMPTZ DEFAULT NOW(),
  progression     INTEGER DEFAULT 0, -- 0-100% pour les vidéos
  UNIQUE(ressource_id, utilisateur_id)
);

-- Sessions simulateur d'entretien
CREATE TABLE IF NOT EXISTS simulations_entretien (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  utilisateur_id  UUID REFERENCES utilisateurs(id),
  poste_vise      TEXT,
  domaine         TEXT,
  niveau          TEXT,
  questions       JSONB,          -- [{question, reponse_candidat, feedback_ia, score}]
  score_global    INTEGER,
  duree_minutes   INTEGER,
  statut          TEXT DEFAULT 'en_cours'
    CHECK (statut IN ('en_cours', 'termine')),
  date_creation   TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_ressources_categorie
  ON ressources_carrieres(categorie);
CREATE INDEX IF NOT EXISTS idx_ressources_publie
  ON ressources_carrieres(est_publie);
CREATE INDEX IF NOT EXISTS idx_ressources_vues_user
  ON ressources_vues(utilisateur_id);
```

---

## 3. Administration — Gérer les ressources

### Backend — Routes admin ressources

```javascript
// Dans backend/src/routes/admin/ressources.routes.js

const express = require('express');
const router  = express.Router();
const multer  = require('multer');
const upload  = multer({ storage: multer.memoryStorage() });

// GET /api/admin/ressources — Lister toutes les ressources
router.get('/', auth, requireAdmin, async (req, res) => {
  try {
    const { categorie, type, publie } = req.query;
    let query = supabase
      .from('ressources_carrieres')
      .select(`
        id, titre, description, type_ressource,
        categorie, niveau, est_publie, est_mis_en_avant,
        nb_vues, date_creation, date_publication,
        auteur:auteur_id (nom)
      `)
      .order('date_creation', { ascending: false });

    if (categorie) query = query.eq('categorie', categorie);
    if (type)      query = query.eq('type_ressource', type);
    if (publie !== undefined) query = query.eq('est_publie', publie === 'true');

    const { data } = await query;
    return res.json({ success: true, data: data || [] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/admin/ressources — Créer une ressource
router.post('/', auth, requireAdmin,
  upload.fields([
    { name: 'fichier', maxCount: 1 },
    { name: 'couverture', maxCount: 1 }
  ]),
  async (req, res) => {
  try {
    const {
      titre, description, contenu, type_ressource,
      categorie, niveau, url_externe, tags,
      duree_minutes, est_publie, est_mis_en_avant,
    } = req.body;

    let fichierUrl   = null;
    let couvertureUrl = null;

    // Upload fichier PDF ou vidéo
    if (req.files?.fichier?.[0]) {
      const fichier = req.files.fichier[0];
      const chemin  =
        `ressources/${Date.now()}-${fichier.originalname}`;
      const { error } = await supabase.storage
        .from('ressources')
        .upload(chemin, fichier.buffer, {
          contentType: fichier.mimetype });
      if (!error) {
        const { data: pub } = supabase.storage
          .from('ressources').getPublicUrl(chemin);
        fichierUrl = pub.publicUrl;
      }
    }

    // Upload image de couverture
    if (req.files?.couverture?.[0]) {
      const img    = req.files.couverture[0];
      const chemin =
        `couvertures/${Date.now()}-${img.originalname}`;
      const { error } = await supabase.storage
        .from('ressources')
        .upload(chemin, img.buffer, {
          contentType: img.mimetype });
      if (!error) {
        const { data: pub } = supabase.storage
          .from('ressources').getPublicUrl(chemin);
        couvertureUrl = pub.publicUrl;
      }
    }

    // Extraire ID YouTube si URL YouTube
    let urlFinale = url_externe;
    if (type_ressource === 'video_youtube' && url_externe) {
      // Convertir en URL embed
      const ytMatch = url_externe.match(
        /(?:youtu\.be\/|youtube\.com\/(?:watch\?v=|embed\/))([\w-]+)/);
      if (ytMatch) {
        urlFinale =
          `https://www.youtube.com/embed/${ytMatch[1]}`;
      }
    }

    const tagsArray = tags
      ? (Array.isArray(tags) ? tags : tags.split(',').map(t => t.trim()))
      : [];

    const { data, error } = await supabase
      .from('ressources_carrieres')
      .insert({
        titre,
        description,
        contenu,
        type_ressource,
        categorie,
        niveau:            niveau || 'tous',
        url_externe:       urlFinale,
        fichier_url:       fichierUrl,
        image_couverture:  couvertureUrl,
        tags:              tagsArray,
        duree_minutes:     duree_minutes
          ? parseInt(duree_minutes) : null,
        est_publie:        est_publie === 'true',
        est_mis_en_avant:  est_mis_en_avant === 'true',
        auteur_id:         req.user.id,
        date_publication:  est_publie === 'true'
          ? new Date().toISOString() : null,
      })
      .select().single();

    if (error) throw error;

    // Notifier les candidats si publiée
    if (est_publie === 'true') {
      await _notifierNouvelleRessource(data);
    }

    return res.status(201).json({
      success: true, message: 'Ressource créée ✅', data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PATCH /api/admin/ressources/:id/publier
router.patch('/:id/publier', auth, requireAdmin,
  async (req, res) => {
  try {
    const { est_publie } = req.body;
    const { data } = await supabase
      .from('ressources_carrieres')
      .update({
        est_publie,
        date_publication: est_publie
          ? new Date().toISOString() : null,
      })
      .eq('id', req.params.id)
      .select().single();

    if (est_publie) await _notifierNouvelleRessource(data);

    return res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Notifier les candidats
async function _notifierNouvelleRessource(ressource) {
  try {
    const { data: candidats } = await supabase
      .from('chercheurs_emploi')
      .select('utilisateur_id');

    if (!candidats?.length) return;

    const notifs = candidats.map(c => ({
      destinataire_id: c.utilisateur_id,
      titre:    `📚 Nouvelle ressource disponible`,
      message:  `"${ressource.titre}" vient d'être ajouté au Parcours Carrière`,
      type:     'ressource',
      lien:     `/dashboard-candidat/parcours/${ressource.id}`,
      est_lue:  false,
    }));

    await supabase.from('notifications').insert(notifs);
    console.log('[ressources] Notifications envoyées:', notifs.length);
  } catch (e) {
    console.warn('[ressources] Notif échouée:', e.message);
  }
}

module.exports = router;
```

### Flutter Admin — Page gestion ressources

```dart
// frontend/lib/screens/admin/pages/ressources_carrieres_admin_page.dart

class RessourcesCarrieresAdminPage extends StatefulWidget {
  const RessourcesCarrieresAdminPage({super.key});
  @override
  State<RessourcesCarrieresAdminPage> createState() =>
    _RessourcesAdminState();
}

class _RessourcesAdminState extends State<RessourcesCarrieresAdminPage> {

  List<Map<String, dynamic>> _ressources = [];
  bool _isLoading = true;
  String _filtreCategorie = 'tous';

  @override
  void initState() { super.initState(); _load(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [

      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        color: Colors.white,
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Parcours Carrière', style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A))),
            Text('${_ressources.length} ressource(s)',
              style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF64748B))),
          ])),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Nouvelle ressource'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56DB),
              foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
            onPressed: () => _showDialogRessource(null)),
        ])),

      // Filtres catégories
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _filtreChip('tous',          'Toutes'),
            _filtreChip('cv',            '📄 CV'),
            _filtreChip('entretien',     '🎤 Entretien'),
            _filtreChip('salaire',       '💰 Salaire'),
            _filtreChip('reconversion',  '🔄 Reconversion'),
            _filtreChip('entrepreneuriat','🚀 Entrepreneuriat'),
          ]))),
      const Divider(height: 1),

      // Liste ressources
      Expanded(child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _ressourcesFiltrees.length,
              itemBuilder: (ctx, i) =>
                _RessourceAdminCard(
                  ressource: _ressourcesFiltrees[i],
                  onEdit:    () => _showDialogRessource(
                    _ressourcesFiltrees[i]),
                  onToggle:  () => _togglePublication(
                    _ressourcesFiltrees[i]),
                  onDelete:  () => _supprimer(
                    _ressourcesFiltrees[i]['id'])))),
    ]);
  }

  List<Map<String, dynamic>> get _ressourcesFiltrees =>
    _filtreCategorie == 'tous'
        ? _ressources
        : _ressources.where((r) =>
            r['categorie'] == _filtreCategorie).toList();

  Widget _filtreChip(String val, String label) {
    final isSel = _filtreCategorie == val;
    return GestureDetector(
      onTap: () => setState(() => _filtreCategorie = val),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSel
              ? const Color(0xFF1A56DB)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSel
                ? const Color(0xFF1A56DB)
                : const Color(0xFFE2E8F0))),
        child: Text(label, style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: isSel
              ? Colors.white : const Color(0xFF64748B)))));
  }

  void _showDialogRessource(Map<String, dynamic>? existing) {
    showDialog(context: context,
      builder: (_) => _DialogRessource(
        existing: existing,
        onSaved: () {
          Navigator.pop(context);
          _load();
        }));
  }

  Future<void> _togglePublication(
      Map<String, dynamic> r) async {
    final token    = context.read<AuthProvider>().token ?? '';
    final newState = !(r['est_publie'] as bool? ?? false);
    await http.patch(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/admin/ressources/${r['id']}/publier'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'est_publie': newState}));
    _load();
  }

  Future<void> _supprimer(String id) async {
    final token = context.read<AuthProvider>().token ?? '';
    await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/ressources/$id'),
      headers: {'Authorization': 'Bearer $token'});
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res   = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/ressources'),
        headers: {'Authorization': 'Bearer $token'});
      final body = jsonDecode(res.body);
      setState(() {
        _ressources = List<Map<String, dynamic>>.from(
          body['data'] ?? []);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }
}
```

---

## 4. Page Parcours Carrière candidat

```dart
// frontend/lib/screens/candidat/pages/parcours_carriere_page.dart

class ParcoursCarrierePage extends StatefulWidget {
  const ParcoursCarrierePage({super.key});
  @override
  State<ParcoursCarrierePage> createState() =>
    _ParcoursCarriereState();
}

class _ParcoursCarriereState extends State<ParcoursCarrierePage>
    with SingleTickerProviderStateMixin {

  late TabController _tabCtrl;
  List<Map<String, dynamic>> _ressources = [];
  bool _isLoading = true;
  String _categorieActive = 'tous';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [

      // ── Hero section ────────────────────────────────────
      Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A56DB), Color(0xFF7C3AED)])),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Parcours Carrière',
                style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: Colors.white)),
              Text(
                'Développez vos compétences avec l\'IA',
                style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.white70)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(100)),
              child: Row(children: [
                const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 13),
                const SizedBox(width: 5),
                Text('Propulsé par IA',
                  style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: Colors.white)),
              ])),
          ]),
          const SizedBox(height: 16),

          // Stats rapides
          Row(children: [
            _StatHero(
              '${_ressources.length}', 'Ressources', Icons.library_books_outlined),
            const SizedBox(width: 16),
            _StatHero('3', 'Outils IA', Icons.psychology_rounded),
            const SizedBox(width: 16),
            _StatHero(
              '${_ressourcesVues}', 'Vus', Icons.visibility_outlined),
          ]),
        ])),

      // ── Tabs ────────────────────────────────────────────
      Container(
        color: Colors.white,
        child: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w400),
          labelColor: const Color(0xFF1A56DB),
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF1A56DB),
          tabs: const [
            Tab(text: '📚 Ressources'),
            Tab(text: '🎤 Simulateur IA'),
            Tab(text: '💰 Calculateur'),
          ])),
      const Divider(height: 1),

      // ── Contenu tabs ────────────────────────────────────
      Expanded(child: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildTabRessources(),
          const SimulateurEntretienIA(),
          const CalculateurSalaire(),
        ])),
    ]);
  }

  Widget _buildTabRessources() => Column(children: [
    // Filtres catégories
    Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _filtreCategorie('tous',     '🗂️ Tout'),
          _filtreCategorie('cv',       '📄 CV'),
          _filtreCategorie('entretien','🎤 Entretien'),
          _filtreCategorie('salaire',  '💰 Salaire'),
          _filtreCategorie('reconversion','🔄 Reconversion'),
          _filtreCategorie('entrepreneuriat','🚀 Entrepreneuriat'),
        ]))),
    const Divider(height: 1),

    // Outils IA mis en avant
    _buildOutilsIA(),

    // Ressources
    Expanded(child: _isLoading
        ? const Center(child: CircularProgressIndicator(
            color: Color(0xFF1A56DB)))
        : _ressourcesFiltrees.isEmpty
            ? _buildEmpty()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _ressourcesFiltrees.length,
                itemBuilder: (ctx, i) =>
                  _RessourceCard(
                    ressource: _ressourcesFiltrees[i],
                    onTap: () => _ouvrirRessource(
                      _ressourcesFiltrees[i])))),
  ]);

  Widget _buildOutilsIA() => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('🛠️ Outils IA disponibles',
        style: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A))),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _OutilIACard(
          icon:  Icons.psychology_rounded,
          titre: 'Simulateur d\'entretien',
          desc:  'Préparez-vous avec l\'IA',
          couleur: const Color(0xFF8B5CF6),
          onTap: () => _tabCtrl.animateTo(1))),
        const SizedBox(width: 10),
        Expanded(child: _OutilIACard(
          icon:  Icons.calculate_rounded,
          titre: 'Calculateur salaire',
          desc:  'Estimez votre valeur',
          couleur: const Color(0xFF10B981),
          onTap: () => _tabCtrl.animateTo(2))),
        const SizedBox(width: 10),
        Expanded(child: _OutilIACard(
          icon:  Icons.description_outlined,
          titre: 'Générateur CV',
          desc:  'Créez votre CV',
          couleur: const Color(0xFF1A56DB),
          onTap: () => context.push(
            '/dashboard-candidat/cv/creer'))),
      ]),
      const SizedBox(height: 14),
    ]));

  Widget _filtreCategorie(String val, String label) {
    final isSel = _categorieActive == val;
    return GestureDetector(
      onTap: () => setState(() => _categorieActive = val),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSel
              ? const Color(0xFF1A56DB)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSel
                ? const Color(0xFF1A56DB)
                : const Color(0xFFE2E8F0))),
        child: Text(label, style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: isSel ? Colors.white : const Color(0xFF64748B)))));
  }

  List<Map<String, dynamic>> get _ressourcesFiltrees =>
    _categorieActive == 'tous'
        ? _ressources
        : _ressources.where((r) =>
            r['categorie'] == _categorieActive).toList();

  int get _ressourcesVues => 0; // À calculer depuis API

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse(
        '${ApiConfig.baseUrl}/api/candidat/ressources-carrieres'));
      final body = jsonDecode(res.body);
      setState(() {
        _ressources = List<Map<String, dynamic>>.from(
          body['data'] ?? []);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _ouvrirRessource(Map<String, dynamic> r) {
    context.push('/dashboard-candidat/parcours/${r['id']}',
      extra: r);
  }

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.library_books_outlined,
          color: Color(0xFFE2E8F0), size: 56),
        const SizedBox(height: 16),
        Text('Aucune ressource disponible',
          style: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A))),
        const SizedBox(height: 8),
        Text('De nouveaux guides arrivent bientôt !',
          style: GoogleFonts.inter(
            fontSize: 13, color: const Color(0xFF64748B))),
      ])));
}
```

---

## 5. Simulateur d'entretien IA

```dart
// frontend/lib/screens/candidat/widgets/simulateur_entretien_ia.dart

class SimulateurEntretienIA extends StatefulWidget {
  const SimulateurEntretienIA({super.key});
  @override
  State<SimulateurEntretienIA> createState() =>
    _SimulateurState();
}

class _SimulateurState extends State<SimulateurEntretienIA> {

  // État
  String _phase = 'config'; // config | simulation | resultat
  String _posteVise   = '';
  String _domaine     = 'informatique';
  String _niveau      = 'junior';
  int    _nbQuestions = 5;

  List<Map<String, dynamic>> _questions = [];
  int    _questionActuelle = 0;
  bool   _isGenerating     = false;
  bool   _isEvaluating     = false;

  final _reponseCtrl = TextEditingController();
  List<Map<String, dynamic>> _reponses = [];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: switch (_phase) {
        'config'     => _buildConfig(),
        'simulation' => _buildSimulation(),
        'resultat'   => _buildResultat(),
        _            => _buildConfig(),
      });
  }

  // ── Phase 1 : Configuration ─────────────────────────────
  Widget _buildConfig() => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [

    // Header
    Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
        borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const Icon(Icons.psychology_rounded,
          color: Colors.white, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Simulateur d\'entretien IA',
            style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w800,
              color: Colors.white)),
          Text(
            'Claude IA vous pose des questions et évalue vos réponses',
            style: GoogleFonts.inter(
              fontSize: 12, color: Colors.white70)),
        ])),
      ])),
    const SizedBox(height: 20),

    _CarteConfig(titre: '🎯 Poste visé', children: [
      TextFormField(
        initialValue: _posteVise,
        decoration: InputDecoration(
          hintText: 'Ex: Développeur Flutter, Comptable, Marketeur...',
          hintStyle: GoogleFonts.inter(
            fontSize: 13, color: const Color(0xFFCBD5E1)),
          filled: true, fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0)))),
        onChanged: (v) => setState(() => _posteVise = v)),
    ]),
    const SizedBox(height: 14),

    _CarteConfig(titre: '📂 Domaine', children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        _ChoixOption('informatique', '💻 Informatique',  _domaine,
          (v) => setState(() => _domaine = v)),
        _ChoixOption('finance',      '💰 Finance',       _domaine,
          (v) => setState(() => _domaine = v)),
        _ChoixOption('marketing',    '📣 Marketing',     _domaine,
          (v) => setState(() => _domaine = v)),
        _ChoixOption('rh',           '👥 Ressources Humaines', _domaine,
          (v) => setState(() => _domaine = v)),
        _ChoixOption('commercial',   '🤝 Commercial',   _domaine,
          (v) => setState(() => _domaine = v)),
        _ChoixOption('autre',        '🔧 Autre',        _domaine,
          (v) => setState(() => _domaine = v)),
      ]),
    ]),
    const SizedBox(height: 14),

    _CarteConfig(titre: '📊 Niveau d\'expérience', children: [
      Row(children: [
        Expanded(child: _ChoixOption(
          'junior', '🌱 Junior (0-2 ans)', _niveau,
          (v) => setState(() => _niveau = v))),
        const SizedBox(width: 8),
        Expanded(child: _ChoixOption(
          'senior', '⭐ Senior (3-7 ans)', _niveau,
          (v) => setState(() => _niveau = v))),
        const SizedBox(width: 8),
        Expanded(child: _ChoixOption(
          'expert', '🏆 Expert (7+ ans)', _niveau,
          (v) => setState(() => _niveau = v))),
      ]),
    ]),
    const SizedBox(height: 14),

    _CarteConfig(titre: '❓ Nombre de questions', children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(
          onPressed: _nbQuestions > 3
              ? () => setState(() => _nbQuestions--)
              : null,
          icon: const Icon(Icons.remove_circle_outline)),
        Container(
          width: 60,
          alignment: Alignment.center,
          child: Text('$_nbQuestions',
            style: GoogleFonts.poppins(
              fontSize: 24, fontWeight: FontWeight.w800,
              color: const Color(0xFF8B5CF6)))),
        IconButton(
          onPressed: _nbQuestions < 10
              ? () => setState(() => _nbQuestions++)
              : null,
          icon: const Icon(Icons.add_circle_outline)),
      ]),
      Text('questions d\'entretien',
        style: GoogleFonts.inter(
          fontSize: 12, color: const Color(0xFF94A3B8)),
        textAlign: TextAlign.center),
    ]),
    const SizedBox(height: 24),

    // Bouton démarrer
    SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: _isGenerating
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.play_arrow_rounded, size: 20),
        label: Text(
          _isGenerating
              ? 'Génération en cours...'
              : 'Démarrer la simulation',
          style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B5CF6),
          foregroundColor: Colors.white, elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12))),
        onPressed: _isGenerating || _posteVise.trim().isEmpty
            ? null : _demarrerSimulation)),
    if (_posteVise.trim().isEmpty)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text('* Renseignez le poste visé pour commencer',
          style: GoogleFonts.inter(
            fontSize: 11, color: const Color(0xFFEF4444)),
          textAlign: TextAlign.center)),
  ]);

  // ── Phase 2 : Simulation ────────────────────────────────
  Widget _buildSimulation() {
    if (_questions.isEmpty) return const SizedBox();
    final q     = _questions[_questionActuelle];
    final total = _questions.length;
    final prog  = (_questionActuelle + 1) / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Progression
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6).withOpacity(0.08),
          borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            Text(
              'Question ${_questionActuelle + 1} / $total',
              style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: const Color(0xFF8B5CF6))),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(100)),
              child: Text(q['type'] ?? 'Question',
                style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: const Color(0xFF8B5CF6)))),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: prog, minHeight: 6,
              backgroundColor: const Color(0xFF8B5CF6)
                .withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation(
                Color(0xFF8B5CF6)))),
        ])),
      const SizedBox(height: 16),

      // Question
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F3FF),
                shape: BoxShape.circle),
              child: const Center(child: Text('🎤',
                style: TextStyle(fontSize: 16)))),
            const SizedBox(width: 10),
            Text('Question de l\'interviewer',
              style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFF94A3B8))),
          ]),
          const SizedBox(height: 12),
          Text(q['question'] as String? ?? '',
            style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A), height: 1.5)),
        ])),
      const SizedBox(height: 16),

      // Réponse candidat
      Text('Votre réponse :',
        style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: const Color(0xFF374151))),
      const SizedBox(height: 8),
      TextFormField(
        controller: _reponseCtrl,
        maxLines: 5,
        decoration: InputDecoration(
          hintText: 'Tapez votre réponse ici...',
          hintStyle: GoogleFonts.inter(
            fontSize: 13, color: const Color(0xFFCBD5E1)),
          filled: true, fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.all(14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color(0xFF8B5CF6), width: 1.5)))),
      const SizedBox(height: 16),

      // Bouton répondre
      Row(children: [
        if (_questionActuelle > 0)
          Expanded(child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
            onPressed: () => setState(() {
              _questionActuelle--;
              _reponseCtrl.text =
                _reponses.length > _questionActuelle
                    ? _reponses[_questionActuelle]['reponse'] ?? ''
                    : '';
            }),
            child: const Text('← Précédent'))),

        if (_questionActuelle > 0) const SizedBox(width: 10),

        Expanded(child: ElevatedButton.icon(
          icon: _isEvaluating
              ? const SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
              : Icon(
                  _questionActuelle < total - 1
                      ? Icons.arrow_forward_rounded
                      : Icons.check_rounded,
                  size: 16),
          label: Text(
            _isEvaluating ? 'Évaluation...'
            : _questionActuelle < total - 1
                ? 'Question suivante'
                : 'Terminer l\'entretien',
            style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10))),
          onPressed: _isEvaluating
              ? null : _repondreEtContinuer)),
      ]),
    ]);
  }

  // ── Phase 3 : Résultats ─────────────────────────────────
  Widget _buildResultat() {
    final scoreGlobal = _reponses.isEmpty ? 0
        : (_reponses.map((r) =>
            r['score'] as int? ?? 0).reduce((a, b) => a + b) /
            _reponses.length).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Score global
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: scoreGlobal >= 70
                ? [const Color(0xFF10B981), const Color(0xFF059669)]
                : scoreGlobal >= 50
                    ? [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)]
                    : [const Color(0xFFF59E0B), const Color(0xFFD97706)]),
          borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Text('Résultat de votre entretien',
            style: GoogleFonts.inter(
              fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 8),
          Text('$scoreGlobal / 100',
            style: GoogleFonts.poppins(
              fontSize: 48, fontWeight: FontWeight.w900,
              color: Colors.white)),
          Text(
            scoreGlobal >= 80
                ? '🎉 Excellent ! Vous êtes bien préparé'
                : scoreGlobal >= 60
                    ? '👍 Bon résultat, continuez à vous améliorer'
                    : '📈 Des axes d\'amélioration identifiés',
            style: GoogleFonts.inter(
              fontSize: 13, color: Colors.white70),
            textAlign: TextAlign.center),
        ])),
      const SizedBox(height: 16),

      // Détail par question
      Text('Détail par question',
        style: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A))),
      const SizedBox(height: 10),

      ..._reponses.asMap().entries.map((entry) {
        final i   = entry.key;
        final r   = entry.value;
        final s   = r['score'] as int? ?? 0;
        final sc  = s >= 70
            ? const Color(0xFF10B981)
            : s >= 50
                ? const Color(0xFF8B5CF6)
                : const Color(0xFFF59E0B);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sc.withOpacity(0.3))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Q${i + 1}',
                style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: const Color(0xFF94A3B8))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: sc.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100)),
                child: Text('$s / 100',
                  style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w800,
                    color: sc))),
            ]),
            const SizedBox(height: 6),
            Text(r['question'] as String? ?? '',
              style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: const Color(0xFF374151))),
            const SizedBox(height: 8),
            // Feedback IA
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: sc.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(children: [
                  const Icon(Icons.auto_awesome_rounded,
                    size: 12, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 4),
                  Text('Feedback IA :',
                    style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: const Color(0xFF8B5CF6))),
                ]),
                const SizedBox(height: 4),
                Text(r['feedback'] as String? ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF374151),
                    height: 1.4)),
              ])),
          ]));
      }),

      const SizedBox(height: 16),

      // Boutons
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Recommencer'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(
              color: Color(0xFF8B5CF6)),
            foregroundColor: const Color(0xFF8B5CF6),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10))),
          onPressed: () => setState(() {
            _phase           = 'config';
            _questions       = [];
            _reponses        = [];
            _questionActuelle = 0;
            _reponseCtrl.clear();
          }))),
      ]),
    ]);
  }

  // ── Actions ────────────────────────────────────────────
  Future<void> _demarrerSimulation() async {
    if (_posteVise.trim().isEmpty) return;
    setState(() => _isGenerating = true);

    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res   = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/candidat/simulateur/generer-questions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'poste_vise':   _posteVise.trim(),
          'domaine':      _domaine,
          'niveau':       _niveau,
          'nb_questions': _nbQuestions,
        })).timeout(const Duration(seconds: 30));

      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        setState(() {
          _questions = List<Map<String, dynamic>>.from(
            body['data']['questions'] ?? []);
          _reponses  = [];
          _questionActuelle = 0;
          _phase     = 'simulation';
          _reponseCtrl.clear();
        });
      } else {
        throw Exception(body['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating));
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _repondreEtContinuer() async {
    final reponse = _reponseCtrl.text.trim();
    if (reponse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Écrivez votre réponse avant de continuer'),
        behavior: SnackBarBehavior.floating));
      return;
    }

    setState(() => _isEvaluating = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final q     = _questions[_questionActuelle];

      final res = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/candidat/simulateur/evaluer-reponse'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'question':   q['question'],
          'reponse':    reponse,
          'poste_vise': _posteVise,
          'domaine':    _domaine,
          'niveau':     _niveau,
        })).timeout(const Duration(seconds: 20));

      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        final eval = body['data'] as Map<String, dynamic>;
        final rep  = {
          'question': q['question'],
          'reponse':  reponse,
          'score':    eval['score'] ?? 50,
          'feedback': eval['feedback'] ?? '',
          'points_forts':  eval['points_forts'] ?? [],
          'ameliorations': eval['ameliorations'] ?? [],
        };

        setState(() {
          if (_reponses.length > _questionActuelle) {
            _reponses[_questionActuelle] = rep;
          } else {
            _reponses.add(rep);
          }
        });

        if (_questionActuelle < _questions.length - 1) {
          setState(() {
            _questionActuelle++;
            _reponseCtrl.clear();
          });
        } else {
          // Sauvegarder la session
          await http.post(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/candidat/simulateur/sauvegarder'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'poste_vise': _posteVise,
              'domaine':    _domaine,
              'niveau':     _niveau,
              'questions':  _reponses,
              'score_global': (_reponses.map((r) =>
                  r['score'] as int? ?? 0)
                  .reduce((a, b) => a + b) /
                  _reponses.length).round(),
            }));
          setState(() => _phase = 'resultat');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur évaluation: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating));
    } finally {
      setState(() => _isEvaluating = false);
    }
  }
}
```

### Backend — Routes simulateur

```javascript
// Dans backend/src/routes/candidat/simulateur.routes.js

// Générer les questions avec Claude
router.post('/generer-questions', auth, async (req, res) => {
  try {
    const {
      poste_vise, domaine, niveau, nb_questions = 5
    } = req.body;

    const { _appellerIA, _getClesIA } =
      require('../../services/ia.service');
    const cles = await _getClesIA();

    const prompt =
      `Tu es un recruteur expert en Guinée (Afrique de l'Ouest).
Génère exactement ${nb_questions} questions d'entretien
pour le poste suivant :

Poste visé : ${poste_vise}
Domaine    : ${domaine}
Niveau     : ${niveau}

Varie les types de questions :
- Questions techniques sur le domaine
- Questions comportementales (STAR)
- Questions de mise en situation
- Questions de motivation
- Questions sur les expériences passées

Réponds UNIQUEMENT avec ce JSON :
{
  "questions": [
    {
      "question": "...",
      "type": "technique|comportemental|situation|motivation",
      "conseil": "Tip pour bien répondre (1 phrase)"
    }
  ]
}`;

    const texte = await _appellerIA(prompt, cles, 'matching');
    if (!texte) throw new Error('IA non disponible');

    const clean = texte
      .replace(/```json/g, '').replace(/```/g, '').trim();
    const data  = JSON.parse(clean);

    return res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Évaluer une réponse avec Claude
router.post('/evaluer-reponse', auth, async (req, res) => {
  try {
    const { question, reponse, poste_vise, domaine, niveau } = req.body;

    const { _appellerIA, _getClesIA } =
      require('../../services/ia.service');
    const cles = await _getClesIA();

    const prompt =
      `Tu es un recruteur expert. Évalue cette réponse d'entretien.

Contexte :
- Poste   : ${poste_vise}
- Domaine : ${domaine}
- Niveau  : ${niveau}

Question posée :
"${question}"

Réponse du candidat :
"${reponse}"

Évalue de manière bienveillante et constructive.
Tiens compte du contexte guinéen/africain.

Réponds UNIQUEMENT avec ce JSON :
{
  "score": <0-100>,
  "feedback": "<feedback principal en 2-3 phrases>",
  "points_forts": ["<point fort 1>", "<point fort 2>"],
  "ameliorations": ["<amélioration 1>", "<amélioration 2>"]
}`;

    const texte = await _appellerIA(prompt, cles, 'matching');
    if (!texte) throw new Error('IA non disponible');

    const clean = texte
      .replace(/```json/g, '').replace(/```/g, '').trim();
    const data  = JSON.parse(clean);

    return res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Sauvegarder la session
router.post('/sauvegarder', auth, async (req, res) => {
  try {
    const {
      poste_vise, domaine, niveau,
      questions, score_global
    } = req.body;

    await supabase.from('simulations_entretien').insert({
      utilisateur_id: req.user.id,
      poste_vise, domaine, niveau,
      questions,
      score_global,
      statut:         'termine',
      duree_minutes:  Math.round(questions.length * 3),
    });

    return res.json({
      success: true,
      message: 'Session sauvegardée ✅'
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});
```

---

## 6. Calculateur de salaire

```dart
// frontend/lib/screens/candidat/widgets/calculateur_salaire.dart

class CalculateurSalaire extends StatefulWidget {
  const CalculateurSalaire({super.key});
  @override
  State<CalculateurSalaire> createState() =>
    _CalculateurState();
}

class _CalculateurState extends State<CalculateurSalaire> {

  String _poste   = '';
  String _domaine = 'informatique';
  String _niveau  = 'junior';
  String _ville   = 'Conakry';
  bool   _isCalculating = false;
  Map<String, dynamic>? _resultat;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Header
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)]),
          borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const Icon(Icons.calculate_rounded,
            color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Calculateur de salaire',
              style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: Colors.white)),
            Text(
              'Estimez votre salaire avec l\'IA selon le marché guinéen',
              style: GoogleFonts.inter(
                fontSize: 12, color: Colors.white70)),
          ])),
        ])),
      const SizedBox(height: 20),

      // Formulaire
      _CarteConfig(titre: '💼 Informations du poste', children: [
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Titre du poste',
            hintText: 'Ex: Développeur Flutter, Comptable...',
            prefixIcon: const Icon(Icons.work_outline_rounded),
            filled: true, fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0)))),
          onChanged: (v) => setState(() => _poste = v)),
        const SizedBox(height: 12),

        // Domaine
        DropdownButtonFormField<String>(
          value: _domaine,
          decoration: InputDecoration(
            labelText: 'Domaine',
            prefixIcon: const Icon(Icons.category_outlined),
            filled: true, fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0)))),
          items: [
            'informatique', 'finance', 'marketing',
            'rh', 'commercial', 'btp', 'sante', 'education',
          ].map((d) => DropdownMenuItem(
            value: d,
            child: Text(_nomDomaine(d)))).toList(),
          onChanged: (v) =>
            setState(() => _domaine = v ?? _domaine)),
        const SizedBox(height: 12),

        // Niveau + Ville
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(
            value: _niveau,
            decoration: InputDecoration(
              labelText: 'Niveau',
              filled: true, fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0)))),
            items: const [
              DropdownMenuItem(
                value: 'junior', child: Text('Junior')),
              DropdownMenuItem(
                value: 'senior', child: Text('Senior')),
              DropdownMenuItem(
                value: 'expert', child: Text('Expert')),
            ],
            onChanged: (v) =>
              setState(() => _niveau = v ?? _niveau))),
          const SizedBox(width: 10),
          Expanded(child: DropdownButtonFormField<String>(
            value: _ville,
            decoration: InputDecoration(
              labelText: 'Ville',
              filled: true, fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0)))),
            items: const [
              DropdownMenuItem(
                value: 'Conakry', child: Text('Conakry')),
              DropdownMenuItem(
                value: 'Kindia', child: Text('Kindia')),
              DropdownMenuItem(
                value: 'Labé', child: Text('Labé')),
              DropdownMenuItem(
                value: 'Kankan', child: Text('Kankan')),
            ],
            onChanged: (v) =>
              setState(() => _ville = v ?? _ville))),
        ]),
      ]),
      const SizedBox(height: 16),

      // Bouton calculer
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: _isCalculating
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.auto_awesome_rounded, size: 18),
          label: Text(
            _isCalculating ? 'Analyse en cours...' : 'Calculer avec l\'IA',
            style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12))),
          onPressed: _isCalculating || _poste.trim().isEmpty
              ? null : _calculer)),

      // Résultat
      if (_resultat != null) ...[
        const SizedBox(height: 20),
        _buildResultat(),
      ],
    ]));

  Widget _buildResultat() {
    final min    = _resultat!['salaire_min'] as int? ?? 0;
    final max    = _resultat!['salaire_max'] as int? ?? 0;
    final median = _resultat!['salaire_median'] as int? ?? 0;
    final devise = _resultat!['devise'] as String? ?? 'GNF';
    final conseils = List<String>.from(
      _resultat!['conseils'] ?? []);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [

        Text('💰 Estimation salariale',
          style: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A))),
        const SizedBox(height: 14),

        // Fourchette
        Row(children: [
          Expanded(child: _SalaireBox(
            label: 'Minimum',
            montant: _formatMontant(min),
            devise: devise,
            couleur: const Color(0xFFF59E0B))),
          const SizedBox(width: 8),
          Expanded(child: _SalaireBox(
            label: 'Médian',
            montant: _formatMontant(median),
            devise: devise,
            couleur: const Color(0xFF10B981),
            isMis: true)),
          const SizedBox(width: 8),
          Expanded(child: _SalaireBox(
            label: 'Maximum',
            montant: _formatMontant(max),
            devise: devise,
            couleur: const Color(0xFF1A56DB))),
        ]),
        const SizedBox(height: 14),

        // Conseils
        if (conseils.isNotEmpty) ...[
          Text('💡 Conseils pour négocier',
            style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A))),
          const SizedBox(height: 8),
          ...conseils.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              const Icon(Icons.arrow_right_rounded,
                color: Color(0xFF10B981), size: 18),
              Expanded(child: Text(c,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF374151)))),
            ]))),
        ],
      ]));
  }

  Future<void> _calculer() async {
    setState(() { _isCalculating = true; _resultat = null; });
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res   = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/candidat/calculateur-salaire'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'poste':   _poste.trim(),
          'domaine': _domaine,
          'niveau':  _niveau,
          'ville':   _ville,
        })).timeout(const Duration(seconds: 20));

      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        setState(() => _resultat = body['data']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating));
    } finally {
      setState(() => _isCalculating = false);
    }
  }

  String _nomDomaine(String d) => {
    'informatique': '💻 Informatique',
    'finance':      '💰 Finance',
    'marketing':    '📣 Marketing',
    'rh':           '👥 RH',
    'commercial':   '🤝 Commercial',
    'btp':          '🏗️ BTP',
    'sante':        '🏥 Santé',
    'education':    '📚 Éducation',
  }[d] ?? d;

  String _formatMontant(int m) =>
    m.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ');
}

class _SalaireBox extends StatelessWidget {
  final String label, montant, devise;
  final Color couleur; final bool isMis;
  const _SalaireBox({required this.label,
    required this.montant, required this.devise,
    required this.couleur, this.isMis = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: couleur.withOpacity(isMis ? 0.12 : 0.06),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: couleur.withOpacity(isMis ? 0.5 : 0.2),
        width: isMis ? 2 : 1)),
    child: Column(children: [
      Text(label, style: GoogleFonts.inter(
        fontSize: 10, color: const Color(0xFF94A3B8))),
      const SizedBox(height: 4),
      Text(montant, style: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w900,
        color: couleur)),
      Text(devise, style: GoogleFonts.inter(
        fontSize: 9, color: const Color(0xFF94A3B8))),
    ]));
}
```

### Backend — Route calculateur salaire

```javascript
// Dans backend/src/routes/candidat.routes.js

router.post('/calculateur-salaire', auth, async (req, res) => {
  try {
    const { poste, domaine, niveau, ville } = req.body;

    const { _appellerIA, _getClesIA } =
      require('../services/ia.service');
    const cles = await _getClesIA();

    const prompt =
      `Tu es un expert RH spécialiste du marché de l'emploi en Guinée (Conakry).

Estime la fourchette salariale pour :
- Poste   : ${poste}
- Domaine : ${domaine}
- Niveau  : ${niveau} (junior=0-2 ans, senior=3-7 ans, expert=7+ ans)
- Ville   : ${ville}, Guinée

Donne une estimation réaliste basée sur le marché guinéen 2024-2025.
Les salaires en Guinée sont en GNF (Franc Guinéen).
1 USD ≈ 8 600 GNF en 2025.

Réponds UNIQUEMENT avec ce JSON :
{
  "salaire_min":    <montant en GNF>,
  "salaire_median": <montant en GNF>,
  "salaire_max":    <montant en GNF>,
  "devise":         "GNF",
  "equivalent_usd": {
    "min":    <en USD>,
    "median": <en USD>,
    "max":    <en USD>
  },
  "conseils": [
    "<conseil négociation 1>",
    "<conseil négociation 2>",
    "<conseil négociation 3>"
  ],
  "facteurs": "<explication courte des facteurs influençant ce salaire>"
}`;

    const texte = await _appellerIA(prompt, cles, 'matching');
    if (!texte) throw new Error('IA non disponible');

    const clean = texte
      .replace(/```json/g, '').replace(/```/g, '').trim();
    const data  = JSON.parse(clean);

    return res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});
```

---

## 7. Notifications nouvelles ressources

```javascript
// Déjà intégré dans la route admin POST /ressources
// Quand une ressource est publiée → notif envoyée à tous les candidats

// Backend : la fonction _notifierNouvelleRessource()
// est appelée automatiquement lors de la publication
```

```dart
// Flutter : le badge de notification dans la sidebar
// sera mis à jour automatiquement via le polling
// existant dans CandidatProvider
```

---

## Critères d'Acceptation

### ✅ Gestion ressources (Admin)
- [ ] Admin peut créer : articles, PDF, vidéos YouTube, vidéos internes
- [ ] Admin peut publier/dépublier
- [ ] Notification automatique aux candidats à la publication
- [ ] Filtrage par catégorie

### ✅ Page Parcours Carrière (Candidat)
- [ ] Hero section avec stats
- [ ] 3 outils IA visibles en haut
- [ ] Filtres par catégorie (CV, Entretien, Salaire...)
- [ ] Ressources affichées en cards
- [ ] Vidéos YouTube lisibles dans la page

### ✅ Simulateur d'entretien IA
- [ ] Configuration : poste, domaine, niveau, nb questions
- [ ] Claude génère les questions pertinentes
- [ ] Claude évalue chaque réponse (score + feedback)
- [ ] Résultat final avec score global + détail
- [ ] Session sauvegardée en BDD

### ✅ Calculateur de salaire
- [ ] Claude estime la fourchette selon le marché guinéen
- [ ] Affichage min/médian/max en GNF et USD
- [ ] Conseils de négociation personnalisés

---

*PRD EmploiConnect v8.7 — Parcours Carrière IA*
*Cursor / Kirsoft AI — Phase 20*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
