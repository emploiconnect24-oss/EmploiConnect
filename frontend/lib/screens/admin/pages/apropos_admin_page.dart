import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/admin_service.dart';

/// Édition des sections de la page « À propos ».
class AproposAdminPage extends StatefulWidget {
  const AproposAdminPage({super.key});

  @override
  State<AproposAdminPage> createState() => _AproposAdminPageState();
}

class _AproposAdminPageState extends State<AproposAdminPage> {
  final _admin = AdminService();
  List<Map<String, dynamic>> _sections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final rows = await _admin.getAproposSectionsAdmin();
      if (!mounted) return;
      setState(() {
        _sections = rows;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Page « À propos »',
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Personnalisez les sections affichées sur le site public.',
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('Voir la page'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1A56DB)),
                    foregroundColor: const Color(0xFF1A56DB),
                  ),
                  onPressed: () => Navigator.of(context).pushNamed('/a-propos'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: _sections.length,
                    itemBuilder: (ctx, i) => _SectionCard(
                      section: _sections[i],
                      onSaved: _load,
                      admin: _admin,
                    ),
                  ),
          ),
        ],
      );
}

class _SectionCard extends StatefulWidget {
  const _SectionCard({
    required this.section,
    required this.onSaved,
    required this.admin,
  });

  final Map<String, dynamic> section;
  final VoidCallback onSaved;
  final AdminService admin;

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _expanded = false;
  late TextEditingController _titreCtrl;
  late TextEditingController _contenuCtrl;
  late TextEditingController _iconeCtrl;
  bool _estActif = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titreCtrl = TextEditingController(text: widget.section['titre'] as String? ?? '');
    _contenuCtrl = TextEditingController(text: widget.section['contenu'] as String? ?? '');
    _iconeCtrl = TextEditingController(text: widget.section['icone'] as String? ?? '');
    _estActif = widget.section['est_actif'] != false;
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _contenuCtrl.dispose();
    _iconeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    setState(() => _isSaving = true);
    try {
      final id = widget.section['id']?.toString() ?? '';
      final res = await widget.admin.putAproposSection(id, {
        'titre': _titreCtrl.text.trim(),
        'contenu': _contenuCtrl.text.trim(),
        'icone': _iconeCtrl.text.trim(),
        'est_actif': _estActif,
      });
      final body = res;
      if (body['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Section sauvegardée.'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onSaved();
        setState(() => _expanded = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(widget.section['icone'] as String? ?? '📌', style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.section['titre'] as String? ?? '',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Section visible sur le site', style: GoogleFonts.inter(fontSize: 13)),
                      value: _estActif,
                      onChanged: (v) => setState(() => _estActif = v),
                    ),
                    Row(
                      children: [
                        Expanded(child: _champAdmin(_iconeCtrl, 'Icône (emoji)', '🎯')),
                        const SizedBox(width: 10),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              _iconeCtrl.text.isEmpty ? '?' : _iconeCtrl.text,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _champAdmin(_titreCtrl, 'Titre', 'Ex: Notre Mission'),
                    const SizedBox(height: 10),
                    _champAdmin(_contenuCtrl, 'Contenu', 'Texte de la section…', maxLines: 5),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isSaving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(_isSaving ? 'Sauvegarde…' : 'Sauvegarder',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A56DB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isSaving ? null : _sauvegarder,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );

  Widget _champAdmin(TextEditingController ctrl, String label, String hint, {int maxLines = 1}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
          const SizedBox(height: 5),
          TextFormField(
            controller: ctrl,
            maxLines: maxLines,
            onChanged: (_) {
              if (label.contains('Icône')) setState(() {});
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ],
      );
}
