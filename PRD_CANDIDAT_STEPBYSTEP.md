# PRD — EmploiConnect · Espace Candidat — Plan Complet Étape par Étape
## Product Requirements Document v6.1 — Candidat Complete Fix
**Stack : Flutter + Node.js/Express + PostgreSQL/Supabase**
**Outil : Cursor / Kirsoft AI**
**Méthode : Étape par étape — tester avant de passer à la suivante**
**Date : Mars 2026**

---

> ### ⚠️ INSTRUCTIONS CRITIQUES POUR CURSOR
>
> Ce PRD se lit et s'exécute ÉTAPE PAR ÉTAPE.
> STOP après chaque étape → attendre validation → continuer.
> Se référer à la logique existante : Admin ✅ · Recruteur ✅ · Candidat → en cours.
> Cohérence totale avec la BDD existante.

---

## PLAN GLOBAL — 10 Étapes

```
ÉTAPE 1  → Fix critique : Upload photo + CV (MIME types)
ÉTAPE 2  → Fix design global : espacement + layout
ÉTAPE 3  → Vue d'ensemble candidat : données réelles
ÉTAPE 4  → Mon Profil & CV : complétion cohérente
ÉTAPE 5  → Recherche offres : scores IA cohérents
ÉTAPE 6  → Mes candidatures : liste + filtres
ÉTAPE 7  → Offres sauvegardées : bookmark fonctionnel
ÉTAPE 8  → Alertes emploi : CRUD complet
ÉTAPE 9  → Messagerie + Notifications : données réelles
ÉTAPE 10 → Paramètres candidat : toutes options
```

---

# ÉTAPE 1 — Fix Upload Photo + CV

> **STOP après cette étape — Tester upload photo ET CV avant de continuer.**

## 1.1 Diagnostiquer le bucket Supabase

Exécuter dans le terminal backend :
```javascript
// Créer backend/src/scripts/check_buckets.js et exécuter avec node

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function checkBuckets() {
  const buckets = ['avatars', 'cv-files', 'logos', 'bannieres'];
  for (const name of buckets) {
    try {
      const { data, error } = await supabase.storage.getBucket(name);
      if (error) {
        console.log(`❌ Bucket "${name}" MANQUANT : ${error.message}`);
        // Créer le bucket automatiquement
        const { error: createErr } = await supabase.storage.createBucket(name, {
          public: ['avatars', 'logos', 'bannieres'].includes(name),
          allowedMimeTypes: null, // Accepter tous les types
          fileSizeLimit: 20 * 1024 * 1024,
        });
        if (createErr) {
          console.log(`  → Création échouée : ${createErr.message}`);
        } else {
          console.log(`  → ✅ Bucket "${name}" créé avec succès`);
        }
      } else {
        console.log(`✅ Bucket "${name}" OK (public: ${data.public})`);
      }
    } catch (e) {
      console.log(`❌ Erreur "${name}" : ${e.message}`);
    }
  }
}

checkBuckets();
```

```bash
cd backend && node src/scripts/check_buckets.js
```

Montrer le résultat.

## 1.2 Fix Backend — Multer accepte TOUT

Trouver tous les fichiers qui contiennent `multer` dans le backend :
```bash
grep -rn "multer\|fileFilter\|MIME\|mimetype" backend/src --include="*.js" -l
```

Dans CHAQUE fichier trouvé, remplacer la fonction `fileFilter` par :
```javascript
// Remplacer TOUTE fonction fileFilter par cette version permissive :
fileFilter: (req, file, cb) => {
  // Accepter TOUT — la validation se fait côté serveur après
  console.log('[Upload] Fichier reçu:', file.originalname, file.mimetype, file.size);
  cb(null, true);
},
```

## 1.3 Fix Backend — Route upload photo profil

Trouver la route upload photo :
```bash
grep -rn "photo\|avatar" backend/src/routes --include="*.js" -l
```

Remplacer complètement la route par :
```javascript
// Route POST /api/users/photo ou /api/users/me/photo
// (adapter selon ce qui existe)

const multerPhoto = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 15 * 1024 * 1024 }, // 15MB
  fileFilter: (req, file, cb) => cb(null, true), // Tout accepter
});

router.post('/photo', auth, multerPhoto.single('photo'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Aucun fichier reçu par le serveur'
      });
    }

    console.log('[uploadPhoto] Reçu:', {
      name: req.file.originalname,
      mime: req.file.mimetype,
      size: req.file.size,
    });

    // Convertir en JPEG avec sharp (ou utiliser le buffer direct)
    let buffer   = req.file.buffer;
    let mimeType = 'image/jpeg';
    let ext      = 'jpg';

    try {
      const sharp = require('sharp');
      buffer = await sharp(req.file.buffer, { failOnError: false })
        .resize(400, 400, { fit: 'cover', position: 'centre' })
        .jpeg({ quality: 85 })
        .toBuffer();
      console.log('[uploadPhoto] Sharp OK');
    } catch (sharpErr) {
      console.warn('[uploadPhoto] Sharp échoué, buffer direct:', sharpErr.message);
      buffer   = req.file.buffer;
      mimeType = req.file.mimetype || 'image/jpeg';
      ext      = req.file.originalname?.split('.').pop()?.toLowerCase() || 'jpg';
    }

    const bucket   = 'avatars';
    const fileName = `avatar-${req.user.id}-${Date.now()}.${ext}`;

    console.log('[uploadPhoto] Upload vers bucket:', bucket, fileName);

    const { error: uploadErr } = await supabase.storage
      .from(bucket)
      .upload(fileName, buffer, {
        contentType: mimeType,
        upsert: true,
        cacheControl: '3600',
      });

    if (uploadErr) {
      console.error('[uploadPhoto] Erreur Supabase:', uploadErr);
      return res.status(500).json({
        success: false,
        message: `Erreur storage: ${uploadErr.message}`,
        detail: uploadErr
      });
    }

    const { data: urlData } = supabase.storage
      .from(bucket).getPublicUrl(fileName);
    const photoUrl = urlData.publicUrl;

    console.log('[uploadPhoto] URL publique:', photoUrl);

    await supabase.from('utilisateurs')
      .update({
        photo_url:         photoUrl,
        date_modification: new Date().toISOString(),
      })
      .eq('id', req.user.id);

    return res.json({
      success: true,
      message: 'Photo mise à jour avec succès',
      data: { photo_url: photoUrl }
    });

  } catch (err) {
    console.error('[uploadPhoto] Exception:', err);
    res.status(500).json({
      success: false,
      message: err.message || 'Erreur upload',
    });
  }
});
```

