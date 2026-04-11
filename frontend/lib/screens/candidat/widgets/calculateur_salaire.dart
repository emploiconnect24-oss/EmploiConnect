import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/candidat_parcours_service.dart';

/// Calculateur de salaire IA (PRD §6).
class CalculateurSalaire extends StatefulWidget {
  const CalculateurSalaire({super.key});

  @override
  State<CalculateurSalaire> createState() => _CalculateurSalaireState();
}

class _CalculateurSalaireState extends State<CalculateurSalaire> {
  final _svc = CandidatParcoursService();
  final _posteCtrl = TextEditingController();
  String _domaine = 'informatique';
  String _niveau = 'junior';
  String _ville = 'Conakry';
  bool _isCalculating = false;
  Map<String, dynamic>? _resultat;

  @override
  void dispose() {
    _posteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.calculate_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calculateur de salaire',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      Text(
                        'Estimation indicative selon le marché (GNF), générée par l’IA',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Informations du poste', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                TextField(
                  controller: _posteCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Titre du poste',
                    hintText: 'Ex : Développeur Flutter…',
                    prefixIcon: const Icon(Icons.work_outline_rounded),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _domaine,
                  decoration: InputDecoration(
                    labelText: 'Domaine',
                    prefixIcon: const Icon(Icons.category_outlined),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'informatique', child: Text('Informatique')),
                    DropdownMenuItem(value: 'finance', child: Text('Finance')),
                    DropdownMenuItem(value: 'marketing', child: Text('Marketing')),
                    DropdownMenuItem(value: 'rh', child: Text('RH')),
                    DropdownMenuItem(value: 'commercial', child: Text('Commercial')),
                    DropdownMenuItem(value: 'btp', child: Text('BTP')),
                    DropdownMenuItem(value: 'sante', child: Text('Santé')),
                    DropdownMenuItem(value: 'education', child: Text('Éducation')),
                  ],
                  onChanged: (v) => setState(() => _domaine = v ?? _domaine),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _niveau,
                        decoration: InputDecoration(
                          labelText: 'Niveau',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'junior', child: Text('Junior')),
                          DropdownMenuItem(value: 'senior', child: Text('Senior')),
                          DropdownMenuItem(value: 'expert', child: Text('Expert')),
                        ],
                        onChanged: (v) => setState(() => _niveau = v ?? _niveau),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _ville,
                        decoration: InputDecoration(
                          labelText: 'Ville',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Conakry', child: Text('Conakry')),
                          DropdownMenuItem(value: 'Kindia', child: Text('Kindia')),
                          DropdownMenuItem(value: 'Labé', child: Text('Labé')),
                          DropdownMenuItem(value: 'Kankan', child: Text('Kankan')),
                        ],
                        onChanged: (v) => setState(() => _ville = v ?? _ville),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isCalculating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(
                _isCalculating ? 'Analyse en cours…' : 'Calculer avec l’IA',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isCalculating || _posteCtrl.text.trim().isEmpty ? null : _calculer,
            ),
          ),
          if (_resultat != null) ...[
            const SizedBox(height: 20),
            _buildResultat(),
          ],
        ],
      ),
    );
  }

  Widget _buildResultat() {
    final min = (_resultat!['salaire_min'] as num?)?.toInt() ?? 0;
    final max = (_resultat!['salaire_max'] as num?)?.toInt() ?? 0;
    final median = (_resultat!['salaire_median'] as num?)?.toInt() ?? 0;
    final devise = _resultat!['devise']?.toString() ?? 'GNF';
    final conseils = List<String>.from(_resultat!['conseils'] as List? ?? []);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estimation salariale', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _SalaireBox(label: 'Minimum', montant: _formatMontant(min), devise: devise, couleur: const Color(0xFFF59E0B))),
              const SizedBox(width: 8),
              Expanded(
                child: _SalaireBox(
                  label: 'Médian',
                  montant: _formatMontant(median),
                  devise: devise,
                  couleur: const Color(0xFF10B981),
                  isMis: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _SalaireBox(label: 'Maximum', montant: _formatMontant(max), devise: devise, couleur: const Color(0xFF1A56DB))),
            ],
          ),
          if (conseils.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Conseils pour négocier', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...conseils.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.arrow_right_rounded, color: Color(0xFF10B981), size: 18),
                    Expanded(child: Text(c, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF374151)))),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _calculer() async {
    setState(() {
      _isCalculating = true;
      _resultat = null;
    });
    try {
      final body = await _svc.calculateurSalaire({
        'poste': _posteCtrl.text.trim(),
        'domaine': _domaine,
        'niveau': _niveau,
        'ville': _ville,
      });
      if (!mounted) return;
      setState(() => _resultat = body['data'] as Map<String, dynamic>?);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isCalculating = false);
    }
  }

  String _formatMontant(int value) =>
      value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match g) => '${g[1]} ');
}

class _SalaireBox extends StatelessWidget {
  const _SalaireBox({
    required this.label,
    required this.montant,
    required this.devise,
    required this.couleur,
    this.isMis = false,
  });

  final String label;
  final String montant;
  final String devise;
  final Color couleur;
  final bool isMis;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: couleur.withOpacity(isMis ? 0.5 : 0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(montant, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: couleur)),
          Text(devise, style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}
