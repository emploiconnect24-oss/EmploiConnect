import 'package:flutter/material.dart';
import '../../services/offres_service.dart';
import '../../widgets/responsive_container.dart';
import '../../widgets/reveal_on_scroll.dart';

/// Création (offreId null) ou édition d’une offre.
class OffreFormScreen extends StatefulWidget {
  const OffreFormScreen({super.key, this.offreId});

  final String? offreId;

  @override
  State<OffreFormScreen> createState() => _OffreFormScreenState();
}

class _OffreFormScreenState extends State<OffreFormScreen> {
  final _service = OffresService();
  final _formKey = GlobalKey<FormState>();
  final _titreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _exigCtrl = TextEditingController();
  final _lieuCtrl = TextEditingController();
  final _domaineCtrl = TextEditingController();
  final _salaireMinCtrl = TextEditingController();
  final _salaireMaxCtrl = TextEditingController();
  bool _loading = false;
  bool _loadExisting = false;

  @override
  void initState() {
    super.initState();
    if (widget.offreId != null) {
      _loadExisting = true;
      _fetch();
    }
  }

  Future<void> _fetch() async {
    try {
      final o = await _service.getOffreById(widget.offreId!);
      _titreCtrl.text = o['titre']?.toString() ?? '';
      _descCtrl.text = o['description']?.toString() ?? '';
      _exigCtrl.text = o['exigences']?.toString() ?? '';
      _lieuCtrl.text = o['localisation']?.toString() ?? '';
      _domaineCtrl.text = o['domaine']?.toString() ?? '';
      _salaireMinCtrl.text = o['salaire_min']?.toString() ?? '';
      _salaireMaxCtrl.text = o['salaire_max']?.toString() ?? '';
    } catch (_) {}
    setState(() => _loadExisting = false);
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descCtrl.dispose();
    _exigCtrl.dispose();
    _lieuCtrl.dispose();
    _domaineCtrl.dispose();
    _salaireMinCtrl.dispose();
    _salaireMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    final body = <String, dynamic>{
      'titre': _titreCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'exigences': _exigCtrl.text.trim(),
      'localisation': _lieuCtrl.text.trim().isEmpty ? null : _lieuCtrl.text.trim(),
      'domaine': _domaineCtrl.text.trim().isEmpty ? null : _domaineCtrl.text.trim(),
      'devise': 'GNF',
    };
    final smin = int.tryParse(_salaireMinCtrl.text.trim());
    final smax = int.tryParse(_salaireMaxCtrl.text.trim());
    if (smin != null) body['salaire_min'] = smin;
    if (smax != null) body['salaire_max'] = smax;
    if (smin != null && smax != null && smax < smin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salaire max doit être ≥ salaire min')),
        );
      }
      setState(() => _loading = false);
      return;
    }

    try {
      if (widget.offreId == null) {
        await _service.createOffre(body);
      } else {
        await _service.updateOffre(widget.offreId!, body);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enregistré')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadExisting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    const orange = Color(0xFFFF8A00);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.offreId == null ? 'Nouvelle offre' : 'Modifier l’offre'),
      ),
      body: SingleChildScrollView(
        child: ResponsiveContainer(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 22),
              shrinkWrap: true,
              children: [
                Text(
                  widget.offreId == null ? 'Créer une offre' : 'Mettre à jour l’offre',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Les champs marqués * sont obligatoires.',
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
                          const Text('Informations', style: TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _titreCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Titre *',
                              prefixIcon: Icon(Icons.title),
                              isDense: true,
                            ),
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return 'Titre requis';
                              if (s.length > 200) return 'Max 200 caractères';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _domaineCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Domaine',
                              prefixIcon: Icon(Icons.category_outlined),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _lieuCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Localisation',
                              prefixIcon: Icon(Icons.place_outlined),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _salaireMinCtrl,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Salaire min (GNF)',
                                    prefixIcon: Icon(Icons.payments_outlined),
                                    isDense: true,
                                  ),
                                  validator: (v) {
                                    final s = (v ?? '').trim();
                                    if (s.isEmpty) return null;
                                    final n = int.tryParse(s);
                                    if (n == null) return 'Nombre invalide';
                                    if (n < 0) return 'Doit être ≥ 0';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _salaireMaxCtrl,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Salaire max (GNF)',
                                    prefixIcon: Icon(Icons.payments_outlined),
                                    isDense: true,
                                  ),
                                  validator: (v) {
                                    final s = (v ?? '').trim();
                                    if (s.isEmpty) return null;
                                    final n = int.tryParse(s);
                                    if (n == null) return 'Nombre invalide';
                                    if (n < 0) return 'Doit être ≥ 0';
                                    return null;
                                  },
                                ),
                              ),
                            ],
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Contenu', style: TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Description *',
                              alignLabelWithHint: true,
                              prefixIcon: Icon(Icons.subject_outlined),
                            ),
                            maxLines: 6,
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return 'Description requise';
                              if (s.length > 8000) return 'Max 8000 caractères';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _exigCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Exigences *',
                              alignLabelWithHint: true,
                              prefixIcon: Icon(Icons.rule_folder_outlined),
                            ),
                            maxLines: 6,
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return 'Exigences requises';
                              if (s.length > 4000) return 'Max 4000 caractères';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading ? null : () => Navigator.of(context).maybePop(),
                        child: const Text('Annuler'),
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
                        onPressed: _loading ? null : _save,
                        icon: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check),
                        label: Text(_loading ? 'Enregistrement…' : 'Enregistrer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
