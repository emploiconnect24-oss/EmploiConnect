import 'package:flutter/material.dart';
import '../widgets/responsive_container.dart';
import '../widgets/hover_scale.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    // Backend actuel : pas encore d'endpoint reset password.
    // On garde une UX propre : message clair.
    await Future<void>.delayed(const Duration(milliseconds: 450));

    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Fonction "mot de passe oublié" à brancher côté backend (envoi email).',
        ),
      ),
    );
  }

  Widget _leftPanel(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const orange = Color(0xFFFF8A00);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.95),
            orange.withValues(alpha: 0.85),
          ],
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
              child: const Icon(Icons.lock_reset, color: Colors.white),
            ),
            const SizedBox(height: 14),
            const Text(
              'Mot de passe oublié ?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Entrez votre email et nous vous enverrons des instructions.\n\n'
              'Note : la fonctionnalité d’envoi email sera activée prochainement.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                height: 1.4,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formCard(BuildContext context) {
    const orange = Color(0xFFFF8A00);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Réinitialisation',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Nous vous guiderons pour récupérer votre compte.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email requis';
                  final ok = RegExp(r'^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$').hasMatch(v.trim());
                  if (!ok) return 'Format email invalide';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              HoverScale(
                onTap: _loading ? null : _submit,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: orange,
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
                      : const Text('Envoyer les instructions'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                child: const Text('Retour à la connexion'),
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
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withValues(alpha: 0.06),
              const Color(0xFFFF8A00).withValues(alpha: 0.05),
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
                          Expanded(child: _leftPanel(context)),
                          const SizedBox(width: 16),
                          Expanded(child: _formCard(context)),
                        ],
                      )
                    : Column(
                        children: [
                          _leftPanel(context),
                          const SizedBox(height: 12),
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

