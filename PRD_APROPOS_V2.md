# PRD — EmploiConnect · Page À propos V2
## Product Requirements Document v9.10
**Date : Avril 2026**

---

## Vision

```
Page À propos professionnelle avec :
1. Hero animé + vrais chiffres depuis la BDD
2. Sections Mission/Vision/Valeurs (existantes)
3. Section Équipe avec photos uploadées depuis l'admin
4. Formulaire de contact fonctionnel
5. Coordonnées depuis les paramètres plateforme
```

---

## 1. Migration SQL

```sql
-- database/migrations/061_equipe_contact.sql

-- Table membres de l'équipe
CREATE TABLE IF NOT EXISTS equipe_membres (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nom         TEXT NOT NULL,
  poste       TEXT,
  description TEXT,
  photo_url   TEXT,
  linkedin    TEXT,
  ordre       INTEGER DEFAULT 0,
  est_actif   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Table messages de contact
CREATE TABLE IF NOT EXISTS messages_contact (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nom         TEXT NOT NULL,
  email       TEXT NOT NULL,
  sujet       TEXT,
  message     TEXT NOT NULL,
  est_lu      BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_equipe_ordre
  ON equipe_membres(ordre, est_actif);
CREATE INDEX IF NOT EXISTS idx_contact_lu
  ON messages_contact(est_lu, created_at DESC);

-- Insérer l'équipe fondatrice par défaut
INSERT INTO equipe_membres
  (nom, poste, description, ordre)
VALUES
  ('BARRY YOUSSOUF',
   'Fondateur & Développeur Full Stack',
   'Étudiant en Licence Professionnelle Génie Logiciel. '
   'Développeur et architecte de la plateforme EmploiConnect.',
   1),
  ('DIALLO ISMAILA',
   'Co-Fondateur & Designer',
   'Étudiant en Licence Professionnelle Génie Logiciel. '
   'Co-développeur et responsable design de la plateforme.',
   2)
ON CONFLICT DO NOTHING;
```

---

## 2. Backend — Routes équipe + contact