## 1.4 Fix Backend — Route upload CV

```javascript
const multerCV = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 20 * 1024 * 1024 }, // 20MB
  fileFilter: (req, file, cb) => cb(null, true), // Tout accepter
});

router.post('/upload', auth, multerCV.single('cv'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false, message: 'Aucun fichier CV reçu'
      });
    }

    console.log('[uploadCV]', {
      name: req.file.originalname,
      mime: req.file.mimetype,
      size: req.file.size,
    });

    // Détecter l'extension
    const ext = (req.file.originalname || 'cv').split('.').pop()
      .toLowerCase().replace(/[^a-z0-9]/g, '') || 'pdf';

    // Corriger le MIME type si nécessaire
    const mimeMap = {
      'pdf':  'application/pdf',
      'doc':  'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    };
    const mimeType = mimeMap[ext] || req.file.mimetype || 'application/octet-stream';

    // Récupérer chercheur_id
    const { data: chercheur, error: chercheurErr } = await supabase
      .from('chercheurs_emploi')
      .select('id')
      .eq('utilisateur_id', req.user.id)
      .single();

    if (chercheurErr || !chercheur) {
      // Créer le profil chercheur s'il n'existe pas
      const { data: newChercheur } = await supabase
        .from('chercheurs_emploi')
        .insert({ utilisateur_id: req.user.id })
        .select()
        .single();
      if (!newChercheur) {
        return res.status(404).json({
          success: false, message: 'Profil candidat non trouvé'
        });
      }
    }

    const chercheurId = chercheur?.id;
    const bucket      = process.env.SUPABASE_STORAGE_BUCKET || 'cv-files';
    const fileName    = `cv-${chercheurId}-${Date.now()}.${ext}`;

    console.log('[uploadCV] Upload vers:', bucket, fileName);

    const { error: uploadErr } = await supabase.storage
      .from(bucket)
      .upload(fileName, req.file.buffer, {
        contentType: mimeType,
        upsert: false,
      });

    if (uploadErr) {
      console.error('[uploadCV] Erreur Supabase:', uploadErr);
      return res.status(500).json({
        success: false,
        message: `Erreur storage: ${uploadErr.message}`
      });
    }

    const { data: urlData } = supabase.storage
      .from(bucket).getPublicUrl(fileName);
    const cvUrl = urlData.publicUrl;

    // Sauvegarder en BDD
    const { data: cv, error: dbErr } = await supabase
      .from('cv')
      .upsert({
        chercheur_id:      chercheurId,
        fichier_url:       cvUrl,
        nom_fichier:       req.file.originalname,
        taille_fichier:    req.file.size,
        type_fichier:      ext.toUpperCase(),
        date_upload:       new Date().toISOString(),
        date_modification: new Date().toISOString(),
      }, { onConflict: 'chercheur_id' })
      .select()
      .single();

    if (dbErr) {
      console.error('[uploadCV] DB error:', dbErr);
      throw dbErr;
    }

    // Analyse IA en arrière-plan
    setImmediate(async () => {
      try {
        const { analyserCV } = require('../services/ia.service');
        const resultat = await analyserCV(cvUrl);
        await supabase.from('cv').update({
          competences_extrait: {
            competences: resultat.competences || [],
            experience:  resultat.experience  || [],
            formation:   resultat.formation   || [],
            langues:     resultat.langues     || ['Français'],
            fallback:    resultat.fallback    || true,
            analyse_le:  new Date().toISOString(),
          },
          date_analyse: new Date().toISOString(),
        }).eq('id', cv.id);
        console.log('[uploadCV] IA OK:', resultat.competences?.length, 'compétences');
      } catch (e) {
        console.warn('[uploadCV] IA non bloquant:', e.message);
      }
    });

    return res.status(201).json({
      success: true,
      message: 'CV uploadé avec succès. Analyse IA en cours...',
      data: {
        id:          cv.id,
        fichier_url: cvUrl,
        nom_fichier: req.file.originalname,
      }
    });

  } catch (err) {
    console.error('[uploadCV] Exception:', err);
    res.status(500).json({
      success: false,
      message: err.message || 'Erreur upload CV',
    });
  }
});
```

## 1.5 Fix Flutter — Upload photo avec bonne gestion des erreurs

