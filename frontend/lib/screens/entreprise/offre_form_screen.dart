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
  final _titreCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _aboutCompanyCtrl = TextEditingController(text: 'Entreprise locale innovante en croissance.');
  final _addressCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();
  final _missionCtrl = TextEditingController();
  final _lieuCtrl = TextEditingController();
  final _salaireMinCtrl = TextEditingController();
  final _salaireMaxCtrl = TextEditingController();
  final _deadlineCtrl = TextEditingController();
  final _scheduledCtrl = TextEditingController();
  int _currentStep = 0;
  int _positions = 1;
  String? _sector;
  String? _contractType;
  String _workMode = 'Présentiel';
  String _education = 'Licence';
  String _experience = '1-2 ans';
  String _publishOption = 'now';
  DateTime? _deadline;
  DateTime? _scheduledDate;
  final List<String> _missions = [];
  final List<String> _skills = [];
  final Set<String> _languages = {'Français'};
  final Set<String> _benefits = {};
  bool _loading = false;
  bool _loadExisting = false;
  bool _isSavingDraft = false;

  static const _sectors = [
    'Technologie',
    'Finance',
    'Santé',
    'Éducation',
    'Commerce',
    'BTP',
    'Transport',
    'Télécom',
    'Administration',
  ];
  static const _contracts = ['CDI', 'CDD', 'Stage', 'Freelance', 'Temps partiel'];
  static const _cities = [
    'Conakry',
    'Kindia',
    'Kankan',
    'Labé',
    'Nzérékoré',
    'Boké',
    'Mamou',
    'Faranah',
  ];
  static const _educations = ['BEPC', 'Bac', 'Licence', 'Master', 'Doctorat', 'Sans diplôme'];
  static const _experiences = ['Sans expérience', '1-2 ans', '3-5 ans', '5-10 ans', '10+ ans'];
  static const _languagesOptions = ['Français', 'Anglais', 'Pular', 'Malinké', 'Soussou'];
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
    if (widget.offreId != null) {
      _loadExisting = true;
      _fetch();
    }
  }

  Future<void> _fetch() async {
    try {
      final o = await _service.getOffreById(widget.offreId!);
      _titreCtrl.text = o['titre']?.toString() ?? '';
      _descriptionCtrl.text = o['description']?.toString() ?? '';
      _lieuCtrl.text = o['localisation']?.toString() ?? '';
      _sector = o['domaine']?.toString();
      _contractType = o['type_contrat']?.toString();
      _salaireMinCtrl.text = o['salaire_min']?.toString() ?? '';
      _salaireMaxCtrl.text = o['salaire_max']?.toString() ?? '';
    } catch (_) {}
    setState(() => _loadExisting = false);
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descriptionCtrl.dispose();
    _aboutCompanyCtrl.dispose();
    _addressCtrl.dispose();
    _skillCtrl.dispose();
    _missionCtrl.dispose();
    _lieuCtrl.dispose();
    _salaireMinCtrl.dispose();
    _salaireMaxCtrl.dispose();
    _deadlineCtrl.dispose();
    _scheduledCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool draft}) async {
    setState(() => _loading = true);
    final smin = int.tryParse(_salaireMinCtrl.text.trim());
    final smax = int.tryParse(_salaireMaxCtrl.text.trim());
    if (smin != null && smax != null && smax < smin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salaire max doit être ≥ salaire min')),
        );
      }
      setState(() => _loading = false);
      return;
    }

    final description = _descriptionCtrl.text.trim();
    final missionLines = _missions.isEmpty ? '' : '\n\nMissions:\n- ${_missions.join('\n- ')}';
    final about = _aboutCompanyCtrl.text.trim().isEmpty ? '' : '\n\nÀ propos de l\'entreprise:\n${_aboutCompanyCtrl.text.trim()}';
    final exigences = <String>[
      if (_education.isNotEmpty) 'Niveau: $_education',
      if (_experience.isNotEmpty) 'Expérience: $_experience',
      if (_skills.isNotEmpty) 'Compétences: ${_skills.join(', ')}',
      if (_languages.isNotEmpty) 'Langues: ${_languages.join(', ')}',
      if (_benefits.isNotEmpty) 'Avantages: ${_benefits.join(', ')}',
      if (_positions > 0) 'Postes: $_positions',
      if (_workMode.isNotEmpty) 'Mode: $_workMode',
    ].join('\n');

    final body = <String, dynamic>{
      'titre': _titreCtrl.text.trim(),
      'description': '$description$missionLines$about',
      'exigences': exigences,
      'localisation': _lieuCtrl.text.trim().isEmpty ? null : _lieuCtrl.text.trim(),
      'domaine': _sector,
      'type_contrat': _contractType?.toLowerCase(),
      'adresse': _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      'mode_travail': _workMode.toLowerCase(),
      'niveau_etudes': _education,
      'experience': _experience,
      'competences': _skills,
      'langues': _languages.toList(),
      'avantages': _benefits.toList(),
      'nombre_postes': _positions,
      'date_limite': _deadline?.toIso8601String(),
      'devise': 'GNF',
      'statut': draft
          ? 'brouillon'
          : (_publishOption == 'schedule' ? 'attente' : 'active'),
    };
    if (smin != null) body['salaire_min'] = smin;
    if (smax != null) body['salaire_max'] = smax;
    if (_publishOption == 'schedule' && _scheduledDate != null) {
      body['date_publication'] = _scheduledDate!.toIso8601String();
    }

    try {
      if (widget.offreId == null) {
        await _service.createOffre(body);
      } else {
        await _service.updateOffre(widget.offreId!, body);
      }
      if (mounted) {
        if (draft) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Brouillon sauvegardé')));
          Navigator.of(context).pop();
        } else {
          _showSuccessDialog();
        }
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

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Offre publiée'),
        content: const Text('Votre offre est visible par les candidats.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      final title = _titreCtrl.text.trim();
      if (title.isEmpty || title.length > 80) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le titre est requis (max 80 caractères).')),
        );
        return false;
      }
      if (_sector == null || _contractType == null || _lieuCtrl.text.trim().isEmpty || _deadline == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complète les champs obligatoires de l’étape 1.')),
        );
        return false;
      }
    }
    if (_currentStep == 1) {
      if (_descriptionCtrl.text.trim().length < 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La description doit contenir au moins 100 caractères.')),
        );
        return false;
      }
      if (_missions.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajoute au moins 3 missions.')),
        );
        return false;
      }
    }
    if (_currentStep == 2 && _skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoute au moins une compétence.')),
      );
      return false;
    }
    if (_currentStep == 3 && _publishOption == 'schedule' && _scheduledDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionne une date de planification.')),
      );
      return false;
    }
    return true;
  }

  Future<void> _pickDate({required bool schedule}) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (d == null) return;
    final formatted = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    setState(() {
      if (schedule) {
        _scheduledDate = d;
        _scheduledCtrl.text = formatted;
      } else {
        _deadline = d;
        _deadlineCtrl.text = formatted;
      }
    });
  }

  void _addMission() {
    final value = _missionCtrl.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _missions.add(value);
      _missionCtrl.clear();
    });
  }

  void _addSkill() {
    final value = _skillCtrl.text.trim();
    if (value.isEmpty || _skills.contains(value) || _skills.length >= 10) return;
    setState(() {
      _skills.add(value);
      _skillCtrl.clear();
    });
  }

  Widget _buildStepper() {
    const labels = ['Informations', 'Description', 'Prérequis', 'Publication'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        labels.length,
        (i) => ChoiceChip(
          label: Text('${i + 1}. ${labels[i]}'),
          selected: _currentStep == i,
          onSelected: (_) => setState(() => _currentStep = i),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titreCtrl,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Titre du poste *', isDense: true),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _sector,
              decoration: const InputDecoration(labelText: 'Secteur *', isDense: true),
              items: _sectors.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _sector = v),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _contracts
                  .map(
                    (c) => ChoiceChip(
                      label: Text(c),
                      selected: _contractType == c,
                      onSelected: (_) => setState(() => _contractType = c),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _lieuCtrl.text.isEmpty ? null : _lieuCtrl.text,
              decoration: const InputDecoration(labelText: 'Ville *', isDense: true),
              items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _lieuCtrl.text = v ?? ''),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Adresse précise (optionnel)', isDense: true),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['Présentiel', 'Hybride', 'Télétravail']
                  .map(
                    (m) => ChoiceChip(
                      label: Text(m),
                      selected: _workMode == m,
                      onSelected: (_) => setState(() => _workMode = m),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _salaireMinCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Salaire min', isDense: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _salaireMaxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Salaire max', isDense: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _deadlineCtrl,
              readOnly: true,
              onTap: () => _pickDate(schedule: false),
              decoration: const InputDecoration(
                labelText: 'Date limite candidature *',
                suffixIcon: Icon(Icons.calendar_month_outlined),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Postes à pourvoir:'),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _positions > 1 ? () => setState(() => _positions--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_positions'),
                IconButton(
                  onPressed: () => setState(() => _positions++),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _descriptionCtrl,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Description du poste * (min 100 caractères)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _missionCtrl,
                    decoration: const InputDecoration(labelText: 'Ajouter une mission', isDense: true),
                    onFieldSubmitted: (_) => _addMission(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(onPressed: _addMission, icon: const Icon(Icons.add), label: const Text('Ajouter')),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                _missions.length,
                (i) => InputChip(
                  label: Text(_missions[i]),
                  onDeleted: () => setState(() => _missions.removeAt(i)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _aboutCompanyCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'À propos de l’entreprise', alignLabelWithHint: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _education,
              decoration: const InputDecoration(labelText: 'Niveau d’études', isDense: true),
              items: _educations.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _education = v ?? _education),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _experience,
              decoration: const InputDecoration(labelText: 'Expérience', isDense: true),
              items: _experiences.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _experience = v ?? _experience),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _skillCtrl,
                    decoration: const InputDecoration(labelText: 'Compétence (max 10)', isDense: true),
                    onFieldSubmitted: (_) => _addSkill(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(onPressed: _addSkill, icon: const Icon(Icons.add), label: const Text('Ajouter')),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills
                  .map((s) => InputChip(label: Text(s), onDeleted: () => setState(() => _skills.remove(s))))
                  .toList(),
            ),
            const SizedBox(height: 12),
            const Text('Langues requises'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _languagesOptions
                  .map(
                    (l) => FilterChip(
                      label: Text(l),
                      selected: _languages.contains(l),
                      onSelected: (v) => setState(() => v ? _languages.add(l) : _languages.remove(l)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            const Text('Avantages proposés'),
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
    );
  }

  Widget _buildPreviewLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: value.isEmpty ? '-' : value),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Aperçu de l’offre', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            _buildPreviewLine('Titre', _titreCtrl.text.trim()),
            _buildPreviewLine('Secteur', _sector ?? ''),
            _buildPreviewLine('Contrat', _contractType ?? ''),
            _buildPreviewLine('Ville', _lieuCtrl.text.trim()),
            _buildPreviewLine('Mode', _workMode),
            _buildPreviewLine('Description', _descriptionCtrl.text.trim()),
            const Divider(height: 24),
            const Text('Options de publication', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'now', label: Text('Publier maintenant')),
                ButtonSegment(value: 'schedule', label: Text('Planifier')),
                ButtonSegment(value: 'draft', label: Text('Brouillon')),
              ],
              selected: {_publishOption},
              onSelectionChanged: (value) => setState(() => _publishOption = value.first),
            ),
            if (_publishOption == 'schedule')
              TextFormField(
                controller: _scheduledCtrl,
                readOnly: true,
                onTap: () => _pickDate(schedule: true),
                decoration: const InputDecoration(
                  labelText: 'Date de publication',
                  suffixIcon: Icon(Icons.event_outlined),
                  isDense: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    if (_currentStep == 0) return _buildStep1();
    if (_currentStep == 1) return _buildStep2();
    if (_currentStep == 2) return _buildStep3();
    return _buildStep4();
  }

  Widget _buildTipsPanel() {
    const tips = [
      [
        'Choisis un titre clair et précis.',
        'Indique le salaire pour améliorer les candidatures.',
      ],
      [
        'Liste 5 à 8 missions avec verbes d’action.',
        'La description doit être concrète et attractive.',
      ],
      [
        'Ajoute les compétences clés du poste.',
        'Précise les avantages pour te différencier.',
      ],
      [
        'Vérifie l’aperçu avant publication.',
        'Planifie la diffusion si nécessaire.',
      ],
    ];
    final current = tips[_currentStep];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Conseils', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ...current.map((t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('• $t'))),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    final isLast = _currentStep == 3;
    return Row(
      children: [
        if (_currentStep > 0)
          OutlinedButton.icon(
            onPressed: _loading ? null : () => setState(() => _currentStep--),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Précédent'),
          ),
        const Spacer(),
        TextButton(
          onPressed: (_loading || _isSavingDraft)
              ? null
              : () async {
                  setState(() => _isSavingDraft = true);
                  await _submit(draft: true);
                  if (mounted) setState(() => _isSavingDraft = false);
                },
          child: Text(_isSavingDraft ? 'Sauvegarde...' : 'Sauvegarder brouillon'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _loading
              ? null
              : () async {
                  if (!isLast) {
                    if (_validateCurrentStep()) {
                      setState(() => _currentStep++);
                    }
                    return;
                  }
                  if (!_validateCurrentStep()) return;
                  if (_publishOption == 'draft') {
                    await _submit(draft: true);
                  } else {
                    await _submit(draft: false);
                  }
                },
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Icon(isLast ? Icons.check_circle_outline : Icons.arrow_forward),
          label: Text(isLast ? 'Publier l’offre' : 'Continuer'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadExisting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.offreId == null ? 'Publier une offre' : 'Modifier l’offre'),
      ),
      body: SingleChildScrollView(
        child: ResponsiveContainer(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 1100;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(0, 12, 0, 22),
                      shrinkWrap: true,
                      children: [
                        Text(
                          widget.offreId == null ? 'Créer une offre' : 'Mettre à jour l’offre',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        const Text('Formulaire multi-étapes pour publier plus vite et mieux.'),
                        const SizedBox(height: 12),
                        _buildStepper(),
                        const SizedBox(height: 12),
                        RevealOnScroll(child: _buildStepContent()),
                        const SizedBox(height: 12),
                        _buildActions(),
                      ],
                    ),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: _buildTipsPanel()),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
