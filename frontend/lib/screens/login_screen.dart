import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/google_auth_service.dart';
import 'auth/admin_two_factor_code_dialog.dart';
import 'auth/auth_widgets.dart';

/// Connexion — PRD_AUTH_PAGES.md §1
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _mdpVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _erreur;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GoogleAuthService.prefetchConfig();
    });
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
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
                colors: [
                  Color(0xFF1A56DB),
                  Color(0xFF2563EB),
                  Color(0xFF4F46E5),
                ],
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
                        'Votre carrière\nvous attend.',
                        style: GoogleFonts.poppins(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Connectez-vous et découvrez les opportunités '
                        'qui correspondent à votre profil.',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.75),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 28),
                      ..._loginPanelHighlights(),
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
                                'La première plateforme intelligente '
                                "de l'emploi en Guinée.",
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
            padding: EdgeInsets.zero,
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                    child: _buildFormulaire(),
                  ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          AuthLogoHeader(couleurTexte: Theme.of(context).colorScheme.onSurface),
          const SizedBox(height: 32),
          _buildFormulaire(),
        ],
      ),
    ),
  );

  Widget _buildFormulaire() {
    final cs = Theme.of(context).colorScheme;
    return Form(
    key: _formKey,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connexion',
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
              const TextSpan(text: 'Nouveau sur EmploiConnect ? '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: GestureDetector(
                  onTap: () =>
                      Navigator.of(context).pushReplacementNamed('/register'),
                  child: Text(
                    'Créer un compte',
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
        const SizedBox(height: 20),
        AuthBoutonGoogle(
          label: 'Continuer avec Google',
          isLoading: _isGoogleLoading,
          onTap: _connecterGoogle,
        ),
        const SizedBox(height: 14),
        const AuthSeparateur(texte: 'ou se connecter avec email'),
        const SizedBox(height: 14),
        if (_erreur != null) ...[
          AuthCarteErreur(message: _erreur!),
          const SizedBox(height: 12),
        ],
        AuthChampEmail(ctrl: _emailCtrl),
        const SizedBox(height: 14),
        AuthChampMotDePasse(
          ctrl: _mdpCtrl,
          visible: _mdpVisible,
          onToggle: () => setState(() => _mdpVisible = !_mdpVisible),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Mot de passe requis';
            return null;
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/forgot-password'),
            child: Text(
              'Mot de passe oublié ?',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AuthBoutonPrincipal(
          label: 'Se connecter',
          isLoading: _isLoading,
          onTap: _seConnecter,
        ),
        const SizedBox(height: 14),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pushReplacementNamed(
                  '/register?role=candidat',
                ),
                child: Text(
                  'Créer un compte Candidat',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '·',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: cs.outline,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pushReplacementNamed(
                  '/register?role=recruteur',
                ),
                child: Text(
                  'Créer un compte Recruteur',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  }

  /// Points forts — panneau gauche (remplace stats / témoignages fictifs).
  List<Widget> _loginPanelHighlights() {
    const items = <(String, String, String)>[
      ('🎯', 'Matching IA intelligent', 'Vos offres idéales en un clic'),
      ('🚀', 'Opportunités en temps réel', 'Nouvelles offres chaque jour'),
      ('🔒', 'Profil 100% sécurisé', 'Vos données restent privées'),
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

  Future<void> _seConnecter() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _erreur = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final r = await auth.login(
        email: _emailCtrl.text.trim(),
        motDePasse: _mdpCtrl.text,
      );
      if (!mounted) return;
      if (r.success) {
        auth.navigateToAuthenticatedHome(context);
        return;
      }
      if (r.needsTwoFactor && (r.tempToken ?? '').isNotEmpty) {
        final done = await showAdminTwoFactorCodeDialog(
          context,
          submit: (code) => auth.completeLogin2Fa(
                tempToken: r.tempToken!,
                code: code,
              ),
        );
        if (!mounted) return;
        if (done) {
          auth.navigateToAuthenticatedHome(context);
        }
        return;
      }
      setState(() => _erreur = r.message ?? 'Erreur de connexion');
    } catch (e) {
      if (mounted) setState(() => _erreur = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _connecterGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _erreur = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final g = await auth.loginWithGoogle();
      if (!mounted) return;
      if (g.ok) {
        auth.navigateToAuthenticatedHome(context);
        return;
      }
      if ((g.twoFaTempToken ?? '').isNotEmpty) {
        final done = await showAdminTwoFactorCodeDialog(
          context,
          submit: (code) => auth.completeLogin2Fa(
                tempToken: g.twoFaTempToken!,
                code: code,
              ),
        );
        if (!mounted) return;
        if (done) {
          auth.navigateToAuthenticatedHome(context);
        }
        return;
      }
      if (g.message == null) return;
      if (g.pendingValidation) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Compte créé'),
            content: Text(g.message!),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
      setState(() => _erreur = g.message);
    } catch (e) {
      if (mounted) setState(() => _erreur = 'Erreur Google: $e');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }
}
