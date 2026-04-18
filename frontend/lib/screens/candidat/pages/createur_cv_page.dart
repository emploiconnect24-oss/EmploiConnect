import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../providers/auth_provider.dart';
import '../../../services/api_service.dart';
import '../../../services/users_service.dart';
import '../widgets/profil_cv_dialogs.dart';

/// Wizard créateur CV + PDF (PRD §6).
class CreateurCvPage extends StatefulWidget {
  const CreateurCvPage({super.key, this.onDone, this.onClose});

  /// Retour shell après succès (ex. recharger profil).
  final VoidCallback? onDone;

  /// Fermer depuis le shell (pas de pile Navigator).
  final VoidCallback? onClose;

  @override
  State<CreateurCvPage> createState() => _CreateurCvPageState();
}

class _CreateurCvPageState extends State<CreateurCvPage> {
  int _etape = 0;
  final _nomCtrl = TextEditingController();
  final _titreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _resumeCtrl = TextEditingController();
  String? _photoUrl;
  Uint8List? _photoBytes;
  String? _photoFileName;
  String _modeleCv = 'moderne';

  final List<Map<String, dynamic>> _experiences = [];
  final List<Map<String, dynamic>> _formations = [];
  final List<Map<String, dynamic>> _competences = [];
  final List<Map<String, dynamic>> _langues = [];

  bool _isDownloading = false;
  bool _isUploadingPhoto = false;
  bool _isResumantIA = false;