```javascript
// backend/src/routes/apropos.routes.js
// Ajouter ces routes

const multer = require('multer');
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }
});

// ── Équipe (public) ──────────────────────────────────
router.get('/equipe', async (req, res) => {
  try {
    const { data } = await supabase
      .from('equipe_membres')
      .select('*')
      .eq('est_actif', true)
      .order('ordre', { ascending: true });
    return res.json({ success: true, data: data || [] });
  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});

// ── Contact (public) ─────────────────────────────────
router.post('/contact', async (req, res) => {
  try {
    const { nom, email, sujet, message } = req.body;

    if (!nom || !email || !message) {
      return res.status(400).json({
        success: false,
        message: 'Nom, email et message requis'
      });
    }

    // Valider email
    if (!email.includes('@')) {
      return res.status(400).json({
        success: false,
        message: 'Email invalide'
      });
    }

    // Sauvegarder en BDD
    const { error } = await supabase
      .from('messages_contact')
      .insert({ nom, email, sujet, message });

    if (error) throw error;

    // Envoyer un email de notification à l'admin
    try {
      const { data: params } = await supabase
        .from('parametres_plateforme')
        .select('valeur')
        .eq('cle', 'email_contact')
        .single();

      if (params?.valeur) {
        await envoyerEmail({
          to:      params.valeur,
          subject: `[Contact EmploiConnect] ${sujet || 'Nouveau message'}`,
          html: `
            <h2>Nouveau message de contact</h2>
            <p><strong>De :</strong> ${nom} (${email})</p>
            <p><strong>Sujet :</strong> ${sujet || 'Non précisé'}</p>
            <p><strong>Message :</strong></p>
            <p>${message.replace(/\n/g, '<br>')}</p>
          `
        });
      }
    } catch (_) {}

    return res.json({
      success: true,
      message: 'Message envoyé ! Nous vous répondrons bientôt.'
    });
  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});

// ── Admin : CRUD équipe ──────────────────────────────

// GET /api/admin/equipe
router.get('/admin/equipe', auth, requireAdmin,
  async (req, res) => {
  const { data } = await supabase
    .from('equipe_membres')
    .select('*')
    .order('ordre', { ascending: true });
  return res.json({ success: true, data: data || [] });
});

// POST /api/admin/equipe — Créer membre
router.post('/admin/equipe', auth, requireAdmin,
  upload.single('photo'), async (req, res) => {
  try {
    const { nom, poste, description, linkedin, ordre } =
      req.body;
    let photoUrl = null;

    if (req.file) {
      const ext = req.file.originalname
        .split('.').pop() || 'jpg';
      const chemin = `equipe/${Date.now()}.${ext}`;
      const { error } = await supabase.storage
        .from('avatars')
        .upload(chemin, req.file.buffer, {
          contentType: req.file.mimetype || 'image/jpeg',
          upsert: true });
      if (!error) {
        const { data: pub } = supabase.storage
          .from('avatars').getPublicUrl(chemin);
        photoUrl = pub.publicUrl;
      }
    }

    const { data, error } = await supabase
      .from('equipe_membres')
      .insert({
        nom, poste, description, linkedin,
        photo_url: photoUrl,
        ordre: parseInt(ordre || '0'),
      })
      .select().single();

    if (error) throw error;
    return res.status(201).json({
      success: true, data });
  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});

// PUT /api/admin/equipe/:id — Modifier
router.put('/admin/equipe/:id', auth, requireAdmin,
  upload.single('photo'), async (req, res) => {
  try {
    const { nom, poste, description, linkedin,
      ordre, est_actif } = req.body;
    const updates = {};
    if (nom        !== undefined) updates.nom        = nom;
    if (poste      !== undefined) updates.poste      = poste;
    if (description !== undefined)
      updates.description = description;
    if (linkedin   !== undefined) updates.linkedin   = linkedin;
    if (ordre      !== undefined)
      updates.ordre = parseInt(ordre);
    if (est_actif  !== undefined)
      updates.est_actif = est_actif === 'true';

    if (req.file) {
      const ext = req.file.originalname
        .split('.').pop() || 'jpg';
      const chemin = `equipe/${Date.now()}.${ext}`;
      const { error } = await supabase.storage
        .from('avatars')
        .upload(chemin, req.file.buffer, {
          contentType: req.file.mimetype || 'image/jpeg',
          upsert: true });
      if (!error) {
        const { data: pub } = supabase.storage
          .from('avatars').getPublicUrl(chemin);
        updates.photo_url = pub.publicUrl;
      }
    }

    const { data, error } = await supabase
      .from('equipe_membres')
      .update(updates)
      .eq('id', req.params.id)
      .select().single();
    if (error) throw error;
    return res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});

// DELETE /api/admin/equipe/:id
router.delete('/admin/equipe/:id', auth, requireAdmin,
  async (req, res) => {
  await supabase.from('equipe_membres')
    .update({ est_actif: false })
    .eq('id', req.params.id);
  return res.json({ success: true });
});

// GET /api/admin/messages-contact
router.get('/admin/messages-contact', auth, requireAdmin,
  async (req, res) => {
  const { data, count } = await supabase
    .from('messages_contact')
    .select('*', { count: 'exact' })
    .order('created_at', { ascending: false });
  return res.json({
    success: true,
    data: data || [],
    non_lus: (data || []).filter(m => !m.est_lu).length
  });
});

// PATCH /api/admin/messages-contact/:id/lire
router.patch('/admin/messages-contact/:id/lire',
  auth, requireAdmin, async (req, res) => {
  await supabase.from('messages_contact')
    .update({ est_lu: true })
    .eq('id', req.params.id);
  return res.json({ success: true });
});
```

---

## 3. Flutter — Page À propos V2

