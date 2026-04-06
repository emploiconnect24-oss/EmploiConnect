import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_extension.dart';
import '../../providers/auth_provider.dart';
import '../../providers/candidat_provider.dart';
import '../../services/cv_service.dart';
import '../../services/matching_service.dart';
import '../../services/users_service.dart';
import '../../widgets/responsive_container.dart';

class CandidatProfileCvScreen extends StatefulWidget {
  const CandidatProfileCvScreen({super.key});

  @override
  State<CandidatProfileCvScreen> createState() =>
      _CandidatProfileCvScreenState();
}

class _CandidatProfileCvScreenState extends State<CandidatProfileCvScreen> {
  final _firstNameCtrl = TextEditingController(text: 'Mamadou');
  final _lastNameCtrl = TextEditingController(text: 'Barry');
  final _titleCtrl = TextEditingController(text: 'Développeur Flutter Senior');
  final _cityCtrl = TextEditingController(text: 'Conakry');
  final _phoneCtrl = TextEditingController(text: '+224 621 00 00 00');
  final _linkedinCtrl = TextEditingController();
  final _portfolioCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController(
    text:
        'Développeur mobile passionné avec expérience Flutter, Firebase et API REST. Je recherche un poste où je peux contribuer à des produits utiles à fort impact.',
  );

  String _availability = 'Immédiatement';
  String? _cvFileName;
  String? _photoFileName;
  Uint8List? _photoBytes;
  String? _photoUrl;
  bool _hasCv = false;
  bool _profileVisible = true;
  bool _allowRecruiterContact = true;
  bool _isAutoSaving = false;
  bool _isAnalysingCv = false;
  bool _isSaving = false;
  bool _isLoading = true;
  DateTime? _lastAutoSavedAt;
  Timer? _autoSaveTimer;
  final MatchingService _matchingService = MatchingService();
  final UsersService _usersService = UsersService();
  final CvService _cvService = CvService();

  final List<Map<String, String>> _experiences = [
    {
      'poste': 'Développeur Flutter',
      'entreprise': 'Orange Guinée',
      'ville': 'Conakry',
      'periode': '2023 - 2026',
      'mission':
          'Développement d’app mobile, optimisation des performances, tests.',
    },
  ];

  final List<Map<String, String>> _formations = [
    {
      'diplome': 'Licence Génie Logiciel',
      'ecole': 'Université de Conakry',
      'ville': 'Conakry',
      'annee': '2024',
    },
  ];

  final List<Map<String, String>> _skills = [
    {'name': 'Flutter', 'level': 'Avancé'},
    {'name': 'Dart', 'level': 'Avancé'},
    {'name': 'Firebase', 'level': 'Intermédiaire'},
  ];

  final List<Map<String, String>> _languages = [
    {'name': 'Français', 'level': 'Courant'},
    {'name': 'Anglais', 'level': 'Intermédiaire'},
  ];

  @override
  void initState() {
    super.initState();
    _bindAutoSaveListeners();
    unawaited(_loadProfile());
  }

  Future<void> _loadProfile() async {
    try {
      final me = await _usersService.getMe();
      final user = me.user;
      final profil = me.profil ?? <String, dynamic>{};
      final nom = (user['nom'] ?? '').toString().trim();
      final split = nom
          .split(RegExp(r'\s+'))
          .where((e) => e.trim().isNotEmpty)
          .toList();
      _firstNameCtrl.text = split.isNotEmpty ? split.first : '';
      _lastNameCtrl.text = split.length > 1 ? split.sublist(1).join(' ') : '';
      _cityCtrl.text = (user['adresse'] ?? '').toString();
      _phoneCtrl.text = (user['telephone'] ?? '').toString();
      _photoUrl = (user['photo_url'] ?? '').toString();
      _titleCtrl.text =
          (profil['titre_poste'] ?? profil['niveau_etude'] ?? '').toString();
      _aboutCtrl.text = (profil['about'] ?? '').toString();
      _availability = (profil['disponibilite'] ?? 'Immédiatement').toString();
      _profileVisible = user['privacy_profile_visible'] == true;
      _allowRecruiterContact = user['privacy_allow_direct_contact'] == true;
      final c = profil['competences'];
      if (c is List) {
        _skills
          ..clear()
          ..addAll(
            c.map((e) => {'name': e.toString(), 'level': 'Intermédiaire'}),
          );
      }
      try {
        final cv = await _cvService.getMonCv();
        _cvFileName = (cv['nom_fichier'] ?? '').toString().isEmpty
            ? null
            : cv['nom_fichier'].toString();
        _hasCv = _cvFileName != null;
      } catch (_) {
        _hasCv = false;
      }
    } catch (_) {
      // Keep page usable with local fallback values.
    } finally {
      if (mounted) {
        await context.read<CandidatProvider>().loadDashboardMetrics();
        setState(() => _isLoading = false);
      }
    }
  }