```dart
// Dans le widget d'upload photo du candidat
// Remplacer la méthode _uploadPhoto() par :

Future<void> _uploadPhoto() async {
  try {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth:     800,
      maxHeight:    800,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _isUploading = true);

    final bytes = await file.readAsBytes();
    print('[uploadPhoto] Fichier: ${file.name}, taille: ${bytes.length}');

    // Détecter le type MIME
    final ext  = file.path.split('.').last.toLowerCase();
    String mime;
    switch (ext) {
      case 'jpg': case 'jpeg': mime = 'image/jpeg'; break;
      case 'png':  mime = 'image/png';  break;
      case 'webp': mime = 'image/webp'; break;
      case 'gif':  mime = 'image/gif';  break;
      default:     mime = 'image/jpeg'; // Forcer JPEG par défaut
    }

    final token = context.read<AuthProvider>().token ?? '';

    // Chercher la bonne URL upload
    // Essayer /api/users/photo d'abord, puis /api/users/me/photo
    final urls = [
      '${ApiConfig.baseUrl}/api/users/photo',
      '${ApiConfig.baseUrl}/api/users/me/photo',
      '${ApiConfig.baseUrl}/api/candidat/photo',
    ];

    http.Response? response;
    for (final url in urls) {
      try {
        final request = http.MultipartRequest('POST', Uri.parse(url));
        request.headers['Authorization'] = 'Bearer $token';
        request.files.add(http.MultipartFile.fromBytes(
          'photo', bytes,
          filename: 'photo.$ext',
          contentType: MediaType.parse(mime),
        ));
        final streamed = await request.send()
          .timeout(const Duration(seconds: 30));
        response = await http.Response.fromStream(streamed);
        if (response.statusCode != 404) break;
      } catch (_) {}
    }

    if (response == null) {
      throw Exception('Aucune route upload trouvée');
    }

    print('[uploadPhoto] Status: ${response.statusCode}');
    print('[uploadPhoto] Body: ${response.body.substring(0, min(200, response.body.length))}');

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['success'] == true) {
      final newUrl = body['data']['photo_url'] as String;
      setState(() => _photoUrl = newUrl);
      context.read<AppConfigProvider?>()?.reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Photo mise à jour !'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } else {
      throw Exception(body['message'] ?? 'Erreur ${response.statusCode}');
    }
  } catch (e) {
    print('[uploadPhoto] Erreur: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur upload photo: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ));
    }
  } finally {
    setState(() => _isUploading = false);
  }
}
```

## ✅ TEST ÉTAPE 1
```
Tester :
1. Upload photo → pas d'erreur "MIME non supporté"
2. Upload CV PDF → pas d'erreur
3. Logs backend montrent : "[Upload] Fichier reçu: ..."
→ Si OK : dire "Étape 1 validée" et passer à l'étape 2
→ Si KO : montrer les logs backend exacts
```

---

# ÉTAPE 2 — Fix Design Global Espace Candidat

> **STOP après cette étape — Vérifier visuellement l'espacement.**

## 2.1 Layout principal candidat

```dart
// Dans frontend/lib/screens/candidat/candidat_shell.dart
// Ajouter un espacement entre la sidebar et le contenu

class CandidatShell extends StatelessWidget {
  final Widget child;
  const CandidatShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Row(children: [
          // Sidebar
          CandidatSidebar(),
          // Divider
          const VerticalDivider(
            width: 1, color: Color(0xFFE2E8F0)),
          // Contenu avec PADDING obligatoire
          Expanded(child: child),
        ]),
      );
    }

    // Mobile : bottom navigation
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: child,
      bottomNavigationBar: CandidatBottomNav(),
    );
  }
}
```

## 2.2 Règle padding sur TOUTES les pages candidat

```
Chercher dans frontend/lib/screens/candidat/pages/
tous les fichiers .dart et appliquer :

padding: const EdgeInsets.all(16)
→ remplacer par :
padding: const EdgeInsets.fromLTRB(20, 16, 20, 20)

Ou pour les SingleChildScrollView :
padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)

Pour les ListView.builder :
padding: const EdgeInsets.fromLTRB(20, 12, 20, 80)
(80 pour éviter que le dernier item soit caché par le bottom nav)

Pour les Cards/Containers dans les listes :
margin: const EdgeInsets.only(bottom: 12)
(pas de margin latérale — le parent a déjà le padding)
```

## 2.3 Sidebar candidat — Espacement correct

```dart
// Dans candidat_sidebar.dart
// S'assurer que le contenu a un padding correct

ListView(
  padding: const EdgeInsets.symmetric(
    horizontal: 12, vertical: 8), // ← Padding interne sidebar
  children: [...],
)
```

## ✅ TEST ÉTAPE 2
```
Vérifier visuellement :
1. Entre la sidebar et le contenu : espace correct
2. Cards des offres/candidatures : pas collées aux bords
3. Dernier item de liste : visible entièrement
→ Si OK : dire "Étape 2 validée"
```

---

# ÉTAPE 3 — Vue d'ensemble Candidat

> **STOP — Tester que la vue d'ensemble affiche des données réelles.**

## 3.1 Backend — Route dashboard candidat

