import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

import '../core/constants/app_animations.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/utils/reset_token.dart';
import '../services/auth_service.dart';
import 'auth/widgets/mobile_auth_header.dart';
import '../widgets/responsive_container.dart';
import '../widgets/hover_scale.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.initialToken});

  final String? initialToken;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _loading = false;
  late String? _token;

  @override
  void initState() {
    super.initState();
    _token = widget.initialToken?.trim().isNotEmpty == true
        ? widget.initialToken!.trim()
        : readResetPasswordTokenFromUrl();
  }

  @override
  void dispose() {
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final t = _token;
    if (t == null || t.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lien invalide ou expiré. Demandez un nouvel email.'),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    final (ok, msg) = await AuthService().resetPassword(
      token: t,
      motDePasse: _passCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe mis à jour. Vous pouvez vous connecter.')),
      );
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg ?? 'Échec de la réinitialisation')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final missingToken = _token == null || _token!.isEmpty;

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
            maxWidth: 520,
            padding: const EdgeInsets.all(14),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FadeInDown(
                      duration: AppAnimations.slow,
                      child: const MobileAuthHeader(
                        title: 'Nouveau mot de passe',
                        subtitle: 'Choisissez un mot de passe sécurisé',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (missingToken)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    'Ouvrez le lien reçu par email, ou demandez une nouvelle réinitialisation depuis la page de connexion.',
                                    style: AppTextStyles.authSubtitle,
                                  ),
                                ),
                              FadeInUp(
                                duration: AppAnimations.medium,
                                delay: const Duration(milliseconds: 120),
                                child: TextFormField(
                                  controller: _passCtrl,
                                  obscureText: true,
                                  enabled: !missingToken,
                                  decoration: const InputDecoration(
                                    labelText: 'Nouveau mot de passe',
                                    prefixIcon: Icon(Icons.lock_outline),
                                  ),
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
                                delay: const Duration(milliseconds: 180),
                                child: TextFormField(
                                  controller: _pass2Ctrl,
                                  obscureText: true,
                                  enabled: !missingToken,
                                  decoration: const InputDecoration(
                                    labelText: 'Confirmer le mot de passe',
                                    prefixIcon: Icon(Icons.lock_outline),
                                  ),
                                  validator: (v) {
                                    if (v != _passCtrl.text) {
                                      return 'Les mots de passe ne correspondent pas';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              HoverScale(
                                onTap: _loading || missingToken ? null : _submit,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onPressed: _loading || missingToken ? null : _submit,
                                  child: _loading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Enregistrer'),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pushReplacementNamed('/login'),
                                child: const Text('Retour à la connexion'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
