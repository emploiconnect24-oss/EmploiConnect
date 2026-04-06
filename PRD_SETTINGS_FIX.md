# PRD — EmploiConnect · Corrections & Complétion Paramètres Admin
## Product Requirements Document v3.4 — Settings Fix & Complete
**Stack : Flutter + Node.js/Express + PostgreSQL/Supabase**
**Outil : Cursor / Kirsoft AI**
**Objectif : Corriger et compléter TOUT le module Paramètres Admin**
**Date : Mars 2026**

---

> ### ⚠️ INSTRUCTIONS POUR CURSOR
> Ce PRD corrige et complète le module Paramètres Admin.
> Implémenter dans l'ordre exact des sections.
> Chaque section = une tâche précise.

---

## Table des Matières

1. [Fix Upload Logo & Bannières — Vrais fichiers](#1-fix-upload-logo--bannières--vrais-fichiers)
2. [Fix Section Comptes — Logique Backend](#2-fix-section-comptes--logique-backend)
3. [Fix Section Notifications — Templates Email](#3-fix-section-notifications--templates-email)
4. [Fix Section IA & Matching — APIs RapidAPI](#4-fix-section-ia--matching--apis-rapidapi)
5. [Fix Section Sécurité — Tout opérationnel](#5-fix-section-sécurité--tout-opérationnel)
6. [Fix Section Pied de Page — Espacement + Propagation](#6-fix-section-pied-de-page--espacement--propagation)
7. [Fix Section Maintenance — Bannière globale](#7-fix-section-maintenance--bannière-globale)
8. [Fix Tooltips Informatifs sur tous les paramètres](#8-fix-tooltips-informatifs-sur-tous-les-paramètres)
9. [Critères d'Acceptation](#9-critères-dacceptation)

---

## 1. Fix Upload Logo & Bannières — Vrais fichiers

### 1.1 Problèmes identifiés
```
❌ Logo : affiche un champ URL texte au lieu d'un vrai upload
❌ Bannières : affiche un champ URL texte au lieu d'un vrai upload
❌ Favicon : même problème
❌ Pas de dimensions affichées pour guider l'utilisateur
```

### 1.2 Correction Backend — Vérifier que multer fonctionne

```javascript
// Vérifier dans backend/src/routes/admin/parametres.routes.js
// que multer est bien configuré AVANT la route upload-logo

const multer = require('multer');
const sharp  = require('sharp');

const uploadLogo = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB max
  fileFilter: (req, file, cb) => {
    // Normaliser le mime en minuscules
    const mime = file.mimetype.toLowerCase();
    const allowed = [
      'image/jpeg', 'image/jpg', 'image/png',
      'image/webp', 'image/svg+xml'
    ];
    if (allowed.includes(mime)) {
      cb(null, true);
    } else {
      cb(new Error(
        `Format non supporté: ${file.mimetype}. ` +
        `Acceptés: JPG, PNG, WEBP, SVG`
      ));
    }
  },
});

// Route upload logo
router.post('/upload-logo',
  uploadLogo.single('logo'),
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: 'Aucun fichier fourni'
        });
      }

      const isSvg = req.file.mimetype.toLowerCase() === 'image/svg+xml';
      let buffer   = req.file.buffer;
      let mimeType = 'image/png';
      let ext      = '.png';

      if (!isSvg) {
        // Redimensionner max 400x200px en gardant le ratio
        buffer = await sharp(req.file.buffer)
          .resize(400, 200, {
            fit: 'inside',
            withoutEnlargement: true
          })
          .png({ quality: 90 })
          .toBuffer();
      } else {
        mimeType = 'image/svg+xml';
        ext      = '.svg';
      }

      // Bucket logos dans Supabase Storage
      const bucket   = process.env.SUPABASE_LOGOS_BUCKET || 'logos';
      const fileName = `logo-emploiconnect-${Date.now()}${ext}`;

      const { error: uploadErr } = await supabase.storage
        .from(bucket)
        .upload(fileName, buffer, {
          contentType: mimeType,
          upsert: true,
          cacheControl: '3600',
        });

      if (uploadErr) {
        console.error('[uploadLogo] Supabase error:', uploadErr);
        return res.status(500).json({
          success: false,
          message: `Erreur Supabase Storage: ${uploadErr.message}. ` +
            `Vérifiez que le bucket "logos" existe et est public.`
        });
      }

      const { data: urlData } = supabase.storage
        .from(bucket).getPublicUrl(fileName);
      const logoUrl = urlData.publicUrl;

      // Mettre à jour le paramètre
      await supabase
        .from('parametres_plateforme')
        .update({
          valeur: logoUrl,
          date_modification: new Date().toISOString(),
          modifie_par: req.user.id,
        })
        .eq('cle', 'logo_url');

      return res.json({
        success: true,
        message: 'Logo uploadé et mis à jour avec succès',
        data: { logo_url: logoUrl }
      });

    } catch (err) {
      console.error('[uploadLogo]', err);
      res.status(500).json({
        success: false,
        message: err.message || 'Erreur lors de l\'upload du logo'
      });
    }
  }
);

// Route upload bannière image
const uploadBanniere = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: (req, file, cb) => {
    const mime = file.mimetype.toLowerCase();
    const allowed = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    if (allowed.includes(mime)) cb(null, true);
    else cb(new Error('Format non supporté. Acceptés: JPG, PNG, WEBP'));
  },
});

// Ajouter dans bannieres.routes.js
router.post('/upload-image',
  uploadBanniere.single('image'),
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({
          success: false, message: 'Aucune image fournie'
        });
      }

      // Redimensionner à 1920x1080 max (format bannière)
      const buffer = await sharp(req.file.buffer)
        .resize(1920, 1080, {
          fit: 'cover',
          position: 'centre'
        })
        .jpeg({ quality: 85 })
        .toBuffer();

      const bucket   = process.env.SUPABASE_BANNIERES_BUCKET || 'bannieres';
      const fileName = `banniere-${Date.now()}.jpg`;

      const { error: uploadErr } = await supabase.storage
        .from(bucket)
        .upload(fileName, buffer, {
          contentType: 'image/jpeg',
          upsert: false,
        });

      if (uploadErr) {
        return res.status(500).json({
          success: false,
          message: `Erreur Storage: ${uploadErr.message}`
        });
      }

      const { data: urlData } = supabase.storage
        .from(bucket).getPublicUrl(fileName);

      return res.json({
        success: true,
        message: 'Image uploadée avec succès',
        data: { image_url: urlData.publicUrl }
      });

    } catch (err) {
      console.error('[uploadBanniere]', err);
      res.status(500).json({
        success: false,
        message: err.message || 'Erreur upload image'
      });
    }
  }
);
```

### 1.3 Flutter — Widget Upload Universel

```dart
// lib/shared/widgets/image_upload_widget.dart
// Widget réutilisable pour tous les uploads d'images dans l'admin

class ImageUploadWidget extends StatefulWidget {
  final String? currentImageUrl;
  final String uploadUrl;          // URL de l'API backend
  final String fieldName;          // Nom du champ multipart
  final String title;              // Ex: "Logo principal"
  final String dimensionsInfo;     // Ex: "400×200px recommandé"
  final String acceptedFormats;    // Ex: "PNG, SVG, WEBP"
  final int maxSizeMb;             // Ex: 5
  final double previewHeight;      // Ex: 70 pour logo, 120 pour bannière
  final void Function(String url) onUploaded;

  const ImageUploadWidget({
    super.key,
    this.currentImageUrl,
    required this.uploadUrl,
    required this.fieldName,
    required this.title,
    required this.dimensionsInfo,
    required this.acceptedFormats,
    required this.maxSizeMb,
    required this.previewHeight,
    required this.onUploaded,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  bool _isUploading = false;
  String? _localPreviewUrl; // Aperçu avant upload confirmé

  @override
  Widget build(BuildContext context) {
    final displayUrl = _localPreviewUrl ?? widget.currentImageUrl ?? '';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // ── Aperçu image actuelle ────────────────────────────
      if (displayUrl.isNotEmpty) ...[
        Row(children: [
          Text('Actuel :', style: GoogleFonts.inter(
            fontSize: 12, color: const Color(0xFF64748B))),
          const SizedBox(width: 8),
          if (_localPreviewUrl != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(100)),
              child: Text('Non sauvegardé', style: GoogleFonts.inter(
                fontSize: 10, color: const Color(0xFF92400E))),
            ),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Center(
            child: Image.network(
              displayUrl,
              height: widget.previewHeight,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Column(
                mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.broken_image_outlined,
                  color: Color(0xFF94A3B8), size: 32),
                Text('Impossible de charger l\'image',
                  style: GoogleFonts.inter(
                    fontSize: 11, color: const Color(0xFF94A3B8))),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],

      // ── Zone de drop / clic ──────────────────────────────
      GestureDetector(
        onTap: _isUploading ? null : _pickAndUpload,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: _isUploading
                ? const Color(0xFFEFF6FF)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isUploading
                  ? const Color(0xFF1A56DB)
                  : const Color(0xFF1A56DB).withOpacity(0.35),
            ),
          ),
          child: Column(children: [

            if (_isUploading) ...[
              const SizedBox(
                width: 32, height: 32,
                child: CircularProgressIndicator(
                  color: Color(0xFF1A56DB), strokeWidth: 2.5)),
              const SizedBox(height: 10),
              Text('Upload en cours...',
                style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF1A56DB))),
            ] else ...[
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.upload_file_outlined,
                  color: Color(0xFF1A56DB), size: 24)),
              const SizedBox(height: 10),
              Text(
                displayUrl.isNotEmpty
                    ? 'Cliquer pour remplacer ${widget.title.toLowerCase()}'
                    : 'Cliquer pour choisir ${widget.title.toLowerCase()}',
                style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A56DB))),
              const SizedBox(height: 6),

              // Formats acceptés
              Text(
                '${widget.acceptedFormats} · Max ${widget.maxSizeMb}MB',
                style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF94A3B8))),
              const SizedBox(height: 4),

              // ── DIMENSIONS RECOMMANDÉES ──────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0xFFFDE68A))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.straighten_outlined,
                    size: 12, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 4),
                  Text(
                    'Dimensions recommandées : ${widget.dimensionsInfo}',
                    style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w500,
                      color: const Color(0xFF92400E))),
                ]),
              ),
            ],
          ]),
        ),
      ),
    ]);
  }

  Future<void> _pickAndUpload() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920, maxHeight: 1920,
        imageQuality: 90,
      );
      if (file == null) return;

      // Vérifier la taille
      final bytes   = await file.readAsBytes();
      final sizeMb  = bytes.length / (1024 * 1024);
      if (sizeMb > widget.maxSizeMb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              'Fichier trop volumineux (${sizeMb.toStringAsFixed(1)}MB). '
              'Max: ${widget.maxSizeMb}MB'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ));
        }
        return;
      }

      setState(() => _isUploading = true);

      final token = context.read<AuthProvider>().token ?? '';
      final uri   = Uri.parse(widget.uploadUrl);
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Détecter le type MIME
      final ext  = file.path.split('.').last.toLowerCase();
      String mime = 'image/jpeg';
      if (ext == 'png')  mime = 'image/png';
      if (ext == 'webp') mime = 'image/webp';
      if (ext == 'svg')  mime = 'image/svg+xml';

      request.files.add(http.MultipartFile.fromBytes(
        widget.fieldName, bytes,
        filename: 'upload.$ext',
        contentType: MediaType.parse(mime),
      ));

      final streamed  = await request.send();
      final response  = await http.Response.fromStream(streamed);
      final body      = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        // Extraire l'URL selon la réponse
        final newUrl = (body['data']['logo_url']
          ?? body['data']['image_url']
          ?? '') as String;

        setState(() {
          _localPreviewUrl = newUrl;
          _isUploading = false;
        });

        widget.onUploaded(newUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text('${widget.title} uploadé avec succès !',
                style: GoogleFonts.inter(color: Colors.white)),
            ]),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ));
        }
      } else {
        throw Exception(body['message'] ?? 'Erreur upload');
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }
}
```

### 1.4 Utiliser ImageUploadWidget dans la page Paramètres

```dart
// Dans settings_page.dart — section Logo :
ImageUploadWidget(
  currentImageUrl: general['logo_url']?['valeur']?.toString(),
  uploadUrl: '${ApiConfig.baseUrl}/api/admin/parametres/upload-logo',
  fieldName: 'logo',
  title: 'Logo principal',
  dimensionsInfo: '400 × 200 px (ratio 2:1)',
  acceptedFormats: 'PNG, SVG, WEBP, JPG',
  maxSizeMb: 5,
  previewHeight: 70,
  onUploaded: (url) {
    // Propager le nouveau logo partout dans l'app
    context.read<AppConfigProvider>().updateLogo(url);
    _loadParams();
  },
)

// Pour le favicon :
ImageUploadWidget(
  currentImageUrl: general['favicon_url']?['valeur']?.toString(),
  uploadUrl: '${ApiConfig.baseUrl}/api/admin/parametres/upload-logo',
  fieldName: 'logo',
  title: 'Favicon',
  dimensionsInfo: '32 × 32 px (format carré)',
  acceptedFormats: 'PNG, ICO, SVG',
  maxSizeMb: 1,
  previewHeight: 40,
  onUploaded: (url) => _saveParam('favicon_url', url),
)

// Dans le dialog d'ajout/édition de bannière :
ImageUploadWidget(
  currentImageUrl: banniere?['image_url'],
  uploadUrl: '${ApiConfig.baseUrl}/api/admin/bannieres/upload-image',
  fieldName: 'image',
  title: 'Image de bannière',
  // ── DIMENSIONS IMPORTANTES AFFICHÉES CLAIREMENT ──
  dimensionsInfo: '1920 × 1080 px (16:9) — Full HD',
  acceptedFormats: 'JPG, PNG, WEBP',
  maxSizeMb: 10,
  previewHeight: 120,
  onUploaded: (url) => setState(() => _imageUrl = url),
)
```

### 1.5 Dialog Ajout/Édition Bannière — Complet

```dart
// Dialog pour créer/modifier une bannière
class _BannièreDialog extends StatefulWidget {
  final Map<String, dynamic>? bannière; // null = création
  final void Function(Map<String, dynamic>) onSave;
  const _BannièreDialog({this.bannière, required this.onSave});
  @override
  State<_BannièreDialog> createState() => _BannièreDialogState();
}

class _BannièreDialogState extends State<_BannièreDialog> {
  final _titreCtrl      = TextEditingController();
  final _sousTitreCtrl  = TextEditingController();
  final _badgeCtrl      = TextEditingController();
  final _labelCta1Ctrl  = TextEditingController();
  final _lienCta1Ctrl   = TextEditingController();
  final _labelCta2Ctrl  = TextEditingController();
  final _lienCta2Ctrl   = TextEditingController();
  String? _imageUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.bannière;
    if (b != null) {
      _titreCtrl.text     = b['titre']       ?? '';
      _sousTitreCtrl.text = b['sous_titre']  ?? '';
      _badgeCtrl.text     = b['texte_badge'] ?? '';
      _labelCta1Ctrl.text = b['label_cta_1'] ?? '';
      _lienCta1Ctrl.text  = b['lien_cta_1']  ?? '';
      _labelCta2Ctrl.text = b['label_cta_2'] ?? '';
      _lienCta2Ctrl.text  = b['lien_cta_2']  ?? '';
      _imageUrl           = b['image_url'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 640,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
            child: Row(children: [
              Text(
                widget.bannière == null
                    ? 'Ajouter une bannière'
                    : 'Modifier la bannière',
                style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A))),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const Divider(height: 20),

          // Contenu scrollable
          Flexible(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Upload image
              Text('Image de fond *', style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w500,
                color: const Color(0xFF374151))),
              const SizedBox(height: 8),
              ImageUploadWidget(
                currentImageUrl: _imageUrl,
                uploadUrl:
                  '${ApiConfig.baseUrl}/api/admin/bannieres/upload-image',
                fieldName: 'image',
                title: 'Image de bannière',
                dimensionsInfo: '1920 × 1080 px (16:9) — Format Full HD',
                acceptedFormats: 'JPG, PNG, WEBP',
                maxSizeMb: 10,
                previewHeight: 120,
                onUploaded: (url) => setState(() => _imageUrl = url),
              ),
              const SizedBox(height: 16),

              // Texte Badge
              _dialogLabel('Badge (ex: 🇬🇳 Plateforme N°1 en Guinée)'),
              const SizedBox(height: 6),
              _dialogField(_badgeCtrl, 'Texte du badge au-dessus du titre'),
              const SizedBox(height: 14),

              // Titre
              _dialogLabel('Titre principal *'),
              const SizedBox(height: 6),
              _dialogField(_titreCtrl, 'Ex: Trouvez l\'Emploi de Vos Rêves'),
              const SizedBox(height: 14),

              // Sous-titre
              _dialogLabel('Sous-titre'),
              const SizedBox(height: 6),
              _dialogField(_sousTitreCtrl,
                'Description courte affichée sous le titre',
                maxLines: 2),
              const SizedBox(height: 14),

              // CTA 1
              Text('Bouton principal (CTA 1)',
                style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A))),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _dialogLabel('Label du bouton'),
                  const SizedBox(height: 4),
                  _dialogField(_labelCta1Ctrl, 'Ex: Trouver un Emploi'),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _dialogLabel('Lien (route)'),
                  const SizedBox(height: 4),
                  _dialogField(_lienCta1Ctrl, 'Ex: /offres'),
                ])),
              ]),
              const SizedBox(height: 14),

              // CTA 2
              Text('Bouton secondaire (CTA 2)',
                style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A))),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _dialogLabel('Label du bouton'),
                  const SizedBox(height: 4),
                  _dialogField(_labelCta2Ctrl, 'Ex: Recruter des Talents'),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _dialogLabel('Lien (route)'),
                  const SizedBox(height: 4),
                  _dialogField(_lienCta2Ctrl,
                    'Ex: /inscription-entreprise'),
                ])),
              ]),
            ]),
          )),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Row(children: [
              Expanded(child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler', style: GoogleFonts.inter(
                  color: const Color(0xFF64748B))),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56DB),
                  foregroundColor: Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
                onPressed: (_isSaving || _imageUrl == null)
                    ? null
                    : () {
                        Navigator.pop(context);
                        widget.onSave({
                          'image_url':   _imageUrl,
                          'texte_badge': _badgeCtrl.text.trim(),
                          'titre':       _titreCtrl.text.trim(),
                          'sous_titre':  _sousTitreCtrl.text.trim(),
                          'label_cta_1': _labelCta1Ctrl.text.trim(),
                          'lien_cta_1':  _lienCta1Ctrl.text.trim(),
                          'label_cta_2': _labelCta2Ctrl.text.trim(),
                          'lien_cta_2':  _lienCta2Ctrl.text.trim(),
                        });
                      },
                child: Text(
                  widget.bannière == null
                      ? 'Créer la bannière'
                      : 'Sauvegarder',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              )),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _dialogLabel(String text) => Text(text,
    style: GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w500,
      color: const Color(0xFF374151)));

  Widget _dialogField(TextEditingController ctrl, String hint,
      {int maxLines = 1}) =>
    TextFormField(
      controller: ctrl, maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 13, color: const Color(0xFFCBD5E1)),
        filled: true, fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFF1A56DB), width: 1.5)),
      ),
    );
}
```

---

## 2. Fix Section Comptes — Logique Backend

### 2.1 Ce que ça fait réellement (explication)

```
inscription_libre = true
→ N'importe qui peut créer un compte sans invitation

validation_manuelle_comptes = true
→ Quand un utilisateur s'inscrit, est_valide = FALSE
→ L'admin doit manuellement valider via PATCH /api/admin/utilisateurs/:id
→ Notification admin reçue automatiquement

validation_manuelle_comptes = false (défaut)
→ Compte validé automatiquement à l'inscription (est_valide = TRUE)

max_offres_gratuit = 5
→ Une entreprise gratuite peut avoir MAX 5 offres actives simultanément
→ Au-delà, elle doit passer à un plan payant (ou l'admin augmente la limite)

duree_validite_offre_jours = 30
→ Quand une offre est publiée, sa date_limite = date_publication + 30 jours
→ Après 30 jours, statut passe automatiquement à 'expiree'
```

### 2.2 Appliquer la logique dans le backend Auth

```javascript
// Dans backend/src/controllers/auth.controller.js (ou routes/auth.routes.js)
// À la fin de la route POST /api/auth/register, APRÈS la création du compte :

// Lire le paramètre validation_manuelle
const { data: paramValidation } = await supabase
  .from('parametres_plateforme')
  .select('valeur')
  .eq('cle', 'validation_manuelle_comptes')
  .single();

const validationManuelle = paramValidation?.valeur === 'true';

// Si validation manuelle OFF → valider automatiquement
if (!validationManuelle) {
  await supabase
    .from('utilisateurs')
    .update({ est_valide: true, est_actif: true })
    .eq('id', nouvelUtilisateur.id);
}
// Si validation manuelle ON → est_valide reste FALSE (défaut)
// → Notifier les admins
else {
  const { notifNouvelleInscription } =
    require('../services/auto_notification.service');
  await notifNouvelleInscription(nouvelUtilisateur);
}
```

### 2.3 Vérifier max_offres_gratuit lors de la publication

```javascript
// Dans backend/src/controllers/offres.controller.js
// Avant de créer une nouvelle offre, vérifier la limite :

const postOffre = async (req, res) => {
  // ... validation ...

  // Récupérer la limite depuis les paramètres
  const { data: paramLimite } = await supabase
    .from('parametres_plateforme')
    .select('valeur')
    .eq('cle', 'max_offres_gratuit')
    .single();

  const limite = parseInt(paramLimite?.valeur || '5');

  // Compter les offres actives de cette entreprise
  const { count: nbOffresActives } = await supabase
    .from('offres_emploi')
    .select('id', { count: 'exact' })
    .eq('entreprise_id', entrepriseId)
    .eq('statut', 'publiee');

  if (nbOffresActives >= limite) {
    return res.status(403).json({
      success: false,
      message: `Limite atteinte. Votre plan gratuit permet ${limite} offres actives simultanément.`
    });
  }

  // ... créer l'offre normalement ...
};
```

---

## 3. Fix Section Notifications — Templates Email

### 3.1 Explication honnête

```
⚠️ IMPORTANT : L'envoi d'emails réels nécessite un service email externe
(SendGrid, Mailgun, Nodemailer+SMTP, etc.).
Ces services ne sont PAS encore configurés dans ce projet.

Ce qu'on peut faire MAINTENANT sans service email :
✅ Stocker les templates dans la BDD (paramètres)
✅ Afficher un éditeur de template dans l'admin
✅ Préparer le code d'envoi pour quand un service email sera ajouté
✅ Utiliser les notifications IN-APP (déjà fonctionnelles)

Ce qu'on va configurer PLUS TARD :
→ Connecter Nodemailer ou SendGrid
→ Les templates seront automatiquement utilisés
```

### 3.2 Migration — Ajouter les templates email dans les paramètres

```sql
-- Ajouter dans database/migrations/009_add_email_templates.sql

INSERT INTO parametres_plateforme
  (cle, valeur, type_valeur, description, categorie)
VALUES
  ('email_service_actif',
   'false', 'boolean',
   'Activer l''envoi d''emails (nécessite SMTP configuré)', 'notifications'),
  ('email_smtp_host',
   '', 'string',
   'Hôte SMTP (ex: smtp.gmail.com)', 'notifications'),
  ('email_smtp_port',
   '587', 'integer',
   'Port SMTP', 'notifications'),
  ('email_smtp_user',
   '', 'string',
   'Email expéditeur SMTP', 'notifications'),
  ('email_smtp_password',
   '', 'string',
   'Mot de passe SMTP (chiffré)', 'notifications'),
  ('email_nom_expediteur',
   'EmploiConnect', 'string',
   'Nom de l''expéditeur affiché', 'notifications'),
  ('template_bienvenue_sujet',
   'Bienvenue sur EmploiConnect ! 🎉', 'string',
   'Sujet de l''email de bienvenue', 'notifications'),
  ('template_bienvenue_corps',
   'Bonjour {{nom}},\n\nBienvenue sur EmploiConnect !\n\nVotre compte a été créé avec succès.\nCommencez dès maintenant à explorer les offres d''emploi.\n\nBonne chance !\nL''équipe EmploiConnect',
   'string',
   'Corps de l''email de bienvenue ({{nom}} = nom du user)', 'notifications'),
  ('template_candidature_sujet',
   'Nouvelle candidature reçue pour "{{poste}}"', 'string',
   'Sujet email notification candidature', 'notifications'),
  ('template_validation_sujet',
   'Votre compte EmploiConnect a été validé ✅', 'string',
   'Sujet email validation compte', 'notifications')
ON CONFLICT (cle) DO NOTHING;
```

### 3.3 Flutter — Section Notifications avec éditeur template

```dart
Widget _buildNotifications() {
  final notifs = _params['notifications'] ?? {};

  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

    _SectionHeader(
      icon: Icons.notifications_outlined,
      title: 'Notifications & Emails',
      subtitle: 'Configurez les notifications et templates d\'email.',
    ),
    const SizedBox(height: 24),

    // ── Card Toggles Notifications ──────────────────────
    _SettingsCard(title: '🔔 Préférences de notifications', children: [
      _toggleParam('notif_email_candidature',
        'Email à chaque candidature',
        'Envoyer un email au recruteur quand il reçoit une candidature',
        notifs),
      const Divider(height: 20),
      _toggleParam('notif_email_validation',
        'Email de validation de compte',
        'Envoyer un email quand un compte est validé par l\'admin',
        notifs),
      const Divider(height: 20),
      _toggleParam('notif_resume_hebdo',
        'Résumé hebdomadaire',
        'Envoyer un résumé hebdo aux candidats et recruteurs actifs',
        notifs),
    ]),
    const SizedBox(height: 16),

    // ── Card Service Email ───────────────────────────────
    _SettingsCard(title: '📧 Service d\'envoi d\'email (SMTP)', children: [

      // Alerte si pas configuré
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFDE68A))),
        child: Row(children: [
          const Icon(Icons.warning_amber_outlined,
            color: Color(0xFFF59E0B), size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(
            'Pour envoyer de vrais emails, configurez votre serveur SMTP '
            '(Gmail, SendGrid, etc.) et activez le service.',
            style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFF92400E)))),
        ]),
      ),
      const SizedBox(height: 14),

      // Toggle service email
      Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Activer l\'envoi d\'emails',
            style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w500,
              color: const Color(0xFF0F172A))),
          Text('Nécessite une configuration SMTP valide',
            style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFF64748B))),
        ])),
        Switch(
          value: notifs['email_service_actif']?['valeur'] == true,
          onChanged: (v) => _saveParam('email_service_actif', v),
          activeColor: const Color(0xFF1A56DB),
        ),
      ]),
      const SizedBox(height: 14),

      // Champs SMTP
      _label('Hôte SMTP'),
      const SizedBox(height: 6),
      _inputField(
        TextEditingController(
          text: notifs['email_smtp_host']?['valeur'] ?? ''),
        'ex: smtp.gmail.com', Icons.dns_outlined),
      const SizedBox(height: 14),

      _label('Email expéditeur'),
      const SizedBox(height: 6),
      _inputField(
        TextEditingController(
          text: notifs['email_smtp_user']?['valeur'] ?? ''),
        'votre@email.com', Icons.email_outlined),
      const SizedBox(height: 14),

      _label('Mot de passe SMTP'),
      const SizedBox(height: 6),
      _secretField(
        TextEditingController(
          text: notifs['email_smtp_password']?['valeur'] ?? ''),
        'Mot de passe d\'application'),
    ]),
    const SizedBox(height: 16),

    // ── Card Template Bienvenue ──────────────────────────
    _SettingsCard(
      title: '✉️ Template email de bienvenue',
      children: [
      Text(
        'Variables disponibles : {{nom}}, {{email}}, {{role}}',
        style: GoogleFonts.inter(
          fontSize: 12, color: const Color(0xFF64748B))),
      const SizedBox(height: 12),
      _label('Sujet'),
      const SizedBox(height: 6),
      _inputField(
        TextEditingController(
          text: notifs['template_bienvenue_sujet']?['valeur'] ?? ''),
        'Sujet de l\'email', Icons.subject_outlined),
      const SizedBox(height: 14),
      _label('Corps du message'),
      const SizedBox(height: 6),
      TextFormField(
        controller: TextEditingController(
          text: notifs['template_bienvenue_corps']?['valeur'] ?? ''),
        maxLines: 8,
        decoration: InputDecoration(
          hintText: 'Corps de l\'email...',
          filled: true, fillColor: const Color(0xFFF8FAFC),
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
      ),
    ]),
  ]);
}
```

---

## 4. Fix Section IA & Matching — APIs RapidAPI Précises

### 4.1 Les 3 APIs à utiliser (déjà identifiées)

```
Sur RapidAPI (rapidapi.com), s'abonner à ces 3 APIs :

API 1 — Parser de CV (extraction compétences, expérience)
  Nom     : "Resume Parser"
  Host    : resume-parser3.p.rapidapi.com
  Usage   : Analyser le texte du CV uploadé
  Endpoint: POST /resume/parse

API 2 — Similarité de texte (matching offre ↔ profil)
  Nom     : "Twinword Text Similarity"
  Host    : twinword-text-similarity-v1.p.rapidapi.com
  Usage   : Calculer le score de matching (0-1)
  Endpoint: GET /similarity/?text1=...&text2=...

API 3 — Extraction de mots-clés (pour les offres)
  Nom     : "Twinword Topic Tagging"
  Host    : twinword-topic-tagging1.p.rapidapi.com
  Usage   : Extraire les compétences requises d'une offre
  Endpoint: GET /classify/?text=...

UNE SEULE CLÉ RAPIDAPI pour les 3 APIs.
```

### 4.2 Flutter — Section IA avec les bonnes APIs

```dart
Widget _buildIAMatching() {
  final ia = _params['ia_matching'] ?? {};
  bool testLoading = false;
  String? testResult;

  final rapidApiKeyCtrl = TextEditingController(
    text: ia['rapidapi_key']?['valeur']?.toString() ?? '');
  final seuil = (ia['seuil_matching_minimum']?['valeur'] as num?)
      ?.toDouble() ?? 40.0;

  return StatefulBuilder(builder: (ctx, setS) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [

    _SectionHeader(
      icon: Icons.psychology_outlined,
      title: 'IA & Matching Automatique',
      subtitle: 'Configurez les APIs pour l\'analyse automatique des CV '
          'et le calcul de compatibilité candidat/offre.',
    ),
    const SizedBox(height: 24),

    // ── Guide étape par étape ────────────────────────────
    _SettingsCard(title: '📋 Guide de configuration (3 étapes)', children: [
      _StepGuide(
        step: 1,
        title: 'Créer un compte sur RapidAPI',
        description: 'Aller sur rapidapi.com et créer un compte gratuit',
        actionLabel: 'Ouvrir RapidAPI',
        onAction: () => launchUrl(Uri.parse('https://rapidapi.com')),
      ),
      const SizedBox(height: 12),
      _StepGuide(
        step: 2,
        title: 'S\'abonner aux 3 APIs',
        description: 'Rechercher et s\'abonner (plan gratuit disponible) à :\n'
            '• Resume Parser (resume-parser3.p.rapidapi.com)\n'
            '• Twinword Text Similarity\n'
            '• Twinword Topic Tagging',
        actionLabel: null,
        onAction: null,
      ),
      const SizedBox(height: 12),
      _StepGuide(
        step: 3,
        title: 'Copier votre clé API',
        description: 'Dans votre profil RapidAPI → Apps → Default Application '
            '→ copier "X-RapidAPI-Key"',
        actionLabel: null,
        onAction: null,
      ),
    ]),
    const SizedBox(height: 16),

    // ── Clé API principale ───────────────────────────────
    _SettingsCard(title: '🔑 Votre clé RapidAPI', children: [
      _label('Clé API (X-RapidAPI-Key)'),
      const SizedBox(height: 8),
      _secretField(rapidApiKeyCtrl, 'Coller votre clé RapidAPI ici'),
      const SizedBox(height: 16),

      Row(children: [
        Expanded(child: ElevatedButton.icon(
          icon: const Icon(Icons.save_outlined, size: 16),
          label: const Text('Sauvegarder la clé'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
            textStyle: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600),
          ),
          onPressed: () => _saveParam(
            'rapidapi_key', rapidApiKeyCtrl.text),
        )),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          icon: testLoading
              ? const SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.wifi_tethering_outlined, size: 16),
          label: Text(testLoading ? 'Test...' : 'Tester'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF10B981),
            side: const BorderSide(color: Color(0xFF10B981)),
            padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
            textStyle: GoogleFonts.inter(fontSize: 14),
          ),
          onPressed: testLoading ? null : () async {
            setS(() => testLoading = true);
            try {
              final token = ctx.read<AuthProvider>().token ?? '';
              final res = await AdminService().testerConnexionIA(token);
              setS(() {
                testResult = res['success'] == true
                    ? '✅ Connexion réussie !'
                    : '❌ ${res['message']}';
                testLoading = false;
              });
            } catch (e) {
              setS(() {
                testResult = '❌ Erreur: $e';
                testLoading = false;
              });
            }
          },
        ),
      ]),

      if (testResult != null) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: testResult!.startsWith('✅')
                ? const Color(0xFFD1FAE5)
                : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(8)),
          child: Text(testResult!, style: GoogleFonts.inter(
            fontSize: 13,
            color: testResult!.startsWith('✅')
                ? const Color(0xFF065F46)
                : const Color(0xFF991B1B),
            fontWeight: FontWeight.w500)),
        ),
      ],
    ]),
    const SizedBox(height: 16),

    // ── Paramètres matching ──────────────────────────────
    _SettingsCard(title: '⚙️ Paramètres du Matching', children: [
      _toggleParam('suggestions_automatiques',
        'Suggestions automatiques',
        'Activer les recommandations IA dans le dashboard candidat',
        ia),
      const Divider(height: 24),

      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _labelWithTooltip(
          'Seuil minimum de matching (%)',
          'Les offres avec un score IA inférieur à ce seuil '
          'ne seront pas suggérées aux candidats.',
        ),
        Text('${seuil.toInt()}%', style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: const Color(0xFF1A56DB))),
      ]),
      const SizedBox(height: 8),
      SliderTheme(
        data: SliderTheme.of(ctx).copyWith(
          activeTrackColor: const Color(0xFF1A56DB),
          thumbColor: const Color(0xFF1A56DB),
          overlayColor: const Color(0xFF1A56DB).withOpacity(0.12),
          inactiveTrackColor: const Color(0xFFE2E8F0),
        ),
        child: Slider(
          value: seuil,
          min: 10, max: 90, divisions: 80,
          label: '${seuil.toInt()}%',
          onChanged: (v) => setS(() {}),
          onChangeEnd: (v) => _saveParam(
            'seuil_matching_minimum', v.toInt()),
        ),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('10% (large)', style: GoogleFonts.inter(
          fontSize: 11, color: const Color(0xFF94A3B8))),
        Text('90% (strict)', style: GoogleFonts.inter(
          fontSize: 11, color: const Color(0xFF94A3B8))),
      ]),
    ]),
  ]));
}
```

---

## 5. Fix Section Sécurité — Tout opérationnel

### 5.1 Explication de chaque option

```
duree_session_minutes = 1440 (24h)
→ Le token JWT expire après cette durée
→ L'utilisateur doit se reconnecter
→ OPÉRATIONNEL via JWT_EXPIRES_IN dans .env

max_tentatives_connexion = 5
→ Après 5 échecs, le compte est temporairement bloqué
→ OPÉRATIONNEL via rate limiting sur /api/auth/login

jwt_expiration_heures = 24
→ Durée de vie du token JWT (cohérent avec duree_session_minutes)
→ OPÉRATIONNEL — lu depuis les paramètres lors de la création du token

twofa_admin_actif = false
→ Si activé, les admins doivent entrer un code TOTP (Google Authenticator)
→ ⚠️ PARTIELLEMENT opérationnel — backend à finaliser

ips_bloquees = []
→ Liste d'IPs qui ne peuvent pas accéder à l'API
→ Vérifiée dans le middleware de chaque requête
→ OPÉRATIONNEL si le middleware est ajouté
```

### 5.2 Backend — Appliquer les paramètres de sécurité

```javascript
// Dans backend/src/middleware/security.middleware.js
// Créer ce middleware pour appliquer les paramètres de sécurité

const { supabase } = require('../config/supabase');

// Cache local des paramètres (rafraîchi toutes les 5 minutes)
let securityParamsCache = null;
let cacheTimestamp = 0;

const getSecurityParams = async () => {
  const now = Date.now();
  if (securityParamsCache && (now - cacheTimestamp) < 5 * 60 * 1000) {
    return securityParamsCache;
  }

  const { data } = await supabase
    .from('parametres_plateforme')
    .select('cle, valeur')
    .eq('categorie', 'securite');

  const params = {};
  (data || []).forEach(p => { params[p.cle] = p.valeur; });

  securityParamsCache = params;
  cacheTimestamp = now;
  return params;
};

// Middleware vérification IP bloquée
const checkBlockedIP = async (req, res, next) => {
  try {
    const params = await getSecurityParams();
    const ipsBloquees = JSON.parse(params['ips_bloquees'] || '[]');

    const clientIP = req.ip ||
      req.connection.remoteAddress ||
      req.headers['x-forwarded-for'];

    if (ipsBloquees.some(ip => clientIP?.includes(ip))) {
      return res.status(403).json({
        success: false,
        message: 'Accès refusé depuis cette adresse IP'
      });
    }
    next();
  } catch (err) {
    next(); // Ne pas bloquer en cas d'erreur
  }
};

module.exports = { checkBlockedIP, getSecurityParams };
```

### 5.3 Appliquer le middleware dans `backend/src/index.js`

```javascript
// Ajouter après les autres middlewares
const { checkBlockedIP } = require('./middleware/security.middleware');
app.use('/api', checkBlockedIP);
```

### 5.4 Flutter — Section Sécurité avec explication claire

```dart
Widget _buildSecurite() {
  final sec = _params['securite'] ?? {};
  final ipsController = TextEditingController(
    text: ((sec['ips_bloquees']?['valeur']) is List
        ? (sec['ips_bloquees']['valeur'] as List).join('\n')
        : ''));

  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

    _SectionHeader(
      icon: Icons.security_outlined,
      title: 'Sécurité',
      subtitle: 'Paramètres de sécurité de la plateforme.',
    ),
    const SizedBox(height: 24),

    // Sessions & Auth
    _SettingsCard(title: '🔐 Sessions & Authentification', children: [

      _labelWithTooltip('Durée de session (minutes)',
        'Après cette durée d\'inactivité, l\'utilisateur doit se reconnecter. '
        '1440 = 24 heures. 10080 = 7 jours.'),
      const SizedBox(height: 8),
      _sliderParam('duree_session_minutes', sec,
        min: 30, max: 10080, label: 'min', divisions: 100),
      const Divider(height: 24),

      _labelWithTooltip('Tentatives max avant blocage temporaire',
        'Après N échecs de connexion consécutifs, l\'adresse IP est '
        'temporairement bloquée pendant 15 minutes.'),
      const SizedBox(height: 8),
      _sliderParam('max_tentatives_connexion', sec,
        min: 3, max: 20, label: 'tentatives', divisions: 17),
      const Divider(height: 24),

      _labelWithTooltip('Expiration du token JWT (heures)',
        'Durée de validité du token d\'authentification. '
        'Après cette durée, l\'utilisateur doit se reconnecter.'),
      const SizedBox(height: 8),
      _sliderParam('jwt_expiration_heures', sec,
        min: 1, max: 168, label: 'h', divisions: 167),
    ]),
    const SizedBox(height: 16),

    // 2FA
    _SettingsCard(title: '🛡️ Double Authentification (2FA)', children: [
      Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Activer 2FA pour les administrateurs',
              style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w500,
                color: const Color(0xFF0F172A))),
            const SizedBox(width: 6),
            _InfoTooltip(
              'Les admins devront scanner un QR code avec Google '
              'Authenticator et entrer un code à 6 chiffres à '
              'chaque connexion.'),
          ]),
          Text('Sécurité renforcée pour les comptes admin',
            style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFF64748B))),
        ])),
        Switch(
          value: sec['twofa_admin_actif']?['valeur'] == true,
          onChanged: (v) => _saveParam('twofa_admin_actif', v),
          activeColor: const Color(0xFF1A56DB)),
      ]),
    ]),
    const SizedBox(height: 16),

    // IPs bloquées
    _SettingsCard(title: '🚫 Adresses IP bloquées', children: [
      Row(children: [
        Text('IPs bloquées',
          style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w500,
            color: const Color(0xFF0F172A))),
        const SizedBox(width: 6),
        _InfoTooltip(
          'Saisissez une adresse IP par ligne. '
          'Ces adresses ne pourront plus accéder à l\'API. '
          'Utile pour bloquer les robots ou les attaques.'),
      ]),
      const SizedBox(height: 8),
      TextFormField(
        controller: ipsController,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: '192.168.1.100\n10.0.0.1\n...',
          hintStyle: GoogleFonts.inter(
            fontSize: 13, color: const Color(0xFFCBD5E1)),
          filled: true, fillColor: const Color(0xFFF8FAFC),
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
      ),
      const SizedBox(height: 12),
      ElevatedButton.icon(
        icon: const Icon(Icons.save_outlined, size: 16),
        label: const Text('Sauvegarder'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A56DB),
          foregroundColor: Colors.white, elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600),
        ),
        onPressed: () {
          final ips = ipsController.text
              .split('\n')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          _saveParam('ips_bloquees', ips);
        },
      ),
    ]),
  ]);
}
```

---

## 6. Fix Section Pied de Page — Espacement + Propagation

```dart
// Remplacer _buildFooter() par cette version bien espacée

Widget _buildFooter() {
  final footer = _params['footer'] ?? {};
  bool isSaving = false;

  // Contrôleurs
  final ctrls = <String, TextEditingController>{
    'footer_linkedin':  TextEditingController(text: _val(footer, 'footer_linkedin')),
    'footer_facebook':  TextEditingController(text: _val(footer, 'footer_facebook')),
    'footer_twitter':   TextEditingController(text: _val(footer, 'footer_twitter')),
    'footer_instagram': TextEditingController(text: _val(footer, 'footer_instagram')),
    'footer_whatsapp':  TextEditingController(text: _val(footer, 'footer_whatsapp')),
    'footer_email':     TextEditingController(text: _val(footer, 'footer_email')),
    'footer_telephone': TextEditingController(text: _val(footer, 'footer_telephone')),
    'footer_adresse':   TextEditingController(text: _val(footer, 'footer_adresse')),
    'footer_tagline':   TextEditingController(text: _val(footer, 'footer_tagline')),
  };

  return StatefulBuilder(builder: (ctx, setS) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [

    _SectionHeader(
      icon: Icons.language_outlined,
      title: 'Pied de page & Réseaux Sociaux',
      subtitle: 'Ces informations s\'affichent dans le footer '
          'de la page d\'accueil.',
    ),
    const SizedBox(height: 24),

    // ── Réseaux sociaux ──────────────────────────────────
    _SettingsCard(title: '📱 Réseaux Sociaux', children: [
      _footerField(ctrls['footer_linkedin']!, 'LinkedIn',
        'https://linkedin.com/company/emploiconnect',
        Icons.link_outlined, 'URL de votre page LinkedIn'),
      _footerField(ctrls['footer_facebook']!, 'Facebook',
        'https://facebook.com/emploiconnect',
        Icons.link_outlined, 'URL de votre page Facebook'),
      _footerField(ctrls['footer_twitter']!, 'Twitter / X',
        'https://twitter.com/emploiconnect',
        Icons.link_outlined, 'URL de votre compte Twitter/X'),
      _footerField(ctrls['footer_instagram']!, 'Instagram',
        'https://instagram.com/emploiconnect',
        Icons.link_outlined, 'URL de votre compte Instagram'),
      _footerField(ctrls['footer_whatsapp']!, 'WhatsApp Business',
        '+224 620 00 00 00',
        Icons.chat_outlined, 'Numéro WhatsApp Business'),
    ]),
    const SizedBox(height: 16),

    // ── Informations de contact ──────────────────────────
    _SettingsCard(title: '📞 Contact public', children: [
      _footerField(ctrls['footer_email']!, 'Email',
        'contact@emploiconnect.gn',
        Icons.email_outlined, 'Email affiché dans le footer'),
      _footerField(ctrls['footer_telephone']!, 'Téléphone',
        '+224 620 00 00 00',
        Icons.phone_outlined, 'Téléphone affiché dans le footer'),
      _footerField(ctrls['footer_adresse']!, 'Adresse',
        'Conakry, République de Guinée',
        Icons.location_on_outlined, 'Adresse affichée dans le footer'),
      _footerField(ctrls['footer_tagline']!, 'Tagline',
        'La plateforme intelligente de l\'emploi en Guinée',
        Icons.short_text_outlined,
        'Texte accrocheur sous le logo dans le footer'),
    ]),
    const SizedBox(height: 20),

    // ── Bouton sauvegarder ───────────────────────────────
    SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: isSaving
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.save_outlined, size: 18),
        label: Text(isSaving ? 'Sauvegarde...' : 'Sauvegarder le pied de page',
          style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A56DB),
          foregroundColor: Colors.white, elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: isSaving ? null : () async {
          setS(() => isSaving = true);
          final data = {
            for (final e in ctrls.entries)
              e.key: e.value.text.trim()
          };
          await _saveMultipleParams(data);

          // Propager immédiatement dans l'app
          ctx.read<AppConfigProvider>().updateFooter(
            data.map((k, v) => MapEntry(k, v)));

          setS(() => isSaving = false);
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
              content: Text('Pied de page mis à jour !'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
      ),
    ),
  ]));
}

// Helper pour créer un champ footer avec espacement correct
Widget _footerField(
  TextEditingController ctrl, String label, String hint,
  IconData icon, String tooltip,
) => Padding(
  padding: const EdgeInsets.only(bottom: 16), // ← Espacement entre champs
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Text(label, style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w500,
        color: const Color(0xFF374151))),
      const SizedBox(width: 4),
      _InfoTooltip(tooltip), // ← Tooltip info
    ]),
    const SizedBox(height: 6),
    TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 13, color: const Color(0xFFCBD5E1)),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
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
      ),
    ),
  ]),
);

String _val(Map<String, dynamic> section, String key) =>
  section[key]?['valeur']?.toString() ?? '';
```

---

## 7. Fix Section Maintenance — Bannière Globale

### 7.1 Backend — Middleware Maintenance

```javascript
// Dans backend/src/middleware/maintenance.middleware.js

const { supabase } = require('../config/supabase');
let maintenanceCache = null;
let maintenanceCacheTime = 0;

const checkMaintenance = async (req, res, next) => {
  // Ne pas bloquer les routes admin ni health
  if (req.path.startsWith('/api/admin') ||
      req.path === '/api/health' ||
      req.path.startsWith('/api/auth')) {
    return next();
  }

  try {
    const now = Date.now();
    // Cache 60 secondes
    if (!maintenanceCache ||
        (now - maintenanceCacheTime) > 60 * 1000) {
      const { data } = await supabase
        .from('parametres_plateforme')
        .select('cle, valeur')
        .in('cle', ['mode_maintenance', 'message_maintenance']);

      maintenanceCache = {};
      (data || []).forEach(p => {
        maintenanceCache[p.cle] = p.valeur;
      });
      maintenanceCacheTime = now;
    }

    if (maintenanceCache['mode_maintenance'] === 'true') {
      return res.status(503).json({
        success: false,
        maintenance: true,
        message: maintenanceCache['message_maintenance'] ||
          'La plateforme est en cours de maintenance. Revenez bientôt.',
      });
    }

    next();
  } catch (err) {
    next(); // En cas d'erreur DB, ne pas bloquer
  }
};

module.exports = { checkMaintenance };
```

### 7.2 Ajouter le middleware dans `backend/src/index.js`

```javascript
const { checkMaintenance } = require('./middleware/maintenance.middleware');
// Ajouter après les autres middlewares, avant les routes
app.use(checkMaintenance);
```

### 7.3 Flutter — Bannière de maintenance sur toute l'app

```dart
// Dans main.dart ou app.dart — Ajouter une bannière globale

class EmploiConnectApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // ...
      builder: (context, child) {
        // Bannière maintenance au-dessus de toute l'app
        return Consumer<AppConfigProvider>(
          builder: (ctx, config, _) {
            if (!config.modeMaintenanceActif) return child ?? const SizedBox();
            return Column(children: [
              // Bannière rouge en haut
              Material(
                color: const Color(0xFFEF4444),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                  child: Row(children: [
                    const Icon(Icons.construction_outlined,
                      color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      config.messageMaintenanceText.isNotEmpty
                          ? config.messageMaintenanceText
                          : '🔧 La plateforme est en cours de maintenance.',
                      style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.white,
                        fontWeight: FontWeight.w500),
                    )),
                    // Badge MAINTENANCE
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(100)),
                      child: Text('MAINTENANCE', style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                    ),
                  ]),
                ),
              ),
              Expanded(child: child ?? const SizedBox()),
            ]);
          },
        );
      },
    );
  }
}

// Dans AppConfigProvider, ajouter :
bool modeMaintenanceActif  = false;
String messageMaintenanceText = '';

// Dans loadConfig(), lire aussi ces paramètres :
final { data: maintenanceParams } = await supabase
  .from('parametres_plateforme')
  .select('cle, valeur')
  .in('cle', ['mode_maintenance', 'message_maintenance']);

(maintenanceParams || []).forEach(p => {
  if (p.cle === 'mode_maintenance')
    modeMaintenanceActif = p.valeur === 'true';
  if (p.cle === 'message_maintenance')
    messageMaintenanceText = p.valeur ?? '';
});
```

### 7.4 Flutter — Section Maintenance

```dart
Widget _buildMaintenance() {
  final maint = _params['maintenance'] ?? {};
  final msgCtrl = TextEditingController(
    text: maint['message_maintenance']?['valeur'] ?? '');
  bool estActif = maint['mode_maintenance']?['valeur'] == true;

  return StatefulBuilder(builder: (ctx, setS) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [

    _SectionHeader(
      icon: Icons.build_outlined,
      title: 'Mode Maintenance',
      subtitle: 'Activez le mode maintenance pour afficher '
          'un message à tous les visiteurs.',
    ),
    const SizedBox(height: 24),

    _SettingsCard(title: '🔧 Mode Maintenance', children: [

      // Toggle avec alerte si actif
      Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Activer le mode maintenance',
            style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w500,
              color: const Color(0xFF0F172A))),
          Text(
            'Une bannière rouge s\'affiche sur toute la plateforme. '
            'Les APIs publiques retournent une erreur 503.',
            style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFF64748B))),
        ])),
        Switch(
          value: estActif,
          onChanged: (v) async {
            setS(() => estActif = v);
            await _saveParam('mode_maintenance', v);
            // Mettre à jour le Provider global
            ctx.read<AppConfigProvider>()
               .updateMaintenance(v, msgCtrl.text);
          },
          activeColor: const Color(0xFFEF4444), // Rouge pour danger
        ),
      ]),

      // Alerte si actif
      if (estActif) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFCA5A5))),
          child: Row(children: [
            const Icon(Icons.warning_rounded,
              color: Color(0xFFEF4444), size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(
              '⚠️ Mode maintenance ACTIF. '
              'Tous les visiteurs voient le message ci-dessous.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF991B1B),
                fontWeight: FontWeight.w500))),
          ]),
        ),
      ],
      const SizedBox(height: 16),

      _label('Message affiché aux utilisateurs'),
      const SizedBox(height: 8),
      TextFormField(
        controller: msgCtrl,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'La plateforme est en cours de maintenance. '
              'Revenez bientôt.',
          hintStyle: GoogleFonts.inter(
            fontSize: 13, color: const Color(0xFFCBD5E1)),
          filled: true, fillColor: const Color(0xFFF8FAFC),
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
      ),
      const SizedBox(height: 14),

      ElevatedButton.icon(
        icon: const Icon(Icons.save_outlined, size: 16),
        label: const Text('Sauvegarder le message'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A56DB),
          foregroundColor: Colors.white, elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600),
        ),
        onPressed: () async {
          await _saveParam(
            'message_maintenance', msgCtrl.text.trim());
          ctx.read<AppConfigProvider>()
             .updateMaintenance(estActif, msgCtrl.text.trim());
        },
      ),
    ]),
    const SizedBox(height: 16),

    // Vider le cache
    _SettingsCard(title: '🗑️ Cache', children: [
      Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Vider le cache applicatif',
            style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w500,
              color: const Color(0xFF0F172A))),
          Text('Force le rechargement des paramètres et des données',
            style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFF64748B))),
        ])),
        OutlinedButton.icon(
          icon: const Icon(Icons.refresh_outlined, size: 16),
          label: const Text('Vider le cache'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF64748B),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
            textStyle: GoogleFonts.inter(fontSize: 13),
          ),
          onPressed: () async {
            final token = ctx.read<AuthProvider>().token ?? '';
            await AdminService().viderCache(token);
            await ctx.read<AppConfigProvider>().reload();
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
              content: Text('Cache vidé et paramètres rechargés'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ));
          },
        ),
      ]),
    ]),
  ]));
}
```

---

## 8. Fix Tooltips Informatifs sur tous les paramètres

```dart
// Widget tooltip réutilisable
class _InfoTooltip extends StatelessWidget {
  final String message;
  const _InfoTooltip(this.message);

  @override
  Widget build(BuildContext context) => Tooltip(
    message: message,
    preferBelow: false,
    textStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white),
    decoration: BoxDecoration(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: const Icon(
      Icons.info_outline_rounded,
      size: 16,
      color: Color(0xFF94A3B8),
    ),
  );
}

// Helper pour label avec tooltip
Widget _labelWithTooltip(String label, String tooltip) => Row(children: [
  Text(label, style: GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w500,
    color: const Color(0xFF374151))),
  const SizedBox(width: 4),
  _InfoTooltip(tooltip),
]);

// Tooltips à ajouter sur chaque paramètre :
// inscription_libre        → "Permet à n'importe qui de créer un compte..."
// validation_manuelle      → "Si activé, les nouveaux comptes attendent..."
// max_offres_gratuit       → "Nombre max d'offres actives pour un compte gratuit..."
// duree_validite_offre     → "Après ce délai, l'offre passe automatiquement..."
// notif_email_candidature  → "L'entreprise reçoit un email à chaque candidature..."
// seuil_matching           → "Les offres sous ce score ne sont pas suggérées..."
// duree_session            → "Durée avant déconnexion automatique..."
// max_tentatives           → "Blocage temporaire après N échecs de connexion..."
// ips_bloquees             → "Ces adresses IP ne peuvent pas accéder à l'API..."
// twofa_admin              → "Code TOTP via Google Authenticator..."
// mode_maintenance         → "Affiche un bandeau et bloque les APIs publiques..."
```

---

## 9. Critères d'Acceptation

### ✅ Upload Logo & Bannières
- [ ] Clic sur zone logo → gestionnaire de fichiers s'ouvre
- [ ] Dimensions recommandées affichées : "400 × 200 px (ratio 2:1)"
- [ ] Upload réel vers Supabase Storage (pas un lien texte)
- [ ] Aperçu logo mis à jour immédiatement après upload
- [ ] Logo propagé sur toute l'app via AppConfigProvider
- [ ] Dialog bannière : zone upload image avec dimensions "1920 × 1080 px"
- [ ] Bannière toggle off → disparaît du carousel homepage

### ✅ Section Comptes
- [ ] validation_manuelle = true → nouveau compte en attente (est_valide = false)
- [ ] validation_manuelle = false → compte validé automatiquement
- [ ] max_offres_gratuit = 5 → erreur 403 si l'entreprise dépasse la limite
- [ ] Tooltips informatifs sur chaque option

### ✅ Section Notifications
- [ ] Éditeur template email affiché
- [ ] Alerte claire : "nécessite configuration SMTP"
- [ ] Champs SMTP sauvegardables

### ✅ Section IA & Matching
- [ ] Guide 3 étapes avec lien RapidAPI
- [ ] 3 APIs listées avec leurs hosts exacts
- [ ] Champ clé API avec masquage (••••)
- [ ] Bouton tester la connexion fonctionnel
- [ ] Slider seuil matching opérationnel

### ✅ Section Sécurité
- [ ] Tooltip sur chaque option (explication claire)
- [ ] IPs bloquées appliquées dans le middleware backend
- [ ] Middleware checkBlockedIP ajouté dans index.js

### ✅ Section Pied de Page
- [ ] Espacement correct entre les champs (16px)
- [ ] Tooltips sur chaque champ
- [ ] Sauvegarde → propagation immédiate sur la homepage

### ✅ Section Maintenance
- [ ] Toggle maintenance → bannière rouge sur toute l'app
- [ ] Middleware backend retourne 503 pour les routes publiques
- [ ] Message personnalisable et sauvegardable
- [ ] Bouton vider cache fonctionnel

---

*PRD EmploiConnect v3.4 — Corrections Paramètres Admin*
*Cursor / Kirsoft AI — Phase 7.4*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
