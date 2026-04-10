# PRD — EmploiConnect · Messagerie Complète + Fixes
## Product Requirements Document v8.6
**Stack : Flutter + Node.js/Express + Supabase**
**Outil : Cursor / Kirsoft AI**
**Date : Avril 2026**

---

## Table des Matières

1. [Fix erreur Flutter "Bad state: Not connected"](#1-fix-erreur-flutter-bad-state)
2. [Fix téléchargement fichiers messagerie recruteur](#2-fix-téléchargement-fichiers-messagerie-recruteur)
3. [Messagerie candidat — Parité complète avec recruteur](#3-messagerie-candidat--parité-complète-avec-recruteur)
4. [Bouton "Contacter" dans l'espace candidat](#4-bouton-contacter-dans-lespace-candidat)

---

## 1. Fix erreur Flutter "Bad state: Not connected"

### Cause
```
"Bad state: Not connected to an application"
= Erreur de hot reload Flutter Web
= Le DevTools DWDS perd la connexion WebSocket
= PAS une erreur de code applicatif
= Se produit quand on fait des modifications
  pendant que l'app tourne
```

### Fix
```bash
# Arrêter complètement Flutter
Ctrl+C dans le terminal Flutter

# Relancer proprement
flutter clean
flutter pub get
flutter run -d chrome --web-port 3001
```

### Prompt pour Cursor
```
"L'erreur 'Bad state: Not connected to an application'
est une erreur de hot reload Flutter Web DWDS.
Ce n'est PAS une erreur de code.

Fix : arrêter Flutter, relancer avec :
flutter clean && flutter pub get
flutter run -d chrome --web-port 3001

Ne pas modifier le code pour cette erreur."
```

---

## 2. Fix téléchargement fichiers messagerie recruteur

### Problème
```
Erreur : "Bad state exception" au téléchargement
Cause  : URL du fichier mal construite ou
         téléchargement via url_launcher non configuré
         ou CORS sur Supabase Storage
```

### Chercher le code de téléchargement
```bash
grep -rn "telecharger\|download\|url_launcher\|launch\|openUrl" \
  frontend/lib/screens/recruteur --include="*.dart" | \
  grep -i "fichier\|document\|attachment"
```

### Fix backend — Route de téléchargement sécurisée
```javascript
// Dans backend/src/routes/messages.routes.js
// Ajouter une route proxy de téléchargement

router.get('/fichier/:messageId', auth, async (req, res) => {
  try {
    const { messageId } = req.params;

    // Récupérer le message
    const { data: message } = await supabase
      .from('messages')
      .select('fichier_url, fichier_nom, fichier_type, fichier_taille')
      .eq('id', messageId)
      .single();

    if (!message?.fichier_url) {
      return res.status(404).json({
        success: false, message: 'Fichier non trouvé'
      });
    }

    // Générer une URL signée depuis Supabase Storage
    // Extraire le chemin depuis l'URL publique
    const urlObj        = new URL(message.fichier_url);
    const cheminFichier = urlObj.pathname
      .replace('/storage/v1/object/public/messages/', '')
      .replace('/storage/v1/object/sign/messages/', '');

    const { data: signed, error } = await supabase.storage
      .from('messages')
      .createSignedUrl(cheminFichier, 300); // 5 minutes

    if (error || !signed?.signedUrl) {
      // Fallback : URL publique directe
      return res.json({
        success:  true,
        url:      message.fichier_url,
        nom:      message.fichier_nom || 'fichier',
        type:     message.fichier_type || 'application/octet-stream',
        taille:   message.fichier_taille || 0,
      });
    }

    return res.json({
      success:  true,
      url:      signed.signedUrl,
      nom:      message.fichier_nom || 'fichier',
      type:     message.fichier_type || 'application/octet-stream',
      taille:   message.fichier_taille || 0,
    });

  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});
```

### Fix Flutter — Téléchargement robuste
```dart
// Dans le widget MessageBubble (messagerie recruteur)
// Remplacer la logique de téléchargement par :

Future<void> _telechargerFichier(
    BuildContext context, String messageId) async {
  try {
    setState(() => _isDownloading = true);

    final token = context.read<AuthProvider>().token ?? '';

    // Demander l'URL sécurisée au backend
    final res = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/messages/fichier/$messageId'),
      headers: {'Authorization': 'Bearer $token'});

    final body = jsonDecode(res.body);

    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Erreur serveur');
    }

    final url = body['url'] as String;
    final nom = body['nom'] as String? ?? 'fichier';

    // Ouvrir l'URL dans le navigateur
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri,
        mode: LaunchMode.externalApplication);
    } else {
      // Fallback Web : créer un lien <a> et cliquer
      // ignore: avoid_web_libraries_in_flutter
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', nom)
        ..setAttribute('target', '_blank')
        ..click();
    }

  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur téléchargement: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating));
    }
  } finally {
    if (mounted) setState(() => _isDownloading = false);
  }
}
```

### Ajouter url_launcher dans pubspec.yaml
```yaml
# Si pas encore présent :
dependencies:
  url_launcher: ^6.2.5
  universal_html: ^2.2.4  # Pour fallback Web
```

---

## 3. Messagerie Candidat — Parité complète avec recruteur

### Ce que la messagerie recruteur a (à copier exactement)

```bash
# Trouver les fichiers de messagerie recruteur
find frontend/lib/screens/recruteur -name "*message*" -o -name "*messagerie*"

# Voir la logique complète
cat frontend/lib/screens/recruteur/pages/messagerie_recruteur_page.dart
```

### Structure complète messagerie candidat

```dart
// frontend/lib/screens/candidat/pages/messagerie_candidat_page.dart
// REMPLACER le contenu actuel par la version complète ci-dessous

import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class _MessagerieState extends State<MessagerieCandidatPage>
    with TickerProviderStateMixin {

  // ── État ───────────────────────────────────────────────
  List<Map<String, dynamic>> _conversations = [];
  Map<String, dynamic>?      _convActive;
  List<Map<String, dynamic>> _messages      = [];
  bool   _isLoadingConvs  = true;
  bool   _isLoadingMsgs   = false;
  bool   _isSending       = false;
  String _searchQuery     = '';
  Timer? _pollTimer;

  final _msgCtrl    = TextEditingController();
  final _searchCtrl = TextEditingController();
  PlatformFile? _fichierEnAttente;
  bool _isImageEnAttente = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5), (_) {
      if (_convActive != null) _pollMessages();
      _updateBadges();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Charger conversations ──────────────────────────────
  Future<void> _loadConversations() async {
    setState(() => _isLoadingConvs = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/messages/conversations'),
        headers: {'Authorization': 'Bearer $token'});
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        final convs = List<Map<String, dynamic>>.from(
          body['data']['conversations'] ?? []);
        final totalNonLus =
          body['data']['total_non_lus'] as int? ?? 0;
        setState(() {
          _conversations  = convs;
          _isLoadingConvs = false;
        });
        context.read<CandidatProvider>()
          .updateNbMessages(totalNonLus);
      }
    } catch (_) {
      setState(() => _isLoadingConvs = false);
    }
  }

  // ── Polling messages ───────────────────────────────────
  Future<void> _pollMessages() async {
    if (_convActive == null) return;
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final autreId =
        _convActive!['autre_user_id'] as String? ?? '';
      final res = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/messages/$autreId'),
        headers: {'Authorization': 'Bearer $token'});
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        final msgs = List<Map<String, dynamic>>.from(
          body['data']['messages'] ?? []);
        if (msgs.length != _messages.length) {
          setState(() => _messages = msgs);
        }
      }
    } catch (_) {}
  }

  Future<void> _updateBadges() async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/messages/conversations'),
        headers: {'Authorization': 'Bearer $token'});
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        final convs = List<Map<String, dynamic>>.from(
          body['data']['conversations'] ?? []);
        final total =
          body['data']['total_non_lus'] as int? ?? 0;
        setState(() => _conversations = convs);
        context.read<CandidatProvider>().updateNbMessages(total);
      }
    } catch (_) {}
  }

  // ── Build principal ────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDesktop =
      MediaQuery.of(context).size.width > 800;

    if (isDesktop) {
      return Row(children: [
        SizedBox(
          width: 300,
          child: _buildListeConversations()),
        const VerticalDivider(
          width: 1, color: Color(0xFFE2E8F0)),
        Expanded(child: _convActive != null
            ? _buildZoneMessages()
            : _buildAccueil()),
      ]);
    }

    return _convActive != null
        ? _buildZoneMessages()
        : _buildListeConversations();
  }

  // ── Liste conversations ────────────────────────────────
  Widget _buildListeConversations() => Column(children: [

    // Header + recherche
    Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      color: Colors.white,
      child: Column(children: [
        Row(children: [
          Text('Messages', style: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A))),
          const Spacer(),
          // Bouton nouveau message
          GestureDetector(
            onTap: _showNouveauMessage,
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF1A56DB),
                borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.edit_rounded,
                color: Colors.white, size: 16))),
        ]),
        const SizedBox(height: 10),

        // Barre de recherche
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Rechercher une entreprise...',
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFFCBD5E1)),
            prefixIcon: const Icon(Icons.search_rounded,
              size: 18, color: Color(0xFF94A3B8)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded,
                      size: 16, color: Color(0xFF94A3B8)),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    }) : null,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0))),
          ),
          onChanged: (v) =>
            setState(() => _searchQuery = v.trim())),
      ])),
    const Divider(height: 1, color: Color(0xFFE2E8F0)),

    // Items
    Expanded(child: _buildItemsConversations()),
  ]);

  Widget _buildItemsConversations() {
    final filtered = _conversations.where((c) {
      if (_searchQuery.isEmpty) return true;
      final nom = (c['nom'] as String? ?? '').toLowerCase();
      return nom.contains(_searchQuery.toLowerCase());
    }).toList();

    if (filtered.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          const Icon(Icons.chat_bubble_outline_rounded,
            color: Color(0xFFE2E8F0), size: 48),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'Aucun résultat'
                : 'Aucune conversation',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF94A3B8))),
        ])));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final conv      = filtered[i];
        final nom       = conv['nom']      as String? ?? '';
        final photo     = conv['photo']    as String?;
        final lastMsg   = conv['dernier_message']
            as String? ?? '';
        final nbNonLus  = conv['nb_non_lus'] as int? ?? 0;
        final dateMsg   =
          conv['date_dernier_message'] as String?;
        final isActive  =
          _convActive?['id'] == conv['id'];

        return GestureDetector(
          onTap: () => _ouvrirConversation(conv),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
            color: isActive
                ? const Color(0xFFEFF6FF) : Colors.white,
            child: Row(children: [
              // Avatar
              Stack(children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF1A56DB)
                    .withOpacity(0.1),
                  backgroundImage: photo != null
                      ? NetworkImage(photo) : null,
                  child: photo == null ? Text(
                    nom.isNotEmpty
                        ? nom[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A56DB)))
                    : null),
              ]),
              const SizedBox(width: 12),

              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(children: [
                  Expanded(child: Text(nom,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: nbNonLus > 0
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: const Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
                  if (dateMsg != null)
                    Text(_fmtDateCourte(dateMsg),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: nbNonLus > 0
                            ? const Color(0xFF1A56DB)
                            : const Color(0xFF94A3B8),
                        fontWeight: nbNonLus > 0
                            ? FontWeight.w600
                            : FontWeight.w400)),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  Expanded(child: Text(
                    lastMsg.isNotEmpty
                        ? lastMsg
                        : 'Démarrer la conversation',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: nbNonLus > 0
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: nbNonLus > 0
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF94A3B8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
                  // Badge non lus
                  if (nbNonLus > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      width: 20, height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle),
                      child: Center(child: Text(
                        nbNonLus > 9 ? '9+' : '$nbNonLus',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)))),
                ]),
              ])),
            ]));
      });
  }

  // ── Zone messages ──────────────────────────────────────
  Widget _buildZoneMessages() {
    final nom   = _convActive!['nom']   as String? ?? '';
    final photo = _convActive!['photo'] as String?;

    return Column(children: [
      // En-tête conversation
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(
            color: Color(0xFFE2E8F0)))),
        child: Row(children: [
          if (MediaQuery.of(context).size.width <= 800)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                color: Color(0xFF64748B)),
              onPressed: () =>
                setState(() => _convActive = null)),

          // Photo interlocuteur
          CircleAvatar(
            radius: 18,
            backgroundColor:
              const Color(0xFF1A56DB).withOpacity(0.1),
            backgroundImage: photo != null
                ? NetworkImage(photo) : null,
            child: photo == null ? Text(
              nom.isNotEmpty ? nom[0].toUpperCase() : '?',
              style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: const Color(0xFF1A56DB))) : null),
          const SizedBox(width: 10),

          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(nom, style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A))),
            Text('Entreprise', style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF94A3B8))),
          ])),
        ])),

      // Liste messages
      Expanded(child: _isLoadingMsgs
          ? const Center(child: CircularProgressIndicator(
              color: Color(0xFF1A56DB)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final msg    = _messages[i];
                final isMe   = msg['expediteur_id']
                    == context.read<AuthProvider>().userId;
                return _MessageBubble(
                  message:   msg,
                  isMe:      isMe,
                  onDelete:  isMe
                    ? () => _supprimerMessage(
                        msg['id'] as String) : null,
                  onDownload: msg['fichier_url'] != null
                    ? () => _telechargerFichier(
                        context, msg['id'] as String) : null,
                );
              })),

      // Zone saisie
      _buildZoneSaisie(),
    ]);
  }

  // ── Zone saisie message ────────────────────────────────
  Widget _buildZoneSaisie() => Container(
    padding: const EdgeInsets.all(12),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(
        color: Color(0xFFE2E8F0)))),
    child: Column(children: [

      // Aperçu fichier en attente
      if (_fichierEnAttente != null)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(
              _isImageEnAttente
                  ? Icons.image_outlined
                  : Icons.attach_file_rounded,
              color: const Color(0xFF1A56DB), size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(
              _fichierEnAttente!.name,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF1A56DB)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis)),
            // Taille fichier
            Text(
              _formatTaille(_fichierEnAttente!.size),
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF94A3B8))),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() {
                _fichierEnAttente = null;
                _isImageEnAttente = false;
              }),
              child: const Icon(Icons.close, size: 16,
                color: Color(0xFF94A3B8))),
          ])),

      Row(children: [
        // Bouton pièce jointe
        GestureDetector(
          onTap: _choisirFichier,
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.attach_file_rounded,
              color: Color(0xFF64748B), size: 18))),
        const SizedBox(width: 6),

        // Bouton image
        GestureDetector(
          onTap: _choisirImage,
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.image_outlined,
              color: Color(0xFF64748B), size: 18))),
        const SizedBox(width: 8),

        // Champ texte
        Expanded(child: TextField(
          controller: _msgCtrl,
          maxLines: null,
          decoration: InputDecoration(
            hintText: 'Écrire un message...',
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFFCBD5E1)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(100),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(100),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0))),
          ))),
        const SizedBox(width: 8),

        // Bouton envoyer
        GestureDetector(
          onTap: _isSending ? null : _envoyerMessage,
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: _isSending
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF1A56DB),
              shape: BoxShape.circle),
            child: _isSending
                ? const Center(
                    child: SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white)))
                : const Icon(Icons.send_rounded,
                    color: Colors.white, size: 18))),
      ]),
    ]));

  // ── Actions ────────────────────────────────────────────
  Future<void> _choisirFichier() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'doc', 'docx', 'xls', 'xlsx',
          'ppt', 'pptx', 'txt', 'zip']);
      if (result?.files.isNotEmpty == true) {
        setState(() {
          _fichierEnAttente = result!.files.first;
          _isImageEnAttente = false;
        });
      }
    } catch (e) {
      print('[messagerie] FilePicker: $e');
    }
  }

  Future<void> _choisirImage() async {
    try {
      final picker = ImagePicker();
      final file   = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _fichierEnAttente = PlatformFile(
            name:  file.name,
            size:  bytes.length,
            bytes: bytes);
          _isImageEnAttente = true;
        });
      }
    } catch (e) {
      print('[messagerie] ImagePicker: $e');
    }
  }

  Future<void> _envoyerMessage() async {
    final texte = _msgCtrl.text.trim();
    if (texte.isEmpty && _fichierEnAttente == null) return;
    if (_convActive == null) return;

    setState(() => _isSending = true);
    try {
      final token     = context.read<AuthProvider>().token ?? '';
      final autreId   = _convActive!['autre_user_id'] as String? ?? '';

      if (_fichierEnAttente != null) {
        // Envoyer avec fichier
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConfig.baseUrl}/api/messages/envoyer'));
        request.headers['Authorization'] = 'Bearer $token';
        request.fields['destinataire_id'] = autreId;
        if (texte.isNotEmpty) request.fields['contenu'] = texte;

        final bytes = _fichierEnAttente!.bytes
            ?? await File(_fichierEnAttente!.path!).readAsBytes();

        request.files.add(http.MultipartFile.fromBytes(
          'fichier',
          bytes,
          filename: _fichierEnAttente!.name));

        final streamed = await request.send();
        final res      = await http.Response.fromStream(streamed);
        final body     = jsonDecode(res.body);

        if (body['success'] == true) {
          _msgCtrl.clear();
          setState(() {
            _fichierEnAttente = null;
            _isImageEnAttente = false;
          });
          await _pollMessages();
        }
      } else {
        // Envoyer texte seulement
        final res = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/messages/envoyer'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'destinataire_id': autreId,
            'contenu':         texte,
          }));
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          _msgCtrl.clear();
          await _pollMessages();
        }
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _supprimerMessage(String msgId) async {
    final token = context.read<AuthProvider>().token ?? '';
    await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/messages/$msgId'),
      headers: {'Authorization': 'Bearer $token'});
    await _pollMessages();
  }

  Future<void> _telechargerFichier(
      BuildContext context, String msgId) async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res   = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/messages/fichier/$msgId'),
        headers: {'Authorization': 'Bearer $token'});
      final body  = jsonDecode(res.body);
      if (body['success'] == true) {
        final url = body['url'] as String;
        final nom = body['nom'] as String? ?? 'fichier';
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri,
            mode: LaunchMode.externalApplication);
        } else {
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', nom)
            ..setAttribute('target', '_blank')
            ..click();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur: $e'),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating));
    }
  }

  void _ouvrirConversation(Map<String, dynamic> conv) {
    setState(() {
      _convActive    = conv;
      _isLoadingMsgs = true;
      _messages      = [];
    });
    _chargerMessages(conv);
  }

  Future<void> _chargerMessages(
      Map<String, dynamic> conv) async {
    try {
      final token   = context.read<AuthProvider>().token ?? '';
      final autreId = conv['autre_user_id'] as String? ?? '';
      final res     = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/messages/$autreId'),
        headers: {'Authorization': 'Bearer $token'});
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        final inter = body['data']['interlocuteur']
            as Map<String, dynamic>?;
        setState(() {
          _messages      = List<Map<String, dynamic>>.from(
            body['data']['messages'] ?? []);
          _isLoadingMsgs = false;
          if (inter != null) {
            _convActive = {
              ..._convActive!,
              'photo': inter['photo_url'],
              'nom':   inter['nom'] ?? _convActive!['nom'],
            };
          }
        });
      }
    } catch (_) {
      setState(() => _isLoadingMsgs = false);
    }
  }

  Widget _buildAccueil() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 80, height: 80,
        decoration: const BoxDecoration(
          color: Color(0xFFEFF6FF), shape: BoxShape.circle),
        child: const Icon(Icons.chat_bubble_outline_rounded,
          color: Color(0xFF1A56DB), size: 40)),
      const SizedBox(height: 16),
      Text('Sélectionnez une conversation',
        style: GoogleFonts.inter(
          fontSize: 14, color: const Color(0xFF64748B))),
      const SizedBox(height: 8),
      Text('Ou démarrez une nouvelle conversation',
        style: GoogleFonts.inter(
          fontSize: 12, color: const Color(0xFF94A3B8))),
    ]));

  void _showNouveauMessage() {
    // Dialog pour choisir l'entreprise à contacter
    showDialog(context: context, builder: (_) => _DialogNouveauMessage(
      onEntrepriseSelectionnee: (entrepriseId, nom, photo) {
        Navigator.pop(context);
        setState(() {
          _convActive = {
            'id':            entrepriseId,
            'autre_user_id': entrepriseId,
            'nom':           nom,
            'photo':         photo,
          };
          _isLoadingMsgs = true;
          _messages      = [];
        });
        _chargerMessages(_convActive!);
      }));
  }

  String _formatTaille(int bytes) {
    if (bytes < 1024)       return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String _fmtDateCourte(String d) {
    try {
      final dt   = DateTime.parse(d).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}min';
      if (diff.inHours   < 24) return '${diff.inHours}h';
      if (diff.inDays    < 7)  return '${diff.inDays}j';
      return '${dt.day}/${dt.month}';
    } catch (_) { return ''; }
  }
}

// ── Widget bulle message ─────────────────────────────────
class _MessageBubble extends StatefulWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final VoidCallback? onDelete;
  final VoidCallback? onDownload;
  const _MessageBubble({required this.message,
    required this.isMe, this.onDelete, this.onDownload});
  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final msg       = widget.message;
    final contenu   = msg['contenu']      as String? ?? '';
    final fichierUrl = msg['fichier_url'] as String?;
    final fichierNom = msg['fichier_nom'] as String?;
    final fichierType = msg['fichier_type'] as String? ?? '';
    final isImage   = fichierType.startsWith('image/');
    final date      = msg['date_envoi']   as String?;

    return GestureDetector(
      onLongPress: widget.onDelete != null ? () {
        showDialog(context: context, builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
          title: Text('Supprimer ce message ?',
            style: GoogleFonts.inter(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                elevation: 0),
              onPressed: () {
                Navigator.pop(context);
                widget.onDelete!();
              },
              child: Text('Supprimer',
                style: GoogleFonts.inter(color: Colors.white))),
          ]));
      } : null,
      child: Align(
        alignment: widget.isMe
            ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.65),
          child: Column(
            crossAxisAlignment: widget.isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start, children: [

            Container(
              padding: fichierUrl != null && isImage
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: widget.isMe
                    ? const Color(0xFF1A56DB)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: widget.isMe ? null : Border.all(
                  color: const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 4, offset: Offset(0, 2))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                // Image
                if (fichierUrl != null && isImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      fichierUrl,
                      width: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image,
                          color: Colors.grey, size: 40))),

                // Fichier non-image
                if (fichierUrl != null && !isImage)
                  GestureDetector(
                    onTap: _isDownloading
                        ? null
                        : () {
                          if (widget.onDownload != null) {
                            setState(() => _isDownloading = true);
                            widget.onDownload!();
                            Future.delayed(
                              const Duration(seconds: 2),
                              () { if (mounted) setState(() =>
                                _isDownloading = false); });
                          }
                        },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.isMe
                            ? Colors.white.withOpacity(0.15)
                            : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        Icon(Icons.description_outlined,
                          color: widget.isMe
                              ? Colors.white
                              : const Color(0xFF1A56DB),
                          size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          fichierNom ?? 'Document',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.isMe
                                ? Colors.white
                                : const Color(0xFF1A56DB)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 6),
                        _isDownloading
                            ? const SizedBox(
                                width: 14, height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2))
                            : Icon(Icons.download_rounded,
                                size: 16,
                                color: widget.isMe
                                    ? Colors.white
                                    : const Color(0xFF1A56DB)),
                      ]))),

                // Texte
                if (contenu.isNotEmpty)
                  Padding(
                    padding: fichierUrl != null
                        ? const EdgeInsets.fromLTRB(14, 8, 14, 10)
                        : EdgeInsets.zero,
                    child: Text(contenu,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: widget.isMe
                            ? Colors.white
                            : const Color(0xFF0F172A)))),
              ])),

            // Heure
            if (date != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(_fmtHeure(date),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF94A3B8)))),
          ]))));
  }

  String _fmtHeure(String d) {
    try {
      final dt = DateTime.parse(d).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:'
             '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }
}
```

---

## 4. Bouton "Contacter" dans l'espace candidat

```dart
// Dans la page détails offre (candidat)
// Ajouter un bouton "Contacter l'entreprise"
// À côté du bouton "Postuler"

Row(children: [
  // Bouton contacter
  Expanded(child: OutlinedButton.icon(
    icon: const Icon(Icons.chat_bubble_outline_rounded,
      size: 16),
    label: const Text('Contacter'),
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: Color(0xFF1A56DB)),
      foregroundColor: const Color(0xFF1A56DB),
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w600)),
    onPressed: () {
      // Aller vers la messagerie avec cette entreprise
      context.push(
        '/dashboard-candidat/messages',
        extra: {
          'autre_user_id': entrepriseUserId,
          'nom':           nomEntreprise,
          'photo':         logoEntreprise,
        });
    })),
  const SizedBox(width: 10),

  // Bouton postuler
  Expanded(child: ElevatedButton.icon(
    icon: const Icon(Icons.send_rounded, size: 16),
    label: const Text('Postuler'),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1A56DB),
      foregroundColor: Colors.white, elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w700)),
    onPressed: () => context.push(
      '/dashboard-candidat/postuler/$offreId'))),
]);
```

---

## Critères d'Acceptation

### ✅ Fix erreur Flutter
- [ ] Relancer avec `flutter clean && flutter run`
- [ ] Erreur DWDS disparue

### ✅ Téléchargement messagerie recruteur
- [ ] Cliquer sur un fichier → téléchargement OK
- [ ] Pas d'erreur "Bad state"
- [ ] URL signée générée par le backend

### ✅ Messagerie candidat
- [ ] Liste conversations avec recherche fonctionnelle
- [ ] Photo de l'entreprise dans l'en-tête
- [ ] Badge rouge + nombre messages non lus
- [ ] Bouton pièce jointe → upload fichier
- [ ] Bouton image → upload photo
- [ ] Long press message → supprimer
- [ ] Téléchargement fichiers reçus
- [ ] Polling toutes les 5 secondes
- [ ] Bouton nouveau message

### ✅ Bouton Contacter
- [ ] Visible sur la page détails offre
- [ ] Redirige vers messagerie avec l'entreprise
- [ ] Conversation s'ouvre directement

---

*PRD EmploiConnect v8.6 — Messagerie Complète*
*Cursor / Kirsoft AI — Phase 19*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