```javascript
// Vérifier que cette route existe dans backend/src/routes/
// Si elle n'existe pas, la créer dans candidat.routes.js

// GET /api/candidat/dashboard
router.get('/dashboard', auth, async (req, res) => {
  try {
    // Récupérer le chercheur
    const { data: chercheur } = await supabase
      .from('chercheurs_emploi')
      .select(`
        id, competences, niveau_etude, disponibilite,
        profil_visible, titre_poste, about,
        utilisateur:utilisateur_id (
          nom, email, photo_url, telephone, adresse
        )
      `)
      .eq('utilisateur_id', req.user.id)
      .single();

    // CV
    const { data: cv } = await supabase
      .from('cv')
      .select('id, fichier_url, nom_fichier, competences_extrait, date_analyse')
      .eq('chercheur_id', chercheur?.id)
      .single();

    // Candidatures
    const { data: candidatures } = await supabase
      .from('candidatures')
      .select('id, statut, date_candidature, offre:offre_id(titre)')
      .eq('chercheur_id', chercheur?.id)
      .order('date_candidature', { ascending: false })
      .limit(5);

    // Stats candidatures
    const { data: tousStatuts } = await supabase
      .from('candidatures')
      .select('statut')
      .eq('chercheur_id', chercheur?.id);

    // Offres recommandées (top 4)
    const { data: offresRecentes } = await supabase
      .from('offres_emploi')
      .select(`
        id, titre, localisation, type_contrat,
        salaire_min, salaire_max, devise, en_vedette,
        entreprise:entreprise_id (nom_entreprise, logo_url)
      `)
      .eq('statut', 'publiee')
      .order('date_publication', { ascending: false })
      .limit(4);

    // Notifications non lues
    const { count: nbNotifs } = await supabase
      .from('notifications')
      .select('id', { count: 'exact' })
      .eq('destinataire_id', req.user.id)
      .eq('est_lue', false);

    // Calcul complétion profil (UNIFIÉ)
    const completion = _calculerCompletion(
      chercheur?.utilisateur, chercheur, cv);

    const stats = {
      total_candidatures:  tousStatuts?.length || 0,
      en_attente:          tousStatuts?.filter(c => c.statut === 'en_attente').length || 0,
      acceptees:           tousStatuts?.filter(c => c.statut === 'acceptee').length || 0,
      entretiens:          tousStatuts?.filter(c => c.statut === 'entretien').length || 0,
    };

    return res.json({
      success: true,
      data: {
        candidat: {
          nom:      chercheur?.utilisateur?.nom || '',
          photo:    chercheur?.utilisateur?.photo_url || null,
          titre:    chercheur?.titre_poste || '',
          dispo:    chercheur?.disponibilite || '',
        },
        completion_profil: completion,
        stats,
        candidatures_recentes: candidatures || [],
        offres_recommandees:   offresRecentes || [],
        nb_notifications:      nbNotifs || 0,
        cv_analyse:            !!cv?.date_analyse,
      }
    });

  } catch (err) {
    console.error('[candidat/dashboard]', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});

// Fonction de calcul complétion (locale dans ce fichier)
function _calculerCompletion(user, chercheur, cv) {
  let pts = 0;
  if (user?.photo_url)      pts += 15;
  if (user?.nom?.trim())    pts += 10;
  if (user?.telephone)      pts += 5;
  if (user?.adresse)        pts += 5;
  if (chercheur?.titre_poste?.trim()) pts += 10;
  if (chercheur?.about?.trim())       pts += 10;
  const comps = Array.isArray(chercheur?.competences)
    ? chercheur.competences
    : Object.values(chercheur?.competences || {});
  if (comps.length > 0) pts += 10;
  if (cv?.fichier_url)    pts += 20;
  if ((cv?.competences_extrait?.competences?.length || 0) > 0) pts += 10;
  if (chercheur?.disponibilite) pts += 5;

  return {
    pourcentage: Math.min(100, pts),
    manquants: [
      !user?.photo_url && { label: 'Photo de profil', pts: 15 },
      !chercheur?.titre_poste && { label: 'Titre professionnel', pts: 10 },
      !chercheur?.about && { label: 'Présentation', pts: 10 },
      !cv?.fichier_url && { label: 'CV uploadé', pts: 20 },
      comps.length === 0 && { label: 'Compétences', pts: 10 },
    ].filter(Boolean),
  };
}
```

## 3.2 Enregistrer la route dans routes/index.js

```javascript
// Dans backend/src/routes/index.js, vérifier/ajouter :

// Routes candidat
const { auth } = require('../middleware/auth');
const candidatRoutes = require('./candidat.routes');
router.use('/candidat', candidatRoutes);
```

## 3.3 Flutter — Page Vue d'ensemble candidat connectée

