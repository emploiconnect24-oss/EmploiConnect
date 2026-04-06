import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../services/recruteur_service.dart';

/// PRD §5–6 — Dialog modification d’offre (champs alignés backend whitelist).
class ModifierOffreDialog extends StatefulWidget {
  const ModifierOffreDialog({
    super.key,
    required this.offre,
    required this.onSaved,
  });

  final Map<String, dynamic> offre;
  final VoidCallback onSaved;

  @override
  State<ModifierOffreDialog> createState() => _ModifierOffreDialogState();
}

class _ModifierOffreDialogState extends State<ModifierOffreDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late TextEditingController _titreCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _exigCtrl;
  late TextEditingController _locaCtrl;
  late TextEditingController _salaireMinCtrl;
  late TextEditingController _salaireMaxCtrl;
  String? _typeContrat;
  String? _niveauExp;
  int _nbPostes = 1;

  static const _contrats = ['cdi', 'cdd', 'stage', 'freelance', 'temps_partiel'];
  static const _niveaux = [
    'sans_experience',
    '1_2_ans',
    '3_5_ans',
    '5_10_ans',
    '10_ans_plus',
  ];
  static const _niveauxLabels = {
    'sans_experience': 'Sans expérience',
    '1_2_ans': '1 à 2 ans',
    '3_5_ans': '3 à 5 ans',
    '5_10_ans': '5 à 10 ans',
    '10_ans_plus': '10 ans et plus',
  };

  @override
  void initState() {
    super.initState();
    final o = widget.offre;
    _titreCtrl = TextEditingController(text: o['titre']?.toString() ?? '');
    _descCtrl = TextEditingController(text: o['description']?.toString() ?? '');
    _exigCtrl = TextEditingController(text: o['exigences']?.toString() ?? '');
    _locaCtrl = TextEditingController(text: o['localisation']?.toString() ?? '');
    _salaireMinCtrl = TextEditingController(text: o['salaire_min']?.toString() ?? '');
    _salaireMaxCtrl = TextEditingController(text: o['salaire_max']?.toString() ?? '');
    final tc = o['type_contrat']?.toString().toLowerCase();
    _typeContrat = _contrats.contains(tc) ? tc : (tc != null && tc.isNotEmpty ? tc : null);
    final ne = o['niveau_experience_requis']?.toString();
    _niveauExp = _niveaux.contains(ne) ? ne : null;
    _nbPostes = (o['nombre_postes'] is int)
        ? o['nombre_postes'] as int
        : int.tryParse(o['nombre_postes']?.toString() ?? '') ?? 1;
    if (_nbPostes < 1) _nbPostes = 1;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 680,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_outlined, color: Color(0xFF1A56DB), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modifier l\'offre',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          widget.offre['titre']?.toString() ?? '',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Titre du poste *'),
                      const SizedBox(height: 6),
                      _field(
                        _titreCtrl,
                        'Ex: Développeur Flutter Senior',
                        validator: (v) => v == null || v.isEmpty ? 'Titre requis' : null,
                      ),
                      const SizedBox(height: 16),
                      _label('Description du poste *'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 5,
                        validator: (v) => v == null || v.isEmpty ? 'Description requise' : null,
                        decoration: _deco('Responsabilités, environnement...'),
                      ),
                      const SizedBox(height: 16),
                      _label('Prérequis et compétences'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _exigCtrl,
                        maxLines: 3,
                        decoration: _deco('Ex: expérience, stack...'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Localisation *'),
                                const SizedBox(height: 6),
                                _field(
                                  _locaCtrl,
                                  'Ex: Conakry',
                                  validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Type de contrat *'),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _typeContrat,
                                  decoration: _deco('Choisir...'),
                                  borderRadius: BorderRadius.circular(10),
                                  items: _contrats
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(
                                            c.replaceAll('_', ' ').toUpperCase(),
                                            style: GoogleFonts.inter(fontSize: 13),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(() => _typeContrat = v),
                                  validator: (v) => v == null ? 'Requis' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Expérience requise'),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _niveauExp,
                                  decoration: _deco('Sélectionner...'),
                                  borderRadius: BorderRadius.circular(10),
                                  items: _niveaux
                                      .map(
                                        (n) => DropdownMenuItem(
                                          value: n,
                                          child: Text(
                                            _niveauxLabels[n] ?? n,
                                            style: GoogleFonts.inter(fontSize: 13),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(() => _niveauExp = v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Nombre de postes'),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      color: const Color(0xFF64748B),
                                      onPressed: _nbPostes > 1 ? () => setState(() => _nbPostes--) : null,
                                    ),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: Text(
                                          '$_nbPostes',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      color: const Color(0xFF1A56DB),
                                      onPressed: () => setState(() => _nbPostes++),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _label('Fourchette salariale (optionnel)'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              _salaireMinCtrl,
                              'Min',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('—', style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF94A3B8))),
                          ),
                          Expanded(
                            child: _field(
                              _salaireMaxCtrl,
                              'Max',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text('Annuler', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(
                        _isSaving ? 'Sauvegarde...' : 'Enregistrer les modifications',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A56DB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isSaving ? null : _save,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final id = widget.offre['id']?.toString() ?? '';
      if (id.isEmpty) throw Exception('ID offre manquant');

      final body = <String, dynamic>{
        'titre': _titreCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'exigences': _exigCtrl.text.trim(),
        'localisation': _locaCtrl.text.trim(),
        'type_contrat': _typeContrat,
        'niveau_experience_requis': _niveauExp,
        'nombre_postes': _nbPostes,
        if (_salaireMinCtrl.text.trim().isNotEmpty)
          'salaire_min': int.tryParse(_salaireMinCtrl.text.replaceAll(' ', '')),
        if (_salaireMaxCtrl.text.trim().isNotEmpty)
          'salaire_max': int.tryParse(_salaireMaxCtrl.text.replaceAll(' ', '')),
      };

      await RecruteurService().updateOffre(token, id, body);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Offre mise à jour', style: GoogleFonts.inter(color: Colors.white)),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _label(String t) => Text(
        t,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF374151),
        ),
      );

  Widget _field(
    TextEditingController c,
    String hint, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) =>
      TextFormField(
        controller: c,
        validator: validator,
        keyboardType: keyboardType,
        decoration: _deco(hint),
      );

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
      );

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descCtrl.dispose();
    _exigCtrl.dispose();
    _locaCtrl.dispose();
    _salaireMinCtrl.dispose();
    _salaireMaxCtrl.dispose();
    super.dispose();
  }
}
