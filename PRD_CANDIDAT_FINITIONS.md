# PRD — EmploiConnect · Espace Candidat — Finitions & Messagerie
## Product Requirements Document v8.4
**Stack : Flutter + Node.js/Express + Supabase**
**Outil : Cursor / Kirsoft AI**
**Date : Avril 2026**

---

## Table des Matières

1. [Notifications — Menu 3 points (Lire / Supprimer)](#1-notifications--menu-3-points)
2. [Mon Profil — Bouton enregistrer modéré](#2-mon-profil--bouton-enregistrer-modéré)
3. [Mon Profil — Vérifier visibilité profil + propositions](#3-mon-profil--vérifier-visibilité-profil)
4. [Messagerie Candidat — Toutes les fonctionnalités](#4-messagerie-candidat--toutes-les-fonctionnalités)
5. [Mes Candidatures — Barre d'évolution animée](#5-mes-candidatures--barre-dévolution-animée)

---

## 1. Notifications — Menu 3 points

```dart
// Dans notifications_candidat_page.dart
// Ajouter un menu 3 points sur chaque notification

// Dans le widget de chaque notification, remplacer
// le point bleu à droite par un PopupMenuButton :

Row(children: [
  // ... icône + contenu existants ...

  // Menu 3 points à droite
  PopupMenuButton<String>(
    icon: Icon(
      Icons.more_vert_rounded,
      size: 18,
      color: notif['est_lue'] == true
          ? const Color(0xFF94A3B8)
          : const Color(0xFF1A56DB)),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10)),
    offset: const Offset(0, 30),
    itemBuilder: (_) => [
      // Option : Marquer comme lu (si non lue)
      if (notif['est_lue'] != true)
        PopupMenuItem<String>(
          value: 'lire',
          child: Row(children: [
            const Icon(Icons.done_rounded,
              size: 16, color: Color(0xFF1A56DB)),
            const SizedBox(width: 8),
            Text('Marquer comme lu',
              style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF374151))),
          ])),
      // Option : Marquer comme non lu (si déjà lue)
      if (notif['est_lue'] == true)
        PopupMenuItem<String>(
          value: 'non_lue',
          child: Row(children: [
            const Icon(Icons.mark_email_unread_outlined,
              size: 16, color: Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text('Marquer comme non lu',
              style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF374151))),
          ])),
      // Séparateur
      const PopupMenuDivider(),
      // Option : Supprimer
      PopupMenuItem<String>(
        value: 'supprimer',
        child: Row(children: [
          const Icon(Icons.delete_outline_rounded,
            size: 16, color: Color(0xFFEF4444)),
          const SizedBox(width: 8),
          Text('Supprimer',
            style: GoogleFonts.inter(
              fontSize: 13, color: const Color(0xFFEF4444))),
        ])),
    ],
    onSelected: (action) => _actionNotification(
      action, notif['id'] as String)),
])

// Méthode d'action sur notification
Future<void> _actionNotification(String action, String id) async {
  final token = context.read<AuthProvider>().token ?? '';

  switch (action) {
    case 'lire':
      await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/$id/lire'),
        headers: {'Authorization': 'Bearer $token'});
      break;

    case 'non_lue':
      await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/$id/non-lue'),
        headers: {'Authorization': 'Bearer $token'});
      break;

    case 'supprimer':
      // Confirmation avant suppression
      final confirme = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
          title: Text('Supprimer cette notification ?',
            style: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w700)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
              onPressed: () => Navigator.pop(context, true),
              child: Text('Supprimer',
                style: GoogleFonts.inter(color: Colors.white))),
          ]));
      if (confirme == true) {
        await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/api/notifications/$id'),
          headers: {'Authorization': 'Bearer $token'});
      }
      break;
  }

  // Recharger les notifications
  _loadNotifications();
}
```

### Backend — Routes manquantes pour notifications

```javascript
// Dans backend/src/routes/notifications.routes.js
// Ajouter si manquant :

// Marquer une notification comme lue
router.patch('/:id/lire', auth, async (req, res) => {
  try {
    await supabase.from('notifications')
      .update({ est_lue: true, date_lecture: new Date().toISOString() })
      .eq('id', req.params.id)
      .eq('destinataire_id', req.user.id);
    return res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Marquer comme non lue
router.patch('/:id/non-lue', auth, async (req, res) => {
  try {
    await supabase.from('notifications')
      .update({ est_lue: false, date_lecture: null })
      .eq('id', req.params.id)
      .eq('destinataire_id', req.user.id);
    return res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Supprimer une notification
router.delete('/:id', auth, async (req, res) => {
  try {
    await supabase.from('notifications')
      .delete()
      .eq('id', req.params.id)
      .eq('destinataire_id', req.user.id);
    return res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});
```

---

## 2. Mon Profil — Bouton enregistrer modéré

```dart
// Dans profil_cv_page.dart
// Remplacer le gros bouton par un bouton compact et élégant

Widget _buildBoutonSauvegarder() => Padding(
  padding: const EdgeInsets.only(top: 8),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
    // Bouton compact à droite
    ElevatedButton.icon(
      icon: _isSaving
          ? const SizedBox(width: 14, height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.save_rounded, size: 16),
      label: Text(
        _isSaving ? 'Enregistrement...' : 'Enregistrer le profil',
        style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A56DB),
        foregroundColor: Colors.white, elevation: 0,
        // ← Taille modérée, pas toute la largeur
        padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10))),
      onPressed: _isSaving ? null : _sauvegarderProfil),
  ]));
```

---

## 3. Mon Profil — Vérifier visibilité profil

### Backend — Vérifier et corriger les routes

```bash
# Chercher les routes de visibilité
grep -rn "profil_visible\|recevoir_propositions" \
  backend/src/routes --include="*.js"
```

### Backend — S'assurer que les colonnes existent

```sql
-- Supabase SQL Editor
ALTER TABLE chercheurs_emploi
  ADD COLUMN IF NOT EXISTS profil_visible
    BOOLEAN DEFAULT TRUE;
ALTER TABLE chercheurs_emploi
  ADD COLUMN IF NOT EXISTS recevoir_propositions
    BOOLEAN DEFAULT TRUE;

SELECT id, profil_visible, recevoir_propositions
FROM chercheurs_emploi LIMIT 5;
```

### Backend — Route PUT profil doit sauvegarder ces champs

```javascript
// Dans la route PUT /api/candidat/profil
// S'assurer que ces champs sont sauvegardés :

const {
  titre_poste, about, disponibilite,
  competences, experiences, formations, langues,
  profil_visible,       // ← Vérifier présent
  recevoir_propositions, // ← Vérifier présent
} = req.body;

const updateData = {};
// ... autres champs ...
if (profil_visible !== undefined)
  updateData.profil_visible = profil_visible;
if (recevoir_propositions !== undefined)
  updateData.recevoir_propositions = recevoir_propositions;

await supabase.from('chercheurs_emploi')
  .update(updateData)
  .eq('id', chercheur.id);

console.log('[profil] profil_visible:', profil_visible);
console.log('[profil] recevoir_propositions:', recevoir_propositions);
```

### Flutter — Toggles avec sauvegarde immédiate

```dart
// Section visibilité profil
Widget _buildVisibiliteCard() => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: const Color(0xFFE2E8F0))),
  child: Column(children: [
    _SectionHeader(
      icon: Icons.visibility_outlined,
      titre: 'Visibilité du profil',
      couleur: const Color(0xFF10B981)),
    const SizedBox(height: 14),

    // Toggle profil visible
    _buildToggle(
      icon:       Icons.person_outline_rounded,
      titre:      'Profil visible par les recruteurs',
      sousTitre:  'Les recruteurs peuvent voir votre profil',
      valeur:     _profilVisible,
      couleur:    const Color(0xFF10B981),
      onChanged: (v) async {
        setState(() => _profilVisible = v);
        // Sauvegarder immédiatement
        final token = context.read<AuthProvider>().token ?? '';
        await http.put(
          Uri.parse('${ApiConfig.baseUrl}/api/candidat/profil'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'profil_visible': v}));
        // Feedback visuel
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(v
              ? '✅ Profil maintenant visible'
              : '🔒 Profil masqué aux recruteurs'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: v
              ? const Color(0xFF10B981)
              : const Color(0xFF64748B)));
      }),
    const SizedBox(height: 12),

    // Toggle recevoir propositions
    _buildToggle(
      icon:       Icons.email_outlined,
      titre:      'Recevoir des propositions',
      sousTitre:  'Les recruteurs peuvent vous contacter',
      valeur:     _recevoirPropositions,
      couleur:    const Color(0xFF1A56DB),
      onChanged: (v) async {
        setState(() => _recevoirPropositions = v);
        final token = context.read<AuthProvider>().token ?? '';
        await http.put(
          Uri.parse('${ApiConfig.baseUrl}/api/candidat/profil'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'recevoir_propositions': v}));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(v
              ? '✅ Propositions activées'
              : '🔕 Propositions désactivées'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: v
              ? const Color(0xFF1A56DB)
              : const Color(0xFF64748B)));
      }),
  ]));

Widget _buildToggle({
  required IconData icon,
  required String titre, sousTitre,
  required bool valeur, couleur,
  required Function(bool) onChanged,
}) => Row(children: [
  Container(
    width: 36, height: 36,
    decoration: BoxDecoration(
      color: couleur.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8)),
    child: Icon(icon, color: couleur, size: 18)),
  const SizedBox(width: 12),
  Expanded(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(titre, style: GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w600,
      color: const Color(0xFF0F172A))),
    Text(sousTitre, style: GoogleFonts.inter(
      fontSize: 11, color: const Color(0xFF94A3B8))),
  ])),
  Switch(
    value: valeur,
    onChanged: onChanged,
    activeColor: couleur),
]);
```

---

## 4. Messagerie Candidat — Toutes les fonctionnalités

### 4.1 Structure complète de la page messagerie candidat

```dart
// frontend/lib/screens/candidat/pages/messagerie_candidat_page.dart
// Appliquer TOUTES les fonctionnalités de la messagerie recruteur

class _MessageriePageState extends State<MessagerieCandidat>
    with TickerProviderStateMixin {

  // État
  List<Map<String, dynamic>> _conversations = [];
  Map<String, dynamic>?      _convActive;
  List<Map<String, dynamic>> _messages      = [];
  bool   _isLoadingConvs = true;
  bool   _isLoadingMsgs  = false;
  String _searchQuery    = '';
  Timer? _pollTimer;

  final _msgCtrl          = TextEditingController();
  final _searchCtrl       = TextEditingController();
  PlatformFile? _fichierEnAttente;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    // Polling toutes les 5 secondes
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_convActive != null) _pollNouveauxMessages();
      _updateBadgesConversations();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Chargement conversations ─────────────────────────────
  Future<void> _loadConversations() async {
    setState(() => _isLoadingConvs = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/messages/conversations'),
        headers: {'Authorization': 'Bearer $token'});
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        final convs = List<Map<String, dynamic>>.from(
          body['data']['conversations'] ?? []);
        final totalNonLus = body['data']['total_non_lus'] as int? ?? 0;

        setState(() {
          _conversations = convs;
          _isLoadingConvs = false;
        });

        // Mettre à jour le badge dans le provider
        context.read<CandidatProvider>()
          .updateNbMessages(totalNonLus);
      }
    } catch (e) {
      setState(() => _isLoadingConvs = false);
    }
  }

  // ── Polling nouveaux messages ────────────────────────────
  Future<void> _pollNouveauxMessages() async {
    if (_convActive == null) return;
    try {
      final token       = context.read<AuthProvider>().token ?? '';
      final autreUserId = _convActive!['autre_user_id'] as String?;
      if (autreUserId == null) return;

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/messages/$autreUserId'),
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

  // ── Mise à jour badges conversations ─────────────────────
  Future<void> _updateBadgesConversations() async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/messages/conversations'),
        headers: {'Authorization': 'Bearer $token'});
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        final convs = List<Map<String, dynamic>>.from(
          body['data']['conversations'] ?? []);
        final totalNonLus = body['data']['total_non_lus'] as int? ?? 0;
        setState(() => _conversations = convs);
        context.read<CandidatProvider>().updateNbMessages(totalNonLus);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    if (isDesktop) {
      return Row(children: [
        // Panneau gauche : liste conversations
        SizedBox(width: 300, child: _buildListeConversations()),
        const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
        // Panneau droit : messages
        Expanded(child: _convActive != null
            ? _buildZoneMessages()
            : _buildAccueilMessagerie()),
      ]);
    }

    // Mobile : alterner entre liste et messages
    return _convActive != null
        ? _buildZoneMessages()
        : _buildListeConversations();
  }

  // ── Liste conversations ──────────────────────────────────
  Widget _buildListeConversations() => Column(children: [
    // Header
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
            hintText: 'Rechercher une conversation...',
            hintStyle: GoogleFonts.inter(
              fontSize: 13, color: const Color(0xFFCBD5E1)),
            prefixIcon: const Icon(Icons.search_rounded,
              size: 18, color: Color(0xFF94A3B8)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded,
                      size: 16, color: Color(0xFF94A3B8)),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    })
                : null,
            filled: true, fillColor: const Color(0xFFF8FAFC),
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
          onChanged: (v) => setState(() => _searchQuery = v.trim())),
      ])),
    const Divider(height: 1, color: Color(0xFFE2E8F0)),

    // Liste conversations filtrées
    Expanded(child: _isLoadingConvs
        ? const Center(child: CircularProgressIndicator(
            color: Color(0xFF1A56DB)))
        : _buildItemsConversations()),
  ]);

  Widget _buildItemsConversations() {
    // Filtrer selon la recherche
    final filtered = _conversations.where((conv) {
      if (_searchQuery.isEmpty) return true;
      final nom = (conv['nom'] as String? ?? '').toLowerCase();
      return nom.contains(_searchQuery.toLowerCase());
    }).toList();

    if (filtered.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.chat_bubble_outline_rounded,
            color: Color(0xFFE2E8F0), size: 48),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'Aucun résultat pour "$_searchQuery"'
                : 'Aucune conversation',
            style: GoogleFonts.inter(
              fontSize: 13, color: const Color(0xFF94A3B8))),
        ])));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final conv        = filtered[i];
        final nom         = conv['nom']         as String? ?? '';
        final photo       = conv['photo']       as String?;
        final dernierMsg  = conv['dernier_message'] as String? ?? '';
        final nbNonLus    = conv['nb_non_lus']  as int? ?? 0;
        final dateMsg     = conv['date_dernier_message'] as String?;
        final isActive    = _convActive?['id'] == conv['id'];

        return GestureDetector(
          onTap: () => _ouvrirConversation(conv),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
            color: isActive
                ? const Color(0xFFEFF6FF) : Colors.white,
            child: Row(children: [
              // Avatar avec photo
              Stack(children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF1A56DB)
                    .withOpacity(0.1),
                  backgroundImage: photo != null
                      ? NetworkImage(photo) : null,
                  child: photo == null ? Text(
                    nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A56DB)))
                    : null),
                // Indicateur en ligne (optionnel)
              ]),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(nom,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: nbNonLus > 0
                          ? FontWeight.w700 : FontWeight.w500,
                      color: const Color(0xFF0F172A)),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                  // Date dernier message
                  if (dateMsg != null)
                    Text(_fmtDateCourte(dateMsg),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: nbNonLus > 0
                            ? const Color(0xFF1A56DB)
                            : const Color(0xFF94A3B8),
                        fontWeight: nbNonLus > 0
                            ? FontWeight.w600 : FontWeight.w400)),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  Expanded(child: Text(
                    dernierMsg.isNotEmpty
                        ? dernierMsg : 'Démarrer une conversation',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: nbNonLus > 0
                          ? FontWeight.w600 : FontWeight.w400,
                      color: nbNonLus > 0
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF94A3B8)),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                  // Badge nombre messages non lus
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
                          fontSize: 10, fontWeight: FontWeight.w800,
                          color: Colors.white)))),
                ]),
              ])),
            ]));
      });
  }

  // ── Zone messages ────────────────────────────────────────
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
          // Bouton retour (mobile)
          if (MediaQuery.of(context).size.width <= 800)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                color: Color(0xFF64748B)),
              onPressed: () =>
                setState(() => _convActive = null)),

          // Photo de profil interlocuteur
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF1A56DB).withOpacity(0.1),
            backgroundImage: photo != null
                ? NetworkImage(photo) : null,
            child: photo == null ? Text(
              nom.isNotEmpty ? nom[0].toUpperCase() : '?',
              style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: const Color(0xFF1A56DB))) : null),
          const SizedBox(width: 10),

          // Nom + statut
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nom, style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A))),
            Text('Discussion sécurisée',
              style: GoogleFonts.inter(
                fontSize: 11, color: const Color(0xFF94A3B8))),
          ])),
        ])),

      // Messages
      Expanded(child: _isLoadingMsgs
          ? const Center(child: CircularProgressIndicator(
              color: Color(0xFF1A56DB)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final msg = _messages[i];
                final isMe = msg['expediteur_id'] ==
                    context.read<AuthProvider>().userId;
                return MessageBubble(
                  message: msg,
                  isMe:    isMe,
                  onDelete: () => _supprimerMessage(msg['id']));
              })),

      // Zone saisie
      _buildMessageInput(),
    ]);
  }

  // ── Zone saisie message (identique au recruteur) ─────────
  Widget _buildMessageInput() => Container(
    padding: const EdgeInsets.all(12),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
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
            const Icon(Icons.attach_file_rounded,
              color: Color(0xFF1A56DB), size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(_fichierEnAttente!.name,
              style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFF1A56DB)),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
            GestureDetector(
              onTap: () => setState(() => _fichierEnAttente = null),
              child: const Icon(Icons.close, size: 16,
                color: Color(0xFF94A3B8))),
          ])),

      Row(children: [
        // Pièce jointe
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

        // Image
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
          controller: _msgCtrl, maxLines: null,
          decoration: InputDecoration(
            hintText: 'Écrire un message...',
            hintStyle: GoogleFonts.inter(
              fontSize: 14, color: const Color(0xFFCBD5E1)),
            filled: true, fillColor: const Color(0xFFF8FAFC),
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

        // Envoyer
        GestureDetector(
          onTap: _sendMessage,
          child: Container(
            width: 42, height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFF1A56DB),
              shape: BoxShape.circle),
            child: const Icon(Icons.send_rounded,
              color: Colors.white, size: 18))),
      ]),
    ]));

  // ── Accueil messagerie (aucune conv sélectionnée) ────────
  Widget _buildAccueilMessagerie() => Center(
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
    ]));

  // ── Helpers ──────────────────────────────────────────────
  Future<void> _choisirFichier() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx']);
      if (result != null && result.files.isNotEmpty) {
        setState(() => _fichierEnAttente = result.files.first);
      }
    } catch (e) { print('[messagerie] FilePicker: $e'); }
  }

  Future<void> _choisirImage() async {
    final picker = ImagePicker();
    final file   = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _fichierEnAttente = PlatformFile(
        name: file.name, size: bytes.length, bytes: bytes));
    }
  }

  Future<void> _sendMessage() async {
    if (_msgCtrl.text.trim().isEmpty && _fichierEnAttente == null)
      return;
    // ... logique d'envoi identique à la messagerie recruteur
  }

  Future<void> _supprimerMessage(String messageId) async {
    final token = context.read<AuthProvider>().token ?? '';
    await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/messages/$messageId'),
      headers: {'Authorization': 'Bearer $token'});
    await _pollNouveauxMessages();
  }

  void _ouvrirConversation(Map<String, dynamic> conv) {
    setState(() {
      _convActive    = conv;
      _isLoadingMsgs = true;
    });
    _chargerMessages(conv);
  }

  Future<void> _chargerMessages(Map<String, dynamic> conv) async {
    try {
      final token       = context.read<AuthProvider>().token ?? '';
      final autreUserId = conv['autre_user_id'] as String?;
      if (autreUserId == null) return;

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/messages/$autreUserId'),
        headers: {'Authorization': 'Bearer $token'});
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        setState(() {
          _messages      = List<Map<String, dynamic>>.from(
            body['data']['messages'] ?? []);
          _isLoadingMsgs = false;
          // Mettre à jour la photo dans convActive
          final interlocuteur = body['data']['interlocuteur']
              as Map<String, dynamic>?;
          if (interlocuteur != null) {
            _convActive = {
              ..._convActive!,
              'photo': interlocuteur['photo_url'],
              'nom':   interlocuteur['nom'] ?? _convActive!['nom'],
            };
          }
        });
      }
    } catch (e) {
      setState(() => _isLoadingMsgs = false);
    }
  }

  String _fmtDateCourte(String d) {
    try {
      final dt   = DateTime.parse(d).toLocal();
      final now  = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}min';
      if (diff.inHours   < 24) return '${diff.inHours}h';
      if (diff.inDays    < 7)  return '${diff.inDays}j';
      return '${dt.day}/${dt.month}';
    } catch (_) { return ''; }
  }

  void _showNouveauMessage() {
    // Même dialog que la messagerie recruteur
    // pour choisir le destinataire
  }
}
```

---

## 5. Mes Candidatures — Barre d'évolution animée

```dart
// Dans mes_candidatures_page.dart
// Ajouter une barre d'évolution en haut de chaque carte

// Les étapes de progression d'une candidature
class _BarreEvolution extends StatefulWidget {
  final String statut;
  const _BarreEvolution({required this.statut});
  @override
  State<_BarreEvolution> createState() => _BarreEvolutionState();
}

class _BarreEvolutionState extends State<_BarreEvolution>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late Animation<double>   _anim;

  // Étapes dans l'ordre
  static const _etapes = [
    _Etape('Envoyée',   Icons.send_rounded,               Color(0xFF94A3B8)),
    _Etape('En examen', Icons.search_rounded,             Color(0xFF1A56DB)),
    _Etape('Entretien', Icons.event_available_rounded,    Color(0xFF8B5CF6)),
    _Etape('Décision',  Icons.gavel_rounded,              Color(0xFFF59E0B)),
  ];

  // Index de l'étape actuelle selon le statut
  int get _etapeActuelle {
    switch (widget.statut) {
      case 'en_attente': return 0;
      case 'en_cours':   return 1;
      case 'entretien':  return 2;
      case 'acceptee':
      case 'refusee':    return 3;
      default:           return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800));
    _anim = Tween<double>(begin: 0, end: 1)
      .animate(CurvedAnimation(
        parent: _ctrl, curve: Curves.easeOutCubic));
    // Lancer avec un délai
    Future.delayed(const Duration(milliseconds: 300),
      () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final etapeIdx    = _etapeActuelle;
    final isRefusee   = widget.statut == 'refusee';
    final isAcceptee  = widget.statut == 'acceptee';

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(children: [

        // Barre de progression
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            final progress = etapeIdx == 0 ? 0.0
                : (etapeIdx / (_etapes.length - 1)) * _anim.value;
            return ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: isRefusee ? 1.0 * _anim.value : progress,
                minHeight: 4,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation(
                  isRefusee  ? const Color(0xFFEF4444) :
                  isAcceptee ? const Color(0xFF10B981) :
                  const Color(0xFF1A56DB))));
          }),
        const SizedBox(height: 8),

        // Étapes avec icônes
        Row(children: List.generate(_etapes.length, (i) {
          final fait    = i < etapeIdx;
          final enCours = i == etapeIdx && !isRefusee && !isAcceptee;
          final etape   = _etapes[i];

          // Couleur finale pour acceptée/refusée
          Color couleurFinale;
          if (isAcceptee && i == _etapes.length - 1) {
            couleurFinale = const Color(0xFF10B981);
          } else if (isRefusee && i == _etapes.length - 1) {
            couleurFinale = const Color(0xFFEF4444);
          } else {
            couleurFinale = etape.couleur;
          }

          return Expanded(child: Column(children: [
            // Icône étape
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: fait || enCours
                    ? couleurFinale.withOpacity(0.15)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: fait || enCours
                      ? couleurFinale : const Color(0xFFE2E8F0),
                  width: enCours ? 2 : 1)),
              child: Icon(
                fait ? Icons.check_rounded : etape.icon,
                size: 13,
                color: fait || enCours
                    ? couleurFinale : const Color(0xFFCBD5E1))),
            const SizedBox(height: 4),
            // Label
            Text(
              // Remplacer "Décision" par Acceptée/Refusée si final
              i == _etapes.length - 1 && isAcceptee ? 'Acceptée ✓' :
              i == _etapes.length - 1 && isRefusee  ? 'Refusée' :
              etape.label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: enCours || (fait && i == etapeIdx - 1)
                    ? FontWeight.w700 : FontWeight.w400,
                color: fait || enCours
                    ? couleurFinale : const Color(0xFF94A3B8)),
              textAlign: TextAlign.center),
          ]));
        })),
      ]));
  }
}

class _Etape {
  final String label; final IconData icon; final Color couleur;
  const _Etape(this.label, this.icon, this.couleur);
}

// Intégrer dans la carte candidature
// Dans _buildCandidatureCard(), ajouter en bas du contenu :
Column(children: [
  // ... contenu existant (titre, statut, etc.) ...

  // ← Ajouter la barre d'évolution
  _BarreEvolution(statut: statut),
])
```

---

## Critères d'Acceptation

### ✅ Notifications
- [ ] Menu 3 points sur chaque notification
- [ ] Option "Marquer comme lu" (si non lue)
- [ ] Option "Marquer comme non lu" (si lue)
- [ ] Option "Supprimer" avec confirmation
- [ ] Rechargement après action

### ✅ Bouton enregistrer profil
- [ ] Taille modérée (pas toute la largeur)
- [ ] Aligné à droite
- [ ] Indicateur de chargement pendant la sauvegarde

### ✅ Visibilité profil
- [ ] Colonnes `profil_visible` et `recevoir_propositions` en BDD
- [ ] Sauvegarde immédiate au toggle
- [ ] Feedback SnackBar après changement

### ✅ Messagerie candidat
- [ ] Barre de recherche fonctionnelle (filtre en temps réel)
- [ ] Photo de profil dans l'en-tête de conversation
- [ ] Badge rouge + nombre sur chaque conversation
- [ ] Badge total dans la sidebar
- [ ] Bouton pièce jointe + bouton image
- [ ] Long press → supprimer message
- [ ] Polling toutes les 5 secondes

### ✅ Barre d'évolution candidatures
- [ ] 4 étapes : Envoyée → En examen → Entretien → Décision
- [ ] Animation au chargement (0 → position actuelle)
- [ ] Vert si acceptée, rouge si refusée
- [ ] Icônes colorées selon l'étape

---

*PRD EmploiConnect v8.4 — Finitions Espace Candidat*
*Cursor / Kirsoft AI — Phase 17*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