```dart
// Dans dashboard_candidat_page.dart
// Charger les données depuis /api/candidat/dashboard

class _DashboardCandidatPageState extends State<DashboardCandidatPage> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/candidat/dashboard'),
        headers: { 'Authorization': 'Bearer $token' },
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          setState(() { _data = body['data']; _isLoading = false; });
        }
      }
    } catch (e) {
      print('[Dashboard candidat] Erreur: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(
      child: CircularProgressIndicator(color: Color(0xFF1A56DB)));

    final completion = _data?['completion_profil'] as Map<String, dynamic>? ?? {};
    final pct        = completion['pourcentage'] as int? ?? 0;
    final stats      = _data?['stats'] as Map<String, dynamic>? ?? {};
    final cands      = List<Map<String, dynamic>>.from(
      _data?['candidatures_recentes'] ?? []);
    final offres     = List<Map<String, dynamic>>.from(
      _data?['offres_recommandees'] ?? []);
    final candidat   = _data?['candidat'] as Map<String, dynamic>? ?? {};

    return RefreshIndicator(
      onRefresh: _load, color: const Color(0xFF1A56DB),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Bienvenue
          _buildBienvenue(candidat, pct),
          const SizedBox(height: 20),

          // Complétion profil
          if (pct < 100) ...[
            _buildCompletion(pct, completion['manquants'] ?? []),
            const SizedBox(height: 20),
          ],

          // Stats candidatures
          _buildStats(stats),
          const SizedBox(height: 20),

          // Candidatures récentes
          if (cands.isNotEmpty) ...[
            _buildCandidaturesRecentes(cands),
            const SizedBox(height: 20),
          ],

          // Offres recommandées
          _buildOffresRecommandees(offres),
        ]),
      ),
    );
  }

  Widget _buildBienvenue(Map<String, dynamic> candidat, int pct) {
    final nom   = candidat['nom'] as String? ?? 'Candidat';
    final photo = candidat['photo'] as String?;
    final hour  = DateTime.now().hour;
    final greet = hour < 12 ? 'Bonjour' :
                  hour < 18 ? 'Bon après-midi' : 'Bonsoir';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$greet, $nom 👋', style: GoogleFonts.poppins(
          fontSize: 20, fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A))),
        const SizedBox(height: 4),
        Text('Votre profil est complété à $pct%',
          style: GoogleFonts.inter(
            fontSize: 13, color: const Color(0xFF64748B))),
      ])),
      CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFF1A56DB),
        backgroundImage: photo != null ? NetworkImage(photo) : null,
        child: photo == null ? Text(nom[0].toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w700,
            color: Colors.white)) : null,
      ),
    ]);
  }

  Widget _buildCompletion(int pct, List<dynamic> manquants) =>
    GestureDetector(
      onTap: () => context.push('/dashboard-candidat/profil'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            const Color(0xFF1E3A8A).withOpacity(0.05),
            const Color(0xFF1A56DB).withOpacity(0.02),
          ]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF1A56DB).withOpacity(0.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.account_circle_outlined,
              color: Color(0xFF1A56DB), size: 20),
            const SizedBox(width: 8),
            Text('Complétez votre profil',
              style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: const Color(0xFF1A56DB))),
            const Spacer(),
            Text('$pct%', style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w800,
              color: const Color(0xFF1A56DB))),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct / 100),
              duration: const Duration(milliseconds: 800),
              builder: (_, v, __) => LinearProgressIndicator(
                value: v, minHeight: 8,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation(
                  pct >= 80 ? const Color(0xFF10B981) :
                  pct >= 50 ? const Color(0xFF1A56DB) :
                  const Color(0xFFF59E0B))),
            ),
          ),
          if (manquants.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'À compléter : ${(manquants as List<Map>)
                .take(2).map((m) => m['label']).join(', ')}...',
              style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFF64748B))),
          ],
        ]),
      ),
    );

  Widget _buildStats(Map<String, dynamic> stats) {
    return LayoutBuilder(builder: (ctx, c) {
      final cols = c.maxWidth < 500 ? 2 : 4;
      return GridView.count(
        crossAxisCount: cols, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10, mainAxisSpacing: 10,
        childAspectRatio: 1.6,
        children: [
          _StatMini('Candidatures',
            '${stats['total_candidatures'] ?? 0}',
            Icons.assignment_outlined,
            const Color(0xFF1A56DB), const Color(0xFFEFF6FF)),
          _StatMini('En attente',
            '${stats['en_attente'] ?? 0}',
            Icons.hourglass_empty_rounded,
            const Color(0xFFF59E0B), const Color(0xFFFEF3C7)),
          _StatMini('Entretiens',
            '${stats['entretiens'] ?? 0}',
            Icons.event_available_rounded,
            const Color(0xFF8B5CF6), const Color(0xFFF5F3FF)),
          _StatMini('Acceptées',
            '${stats['acceptees'] ?? 0}',
            Icons.check_circle_rounded,
            const Color(0xFF10B981), const Color(0xFFECFDF5)),
        ],
      );
    });
  }

  Widget _buildCandidaturesRecentes(List<Map<String, dynamic>> cands) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Mes candidatures récentes', style: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A))),
        TextButton(
          onPressed: () => context.push('/dashboard-candidat/candidatures'),
          child: Text('Voir tout', style: GoogleFonts.inter(
            fontSize: 12, color: const Color(0xFF1A56DB)))),
      ]),
      const SizedBox(height: 10),
      ...cands.map((c) {
        final statut = c['statut'] as String? ?? '';
        Color sc; String sl;
        switch (statut) {
          case 'acceptee':  sc = const Color(0xFF10B981); sl = 'Acceptée ✓'; break;
          case 'entretien': sc = const Color(0xFF8B5CF6); sl = 'Entretien'; break;
          case 'en_cours':  sc = const Color(0xFF1A56DB); sl = 'En examen'; break;
          case 'refusee':   sc = const Color(0xFFEF4444); sl = 'Refusée'; break;
          default:          sc = const Color(0xFFF59E0B); sl = 'En attente';
        }
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(children: [
            Expanded(child: Text(
              c['offre']?['titre'] ?? 'Offre',
              style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A)),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: sc.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100)),
              child: Text(sl, style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600, color: sc))),
          ]),
        );
      }),
    ]);

  Widget _buildOffresRecommandees(List<Map<String, dynamic>> offres) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Offres pour vous', style: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A))),
        TextButton(
          onPressed: () => context.push('/dashboard-candidat/offres'),
          child: Text('Voir tout', style: GoogleFonts.inter(
            fontSize: 12, color: const Color(0xFF1A56DB)))),
      ]),
      const SizedBox(height: 10),
      if (offres.isEmpty)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Center(child: Text(
            'Aucune offre disponible pour le moment',
            style: GoogleFonts.inter(
              fontSize: 13, color: const Color(0xFF94A3B8)))))
      else
        ...offres.map((o) => _OffreMiniCard(offre: o)),
    ]);
}

class _StatMini extends StatelessWidget {
  final String label, value;
  final IconData icon; final Color color, bg;
  const _StatMini(this.label, this.value, this.icon, this.color, this.bg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, color: color, size: 15)),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A))),
        Text(label, style: GoogleFonts.inter(
          fontSize: 10, color: const Color(0xFF64748B))),
      ]),
    ]),
  );
}

class _OffreMiniCard extends StatelessWidget {
  final Map<String, dynamic> offre;
  const _OffreMiniCard({required this.offre});

  @override
  Widget build(BuildContext context) {
    final titre  = offre['titre']        as String? ?? '';
    final ent    = offre['entreprise']   as Map?    ?? {};
    final logo   = ent['logo_url']       as String?;
    final nom    = ent['nom_entreprise'] as String? ?? '';
    final loc    = offre['localisation'] as String? ?? '';
    final contrat = offre['type_contrat'] as String? ?? '';

    return GestureDetector(
      onTap: () => context.push('/offres/${offre['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8)),
            child: logo != null
                ? ClipRRect(borderRadius: BorderRadius.circular(8),
                    child: Image.network(logo, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(child: Text(
                        nom.isNotEmpty ? nom[0] : '?',
                        style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A56DB))))))
                : Center(child: Text(nom.isNotEmpty ? nom[0] : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A56DB)))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titre, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A)),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('$nom · $loc · $contrat',
              style: GoogleFonts.inter(
                fontSize: 11, color: const Color(0xFF94A3B8)),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56DB),
              foregroundColor: Colors.white, elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
              textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
            onPressed: () => context.push('/dashboard-candidat/postuler/${offre['id']}'),
            child: const Text('Postuler')),
        ]),
      ),
    );
  }
}
```

