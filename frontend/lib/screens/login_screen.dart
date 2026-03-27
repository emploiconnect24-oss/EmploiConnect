import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_animations.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../providers/auth_provider.dart';
import 'auth/widgets/mobile_auth_header.dart';
import '../widgets/responsive_container.dart';
import '../widgets/hover_scale.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goForgotPassword() {
    Navigator.of(context).pushNamed('/forgot-password');
  }

  Future<void> _googleSignIn() async {
    // UI prête. L’intégration technique nécessite un endpoint backend du type:
    // POST /auth/google (échange idToken → JWT EmploiConnect).
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connexion Google : à brancher côté backend (OAuth).'),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _errorMessage = null;
      _loading = true;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final auth = context.read<AuthProvider>();
    final (ok, msg) = await auth.login(email: email, motDePasse: password);
    setState(() => _loading = false);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() => _errorMessage = msg ?? 'Erreur de connexion');
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
              ),
              child: const Icon(Icons.work_outline, color: Colors.white),
            ),
            const SizedBox(height: 14),
            Text(
              'Bienvenue sur EmploiConnect',
              style: AppTextStyles.authPanelTitle,
            ),
            const SizedBox(height: 10),
            Text(
              'Connectez-vous pour accéder à vos offres, candidatures, CV et suggestions IA.',
              style: AppTextStyles.authPanelBody,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Pill(
                  icon: Icons.auto_awesome,
                  label: 'Matching IA',
                ),
                _Pill(
                  icon: Icons.assignment,
                  label: 'Suivi candidatures',
                ),
                _Pill(
                  icon: Icons.shield,
                  label: 'Plateforme modérée',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _formCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
                child: Text(
                  'Connexion',
                  style: AppTextStyles.authTitle,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Accédez à votre espace EmploiConnect.',
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
                delay: const Duration(milliseconds: 250),
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
                    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
                    if (!ok) return 'Format email invalide';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                duration: AppAnimations.medium,
                delay: const Duration(milliseconds: 300),
                child: TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Afficher' : 'Masquer',
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    ),
                  ),
                  obscureText: _obscure,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Mot de passe requis';
                    return null;
                  },
                  onFieldSubmitted: (_) => _loading ? null : _submit(),
                ),
              ),
              const SizedBox(height: 10),
              FadeInUp(
                duration: AppAnimations.medium,
                delay: const Duration(milliseconds: 350),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _loading ? null : _goForgotPassword,
                    child: const Text('Mot de passe oublié ?'),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FadeInUp(
                duration: AppAnimations.medium,
                delay: const Duration(milliseconds: 400),
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
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Se connecter'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                duration: AppAnimations.medium,
                delay: const Duration(milliseconds: 500),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Divider(color: scheme.outlineVariant)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('ou'),
                        ),
                        Expanded(child: Divider(color: scheme.outlineVariant)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _loading ? null : _googleSignIn,
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: const Text('Continuer avec Google'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacementNamed('/register'),
                      child: const Text('Pas de compte ? S’inscrire'),
                    ),
                  ],
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
              Colors.white,
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
                              title: 'Connexion',
                              subtitle: 'Accedez a votre espace EmploiConnect',
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
