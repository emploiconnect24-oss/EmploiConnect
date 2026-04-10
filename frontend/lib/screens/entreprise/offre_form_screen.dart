import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool _isAmeliorantDesc = false;

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

  Future<void> _ameliorerDescriptionIA() async {
    if (_descriptionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💡 Écrivez d\'abord quelques mots sur le poste'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isAmeliorantDesc = true);
    try {
      final res = await _service.ameliorerDescription(
        descriptionOriginale: _descriptionCtrl.text.trim(),
        titrePoste: _titreCtrl.text.trim(),
        competencesRequises: _skills,
        typeContrat: _contractType ?? '',
      );

      if (res['success'] == true) {
        final descAmelioree = (res['data']?['description_amelioree'] ?? '').toString();
        if (!mounted || descAmelioree.isEmpty) return;

        await showDialog<void>(
          context: context,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF7C3AED),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Description améliorée par l\'IA',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      descAmelioree,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF374151),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Garder l\'original',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Utiliser ce texte'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () {
                            setState(() => _descriptionCtrl.text = descAmelioree);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur IA: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAmeliorantDesc = false);
    }
  }

  Widget _buildDescriptionField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Description du poste *',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _ameliorerDescriptionIA,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A56DB), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isAmeliorantDesc
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                      const SizedBox(width: 5),
                      Text(
                        _isAmeliorantDesc ? 'IA en cours...' : '✨ Rédiger avec l\'IA',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionCtrl,
            maxLines: 12,
            minLines: 8,
            maxLength: 5000,
            decoration: InputDecoration(
              hintText: 'Décrivez le poste en détail (missions, contexte, objectifs, environnement, outils, organisation, livrables...)',
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFFCBD5E1),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1A56DB), width: 1.5),
              ),
            ),
          ),
        ],
      );

  Widget _buildGradientHeader() {
    final isNew = widget.offreId == null;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.work_outline_rounded, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isNew ? 'Publier une offre d\'emploi' : 'Modifier l\'offre',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                Text(
                  'Remplissez les informations ci-dessous',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text('IA activée', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepConnector(bool filled) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: filled ? const Color(0xFF1A56DB) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _buildStepIndicatorRow() {
    const steps = ['Infos générales', 'Description', 'Compétences', 'Publication'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0) _stepConnector(_currentStep > i),
              _OffreFormStepChip(
                step: i + 1,
                label: steps[i],
                selected: _currentStep == i,
                done: _currentStep > i,
                onTap: () => setState(() => _currentStep = i),
              ),
            ],
          ],
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
            _buildDescriptionField(),
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

  Widget _buildPreviewField(String label, String value, {bool longText = false}) {
    final v = value.trim();
    final display = v.isEmpty ? '—' : v;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          if (longText && display != '—')
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  display,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            )
          else
            Text(
              display,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Color(0xFF334155),
              ),
              maxLines: longText ? 6 : 3,
              overflow: TextOverflow.ellipsis,
            ),
        ],
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
            const Text(
              'Aperçu de l’offre',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Vérification avant publication',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            _buildPreviewField('Titre', _titreCtrl.text),
            _buildPreviewField('Secteur', _sector ?? ''),
            _buildPreviewField('Contrat', _contractType ?? ''),
            _buildPreviewField('Ville', _lieuCtrl.text),
            _buildPreviewField('Mode', _workMode),
            _buildPreviewField('Description', _descriptionCtrl.text, longText: true),
            const Divider(height: 28),
            const Text(
              'Options de publication',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
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
                        _buildGradientHeader(),
                        _buildStepIndicatorRow(),
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

class _OffreFormStepChip extends StatelessWidget {
  const _OffreFormStepChip({
    required this.step,
    required this.label,
    required this.selected,
    required this.done,
    required this.onTap,
  });

  final int step;
  final String label;
  final bool selected;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF1A56DB);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? primary.withValues(alpha: 0.12) : (done ? const Color(0xFFF0FDF4) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? primary : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected || done ? primary : const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: done && !selected
                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                    : Text(
                        '$step',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: selected || done ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