```dart
// frontend/lib/screens/about/about_page.dart
// Version complète redesignée

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});
  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with TickerProviderStateMixin {

  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _equipe   = [];
  Map<String, dynamic>       _config   = {};
  bool _isLoading = true;

  // Stats
  int _nbCandidats   = 0;
  int _nbEntreprises = 0;
  int _nbOffres      = 0;

  late AnimationController _statsCtrl;

  @override
  void initState() {
    super.initState();
    _statsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000));
    _loadAll();
  }

  @override
  void dispose() {
    _statsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    try {
      final results = await Future.wait([
        http.get(Uri.parse(
          '${ApiConfig.baseUrl}/api/apropos')),
        http.get(Uri.parse(
          '${ApiConfig.baseUrl}/api/apropos/equipe')),
        http.get(Uri.parse(
          '${ApiConfig.baseUrl}/api/stats/homepage')),
        http.get(Uri.parse(
          '${ApiConfig.baseUrl}/api/config/general')),
      ]);

      final sections = jsonDecode(results[0].body);
      final equipe   = jsonDecode(results[1].body);
      final stats    = jsonDecode(results[2].body);
      final config   = jsonDecode(results[3].body);

      if (mounted) {
        setState(() {
          _sections = List<Map<String, dynamic>>.from(
            sections['data'] ?? []);
          _equipe = List<Map<String, dynamic>>.from(
            equipe['data'] ?? []);
          _config = Map<String, dynamic>.from(
            config['data'] ?? {});
          final d = stats['data'] as Map? ?? {};
          _nbCandidats   = d['candidats']   as int? ?? 0;
          _nbEntreprises = d['entreprises'] as int? ?? 0;
          _nbOffres      = d['offres']       as int? ?? 0;
          _isLoading = false;
        });
        _statsCtrl.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? _section(String s) =>
    _sections.where((x) => x['section'] == s)
      .firstOrNull;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isDark = Theme.of(context).brightness
      == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(
              color: Color(0xFF1A56DB)))
          : CustomScrollView(slivers: [

          // ── AppBar ──────────────────────────────
          SliverAppBar(
            pinned: true, elevation: 0,
            backgroundColor: isDark
                ? const Color(0xFF1E293B) : Colors.white,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded,
                color: isDark ? Colors.white
                    : const Color(0xFF374151)),
              onPressed: () => context.go('/')),
            title: const AuthLogoHeader()),

          // ── Hero ────────────────────────────────
          SliverToBoxAdapter(child: _buildHero(isMobile)),

          // ── Stats animées ────────────────────────
          SliverToBoxAdapter(
            child: _buildStats(isMobile, isDark)),

          // ── Sections (Mission/Vision/Valeurs) ───
          SliverToBoxAdapter(child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 80,
              vertical: 48),
            child: Column(children: [

              // Mission + Vision
              isMobile
                  ? Column(children: [
                      _buildSection('mission', isDark),
                      const SizedBox(height: 16),
                      _buildSection('vision', isDark),
                    ])
                  : Row(children: [
                      Expanded(child:
                        _buildSection('mission', isDark)),
                      const SizedBox(width: 16),
                      Expanded(child:
                        _buildSection('vision', isDark)),
                    ]),
              const SizedBox(height: 16),

              // Valeurs
              _buildSection('valeurs', isDark,
                pleineLargeur: true),
            ]))),

          // ── Équipe ──────────────────────────────
          SliverToBoxAdapter(
            child: _buildEquipe(isMobile, isDark)),

          // ── Contact ──────────────────────────────
          SliverToBoxAdapter(
            child: _buildContact(isMobile, isDark)),

          // ── Footer ──────────────────────────────
          SliverToBoxAdapter(child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 40, vertical: 20),
            color: const Color(0xFF0D1B3E),
            child: Text(
              '© 2025 EmploiConnect · Guinée',
              style: GoogleFonts.inter(
                fontSize: 12, color: Colors.white38),
              textAlign: TextAlign.center))),
        ]));
  }

  Widget _buildHero(bool isMobile) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: isMobile ? 24 : 80,
      vertical: isMobile ? 48 : 80),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A56DB), Color(0xFF4F46E5)])),
    child: Column(children: [
      // Badge
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(100)),
        child: Text('🇬🇳 La plateforme guinéenne de l\'emploi',
          style: GoogleFonts.inter(
            fontSize: 12, color: Colors.white,
            fontWeight: FontWeight.w600))),
      const SizedBox(height: 20),

      // Titre
      Text(
        _section('hero')?['titre'] as String?
            ?? 'À propos d\'EmploiConnect',
        style: GoogleFonts.poppins(
          fontSize: isMobile ? 28 : 44,
          fontWeight: FontWeight.w900,
          color: Colors.white, height: 1.1),
        textAlign: TextAlign.center),
      const SizedBox(height: 16),
      Text(
        _section('hero')?['contenu'] as String?
            ?? '',
        style: GoogleFonts.inter(
          fontSize: isMobile ? 14 : 17,
          color: Colors.white.withOpacity(0.8),
          height: 1.6),
        textAlign: TextAlign.center),
    ]));

  Widget _buildStats(bool isMobile, bool isDark) =>
    Container(
    padding: EdgeInsets.symmetric(
      horizontal: isMobile ? 24 : 80,
      vertical: 40),
    color: isDark
        ? const Color(0xFF1E293B) : Colors.white,
    child: Column(children: [
      Text('Nos chiffres',
        style: GoogleFonts.poppins(
          fontSize: 20, fontWeight: FontWeight.w800,
          color: isDark ? Colors.white
              : const Color(0xFF0F172A))),
      const SizedBox(height: 8),
      Text('Des résultats réels, mesurés chaque jour',
        style: GoogleFonts.inter(
          fontSize: 13,
          color: isDark ? const Color(0xFF94A3B8)
              : const Color(0xFF64748B))),
      const SizedBox(height: 28),
      Wrap(
        spacing: 24, runSpacing: 24,
        alignment: WrapAlignment.center,
        children: [
        _StatAnimee(
          ctrl:    _statsCtrl,
          valeur:  _nbCandidats,
          label:   'Candidats inscrits',
          icone:   '👤',
          couleur: const Color(0xFF1A56DB)),
        _StatAnimee(
          ctrl:    _statsCtrl,
          valeur:  _nbEntreprises,
          label:   'Entreprises partenaires',
          icone:   '🏢',
          couleur: const Color(0xFF10B981)),
        _StatAnimee(
          ctrl:    _statsCtrl,
          valeur:  _nbOffres,
          label:   'Offres publiées',
          icone:   '💼',
          couleur: const Color(0xFF8B5CF6)),
        _StatAnimee(
          ctrl:    _statsCtrl,
          valeur:  98,
          label:   '% Satisfaction',
          icone:   '⭐',
          couleur: const Color(0xFFF59E0B),
          suffixe: '%'),
      ]),
    ]));

  Widget _buildSection(String section, bool isDark,
      {bool pleineLargeur = false}) {
    final s = _section(section);
    if (s == null) return const SizedBox();
    return Container(
      width: pleineLargeur ? double.infinity : null,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(
            isDark ? 0.2 : 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2))]),
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
              color: isDark ? Colors.white
                  : const Color(0xFF0F172A)))),
        ]),
        const SizedBox(height: 12),
        Text(s['contenu'] as String? ?? '',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF64748B),
            height: 1.7)),
      ]));
  }

  Widget _buildEquipe(bool isMobile, bool isDark) =>
    Container(
    padding: EdgeInsets.symmetric(
      horizontal: isMobile ? 24 : 80,
      vertical: 60),
    color: isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC),
    child: Column(children: [
      // Titre section
      Text('Notre Équipe',
        style: GoogleFonts.poppins(
          fontSize: 28, fontWeight: FontWeight.w900,
          color: isDark ? Colors.white
              : const Color(0xFF0F172A))),
      const SizedBox(height: 8),
      Text(
        'Les personnes passionnées derrière EmploiConnect',
        style: GoogleFonts.inter(
          fontSize: 14,
          color: isDark ? const Color(0xFF94A3B8)
              : const Color(0xFF64748B))),
      const SizedBox(height: 40),

      // Grille équipe
      if (_equipe.isEmpty)
        Text('Équipe en cours de configuration...',
          style: GoogleFonts.inter(
            color: const Color(0xFF94A3B8)))
      else
        Wrap(
          spacing: 24, runSpacing: 24,
          alignment: WrapAlignment.center,
          children: _equipe.map((m) =>
            _CarteMembreEquipe(
              membre: m, isDark: isDark,
              isMobile: isMobile))
            .toList()),
    ]));

  Widget _buildContact(bool isMobile, bool isDark) =>
    Container(
    padding: EdgeInsets.symmetric(
      horizontal: isMobile ? 24 : 80,
      vertical: 60),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF1E293B),
               const Color(0xFF0F172A)]
            : [const Color(0xFFF0F7FF),
               Colors.white])),
    child: isMobile
        ? Column(children: [
            _infosContact(isDark),
            const SizedBox(height: 32),
            _FormContact(isDark: isDark),
          ])
        : Row(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Expanded(flex: 2, child:
              _infosContact(isDark)),
            const SizedBox(width: 48),
            Expanded(flex: 3, child:
              _FormContact(isDark: isDark)),
          ]));

  Widget _infosContact(bool isDark) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text('Nous contacter',
      style: GoogleFonts.poppins(
        fontSize: 24, fontWeight: FontWeight.w800,
        color: isDark ? Colors.white
            : const Color(0xFF0F172A))),
    const SizedBox(height: 12),
    Text(
      'Une question ? Un partenariat ? '
      'N\'hésitez pas à nous écrire.',
      style: GoogleFonts.inter(
        fontSize: 14,
        color: isDark ? const Color(0xFF94A3B8)
            : const Color(0xFF64748B),
        height: 1.6)),
    const SizedBox(height: 24),
    if ((_config['email_contact'] ?? '').isNotEmpty)
      _InfoContactItem(
        icone: Icons.email_outlined,
        valeur: _config['email_contact'] as String),
    if ((_config['telephone_contact'] ?? '').isNotEmpty)
      _InfoContactItem(
        icone: Icons.phone_outlined,
        valeur: _config['telephone_contact'] as String),
    if ((_config['adresse_contact'] ?? '').isNotEmpty)
      _InfoContactItem(
        icone: Icons.location_on_outlined,
        valeur: _config['adresse_contact'] as String),
  ]);
}

// ── Stat animée ──────────────────────────────────────────
class _StatAnimee extends StatelessWidget {
  final AnimationController ctrl;
  final int     valeur;
  final String  label, icone;
  final Color   couleur;
  final String  suffixe;
  const _StatAnimee({
    required this.ctrl, required this.valeur,
    required this.label, required this.icone,
    required this.couleur, this.suffixe = '+'});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness
      == Brightness.dark;
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: couleur.withOpacity(0.2)),
        boxShadow: [BoxShadow(
          color: couleur.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 4))]),
      child: Column(children: [
        Text(icone, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: ctrl,
          builder: (_, __) {
            final v = (valeur * ctrl.value).round();
            final txt = valeur == 0
                ? 'Bientôt'
                : '$v$suffixe';
            return Text(txt,
              style: GoogleFonts.poppins(
                fontSize: 28, fontWeight: FontWeight.w900,
                color: couleur));
          }),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(
          fontSize: 11,
          color: isDark
              ? const Color(0xFF94A3B8)
              : const Color(0xFF64748B)),
          textAlign: TextAlign.center),
      ]));
  }
}

// ── Carte membre équipe ───────────────────────────────────
class _CarteMembreEquipe extends StatefulWidget {
  final Map<String, dynamic> membre;
  final bool isDark, isMobile;
  const _CarteMembreEquipe({
    required this.membre, required this.isDark,
    required this.isMobile});
  @override
  State<_CarteMembreEquipe> createState() =>
    _CarteMembreState();
}

class _CarteMembreState extends State<_CarteMembreEquipe> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final m      = widget.membre;
    final photo  = m['photo_url']   as String?;
    final nom    = m['nom']         as String? ?? '';
    final poste  = m['poste']       as String? ?? '';
    final desc   = m['description'] as String? ?? '';
    final li     = m['linkedin']    as String?;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.isMobile ? double.infinity : 240,
        transform: Matrix4.identity()
          ..translate(0.0, _hovered ? -6.0 : 0.0),
        decoration: BoxDecoration(
          color: widget.isDark
              ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? const Color(0xFF1A56DB).withOpacity(0.4)
                : widget.isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(
            color: _hovered
                ? const Color(0xFF1A56DB).withOpacity(0.12)
                : Colors.black.withOpacity(0.04),
            blurRadius: _hovered ? 20 : 8,
            offset: const Offset(0, 4))]),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            // Photo ou initiales
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: photo == null
                    ? const LinearGradient(
                        colors: [Color(0xFF1A56DB),
                                 Color(0xFF7C3AED)])
                    : null,
                border: Border.all(
                  color: const Color(0xFF1A56DB)
                    .withOpacity(0.3), width: 3),
                boxShadow: [BoxShadow(
                  color: const Color(0xFF1A56DB)
                    .withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4))]),
              child: photo != null
                  ? ClipOval(child: Image.network(
                      photo, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                        _initiales(nom)))
                  : _initiales(nom)),
            const SizedBox(height: 16),

            // Nom
            Text(nom,
              style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: widget.isDark ? Colors.white
                    : const Color(0xFF0F172A)),
              textAlign: TextAlign.center),
            const SizedBox(height: 4),

            // Poste
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A56DB)
                  .withOpacity(0.1),
                borderRadius: BorderRadius.circular(100)),
              child: Text(poste,
                style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A56DB)),
                textAlign: TextAlign.center)),
            const SizedBox(height: 10),

            // Description
            if (desc.isNotEmpty)
              Text(desc,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: widget.isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  height: 1.5),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis),

            // LinkedIn
            if (li != null && li.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => launchUrl(Uri.parse(li)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A66C2)
                      .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min,
                    children: [
                    const Icon(Icons.link_rounded,
                      color: Color(0xFF0A66C2), size: 14),
                    const SizedBox(width: 4),
                    Text('LinkedIn',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A66C2))),
                  ]))),
            ],
          ]))));
  }

  Widget _initiales(String nom) => Center(child: Text(
    nom.split(' ').take(2)
      .map((w) => w.isNotEmpty ? w[0] : '')
      .join().toUpperCase(),
    style: const TextStyle(
      color: Colors.white, fontSize: 28,
      fontWeight: FontWeight.w900)));
}

// ── Info contact item ─────────────────────────────────────
class _InfoContactItem extends StatelessWidget {
  final IconData icone; final String valeur;
  const _InfoContactItem({
    required this.icone, required this.valeur});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness
      == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1A56DB).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
          child: Icon(icone,
            color: const Color(0xFF1A56DB), size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Text(valeur,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? Colors.white
                : const Color(0xFF374151),
            fontWeight: FontWeight.w500))),
      ]));
  }
}

// ── Formulaire de contact ─────────────────────────────────
class _FormContact extends StatefulWidget {
  final bool isDark;
  const _FormContact({required this.isDark});
  @override
  State<_FormContact> createState() => _FormContactState();
}

class _FormContactState extends State<_FormContact> {
  final _formKey  = GlobalKey<FormState>();
  final _nomCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _sujetCtrl = TextEditingController();
  final _msgCtrl  = TextEditingController();
  bool  _isSending = false;
  bool  _envoye    = false;

  @override
  void dispose() {
    _nomCtrl.dispose(); _emailCtrl.dispose();
    _sujetCtrl.dispose(); _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_envoye) return _buildSucces();

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDark
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 16, offset: const Offset(0, 4))]),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text('Envoyer un message',
            style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w800,
              color: widget.isDark ? Colors.white
                  : const Color(0xFF0F172A))),
          const SizedBox(height: 20),

          // Nom + Email
          Row(children: [
            Expanded(child: _champContact(
              _nomCtrl, 'Votre nom *',
              'Mamadou Barry',
              Icons.person_outline_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _champContact(
              _emailCtrl, 'Email *',
              'votre@email.com',
              Icons.email_outlined,
              keyType: TextInputType.emailAddress)),
          ]),
          const SizedBox(height: 12),

          // Sujet
          _champContact(
            _sujetCtrl, 'Sujet',
            'Ex: Partenariat, Question...',
            Icons.subject_rounded),
          const SizedBox(height: 12),

          // Message
          _champContact(
            _msgCtrl, 'Message *',
            'Décrivez votre demande...',
            Icons.message_outlined,
            maxLines: 4,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Message requis' : null),
          const SizedBox(height: 20),

          // Bouton
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isSending
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(
                _isSending ? 'Envoi...' : 'Envoyer le message',
                style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(
                  vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
              onPressed: _isSending ? null : _envoyer)),
        ]));
  }

  Widget _buildSucces() => Container(
    padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(
      color: widget.isDark
          ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(20)),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        builder: (_, v, child) =>
          Transform.scale(scale: v, child: child),
        child: Container(
          width: 70, height: 70,
          decoration: const BoxDecoration(
            color: Color(0xFFECFDF5),
            shape: BoxShape.circle),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF10B981), size: 40))),
      const SizedBox(height: 16),
      Text('Message envoyé !',
        style: GoogleFonts.poppins(
          fontSize: 20, fontWeight: FontWeight.w800,
          color: widget.isDark ? Colors.white
              : const Color(0xFF0F172A))),
      const SizedBox(height: 8),
      Text(
        'Merci pour votre message.\n'
        'Nous vous répondrons dans les plus brefs délais.',
        style: GoogleFonts.inter(
          fontSize: 13,
          color: widget.isDark
              ? const Color(0xFF94A3B8)
              : const Color(0xFF64748B),
          height: 1.5),
        textAlign: TextAlign.center),
    ]));

  Widget _champContact(
    TextEditingController ctrl, String label, String hint,
    IconData icone, {
    int maxLines = 1,
    TextInputType? keyType,
    String? Function(String?)? validator,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(label, style: GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w600,
      color: widget.isDark
          ? const Color(0xFFE2E8F0)
          : const Color(0xFF374151))),
    const SizedBox(height: 6),
    TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyType,
      validator: validator ?? (v) =>
        label.endsWith('*') && (v == null || v.trim().isEmpty)
            ? 'Champ requis' : null,
      style: GoogleFonts.inter(
        fontSize: 13,
        color: widget.isDark ? Colors.white
            : const Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 12, color: const Color(0xFFCBD5E1)),
        prefixIcon: maxLines == 1
            ? Icon(icone, size: 16,
                color: const Color(0xFF94A3B8))
            : null,
        filled: true,
        fillColor: widget.isDark
            ? const Color(0xFF334155)
            : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: widget.isDark
                ? const Color(0xFF475569)
                : const Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: widget.isDark
                ? const Color(0xFF475569)
                : const Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFF1A56DB), width: 1.5)))),
  ]);

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);
    try {
      final res = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/apropos/contact'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nom':     _nomCtrl.text.trim(),
          'email':   _emailCtrl.text.trim(),
          'sujet':   _sujetCtrl.text.trim(),
          'message': _msgCtrl.text.trim(),
        }));
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        setState(() => _envoye = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(body['message'] ?? 'Erreur'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}
```