  void _bindAutoSaveListeners() {
    for (final ctrl in [
      _firstNameCtrl,
      _lastNameCtrl,
      _titleCtrl,
      _cityCtrl,
      _phoneCtrl,
      _linkedinCtrl,
      _portfolioCtrl,
      _aboutCtrl,
    ]) {
      ctrl.addListener(_scheduleAutoSave);
    }
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 850), () async {
      if (!mounted) return;
      setState(() => _isAutoSaving = true);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() {
        _isAutoSaving = false;
        _lastAutoSavedAt = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _titleCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    _linkedinCtrl.dispose();
    _portfolioCtrl.dispose();
    _aboutCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.size > 3 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo trop lourde (max 3MB).')),
      );
      return;
    }
    final bytes = file.bytes;
    if (bytes == null) return;
    try {
      final url = await _usersService.uploadMyPhoto(
        bytes: bytes,
        filename: file.name,
      );
      if (!mounted) return;
      setState(() {
        _photoFileName = file.name;
        _photoBytes = bytes;
        _photoUrl = url;
      });
      if (!mounted) return;
      await context.read<AuthProvider>().loadSession();
      if (!mounted) return;
      await context.read<CandidatProvider>().loadDashboardMetrics();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo mise à jour avec succès.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur upload photo: $e')));
    }
  }

  Future<void> _pickCv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    try {
      await _cvService.uploadCv(file.bytes!, file.name);
      if (!mounted) return;
      setState(() {
        _cvFileName = file.name;
        _hasCv = true;
      });
      if (!mounted) return;
      await context.read<CandidatProvider>().loadDashboardMetrics();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CV uploadé avec succès.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur upload CV: $e')));
    }
  }

  Future<void> _reanalyserCv() async {
    if (!_hasCv) return;
    setState(() => _isAnalysingCv = true);
    try {
      final res = await _matchingService.analyserCV();
      if (!mounted) return;
      await context.read<CandidatProvider>().loadDashboardMetrics();
      if (!mounted) return;
      final count = res['data']?['competences_count'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Analyse IA terminée: $count compétence(s) détectée(s).',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur analyse IA: $e')));
    } finally {
      if (mounted) setState(() => _isAnalysingCv = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final fullName =
          '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim();
      final competences = _skills
          .map((e) => e['name']?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
      await _usersService.updateMe({
        'nom': fullName,
        'telephone': _phoneCtrl.text.trim(),
        'adresse': _cityCtrl.text.trim(),
        if ((_photoUrl ?? '').trim().isNotEmpty) 'photo_url': _photoUrl!.trim(),
        'privacy_profile_visible': _profileVisible,
        'privacy_allow_direct_contact': _allowRecruiterContact,
        'titre_poste': _titleCtrl.text.trim(),
        'niveau_etude': _titleCtrl.text.trim(),
        'about': _aboutCtrl.text.trim(),
        'disponibilite': _availability,
        'competences': competences,
      });
      if (!mounted) return;
      await context.read<AuthProvider>().loadSession();
      if (!mounted) return;
      await context.read<CandidatProvider>().loadDashboardMetrics();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil enregistré.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur enregistrement: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addExperience() {
    setState(() {
      _experiences.add({
        'poste': 'Nouveau poste',
        'entreprise': 'Entreprise',
        'ville': 'Conakry',
        'periode': '2026 - ...',
        'mission': 'Décrivez vos missions.',
      });
    });
    _scheduleAutoSave();
  }

  void _addFormation() {
    setState(() {
      _formations.add({
        'diplome': 'Nouveau diplôme',
        'ecole': 'Établissement',
        'ville': 'Conakry',
        'annee': '2026',
      });
    });
    _scheduleAutoSave();
  }

  void _addSkill() {
    setState(
      () => _skills.add({'name': 'Nouvelle compétence', 'level': 'Débutant'}),
    );
    _scheduleAutoSave();
  }

  void _addLanguage() {
    setState(
      () => _languages.add({'name': 'Nouvelle langue', 'level': 'Notions'}),
    );
    _scheduleAutoSave();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final completionPct =
        context.watch<CandidatProvider>().profileCompletionPercent;
    final bottomInset = MediaQuery.of(context).size.width <= 900 ? 80.0 : 24.0;
    return ResponsiveContainer(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: LayoutBuilder(
        builder: (context, c) {
          final desktop = c.maxWidth >= 1100;
          return SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: desktop ? 7 : 1,
                  child: Column(
                    children: [
                      _completionHeader(completionPct),
                      const SizedBox(height: 12),
                      _sectionCard(
                        title: 'Photo & Identité',
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: const Color(0xFFEFF6FF),
                                  backgroundImage: _photoBytes != null
                                      ? MemoryImage(_photoBytes!)
                                      : ((_photoUrl ?? '').isNotEmpty
                                                ? NetworkImage(_photoUrl!)
                                                : null)
                                            as ImageProvider?,
                                  child:
                                      _photoBytes == null &&
                                          (_photoUrl ?? '').isEmpty
                                      ? const Text('MB')
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: _pickPhoto,
                                  icon: const Icon(Icons.photo_camera_outlined),
                                  label: Text(
                                    _photoFileName == null
                                        ? 'Changer photo'
                                        : 'Photo: ${_photoFileName!}',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _firstNameCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Prénom',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _lastNameCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Nom',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _titleCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Titre professionnel',
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _cityCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Ville',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _phoneCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Téléphone',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _linkedinCtrl,
                              decoration: const InputDecoration(
                                labelText: 'LinkedIn (optionnel)',
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _portfolioCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Portfolio (optionnel)',
                              ),
                            ),
                            const SizedBox(height: 10),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'Immédiatement',
                                  label: Text('Immédiatement'),
                                ),
                                ButtonSegment(
                                  value: '1 mois',
                                  label: Text('Dans 1 mois'),
                                ),
                                ButtonSegment(
                                  value: '3 mois',
                                  label: Text('Dans 3 mois'),
                                ),
                                ButtonSegment(
                                  value: 'En poste',
                                  label: Text('En poste'),
                                ),
                              ],
                              selected: {_availability},
                              onSelectionChanged: (v) {
                                setState(() => _availability = v.first);
                                _scheduleAutoSave();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        title: 'À propos',
                        child: TextField(
                          controller: _aboutCtrl,
                          maxLines: 6,
                          maxLength: 600,
                          decoration: const InputDecoration(
                            labelText:
                                'Parlez de votre parcours et motivations',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        title: 'Expériences professionnelles',
                        onAdd: _addExperience,
                        child: Column(
                          children: List.generate(
                            _experiences.length,
                            (i) => _editableCard(
                              title: _experiences[i]['poste']!,
                              subtitle:
                                  '${_experiences[i]['entreprise']} · ${_experiences[i]['ville']} · ${_experiences[i]['periode']}',
                              body: _experiences[i]['mission']!,
                              onDelete: () {
                                setState(() => _experiences.removeAt(i));
                                _scheduleAutoSave();
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        title: 'Formations',
                        onAdd: _addFormation,
                        child: Column(
                          children: List.generate(
                            _formations.length,
                            (i) => _editableCard(
                              title: _formations[i]['diplome']!,
                              subtitle:
                                  '${_formations[i]['ecole']} · ${_formations[i]['ville']} · ${_formations[i]['annee']}',
                              body: '',
                              onDelete: () {
                                setState(() => _formations.removeAt(i));
                                _scheduleAutoSave();
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        title: 'Compétences',
                        onAdd: _addSkill,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _skills
                              .map(
                                (s) => InputChip(
                                  label: Text('${s['name']} · ${s['level']}'),
                                  onDeleted: () {
                                    setState(() => _skills.remove(s));
                                    _scheduleAutoSave();
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        title: 'Langues',
                        onAdd: _addLanguage,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _languages
                              .map(
                                (l) => InputChip(
                                  label: Text('${l['name']} · ${l['level']}'),
                                  onDeleted: () {
                                    setState(() => _languages.remove(l));
                                    _scheduleAutoSave();
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        title: 'Mon CV',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_cvFileName == null)
                              const Text('Aucun CV uploadé pour le moment.')
                            else
                              Text('Fichier actuel: $_cvFileName'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton.icon(
                                  onPressed: _pickCv,
                                  icon: const Icon(Icons.upload_file),
                                  label: Text(
                                    _cvFileName == null
                                        ? 'Uploader CV'
                                        : 'Remplacer CV',
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: !_hasCv || _isAnalysingCv
                                      ? null
                                      : _reanalyserCv,
                                  icon: _isAnalysingCv
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.auto_awesome),
                                  label: Text(
                                    _isAnalysingCv
                                        ? 'Analyse...'
                                        : 'Ré-analyser IA',
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: !_hasCv ? null : () {},
                                  icon: const Icon(Icons.download_outlined),
                                  label: const Text('Télécharger'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: !_hasCv
                                      ? null
                                      : () {
                                          setState(() {
                                            _cvFileName = null;
                                            _hasCv = false;
                                          });
                                          _scheduleAutoSave();
                                        },
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Supprimer'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        title: 'Visibilité du profil',
                        child: Column(
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _profileVisible,
                              onChanged: (v) {
                                setState(() => _profileVisible = v);
                                _scheduleAutoSave();
                              },
                              title: const Text(
                                'Mon profil est visible par les recruteurs',
                              ),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _allowRecruiterContact,
                              onChanged: (v) {
                                setState(() => _allowRecruiterContact = v);
                                _scheduleAutoSave();
                              },
                              title: const Text(
                                'Recevoir des propositions de contact',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (desktop) ...[
                  const SizedBox(width: 14),
                  Expanded(flex: 3, child: _iaPanel(completionPct)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _completionHeader(int completion) {
    final scheme = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ext.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complétion globale du profil',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  _isAutoSaving
                      ? 'Autosave en cours...'
                      : _lastAutoSavedAt == null
                      ? 'Autosave inactif'
                      : 'Sauvegardé à ${_lastAutoSavedAt!.hour.toString().padLeft(2, '0')}:${_lastAutoSavedAt!.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isAutoSaving
                        ? const Color(0xFF1A56DB)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _isSaving ? null : _saveProfile,
            icon: _isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
          ),
          const SizedBox(width: 12),
          Text(
            '$completion%',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: completion / 100,
                minHeight: 8,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  completion < 40
                      ? const Color(0xFFEF4444)
                      : completion < 70
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF10B981),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    VoidCallback? onAdd,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.themeExt.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (onAdd != null)
                IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_circle_outline),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _editableCard({
    required String title,
    required String subtitle,
    required String body,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.themeExt.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (subtitle.isNotEmpty) Text(subtitle),
                if (body.isNotEmpty)
                  Text(body, style: const TextStyle(color: Color(0xFF64748B))),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  Widget _iaPanel(int completion) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF1A56DB)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Analyse IA du profil',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 88,
                    height: 88,
                    child: CircularProgressIndicator(
                      value: completion / 100,
                      strokeWidth: 8,
                      backgroundColor: const Color(0x33FFFFFF),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '$completion',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Très bon profil !',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.themeExt.cardBorder),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pour améliorer votre score',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text('• Ajouter une photo de profil'),
              Text('• Détailler la section À propos'),
              Text('• Ajouter votre profil LinkedIn'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.themeExt.cardBorder),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              Chip(label: Text('Flutter')),
              Chip(label: Text('Dart')),
              Chip(label: Text('Firebase')),
              Chip(label: Text('REST API')),
              Chip(label: Text('Git')),
            ],
          ),
        ),
      ],
    );
  }
}
