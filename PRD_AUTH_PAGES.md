# PRD — EmploiConnect · Pages Connexion & Inscription
## Product Requirements Document v9.4
**Stack : Flutter Web + Mobile**
**Outil : Cursor / Kirsoft AI**
**Date : Avril 2026**

---

## Vision

```
OBJECTIF :
Pages de connexion et d'inscription professionnelles,
cohérentes avec le design de la homepage.
Intuitives, animées, responsives mobile et desktop.

DESIGN :
→ Gauche : illustration animée + témoignages + stats
→ Droite : formulaire propre et complet
→ Cohérent avec la homepage (mêmes couleurs, polices)
→ Google OAuth déjà intégré → l'afficher clairement
```

---

## Table des Matières

1. [Page Connexion](#1-page-connexion)
2. [Page Inscription Candidat](#2-page-inscription-candidat)
3. [Page Inscription Recruteur](#3-page-inscription-recruteur)
4. [Composants partagés](#4-composants-partagés)

---

## 1. Page Connexion

```dart
// frontend/lib/screens/auth/login_screen.dart
// REMPLACER entièrement

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  final _emailCtrl  = TextEditingController();
  final _mdpCtrl    = TextEditingController();
  final _formKey    = GlobalKey<FormState>();
  bool  _mdpVisible = false;
  bool  _isLoading  = false;
  bool  _isGoogleLoading = false;
  String? _erreur;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 800));
    _fadeAnim  = Tween<double>(begin: 0, end: 1)
      .animate(CurvedAnimation(
        parent: _animCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1), end: Offset.zero)
      .animate(CurvedAnimation(
        parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _mdpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: isMobile
          ? _buildMobile()
          : _buildDesktop());
  }

  // ── VERSION DESKTOP ─────────────────────────────────────
  Widget _buildDesktop() => Row(children: [

    // ── Panneau gauche illustré ────────────────────
    Expanded(
      flex: 5,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A56DB),
              Color(0xFF2563EB),
              Color(0xFF4F46E5),
            ])),
        child: SafeArea(child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

            // Logo
            _LogoHeader(couleurTexte: Colors.white),
            const SizedBox(height: 48),

            // Titre principal
            Text(
              'Bon retour\nparmi nous !',
              style: GoogleFonts.poppins(
                fontSize: 40, fontWeight: FontWeight.w900,
                color: Colors.white, height: 1.1)),
            const SizedBox(height: 16),
            Text(
              'Connectez-vous pour accéder à vos '
              'opportunités professionnelles.',
              style: GoogleFonts.inter(
                fontSize: 16, color: Colors.white70,
                height: 1.6)),
            const SizedBox(height: 40),

            // Stats rapides
            _StatsRapides(),
            const Spacer(),

            // Témoignage
            _TemoignageMini(),
          ])))),

    // ── Panneau droite formulaire ──────────────────
    Expanded(
      flex: 4,
      child: Center(child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(40),
            child: _buildFormulaire()))))),
  ]);

  // ── VERSION MOBILE ───────────────────────────────────────
  Widget _buildMobile() => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 20),
        _LogoHeader(),
        const SizedBox(height: 32),
        _buildFormulaire(),
      ])));

  // ── FORMULAIRE ───────────────────────────────────────────
  Widget _buildFormulaire() => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Titre
      Text('Connexion',
        style: GoogleFonts.poppins(
          fontSize: 28, fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A))),
      const SizedBox(height: 6),
      RichText(text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: 14, color: const Color(0xFF64748B)),
        children: [
        const TextSpan(text: 'Nouveau sur EmploiConnect ? '),
        WidgetSpan(child: GestureDetector(
          onTap: () => context.push('/register'),
          child: Text('Créer un compte',
            style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: const Color(0xFF1A56DB))))),
      ])),
      const SizedBox(height: 28),

      // Bouton Google
      _BoutonGoogle(
        label:    'Continuer avec Google',
        isLoading: _isGoogleLoading,
        onTap:    () => _connecterGoogle()),
      const SizedBox(height: 16),

      // Séparateur
      _Separateur(texte: 'ou se connecter avec email'),
      const SizedBox(height: 16),

      // Erreur
      if (_erreur != null) ...[
        _CarteErreur(message: _erreur!),
        const SizedBox(height: 14),
      ],

      // Email
      _ChampEmail(ctrl: _emailCtrl),
      const SizedBox(height: 14),

      // Mot de passe
      _ChampMotDePasse(
        ctrl:      _mdpCtrl,
        visible:   _mdpVisible,
        onToggle:  () =>
          setState(() => _mdpVisible = !_mdpVisible)),
      const SizedBox(height: 8),

      // Mot de passe oublié
      Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: () => context.push('/forgot-password'),
          child: Text('Mot de passe oublié ?',
            style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: const Color(0xFF1A56DB))))),
      const SizedBox(height: 24),

      // Bouton connexion
      _BoutonPrincipal(
        label:     'Se connecter',
        isLoading: _isLoading,
        onTap:     _seConnecter),
      const SizedBox(height: 20),

      // Liens inscription
      Center(child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        children: [
        GestureDetector(
          onTap: () => context.push('/register?role=candidat'),
          child: Text('Créer un compte Candidat',
            style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFF64748B)))),
        Text('·', style: GoogleFonts.inter(
          fontSize: 12, color: const Color(0xFFCBD5E1))),
        GestureDetector(
          onTap: () => context.push('/register?role=recruteur'),
          child: Text('Créer un compte Recruteur',
            style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFF64748B)))),
      ])),
    ]));

  Future<void> _seConnecter() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _erreur = null; });
    try {
      final result = await context.read<AuthProvider>()
        .login(_emailCtrl.text.trim(), _mdpCtrl.text);
      if (!result.success && mounted) {
        setState(() => _erreur = result.message);
      }
    } catch (e) {
      setState(() => _erreur = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _connecterGoogle() async {
    setState(() { _isGoogleLoading = true; _erreur = null; });
    try {
      await context.read<AuthProvider>().loginWithGoogle();
    } catch (e) {
      setState(() => _erreur = 'Erreur Google: $e');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }
}
```

---

## 2. Page Inscription Candidat

```dart
// frontend/lib/screens/auth/register_screen.dart
// Version complète avec sélection de rôle

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {

  // État
  String? _roleChoisi; // null | 'chercheur' | 'entreprise'
  int     _etape = 1;  // 1 = choix rôle, 2 = formulaire

  // Formulaire
  final _formKey    = GlobalKey<FormState>();
  final _nomCtrl    = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _mdpCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  // Champs recruteur
  final _entrepriseCtrl = TextEditingController();
  final _posteCtrl      = TextEditingController();

  bool   _mdpVisible     = false;
  bool   _confirmVisible = false;
  bool   _accepteCGU     = false;
  bool   _isLoading      = false;
  bool   _isGoogleLoading = false;
  String? _erreur;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 500));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
      .animate(CurvedAnimation(
        parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nomCtrl.dispose(); _emailCtrl.dispose();
    _mdpCtrl.dispose(); _confirmCtrl.dispose();
    _entrepriseCtrl.dispose(); _posteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: isMobile
          ? _buildMobile()
          : _buildDesktop());
  }

  Widget _buildDesktop() => Row(children: [

    // ── Panneau gauche ─────────────────────────────
    Expanded(
      flex: 5,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A56DB),
              Color(0xFF7C3AED),
            ])),
        child: SafeArea(child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            _LogoHeader(couleurTexte: Colors.white),
            const SizedBox(height: 48),
            Text(
              'Votre carrière\ncommence ici.',
              style: GoogleFonts.poppins(
                fontSize: 40, fontWeight: FontWeight.w900,
                color: Colors.white, height: 1.1)),
            const SizedBox(height: 16),
            Text(
              'Rejoignez des milliers de professionnels '
              'guinéens qui ont trouvé leur voie.',
              style: GoogleFonts.inter(
                fontSize: 16, color: Colors.white70,
                height: 1.6)),
            const SizedBox(height: 40),
            _AvantagesListe(),
            const Spacer(),
            _TemoignageMini(),
          ])))),

    // ── Panneau droite ─────────────────────────────
    Expanded(
      flex: 4,
      child: SingleChildScrollView(
        child: Center(child: FadeTransition(
          opacity: _fadeAnim,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.symmetric(
              horizontal: 40, vertical: 48),
            child: _etape == 1
                ? _buildChoixRole()
                : _buildFormulaire()))))),
  ]);

  Widget _buildMobile() => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 16),
        _LogoHeader(),
        const SizedBox(height: 28),
        _etape == 1
            ? _buildChoixRole()
            : _buildFormulaire(),
      ])));

  // ── ÉTAPE 1 : Choix du rôle ──────────────────────────────
  Widget _buildChoixRole() => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [

    Text('Créer un compte',
      style: GoogleFonts.poppins(
        fontSize: 28, fontWeight: FontWeight.w800,
        color: const Color(0xFF0F172A))),
    const SizedBox(height: 6),
    RichText(text: TextSpan(
      style: GoogleFonts.inter(
        fontSize: 14, color: const Color(0xFF64748B)),
      children: [
      const TextSpan(text: 'Déjà inscrit ? '),
      WidgetSpan(child: GestureDetector(
        onTap: () => context.push('/login'),
        child: Text('Se connecter',
          style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: const Color(0xFF1A56DB))))),
    ])),
    const SizedBox(height: 32),

    Text('Je souhaite...',
      style: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w700,
        color: const Color(0xFF374151))),
    const SizedBox(height: 12),

    // Cartes choix rôle
    Row(children: [
      Expanded(child: _CarteRole(
        emoji:   '👤',
        titre:   'Trouver un emploi',
        desc:    'Candidat · Chercheur d\'emploi',
        couleur: const Color(0xFF1A56DB),
        isSelected: _roleChoisi == 'chercheur',
        onTap: () => setState(() => _roleChoisi = 'chercheur'))),
      const SizedBox(width: 12),
      Expanded(child: _CarteRole(
        emoji:   '🏢',
        titre:   'Recruter des talents',
        desc:    'Recruteur · Entreprise',
        couleur: const Color(0xFF8B5CF6),
        isSelected: _roleChoisi == 'entreprise',
        onTap: () => setState(() => _roleChoisi = 'entreprise'))),
    ]),
    const SizedBox(height: 24),

    // Bouton Google (si rôle choisi)
    AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: _roleChoisi != null
          ? Column(children: [
              _BoutonGoogle(
                label: 'S\'inscrire avec Google',
                isLoading: _isGoogleLoading,
                onTap: () => _inscrireGoogle()),
              const SizedBox(height: 12),
              _Separateur(texte: 'ou créer un compte'),
              const SizedBox(height: 12),
            ])
          : const SizedBox()),

    // Bouton continuer
    _BoutonPrincipal(
      label:     'Continuer →',
      isLoading: false,
      couleur:   _roleChoisi != null
          ? const Color(0xFF1A56DB)
          : const Color(0xFFCBD5E1),
      onTap:     _roleChoisi != null
          ? () {
              _animCtrl.forward(from: 0);
              setState(() => _etape = 2);
            }
          : null),
    const SizedBox(height: 16),

    // Lien admin
    Center(child: GestureDetector(
      onTap: () {
        setState(() {
          _roleChoisi = 'admin';
          _etape = 2;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE2E8F0))),
        child: Text(
          '🔐 Compte administrateur (email uniquement)',
          style: GoogleFonts.inter(
            fontSize: 12, color: const Color(0xFF94A3B8)))))),
  ]);

  // ── ÉTAPE 2 : Formulaire ─────────────────────────────────
  Widget _buildFormulaire() => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Retour
      GestureDetector(
        onTap: () {
          _animCtrl.forward(from: 0);
          setState(() => _etape = 1);
        },
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.arrow_back_rounded,
            size: 16, color: Color(0xFF1A56DB)),
          const SizedBox(width: 4),
          Text('Retour',
            style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: const Color(0xFF1A56DB))),
        ])),
      const SizedBox(height: 16),

      // Titre + badge rôle
      Row(children: [
        Expanded(child: Text(
          _roleChoisi == 'entreprise'
              ? 'Compte Recruteur'
              : _roleChoisi == 'admin'
                  ? 'Compte Admin'
                  : 'Compte Candidat',
          style: GoogleFonts.poppins(
            fontSize: 24, fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A)))),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _couleurRole.withOpacity(0.1),
            borderRadius: BorderRadius.circular(100)),
          child: Text(
            _roleChoisi == 'entreprise'
                ? '🏢 Recruteur'
                : _roleChoisi == 'admin'
                    ? '🔐 Admin'
                    : '👤 Candidat',
            style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: _couleurRole))),
      ]),
      const SizedBox(height: 24),

      // Erreur
      if (_erreur != null) ...[
        _CarteErreur(message: _erreur!),
        const SizedBox(height: 14),
      ],

      // Champ nom
      _ChampFormulaire(
        ctrl:        _nomCtrl,
        label:       'Nom complet *',
        hint:        'Ex: Mamadou Barry',
        icone:       Icons.person_outline_rounded,
        validator:   (v) => v == null || v.trim().length < 2
            ? 'Nom trop court' : null),
      const SizedBox(height: 12),

      // Champ entreprise (si recruteur)
      if (_roleChoisi == 'entreprise') ...[
        _ChampFormulaire(
          ctrl:      _entrepriseCtrl,
          label:     'Nom de l\'entreprise *',
          hint:      'Ex: TechGuinée SARL',
          icone:     Icons.business_outlined,
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Champ requis' : null),
        const SizedBox(height: 12),
        _ChampFormulaire(
          ctrl:  _posteCtrl,
          label: 'Votre poste',
          hint:  'Ex: Directeur RH',
          icone: Icons.work_outline_rounded),
        const SizedBox(height: 12),
      ],

      // Email
      _ChampEmail(ctrl: _emailCtrl),
      const SizedBox(height: 12),

      // Mot de passe
      _ChampMotDePasse(
        ctrl:     _mdpCtrl,
        label:    'Mot de passe *',
        visible:  _mdpVisible,
        onToggle: () =>
          setState(() => _mdpVisible = !_mdpVisible)),
      const SizedBox(height: 4),
      // Indicateur force mot de passe
      _ForceMotDePasse(mdp: _mdpCtrl.text),
      const SizedBox(height: 12),

      // Confirmation
      _ChampMotDePasse(
        ctrl:     _confirmCtrl,
        label:    'Confirmer le mot de passe *',
        visible:  _confirmVisible,
        onToggle: () =>
          setState(() => _confirmVisible = !_confirmVisible),
        validator: (v) => v != _mdpCtrl.text
            ? 'Les mots de passe ne correspondent pas'
            : null),
      const SizedBox(height: 16),

      // Accepter CGU
      Row(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Checkbox(
          value: _accepteCGU,
          activeColor: const Color(0xFF1A56DB),
          onChanged: (v) =>
            setState(() => _accepteCGU = v ?? false)),
        Expanded(child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: RichText(text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFF64748B)),
            children: [
            const TextSpan(
              text: 'J\'accepte les '),
            WidgetSpan(child: GestureDetector(
              onTap: () {},
              child: Text('Conditions d\'utilisation',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A56DB))))),
            const TextSpan(text: ' et la '),
            WidgetSpan(child: GestureDetector(
              onTap: () {},
              child: Text(
                'Politique de confidentialité',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A56DB))))),
          ])))),
      ]),
      const SizedBox(height: 20),

      // Bouton créer compte
      _BoutonPrincipal(
        label:     'Créer mon compte',
        isLoading: _isLoading,
        onTap:     _accepteCGU ? _creerCompte : null,
        couleur:   _accepteCGU
            ? const Color(0xFF1A56DB)
            : const Color(0xFFCBD5E1)),
    ]));

  Color get _couleurRole {
    if (_roleChoisi == 'entreprise') return const Color(0xFF8B5CF6);
    if (_roleChoisi == 'admin')      return const Color(0xFFEF4444);
    return const Color(0xFF1A56DB);
  }

  Future<void> _creerCompte() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _erreur = null; });
    try {
      final result = await context.read<AuthProvider>()
        .register(
          nom:         _nomCtrl.text.trim(),
          email:       _emailCtrl.text.trim(),
          mdp:         _mdpCtrl.text,
          role:        _roleChoisi ?? 'chercheur',
          entreprise:  _entrepriseCtrl.text.trim(),
          poste:       _posteCtrl.text.trim());
      if (!result.success && mounted) {
        setState(() => _erreur = result.message);
      }
    } catch (e) {
      setState(() => _erreur = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _inscrireGoogle() async {
    setState(() { _isGoogleLoading = true; _erreur = null; });
    try {
      await context.read<AuthProvider>()
        .loginWithGoogle(role: _roleChoisi);
    } catch (e) {
      setState(() => _erreur = 'Erreur Google: $e');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }
}
```

---

## 4. Composants partagés

```dart
// frontend/lib/screens/auth/widgets/auth_widgets.dart

// ── Logo Header ──────────────────────────────────────────
class _LogoHeader extends StatelessWidget {
  final Color couleurTexte;
  const _LogoHeader({
    this.couleurTexte = const Color(0xFF0F172A)});

  @override
  Widget build(BuildContext context) => Row(children: [
    GestureDetector(
      onTap: () => context.go('/'),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A56DB), Color(0xFF7C3AED)]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(
              color: const Color(0xFF1A56DB).withOpacity(0.3),
              blurRadius: 10, offset: const Offset(0, 4))]),
          child: const Center(child: Text('E',
            style: TextStyle(
              color: Colors.white, fontSize: 20,
              fontWeight: FontWeight.w900)))),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text('EmploiConnect',
            style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w800,
              color: couleurTexte)),
          Text('Guinée',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: couleurTexte.withOpacity(0.5))),
        ]),
      ])),
  ]);
}

// ── Bouton Google ────────────────────────────────────────
class _BoutonGoogle extends StatelessWidget {
  final String label; final bool isLoading;
  final VoidCallback? onTap;
  const _BoutonGoogle({required this.label,
    required this.isLoading, this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
        elevation: 0),
      onPressed: isLoading ? null : onTap,
      child: isLoading
          ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF4285F4)))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              // Logo G
              Container(
                width: 20, height: 20,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle),
                child: Center(child: Text('G',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4285F4))))),
              const SizedBox(width: 10),
              Text(label, style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w500,
                color: const Color(0xFF374151))),
            ])));
}

// ── Bouton principal ─────────────────────────────────────
class _BoutonPrincipal extends StatelessWidget {
  final String label; final bool isLoading;
  final VoidCallback? onTap;
  final Color couleur;
  const _BoutonPrincipal({required this.label,
    required this.isLoading, this.onTap,
    this.couleur = const Color(0xFF1A56DB)});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: couleur,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10))),
      onPressed: isLoading ? null : onTap,
      child: isLoading
          ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white))
          : Text(label, style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w700))));
}

// ── Champ email ──────────────────────────────────────────
class _ChampEmail extends StatelessWidget {
  final TextEditingController ctrl;
  const _ChampEmail({required this.ctrl});

  @override
  Widget build(BuildContext context) => _ChampFormulaire(
    ctrl:      ctrl,
    label:     'Adresse email *',
    hint:      'votre@email.com',
    icone:     Icons.email_outlined,
    keyType:   TextInputType.emailAddress,
    validator: (v) {
      if (v == null || v.trim().isEmpty)
        return 'Email requis';
      if (!v.contains('@'))
        return 'Email invalide';
      return null;
    });
}

// ── Champ mot de passe ───────────────────────────────────
class _ChampMotDePasse extends StatelessWidget {
  final TextEditingController ctrl;
  final String label; final bool visible;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;
  const _ChampMotDePasse({required this.ctrl,
    this.label = 'Mot de passe *',
    required this.visible, required this.onToggle,
    this.validator});

  @override
  Widget build(BuildContext context) => _ChampFormulaire(
    ctrl:        ctrl,
    label:       label,
    hint:        '••••••••',
    icone:       Icons.lock_outline_rounded,
    obscure:     !visible,
    suffixIcon:  IconButton(
      icon: Icon(visible
          ? Icons.visibility_off_outlined
          : Icons.visibility_outlined,
        size: 18,
        color: const Color(0xFF94A3B8)),
      onPressed: onToggle),
    validator: validator ?? (v) =>
      v == null || v.length < 6
          ? 'Minimum 6 caractères' : null);
}

// ── Champ formulaire générique ───────────────────────────
class _ChampFormulaire extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final IconData icone;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType? keyType;
  final int maxLines;
  final String? Function(String?)? validator;
  const _ChampFormulaire({required this.ctrl,
    required this.label, required this.hint,
    required this.icone, this.obscure = false,
    this.suffixIcon, this.keyType, this.maxLines = 1,
    this.validator});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w600,
      color: const Color(0xFF374151))),
    const SizedBox(height: 6),
    TextFormField(
      controller:    ctrl,
      obscureText:   obscure,
      keyboardType:  keyType,
      maxLines:      obscure ? 1 : maxLines,
      validator:     validator,
      style: GoogleFonts.inter(
        fontSize: 14, color: const Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 13, color: const Color(0xFFCBD5E1)),
        prefixIcon: Icon(icone, size: 18,
          color: const Color(0xFF94A3B8)),
        suffixIcon: suffixIcon,
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF1A56DB), width: 1.5)),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444), width: 1.5)))),
  ]);
}

// ── Séparateur ───────────────────────────────────────────
class _Separateur extends StatelessWidget {
  final String texte;
  const _Separateur({required this.texte});
  @override
  Widget build(BuildContext context) => Row(children: [
    const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(texte, style: GoogleFonts.inter(
        fontSize: 12, color: const Color(0xFF94A3B8)))),
    const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
  ]);
}

// ── Carte erreur ─────────────────────────────────────────
class _CarteErreur extends StatelessWidget {
  final String message;
  const _CarteErreur({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: const Color(0xFFEF4444).withOpacity(0.3))),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded,
        color: Color(0xFFEF4444), size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(message, style: GoogleFonts.inter(
        fontSize: 13, color: const Color(0xFF991B1B)))),
    ]));
}

// ── Carte rôle ───────────────────────────────────────────
class _CarteRole extends StatelessWidget {
  final String emoji, titre, desc;
  final Color couleur; final bool isSelected;
  final VoidCallback onTap;
  const _CarteRole({required this.emoji, required this.titre,
    required this.desc, required this.couleur,
    required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected
            ? couleur.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? couleur : const Color(0xFFE2E8F0),
          width: isSelected ? 2 : 1),
        boxShadow: isSelected ? [BoxShadow(
          color: couleur.withOpacity(0.15),
          blurRadius: 12, offset: const Offset(0, 4))]
            : []),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 10),
        Text(titre, style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: isSelected ? couleur
              : const Color(0xFF0F172A))),
        const SizedBox(height: 4),
        Text(desc, style: GoogleFonts.inter(
          fontSize: 10, color: const Color(0xFF94A3B8)),
          textAlign: TextAlign.center),
        if (isSelected) ...[
          const SizedBox(height: 8),
          Icon(Icons.check_circle_rounded,
            color: couleur, size: 20),
        ],
      ])));
}

// ── Force du mot de passe ────────────────────────────────
class _ForceMotDePasse extends StatelessWidget {
  final String mdp;
  const _ForceMotDePasse({required this.mdp});

  int get _score {
    if (mdp.isEmpty) return 0;
    int s = 0;
    if (mdp.length >= 8)  s++;
    if (mdp.length >= 12) s++;
    if (RegExp(r'[A-Z]').hasMatch(mdp)) s++;
    if (RegExp(r'[0-9]').hasMatch(mdp)) s++;
    if (RegExp(r'[!@#\$%]').hasMatch(mdp)) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    if (mdp.isEmpty) return const SizedBox(height: 4);
    final score = _score;
    final couleurs = [
      const Color(0xFFEF4444),
      const Color(0xFFF59E0B),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF10B981),
    ];
    final labels = ['Très faible', 'Faible', 'Moyen', 'Fort', 'Très fort'];
    final couleur = couleurs[score.clamp(0, 4)];

    return Row(children: [
      Expanded(child: Row(children:
        List.generate(5, (i) => Expanded(child: Container(
          height: 3,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(
            color: i < score ? couleur : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(100))))))),
      const SizedBox(width: 8),
      Text(labels[score.clamp(0, 4)],
        style: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w600,
          color: couleur)),
    ]);
  }
}

// ── Stats rapides (panneau gauche) ───────────────────────
class _StatsRapides extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [
    _MiniStat('500+', 'Entreprises'),
    const SizedBox(width: 24),
    _MiniStat('2000+', 'Candidats'),
    const SizedBox(width: 24),
    _MiniStat('98%', 'Satisfaction'),
  ]);
}

class _MiniStat extends StatelessWidget {
  final String val, label;
  const _MiniStat(this.val, this.label);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(val, style: GoogleFonts.poppins(
      fontSize: 22, fontWeight: FontWeight.w900,
      color: Colors.white)),
    Text(label, style: GoogleFonts.inter(
      fontSize: 11, color: Colors.white60)),
  ]);
}

// ── Témoignage mini ──────────────────────────────────────
class _TemoignageMini extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.white.withOpacity(0.2))),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: List.generate(5, (_) =>
        const Icon(Icons.star_rounded,
          color: Color(0xFFFBBC05), size: 14))),
      const SizedBox(height: 8),
      Text(
        '"EmploiConnect m\'a aidé à trouver mon '
        'emploi en 2 semaines seulement !"',
        style: GoogleFonts.inter(
          fontSize: 13, color: Colors.white,
          fontStyle: FontStyle.italic, height: 1.5)),
      const SizedBox(height: 10),
      Row(children: [
        const CircleAvatar(
          radius: 14,
          backgroundColor: Color(0xFF10B981),
          child: Text('M', style: TextStyle(
            color: Colors.white, fontSize: 12,
            fontWeight: FontWeight.w700))),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text('Mamadou Barry', style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: Colors.white)),
          Text('Développeur · Conakry', style: GoogleFonts.inter(
            fontSize: 10, color: Colors.white60)),
        ]),
      ]),
    ]));
}

// ── Avantages liste ──────────────────────────────────────
class _AvantagesListe extends StatelessWidget {
  final _items = const [
    ('🤖', 'Matching IA intelligent',
     'Offres parfaitement adaptées à votre profil'),
    ('⚡', 'Réponse en 24h',
     'Les recruteurs répondent rapidement'),
    ('🔒', '100% Sécurisé',
     'Vos données sont protégées'),
    ('🆓', 'Totalement gratuit',
     'Inscription et recherche sans frais'),
  ];

  @override
  Widget build(BuildContext context) => Column(
    children: _items.map((item) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(item.$1,
            style: const TextStyle(fontSize: 18)))),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(item.$2, style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: Colors.white)),
          Text(item.$3, style: GoogleFonts.inter(
            fontSize: 11, color: Colors.white60)),
        ])),
      ]))).toList());
}
```

---

## Critères d'Acceptation

### Page Connexion
- [ ] Panneau gauche bleu avec titre + stats + témoignage (desktop)
- [ ] Bouton Google en premier
- [ ] Champs email + mot de passe avec icônes
- [ ] Lien mot de passe oublié
- [ ] Liens vers inscription candidat/recruteur
- [ ] Message d'erreur stylisé
- [ ] Responsive mobile ✅

### Page Inscription
- [ ] Étape 1 : choix du rôle (cartes animées)
- [ ] Bouton Google après choix du rôle
- [ ] Étape 2 : formulaire selon le rôle
- [ ] Champs spécifiques recruteur (entreprise, poste)
- [ ] Indicateur force du mot de passe
- [ ] Case CGU obligatoire
- [ ] Bouton retour entre étapes
- [ ] Panneau gauche avec avantages (desktop)
- [ ] Responsive mobile ✅

---

*PRD EmploiConnect v9.4 — Pages Auth Professionnelles*
*Cursor / Kirsoft AI — Phase 27*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
