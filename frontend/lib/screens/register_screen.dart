import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_animations.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../providers/auth_provider.dart';
import '../services/google_auth_service.dart';
import 'auth/widgets/mobile_auth_header.dart';
import '../shared/widgets/logo_widget.dart';
import '../widgets/responsive_container.dart';
import '../widgets/hover_scale.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nomController = TextEditingController();
  /// `null` = pas encore choisi. `chercheur` | `entreprise` | `admin` (admin = e-mail uniquement).
  String? _roleChoisi;
  String _role = 'chercheur';
  bool _loading = false;
  bool _googleLoading = false;
  String? _errorMessage;
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GoogleAuthService.prefetchConfig();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nomController.dispose();
    super.dispose();
  }

  Future<void> _googleSignUp() async {
    if (_loading || _googleLoading) return;
    final r = _roleChoisi;
    if (r == null || r == 'admin') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisissez d’abord « Candidat » ou « Recruteur » pour utiliser Google.'),
        ),
      );
      return;
    }
    debugPrint('[BoutonGoogle] register: clic (role=$r)');
    setState(() {
      _googleLoading = true;
      _errorMessage = null;
    });
    final auth = context.read<AuthProvider>();
    debugPrint('[BoutonGoogle] register: loginWithGoogle…');
    final (ok, msg, pending) = await auth.loginWithGoogle(role: r);
    debugPrint('[BoutonGoogle] register: ok=$ok pending=$pending msg=$msg');
    if (!mounted) return;
    setState(() => _googleLoading = false);
    if (ok) {
      auth.navigateToAuthenticatedHome(context);
      return;
    }
    if (msg == null) return;
    if (pending) {
      await auth.logout();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Inscription réussie'),
          content: Text(msg),
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
    setState(() => _errorMessage = msg);
  }

  Future<void> _submit() async {
    if (_roleChoisi == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indiquez d’abord si vous êtes candidat, recruteur ou administrateur.'),
        ),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _errorMessage = null;
      _loading = true;
    });
    final auth = context.read<AuthProvider>();
    final (ok, msg) = await auth.register(
      email: _emailController.text.trim(),
      motDePasse: _passwordController.text,
      nom: _nomController.text.trim(),
      role: _role,
    );
    setState(() => _loading = false);
    if (!mounted) return;
    if (ok) {
      // Côté backend, seuls les admins sont validés automatiquement.
      // Pour chercheur/entreprise, on affiche un message explicite et on renvoie au login.
      if (_role != 'admin') {
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
      setState(() => _errorMessage = msg ?? 'Erreur lors de l\'inscription');
    }
  }

  Widget _leftPanel(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.authPanelGradient,
          stops: AppColors.authPanelStops,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LogoWidget(
              height: 40,
              fallbackTextColor: Colors.white,
              fallbackAccentColor: Color(0xFFBAE6FD),
            ),
            const SizedBox(height: 14),
            Text('Créer un compte', style: AppTextStyles.authPanelTitle),
            const SizedBox(height: 10),
            Text(
              'Rejoignez EmploiConnect : publiez des offres, postulez, téléversez un CV et recevez des suggestions IA.',
              style: AppTextStyles.authPanelBody,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                _Pill(icon: Icons.person_search, label: 'Chercheur'),
                _Pill(icon: Icons.apartment, label: 'Entreprise'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoixRole() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Je souhaite…',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _roleChoisi = 'chercheur';
                  _role = 'chercheur';
                  _errorMessage = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _roleChoisi == 'chercheur'
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _roleChoisi == 'chercheur'
                          ? const Color(0xFF1A56DB)
                          : const Color(0xFFE2E8F0),
                      width: _roleChoisi == 'chercheur' ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text('👤', style: TextStyle(fontSize: 28)),
                      const SizedBox(height: 8),
                      Text(
                        'Candidat',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _roleChoisi == 'chercheur'
                              ? const Color(0xFF1A56DB)
                              : const Color(0xFF374151),
                        ),
                      ),
                      Text(
                        'Je cherche un emploi',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF94A3B8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_roleChoisi == 'chercheur')
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF1A56DB),
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _roleChoisi = 'entreprise';
                  _role = 'entreprise';
                  _errorMessage = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _roleChoisi == 'entreprise'
                        ? const Color(0xFFF5F3FF)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _roleChoisi == 'entreprise'
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFFE2E8F0),
                      width: _roleChoisi == 'entreprise' ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text('🏢', style: TextStyle(fontSize: 28)),
                      const SizedBox(height: 8),
                      Text(
                        'Recruteur',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _roleChoisi == 'entreprise'
                              ? const Color(0xFF8B5CF6)
                              : const Color(0xFF374151),
                        ),
                      ),
                      Text(
                        'Je recrute des talents',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF94A3B8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_roleChoisi == 'entreprise')
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF8B5CF6),
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _loading
                ? null
                : () => setState(() {
                    _roleChoisi = 'admin';
                    _role = 'admin';
                    _errorMessage = null;
                  }),
            child: Text(
              'Compte administrateur (inscription par e-mail uniquement)',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeparateurInscription(String label, Color schemeOutline) {
    return Row(
      children: [
        Expanded(child: Divider(color: schemeOutline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label, style: TextStyle(color: schemeOutline, fontSize: 12)),
        ),
        Expanded(child: Divider(color: schemeOutline)),
      ],
    );
  }

  Widget _formCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showGoogle = _roleChoisi == 'chercheur' || _roleChoisi == 'entreprise';
    final showForm = _roleChoisi != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeInDown(
                duration: AppAnimations.medium,
                delay: const Duration(milliseconds: 200),
                child: Text('Inscription', style: AppTextStyles.authTitle),
              ),
              const SizedBox(height: 6),
              Text(
                'Créez votre compte en quelques secondes.',
                style: AppTextStyles.authSubtitle,
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              FadeInUp(
                duration: AppAnimations.medium,
                delay: const Duration(milliseconds: 220),
                child: _buildChoixRole(),
              ),
              if (showGoogle) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: (_loading || _googleLoading) ? null : _googleSignUp,
                  icon: _googleLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.g_mobiledata, size: 28),
                  label: Text(
                    _googleLoading ? 'Inscription Google…' : 'Continuer avec Google',
                  ),
                ),
                const SizedBox(height: 12),
                _buildSeparateurInscription('ou créer un compte', scheme.outlineVariant),
                const SizedBox(height: 12),
              ],
              if (_roleChoisi == 'admin') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    'Les comptes administrateur s’inscrivent uniquement par e-mail et mot de passe (pas de Google).',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), height: 1.35),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (showForm) ...[
                FadeInUp(
                  duration: AppAnimations.medium,
                  delay: const Duration(milliseconds: 250),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          _roleChoisi == 'chercheur'
                              ? 'Profil : candidat'
                              : _roleChoisi == 'entreprise'
                                  ? 'Profil : recruteur'
                                  : 'Profil : administrateur',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => setState(() {
                                _roleChoisi = null;
                                _role = 'chercheur';
                              }),
                        child: const Text('Modifier'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                FadeInUp(
                  duration: AppAnimations.medium,
                  delay: const Duration(milliseconds: 260),
                  child: TextFormField(
                    controller: _nomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom complet',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  duration: AppAnimations.medium,
                  delay: const Duration(milliseconds: 300),
                  child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email requis';
                      final email = v.trim();
                      final ok = RegExp(
                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                      ).hasMatch(email);
                      if (!ok) return 'Format email invalide';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  duration: AppAnimations.medium,
                  delay: const Duration(milliseconds: 350),
                  child: TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe (min. 8 caractères)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Afficher' : 'Masquer',
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    obscureText: _obscure,
                    validator: (v) {
                      if (v == null || v.length < 8) {
                        return 'Au moins 8 caractères';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  duration: AppAnimations.medium,
                  delay: const Duration(milliseconds: 400),
                  child: TextFormField(
                    controller: _confirmController,
                    decoration: InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _obscureConfirm ? 'Afficher' : 'Masquer',
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    obscureText: _obscureConfirm,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Confirmez le mot de passe';
                      }
                      if (v != _passwordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 14),
                FadeInUp(
                  duration: AppAnimations.medium,
                  delay: const Duration(milliseconds: 500),
                  child: HoverScale(
                    onTap: _loading ? null : _submit,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Créer mon compte'),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              FadeInUp(
                duration: AppAnimations.medium,
                delay: const Duration(milliseconds: 600),
                child: TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed('/login'),
                  child: const Text('Déjà un compte ? Se connecter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withValues(alpha: 0.06),
              AppColors.primary.withValues(alpha: 0.05),
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: ResponsiveContainer(
            maxWidth: 1100,
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (context, c) {
                final desktop = c.maxWidth >= 900;
                final content = desktop
                    ? Row(
                        children: [
                          Expanded(
                            child: FadeInLeft(
                              duration: AppAnimations.slow,
                              child: _leftPanel(context),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FadeInRight(
                              duration: AppAnimations.slow,
                              delay: const Duration(milliseconds: 150),
                              child: _formCard(context),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          FadeInDown(
                            duration: AppAnimations.slow,
                            child: const MobileAuthHeader(
                              title: 'Inscription',
                              subtitle:
                                  'Creez votre compte en quelques secondes',
                            ),
                          ),
                          const SizedBox(height: 10),
                          _formCard(context),
                        ],
                      );
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: content,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.92), size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
