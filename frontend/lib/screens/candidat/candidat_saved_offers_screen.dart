import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/candidatures_service.dart';
import '../../services/offres_service.dart';
import '../../widgets/dialog_analyse_postulation.dart';
import 'candidat_offer_detail_screen.dart';
import 'widgets/apply_bottom_sheet.dart';

class CandidatSavedOffersScreen extends StatefulWidget {
  const CandidatSavedOffersScreen({super.key});

  @override
  State<CandidatSavedOffersScreen> createState() =>
      _CandidatSavedOffersScreenState();
}

class _CandidatSavedOffersScreenState extends State<CandidatSavedOffersScreen> {
  final _offresService = OffresService();
  final _candidaturesService = CandidaturesService();
  List<Map<String, dynamic>> _offres = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final rows = await _offresService.getSavedOffres();
      if (!mounted) return;
      setState(() {
        _offres = rows.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _retirer(Map<String, dynamic> item) async {
    final offre = (item['offre'] as Map?)?.cast<String, dynamic>() ?? {};
    final offreId = (offre['id'] ?? item['offre_id'] ?? '').toString();
    if (offreId.isEmpty) return;
    await _offresService.removeSavedOffre(offreId);
    if (!mounted) return;
    setState(() => _offres.remove(item));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Offre retirée des favoris'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _ouvrirSheetPostulation(Map<String, dynamic> item) async {
    final offre = (item['offre'] as Map?)?.cast<String, dynamic>() ?? {};
    final id = (offre['id'] ?? '').toString();
    final titre = (offre['titre'] ?? 'Offre').toString();
    if (id.isEmpty) return;
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ApplyBottomSheet(
        offerTitle: titre,
        onSubmit: (motivation) async {
          await _candidaturesService.postuler(
            offreId: id,
            lettreMotivation: motivation,
          );
        },
      ),
    );
  }

  Future<void> _postuler(Map<String, dynamic> item) async {
    final offre = (item['offre'] as Map?)?.cast<String, dynamic>() ?? {};
    final id = (offre['id'] ?? '').toString();
    final titre = (offre['titre'] ?? 'Offre').toString();
    if (id.isEmpty) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DialogAnalysePostulation(
        offreId: id,
        offreTitre: titre,
        onConfirmerPostulation: () {
          _ouvrirSheetPostulation(item);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 380;
    return Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(compact ? 12 : 20, compact ? 14 : 20, compact ? 12 : 20, 16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offres sauvegardées',
                      style: GoogleFonts.poppins(
                        fontSize: compact ? 18 : 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${_offres.length} offre(s) dans vos favoris',
                      style: GoogleFonts.inter(
                        fontSize: compact ? 12 : 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bookmark_rounded,
                  color: Color(0xFFF59E0B),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1A56DB)),
                )
              : _offres.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: const Color(0xFF1A56DB),
                      child: ListView.builder(
                        padding: EdgeInsets.all(compact ? 12 : 16),
                        itemCount: _offres.length,
                        itemBuilder: (_, i) {
                          final item = _offres[i];
                          final offre =
                              (item['offre'] as Map?)?.cast<String, dynamic>() ??
                                  {};
                          final id = (offre['id'] ?? '').toString();
                          return _OffreSauvCard(
                            offre: item,
                            onRetirer: () => _retirer(item),
                            onPostuler: () => _postuler(item),
                            onVoir: () {
                              if (id.isEmpty) return;
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      CandidatOfferDetailScreen(offreId: id),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmpty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bookmark_border_rounded,
                  color: Color(0xFFF59E0B),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune offre sauvegardée',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cliquez sur le 🔖 d\'une offre\npour la sauvegarder ici.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.search_rounded, size: 16),
                label: const Text('Parcourir les offres'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56DB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => context.go('/dashboard/offres'),
              ),
            ],
          ),
        ),
      );
}

class _OffreSauvCard extends StatelessWidget {
  const _OffreSauvCard({
    required this.offre,
    required this.onRetirer,
    required this.onPostuler,
    required this.onVoir,
  });

  final Map<String, dynamic> offre;
  final VoidCallback onRetirer;
  final VoidCallback onPostuler;
  final VoidCallback onVoir;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 420;
    final data = (offre['offre'] as Map?)?.cast<String, dynamic>() ?? {};
    final ent =
        (data['entreprise'] as Map?)?.cast<String, dynamic>() ?? {};
    final titre = (data['titre'] ?? '').toString();
    final nomEnt = (ent['nom_entreprise'] ?? 'Entreprise').toString();
    final logo = ent['logo_url']?.toString();
    final loc = (data['localisation'] ?? '').toString();
    final contrat = (data['type_contrat'] ?? '').toString();
    final score = (offre['score_compatibilite'] as num?)?.toInt();
    final dateSauv = offre['date_sauvegarde']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: logo != null && logo.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            logo,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _initLogo(nomEnt),
                          ),
                        )
                      : _initLogo(nomEnt),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              titre,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (score != null && score > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1A56DB),
                                    Color(0xFF7C3AED),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$score%',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        nomEnt,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF1A56DB),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                if (loc.isNotEmpty) ...[
                  const Icon(
                    Icons.location_on_outlined,
                    size: 12,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    loc,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                if (contrat.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      contrat,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF1A56DB),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const Spacer(),
                if (dateSauv != null)
                  Text(
                    'Sauvegardée ${_fmtDate(dateSauv)}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: narrow
                ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _retirerButton(),
                      SizedBox(width: 120, child: _voirButton()),
                      SizedBox(width: 120, child: _postulerButton()),
                    ],
                  )
                : Row(
                    children: [
                      _retirerButton(),
                      const SizedBox(width: 8),
                      Expanded(child: _voirButton()),
                      const SizedBox(width: 8),
                      Expanded(child: _postulerButton()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _retirerButton() => GestureDetector(
        onTap: onRetirer,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bookmark_remove_rounded,
                size: 14,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(width: 4),
              Text(
                'Retirer',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _voirButton() => OutlinedButton.icon(
        icon: const Icon(Icons.visibility_outlined, size: 14),
        label: const Text('Voir'),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          foregroundColor: const Color(0xFF64748B),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: onVoir,
      );

  Widget _postulerButton() => ElevatedButton.icon(
        icon: const Icon(Icons.send_rounded, size: 14),
        label: const Text('Postuler'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A56DB),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: onPostuler,
      );

  Widget _initLogo(String nom) => Center(
        child: Text(
          nom.isNotEmpty ? nom[0].toUpperCase() : '?',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A56DB),
          ),
        ),
      );

  String _fmtDate(String d) {
    try {
      final dt = DateTime.parse(d).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays == 0) return 'aujourd\'hui';
      if (diff.inDays == 1) return 'hier';
      return 'il y a ${diff.inDays}j';
    } catch (_) {
      return '';
    }
  }
}