## ✅ TEST ÉTAPE 3
```
Tester :
1. Vue d'ensemble affiche : nom du candidat, % complétion, stats candidatures
2. Section "Offres pour vous" affiche des offres réelles
3. Section "Candidatures récentes" affiche les candidatures si elles existent
→ Si OK : dire "Étape 3 validée"
```

---

# ÉTAPE 4 — Mon Profil & CV

> **STOP — Vérifier que le % de complétion est identique partout.**

## 4.1 Utiliser la même logique de calcul partout

```javascript
// Dans backend/src/routes/users.routes.js ou profil.routes.js
// Route GET /api/users/me — ajouter le calcul de complétion

router.get('/me', auth, async (req, res) => {
  try {
    const { data: user } = await supabase
      .from('utilisateurs')
      .select('id, nom, email, telephone, adresse, photo_url, role')
      .eq('id', req.user.id)
      .single();

    // Pour les candidats, ajouter les données complètes
    let completion = null;
    if (user?.role === 'chercheur') {
      const { data: chercheur } = await supabase
        .from('chercheurs_emploi')
        .select('*')
        .eq('utilisateur_id', req.user.id)
        .single();

      const { data: cv } = await supabase
        .from('cv')
        .select('id, fichier_url, competences_extrait')
        .eq('chercheur_id', chercheur?.id)
        .single();

      // Même calcul que dans /api/candidat/dashboard
      let pts = 0;
      if (user?.photo_url)      pts += 15;
      if (user?.nom?.trim())    pts += 10;
      if (user?.telephone)      pts += 5;
      if (user?.adresse)        pts += 5;
      if (chercheur?.titre_poste) pts += 10;
      if (chercheur?.about)       pts += 10;
      const comps = Array.isArray(chercheur?.competences)
        ? chercheur.competences
        : Object.values(chercheur?.competences || {});
      if (comps.length > 0) pts += 10;
      if (cv?.fichier_url) pts += 20;
      if ((cv?.competences_extrait?.competences?.length || 0) > 0) pts += 10;
      if (chercheur?.disponibilite) pts += 5;

      completion = { pourcentage: Math.min(100, pts) };
    }

    return res.json({
      success: true,
      data: { ...user, completion_profil: completion }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});
```

## 4.2 Flutter — Sidebar utilise completion_profil de l'API

```dart
// Dans candidat_sidebar.dart
// Le % affiché doit venir du CandidatProvider/AuthProvider
// et non être calculé localement

Consumer<CandidatProvider>(
  builder: (ctx, provider, _) {
    final pct = provider.completionPourcentage; // Depuis l'API
    return Column(children: [
      // Barre de progression
      LinearProgressIndicator(
        value: pct / 100,
        backgroundColor: const Color(0xFFE2E8F0),
        valueColor: AlwaysStoppedAnimation(
          pct >= 80 ? const Color(0xFF10B981) :
          pct >= 50 ? const Color(0xFF1A56DB) :
          const Color(0xFFF59E0B)),
        minHeight: 4,
      ),
      const SizedBox(height: 4),
      Text('$pct% complété',
        style: GoogleFonts.inter(
          fontSize: 11, color: const Color(0xFF64748B))),
    ]);
  },
)
```

## ✅ TEST ÉTAPE 4
```
Tester :
1. % sidebar = % vue d'ensemble = % page profil (même valeur)
2. Upload photo → % augmente
3. Remplir un champ profil → % augmente
→ Si OK : dire "Étape 4 validée"
```

---

# ÉTAPE 5 — Recherche Offres & Scores IA

> **STOP — Vérifier que les scores sont cohérents.**

## 5.1 Exécuter la migration SQL

```sql
-- Dans Supabase SQL Editor :
CREATE TABLE IF NOT EXISTS offres_scores_cache (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chercheur_id UUID NOT NULL REFERENCES chercheurs_emploi(id)
    ON DELETE CASCADE,
  offre_id     UUID NOT NULL REFERENCES offres_emploi(id)
    ON DELETE CASCADE,
  score        INTEGER NOT NULL DEFAULT 0,
  calcule_le   TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(chercheur_id, offre_id)
);

SELECT 'offres_scores_cache créé' AS status;
```

## 5.2 Flutter — Afficher score ou "—" (jamais 0% faux)

```dart
// Dans la carte d'offre :
// Si score = null → afficher "—" (pas encore calculé)
// Si score = 0 → afficher "—"
// Si score > 0 → afficher le badge

Widget _buildScoreBadge(int? score) {
  if (score == null || score == 0) {
    // Score pas encore calculé → ne pas afficher 0%
    return const SizedBox.shrink(); // Rien du tout
  }
  // Score réel
  return IAScoreBadge(score: score);
}
```

## ✅ TEST ÉTAPE 5
```
Tester :
1. Page recherche offres → les offres sans score n'affichent pas "0%"
2. Page recommandations → même score que dans la recherche
→ Si OK : dire "Étape 5 validée"
```

---

# ÉTAPE 6 — Mes Candidatures

> **STOP — Vérifier la liste des candidatures.**

## 6.1 Vérifier que la route existe et est enregistrée

