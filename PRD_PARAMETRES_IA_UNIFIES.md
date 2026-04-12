# PRD — EmploiConnect · Paramètres IA Unifiés + Multi-Provider
## Product Requirements Document v9.3
**Stack : Flutter + Node.js/Express + Supabase**
**Outil : Cursor / Kirsoft AI**
**Date : Avril 2026**

---

## Explication complète de la vision

```
SITUATION ACTUELLE :
→ Anthropic Claude : configuré ✅ (matching, amélioration texte)
→ OpenAI ChatGPT   : peut être configuré
→ DALL-E (images)  : même clé OpenAI
→ Illustrations IA : menu séparé dans la sidebar admin

OBJECTIF :
→ Tout regrouper dans Admin → Paramètres → IA
→ Pouvoir activer Claude ET OpenAI EN MÊME TEMPS
→ Le système utilise les 2 automatiquement selon la dispo
→ Illustrations IA gérées dans les Paramètres
→ Upload image manuelle avec bouton fichier
→ Tests automatiques des clés API

LOGIQUE MULTI-PROVIDER :
→ Si Claude ET OpenAI activés → utiliser Claude en priorité
→ Si Claude échoue → basculer sur OpenAI automatiquement
→ Si OpenAI activé → DALL-E disponible pour les images
→ L'admin voit le statut de chaque API en temps réel
```

---

## Table des Matières