---

## 4. Admin — Gestion équipe + messages contact

```dart
// Dans admin_settings_screen.dart → onglet Contenu
// Ajouter section Équipe

_CarteSection(
  titre: '👥 Notre Équipe',
  sousTitre: 'Membres affichés sur la page À propos',
  children: [
  // Bouton ajouter
  SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      icon: const Icon(Icons.person_add_rounded, size: 14),
      label: const Text('Ajouter un membre'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A56DB),
        foregroundColor: Colors.white, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8))),
      onPressed: () => _showDialogAddMembre())),
  const SizedBox(height: 12),

  // Liste membres
  ..._equipe.map((m) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(
      radius: 20,
      backgroundImage: m['photo_url'] != null
          ? NetworkImage(m['photo_url'] as String)
          : null,
      child: m['photo_url'] == null
          ? Text((m['nom'] as String? ?? 'A')[0],
              style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700))
          : null),
    title: Text(m['nom'] as String? ?? '',
      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
    subtitle: Text(m['poste'] as String? ?? '',
      style: GoogleFonts.inter(fontSize: 11)),
    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        icon: const Icon(Icons.edit_rounded, size: 16),
        onPressed: () => _showDialogEditMembre(m)),
      IconButton(
        icon: const Icon(Icons.delete_outline_rounded,
          size: 16, color: Color(0xFFEF4444)),
        onPressed: () => _supprimerMembre(m['id'])),
    ]))).toList(),
]),

// Ajouter aussi une entrée dans le menu sidebar admin
// → "Messages Contact" avec badge non-lus
```

---

## Critères d'Acceptation

- [ ] Migration SQL 061 exécutée
- [ ] Route GET /api/apropos/equipe publique
- [ ] Route POST /api/apropos/contact fonctionnelle
- [ ] Email de notification à l'admin
- [ ] Page À propos avec stats animées réelles
- [ ] Section équipe avec cartes photo
- [ ] Hover animation sur les cartes équipe
- [ ] Formulaire contact avec validation
- [ ] Page succès après envoi message
- [ ] Admin peut ajouter/modifier/supprimer membres
- [ ] Admin reçoit les messages de contact
- [ ] Mode sombre supporté partout

---

*PRD EmploiConnect v9.10 — Page À propos V2*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
