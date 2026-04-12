# PRD — EmploiConnect · Section Illustration IA + DALL-E
## Product Requirements Document v9.2
**Stack : Flutter + Node.js/Express + Supabase + OpenAI DALL-E**
**Date : Avril 2026**

---

## Vision

```
La section illustration de la homepage affiche
une belle image générée par IA chaque jour.
Le fond de l'illustration est transparent/supprimé.
L'admin peut activer/désactiver la génération IA
ou uploader manuellement une image.
```

---

## Table des Matières

1. [Migration SQL — Table illustrations_ia](#1-migration-sql)
2. [Backend — Service génération DALL-E](#2-backend--service-dall-e)
3. [Backend — Cron job quotidien](#3-cron-job-quotidien)
4. [Backend — Routes illustration](#4-routes-illustration)
5. [Admin — Gestion illustrations](#5-admin--gestion-illustrations)
6. [Flutter — Section illustration améliorée](#6-flutter--section-illustration)

---

## 1. Migration SQL

```sql
-- database/migrations/049_illustrations_ia.sql

-- Table des illustrations générées par IA
CREATE TABLE IF NOT EXISTS illustrations_ia (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  url_image       TEXT NOT NULL,
  prompt_utilise  TEXT,
  source          TEXT DEFAULT 'dalle'
    CHECK (source IN ('dalle', 'upload', 'unsplash')),
  est_active      BOOLEAN DEFAULT TRUE,
  date_generation TIMESTAMPTZ DEFAULT NOW(),
  heure_affichage INTEGER, -- 0-23 pour planifier l'heure
  meta_donnees    JSONB
);

-- Index
CREATE INDEX IF NOT EXISTS idx_illustrations_active
  ON illustrations_ia(est_active, date_generation DESC);

-- Paramètres pour la génération IA
INSERT INTO parametres_plateforme
  (cle, valeur, type_valeur, description, categorie)
VALUES
  ('illustration_ia_actif', 'false', 'boolean',
   'Activer la génération IA quotidienne', 'ia'),
  ('illustration_nb_par_jour', '4', 'string',
   'Nombre d images générées par jour', 'ia'),
  ('illustration_heure_generation', '6', 'string',
   'Heure de génération (0-23)', 'ia'),
  ('illustration_url_manuelle', '', 'string',
   'URL image manuelle (si IA désactivée)', 'ia'),
  ('openai_api_key', '', 'string',
   'Clé API OpenAI pour DALL-E', 'ia')
ON CONFLICT (cle) DO NOTHING;
```

---

## 2. Backend — Service génération DALL-E

```javascript
// backend/src/services/illustrationIa.service.js

const fetch   = require('node-fetch');
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY);

// ── Prompts pour DALL-E ──────────────────────────────────
const PROMPTS_EMPLOI = [
  'Professional African woman smiling confidently at work desk '
    + 'in modern office, business attire, clean white background, '
    + 'photorealistic, no background artifacts',
  'Young African professional man in suit celebrating job offer '
    + 'with laptop, diverse workplace Guinea West Africa, '
    + 'white background, high quality illustration',
  'African business team meeting collaboration smiling, '
    + 'modern office Guinea, diverse professionals, '
    + 'transparent/white background, professional photography',
  'Confident African woman holding resume document smiling, '
    + 'professional business outfit, clean background, '
    + 'Guinea West Africa employment theme',
  'African man working on laptop modern office setup, '
    + 'professional technology worker, clean white background, '
    + 'high resolution illustration',
  'Happy African professionals shaking hands job interview, '
    + 'modern Guinea office, business suits, white background',
  'African woman graduate celebrating success career milestone, '
    + 'joyful expression, professional setting white background',
  'Diverse African business team standing together smiling, '
    + 'modern office Guinea, professional attire, clean background',
];

// ── Récupérer la config depuis BDD ───────────────────────
const _getConfig = async () => {
  try {
    const { data: rows } = await supabase
      .from('parametres_plateforme')
      .select('cle, valeur')
      .in('cle', [
        'illustration_ia_actif',
        'illustration_nb_par_jour',
        'openai_api_key',
        'openai_model',
      ]);

    const c = {};
    (rows || []).forEach(r => { c[r.cle] = r.valeur; });

    return {
      actif:       c['illustration_ia_actif'] === 'true',
      nbParJour:   parseInt(c['illustration_nb_par_jour'] || '4'),
      openaiKey:   c['openai_api_key']
                    || process.env.OPENAI_API_KEY || '',
    };
  } catch (e) {
    console.error('[illustrationIa] Config erreur:', e.message);
    return { actif: false, nbParJour: 4, openaiKey: '' };
  }
};

// ── Générer une image avec DALL-E ────────────────────────
const genererImageDalle = async (prompt, openaiKey) => {
  try {
    console.log('[DALL-E] Génération image...');
    console.log('[DALL-E] Prompt:', prompt.substring(0, 60) + '...');

    const response = await fetch(
      'https://api.openai.com/v1/images/generations',
      {
        method: 'POST',
        headers: {
          'Content-Type':  'application/json',
          'Authorization': `Bearer ${openaiKey}`,
        },
        body: JSON.stringify({
          model:   'dall-e-3',
          prompt:  prompt,
          n:       1,
          size:    '1024x1024',
          quality: 'standard', // 'hd' pour meilleure qualité
          style:   'natural',  // 'vivid' ou 'natural'
        }),
      });

    const data = await response.json();

    if (data.error) {
      throw new Error(data.error.message);
    }

    const urlImage = data.data?.[0]?.url;
    if (!urlImage) throw new Error('Pas d\'URL retournée');

    console.log('[DALL-E] ✅ Image générée:', urlImage.substring(0, 50) + '...');
    return urlImage;

  } catch (e) {
    console.error('[DALL-E] Erreur:', e.message);
    throw e;
  }
};

// ── Télécharger et sauvegarder dans Supabase Storage ─────
const _sauvegarderImage = async (urlExterne, nomFichier) => {
  try {
    // Télécharger l'image depuis OpenAI
    const response = await fetch(urlExterne);
    if (!response.ok) throw new Error('Download failed');

    const buffer    = await response.buffer();
    const cheminSto = `illustrations/${nomFichier}.png`;

    // Upload dans Supabase Storage bucket "images"
    const { error: uploadError } = await supabase.storage
      .from('images')
      .upload(cheminSto, buffer, {
        contentType:  'image/png',
        upsert:       true,
        cacheControl: '86400',
      });

    if (uploadError) {
      console.warn('[illustrationIa] Upload Supabase:', uploadError.message);
      // Retourner l'URL OpenAI directement comme fallback
      return urlExterne;
    }

    // URL publique Supabase
    const { data: pub } = supabase.storage
      .from('images')
      .getPublicUrl(cheminSto);

    console.log('[illustrationIa] ✅ Image sauvegardée');
    return pub.publicUrl;

  } catch (e) {
    console.warn('[illustrationIa] Sauvegarde erreur:', e.message);
    return urlExterne; // Fallback URL OpenAI
  }
};

// ── Générer les illustrations du jour ────────────────────
const genererIllustrationsJour = async () => {
  try {
    const config = await _getConfig();

    if (!config.actif) {
      console.log('[illustrationIa] IA désactivée dans l\'admin');
      return { success: false, message: 'IA désactivée' };
    }

    if (!config.openaiKey) {
      console.error('[illustrationIa] Clé OpenAI manquante');
      return { success: false, message: 'Clé OpenAI manquante' };
    }

    const nb     = Math.min(config.nbParJour, 10); // Max 10/jour
    const resultats = [];

    console.log(`[illustrationIa] Génération de ${nb} images...`);

    for (let i = 0; i < nb; i++) {
      try {
        // Choisir un prompt aléatoire
        const prompt = PROMPTS_EMPLOI[
          Math.floor(Math.random() * PROMPTS_EMPLOI.length)];

        // Générer l'image
        const urlDalle = await genererImageDalle(
          prompt, config.openaiKey);

        // Sauvegarder dans Supabase Storage
        const nomFichier = `day_${Date.now()}_${i}`;
        const urlFinale  = await _sauvegarderImage(
          urlDalle, nomFichier);

        // Sauvegarder en BDD
        const { data: illus } = await supabase
          .from('illustrations_ia')
          .insert({
            url_image:       urlFinale,
            prompt_utilise:  prompt,
            source:          'dalle',
            est_active:      i === 0, // Seule la 1ère est active
            heure_affichage: Math.floor((24 / nb) * i),
          })
          .select()
          .single();

        resultats.push(illus);
        console.log(`[illustrationIa] Image ${i + 1}/${nb} ✅`);

        // Pause entre les appels (rate limiting)
        if (i < nb - 1) {
          await new Promise(r => setTimeout(r, 2000));
        }

      } catch (e) {
        console.error(`[illustrationIa] Image ${i + 1} erreur:`, e.message);
      }
    }

    // Désactiver les anciennes illustrations
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    await supabase
      .from('illustrations_ia')
      .update({ est_active: false })
      .lt('date_generation', yesterday.toISOString())
      .eq('est_active', true);

    console.log(`[illustrationIa] ✅ ${resultats.length} images générées`);
    return {
      success: true,
      nb_generees: resultats.length,
      illustrations: resultats,
    };

  } catch (e) {
    console.error('[illustrationIa] Erreur globale:', e.message);
    return { success: false, message: e.message };
  }
};

// ── Récupérer l'illustration active du moment ─────────────
const getIllustrationActive = async () => {
  try {
    // 1. Essayer depuis la BDD (IA)
    const { data: illus } = await supabase
      .from('illustrations_ia')
      .select('url_image, prompt_utilise, source')
      .eq('est_active', true)
      .order('date_generation', { ascending: false })
      .limit(1)
      .single();

    if (illus?.url_image) return illus;

    // 2. Fallback : URL manuelle dans les paramètres
    const { data: param } = await supabase
      .from('parametres_plateforme')
      .select('valeur')
      .eq('cle', 'illustration_url_manuelle')
      .single();

    if (param?.valeur) {
      return { url_image: param.valeur, source: 'upload' };
    }

    // 3. Fallback final : image Unsplash
    return {
      url_image: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=800&q=80',
      source: 'unsplash',
    };

  } catch (e) {
    console.warn('[illustrationIa] getActive:', e.message);
    return {
      url_image: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=800&q=80',
      source: 'unsplash',
    };
  }
};

module.exports = {
  genererIllustrationsJour,
  getIllustrationActive,
  genererImageDalle,
};
```

---

## 3. Cron job quotidien

```javascript
// backend/src/crons/illustration.cron.js

const cron = require('node-cron');
const {
  genererIllustrationsJour
} = require('../services/illustrationIa.service');

const demarrerCronIllustration = () => {
  // Lire l'heure depuis les paramètres
  // Par défaut : 6h00 chaque matin
  const expression = '0 6 * * *'; // Chaque jour à 6h

  cron.schedule(expression, async () => {
    console.log('[CRON] Génération illustrations IA...');
    const result = await genererIllustrationsJour();
    console.log('[CRON] Résultat:', result);
  }, {
    timezone: 'Africa/Conakry',
  });

  console.log('[CRON] Illustration IA : chaque jour à 6h (Conakry)');
};

module.exports = { demarrerCronIllustration };
```

```javascript
// Dans backend/src/index.js — ajouter :
const {
  demarrerCronIllustration
} = require('./crons/illustration.cron');

// Après les autres crons :
demarrerCronIllustration();
```

---

## 4. Routes illustration

```javascript
// backend/src/routes/illustration.routes.js

const express = require('express');
const router  = express.Router();
const {
  genererIllustrationsJour,
  getIllustrationActive,
} = require('../services/illustrationIa.service');
const { auth, requireAdmin } = require('../middleware/auth');

// GET /api/illustration/active — Pour Flutter homepage
router.get('/active', async (req, res) => {
  try {
    const illus = await getIllustrationActive();
    return res.json({ success: true, data: illus });
  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});

// POST /api/illustration/generer — Déclencher manuellement
router.post('/generer', auth, requireAdmin, async (req, res) => {
  try {
    console.log('[illustration] Génération manuelle...');
    const result = await genererIllustrationsJour();
    return res.json(result);
  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});

// GET /api/illustration/liste — Toutes les illustrations
router.get('/liste', auth, requireAdmin, async (req, res) => {
  try {
    const { data } = await supabase
      .from('illustrations_ia')
      .select('*')
      .order('date_generation', { ascending: false })
      .limit(30);
    return res.json({ success: true, data: data || [] });
  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});

// PATCH /api/illustration/:id/activer
router.patch('/:id/activer', auth, requireAdmin,
  async (req, res) => {
  try {
    // Désactiver toutes les autres
    await supabase
      .from('illustrations_ia')
      .update({ est_active: false })
      .neq('id', req.params.id);

    // Activer celle-ci
    const { data } = await supabase
      .from('illustrations_ia')
      .update({ est_active: true })
      .eq('id', req.params.id)
      .select()
      .single();

    return res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});

// Monter dans index.js :
// router.use('/illustration', illustrationRoutes);

module.exports = router;
```

---

## 5. Admin — Gestion illustrations

```dart
// frontend/lib/screens/admin/pages/illustrations_ia_page.dart

class IllustrationsIaAdminPage extends StatefulWidget {
  const IllustrationsIaAdminPage({super.key});
  @override
  State<IllustrationsIaAdminPage> createState() =>
    _IllustrationsAdminState();
}

class _IllustrationsAdminState
    extends State<IllustrationsIaAdminPage> {

  List<Map<String, dynamic>> _illustrations = [];
  bool   _isLoading       = false;
  bool   _isGenerating    = false;
  bool   _iaActif         = false;
  String _nbParJour       = '4';
  String _urlManuelle     = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [

      // ── Header ──────────────────────────────────
      Text('🖼️ Illustrations IA',
        style: GoogleFonts.poppins(
          fontSize: 20, fontWeight: FontWeight.w800)),
      Text('Images générées automatiquement par DALL-E',
        style: GoogleFonts.inter(
          fontSize: 13, color: const Color(0xFF64748B))),
      const SizedBox(height: 24),

      // ── Config IA ───────────────────────────────
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

          Text('Configuration',
            style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),

          // Toggle IA actif
          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text('Génération IA automatique',
                style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600)),
              Text(
                'DALL-E génère des images chaque jour à 6h',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8))),
            ])),
            Switch(
              value: _iaActif,
              activeColor: const Color(0xFF1A56DB),
              onChanged: (v) {
                setState(() => _iaActif = v);
                _saveParam('illustration_ia_actif',
                  v.toString());
              }),
          ]),
          const Divider(height: 20),

          // Nb images par jour
          Row(children: [
            Expanded(child: Text(
              'Images par jour',
              style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600))),
            DropdownButton<String>(
              value: _nbParJour,
              underline: const SizedBox(),
              items: ['2', '4', '6', '8', '10']
                .map((v) => DropdownMenuItem(
                  value: v, child: Text('$v images')))
                .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _nbParJour = v);
                  _saveParam('illustration_nb_par_jour', v);
                }
              }),
          ]),
          const Divider(height: 20),

          // URL manuelle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text('Image manuelle (si IA désactivée)',
              style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextFormField(
                initialValue: _urlManuelle,
                decoration: InputDecoration(
                  hintText: 'URL de l\'image PNG sans fond...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFFCBD5E1)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE2E8F0)))),
                onChanged: (v) => _urlManuelle = v)),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56DB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
                onPressed: () => _saveParam(
                  'illustration_url_manuelle', _urlManuelle),
                child: const Text('Sauvegarder')),
            ]),
          ]),
        ])),
      const SizedBox(height: 20),

      // ── Bouton générer maintenant ────────────────
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: _isGenerating
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
              : const Icon(
                  Icons.auto_awesome_rounded, size: 18),
          label: Text(
            _isGenerating
                ? 'Génération en cours...'
                : '✨ Générer maintenant',
            style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12))),
          onPressed: _isGenerating ? null : _genererMaintenant)),
      const SizedBox(height: 8),
      Text(
        '⚠️ Chaque image coûte ~0.04\$ (OpenAI DALL-E 3)',
        style: GoogleFonts.inter(
          fontSize: 11, color: const Color(0xFF94A3B8)),
        textAlign: TextAlign.center),
      const SizedBox(height: 24),

      // ── Liste illustrations ──────────────────────
      Text('Illustrations disponibles',
        style: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),

      if (_isLoading)
        const Center(child: CircularProgressIndicator(
          color: Color(0xFF1A56DB)))
      else if (_illustrations.isEmpty)
        Container(
          padding: const EdgeInsets.all(40),
          alignment: Alignment.center,
          child: Column(children: [
            const Icon(Icons.image_outlined,
              color: Color(0xFFE2E8F0), size: 48),
            const SizedBox(height: 12),
            Text('Aucune illustration générée',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF94A3B8))),
            const SizedBox(height: 8),
            Text(
              'Activez la génération IA ou cliquez '
              '"Générer maintenant"',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFFCBD5E1))),
          ]))
      else
        Wrap(
          spacing: 12, runSpacing: 12,
          children: _illustrations.map((illus) {
            final isActive = illus['est_active'] as bool? ?? false;
            return Container(
              width: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF10B981)
                      : const Color(0xFFE2E8F0),
                  width: isActive ? 2 : 1)),
              child: Column(children: [
                // Image preview
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11)),
                  child: Image.network(
                    illus['url_image'] as String,
                    height: 140, width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                      Container(
                        height: 140,
                        color: const Color(0xFFF8FAFC),
                        child: const Icon(Icons.broken_image,
                          color: Color(0xFFCBD5E1))))),
                // Infos + actions
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(children: [
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius:
                            BorderRadius.circular(100)),
                        child: Text('✅ Active',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white))),
                    const SizedBox(height: 6),
                    Text(
                      illus['source'] as String? ?? 'dalle',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF94A3B8))),
                    const SizedBox(height: 8),
                    if (!isActive)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF1A56DB)),
                            foregroundColor:
                              const Color(0xFF1A56DB),
                            padding:
                              const EdgeInsets.symmetric(
                                vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                BorderRadius.circular(6))),
                          onPressed: () => _activerIllustration(
                            illus['id'] as String),
                          child: Text('Activer',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight:
                                FontWeight.w700)))),
                  ])),
              ]));
          }).toList()),
    ]));

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res   = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/illustration/liste'),
        headers: {'Authorization': 'Bearer $token'});
      final body = jsonDecode(res.body);
      setState(() => _illustrations =
        List<Map<String, dynamic>>.from(
          body['data'] ?? []));
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _genererMaintenant() async {
    setState(() => _isGenerating = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res   = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/illustration/generer'),
        headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(minutes: 3));
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            '✅ ${body['nb_generees']} images générées !'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating));
        _loadData();
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
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _activerIllustration(String id) async {
    final token = context.read<AuthProvider>().token ?? '';
    await http.patch(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/illustration/$id/activer'),
      headers: {'Authorization': 'Bearer $token'});
    _loadData();
  }

  Future<void> _saveParam(String cle, String valeur) async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/parametres'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'cle': cle, 'valeur': valeur}));
    } catch (_) {}
  }
}
```

---

## 6. Flutter — Section illustration améliorée

```dart
// frontend/lib/screens/home/widgets/illustration_section.dart
// REMPLACER entièrement

class IllustrationSection extends StatefulWidget {
  const IllustrationSection({super.key});
  @override
  State<IllustrationSection> createState() =>
    _IllustrationState();
}

class _IllustrationState extends State<IllustrationSection>
    with SingleTickerProviderStateMixin {

  late AnimationController _floatCtrl;
  late Animation<double>   _floatAnim;
  String? _imageUrl;
  bool    _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(vsync: this,
      duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -12, end: 12)
      .animate(CurvedAnimation(
        parent: _floatCtrl, curve: Curves.easeInOut));

    _loadIllustration();
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadIllustration() async {
    try {
      final res = await http.get(Uri.parse(
        '${ApiConfig.baseUrl}/api/illustration/active'));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final url  = body['data']?['url_image'] as String?;
        if (url != null && mounted) {
          setState(() => _imageUrl = url);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 60,
        vertical:   isMobile ? 40 : 60),
      color: const Color(0xFFF0F7FF),
      child: isMobile
          ? _buildMobile()
          : _buildDesktop());
  }

  Widget _buildDesktop() => Row(
    crossAxisAlignment: CrossAxisAlignment.center, children: [

    // ── Texte gauche ─────────────────────────────
    Expanded(child: _buildTexte()),
    const SizedBox(width: 60),

    // ── Illustration droite flottante ─────────────
    SizedBox(
      width: 360,
      height: 400,
      child: _buildIllustration()),
  ]);

  Widget _buildMobile() => Column(children: [
    _buildIllustration(),
    const SizedBox(height: 32),
    _buildTexte(),
  ]);

  Widget _buildTexte() => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1A56DB).withOpacity(0.1),
        borderRadius: BorderRadius.circular(100)),
      child: Text('✨ Ils ont réussi grâce à nous',
        style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: const Color(0xFF1A56DB)))),
    const SizedBox(height: 16),
    Text(
      'Des milliers de Guinéens\nont changé leur vie',
      style: GoogleFonts.poppins(
        fontSize: 32, fontWeight: FontWeight.w800,
        color: const Color(0xFF0F172A), height: 1.2)),
    const SizedBox(height: 16),
    Text(
      'Chaque jour, des candidats trouvent leur '
      'emploi idéal et des entreprises recrutent '
      'les meilleurs talents grâce à EmploiConnect.',
      style: GoogleFonts.inter(
        fontSize: 14, color: const Color(0xFF64748B),
        height: 1.7)),
    const SizedBox(height: 24),
    ...[
      ('🎯', 'Matching IA précis', 'Compatible avec votre profil'),
      ('⚡', 'Réponse rapide',     'Moins de 24h en moyenne'),
      ('🔒', 'Sécurisé',          'Vos données sont protégées'),
    ].map((item) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1A56DB).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(item.$1,
            style: const TextStyle(fontSize: 18)))),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(item.$2, style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A))),
          Text(item.$3, style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF94A3B8))),
        ]),
      ]))),
    const SizedBox(height: 24),
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A56DB),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12))),
      onPressed: () => context.push('/register'),
      child: Text('Rejoindre gratuitement',
        style: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w700))),
  ]);

  Widget _buildIllustration() => AnimatedBuilder(
    animation: _floatAnim,
    builder: (_, __) => Transform.translate(
      offset: Offset(0, _floatAnim.value),
      child: Stack(children: [

        // ── Image principale sans fond ───────────
        Container(
          width: 360, height: 400,
          child: _imageUrl != null
              ? Image.network(
                  _imageUrl!,
                  fit: BoxFit.contain, // ← contain préserve transparence
                  filterQuality: FilterQuality.high,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return _buildPlaceholder();
                  },
                  errorBuilder: (_, __, ___) =>
                    _buildEmojiDefaut())
              : _buildPlaceholder()),

        // ── Badge flottant haut droit ───────────
        Positioned(top: 24, right: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.scale(
              scale: v, child: child),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8))]),
              child: Row(mainAxisSize: MainAxisSize.min,
                children: [
                const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF10B981), size: 16),
                const SizedBox(width: 6),
                Text('Offre acceptée !',
                  style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A))),
              ])))),

        // ── Badge flottant bas gauche ────────────
        Positioned(bottom: 30, left: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.scale(
              scale: v, child: child),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8))]),
              child: Row(mainAxisSize: MainAxisSize.min,
                children: [
                const Text('🚀',
                  style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text('Score IA : 94%',
                  style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A56DB))),
              ])))),
      ])));

  Widget _buildPlaceholder() => Container(
    width: 360, height: 400,
    decoration: BoxDecoration(
      color: const Color(0xFF1A56DB).withOpacity(0.06),
      borderRadius: BorderRadius.circular(20)),
    child: Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(
        width: 32, height: 32,
        child: CircularProgressIndicator(
          color: Color(0xFF1A56DB), strokeWidth: 2)),
      const SizedBox(height: 12),
      Text('Chargement illustration...',
        style: GoogleFonts.inter(
          fontSize: 11, color: const Color(0xFF94A3B8))),
    ])));

  Widget _buildEmojiDefaut() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('👩‍💼', style: TextStyle(fontSize: 100)),
      const SizedBox(height: 8),
      const Text('🎉', style: TextStyle(fontSize: 50)),
    ]));
}
```

---

## Ajouter la route dans index.js

```javascript
// backend/src/routes/index.js
const illustrationRoutes = require('./illustration.routes');
router.use('/illustration', illustrationRoutes);

// Log :
// - Illustration: GET /api/illustration/active,
//   POST /api/illustration/generer
```

---

## Ajouter dans le menu admin

```dart
// Dans admin_shell ou admin_menu
// Ajouter une entrée :

_MenuItem(
  icone: Icons.image_outlined,
  titre: 'Illustrations IA',
  route: '/admin/illustrations',
  onTap: () => context.push('/admin/illustrations')),
```

---

## Critères d'Acceptation

- [ ] Route SQL migrée (049)
- [ ] Service DALL-E fonctionne avec clé OpenAI
- [ ] Cron job 6h00 tous les matins
- [ ] GET /api/illustration/active retourne l'image
- [ ] Section Flutter charge l'image sans fond
- [ ] Badges "Offre acceptée" et "Score IA" flottants
- [ ] Admin peut générer manuellement
- [ ] Admin peut activer/désactiver une illustration
- [ ] Admin peut mettre une URL manuelle
- [ ] Fallback Unsplash si pas d'image disponible

---

## Coût estimé DALL-E

```
DALL-E 3 Standard :
→ 0.040$ par image 1024×1024
→ 4 images/jour = 0.16$/jour = 4.80$/mois
→ Très abordable !

Pour économiser :
→ Utiliser DALL-E 2 (0.020$/image)
→ Générer 2 images au lieu de 4
→ Réutiliser les images pendant plusieurs jours
```

---

*PRD EmploiConnect v9.2 — Illustrations IA DALL-E*
*Cursor / Kirsoft AI — Phase 25*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
