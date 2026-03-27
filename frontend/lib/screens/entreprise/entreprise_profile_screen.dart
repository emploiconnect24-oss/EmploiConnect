import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/users_service.dart';
import '../../widgets/responsive_container.dart';
import '../../widgets/reveal_on_scroll.dart';

class EntrepriseProfileScreen extends StatefulWidget {
  const EntrepriseProfileScreen({super.key});

  @override
  State<EntrepriseProfileScreen> createState() => _EntrepriseProfileScreenState();
}

class _EntrepriseProfileScreenState extends State<EntrepriseProfileScreen> {
  final _service = UsersService();
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _sloganCtrl = TextEditingController();
  final _secteurCtrl = TextEditingController();
  final _tailleCtrl = TextEditingController();
  final _anneeCtrl = TextEditingController();
  final _siteCtrl = TextEditingController();
  final _emailPublicCtrl = TextEditingController();
  final _telPublicCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  final _missionCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();
  final _banniereCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _twitterCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _hasUnsavedChanges = false;
  String? _error;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _profil;
  List<String> _values = [];
  Set<String> _benefits = {};

  static const _benefitsOptions = [
    'Assurance maladie',
    'Transport',
    'Logement',
    'Formation',
    'Bonus annuel',
    'Téléphone professionnel',
    'Repas',
    'Congés payés',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _sloganCtrl.dispose();
    _secteurCtrl.dispose();
    _tailleCtrl.dispose();
    _anneeCtrl.dispose();
    _siteCtrl.dispose();
    _emailPublicCtrl.dispose();
    _telPublicCtrl.dispose();
    _adresseCtrl.dispose();
    _aboutCtrl.dispose();
    _missionCtrl.dispose();
    _logoCtrl.dispose();
    _banniereCtrl.dispose();
    _linkedinCtrl.dispose();
    _facebookCtrl.dispose();
    _twitterCtrl.dispose();
    _instagramCtrl.dispose();
    _whatsappCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _service.getMe();
      _user = r.user;
      _profil = r.profil ?? <String, dynamic>{};
      _nomCtrl.text = _profil?['nom_entreprise']?.toString() ?? r.user['nom']?.toString() ?? '';
      _sloganCtrl.text = _profil?['slogan']?.toString() ?? '';
      _secteurCtrl.text = _profil?['secteur_activite']?.toString() ?? '';
      _tailleCtrl.text = _profil?['taille_entreprise']?.toString() ?? '';
      _anneeCtrl.text = _profil?['annee_fondation']?.toString() ?? '';
      _siteCtrl.text = _profil?['site_web']?.toString() ?? '';
      _emailPublicCtrl.text = _profil?['email_public']?.toString() ?? r.user['email']?.toString() ?? '';
      _telPublicCtrl.text = _profil?['telephone_public']?.toString() ?? r.user['telephone']?.toString() ?? '';
      _adresseCtrl.text = _profil?['adresse_siege']?.toString() ?? r.user['adresse']?.toString() ?? '';
      _aboutCtrl.text = _profil?['description']?.toString() ?? '';
      _missionCtrl.text = _profil?['mission']?.toString() ?? '';
      _logoCtrl.text = _profil?['logo_url']?.toString() ?? '';
      _banniereCtrl.text = _profil?['cover_url']?.toString() ?? '';
      _linkedinCtrl.text = _profil?['linkedin']?.toString() ?? '';
      _facebookCtrl.text = _profil?['facebook']?.toString() ?? '';
      _twitterCtrl.text = _profil?['twitter']?.toString() ?? '';
      _instagramCtrl.text = _profil?['instagram']?.toString() ?? '';
      _whatsappCtrl.text = _profil?['whatsapp_business']?.toString() ?? '';
      _values = (( _profil?['valeurs'] as List?) ?? const []).map((e) => e.toString()).toList();
      _benefits = (((_profil?['avantages'] as List?) ?? const []).map((e) => e.toString())).toSet();
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final updated = await _service.updateMe({
        'nom': _nomCtrl.text.trim(),
        'nom_entreprise': _nomCtrl.text.trim(),
        'slogan': _sloganCtrl.text.trim().isEmpty ? null : _sloganCtrl.text.trim(),
        'secteur_activite': _secteurCtrl.text.trim().isEmpty ? null : _secteurCtrl.text.trim(),
        'taille_entreprise': _tailleCtrl.text.trim().isEmpty ? null : _tailleCtrl.text.trim(),
        'annee_fondation': _anneeCtrl.text.trim().isEmpty ? null : _anneeCtrl.text.trim(),
        'site_web': _siteCtrl.text.trim().isEmpty ? null : _siteCtrl.text.trim(),
        'email_public': _emailPublicCtrl.text.trim().isEmpty ? null : _emailPublicCtrl.text.trim(),
        'telephone': _telPublicCtrl.text.trim().isEmpty ? null : _telPublicCtrl.text.trim(),
        'telephone_public': _telPublicCtrl.text.trim().isEmpty ? null : _telPublicCtrl.text.trim(),
        'adresse': _adresseCtrl.text.trim().isEmpty ? null : _adresseCtrl.text.trim(),
        'adresse_siege': _adresseCtrl.text.trim().isEmpty ? null : _adresseCtrl.text.trim(),
        'description': _aboutCtrl.text.trim().isEmpty ? null : _aboutCtrl.text.trim(),
        'mission': _missionCtrl.text.trim().isEmpty ? null : _missionCtrl.text.trim(),
        'logo_url': _logoCtrl.text.trim().isEmpty ? null : _logoCtrl.text.trim(),
        'cover_url': _banniereCtrl.text.trim().isEmpty ? null : _banniereCtrl.text.trim(),
        'linkedin': _linkedinCtrl.text.trim().isEmpty ? null : _linkedinCtrl.text.trim(),
        'facebook': _facebookCtrl.text.trim().isEmpty ? null : _facebookCtrl.text.trim(),
        'twitter': _twitterCtrl.text.trim().isEmpty ? null : _twitterCtrl.text.trim(),
        'instagram': _instagramCtrl.text.trim().isEmpty ? null : _instagramCtrl.text.trim(),
        'whatsapp_business': _whatsappCtrl.text.trim().isEmpty ? null : _whatsappCtrl.text.trim(),
        'valeurs': _values,
        'avantages': _benefits.toList(),
      });
      if (!mounted) return;
      await context.read<AuthProvider>().loadSession();
      if (!mounted) return;
      setState(() {
        _user = updated;
        _hasUnsavedChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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

    final email = _user?['email']?.toString() ?? '—';
    final role = _user?['role']?.toString() ?? 'entreprise';

    return ResponsiveContainer(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Text(
              'Profil entreprise',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Gérez les informations visibles et utiles au recrutement.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            RevealOnScroll(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _InfoChip(icon: Icons.mail, label: email),
                      _InfoChip(icon: Icons.badge, label: 'Rôle : $role'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              onChanged: () => setState(() => _hasUnsavedChanges = true),
              child: Column(
                children: [
                  _sectionCard(
                    title: '1) Identité visuelle',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _banniereCtrl,
                          decoration: const InputDecoration(labelText: 'URL bannière', isDense: true),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _logoCtrl,
                          decoration: const InputDecoration(labelText: 'URL logo', isDense: true),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _nomCtrl,
                          decoration: const InputDecoration(labelText: 'Nom entreprise *', isDense: true),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _sloganCtrl,
                          maxLength: 120,
                          decoration: const InputDecoration(labelText: 'Slogan / Tagline', isDense: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: '2) Informations générales',
                    child: Column(
                      children: [
                        TextFormField(controller: _secteurCtrl, decoration: const InputDecoration(labelText: 'Secteur', isDense: true)),
                        const SizedBox(height: 10),
                        TextFormField(controller: _tailleCtrl, decoration: const InputDecoration(labelText: 'Taille entreprise', isDense: true)),
                        const SizedBox(height: 10),
                        TextFormField(controller: _anneeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Année de fondation', isDense: true)),
                        const SizedBox(height: 10),
                        TextFormField(controller: _siteCtrl, decoration: const InputDecoration(labelText: 'Site web', isDense: true)),
                        const SizedBox(height: 10),
                        TextFormField(controller: _emailPublicCtrl, decoration: const InputDecoration(labelText: 'Email public', isDense: true)),
                        const SizedBox(height: 10),
                        TextFormField(controller: _telPublicCtrl, decoration: const InputDecoration(labelText: 'Téléphone public', isDense: true)),
                        const SizedBox(height: 10),
                        TextFormField(controller: _adresseCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Adresse complète', alignLabelWithHint: true)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: '3) Description & culture',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(controller: _aboutCtrl, maxLines: 5, decoration: const InputDecoration(labelText: 'À propos', alignLabelWithHint: true)),
                        const SizedBox(height: 10),
                        TextFormField(controller: _missionCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Mission', alignLabelWithHint: true)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _valueCtrl,
                                decoration: const InputDecoration(labelText: 'Ajouter une valeur', isDense: true),
                                onFieldSubmitted: (_) {
                                  final v = _valueCtrl.text.trim();
                                  if (v.isEmpty || _values.length >= 5 || _values.contains(v)) return;
                                  setState(() {
                                    _values.add(v);
                                    _valueCtrl.clear();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () {
                                final v = _valueCtrl.text.trim();
                                if (v.isEmpty || _values.length >= 5 || _values.contains(v)) return;
                                setState(() {
                                  _values.add(v);
                                  _valueCtrl.clear();
                                });
                              },
                              child: const Text('Ajouter'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _values
                              .map((v) => InputChip(label: Text(v), onDeleted: () => setState(() => _values.remove(v))))
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        const Text('Avantages employeur'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _benefitsOptions
                              .map(
                                (b) => FilterChip(
                                  label: Text(b),
                                  selected: _benefits.contains(b),
                                  onSelected: (v) => setState(() => v ? _benefits.add(b) : _benefits.remove(b)),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: '4) Réseaux sociaux',
                    child: Column(
                      children: [
                        TextFormField(controller: _linkedinCtrl, decoration: const InputDecoration(labelText: 'LinkedIn', isDense: true)),
                        const SizedBox(height: 10),
                        TextFormField(controller: _facebookCtrl, decoration: const InputDecoration(labelText: 'Facebook', isDense: true)),
                        const SizedBox(height: 10),
                        TextFormField(controller: _twitterCtrl, decoration: const InputDecoration(labelText: 'Twitter / X', isDense: true)),
                        const SizedBox(height: 10),
                        TextFormField(controller: _instagramCtrl, decoration: const InputDecoration(labelText: 'Instagram', isDense: true)),
                        const SizedBox(height: 10),
                        TextFormField(controller: _whatsappCtrl, decoration: const InputDecoration(labelText: 'WhatsApp Business', isDense: true)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: '5) Aperçu public',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_nomCtrl.text.trim().isEmpty ? 'Nom entreprise' : _nomCtrl.text.trim(),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                        if (_sloganCtrl.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(_sloganCtrl.text.trim(), style: TextStyle(color: scheme.onSurfaceVariant)),
                        ],
                        const SizedBox(height: 8),
                        Text('Secteur: ${_secteurCtrl.text.trim().isEmpty ? '-' : _secteurCtrl.text.trim()}'),
                        Text('Taille: ${_tailleCtrl.text.trim().isEmpty ? '-' : _tailleCtrl.text.trim()}'),
                        Text('Ville/Adresse: ${_adresseCtrl.text.trim().isEmpty ? '-' : _adresseCtrl.text.trim()}'),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Voir mon profil public'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_hasUnsavedChanges)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Modifications non enregistrées', style: TextStyle(color: scheme.error)),
                    ),
                  const SizedBox(height: 8),
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
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check),
                          label: Text(_saving ? 'Enregistrement…' : 'Sauvegarder les modifications'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}

extension on _EntrepriseProfileScreenState {
  Widget _sectionCard({required String title, required Widget child}) {
    return RevealOnScroll(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              child,
            ],
          ),
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

