import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../providers/auth_provider.dart';
import '../../../services/api_service.dart';
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

  final List<Map<String, dynamic>> _experiences = [];
  final List<Map<String, dynamic>> _formations = [];
  final List<Map<String, dynamic>> _competences = [];
  final List<Map<String, dynamic>> _langues = [];

  bool _isDownloading = false;

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
                backgroundImage: (_photoUrl != null && _photoUrl!.startsWith('http'))
                    ? NetworkImage(_photoUrl!)
                    : null,
                child: (_photoUrl == null || !_photoUrl!.startsWith('http'))
                    ? const Icon(Icons.person_outline_rounded, color: Color(0xFF1A56DB), size: 32)
                    : null,
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
        return TextField(
          controller: _resumeCtrl,
          maxLines: 8,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Résumé professionnel',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
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
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _WizardEtape {
  const _WizardEtape(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}
