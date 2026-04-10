import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../core/theme/theme_extension.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/candidat_provider.dart';
import '../../services/cv_service.dart';
import '../../services/users_service.dart';
import '../../widgets/responsive_container.dart';
import 'pages/createur_cv_page.dart';
import 'widgets/analyse_ia_widget.dart';
import 'widgets/profil_cv_dialogs.dart';
import 'widgets/profil_mon_profil_widgets.dart';

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
  int? _cvTailleFichier;
  String? _cvAnalyseSource;
  bool _profileVisible = true;
  bool _allowRecruiterContact = true;
  bool _isAutoSaving = false;
  bool _isAnalysingCv = false;
  bool _isSaving = false;
  bool _isAmeliorant = false;
  bool _isLoading = true;
  DateTime? _lastAutoSavedAt;
  Timer? _autoSaveTimer;
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
      _titleCtrl.text = (profil['titre_poste'] ?? profil['niveau_etude'] ?? '')
          .toString();
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
      final exps = profil['experiences'];
      if (exps is List) {
        _experiences
          ..clear()
          ..addAll(
            exps.map((e) {
              if (e is Map) {
                return {
                  'poste': (e['titre'] ?? e['poste'] ?? '').toString(),
                  'entreprise': (e['entreprise'] ?? e['company'] ?? '')
                      .toString(),
                  'ville': (e['ville'] ?? '').toString(),
                  'periode': (e['duree'] ?? e['periode'] ?? '').toString(),
                  'mission': (e['description'] ?? e['mission'] ?? '')
                      .toString(),
                };
              }
              return {
                'poste': e.toString(),
                'entreprise': '',
                'ville': '',
                'periode': '',
                'mission': '',
              };
            }),
          );
      }
      final fmts = profil['formations'];
      if (fmts is List) {
        _formations
          ..clear()
          ..addAll(
            fmts.map((e) {
              if (e is Map) {
                return {
                  'diplome': (e['diplome'] ?? e['title'] ?? '').toString(),
                  'ecole': (e['ecole'] ?? e['institute'] ?? '').toString(),
                  'ville': (e['ville'] ?? '').toString(),
                  'annee': (e['annee'] ?? e['end_date'] ?? '').toString(),
                };
              }
              return {
                'diplome': e.toString(),
                'ecole': '',
                'ville': '',
                'annee': '',
              };
            }),
          );
      }
      final langs = profil['langues'];
      if (langs is List) {
        _languages
          ..clear()
          ..addAll(
            langs.map((e) => {'name': e.toString(), 'level': 'Courant'}),
          );
      }
      try {
        final cv = await _cvService.getMonCv();
        _cvFileName = (cv['nom_fichier'] ?? '').toString().isEmpty
            ? null
            : cv['nom_fichier'].toString();
        _hasCv = _cvFileName != null;
        final tf = cv['taille_fichier'];
        _cvTailleFichier = tf is int ? tf : (tf is num ? tf.toInt() : null);
        final ce = cv['competences_extrait'];
        if (ce is Map) {
          _cvAnalyseSource = ce['source']?.toString();
        } else {
          _cvAnalyseSource = null;
        }
      } catch (_) {
        _hasCv = false;
        _cvTailleFichier = null;
        _cvAnalyseSource = null;
      }
    } catch (_) {
      // Keep page usable with local fallback values.
    } finally {
      if (mounted) {
        context.read<CandidatProvider>().recalculerCompletion(
          _buildProfilPayload(),
        );
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
      context.read<CandidatProvider>().recalculerCompletion(
        _buildProfilPayload(),
      );
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
      context.read<CandidatProvider>().recalculerCompletion(
        _buildProfilPayload(),
      );
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
      try {
        final cv = await _cvService.getMonCv();
        final tf = cv['taille_fichier'];
        final ce = cv['competences_extrait'];
        setState(() {
          _cvFileName = file.name;
          _hasCv = true;
          _cvTailleFichier = tf is int
              ? tf
              : (tf is num ? tf.toInt() : file.bytes!.length);
          _cvAnalyseSource = ce is Map ? ce['source']?.toString() : null;
        });
      } catch (_) {
        setState(() {
          _cvFileName = file.name;
          _hasCv = true;
          _cvTailleFichier = file.bytes!.length;
          _cvAnalyseSource = null;
        });
      }
      if (!mounted) return;
      await context.read<CandidatProvider>().loadDashboardMetrics();
      if (!mounted) return;
      context.read<CandidatProvider>().recalculerCompletion(
        _buildProfilPayload(),
      );
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

  Map<String, dynamic> _buildProfilPayload() {
    return {
      'utilisateur': {
        'photo_url': _photoUrl,
        'nom': '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'
            .trim(),
        'telephone': _phoneCtrl.text.trim(),
        'adresse': _cityCtrl.text.trim(),
      },
      'titre_poste': _titleCtrl.text.trim(),
      'about': _aboutCtrl.text.trim(),
      'competences': _skills.map((e) => e['name']).whereType<String>().toList(),
      'disponibilite': _availability,
      'cv': {
        'fichier_url': _hasCv ? '1' : null,
        'analyse': {
          'competences': _skills
              .map((e) => e['name'])
              .whereType<String>()
              .toList(),
        },
      },
    };
  }

  Future<void> _ameliorerAPropos() async {
    if (_aboutCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Écrivez d\'abord quelques mots sur vous'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isAmeliorant = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http
          .post(
            Uri.parse('$apiBaseUrl$apiPrefix/candidat/ameliorer-apropos'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'texte_original': _aboutCtrl.text.trim(),
              'titre_poste': _titleCtrl.text.trim(),
              'competences': _skills
                  .map((e) => e['name'])
                  .whereType<String>()
                  .toList(),
            }),
          )
          .timeout(const Duration(seconds: 30));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 400 || body['success'] != true) {
        throw Exception(body['message']?.toString() ?? 'Erreur IA');
      }
      final texteAmeliore =
          ((body['data'] as Map<String, dynamic>)['texte_ameliore'] ?? '')
              .toString();
      if (!mounted) return;
      _showComparaisonDialog(
        original: _aboutCtrl.text.trim(),
        ameliore: texteAmeliore,
        onAccepter: () {
          setState(() => _aboutCtrl.text = texteAmeliore);
          _scheduleAutoSave();
          Navigator.pop(context);
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur IA: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAmeliorant = false);
    }
  }

  void _showComparaisonDialog({
    required String original,
    required String ameliore,
    required VoidCallback onAccepter,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF7C3AED),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Amélioration IA',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  ameliore,
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Garder l\'original'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onAccepter,
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Utiliser ce texte'),
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

  Future<void> _reanalyserCv() async {
    if (!_hasCv) return;
    setState(() => _isAnalysingCv = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http
          .post(
            Uri.parse('$apiBaseUrl$apiPrefix/cv/analyser'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 45));

      if (!mounted) return;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 400 || body['success'] != true) {
        throw Exception(
          body['message']?.toString() ?? 'Erreur ${res.statusCode}',
        );
      }

      final data = body['data'] as Map<String, dynamic>? ?? {};
      final nbRaw = data['nb_competences'];
      final nbComps = nbRaw is int ? nbRaw : (nbRaw is num ? nbRaw.toInt() : 0);
      final message = (body['message'] as String?)?.trim() ?? '';
      final resumeProfil = data['resume_profil']?.toString().trim();
      if (resumeProfil != null &&
          resumeProfil.isNotEmpty &&
          _aboutCtrl.text.trim().isEmpty) {
        setState(() => _aboutCtrl.text = resumeProfil);
      }

      await context.read<CandidatProvider>().loadDashboardMetrics();
      if (!mounted) return;
      await _loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.isNotEmpty
                  ? message
                  : 'Analyse terminée: $nbComps compétence(s).',
            ),
            backgroundColor: nbComps > 0
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur analyse IA: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAnalysingCv = false);
    }
  }

  List<String> _competencesForApi() {
    return _skills
        .map((e) => e['name']?.toString().trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _experiencesForApi() {
    return _experiences
        .map(
          (e) => <String, dynamic>{
            'poste': e['poste'] ?? '',
            'titre': e['poste'] ?? '',
            'entreprise': e['entreprise'] ?? '',
            'ville': e['ville'] ?? '',
            'periode': e['periode'] ?? '',
            'duree': e['periode'] ?? '',
            'mission': e['mission'] ?? '',
            'description': e['mission'] ?? '',
          },
        )
        .toList();
  }

  List<Map<String, dynamic>> _formationsForApi() {
    return _formations
        .map(
          (f) => <String, dynamic>{
            'diplome': f['diplome'] ?? '',
            'titre': f['diplome'] ?? '',
            'ecole': f['ecole'] ?? '',
            'ville': f['ville'] ?? '',
            'annee': f['annee'] ?? '',
            'end_date': f['annee'] ?? '',
          },
        )
        .toList();
  }

  List<String> _languesForApi() {
    return _languages
        .map((l) => l['name']?.toString().trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> _profilListsPatchBody() {
    return {
      'competences': _competencesForApi(),
      'experiences': _experiencesForApi(),
      'formations': _formationsForApi(),
      'langues': _languesForApi(),
    };
  }

  Future<void> _persistProfilListsToBackend() async {
    try {
      await _usersService.updateMe(_profilListsPatchBody());
      if (!mounted) return;
      context.read<CandidatProvider>().recalculerCompletion(
        _buildProfilPayload(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enregistrement des listes impossible: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final fullName =
          '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim();
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
        ..._profilListsPatchBody(),
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

  Future<void> _addExperience() async {
    final m = await showProfilExperienceDialog(context);
    if (m != null && mounted) {
      setState(() => _experiences.add(m));
      await _persistProfilListsToBackend();
      _scheduleAutoSave();
    }
  }

  Future<void> _removeExperienceAt(int index) async {
    if (index < 0 || index >= _experiences.length) return;
    setState(() => _experiences.removeAt(index));
    await _persistProfilListsToBackend();
    _scheduleAutoSave();
  }

  Future<void> _addFormation() async {
    final m = await showProfilFormationDialog(context);
    if (m != null && mounted) {
      setState(() => _formations.add(m));
      await _persistProfilListsToBackend();
      _scheduleAutoSave();
    }
  }

  Future<void> _removeFormationAt(int index) async {
    if (index < 0 || index >= _formations.length) return;
    setState(() => _formations.removeAt(index));
    await _persistProfilListsToBackend();
    _scheduleAutoSave();
  }

  Future<void> _modifierExperienceAt(int index) async {
    if (index < 0 || index >= _experiences.length) return;
    final existing = _experiences[index];
    final m = await showProfilExperienceDialog(context, existing: existing);
    if (m != null && mounted) {
      setState(() => _experiences[index] = m);
      await _persistProfilListsToBackend();
      _scheduleAutoSave();
    }
  }

  Future<void> _modifierFormationAt(int index) async {
    if (index < 0 || index >= _formations.length) return;
    final existing = _formations[index];
    final m = await showProfilFormationDialog(context, existing: existing);
    if (m != null && mounted) {
      setState(() => _formations[index] = m);
      await _persistProfilListsToBackend();
      _scheduleAutoSave();
    }
  }

  Future<void> _addSkill() async {
    final m = await showProfilCompetenceDialog(context);
    if (m != null && mounted) {
      setState(() => _skills.add({'name': m['name']!, 'level': m['level']!}));
      await _persistProfilListsToBackend();
      _scheduleAutoSave();
    }
  }

  Future<void> _modifierSkillAt(int index) async {
    if (index < 0 || index >= _skills.length) return;
    final existing = _skills[index];
    final m = await showProfilCompetenceDialog(context, existing: existing);
    if (m != null && mounted) {
      setState(
        () => _skills[index] = {'name': m['name']!, 'level': m['level']!},
      );
      await _persistProfilListsToBackend();
      _scheduleAutoSave();
    }
  }

  Future<void> _removeSkillAt(int index) async {
    if (index < 0 || index >= _skills.length) return;
    setState(() => _skills.removeAt(index));
    await _persistProfilListsToBackend();
    _scheduleAutoSave();
  }

  Future<void> _addLanguage() async {
    final m = await showProfilLangueDialog(context);
    if (m != null && mounted) {
      setState(
        () => _languages.add({'name': m['name']!, 'level': m['level']!}),
      );
      await _persistProfilListsToBackend();
      _scheduleAutoSave();
    }
  }

  Future<void> _modifierLanguageAt(int index) async {
    if (index < 0 || index >= _languages.length) return;
    final existing = _languages[index];
    final m = await showProfilLangueDialog(context, existing: existing);
    if (m != null && mounted) {
      setState(
        () => _languages[index] = {'name': m['name']!, 'level': m['level']!},
      );
      await _persistProfilListsToBackend();
      _scheduleAutoSave();
    }
  }

  Future<void> _removeLanguageAt(int index) async {
    if (index < 0 || index >= _languages.length) return;
    setState(() => _languages.removeAt(index));
    await _persistProfilListsToBackend();
    _scheduleAutoSave();
  }

  void _openCreateurCv() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => CreateurCvPage(
          onDone: () {
            Navigator.of(ctx).pop();
            if (mounted) {
              unawaited(_loadProfile());
              unawaited(
                context.read<CandidatProvider>().loadDashboardMetrics(),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final completionPct = context
        .watch<CandidatProvider>()
        .profileCompletionPercent;
    final bottomInset = MediaQuery.of(context).size.width <= 900 ? 80.0 : 24.0;
    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: ResponsiveContainer(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: LayoutBuilder(
          builder: (context, c) {
            final desktop = c.maxWidth >= 1100;
            return RefreshIndicator(
              color: const Color(0xFF1A56DB),
              onRefresh: () async {
                await _loadProfile();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: desktop ? 7 : 1,
                      child: Column(
                        children: [
                          _buildCompletionCard(completionPct),
                          _buildPhotoIdentiteCard(),
                          _buildAProposCard(),
                          _buildCompetencesCard(),
                          _buildExperiencesCard(),
                          _buildFormationsCard(),
                          _buildLanguesCard(),
                          _buildVisibiliteCard(),
                          _buildCVCard(),
                          _buildBoutonSauvegarder(),
                        ],
                      ),
                    ),
                    if (desktop) ...[
                      const SizedBox(width: 14),
                      Expanded(flex: 3, child: _iaPanel(completionPct)),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompletionCard(int completionPct) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfilCompletionCard(
          completion: completionPct,
          isAutoSaving: _isAutoSaving,
          lastAutoSavedAt: _lastAutoSavedAt,
          isSaving: _isSaving,
          onSave: _saveProfile,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPhotoIdentiteCard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfilSectionCard(
          title: 'Photo & Identité',
          icon: Icons.person_outline_rounded,
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
                    child: _photoBytes == null && (_photoUrl ?? '').isEmpty
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
                      decoration: const InputDecoration(labelText: 'Prénom'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _lastNameCtrl,
                      decoration: const InputDecoration(labelText: 'Nom'),
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
                      decoration: const InputDecoration(labelText: 'Ville'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Téléphone'),
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
                  ButtonSegment(value: '1 mois', label: Text('Dans 1 mois')),
                  ButtonSegment(value: '3 mois', label: Text('Dans 3 mois')),
                  ButtonSegment(value: 'En poste', label: Text('En poste')),
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
      ],
    );
  }

  Widget _buildAProposCard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfilSectionCard(
          title: 'À propos',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Spacer(),
                  GestureDetector(
                    onTap: _isAmeliorant ? null : _ameliorerAPropos,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A56DB), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _isAmeliorant
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
                            _isAmeliorant
                                ? 'IA en cours...'
                                : '✨ Améliorer avec l\'IA',
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
              TextField(
                controller: _aboutCtrl,
                maxLines: 8,
                maxLength: 800,
                decoration: const InputDecoration(
                  labelText: 'Parlez de votre parcours et motivations',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildCVCard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfilSectionCard(
          title: 'Mon CV',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openCreateurCv,
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A56DB), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x301A56DB),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Créer mon CV avec l'assistant",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Renseignez vos infos puis téléchargez un PDF pro.',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'Créer',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A56DB),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_cvTailleFichier != null &&
                  _cvTailleFichier! < 5000 &&
                  _cvAnalyseSource != 'plateforme_cv_builder' &&
                  _cvAnalyseSource != 'plateforme')
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFFF59E0B),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Pour que l'IA analyse correctement : uploadez un vrai CV Word (.docx) ou un PDF avec du texte.",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF92400E),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Color(0xFFF59E0B),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pour une meilleure analyse IA : créez le CV depuis la plateforme ou utilisez un PDF texte clair (évitez les scans illisibles).',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF92400E),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasCv) ...[
                const SizedBox(height: 12),
                AnalyseIAWidget(onAnalysed: () => unawaited(_loadProfile())),
              ],
              const SizedBox(height: 14),
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
                      _cvFileName == null ? 'Uploader CV' : 'Remplacer CV',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: !_hasCv || _isAnalysingCv ? null : _reanalyserCv,
                    icon: _isAnalysingCv
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      _isAnalysingCv ? 'Analyse...' : 'Ré-analyser IA',
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
                              _cvTailleFichier = null;
                              _cvAnalyseSource = null;
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
      ],
    );
  }

  Widget _buildExperiencesCard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfilSectionCard(
          title: 'Expériences professionnelles',
          icon: Icons.work_outline_rounded,
          accent: const Color(0xFF1A56DB),
          onAdd: () => unawaited(_addExperience()),
          child: Column(
            children: List.generate(
              _experiences.length,
              (i) => ProfilEditableRow(
                title: _experiences[i]['poste']!,
                subtitle:
                    '${_experiences[i]['entreprise']} · ${_experiences[i]['ville']} · ${_experiences[i]['periode']}',
                body: _experiences[i]['mission']!,
                onEdit: () => unawaited(_modifierExperienceAt(i)),
                onDelete: () => unawaited(_removeExperienceAt(i)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildFormationsCard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfilSectionCard(
          title: 'Formations',
          icon: Icons.school_outlined,
          accent: const Color(0xFFF59E0B),
          onAdd: () => unawaited(_addFormation()),
          child: Column(
            children: List.generate(
              _formations.length,
              (i) => ProfilEditableRow(
                title: _formations[i]['diplome']!,
                subtitle:
                    '${_formations[i]['ecole']} · ${_formations[i]['ville']} · ${_formations[i]['annee']}',
                body: '',
                onEdit: () => unawaited(_modifierFormationAt(i)),
                onDelete: () => unawaited(_removeFormationAt(i)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildCompetencesCard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfilSectionCard(
          title: 'Compétences',
          icon: Icons.construction_outlined,
          accent: const Color(0xFF6366F1),
          onAdd: () => unawaited(_addSkill()),
          child: Column(
            children: List.generate(
              _skills.length,
              (i) => ProfilEditableRow(
                title: _skills[i]['name']!,
                subtitle: _skills[i]['level']!,
                body: '',
                onEdit: () => unawaited(_modifierSkillAt(i)),
                onDelete: () => unawaited(_removeSkillAt(i)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildLanguesCard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfilSectionCard(
          title: 'Langues',
          icon: Icons.translate_rounded,
          accent: const Color(0xFF0EA5E9),
          onAdd: () => unawaited(_addLanguage()),
          child: Column(
            children: List.generate(
              _languages.length,
              (i) => ProfilEditableRow(
                title: _languages[i]['name']!,
                subtitle: _languages[i]['level']!,
                body: '',
                onEdit: () => unawaited(_modifierLanguageAt(i)),
                onDelete: () => unawaited(_removeLanguageAt(i)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildVisibiliteCard() {
    return ProfilSectionCard(
      title: 'Visibilité du profil',
      child: Column(
        children: [
          _buildVisibilityToggle(
            icon: Icons.person_outline_rounded,
            title: 'Profil visible par les recruteurs',
            subtitle: 'Les recruteurs peuvent voir votre profil',
            value: _profileVisible,
            color: const Color(0xFF10B981),
            onChanged: (v) async {
              final prev = _profileVisible;
              setState(() => _profileVisible = v);
              try {
                await _usersService.updateMe({
                  'privacy_profile_visible': v,
                });
                if (!mounted) return;
                _scheduleAutoSave();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      v
                          ? '✅ Profil maintenant visible'
                          : '🔒 Profil masqué aux recruteurs',
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    backgroundColor: v
                        ? const Color(0xFF10B981)
                        : const Color(0xFF64748B),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                setState(() => _profileVisible = prev);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          _buildVisibilityToggle(
            icon: Icons.email_outlined,
            title: 'Recevoir des propositions',
            subtitle: 'Les recruteurs peuvent vous contacter',
            value: _allowRecruiterContact,
            color: const Color(0xFF1A56DB),
            onChanged: (v) async {
              final prev = _allowRecruiterContact;
              setState(() => _allowRecruiterContact = v);
              try {
                await _usersService.updateMe({
                  'privacy_allow_direct_contact': v,
                });
                if (!mounted) return;
                _scheduleAutoSave();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      v
                          ? '✅ Propositions activées'
                          : '🔕 Propositions désactivées',
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    backgroundColor: v
                        ? const Color(0xFF1A56DB)
                        : const Color(0xFF64748B),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                setState(() => _allowRecruiterContact = prev);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: color,
        ),
      ],
    );
  }

  Widget _buildBoutonSauvegarder() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1A56DB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _isSaving ? null : _saveProfile,
            icon: _isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 16),
            label: Text(
              _isSaving ? 'Enregistrement...' : 'Enregistrer le profil',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
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
