import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/theme_extension.dart';
import '../providers/auth_provider.dart';
import '../services/google_auth_service.dart';
import 'auth/auth_widgets.dart';

/// Inscription — PRD_AUTH_PAGES.md §2
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  String? _roleChoisi;
  int _etape = 1;

  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _entrepriseCtrl = TextEditingController();
  final _posteCtrl = TextEditingController();

  bool _mdpVisible = false;
  bool _confirmVisible = false;
  bool _accepteCGU = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _erreur;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  bool _routeParsed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GoogleAuthService.prefetchConfig();
    });
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _animCtrl.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeParsed) return;
    _routeParsed = true;
    final name = ModalRoute.of(context)?.settings.name ?? '';
    if (!name.startsWith('/register')) return;
    try {
      final uri = Uri.parse('http://_placeholder$name');
      final r = uri.queryParameters['role']?.toLowerCase().trim();
      if (r == null || r.isEmpty) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (r == 'candidat' || r == 'chercheur') {
          setState(() {
            _roleChoisi = 'chercheur';
            _etape = 2;
          });
        } else if (r == 'recruteur' || r == 'entreprise') {
          setState(() {
            _roleChoisi = 'entreprise';
            _etape = 2;
          });
        }
        _animCtrl.forward(from: 0);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _mdpCtrl.dispose();
    _confirmCtrl.dispose();
    _entrepriseCtrl.dispose();
    _posteCtrl.dispose();
    super.dispose();
  }

  String get _roleApi {
    switch (_roleChoisi) {
      case 'entreprise':
        return 'entreprise';
      case 'admin':
        return 'admin';
      default:
        return 'chercheur';
    }
  }

  Color get _couleurRole {
    if (_roleChoisi == 'entreprise') return const Color(0xFF8B5CF6);
    if (_roleChoisi == 'admin') return const Color(0xFFEF4444);
    return const Color(0xFF1A56DB);
  }

  List<Widget> _registerPanelHighlights() {
    const items = <(String, String, String)>[
      ('🎯', 'Matching IA intelligent', 'Offres alignées sur votre profil'),
      ('🚀', 'Opportunités en temps réel', 'Postulez ou publiez en quelques clics'),
      ('🔒', 'Données protégées', 'Espace sécurisé pour votre parcours'),
    ];
    return items.map((item) {
      final (emoji, titre, sous) = item;
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    sous,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: isMobile ? _buildMobile() : _buildDesktop(),
    );
  }

  Widget _buildDesktop() => Row(
    children: [
      Expanded(
        flex: 5,
        child: ClipRect(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A56DB), Color(0xFF7C3AED)],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuthLogoHeader(couleurTexte: Colors.white),
                      const SizedBox(height: 40),
                      Text(
                        'Commencez votre\nsuccès aujourd\'hui.',
                        style: GoogleFonts.poppins(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Rejoignez des milliers de professionnels '
                        'guinéens qui ont trouvé leur voie.',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.75),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 28),
                      ..._registerPanelHighlights(),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('🇬🇳', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Candidats et recruteurs : un seul lieu pour '
                                'faire matcher talents et opportunités.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      Expanded(
        flex: 4,
        child: ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SingleChildScrollView(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 460),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                  child: _etape == 1 ? _buildChoixRole() : _buildFormulaire(),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _buildMobile() => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          AuthLogoHeader(couleurTexte: Theme.of(context).colorScheme.onSurface),
          const SizedBox(height: 28),
          _etape == 1 ? _buildChoixRole() : _buildFormulaire(),
        ],
      ),
    ),
  );

  Widget _buildChoixRole() {
    final cs = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Créer un compte',
        style: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: cs.onSurface,
        ),
      ),
      const SizedBox(height: 6),
      RichText(
        text: TextSpan(
          style: GoogleFonts.inter(
            fontSize: 14,
            color: cs.onSurfaceVariant,
          ),
          children: [
            const TextSpan(text: 'Déjà inscrit ? '),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: () =>
                    Navigator.of(context).pushReplacementNamed('/login'),
                child: Text(
                  'Se connecter',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 32),
      Text(
        'Je souhaite...',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: cs.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: AuthCarteRole(
              emoji: '👤',
              titre: 'Trouver un emploi',
              desc: "Candidat · Chercheur d'emploi",
              couleur: const Color(0xFF1A56DB),
              isSelected: _roleChoisi == 'chercheur',
              onTap: () => setState(() => _roleChoisi = 'chercheur'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AuthCarteRole(
              emoji: '🏢',
              titre: 'Recruter des talents',
              desc: 'Recruteur · Entreprise',
              couleur: const Color(0xFF8B5CF6),
              isSelected: _roleChoisi == 'entreprise',
              onTap: () => setState(() => _roleChoisi = 'entreprise'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        child: (_roleChoisi == 'chercheur' || _roleChoisi == 'entreprise')
            ? Column(
                children: [
                  AuthBoutonGoogle(
                    label: "S'inscrire avec Google",
                    isLoading: _isGoogleLoading,
                    onTap: _inscrireGoogle,
                  ),
                  const SizedBox(height: 12),
                  const AuthSeparateur(texte: 'ou créer un compte'),
                  const SizedBox(height: 12),
                ],
              )
            : const SizedBox.shrink(),
      ),
      AuthBoutonPrincipal(
        label: 'Continuer →',
        isLoading: false,
        couleur: _roleChoisi != null
            ? cs.primary
            : cs.outline.withValues(alpha: 0.5),
        onTap: _roleChoisi != null
            ? () {
                _animCtrl.forward(from: 0);
                setState(() => _etape = 2);
              }
            : null,
      ),
      const SizedBox(height: 16),
      Center(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _roleChoisi = 'admin';
              _etape = 2;
            });
            _animCtrl.forward(from: 0);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ext.sectionBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ext.cardBorder),
            ),
            child: Text(
              '🔐 Compte administrateur (email uniquement)',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    ],
  );
  }

  void _snackLegal(String label) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — contenu à venir.')),
    );
  }

  Widget _buildFormulaire() {
    final cs = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    return Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            _animCtrl.forward(from: 0);
            setState(() {
              _etape = 1;
              _erreur = null;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_rounded, size: 16, color: cs.primary),
              const SizedBox(width: 4),
              Text(
                'Retour',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                _roleChoisi == 'entreprise'
                    ? 'Compte Recruteur'
                    : _roleChoisi == 'admin'
                        ? 'Compte Admin'
                        : 'Compte Candidat',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _couleurRole.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                _roleChoisi == 'entreprise'
                    ? '🏢 Recruteur'
                    : _roleChoisi == 'admin'
                        ? '🔐 Admin'
                        : '👤 Candidat',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _couleurRole,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_erreur != null) ...[
          AuthCarteErreur(message: _erreur!),
          const SizedBox(height: 14),
        ],
        if (_roleChoisi == 'admin') ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ext.sectionBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ext.cardBorder),
            ),
            child: Text(
              'Les comptes administrateur s’inscrivent uniquement par e-mail et mot de passe (pas de Google).',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: cs.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        AuthChampFormulaire(
          ctrl: _nomCtrl,
          label: 'Nom complet *',
          hint: 'Ex: Mamadou Barry',
          icone: Icons.person_outline_rounded,
          validator: (v) =>
              v == null || v.trim().length < 2 ? 'Nom trop court' : null,
        ),
        const SizedBox(height: 12),
        if (_roleChoisi == 'entreprise') ...[
          AuthChampFormulaire(
            ctrl: _entrepriseCtrl,
            label: "Nom de l'entreprise *",
            hint: 'Ex: TechGuinée SARL',
            icone: Icons.business_outlined,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Champ requis' : null,
          ),
          const SizedBox(height: 12),
          AuthChampFormulaire(
            ctrl: _posteCtrl,
            label: 'Votre poste',
            hint: 'Ex: Directeur RH',
            icone: Icons.work_outline_rounded,
          ),
          const SizedBox(height: 12),
        ],
        AuthChampEmail(ctrl: _emailCtrl),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: _mdpCtrl,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthChampMotDePasse(
                ctrl: _mdpCtrl,
                label: 'Mot de passe *',
                visible: _mdpVisible,
                onToggle: () => setState(() => _mdpVisible = !_mdpVisible),
              ),
              const SizedBox(height: 4),
              AuthForceMotDePasse(mdp: _mdpCtrl.text),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AuthChampMotDePasse(
          ctrl: _confirmCtrl,
          label: 'Confirmer le mot de passe *',
          visible: _confirmVisible,
          onToggle: () => setState(() => _confirmVisible = !_confirmVisible),
          validator: (v) =>
              v != _mdpCtrl.text ? 'Les mots de passe ne correspondent pas' : null,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _accepteCGU,
              onChanged: (v) => setState(() => _accepteCGU = v ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                    children: [
                      const TextSpan(text: "J'accepte les "),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () => _snackLegal('Conditions d’utilisation'),
                          child: Text(
                            "Conditions d'utilisation",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ' et la '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () => _snackLegal('Politique de confidentialité'),
                          child: Text(
                            'Politique de confidentialité',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AuthBoutonPrincipal(
          label: 'Créer mon compte',
          isLoading: _isLoading,
          onTap: _accepteCGU ? _creerCompte : null,
          couleur: _accepteCGU ? const Color(0xFF1A56DB) : const Color(0xFFCBD5E1),
        ),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
            child: Text(
              'Déjà un compte ? Se connecter',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
          ),
        ),
      ],
    ),
  );
  }

  Future<void> _creerCompte() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _erreur = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final (ok, msg) = await auth.register(
        email: _emailCtrl.text.trim(),
        motDePasse: _mdpCtrl.text,
        nom: _nomCtrl.text.trim(),
        role: _roleApi,
        nomEntreprise:
            _roleChoisi == 'entreprise' ? _entrepriseCtrl.text.trim() : null,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (ok) {
        if (_roleApi != 'admin') {
          await auth.logout();
          if (!mounted) return;
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Inscription réussie'),
              content: const Text(
                'Votre compte a été créé mais il est en attente de validation par un administrateur. '
                'Vous pourrez vous connecter après validation.',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/login');
          return;
        }
        auth.navigateToAuthenticatedHome(context);
      } else {
        setState(() => _erreur = msg ?? 'Erreur lors de l\'inscription');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _erreur = e.toString();
        });
      }
    }
  }

  Future<void> _inscrireGoogle() async {
    final r = _roleChoisi;
    if (r == null || r == 'admin') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Choisissez d’abord « Candidat » ou « Recruteur » pour utiliser Google.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _isGoogleLoading = true;
      _erreur = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final role = r == 'entreprise' ? 'entreprise' : 'chercheur';
      final g = await auth.loginWithGoogle(role: role);
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);
      if (g.ok) {
        auth.navigateToAuthenticatedHome(context);
        return;
      }
      if (g.message == null) return;
      if (g.pendingValidation) {
        await auth.logout();
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Inscription réussie'),
            content: Text(g.message!),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }
      setState(() => _erreur = g.message);
    } catch (e) {
      if (mounted) {
        setState(() => _erreur = 'Erreur Google: $e');
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }
}