```bash
# Chercher la route
grep -rn "candidatures" backend/src/routes --include="*.js" | grep "GET.*candidat"

# Vérifier qu'elle est dans index.js
grep -n "candidat" backend/src/routes/index.js
```

## 6.2 Si la route n'existe pas, la créer

```javascript
// Dans backend/src/routes/candidat.routes.js, ajouter :

router.get('/candidatures', auth, async (req, res) => {
  try {
    const { statut } = req.query;

    const { data: chercheur } = await supabase
      .from('chercheurs_emploi')
      .select('id')
      .eq('utilisateur_id', req.user.id)
      .single();

    if (!chercheur) {
      return res.json({
        success: true,
        data: { candidatures: [], stats: {} }
      });
    }

    let query = supabase
      .from('candidatures')
      .select(`
        id, statut, score_compatibilite,
        date_candidature, date_modification,
        offre:offre_id (
          id, titre, localisation, type_contrat,
          date_limite,
          entreprise:entreprise_id (
            nom_entreprise, logo_url
          )
        )
      `)
      .eq('chercheur_id', chercheur.id)
      .order('date_candidature', { ascending: false });

    if (statut && statut !== 'all') {
      query = query.eq('statut', statut);
    }

    const { data, error } = await query;
    if (error) throw error;

    // Stats
    const { data: tous } = await supabase
      .from('candidatures')
      .select('statut')
      .eq('chercheur_id', chercheur.id);

    return res.json({
      success: true,
      data: {
        candidatures: data || [],
        stats: {
          total:      tous?.length || 0,
          en_attente: tous?.filter(c => c.statut === 'en_attente').length || 0,
          en_cours:   tous?.filter(c => c.statut === 'en_cours').length || 0,
          entretien:  tous?.filter(c => c.statut === 'entretien').length || 0,
          acceptees:  tous?.filter(c => c.statut === 'acceptee').length || 0,
          refusees:   tous?.filter(c => c.statut === 'refusee').length || 0,
        }
      }
    });
  } catch (err) {
    console.error('[candidat/candidatures]', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
});
```

## ✅ TEST ÉTAPE 6
```
Tester :
1. Page Mes candidatures charge sans erreur
2. Si candidatures existent → elles s'affichent
3. Si pas de candidatures → message "Aucune candidature"
→ Si OK : dire "Étape 6 validée"
```

---

# ÉTAPE 7 — Offres Sauvegardées

> **STOP — Vérifier que le bookmark fonctionne.**

## 7.1 Exécuter migration SQL

```sql
CREATE TABLE IF NOT EXISTS offres_sauvegardees (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chercheur_id UUID NOT NULL REFERENCES chercheurs_emploi(id) ON DELETE CASCADE,
  offre_id     UUID NOT NULL REFERENCES offres_emploi(id) ON DELETE CASCADE,
  date_sauvegarde TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(chercheur_id, offre_id)
);

SELECT 'offres_sauvegardees créé' AS status;
```

## 7.2 Routes sauvegardes

```javascript
// Dans candidat.routes.js

// Sauvegarder une offre
router.post('/offres-sauvegardees/:offreId', auth, async (req, res) => {
  try {
    const { data: chercheur } = await supabase
      .from('chercheurs_emploi')
      .select('id')
      .eq('utilisateur_id', req.user.id)
      .single();

    if (!chercheur) {
      return res.status(404).json({
        success: false, message: 'Profil candidat non trouvé'
      });
    }

    await supabase.from('offres_sauvegardees').upsert({
      chercheur_id:    chercheur.id,
      offre_id:        req.params.offreId,
      date_sauvegarde: new Date().toISOString(),
    }, { onConflict: 'chercheur_id,offre_id' });

    return res.json({ success: true, message: 'Offre sauvegardée' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Supprimer une sauvegarde
router.delete('/offres-sauvegardees/:offreId', auth, async (req, res) => {
  try {
    const { data: chercheur } = await supabase
      .from('chercheurs_emploi')
      .select('id')
      .eq('utilisateur_id', req.user.id)
      .single();

    await supabase.from('offres_sauvegardees')
      .delete()
      .eq('chercheur_id', chercheur?.id)
      .eq('offre_id', req.params.offreId);

    return res.json({ success: true, message: 'Offre retirée des favoris' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Liste des offres sauvegardées
router.get('/offres-sauvegardees', auth, async (req, res) => {
  try {
    const { data: chercheur } = await supabase
      .from('chercheurs_emploi')
      .select('id')
      .eq('utilisateur_id', req.user.id)
      .single();

    const { data } = await supabase
      .from('offres_sauvegardees')
      .select(`
        id, date_sauvegarde,
        offre:offre_id (
          id, titre, localisation, type_contrat,
          statut, date_limite,
          entreprise:entreprise_id (nom_entreprise, logo_url)
        )
      `)
      .eq('chercheur_id', chercheur?.id)
      .eq('offre.statut', 'publiee')
      .order('date_sauvegarde', { ascending: false });

    return res.json({ success: true, data: data || [] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});
```

## ✅ TEST ÉTAPE 7
```
Tester :
1. Cliquer bookmark sur une offre → icône change (remplie)
2. Aller dans page "Offres sauvegardées" → offre apparaît
3. Cliquer à nouveau bookmark → offre disparaît
→ Si OK : dire "Étape 7 validée"
```

---

# ÉTAPE 8 — Alertes Emploi

> **STOP — Vérifier que les alertes fonctionnent.**

## 8.1 Migration SQL

