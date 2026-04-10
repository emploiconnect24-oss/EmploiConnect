import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/candidat_temoignage_service.dart';
import '../../services/public_site_service.dart';

class CandidatTemoignageScreen extends StatefulWidget {
  const CandidatTemoignageScreen({super.key, this.initialCandidatureId});

  final String? initialCandidatureId;

  @override
  State<CandidatTemoignageScreen> createState() => _CandidatTemoignageScreenState();
}

class _CandidatTemoignageScreenState extends State<CandidatTemoignageScreen> {
  final _publicSvc = PublicSiteService();
  final _svc = CandidatTemoignageService();
  final _contenuCtrl = TextEditingController();

  List<Map<String, dynamic>> _temoignages = [];
  List<Map<String, dynamic>> _eligible = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _note = 5;
  String? _selectedCandidatureId;

  bool get _peutTemoigner => _eligible.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _contenuCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final list = await _publicSvc.getTemoignagesPublic(limit: 60);
      final eligible = await _svc.getEligible();
      String? selected;
      final wanted = widget.initialCandidatureId?.trim() ?? '';
      if (wanted.isNotEmpty &&
          eligible.any((e) => (e['candidature_id']?.toString() ?? '') == wanted)) {
        selected = wanted;
      } else if (eligible.isNotEmpty) {
        selected = eligible.first['candidature_id']?.toString();
      }
      if (!mounted) return;
      setState(() {
        _temoignages = list;
        _eligible = eligible;
        _selectedCandidatureId = selected;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _soumettre() async {
    final cid = (_selectedCandidatureId ?? '').trim();
    if (cid.isEmpty) return;
    if (_contenuCtrl.text.trim().length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum 20 caractères requis'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await _svc.submit(
        candidatureId: cid,
        message: _contenuCtrl.text.trim(),
      );
      _contenuCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Témoignage soumis. En attente de validation administrateur.'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 380;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(compact ? 12 : 20, compact ? 12 : 20, compact ? 12 : 20, 40),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 16 : 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.star_rounded, color: Colors.white, size: 40),
                const SizedBox(height: 12),
                Text(
                  'Témoignages & Recrutement',
                  style: GoogleFonts.poppins(
                    fontSize: compact ? 17 : 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Partagez votre expérience sur EmploiConnect et aidez les autres candidats.',
                  style: GoogleFonts.inter(
                    fontSize: compact ? 12 : 13,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    _StatTemoignage('${_temoignages.length}', 'Témoignages'),
                    _StatTemoignage(_noteMoyenne(), 'Note moyenne'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionTemoignage(),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF1A56DB)))
          else if (_temoignages.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Soyez le premier à partager votre expérience !',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                ),
              ),
            )
          else ...[
            Row(
              children: [
                Text(
                  '${_temoignages.length} témoignage(s)',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._temoignages.map((t) => _TemoignageCard(temoignage: t)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTemoignage() {
    if (!_peutTemoigner) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8), size: 36),
            const SizedBox(height: 12),
            Text(
              'Témoignage disponible après acceptation',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vous pourrez partager votre expérience lorsqu\'une de vos candidatures sera acceptée par une entreprise.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final selected = _eligible.firstWhere(
      (e) => (e['candidature_id']?.toString() ?? '') == _selectedCandidatureId,
      orElse: () => _eligible.first,
    );
    final entNom = (selected['entreprise_nom'] ?? 'l\'entreprise').toString();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '✍️ Partager mon expérience',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.business_rounded, color: Color(0xFF10B981), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Suite à votre recrutement chez $entNom',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedCandidatureId,
            decoration: const InputDecoration(
              labelText: 'Candidature acceptée',
              isDense: true,
            ),
            items: _eligible
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: (e['candidature_id'] ?? '').toString(),
                    child: Text(
                      '${e['entreprise_nom'] ?? 'Entreprise'} — ${e['offre_titre'] ?? 'Offre'}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedCandidatureId = v),
          ),
          const SizedBox(height: 14),
          Text(
            'Votre note',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(
              5,
              (i) => GestureDetector(
                onTap: () => setState(() => _note = i + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    i < _note ? Icons.star_rounded : Icons.star_border_rounded,
                    color: i < _note ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _contenuCtrl,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText:
                  'Décrivez votre expérience : le processus de recrutement, l\'accueil de l\'équipe, les conditions de travail...',
              hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1)),
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
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(
                _isSubmitting ? 'Envoi...' : 'Soumettre mon témoignage',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isSubmitting ? null : _soumettre,
            ),
          ),
        ],
      ),
    );
  }

  String _noteMoyenne() {
    if (_temoignages.isEmpty) return '—';
    final notes = _temoignages.map((e) => (e['note'] as num?)?.toDouble() ?? 0).toList();
    final sum = notes.fold<double>(0, (a, b) => a + b);
    return (sum / notes.length).toStringAsFixed(1);
  }
}

class _TemoignageCard extends StatelessWidget {
  const _TemoignageCard({required this.temoignage});

  final Map<String, dynamic> temoignage;

  @override
  Widget build(BuildContext context) {
    final nom = (temoignage['candidat_nom'] ?? 'Anonyme').toString();
    final photo = temoignage['candidat_photo_url']?.toString();
    final contenu = (temoignage['message'] ?? '').toString();
    final date = temoignage['date_creation']?.toString();
    final ent = (temoignage['entreprise_nom'] ?? 'Entreprise').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF1A56DB).withValues(alpha: 0.1),
                backgroundImage: (photo != null && photo.isNotEmpty) ? NetworkImage(photo) : null,
                child: (photo == null || photo.isEmpty)
                    ? Text(
                        nom.isNotEmpty ? nom[0].toUpperCase() : 'A',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A56DB),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      ent,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (date != null && date.isNotEmpty)
                Text(
                  _fmtDate(date),
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            contenu,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF374151),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(String d) {
    try {
      final dt = DateTime.parse(d).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays < 30) return 'Il y a ${diff.inDays}j';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

class _StatTemoignage extends StatelessWidget {
  const _StatTemoignage(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
          ),
        ],
      );
}