1. [Déplacer Illustrations dans Paramètres IA](#1-déplacer-illustrations-dans-paramètres-ia)
2. [Upload image manuelle avec fichier picker](#2-upload-image-manuelle)
3. [Tests automatiques des clés API](#3-tests-automatiques-clés-api)
4. [Logique multi-provider intelligente](#4-logique-multi-provider)
5. [Backend — Service IA unifié](#5-backend--service-ia-unifié)
6. [Admin Flutter — Section IA complète](#6-admin-flutter--section-ia-complète)

---

## 1. Déplacer Illustrations dans Paramètres IA

### Dans admin_sidebar.dart

```dart
// Supprimer l'entrée "Illustrations IA" du menu sidebar
// AVANT ❌ — entrée séparée dans le menu
_SidebarItem(
  icone: Icons.image_outlined,
  titre: 'Illustrations IA',
  route: '/admin/illustrations-ia',
  ...),

// APRÈS ✅ — Supprimé du menu
// La gestion des illustrations se fait dans
// Admin → Paramètres → onglet IA
```

### Dans admin_shell_screen.dart

```dart
// Garder la route mais accessible uniquement depuis
// les Paramètres (pas du menu principal)
// OU fusionner directement dans admin_settings_screen.dart
```

### Dans admin_settings_screen.dart

```dart
// Dans l'onglet IA des paramètres
// Ajouter une section "Illustration de la homepage"
// APRÈS les sections Claude et OpenAI

_SectionParametres(
  titre: '🖼️ Illustration de la homepage',
  children: [
    _IllustrationManagerWidget(),
  ]),
```

---

## 2. Upload image manuelle

```dart
// Widget de gestion de l'illustration
// À intégrer dans admin_settings_screen.dart

class _IllustrationManagerWidget extends StatefulWidget {
  @override
  State<_IllustrationManagerWidget> createState() =>
    _IllustrationManagerState();
}

class _IllustrationManagerState
    extends State<_IllustrationManagerWidget> {

  bool   _iaActif          = false;
  String _nbParJour        = '4';
  String _urlManuelle      = '';
  bool   _isUploading      = false;
  bool   _isGenerating     = false;
  String? _previewUrl;
  List<Map<String, dynamic>> _illustrations = [];

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadIllustrations();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [

    // ── Toggle IA automatique ───────────────────
    _ToggleNotif(
      icon:      Icons.auto_awesome_rounded,
      couleur:   const Color(0xFF8B5CF6),
      titre:     'Génération IA automatique (DALL-E)',
      sousTitre: 'OpenAI génère une image chaque jour à 6h',
      valeur:    _iaActif,
      onChanged: (v) {
        setState(() => _iaActif = v);
        _saveParam('illustration_ia_actif', v.toString());
      }),
    const SizedBox(height: 8),

    // Info coût
    Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded,
          color: Color(0xFF92400E), size: 14),
        const SizedBox(width: 8),
        Expanded(child: Text(
          '💰 Coût : ~0.04\$ par image (DALL-E 3). '
          '4 images/jour = ~4.80\$/mois. '
          'Nécessite la clé OpenAI configurée ci-dessus.',
          style: GoogleFonts.inter(
            fontSize: 11, color: const Color(0xFF92400E),
            height: 1.4))),
      ])),
    const SizedBox(height: 12),

    // Nb images par jour
    if (_iaActif) ...[
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
        Text('Images générées par jour',
          style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: const Color(0xFF374151))),
        DropdownButton<String>(
          value: _nbParJour,
          underline: const SizedBox(),
          style: GoogleFonts.inter(
            fontSize: 13, color: const Color(0xFF0F172A)),
          items: ['2', '4', '6', '8', '10']
            .map((v) => DropdownMenuItem(
              value: v,
              child: Text('$v images/jour')))
            .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() => _nbParJour = v);
              _saveParam('illustration_nb_par_jour', v);
            }
          }),
      ]),
      const SizedBox(height: 12),

      // Bouton générer maintenant
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: _isGenerating
              ? const SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.auto_awesome_rounded,
                  size: 16),
          label: Text(
            _isGenerating
                ? 'Génération en cours...'
                : '✨ Générer maintenant',
            style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10))),
          onPressed: _isGenerating ? null : _generer)),
      const SizedBox(height: 16),
    ],

    // ── Image manuelle ──────────────────────────
    const Divider(color: Color(0xFFE2E8F0)),
    const SizedBox(height: 12),
    Text('Ou uploader une image manuellement',
      style: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: const Color(0xFF374151))),
    const SizedBox(height: 4),
    Text(
      'Image PNG sans fond recommandée. '
      'Elle remplacera l\'illustration IA si l\'IA est désactivée.',
      style: GoogleFonts.inter(
        fontSize: 11, color: const Color(0xFF94A3B8))),
    const SizedBox(height: 10),

    // Aperçu + bouton upload
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Aperçu image
      Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0))),
        child: _previewUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.network(
                  _previewUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image,
                      color: Color(0xFFCBD5E1))))
            : _urlManuelle.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.network(
                      _urlManuelle,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_outlined,
                          color: Color(0xFFCBD5E1), size: 32)))
                : const Icon(Icons.image_outlined,
                    color: Color(0xFFCBD5E1), size: 32)),
      const SizedBox(width: 12),

      // Boutons
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Bouton choisir fichier
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: _isUploading
                ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1A56DB)))
                : const Icon(
                    Icons.upload_file_rounded, size: 16),
            label: Text(
              _isUploading
                  ? 'Upload en cours...'
                  : '📁 Choisir une image',
              style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: Color(0xFF1A56DB)),
              foregroundColor: const Color(0xFF1A56DB),
              padding: const EdgeInsets.symmetric(
                vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8))),
            onPressed: _isUploading ? null : _choisirImage)),
        const SizedBox(height: 6),
        Text(
          'PNG, JPG ou WebP\n'
          'Recommandé : PNG sans fond (transparence)',
          style: GoogleFonts.inter(
            fontSize: 10, color: const Color(0xFF94A3B8),
            height: 1.4)),
        if (_urlManuelle.isNotEmpty) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              await _saveParam('illustration_url_manuelle', '');
              setState(() {
                _urlManuelle = '';
                _previewUrl  = null;
              });
            },
            child: Text('❌ Supprimer l\'image manuelle',
              style: GoogleFonts.inter(
                fontSize: 11, color: const Color(0xFFEF4444),
                fontWeight: FontWeight.w600))),
        ],
      ])),
    ]),
    const SizedBox(height: 16),

    // ── Grille illustrations générées ───────────
    if (_illustrations.isNotEmpty) ...[
      const Divider(color: Color(0xFFE2E8F0)),
      const SizedBox(height: 12),
      Text('Images générées par IA',
        style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: const Color(0xFF374151))),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10, runSpacing: 10,
        children: _illustrations.take(6).map((illus) {
          final isActive =
            illus['est_active'] as bool? ?? false;
          return GestureDetector(
            onTap: () => _activerIllustration(
              illus['id'] as String),
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF10B981)
                      : const Color(0xFFE2E8F0),
                  width: isActive ? 2.5 : 1)),
              child: Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.network(
                    illus['url_image'] as String,
                    width: 100, height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image,
                        color: Color(0xFFCBD5E1)))),
                if (isActive)
                  Positioned(
                    top: 4, right: 4,
                    child: Container(
                      width: 20, height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle),
                      child: const Icon(Icons.check,
                        color: Colors.white, size: 12))),
              ])));
        }).toList()),
      const SizedBox(height: 4),
      Text('Cliquez sur une image pour l\'activer',
        style: GoogleFonts.inter(
          fontSize: 10, color: const Color(0xFF94A3B8))),
    ],
  ]);

  Future<void> _choisirImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
        withData: true);

      if (result?.files.isNotEmpty != true) return;
      final file = result!.files.first;
      if (file.bytes == null) return;

      setState(() => _isUploading = true);

      // Upload vers Supabase Storage
      final token = context.read<AuthProvider>().token ?? '';
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '${ApiConfig.baseUrl}/api/illustration/upload-manuel'));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes(
        'image', file.bytes!,
        filename: file.name));

      final streamed = await request.send();
      final res      = await http.Response.fromStream(streamed);
      final body     = jsonDecode(res.body);

      if (body['success'] == true) {
        final url = body['data']['url'] as String;
        await _saveParam('illustration_url_manuelle', url);
        setState(() {
          _urlManuelle = url;
          _previewUrl  = url;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Image uploadée !'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur upload: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _generer() async {
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
            '✅ ${body['nb_generees']} image(s) générée(s) !'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating));
        _loadIllustrations();
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
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _activerIllustration(String id) async {
    final token = context.read<AuthProvider>().token ?? '';
    await http.patch(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/illustration/$id/activer'),
      headers: {'Authorization': 'Bearer $token'});
    _loadIllustrations();
  }

  Future<void> _loadConfig() async {
    // Charger depuis _params du parent
    // ou directement depuis l'API
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res   = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/parametres'),
        headers: {'Authorization': 'Bearer $token'});
      final body  = jsonDecode(res.body);
      final params = <String, String>{};
      for (final p in (body['data'] ?? [])) {
        params[p['cle'] as String] = p['valeur'] as String? ?? '';
      }
      setState(() {
        _iaActif    = params['illustration_ia_actif'] == 'true';
        _nbParJour  = params['illustration_nb_par_jour'] ?? '4';
        _urlManuelle = params['illustration_url_manuelle'] ?? '';
        if (_urlManuelle.isNotEmpty) _previewUrl = _urlManuelle;
      });
    } catch (_) {}
  }

  Future<void> _loadIllustrations() async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res   = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/illustration/liste'),
        headers: {'Authorization': 'Bearer $token'});
      final body  = jsonDecode(res.body);
      setState(() => _illustrations =
        List<Map<String, dynamic>>.from(
          body['data'] ?? []));
    } catch (_) {}
  }

  Future<void> _saveParam(String cle, String valeur) async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/admin/parametres'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'cle': cle, 'valeur': valeur}));
    } catch (_) {}
  }
}
```

### Route upload manuel backend

```javascript
// Dans backend/src/routes/illustration.routes.js
// Ajouter :

const multer = require('multer');
const upload = multer({ storage: multer.memoryStorage() });

// POST /api/illustration/upload-manuel
router.post('/upload-manuel',
  auth, requireAdmin,
  upload.single('image'),
  async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Fichier manquant'
      });
    }

    const nomFichier = `manuel_${Date.now()}.png`;
    const chemin     = `illustrations_ia/${nomFichier}`;

    const { error } = await supabase.storage
      .from('bannieres')
      .upload(chemin, req.file.buffer, {
        contentType:  req.file.mimetype || 'image/png',
        upsert:       true,
        cacheControl: '86400',
      });

    if (error) throw error;

    const { data: pub } = supabase.storage
      .from('bannieres')
      .getPublicUrl(chemin);

    // Sauvegarder en BDD
    await supabase.from('illustrations_ia').insert({
      url_image:       pub.publicUrl,
      source:          'upload',
      est_active:      true,
      prompt_utilise:  'Upload manuel',
    });

    // Désactiver les autres
    await supabase
      .from('illustrations_ia')
      .update({ est_active: false })
      .neq('url_image', pub.publicUrl);

    return res.json({
      success: true,
      data: { url: pub.publicUrl }
    });
  } catch (err) {
    res.status(500).json({
      success: false, message: err.message });
  }
});
```

---

## 3. Tests automatiques des clés API

```dart
// Dans admin_settings_screen.dart
// Pour chaque clé API → bouton "Tester"

// ── Test Anthropic Claude ───────────────────────────────
Future<void> _testerClaude() async {
  setState(() => _testClaudeEnCours = true);
  try {
    final token = context.read<AuthProvider>().token ?? '';
    final res   = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/test-ia'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'provider': 'anthropic'}))
      .timeout(const Duration(seconds: 15));

    final body = jsonDecode(res.body);
    setState(() {
      _testClaudeResultat = body['success'] == true
          ? '✅ Claude opérationnel !'
          : '❌ ${body['message']}';
      _testClaudeOk = body['success'] == true;
    });
  } catch (e) {
    setState(() {
      _testClaudeResultat = '❌ Erreur: $e';
      _testClaudeOk = false;
    });
  } finally {
    setState(() => _testClaudeEnCours = false);
  }
}

// ── Test OpenAI ─────────────────────────────────────────
Future<void> _testerOpenAI() async {
  setState(() => _testOpenAIEnCours = true);
  try {
    final token = context.read<AuthProvider>().token ?? '';
    final res   = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/test-ia'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'provider': 'openai'}))
      .timeout(const Duration(seconds: 15));

    final body = jsonDecode(res.body);
    setState(() {
      _testOpenAIResultat = body['success'] == true
          ? '✅ OpenAI opérationnel ! DALL-E disponible.'
          : '❌ ${body['message']}';
      _testOpenAIOk = body['success'] == true;
    });
  } catch (e) {
    setState(() {
      _testOpenAIResultat = '❌ Erreur: $e';
      _testOpenAIOk = false;
    });
  } finally {
    setState(() => _testOpenAIEnCours = false);
  }
}

// Afficher le résultat du test sous chaque clé :
if (_testClaudeResultat != null)
  Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: _testClaudeOk
          ? const Color(0xFFECFDF5)
          : const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(8)),
    child: Text(_testClaudeResultat!,
      style: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: _testClaudeOk
            ? const Color(0xFF065F46)
            : const Color(0xFF991B1B)))),
```

### Route backend test IA

```javascript
// backend/src/routes/admin/index.js
// Ajouter :

router.post('/test-ia', auth, requireAdmin,
  async (req, res) => {
  try {
    const { provider } = req.body;
    const { _getClesIA, _appellerIA } =
      require('../../services/ia.service');

    const cles = await _getClesIA();

    const prompt = 'Réponds uniquement "OK" en un mot.';

    // Forcer le provider demandé
    const clesTest = {
      ...cles,
      providerTexte:    provider,
      providerMatching: provider,
    };

    const resultat = await _appellerIA(
      prompt, clesTest, 'texte');

    if (!resultat) {
      return res.json({
        success: false,
        message: `Provider ${provider} non disponible `
          + `ou clé manquante`
      });
    }

    return res.json({
      success:  true,
      provider: provider,
      reponse:  resultat.substring(0, 50),
      message:  `${provider} fonctionne correctement`,
    });

  } catch (err) {
    return res.json({
      success:  false,
      provider: req.body.provider,
      message:  err.message,
    });
  }
});

// Route test DALL-E séparée
router.post('/test-dalle', auth, requireAdmin,
  async (req, res) => {
  try {
    const { _getClesIA } =
      require('../../services/ia.service');
    const {
      genererImageDalle
    } = require('../../services/illustrationIa.service');

    const cles     = await _getClesIA();
    const openaiKey = cles.openaiKey;

    if (!openaiKey) {
      return res.json({
        success: false,
        message: 'Clé OpenAI non configurée'
      });
    }

    // Test avec une petite image (256x256)
    const response = await fetch(
      'https://api.openai.com/v1/images/generations',
      {
        method: 'POST',
        headers: {
          'Content-Type':  'application/json',
          'Authorization': `Bearer ${openaiKey}`,
        },
        body: JSON.stringify({
          model:   'dall-e-2', // Moins cher pour le test
          prompt:  'Professional business person smiling',
          n:       1,
          size:    '256x256',
        }),
      });

    const data = await response.json();

    if (data.error) throw new Error(data.error.message);

    return res.json({
      success:  true,
      message:  'DALL-E opérationnel ! Génération d\'images disponible.',
      test_url: data.data?.[0]?.url,
    });

  } catch (err) {
    return res.json({
      success: false,
      message: err.message,
    });
  }
});
```

---

## 4. Logique multi-provider intelligente

### Principe de fonctionnement

```
PRIORITÉ :
1. Si Claude activé ET OpenAI activé
   → Claude en priorité (meilleure qualité texte)
   → Si Claude échoue → bascule sur OpenAI
   → Pour les IMAGES → OpenAI/DALL-E (Claude ne génère pas d'images)

2. Si seulement Claude activé
   → Tout passe par Claude
   → Images : fallback Unsplash (pas de DALL-E)

3. Si seulement OpenAI activé
   → Tout passe par OpenAI
   → Images : DALL-E disponible

4. Si aucun activé
   → Fallback local (mots-clés, scores approximatifs)
```

### ia.service.js — Logique fallback automatique

```javascript
// Dans backend/src/services/ia.service.js
// Remplacer _appellerIA par version avec fallback

const _appellerIA = async (prompt, cles, role = 'matching') => {
  const provider = role === 'texte'
    ? cles.providerTexte
    : cles.providerMatching;

  console.log(`[IA] Provider principal: ${provider} | Rôle: ${role}`);

  // ── Essai 1 : Provider configuré ──────────────────────
  try {
    const resultat = await _appellerProviderSpecifique(
      prompt, cles, provider, role);
    if (resultat) return resultat;
  } catch (e) {
    console.warn(`[IA] ${provider} échoué:`, e.message);
  }

  // ── Essai 2 : Fallback sur l'autre provider ────────────
  const fallbackProvider = provider === 'anthropic'
    ? 'openai' : 'anthropic';

  const fallbackKey = fallbackProvider === 'anthropic'
    ? cles.anthropicKey : cles.openaiKey;

  if (fallbackKey) {
    console.log(`[IA] Fallback sur: ${fallbackProvider}`);
    try {
      const resultat = await _appellerProviderSpecifique(
        prompt, cles, fallbackProvider, role);
      if (resultat) {
        console.log(`[IA] ✅ Fallback ${fallbackProvider} réussi`);
        return resultat;
      }
    } catch (e) {
      console.warn(`[IA] Fallback ${fallbackProvider} échoué:`, e.message);
    }
  }

  console.warn('[IA] Aucun provider disponible');
  return null;
};

// Fonction appelant un provider spécifique
const _appellerProviderSpecifique = async (
    prompt, cles, provider, role) => {

  // ── Anthropic Claude ─────────────────────────────────
  if (provider === 'anthropic' && cles.anthropicKey) {
    const response = await fetch(
      'https://api.anthropic.com/v1/messages',
      {
        method: 'POST',
        headers: {
          'Content-Type':      'application/json',
          'x-api-key':         cles.anthropicKey,
          'anthropic-version': '2023-06-01',
        },
        body: JSON.stringify({
          model:      cles.anthropicModel
                        || 'claude-haiku-4-5-20251001',
          max_tokens: role === 'texte' ? 300 : 4096,
          messages: [{ role: 'user', content: prompt }],
        }),
      });
    const data = await response.json();
    if (data.error) throw new Error(data.error.message);
    const texte = data.content?.[0]?.text?.trim() || '';
    console.log(`[IA] Claude ✅ (${texte.length} chars)`);
    return texte;
  }

  // ── OpenAI ChatGPT ────────────────────────────────────
  if (provider === 'openai' && cles.openaiKey) {
    const response = await fetch(
      'https://api.openai.com/v1/chat/completions',
      {
        method: 'POST',
        headers: {
          'Content-Type':  'application/json',
          'Authorization': `Bearer ${cles.openaiKey}`,
        },
        body: JSON.stringify({
          model:      'gpt-3.5-turbo',
          max_tokens: role === 'texte' ? 300 : 4096,
          messages: [{ role: 'user', content: prompt }],
        }),
      });
    const data = await response.json();
    if (data.error) throw new Error(data.error.message);
    const texte =
      data.choices?.[0]?.message?.content?.trim() || '';
    console.log(`[IA] OpenAI ✅ (${texte.length} chars)`);
    return texte;
  }

  return null;
};
```

---

## 5. Admin Flutter — Section IA complète

```dart
// Dans admin_settings_screen.dart
// Onglet IA — structure complète réorganisée

Widget _buildOngletIA() => SingleChildScrollView(
  padding: const EdgeInsets.all(20),
  child: Column(children: [

    // ══ SECTION 1 : STATUS EN TEMPS RÉEL ══════════════
    _CarteSection(
      titre: '📊 Statut des APIs IA',
      children: [
        Row(children: [
          Expanded(child: _StatusBadge(
            provider: 'Claude',
            actif:    _params['ia_matching_actif'] == 'true'
                      && (_params['anthropic_api_key'] ?? '').isNotEmpty,
            cleConfigure: (_params['anthropic_api_key'] ?? '').isNotEmpty)),
          const SizedBox(width: 12),
          Expanded(child: _StatusBadge(
            provider: 'OpenAI',
            actif:    (_params['openai_api_key'] ?? '').isNotEmpty,
            cleConfigure: (_params['openai_api_key'] ?? '').isNotEmpty)),
        ]),
        const SizedBox(height: 12),
        // Info multi-provider
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded,
              color: Color(0xFF1A56DB), size: 14),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Si les 2 providers sont activés, Claude est utilisé '
              'en priorité. En cas d\'échec, le système bascule '
              'automatiquement sur OpenAI.',
              style: GoogleFonts.inter(
                fontSize: 11, color: const Color(0xFF1E40AF),
                height: 1.4))),
          ])),
      ]),
    const SizedBox(height: 16),

    // ══ SECTION 2 : ANTHROPIC CLAUDE ══════════════════
    _CarteSection(
      titre: '🤖 Anthropic Claude',
      sousTitre: 'Recommandé · Texte, matching, simulateur',
      children: [
        // Clé API
        _buildChampCleGoogle(
          cle:   'anthropic_api_key',
          label: 'Clé API Anthropic',
          hint:  'sk-ant-api03-...'),
        const SizedBox(height: 10),
        // Modèle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
          Text('Modèle',
            style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: const Color(0xFF374151))),
          DropdownButton<String>(
            value: _params['anthropic_model']
                ?? 'claude-haiku-4-5-20251001',
            underline: const SizedBox(),
            items: [
              'claude-haiku-4-5-20251001',
              'claude-sonnet-4-6',
            ].map((m) => DropdownMenuItem(
              value: m,
              child: Text(m.split('-').take(2).join(' '),
                style: GoogleFonts.inter(fontSize: 12))))
              .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() =>
                  _params['anthropic_model'] = v);
                _saveParam('anthropic_model', v);
              }
            }),
        ]),
        const SizedBox(height: 10),
        // Bouton tester
        _BoutonTester(
          label:      'Tester Claude',
          couleur:    const Color(0xFF7C3AED),
          onTap:      _testerClaude,
          enCours:    _testClaudeEnCours,
          resultat:   _testClaudeResultat,
          resultatOk: _testClaudeOk),
      ]),
    const SizedBox(height: 16),

    // ══ SECTION 3 : OPENAI CHATGPT + DALL-E ═══════════
    _CarteSection(
      titre: '⚡ OpenAI ChatGPT + DALL-E',
      sousTitre: 'Texte ET génération d\'images',
      children: [
        // Info même clé
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FFF4),
            borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            const Text('💡', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'La même clé OpenAI fonctionne pour '
              'ChatGPT (texte) ET DALL-E (images).',
              style: GoogleFonts.inter(
                fontSize: 11, color: const Color(0xFF065F46),
                height: 1.4))),
          ])),
        const SizedBox(height: 10),
        // Clé API
        _buildChampCleGoogle(
          cle:   'openai_api_key',
          label: 'Clé API OpenAI',
          hint:  'sk-proj-...'),
        const SizedBox(height: 10),
        // Boutons tester
        Row(children: [
          Expanded(child: _BoutonTester(
            label:      'Tester ChatGPT',
            couleur:    const Color(0xFF10B981),
            onTap:      _testerOpenAI,
            enCours:    _testOpenAIEnCours,
            resultat:   _testOpenAIResultat,
            resultatOk: _testOpenAIOk)),
          const SizedBox(width: 10),
          Expanded(child: _BoutonTester(
            label:      'Tester DALL-E',
            couleur:    const Color(0xFFF59E0B),
            onTap:      _testerDallE,
            enCours:    _testDallEEnCours,
            resultat:   _testDallEResultat,
            resultatOk: _testDallEOk)),
        ]),
      ]),
    const SizedBox(height: 16),

    // ══ SECTION 4 : TOGGLES FONCTIONNALITÉS IA ═════════
    _CarteSection(
      titre: '⚙️ Fonctionnalités IA',
      children: [
        _ToggleIA('ia_matching_actif',
          '🎯 Scoring compatibilité offres',
          'Claude analyse profil vs offre'),
        _ToggleIA('ia_simulateur_actif',
          '🎤 Simulateur d\'entretien IA',
          'Claude génère et évalue les entretiens'),
        _ToggleIA('ia_calculateur_actif',
          '💰 Calculateur de salaire IA',
          'Claude estime les salaires guinéens'),
        _ToggleIA('illustration_ia_actif',
          '🖼️ Illustrations DALL-E automatiques',
          'OpenAI génère des images chaque jour'),
      ]),
    const SizedBox(height: 16),

    // ══ SECTION 5 : ILLUSTRATION HOMEPAGE ══════════════
    _CarteSection(
      titre: '🖼️ Illustration de la homepage',
      sousTitre: 'Image affichée dans la section "Ils ont réussi"',
      children: [
        _IllustrationManagerWidget(),
      ]),
  ]));

// Widget badge statut
class _StatusBadge extends StatelessWidget {
  final String provider;
  final bool   actif, cleConfigure;
  const _StatusBadge({required this.provider,
    required this.actif, required this.cleConfigure});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: actif
          ? const Color(0xFFECFDF5)
          : cleConfigure
              ? const Color(0xFFFEF3C7)
              : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: actif
            ? const Color(0xFF10B981).withOpacity(0.4)
            : cleConfigure
                ? const Color(0xFFF59E0B).withOpacity(0.4)
                : const Color(0xFFE2E8F0))),
    child: Row(children: [
      Icon(
        actif ? Icons.check_circle_rounded
            : cleConfigure ? Icons.warning_rounded
                : Icons.cancel_rounded,
        color: actif
            ? const Color(0xFF10B981)
            : cleConfigure
                ? const Color(0xFFF59E0B)
                : const Color(0xFF94A3B8),
        size: 18),
      const SizedBox(width: 8),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(provider, style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A))),
        Text(
          actif       ? 'Actif ✅'
          : cleConfigure ? 'Clé configurée ⚠️'
                        : 'Non configuré',
          style: GoogleFonts.inter(
            fontSize: 10,
            color: actif
                ? const Color(0xFF10B981)
                : cleConfigure
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF94A3B8))),
      ])),
    ]));
}

// Widget bouton tester
class _BoutonTester extends StatelessWidget {
  final String label, couleur_; final Color couleur;
  final VoidCallback onTap;
  final bool enCours, resultatOk;
  final String? resultat;
  const _BoutonTester({
    required this.label, required this.couleur,
    required this.onTap, required this.enCours,
    this.resultat, this.resultatOk = false,
    this.couleur_ = ''});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    OutlinedButton.icon(
      icon: enCours
          ? SizedBox(width: 12, height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: couleur))
          : Icon(Icons.play_arrow_rounded,
              size: 14, color: couleur),
      label: Text(enCours ? 'Test...' : label,
        style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: couleur)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: couleur.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8))),
      onPressed: enCours ? null : onTap),
    if (resultat != null)
      Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: resultatOk
              ? const Color(0xFFECFDF5)
              : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(6)),
        child: Text(resultat!,
          style: GoogleFonts.inter(
            fontSize: 10, fontWeight: FontWeight.w600,
            color: resultatOk
                ? const Color(0xFF065F46)
                : const Color(0xFF991B1B)))),
  ]);
}

// Widget toggle IA
Widget _ToggleIA(String cle, String titre, String desc) =>
  Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(titre, style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A))),
        Text(desc, style: GoogleFonts.inter(
          fontSize: 11, color: const Color(0xFF94A3B8))),
      ])),
      Switch(
        value: (_params[cle] ?? 'true') != 'false',
        activeColor: const Color(0xFF1A56DB),
        onChanged: (v) {
          final val = v ? 'true' : 'false';
          setState(() => _params[cle] = val);
          _saveParam(cle, val);
        }),
    ]));
```

---

## Résumé des changements

```
AVANT :
→ Illustrations IA = menu séparé dans la sidebar
→ Pas de test automatique des clés
→ Un seul provider à la fois
→ Pas d'upload manuel d'image

APRÈS :
→ Illustrations IA = dans Paramètres → IA
→ Bouton "Tester" pour Claude, OpenAI, DALL-E
→ Si Claude + OpenAI activés → fallback automatique
→ Upload image manuelle avec FilePicker
→ Statut en temps réel de chaque API
→ Toggles pour chaque fonctionnalité IA
```

---

## Critères d'Acceptation

### Déplacement Illustrations
- [ ] Entrée "Illustrations IA" supprimée du menu sidebar
- [ ] Widget illustrations intégré dans Paramètres → IA
- [ ] Bouton "Générer maintenant" fonctionne
- [ ] Grille images avec bouton "Activer"

### Upload manuel
- [ ] Cliquer "📁 Choisir une image" → FilePicker s'ouvre
- [ ] Image uploadée dans Supabase Storage
- [ ] Aperçu visible dans les paramètres
- [ ] Page d'accueil affiche la nouvelle image

### Tests automatiques
- [ ] "Tester Claude" → SnackBar vert si OK
- [ ] "Tester OpenAI" → SnackBar vert si OK
- [ ] "Tester DALL-E" → SnackBar vert si OK
- [ ] Messages d'erreur clairs si clé manquante

### Multi-provider
- [ ] Claude activé + OpenAI activé → Claude utilisé en priorité
- [ ] Si Claude échoue → bascule sur OpenAI automatiquement
- [ ] Logs backend montrent le provider utilisé
- [ ] Status badges corrects dans l'interface

---

*PRD EmploiConnect v9.3 — Paramètres IA Unifiés*
*Cursor / Kirsoft AI — Phase 26*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