```sql
CREATE TABLE IF NOT EXISTS alertes_emploi (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chercheur_id UUID NOT NULL REFERENCES chercheurs_emploi(id) ON DELETE CASCADE,
  nom          VARCHAR(100) NOT NULL,
  mots_cles    TEXT DEFAULT '',
  localisation VARCHAR(100) DEFAULT '',
  type_contrat VARCHAR(50),
  domaine      VARCHAR(100),
  frequence    VARCHAR(20) DEFAULT 'quotidien',
  est_active   BOOLEAN DEFAULT TRUE,
  date_creation TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

SELECT 'alertes_emploi créé' AS status;
```

## 8.2 Routes alertes

```javascript
// CRUD complet dans candidat.routes.js

router.get('/alertes', auth, async (req, res) => {
  try {
    const { data: chercheur } = await supabase
      .from('chercheurs_emploi').select('id')
      .eq('utilisateur_id', req.user.id).single();
    const { data } = await supabase
      .from('alertes_emploi').select('*')
      .eq('chercheur_id', chercheur?.id)
      .order('date_creation', { ascending: false });
    return res.json({ success: true, data: data || [] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/alertes', auth, async (req, res) => {
  try {
    const { nom, mots_cles, localisation, type_contrat,
            domaine, frequence } = req.body;
    if (!nom?.trim()) {
      return res.status(400).json({
        success: false, message: 'Nom de l\'alerte requis'
      });
    }
    const { data: chercheur } = await supabase
      .from('chercheurs_emploi').select('id')
      .eq('utilisateur_id', req.user.id).single();
    const { data, error } = await supabase
      .from('alertes_emploi')
      .insert({
        chercheur_id:  chercheur?.id,
        nom:           nom.trim(),
        mots_cles:     mots_cles     || '',
        localisation:  localisation  || '',
        type_contrat:  type_contrat  || null,
        domaine:       domaine       || null,
        frequence:     frequence     || 'quotidien',
        est_active:    true,
        date_creation: new Date().toISOString(),
      }).select().single();
    if (error) throw error;
    return res.status(201).json({
      success: true, message: 'Alerte créée', data
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.patch('/alertes/:id', auth, async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('alertes_emploi')
      .update({ ...req.body })
      .eq('id', req.params.id)
      .select().single();
    if (error) throw error;
    return res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.delete('/alertes/:id', auth, async (req, res) => {
  try {
    await supabase.from('alertes_emploi')
      .delete().eq('id', req.params.id);
    return res.json({ success: true, message: 'Alerte supprimée' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});
```

## ✅ TEST ÉTAPE 8
```
Tester :
1. Créer une alerte emploi
2. Elle apparaît dans la liste
3. Activer/désactiver → toggle fonctionne
4. Supprimer → disparaît
→ Si OK : dire "Étape 8 validée"
```

---

# ÉTAPE 9 — Messagerie + Notifications

> **STOP — Vérifier messagerie et notifications.**

## 9.1 Vérifier que les routes notifications/messages sont enregistrées

```bash
grep -n "notifications\|messages" backend/src/routes/index.js
```

Si manquant, ajouter :
```javascript
router.use('/notifications', require('./notifications.routes'));
router.use('/messages', require('./messages.routes'));
```

## 9.2 Fix Flutter — Polling messagerie

```dart
// Dans la page messagerie candidat
// Ajouter un Timer pour le polling

@override
void initState() {
  super.initState();
  _loadConversations();
  // Polling toutes les 5 secondes
  _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
    if (_convActiveId != null) {
      _pollNouveauxMessages();
    }
  });
}

@override
void dispose() {
  _pollTimer?.cancel();
  super.dispose();
}
```

## ✅ TEST ÉTAPE 9
```
Tester :
1. Envoyer un message → apparaît dans la liste
2. Notification reçue → affichée dans la page notifications
3. Marquer comme lu → badge diminue
→ Si OK : dire "Étape 9 validée"
```

---

# ÉTAPE 10 — Paramètres Candidat

> **STOP — Vérifier que les paramètres sauvegardent.**

## 10.1 Ajouter colonnes manquantes en BDD

```sql
ALTER TABLE chercheurs_emploi
  ADD COLUMN IF NOT EXISTS profil_visible BOOLEAN DEFAULT TRUE;
ALTER TABLE chercheurs_emploi
  ADD COLUMN IF NOT EXISTS recevoir_propositions BOOLEAN DEFAULT TRUE;
ALTER TABLE utilisateurs
  ADD COLUMN IF NOT EXISTS preferences_notif JSONB;

SELECT 'Colonnes ajoutées' AS status;
```

## 10.2 Vérifier toutes les routes paramètres

```bash
grep -rn "parametres\|mot-de-passe\|confidentialite" \
  backend/src/routes --include="*.js"
```

Si manquant, ajouter dans `candidat.routes.js` les routes des sections 9 du PRD_CANDIDAT_FIX.md.

## ✅ TEST ÉTAPE 10
```
Tester :
1. Modifier le nom → sauvegardé en BDD
2. Changer mot de passe → fonctionne
3. Toggle "profil visible" → sauvegardé
4. Toggle thème → change instantanément
→ Si OK : dire "Toutes les étapes validées !"
```

---

# RÉSUMÉ — Ce que cursor doit faire

```
Pour CHAQUE étape :
1. Implémenter ce qui est décrit
2. Redémarrer backend (npm run dev)
3. Hot reload Flutter ou flutter run
4. Dire : "Étape X prête, veuillez tester"
5. Attendre confirmation avant de passer à la suivante

Ordre d'exécution :
1. node src/scripts/check_buckets.js → créer les buckets
2. Exécuter toutes les migrations SQL (Supabase SQL Editor)
3. Implémenter routes backend dans l'ordre
4. Connecter les pages Flutter dans l'ordre
5. NE PAS passer à l'étape suivante sans validation
```

---

*PRD EmploiConnect v6.1 — Espace Candidat Étape par Étape*
*Cursor / Kirsoft AI — Phase 10*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