  static const _etapes = [
    _WizardEtape('Infos perso', Icons.person_outline_rounded, Color(0xFF1A56DB)),
    _WizardEtape('Résumé', Icons.description_outlined, Color(0xFF8B5CF6)),
    _WizardEtape('Expériences', Icons.work_outline_rounded, Color(0xFF10B981)),
    _WizardEtape('Formations', Icons.school_outlined, Color(0xFFF59E0B)),
    _WizardEtape('Comp. & langues', Icons.psychology_rounded, Color(0xFFEF4444)),
  ];

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user;
    if (u != null) {
      _nomCtrl.text = (u['nom'] ?? '').toString();
      _emailCtrl.text = (u['email'] ?? '').toString();
      _telCtrl.text = (u['telephone'] ?? '').toString();
      _villeCtrl.text = (u['adresse'] ?? '').toString();
      final p = (u['photo_url'] ?? '').toString();
      if (p.isNotEmpty) _photoUrl = p;
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _titreCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _villeCtrl.dispose();
    _linkedinCtrl.dispose();
    _resumeCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _experiencesForApi() {
    return _experiences.map((e) {
      return {
        'titre': e['poste'] ?? e['titre'] ?? '',
        'entreprise': e['entreprise'] ?? '',
        'description': e['mission'] ?? e['description'] ?? '',
        'date_debut': '${DateTime.now().year}-01-01',
        'date_fin': null,
        'en_poste': (e['periode']?.toString().contains('...') ?? false) ||
            (e['periode']?.toString().toLowerCase().contains('actuel') ?? false),
      };
    }).toList();
  }

  List<Map<String, dynamic>> _formationsForApi() {
    return _formations
        .map(
          (f) => {
            'diplome': f['diplome'] ?? '',
            'ecole': f['ecole'] ?? '',
            'annee': f['annee'] ?? '',
          },
        )
        .toList();
  }

  Future<void> _genererPdf() async {
    if (_nomCtrl.text.trim().isEmpty || _titreCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom et titre professionnels requis.')),
      );
      return;
    }
    setState(() => _isDownloading = true);
    try {
      final api = ApiService();
      final body = {
        'nom': _nomCtrl.text.trim(),
        'titre': _titreCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'telephone': _telCtrl.text.trim(),
        'ville': _villeCtrl.text.trim(),
        'linkedin': _linkedinCtrl.text.trim(),
        'resume': _resumeCtrl.text.trim(),
        'photo_url': (_photoUrl != null && _photoUrl!.startsWith('http')) ? _photoUrl : null,
        'modele_cv': _modeleCv,
        'experiences': _experiencesForApi(),
        'formations': _formationsForApi(),
        'competences': _competences.map((c) => {'nom': c['name'], 'niveau': c['level']}).toList(),
        'langues': _langues.map((l) => {'name': l['name'], 'niveau': l['level']}).toList(),
      };
      final res = await api.post('/candidat/cv/generer-pdf', body: body, useAuth: true);
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && map['success'] == true) {
        final data = map['data'] as Map?;
        final profilMaj = data?['profil_mis_a_jour'] == true;
        final url = data?['pdf_url']?.toString();
        if (url != null && url.isNotEmpty) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    profilMaj ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      profilMaj
                          ? 'CV téléchargé ! Votre profil a été mis à jour automatiquement.'
                          : 'CV généré. Vous pouvez l’enregistrer depuis Mon profil.',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: profilMaj ? const Color(0xFF10B981) : null,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
              action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
            ),
          );
          widget.onDone?.call();
        }
      } else {
        throw Exception(map['message']?.toString() ?? 'Erreur API');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _pickPhotoCv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;
    if (file.size > 3 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo trop lourde (max 3MB).')),
      );
      return;
    }
    setState(() => _isUploadingPhoto = true);
    try {
      final usersService = UsersService();
      final url = await usersService.uploadMyPhoto(
        bytes: bytes,
        filename: file.name,
      );
      if (!mounted) return;
      setState(() {
        _photoUrl = url;
        _photoBytes = bytes;
        _photoFileName = file.name;
      });
      await context.read<AuthProvider>().loadSession();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo ajoutée au CV avec succès.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur upload photo: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _resumerAvecIA() async {
    final texte = _resumeCtrl.text.trim();
    if (texte.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez d’abord un résumé à condenser.')),
      );
      return;
    }
    setState(() => _isResumantIA = true);
    try {
      final api = ApiService();
      final res = await api.post(
        '/candidat/ameliorer-apropos',
        body: {
          'texte_original': texte,
          'titre_poste': _titreCtrl.text.trim(),
          'style': 'professionnel, concis, orienté impact',
          'objectif': 'Résumer en 5 à 8 phrases max, 900 caractères maximum.',
        },
        useAuth: true,
      );
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200 || map['success'] != true) {
        throw Exception(map['message']?.toString() ?? 'Impossible de résumer');
      }
      final data = Map<String, dynamic>.from(map['data'] as Map? ?? {});
      final resume = (data['texte_ameliore'] ?? data['texte'] ?? '').toString().trim();
      if (resume.isEmpty) throw Exception('Réponse IA vide');
      setState(() {
        _resumeCtrl.text = resume.length > 1000 ? resume.substring(0, 1000) : resume;
        _resumeCtrl.selection = TextSelection.collapsed(offset: _resumeCtrl.text.length);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Résumé optimisé avec l’IA.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur IA: $e')),
      );
    } finally {
      if (mounted) setState(() => _isResumantIA = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (widget.onClose != null) {
              widget.onClose!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: Text(
          'Créer mon CV',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_etape == 4)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                onPressed: _isDownloading ? null : _genererPdf,
                icon: _isDownloading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.download_rounded, size: 16),
                label: Text(_isDownloading ? '…' : 'PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: List.generate(_etapes.length, (i) {
                final done = i < _etape;
                final cur = i == _etape;
                final col = _etapes[i].color;
                return Expanded(
                  child: Row(
                    children: [
                      Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: done || cur ? col : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              done ? Icons.check_rounded : _etapes[i].icon,
                              size: 14,
                              color: done || cur ? Colors.white : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _etapes[i].label,
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: cur ? FontWeight.w700 : FontWeight.w400,
                              color: cur ? col : const Color(0xFF94A3B8),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                        ],
                      ),
                      if (i < _etapes.length - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.only(bottom: 18),
                            color: i < _etape ? col : const Color(0xFFE2E8F0),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildEtape(),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            color: Colors.white,
            child: Row(
              children: [
                if (_etape > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _etape--),
                      child: const Text('Précédent'),
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _etapes[_etape].color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      if (_etape < 4) {
                        setState(() => _etape++);
                      } else {
                        _genererPdf();
                      }
                    },
                    child: Text(_etape < 4 ? 'Suivant' : 'Générer le PDF'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtape() {
    switch (_etape) {
      case 0:
        return Column(
          children: [
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFFEFF6FF),
                backgroundImage: _photoBytes != null
                    ? MemoryImage(_photoBytes!)
                    : ((_photoUrl != null && _photoUrl!.startsWith('http'))
                    ? NetworkImage(_photoUrl!)
                    : null),
                child: (_photoBytes == null && (_photoUrl == null || !_photoUrl!.startsWith('http')))
                    ? const Icon(Icons.person_outline_rounded, color: Color(0xFF1A56DB), size: 32)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isUploadingPhoto ? null : _pickPhotoCv,
              icon: _isUploadingPhoto
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_camera_outlined),
              label: Text(
                _photoFileName == null ? 'Uploader une photo' : 'Photo: ${_photoFileName!}',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nomCtrl,
              decoration: const InputDecoration(labelText: 'Nom complet *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titreCtrl,
              decoration: const InputDecoration(
                labelText: 'Titre professionnel *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _telCtrl,
              decoration: const InputDecoration(labelText: 'Téléphone', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _villeCtrl,
              decoration: const InputDecoration(labelText: 'Ville', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _linkedinCtrl,
              decoration: const InputDecoration(labelText: 'LinkedIn', border: OutlineInputBorder()),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                'Ajoutez un résumé professionnel convaincant. S’il est trop long, utilisez “Résumer avec l’IA”.',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1E3A8A), height: 1.35),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _isResumantIA ? null : _resumerAvecIA,
                icon: _isResumantIA
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(_isResumantIA ? 'Résumé en cours...' : 'Résumer avec l’IA'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _resumeCtrl,
              maxLines: 12,
              minLines: 8,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Résumé professionnel',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._experiences.map(
              (e) => ListTile(
                title: Text(e['poste']?.toString() ?? ''),
                subtitle: Text('${e['entreprise']} · ${e['periode']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _experiences.remove(e)),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final m = await showProfilExperienceDialog(context);
                if (m != null) setState(() => _experiences.add(m));
              },
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une expérience'),
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._formations.map(
              (f) => ListTile(
                title: Text(f['diplome']?.toString() ?? ''),
                subtitle: Text('${f['ecole']} · ${f['annee']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _formations.remove(f)),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final m = await showProfilFormationDialog(context);
                if (m != null) setState(() => _formations.add(m));
              },
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une formation'),
            ),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Compétences', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            ..._competences.map(
              (c) => ListTile(
                title: Text(c['name']?.toString() ?? ''),
                subtitle: Text(c['level']?.toString() ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _competences.remove(c)),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final m = await showProfilCompetenceDialog(context);
                if (m != null) {
                  setState(() => _competences.add({'name': m['name'], 'level': m['level']}));
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Compétence'),
            ),
            const SizedBox(height: 20),
            Text('Langues', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            ..._langues.map(
              (l) => ListTile(
                title: Text(l['name']?.toString() ?? ''),
                subtitle: Text(l['level']?.toString() ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _langues.remove(l)),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final m = await showProfilLangueDialog(context);
                if (m != null) {
                  setState(() => _langues.add({'name': m['name'], 'level': m['level']}));
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Langue'),
            ),
            const SizedBox(height: 24),
            Text('Modèle de CV', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Aperçu du rendu PDF — touchez un modèle pour le sélectionner.',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = const [
                  ('moderne', 'Moderne', 'Avec photo, clair et structuré'),
                  ('classique', 'Classique', 'Sans photo, style professionnel'),
                  ('elegant', 'Élégant', 'Mise en page premium avec photo'),
                  ('compact', 'Compact', 'Dense et efficace sans photo'),
                ];
                final isMobile = constraints.maxWidth < 700;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: cards.map((c) {
                    final selected = _modeleCv == c.$1;
                    return SizedBox(
                      width: isMobile ? constraints.maxWidth : (constraints.maxWidth - 10) / 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _modeleCv = c.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFFEFF6FF) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? const Color(0xFF1A56DB) : const Color(0xFFE2E8F0),
                              width: selected ? 1.8 : 1,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF1A56DB).withValues(alpha: 0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _CvModeleThumbnail(modele: c.$1, selected: selected),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          selected ? Icons.radio_button_checked : Icons.radio_button_off,
                                          color: selected ? const Color(0xFF1A56DB) : const Color(0xFF94A3B8),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            c.$2,
                                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      c.$3,
                                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B), height: 1.35),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Miniature stylisée du rendu PDF (aperçu non contractuel mais représentatif).
class _CvModeleThumbnail extends StatelessWidget {
  const _CvModeleThumbnail({required this.modele, required this.selected});

  final String modele;
  final bool selected;

  static const _w = 76.0;
  static const _h = 100.0;

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: selected ? const Color(0xFF1A56DB) : const Color(0xFFCBD5E1),
      width: selected ? 1.5 : 1,
    );
    return Semantics(
      label: 'Aperçu modèle $modele',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: _w,
          height: _h,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
            border: border,
          ),
          child: switch (modele) {
            'classique' => _buildClassique(),
            'elegant' => _buildElegant(),
            'compact' => _buildCompact(),
            _ => _buildModerne(),
          },
        ),
      ),
    );
  }

  Widget _bar(double w, double h, Color c) => Container(width: w, height: h, color: c);

  Widget _buildModerne() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 26,
          color: const Color(0xFF1A56DB),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar(40, 4, Colors.white70),
                    const SizedBox(height: 3),
                    _bar(28, 3, Colors.white54),
                  ],
                ),
              ),
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFBFDBFE),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(52, 3, const Color(0xFFCBD5E1)),
                const SizedBox(height: 4),
                _bar(60, 2, const Color(0xFFE2E8F0)),
                const SizedBox(height: 4),
                _bar(48, 2, const Color(0xFFE2E8F0)),
                const Spacer(),
                _bar(40, 3, const Color(0xFF1A56DB)),
                const SizedBox(height: 4),
                _bar(56, 2, const Color(0xFFCBD5E1)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassique() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 30,
          color: const Color(0xFF0F172A),
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _bar(44, 4, Colors.white70),
              const SizedBox(height: 4),
              _bar(32, 3, Colors.white38),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(50, 3, const Color(0xFF94A3B8)),
                const SizedBox(height: 5),
                _bar(58, 2, const Color(0xFFE2E8F0)),
                const SizedBox(height: 3),
                _bar(52, 2, const Color(0xFFE2E8F0)),
                const Spacer(),
                _bar(36, 3, const Color(0xFF334155)),
                const SizedBox(height: 4),
                _bar(50, 2, const Color(0xFFE2E8F0)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildElegant() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 22,
          color: const Color(0xFF111827),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
          child: Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Color(0xFF4C1D95),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 6),
              _bar(14, 2, const Color(0xFF9CA3AF)),
              const SizedBox(height: 3),
              _bar(14, 2, const Color(0xFF6B7280)),
              const Spacer(),
              _bar(14, 2, const Color(0xFF9CA3AF)),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(40, 3, const Color(0xFF6D28D9)),
                const SizedBox(height: 4),
                _bar(48, 2, const Color(0xFFCBD5E1)),
                const SizedBox(height: 3),
                _bar(44, 2, const Color(0xFFE2E8F0)),
                const Spacer(),
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6D28D9).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 2),
                _bar(36, 2, const Color(0xFFCBD5E1)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompact() {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFF1A56DB),
              borderRadius: BorderRadius.circular(2),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                Expanded(child: _bar(32, 3, Colors.white70)),
                _bar(10, 3, Colors.white54),
              ],
            ),
          ),
          const SizedBox(height: 4),
          _bar(58, 2, const Color(0xFFCBD5E1)),
          const SizedBox(height: 2),
          _bar(54, 2, const Color(0xFFE2E8F0)),
          const SizedBox(height: 2),
          _bar(56, 2, const Color(0xFFE2E8F0)),
          const SizedBox(height: 3),
          _bar(50, 2, const Color(0xFFE2E8F0)),
          const SizedBox(height: 2),
          _bar(52, 2, const Color(0xFFE2E8F0)),
          const SizedBox(height: 2),
          _bar(48, 2, const Color(0xFFE2E8F0)),
          const Spacer(),
          Wrap(
            spacing: 2,
            runSpacing: 2,
            children: List.generate(
              4,
              (i) => Container(
                width: 14,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WizardEtape {
  const _WizardEtape(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}
