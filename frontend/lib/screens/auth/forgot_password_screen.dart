import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme_extension.dart';
import '../../services/auth_service.dart';
import 'auth_widgets.dart';

/// Réinitialisation du mot de passe — layout aligné login / register.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailEnvoye = false;
  String? _erreur;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _retourConnexion() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
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
                colors: [Color(0xFF1A56DB), Color(0xFF4F46E5)],
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
                      Center(
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('🔑', style: TextStyle(fontSize: 64)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Mot de passe\noublié ?',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Pas d'inquiétude ! Entrez votre adresse "
                        'email et nous vous enverrons un lien '
                        'pour réinitialiser votre mot de passe.',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.75),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const _EtapesReset(),
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
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                  child: _emailEnvoye ? _buildSucces() : _buildFormulaire(),
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1A56DB).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🔑', style: TextStyle(fontSize: 40))),
          ),
          const SizedBox(height: 24),
          _emailEnvoye ? _buildSucces() : _buildFormulaire(),
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
        GestureDetector(
          onTap: _retourConnexion,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_rounded, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                'Retour à la connexion',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Réinitialisation',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Entrez l'email associé à votre compte.",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        if (_erreur != null) ...[
          AuthCarteErreur(message: _erreur!),
          const SizedBox(height: 16),
        ],
        AuthChampEmail(ctrl: _emailCtrl),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(
              _isLoading ? 'Envoi en cours...' : 'Envoyer le lien',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _isLoading ? null : _envoyerLien,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
            child: Text(
              'Retour à la connexion',
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

  Widget _buildSucces() {
    final cs = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: ext.successBg,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.mark_email_read_rounded, color: Color(0xFF10B981), size: 40),
          ),
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'Email envoyé !',
        style: GoogleFonts.poppins(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: cs.onSurface,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Un lien de réinitialisation a été envoyé à\n${_emailCtrl.text}',
        style: GoogleFonts.inter(
          fontSize: 14,
          color: cs.onSurfaceVariant,
          height: 1.6,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Text(
        "Vérifiez aussi vos spams si vous ne trouvez pas l'email.",
        style: GoogleFonts.inter(
          fontSize: 12,
          color: cs.outline,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 28),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.login_rounded, size: 18),
          label: Text(
            'Retour à la connexion',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
        ),
      ),
      const SizedBox(height: 14),
      GestureDetector(
        onTap: () {
          setState(() {
            _emailEnvoye = false;
            _erreur = null;
          });
          _animCtrl.forward(from: 0);
        },
        child: Text(
          "Renvoyer l'email",
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    ],
  );
  }

  Future<void> _envoyerLien() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _erreur = null;
    });
    try {
      final (ok, msg) = await AuthService().forgotPassword(_emailCtrl.text.trim());
      if (!mounted) return;
      if (ok) {
        setState(() => _emailEnvoye = true);
        _animCtrl.forward(from: 0);
      } else {
        setState(() => _erreur = msg ?? 'Impossible d’envoyer la demande pour le moment.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _erreur = 'Erreur de connexion. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _EtapesReset extends StatelessWidget {
  const _EtapesReset();

  @override
  Widget build(BuildContext context) => const Column(
    children: <Widget>[
      _EtapeItem('1', 'Entrez votre email', 'Dans le formulaire ci-contre'),
      _EtapeItem('2', 'Vérifiez votre boîte mail', 'Un lien vous sera envoyé'),
      _EtapeItem('3', 'Créez un nouveau mot de passe', 'Sécurisé et mémorisable', isLast: true),
    ],
  );
}

class _EtapeItem extends StatelessWidget {
  const _EtapeItem(this.numero, this.titre, this.desc, {this.isLast = false});

  final String numero;
  final String titre;
  final String desc;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              ),
              child: Center(
                child: Text(
                  numero,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: Colors.white.withValues(alpha: 0.2),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 12),
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
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
