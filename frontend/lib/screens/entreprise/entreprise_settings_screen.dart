import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/users_service.dart';
import '../../widgets/responsive_container.dart';
import '../../widgets/reveal_on_scroll.dart';

class EntrepriseSettingsScreen extends StatefulWidget {
  const EntrepriseSettingsScreen({super.key});

  @override
  State<EntrepriseSettingsScreen> createState() => _EntrepriseSettingsScreenState();
}

class _EntrepriseSettingsScreenState extends State<EntrepriseSettingsScreen> {
  final _service = UsersService();
  final _formKey = GlobalKey<FormState>();
  final _securityKey = GlobalKey<FormState>();

  final _nomEntrepriseCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _secteurCtrl = TextEditingController();
  final _tailleCtrl = TextEditingController();
  final _siteCtrl = TextEditingController();
  final _adresseSiegeCtrl = TextEditingController();
  final _logoUrlCtrl = TextEditingController();

  final _pwdCtrl = TextEditingController();
  final _pwdConfirmCtrl = TextEditingController();
  bool _obscurePwd = true;
  bool _obscureConfirm = true;

  bool _loading = true;
  bool _saving = false;
  String? _error;
  Map<String, dynamic>? _profil;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nomEntrepriseCtrl.dispose();
    _descriptionCtrl.dispose();
    _secteurCtrl.dispose();
    _tailleCtrl.dispose();
    _siteCtrl.dispose();
    _adresseSiegeCtrl.dispose();
    _logoUrlCtrl.dispose();
    _pwdCtrl.dispose();
    _pwdConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _service.getMe();
      final profil = r.profil ?? <String, dynamic>{};
      _profil = profil;
      _nomEntrepriseCtrl.text = profil['nom_entreprise']?.toString() ?? '';
      _descriptionCtrl.text = profil['description']?.toString() ?? '';
      _secteurCtrl.text = profil['secteur_activite']?.toString() ?? '';
      _tailleCtrl.text = profil['taille_entreprise']?.toString() ?? '';
      _siteCtrl.text = profil['site_web']?.toString() ?? '';
      _adresseSiegeCtrl.text = profil['adresse_siege']?.toString() ?? '';
      _logoUrlCtrl.text = profil['logo_url']?.toString() ?? '';
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _saveEntreprise() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await _service.updateMe({
        'nom_entreprise': _nomEntrepriseCtrl.text.trim().isEmpty ? null : _nomEntrepriseCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
        'secteur_activite': _secteurCtrl.text.trim().isEmpty ? null : _secteurCtrl.text.trim(),
        'taille_entreprise': _tailleCtrl.text.trim().isEmpty ? null : _tailleCtrl.text.trim(),
        'site_web': _siteCtrl.text.trim().isEmpty ? null : _siteCtrl.text.trim(),
        'adresse_siege': _adresseSiegeCtrl.text.trim().isEmpty ? null : _adresseSiegeCtrl.text.trim(),
        'logo_url': _logoUrlCtrl.text.trim().isEmpty ? null : _logoUrlCtrl.text.trim(),
      });
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paramètres entreprise mis à jour')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    if (_saving) return;
    if (!(_securityKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await _service.updateMe({
        'mot_de_passe': _pwdCtrl.text,
      });
      if (!mounted) return;
      _pwdCtrl.clear();
      _pwdConfirmCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe mis à jour')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user ?? const <String, dynamic>{};
    final email = user['email']?.toString() ?? '—';
    final role = user['role']?.toString() ?? '—';

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            FilledButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    const orange = Color(0xFFFF8A00);
    final profilId = _profil?['id']?.toString();

    return ResponsiveContainer(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Text(
              'Paramètres',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Gérez les informations de votre entreprise et la sécurité du compte.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            RevealOnScroll(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Compte', style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _InfoChip(icon: Icons.mail, label: email),
                          _InfoChip(icon: Icons.badge, label: 'Rôle : $role'),
                          if (profilId != null) _InfoChip(icon: Icons.fingerprint, label: 'Entreprise ID : $profilId'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Astuce : remplissez au moins le nom entreprise et le site web pour une meilleure visibilité.',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            RevealOnScroll(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Entreprise', style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nomEntrepriseCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nom entreprise',
                            prefixIcon: Icon(Icons.apartment_outlined),
                            isDense: true,
                          ),
                          validator: (v) {
                            final s = (v ?? '').trim();
                            if (s.isEmpty) return null;
                            if (s.length > 200) return 'Max 200 caractères';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _secteurCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Secteur d’activité',
                            prefixIcon: Icon(Icons.category_outlined),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _tailleCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Taille entreprise',
                            prefixIcon: Icon(Icons.groups_outlined),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _siteCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Site web',
                            prefixIcon: Icon(Icons.link),
                            isDense: true,
                          ),
                          validator: (v) {
                            final s = (v ?? '').trim();
                            if (s.isEmpty) return null;
                            final ok = Uri.tryParse(s);
                            if (ok == null || !(ok.hasScheme && ok.host.isNotEmpty)) {
                              return 'URL invalide (ex: https://entreprise.com)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _adresseSiegeCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Adresse siège',
                            prefixIcon: Icon(Icons.place_outlined),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _logoUrlCtrl,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Logo URL',
                            prefixIcon: Icon(Icons.image_outlined),
                            isDense: true,
                          ),
                          validator: (v) {
                            final s = (v ?? '').trim();
                            if (s.isEmpty) return null;
                            final ok = Uri.tryParse(s);
                            if (ok == null || !(ok.hasScheme && ok.host.isNotEmpty)) {
                              return 'URL invalide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            prefixIcon: Icon(Icons.subject_outlined),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _saving ? null : _load,
                                child: const Text('Réinitialiser'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: _saving ? null : _saveEntreprise,
                                icon: _saving
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.check),
                                label: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            RevealOnScroll(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Form(
                    key: _securityKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sécurité', style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pwdCtrl,
                          obscureText: _obscurePwd,
                          decoration: InputDecoration(
                            labelText: 'Nouveau mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline),
                            isDense: true,
                            suffixIcon: IconButton(
                              tooltip: _obscurePwd ? 'Afficher' : 'Masquer',
                              onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                              icon: Icon(_obscurePwd ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                          validator: (v) {
                            final s = (v ?? '');
                            if (s.isEmpty) return null; // pas obligatoire
                            if (s.length < 8) return 'Minimum 8 caractères';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pwdConfirmCtrl,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Confirmer le mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline),
                            isDense: true,
                            suffixIcon: IconButton(
                              tooltip: _obscureConfirm ? 'Afficher' : 'Masquer',
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                          validator: (v) {
                            final pwd = _pwdCtrl.text;
                            final confirm = (v ?? '');
                            if (pwd.isEmpty && confirm.isEmpty) return null;
                            if (pwd.isEmpty) return 'Entrez un mot de passe';
                            if (confirm.isEmpty) return 'Confirmez le mot de passe';
                            if (pwd != confirm) return 'Les mots de passe ne correspondent pas';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Laissez vide si vous ne voulez pas changer le mot de passe.',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _saving
                                ? null
                                : () {
                                    if (_pwdCtrl.text.isEmpty && _pwdConfirmCtrl.text.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Renseignez un nouveau mot de passe')),
                                      );
                                      return;
                                    }
                                    _changePassword();
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: scheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.security),
                            label: const Text('Mettre à jour'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

