# PRD — EmploiConnect · Espace Candidat — Design Final
## Product Requirements Document v8.5
**Stack : Flutter + Node.js/Express + Supabase**
**Outil : Cursor / Kirsoft AI**
**Date : Avril 2026**

---

## Table des Matières

1. [Page Paramètres Candidat — Design complet](#1-page-paramètres-candidat--design-complet)
2. [Page Offres Sauvegardées — Design amélioré](#2-page-offres-sauvegardées--design-amélioré)
3. [Page Témoignages & Recrutement — Design amélioré](#3-page-témoignages--recrutement--design-amélioré)
4. [Sidebar Candidat — Couleurs dégradées + effets](#4-sidebar-candidat--couleurs-dégradées--effets)

---

## 1. Page Paramètres Candidat — Design complet

```dart
// frontend/lib/screens/candidat/pages/parametres_candidat_page.dart

class ParametresCandidatPage extends StatefulWidget {
  const ParametresCandidatPage({super.key});
  @override
  State<ParametresCandidatPage> createState() =>
    _ParametresCandidatPageState();
}

class _ParametresCandidatPageState
    extends State<ParametresCandidatPage>
    with SingleTickerProviderStateMixin {

  late TabController _tabCtrl;

  // Données
  String _nom   = '';
  String _email = '';
  String _tel   = '';
  bool   _notifEmail    = true;
  bool   _notifPush     = true;
  bool   _notifCandidatures = true;
  bool   _notifMessages = true;
  bool   _notifOffres   = true;
  String _theme         = 'clair'; // clair | sombre | systeme
  bool   _isSaving      = false;

  // Contrôleurs
  final _nomCtrl         = TextEditingController();
  final _telCtrl         = TextEditingController();
  final _pwdActuelCtrl   = TextEditingController();
  final _pwdNouveauCtrl  = TextEditingController();
  final _pwdConfirmCtrl  = TextEditingController();
  bool _showPwd          = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nomCtrl.dispose(); _telCtrl.dispose();
    _pwdActuelCtrl.dispose(); _pwdNouveauCtrl.dispose();
    _pwdConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/me'),
        headers: {'Authorization': 'Bearer $token'});
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        final prefs = data['preferences_notif']
            as Map<String, dynamic>? ?? {};
        setState(() {
          _nom   = data['nom']       as String? ?? '';
          _email = data['email']     as String? ?? '';
          _tel   = data['telephone'] as String? ?? '';
          _nomCtrl.text = _nom;
          _telCtrl.text = _tel;
          _notifEmail         = prefs['email']         as bool? ?? true;
          _notifPush          = prefs['push']          as bool? ?? true;
          _notifCandidatures  = prefs['candidatures']  as bool? ?? true;
          _notifMessages      = prefs['messages']      as bool? ?? true;
          _notifOffres        = prefs['offres']        as bool? ?? true;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [

      // ── Header ────────────────────────────────────────────
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Paramètres', style: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A))),
          Text('Gérez votre compte et vos préférences',
            style: GoogleFonts.inter(
              fontSize: 13, color: const Color(0xFF64748B))),
          const SizedBox(height: 16),

          // Tabs
          TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            labelStyle: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w400),
            labelColor: const Color(0xFF1A56DB),
            unselectedLabelColor: const Color(0xFF94A3B8),
            indicatorColor: const Color(0xFF1A56DB),
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Compte'),
              Tab(text: 'Notifications'),
              Tab(text: 'Sécurité'),
              Tab(text: 'Apparence'),
            ]),
        ])),
      const Divider(height: 1, color: Color(0xFFE2E8F0)),

      // ── Contenu tabs ──────────────────────────────────────
      Expanded(child: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildTabCompte(),
          _buildTabNotifications(),
          _buildTabSecurite(),
          _buildTabApparence(),
        ])),
    ]);
  }

  // ── Tab Compte ───────────────────────────────────────────
  Widget _buildTabCompte() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(children: [

      // Infos du compte (lecture seule)
      _CarteSection(
        titre: '📋 Informations du compte',
        children: [
          _InfoLecture(
            icon:  Icons.email_outlined,
            label: 'Adresse email',
            value: _email,
            note:  'Non modifiable'),
          const SizedBox(height: 10),
          _InfoLecture(
            icon:  Icons.badge_outlined,
            label: 'Rôle',
            value: 'Chercheur d\'emploi',
            badge: 'Actif'),
        ]),
      const SizedBox(height: 16),

      // Infos modifiables
      _CarteSection(
        titre: '✏️ Modifier mes informations',
        children: [
          _ChampForm(
            ctrl:  _nomCtrl,
            label: 'Nom complet',
            icon:  Icons.person_outline_rounded),
          const SizedBox(height: 12),
          _ChampForm(
            ctrl:  _telCtrl,
            label: 'Téléphone',
            icon:  Icons.phone_outlined,
            keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _BoutonSauvegarder(
            label:    'Mettre à jour',
            isSaving: _isSaving,
            onPressed: _sauvegarderCompte),
        ]),
      const SizedBox(height: 16),

      // Zone danger
      _CarteSection(
        titre: '⚠️ Zone de danger',
        couleurBord: const Color(0xFFEF4444).withOpacity(0.3),
        children: [
          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Supprimer mon compte',
                style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A))),
              Text(
                'Cette action est irréversible. '
                'Toutes vos données seront supprimées.',
                style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF64748B))),
            ])),
            const SizedBox(width: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444)),
                foregroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
              onPressed: _confirmerSuppression,
              child: Text('Supprimer',
                style: GoogleFonts.inter(fontSize: 12))),
          ]),
        ]),
    ]));

  // ── Tab Notifications ────────────────────────────────────
  Widget _buildTabNotifications() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(children: [

      // Canal de notification
      _CarteSection(
        titre: '📡 Canaux de notification',
        children: [
          _ToggleNotif(
            icon:      Icons.email_outlined,
            couleur:   const Color(0xFF1A56DB),
            titre:     'Notifications par email',
            sousTitre: 'Recevoir les alertes par email',
            valeur:    _notifEmail,
            onChanged: (v) {
              setState(() => _notifEmail = v);
              _sauvegarderPreferences();
            }),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _ToggleNotif(
            icon:      Icons.notifications_outlined,
            couleur:   const Color(0xFF8B5CF6),
            titre:     'Notifications push',
            sousTitre: 'Alertes en temps réel sur l\'application',
            valeur:    _notifPush,
            onChanged: (v) {
              setState(() => _notifPush = v);
              _sauvegarderPreferences();
            }),
        ]),
      const SizedBox(height: 16),

      // Types de notifications
      _CarteSection(
        titre: '🔔 Types de notifications',
        children: [
          _ToggleNotif(
            icon:      Icons.assignment_outlined,
            couleur:   const Color(0xFF10B981),
            titre:     'Candidatures',
            sousTitre: 'Statut de vos candidatures',
            valeur:    _notifCandidatures,
            onChanged: (v) {
              setState(() => _notifCandidatures = v);
              _sauvegarderPreferences();
            }),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _ToggleNotif(
            icon:      Icons.chat_bubble_outline_rounded,
            couleur:   const Color(0xFF1A56DB),
            titre:     'Messages',
            sousTitre: 'Nouveaux messages reçus',
            valeur:    _notifMessages,
            onChanged: (v) {
              setState(() => _notifMessages = v);
              _sauvegarderPreferences();
            }),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _ToggleNotif(
            icon:      Icons.work_outline_rounded,
            couleur:   const Color(0xFFF59E0B),
            titre:     'Nouvelles offres',
            sousTitre: 'Offres correspondant à votre profil',
            valeur:    _notifOffres,
            onChanged: (v) {
              setState(() => _notifOffres = v);
              _sauvegarderPreferences();
            }),
        ]),
    ]));

  // ── Tab Sécurité ─────────────────────────────────────────
  Widget _buildTabSecurite() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(children: [

      _CarteSection(
        titre: '🔐 Changer le mot de passe',
        children: [
          _ChampMdp(
            ctrl:  _pwdActuelCtrl,
            label: 'Mot de passe actuel',
            show:  _showPwd,
            onToggle: () => setState(() => _showPwd = !_showPwd)),
          const SizedBox(height: 12),
          _ChampMdp(
            ctrl:  _pwdNouveauCtrl,
            label: 'Nouveau mot de passe',
            show:  _showPwd,
            onToggle: () => setState(() => _showPwd = !_showPwd)),
          const SizedBox(height: 12),
          _ChampMdp(
            ctrl:  _pwdConfirmCtrl,
            label: 'Confirmer le nouveau mot de passe',
            show:  _showPwd,
            onToggle: () => setState(() => _showPwd = !_showPwd)),
          const SizedBox(height: 6),
          // Conseils mot de passe
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Conseils pour un mot de passe sécurisé :',
                style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B))),
              const SizedBox(height: 4),
              ...[
                '✓ Au moins 8 caractères',
                '✓ Lettres majuscules et minuscules',
                '✓ Au moins un chiffre',
                '✓ Au moins un caractère spécial',
              ].map((c) => Text(c, style: GoogleFonts.inter(
                fontSize: 10, color: const Color(0xFF94A3B8)))),
            ])),
          const SizedBox(height: 16),
          _BoutonSauvegarder(
            label:    'Changer le mot de passe',
            isSaving: _isSaving,
            onPressed: _changerMotDePasse),
        ]),
    ]));

  // ── Tab Apparence ────────────────────────────────────────
  Widget _buildTabApparence() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(children: [

      _CarteSection(
        titre: '🎨 Thème de l\'application',
        children: [
          ...[
            _ThemeOption('clair',   '☀️ Thème clair',
              'Interface lumineuse'),
            _ThemeOption('sombre',  '🌙 Thème sombre',
              'Interface sombre, repose les yeux'),
            _ThemeOption('systeme', '⚙️ Suivre le système',
              'S\'adapte automatiquement'),
          ].map((opt) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _theme = opt.valeur);
                context.read<ThemeProvider>().setTheme(opt.valeur);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _theme == opt.valeur
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _theme == opt.valeur
                        ? const Color(0xFF1A56DB)
                        : const Color(0xFFE2E8F0),
                    width: _theme == opt.valeur ? 1.5 : 1)),
                child: Row(children: [
                  Text(opt.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(opt.titre, style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A))),
                    Text(opt.sousTitre, style: GoogleFonts.inter(
                      fontSize: 11, color: const Color(0xFF64748B))),
                  ])),
                  if (_theme == opt.valeur)
                    const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF1A56DB), size: 20),
                ]),
              )))),
        ]),
    ]));

  // ── Sauvegarde ───────────────────────────────────────────
  Future<void> _sauvegarderCompte() async {
    setState(() => _isSaving = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nom': _nomCtrl.text.trim(),
          'telephone': _telCtrl.text.trim(),
        }));
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Informations mises à jour'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _sauvegarderPreferences() async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/users/preferences-notif'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'email':        _notifEmail,
          'push':         _notifPush,
          'candidatures': _notifCandidatures,
          'messages':     _notifMessages,
          'offres':       _notifOffres,
        }));
    } catch (_) {}
  }

  Future<void> _changerMotDePasse() async {
    if (_pwdNouveauCtrl.text != _pwdConfirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Les mots de passe ne correspondent pas'),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/users/mot-de-passe'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'mot_de_passe_actuel': _pwdActuelCtrl.text,
          'nouveau_mot_de_passe': _pwdNouveauCtrl.text,
        }));
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        _pwdActuelCtrl.clear();
        _pwdNouveauCtrl.clear();
        _pwdConfirmCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Mot de passe modifié avec succès'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(body['message'] ?? 'Erreur'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _confirmerSuppression() {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16)),
      title: Text('Supprimer le compte ?',
        style: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w700)),
      content: Text(
        'Cette action est irréversible. '
        'Toutes vos données, candidatures et messages '
        'seront définitivement supprimés.',
        style: GoogleFonts.inter(
          fontSize: 13, color: const Color(0xFF64748B))),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444), elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8))),
          onPressed: () {
            Navigator.pop(context);
            // TODO: Appeler route suppression compte
          },
          child: Text('Supprimer définitivement',
            style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w600))),
      ]));
  }
}

// ── Widgets helpers ──────────────────────────────────────────

class _CarteSection extends StatelessWidget {
  final String titre; final List<Widget> children;
  final Color? couleurBord;
  const _CarteSection({required this.titre,
    required this.children, this.couleurBord});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: couleurBord ?? const Color(0xFFE2E8F0))),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titre, style: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w700,
        color: const Color(0xFF0F172A))),
      const SizedBox(height: 14),
      ...children,
    ]));
}

class _InfoLecture extends StatelessWidget {
  final IconData icon; final String label, value; final String? badge, note;
  const _InfoLecture({required this.icon, required this.label,
    required this.value, this.badge, this.note});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
      const SizedBox(width: 10),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(
          fontSize: 11, color: const Color(0xFF94A3B8))),
        Text(value, style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A))),
      ])),
      if (badge != null)
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(100)),
          child: Text(badge!, style: GoogleFonts.inter(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: const Color(0xFF10B981)))),
      if (note != null)
        Text(note!, style: GoogleFonts.inter(
          fontSize: 10, color: const Color(0xFF94A3B8),
          fontStyle: FontStyle.italic)),
    ]));
}

class _ChampForm extends StatelessWidget {
  final TextEditingController ctrl;
  final String label; final IconData icon;
  final TextInputType? keyboardType;
  const _ChampForm({required this.ctrl, required this.label,
    required this.icon, this.keyboardType});
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18,
        color: const Color(0xFF94A3B8)),
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
          color: Color(0xFF1A56DB), width: 1.5))));
}

class _ChampMdp extends StatelessWidget {
  final TextEditingController ctrl;
  final String label; final bool show;
  final VoidCallback onToggle;
  const _ChampMdp({required this.ctrl, required this.label,
    required this.show, required this.onToggle});
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    obscureText: !show,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18,
        color: Color(0xFF94A3B8)),
      suffixIcon: IconButton(
        icon: Icon(show
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
          size: 18, color: const Color(0xFF94A3B8)),
        onPressed: onToggle),
      filled: true, fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)))));
}

class _BoutonSauvegarder extends StatelessWidget {
  final String label; final bool isSaving;
  final VoidCallback onPressed;
  const _BoutonSauvegarder({required this.label,
    required this.isSaving, required this.onPressed});
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: ElevatedButton.icon(
      icon: isSaving
          ? const SizedBox(width: 14, height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.save_rounded, size: 15),
      label: Text(isSaving ? 'Enregistrement...' : label,
        style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A56DB),
        foregroundColor: Colors.white, elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10))),
      onPressed: isSaving ? null : onPressed));
}

class _ToggleNotif extends StatelessWidget {
  final IconData icon; final Color couleur;
  final String titre, sousTitre; final bool valeur;
  final Function(bool) onChanged;
  const _ToggleNotif({required this.icon, required this.couleur,
    required this.titre, required this.sousTitre,
    required this.valeur, required this.onChanged});
  @override
  Widget build(BuildContext context) => Row(children: [
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
    Switch(value: valeur, onChanged: onChanged,
      activeColor: couleur),
  ]);
}

class _ThemeOption {
  final String valeur, emoji, titre, sousTitre;
  const _ThemeOption(this.valeur, this.emoji,
    this.titre, this.sousTitre) :
    super();
  // Ignorer le warning
  _ThemeOption._(this.valeur, this.emoji, this.titre, this.sousTitre);
}
```

---

## 2. Page Offres Sauvegardées — Design amélioré

```dart
// frontend/lib/screens/candidat/pages/offres_sauvegardees_page.dart

class OffresSauvegardeesPage extends StatefulWidget {
  const OffresSauvegardeesPage({super.key});
  @override
  State<OffresSauvegardeesPage> createState() =>
    _OffresSauvegardeesPageState();
}

class _OffresSauvegardeesPageState
    extends State<OffresSauvegardeesPage> {
  List<Map<String, dynamic>> _offres = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/candidat/offres-sauvegardees'),
        headers: {'Authorization': 'Bearer $token'});
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        setState(() {
          _offres = List<Map<String, dynamic>>.from(
            body['data'] ?? []);
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [

      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        color: Colors.white,
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Offres sauvegardées', style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A))),
            Text('${_offres.length} offre(s) dans vos favoris',
              style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF64748B))),
          ])),
          // Icône bookmark décorative
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.bookmark_rounded,
              color: Color(0xFFF59E0B), size: 22)),
        ])),
      const Divider(height: 1, color: Color(0xFFE2E8F0)),

      // Contenu
      Expanded(child: _isLoading
          ? const Center(child: CircularProgressIndicator(
              color: Color(0xFF1A56DB)))
          : _offres.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFF1A56DB),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _offres.length,
                    itemBuilder: (ctx, i) =>
                      _OffreSauvCard(
                        offre:      _offres[i],
                        onRetirer:  () => _retirer(_offres[i]),
                        onPostuler: () => context.push(
                          '/dashboard-candidat/postuler/${_offres[i]['offre']?['id']}'),
                        onVoir:     () => context.push(
                          '/offres/${_offres[i]['offre']?['id']}'),
                      )))),
    ]);
  }

  Future<void> _retirer(Map<String, dynamic> item) async {
    final offreId = item['offre']?['id'] as String?;
    if (offreId == null) return;
    final token = context.read<AuthProvider>().token ?? '';
    await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/candidat/offres-sauvegardees/$offreId'),
      headers: {'Authorization': 'Bearer $token'});
    setState(() => _offres.remove(item));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Offre retirée des favoris'),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2)));
  }

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFFFEF3C7), shape: BoxShape.circle),
          child: const Icon(Icons.bookmark_border_rounded,
            color: Color(0xFFF59E0B), size: 40)),
        const SizedBox(height: 16),
        Text('Aucune offre sauvegardée',
          style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A))),
        const SizedBox(height: 8),
        Text(
          'Cliquez sur le 🔖 d\'une offre\n'
          'pour la sauvegarder ici.',
          style: GoogleFonts.inter(
            fontSize: 13, color: const Color(0xFF64748B),
            height: 1.5),
          textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.search_rounded, size: 16),
          label: const Text('Parcourir les offres'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10))),
          onPressed: () =>
            context.push('/dashboard-candidat/offres')),
      ])));
}

class _OffreSauvCard extends StatelessWidget {
  final Map<String, dynamic> offre;
  final VoidCallback onRetirer, onPostuler, onVoir;
  const _OffreSauvCard({required this.offre,
    required this.onRetirer, required this.onPostuler,
    required this.onVoir});

  @override
  Widget build(BuildContext context) {
    final data    = offre['offre'] as Map<String, dynamic>? ?? {};
    final ent     = data['entreprise'] as Map? ?? {};
    final titre   = data['titre']       as String? ?? '';
    final nomEnt  = ent['nom_entreprise'] as String? ?? '';
    final logo    = ent['logo_url']     as String?;
    final loc     = data['localisation'] as String? ?? '';
    final contrat = data['type_contrat'] as String? ?? '';
    final score   = offre['score_compatibilite'] as int?;
    final dateSauv = offre['date_sauvegarde'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(
          color: Color(0x06000000), blurRadius: 10,
          offset: Offset(0, 3))]),
      child: Column(children: [

        // Haut de la carte
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            // Logo entreprise
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10)),
              child: logo != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(logo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                          _initLogo(nomEnt)))
                  : _initLogo(nomEnt)),
            const SizedBox(width: 12),

            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Titre + Badge IA
              Row(children: [
                Expanded(child: Text(titre,
                  style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A)),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
                // Badge IA si score disponible
                if (score != null && score > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        const Color(0xFF1A56DB),
                        const Color(0xFF7C3AED),
                      ]),
                      borderRadius: BorderRadius.circular(100)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.auto_awesome_rounded,
                        size: 10, color: Colors.white),
                      const SizedBox(width: 3),
                      Text('$score%', style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w800,
                        color: Colors.white)),
                    ])),
                ],
              ]),
              Text(nomEnt, style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFF1A56DB))),
            ])),
          ])),

        // Infos
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(children: [
            if (loc.isNotEmpty) ...[
              const Icon(Icons.location_on_outlined,
                size: 12, color: Color(0xFF94A3B8)),
              const SizedBox(width: 3),
              Text(loc, style: GoogleFonts.inter(
                fontSize: 11, color: const Color(0xFF94A3B8))),
              const SizedBox(width: 10),
            ],
            if (contrat.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(100)),
                child: Text(contrat, style: GoogleFonts.inter(
                  fontSize: 10, color: const Color(0xFF1A56DB),
                  fontWeight: FontWeight.w500))),
            const Spacer(),
            if (dateSauv != null)
              Text('Sauvegardée ${_fmtDate(dateSauv)}',
                style: GoogleFonts.inter(
                  fontSize: 10, color: const Color(0xFF94A3B8))),
          ])),

        // Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Row(children: [
            // Retirer des favoris
            GestureDetector(
              onTap: onRetirer,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.bookmark_remove_rounded,
                    size: 14, color: Color(0xFFEF4444)),
                  const SizedBox(width: 4),
                  Text('Retirer', style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF4444))),
                ]))),
            const SizedBox(width: 8),

            // Voir l'offre
            Expanded(child: OutlinedButton.icon(
              icon: const Icon(Icons.visibility_outlined, size: 14),
              label: const Text('Voir'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                foregroundColor: const Color(0xFF64748B),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
                textStyle: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600)),
              onPressed: onVoir)),
            const SizedBox(width: 8),

            // Postuler
            Expanded(child: ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, size: 14),
              label: const Text('Postuler'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
                textStyle: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600)),
              onPressed: onPostuler)),
          ])),
      ]));
  }

  Widget _initLogo(String nom) => Center(child: Text(
    nom.isNotEmpty ? nom[0].toUpperCase() : '?',
    style: GoogleFonts.poppins(
      fontSize: 18, fontWeight: FontWeight.w700,
      color: const Color(0xFF1A56DB))));

  String _fmtDate(String d) {
    try {
      final dt   = DateTime.parse(d).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays == 0) return 'aujourd\'hui';
      if (diff.inDays == 1) return 'hier';
      return 'il y a ${diff.inDays}j';
    } catch (_) { return ''; }
  }
}
```

---

## 3. Page Témoignages & Recrutement — Design amélioré

```dart
// frontend/lib/screens/candidat/pages/temoignages_page.dart

class TemoignagesPage extends StatefulWidget {
  const TemoignagesPage({super.key});
  @override
  State<TemoignagesPage> createState() => _TemoignagesPageState();
}

class _TemoignagesPageState extends State<TemoignagesPage> {
  List<Map<String, dynamic>> _temoignages = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Formulaire
  final _contenuCtrl = TextEditingController();
  int    _note       = 5;
  String _type       = 'candidat'; // candidat | recruteur

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse(
        '${ApiConfig.baseUrl}/api/temoignages'));
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        setState(() {
          _temoignages = List<Map<String, dynamic>>.from(
            body['data'] ?? []);
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(children: [

        // ── Hero section ────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)]),
            borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            const Icon(Icons.star_rounded,
              color: Colors.white, size: 40),
            const SizedBox(height: 12),
            Text('Témoignages & Recrutement',
              style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.w800,
                color: Colors.white),
              textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Partagez votre expérience sur EmploiConnect '
              'et aidez les autres candidats.',
              style: GoogleFonts.inter(
                fontSize: 13, color: Colors.white70,
                height: 1.5),
              textAlign: TextAlign.center),
            const SizedBox(height: 16),
            // Stats rapides
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _StatTemoignage('${_temoignages.length}', 'Témoignages'),
              const SizedBox(width: 24),
              _StatTemoignage(
                _temoignages.isEmpty ? '—'
                    : (_temoignages.map((t) =>
                        t['note'] as int? ?? 0).reduce((a, b) => a + b) /
                        _temoignages.length).toStringAsFixed(1),
                'Note moyenne'),
            ]),
          ])),
        const SizedBox(height: 20),

        // ── Formulaire nouveau témoignage ────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('✍️ Partager mon expérience',
              style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A))),
            const SizedBox(height: 14),

            // Type
            Row(children: [
              Expanded(child: _TypeBtn(
                'candidat', '👤 Candidat', _type,
                (v) => setState(() => _type = v))),
              const SizedBox(width: 8),
              Expanded(child: _TypeBtn(
                'recruteur', '🏢 Recruteur', _type,
                (v) => setState(() => _type = v))),
            ]),
            const SizedBox(height: 14),

            // Note étoiles
            Text('Note', style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: const Color(0xFF374151))),
            const SizedBox(height: 6),
            Row(children: List.generate(5, (i) =>
              GestureDetector(
                onTap: () => setState(() => _note = i + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    i < _note
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: i < _note
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFE2E8F0),
                    size: 30))))),
            const SizedBox(height: 14),

            // Texte
            TextFormField(
              controller: _contenuCtrl,
              maxLines: 4, maxLength: 500,
              decoration: InputDecoration(
                hintText:
                  'Décrivez votre expérience avec EmploiConnect...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFFCBD5E1)),
                filled: true, fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0))))),
            const SizedBox(height: 14),

            // Bouton envoyer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isSubmitting
                    ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  _isSubmitting
                      ? 'Envoi...' : 'Soumettre le témoignage',
                  style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56DB),
                  foregroundColor: Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
                onPressed: _isSubmitting ? null : _soumettre)),
          ])),
        const SizedBox(height: 20),

        // ── Liste témoignages ────────────────────────────────
        if (_isLoading)
          const Center(child: CircularProgressIndicator(
            color: Color(0xFF1A56DB)))
        else if (_temoignages.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(
              'Soyez le premier à partager votre expérience !',
              style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF94A3B8)))))
        else ...[
          Row(children: [
            Text('${_temoignages.length} témoignage(s)',
              style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A))),
          ]),
          const SizedBox(height: 12),
          ..._temoignages.map((t) => _TemoignageCard(temoignage: t)),
        ],
      ]));
  }

  Future<void> _soumettre() async {
    if (_contenuCtrl.text.trim().length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Minimum 20 caractères requis'),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/temoignages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'contenu': _contenuCtrl.text.trim(),
          'note':    _note,
          'type':    _type,
        }));
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        _contenuCtrl.clear();
        setState(() => _note = 5);
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            '✅ Merci ! Votre témoignage est en attente de validation.'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating));
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}

class _TemoignageCard extends StatelessWidget {
  final Map<String, dynamic> temoignage;
  const _TemoignageCard({required this.temoignage});

  @override
  Widget build(BuildContext context) {
    final user    = temoignage['auteur'] as Map? ?? {};
    final nom     = user['nom']       as String? ?? 'Anonyme';
    final photo   = user['photo_url'] as String?;
    final note    = temoignage['note']    as int? ?? 5;
    final contenu = temoignage['contenu'] as String? ?? '';
    final date    = temoignage['date_creation'] as String?;
    final type    = temoignage['type']    as String? ?? 'candidat';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF1A56DB).withOpacity(0.1),
            backgroundImage: photo != null
                ? NetworkImage(photo) : null,
            child: photo == null ? Text(
              nom[0].toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: const Color(0xFF1A56DB))) : null),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nom, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A))),
            Row(children: [
              // Étoiles
              ...List.generate(5, (i) => Icon(
                i < note
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: i < note
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFE2E8F0),
                size: 14)),
              const SizedBox(width: 6),
              // Badge type
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: type == 'recruteur'
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(100)),
                child: Text(
                  type == 'recruteur' ? '🏢 Recruteur' : '👤 Candidat',
                  style: GoogleFonts.inter(
                    fontSize: 9, fontWeight: FontWeight.w600,
                    color: type == 'recruteur'
                        ? const Color(0xFF1A56DB)
                        : const Color(0xFF10B981)))),
            ]),
          ])),
          if (date != null)
            Text(_fmtDate(date), style: GoogleFonts.inter(
              fontSize: 10, color: const Color(0xFF94A3B8))),
        ]),
        const SizedBox(height: 10),
        // Contenu
        Text(contenu, style: GoogleFonts.inter(
          fontSize: 13, color: const Color(0xFF374151),
          height: 1.5)),
      ]));
  }

  String _fmtDate(String d) {
    try {
      final dt   = DateTime.parse(d).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays < 30) return 'Il y a ${diff.inDays}j';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return ''; }
  }
}

class _StatTemoignage extends StatelessWidget {
  final String value, label;
  const _StatTemoignage(this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: GoogleFonts.poppins(
      fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
    Text(label, style: GoogleFonts.inter(
      fontSize: 11, color: Colors.white70)),
  ]);
}

class _TypeBtn extends StatelessWidget {
  final String valeur, label, selected;
  final void Function(String) onTap;
  const _TypeBtn(this.valeur, this.label, this.selected, this.onTap);
  @override
  Widget build(BuildContext context) {
    final isSel = valeur == selected;
    return GestureDetector(
      onTap: () => onTap(valeur),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSel ? const Color(0xFF1A56DB) : const Color(0xFFE2E8F0))),
        child: Text(label, style: GoogleFonts.inter(
          fontSize: 12, fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
          color: isSel ? const Color(0xFF1A56DB) : const Color(0xFF64748B)),
          textAlign: TextAlign.center)));
  }
}
```

---

## 4. Sidebar Candidat — Couleurs dégradées + effets

```dart
// frontend/lib/screens/candidat/candidat_sidebar.dart
// Remplacer le fond actuel par un dégradé bleu élégant

class CandidatSidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final route = GoRouterState.of(context).uri.path;

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        // ← Dégradé bleu profond — cohérent avec recruteur et admin
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [
            Color(0xFF0D1B3E), // Bleu marine profond
            Color(0xFF1A2F5E), // Bleu nuit saturé
          ]),
        boxShadow: [BoxShadow(
          color: Color(0x30000000), blurRadius: 20,
          offset: Offset(4, 0))],
      ),
      child: Column(children: [

        // ── Logo + Titre ──────────────────────────────────────
        _buildLogoSection(context),

        // ── Navigation ───────────────────────────────────────
        Expanded(child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 8),
          children: [
            _section('PRINCIPAL', [
              _item(context, Icons.dashboard_rounded,
                'Vue d\'ensemble',
                '/dashboard-candidat', route),
              _item(context, Icons.search_rounded,
                'Recherche d\'offres',
                '/dashboard-candidat/offres', route),
              _item(context, Icons.auto_awesome_rounded,
                'Recommandations IA',
                '/dashboard-candidat/recommandations', route),
              _item(context, Icons.assignment_outlined,
                'Mes candidatures',
                '/dashboard-candidat/candidatures', route,
                badge: _getBadge(context, 'candidatures')),
              _item(context, Icons.bookmark_outline_rounded,
                'Offres sauvegardées',
                '/dashboard-candidat/sauvegardes', route),
            ]),
            _section('MON PROFIL', [
              _item(context, Icons.person_outline_rounded,
                'Mon Profil & CV',
                '/dashboard-candidat/profil', route),
              _item(context, Icons.star_outline_rounded,
                'Témoignages',
                '/dashboard-candidat/temoignages', route),
            ]),
            _section('COMMUNICATION', [
              _item(context, Icons.chat_bubble_outline_rounded,
                'Messagerie',
                '/dashboard-candidat/messages', route,
                badge: _getBadge(context, 'messages')),
              _item(context, Icons.notifications_outlined,
                'Notifications',
                '/dashboard-candidat/notifications', route,
                badge: _getBadge(context, 'notifications')),
            ]),
            _section('COMPTE', [
              _item(context, Icons.settings_outlined,
                'Paramètres',
                '/dashboard-candidat/parametres', route),
            ]),
          ])),

        // ── Profil candidat en bas ────────────────────────────
        _buildProfilBas(context),
      ]));
  }

  Widget _buildLogoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(
          color: Color(0x20FFFFFF)))),
      child: Row(children: [
        // Logo grand, sans fond rond/carré
        Consumer<AppConfigProvider>(
          builder: (ctx, cfg, _) => cfg.logoUrl.isNotEmpty
              ? Image.network(
                  cfg.logoUrl,
                  height: 44, // ← Grand
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                  errorBuilder: (_, __, ___) => _logoTexte())
              : _logoTexte()),
        const Spacer(),
        // Badge "Candidat"
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: const Color(0xFF10B981).withOpacity(0.4))),
          child: Text('Candidat', style: GoogleFonts.inter(
            fontSize: 9, fontWeight: FontWeight.w700,
            color: const Color(0xFF34D399)))),
      ]));
  }

  Widget _logoTexte() => Text('EmploiConnect',
    style: GoogleFonts.poppins(
      fontSize: 15, fontWeight: FontWeight.w800,
      color: Colors.white));

  Widget _section(String titre, List<Widget> items) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
        child: Text(titre, style: GoogleFonts.inter(
          fontSize: 9, fontWeight: FontWeight.w700,
          color: const Color(0xFF475569),
          letterSpacing: 0.8))),
      ...items,
    ]);

  Widget _item(
    BuildContext ctx, IconData icon, String label,
    String route, String currentRoute, {int? badge}
  ) {
    final isActive = currentRoute == route ||
        (route != '/dashboard-candidat' &&
         currentRoute.startsWith(route));

    return MouseRegion(
      // Effet hover sur le web
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => ctx.go(route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF1A56DB)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF3B82F6).withOpacity(0.4)
                  : Colors.transparent)),
          child: Row(children: [
            Icon(icon, size: 17,
              color: isActive
                  ? Colors.white : const Color(0xFF94A3B8)),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isActive
                  ? FontWeight.w600 : FontWeight.w400,
              color: isActive
                  ? Colors.white : const Color(0xFFCBD5E1)))),
            if (badge != null && badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withOpacity(0.25)
                      : const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(100)),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w800,
                    color: Colors.white))),
          ])),
      ));
  }

  Widget _buildProfilBas(BuildContext context) {
    return Consumer<CandidatProvider>(
      builder: (ctx, provider, _) {
        final nom   = provider.nomCandidat   ?? 'Candidat';
        final photo = provider.photoCandidat;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(
              color: Color(0x20FFFFFF)))),
          child: Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF1A56DB),
              backgroundImage: photo != null
                  ? NetworkImage(photo) : null,
              child: photo == null ? Text(
                nom.isNotEmpty ? nom[0].toUpperCase() : 'C',
                style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w700)) : null),
            const SizedBox(width: 8),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nom, style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: Colors.white),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('Espace Candidat', style: GoogleFonts.inter(
                fontSize: 9, color: const Color(0xFF64748B))),
            ])),
            // Bouton déconnexion
            GestureDetector(
              onTap: () {
                context.read<AuthProvider>().logout();
                context.go('/connexion');
              },
              child: Tooltip(
                message: 'Se déconnecter',
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.logout_rounded,
                    color: Color(0xFFEF4444), size: 14)))),
          ]));
      });
  }

  int? _getBadge(BuildContext context, String type) {
    try {
      final p = context.watch<CandidatProvider>();
      switch (type) {
        case 'messages':      return p.nbMessages      > 0 ? p.nbMessages      : null;
        case 'notifications': return p.nbNotifications > 0 ? p.nbNotifications : null;
        case 'candidatures':  return null; // Optionnel
        default: return null;
      }
    } catch (_) { return null; }
  }
}
```

---

## Critères d'Acceptation

### ✅ Paramètres Candidat
- [ ] 4 onglets : Compte / Notifications / Sécurité / Apparence
- [ ] Email en lecture seule (non modifiable)
- [ ] Toggles notifications avec sauvegarde immédiate
- [ ] Changer mot de passe avec validation
- [ ] Choix thème : Clair / Sombre / Système
- [ ] Zone danger avec confirmation suppression compte

### ✅ Offres Sauvegardées
- [ ] Badge IA avec score % en gradient sur chaque carte
- [ ] 3 boutons : Retirer / Voir / Postuler
- [ ] Date de sauvegarde affichée
- [ ] Page vide avec invitation à parcourir les offres

### ✅ Témoignages
- [ ] Hero section avec stats (nb témoignages + note moyenne)
- [ ] Formulaire : type (Candidat/Recruteur) + étoiles + texte
- [ ] Liste témoignages avec avatar + étoiles + badge type
- [ ] Message de confirmation après soumission

### ✅ Sidebar Candidat
- [ ] Fond dégradé #0D1B3E → #1A2F5E
- [ ] Logo grand (44px) sans fond carré/rond
- [ ] Badge "Candidat" vert en haut à droite
- [ ] Items actifs : fond bleu #1A56DB
- [ ] Hover : curseur pointer sur web
- [ ] Badges rouges sur messages + notifications
- [ ] Profil + bouton déconnexion en bas

---

*PRD EmploiConnect v8.5 — Design Final Espace Candidat*
*Cursor / Kirsoft AI — Phase 18*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
