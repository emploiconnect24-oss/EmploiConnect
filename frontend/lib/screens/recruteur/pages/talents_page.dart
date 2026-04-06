import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../services/recruteur_service.dart';
import '../../../widgets/signalement_content_sheet.dart';
import '../recruteur_messagerie_connected_screen.dart';

/// PRD §6–7 — Recherche talents : filtres, matching par offre, grille premium.
class TalentsPage extends StatefulWidget {
  const TalentsPage({super.key});

  @override
  State<TalentsPage> createState() => _TalentsPageState();
}

class _TalentsPageState extends State<TalentsPage> {
  final RecruteurService _svc = RecruteurService();
  List<Map<String, dynamic>> _talents = [];
  List<Map<String, dynamic>> _mesOffres = [];
  bool _isLoading = true;
  String? _offreSelectee;
  String? _offreSelecteeTitre;
  String _recherche = '';
  String? _niveauEtude;
  String? _disponibilite;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMesOffres();
      _loadTalents();
    });
  }

  Future<void> _loadMesOffres() async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await _svc.getOffres(token, statut: 'publiee', limite: 100);
      if (!mounted) return;
      setState(() {
        _mesOffres = List<Map<String, dynamic>>.from(res['data']?['offres'] ?? []);
      });
    } catch (_) {}
  }

  Future<void> _loadTalents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await _svc.getTalents(
        token,
        recherche: _recherche.isNotEmpty ? _recherche : null,
        niveauEtude: _niveauEtude,
        disponibilite: _disponibilite,
        offreId: _offreSelectee,
        limite: 60,
      );
      if (!mounted) return;
      setState(() {
        _talents = List<Map<String, dynamic>>.from(res['data']?['talents'] ?? []);
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                _buildSearchAndFilters(),
                const SizedBox(height: 16),
                if (_offreSelectee != null) _buildMatchingBanner(),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(60),
                      child: CircularProgressIndicator(color: Color(0xFF1A56DB)),
                    ),
                  )
                else if (_talents.isEmpty)
                  _buildEmptyTalents()
                else
                  _buildTalentsGrid(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        color: const Color(0xFFF8FAFC),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              'IA',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Recherche de Talents',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_talents.length} profil(s) dans cette vue',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildSearchAndFilters() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Rechercher par compétence, nom...',
              hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFCBD5E1)),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
              suffixIcon: _recherche.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _recherche = '');
                        _loadTalents();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1A56DB), width: 1.5),
              ),
            ),
            onChanged: (v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 400), () {
                setState(() => _recherche = v);
                _loadTalents();
              });
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (_mesOffres.isNotEmpty) ...[
                  _FilterChip(
                    label: _offreSelecteeTitre ?? 'Matcher avec une offre (IA)',
                    isActive: _offreSelectee != null,
                    icon: Icons.auto_awesome_outlined,
                    color: const Color(0xFF8B5CF6),
                    onTap: _showOffreMatcherBottomSheet,
                  ),
                  const SizedBox(width: 8),
                ],
                _FilterChip(
                  label: _niveauEtude != null ? _labelNiveau(_niveauEtude!) : 'Niveau d\'étude',
                  isActive: _niveauEtude != null,
                  icon: Icons.school_outlined,
                  color: const Color(0xFF1A56DB),
                  onTap: _showNiveauPicker,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _disponibilite != null ? _labelDispo(_disponibilite!) : 'Disponibilité',
                  isActive: _disponibilite != null,
                  icon: Icons.schedule_outlined,
                  color: const Color(0xFF10B981),
                  onTap: _showDispoPicker,
                ),
                if (_offreSelectee != null || _niveauEtude != null || _disponibilite != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _offreSelectee = null;
                        _offreSelecteeTitre = null;
                        _niveauEtude = null;
                        _disponibilite = null;
                      });
                      _loadTalents();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444)),
                          const SizedBox(width: 4),
                          Text(
                            'Réinitialiser',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );

  Widget _buildMatchingBanner() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1A56DB), Color(0xFF8B5CF6)]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Score IA activé',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Tri par compatibilité avec « ${_offreSelecteeTitre ?? ''} »',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _offreSelectee = null;
                  _offreSelecteeTitre = null;
                });
                _loadTalents();
              },
              child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
            ),
          ],
        ),
      );

  Widget _buildTalentsGrid() {
    return LayoutBuilder(
      builder: (ctx, c) {
        final cols = c.maxWidth > 1200
            ? 4
            : c.maxWidth > 900
                ? 3
                : c.maxWidth > 600
                    ? 2
                    : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            childAspectRatio: 0.72,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: _talents.length,
          itemBuilder: (ctx, i) {
            final t = _talents[i];
            final uid = (t['utilisateur'] as Map?)?['id']?.toString() ?? t['utilisateur_id']?.toString() ?? '';
            return _TalentCard(
              talent: t,
              mesOffres: _mesOffres,
              offrePreselectionneeId: _offreSelectee,
              onContact: (msg, offreId) => _contacter(t, msg, offreId),
              onSignaler: uid.isEmpty
                  ? null
                  : () => showSignalementContentDialog(
                        context,
                        typeObjet: 'profil',
                        objetId: uid,
                        dialogTitle: 'Signaler ce profil candidat',
                        description:
                            'Réservé à la modération : profil suspect, identité douteuse, contenu inapproprié, etc.',
                      ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyTalents() => Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
              child: const Icon(Icons.search_off_outlined, color: Color(0xFF1A56DB), size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun talent trouvé',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Modifiez vos critères de recherche',
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
            ),
          ],
        ),
      );

  Future<void> _contacter(Map<String, dynamic> talent, String message, String? offreId) async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final userId = talent['utilisateur']?['id']?.toString();
      if (userId == null || userId.isEmpty) return;

      await _svc.contacterTalent(token, userId, message, offreId: offreId ?? _offreSelectee);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.send_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Message envoyé à ${talent['utilisateur']?['nom'] ?? ''}',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );

      // UX pro: ouvrir directement le fil après envoi
      final peerName = talent['utilisateur']?['nom']?.toString();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RecruteurMessagerieConnectedScreen(
            initialPeerId: userId,
            initialPeerName: peerName,
          ),
        ),
      );
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
    }
  }

  void _showOffreMatcherBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sélectionner une offre pour le matching IA',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
              child: SingleChildScrollView(
                child: Column(
                  children: _mesOffres
                      .map(
                        (o) => ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.work_outline, color: Color(0xFF1A56DB), size: 18),
                          ),
                          title: Text(o['titre']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 14)),
                          trailing: _offreSelectee == o['id']
                              ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981))
                              : null,
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _offreSelectee = o['id']?.toString();
                              _offreSelecteeTitre = o['titre']?.toString();
                            });
                            _loadTalents();
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNiveauPicker() {
    const niveaux = {
      'bac': 'Baccalauréat',
      'bac2': 'Bac+2',
      'licence': 'Licence (Bac+3)',
      'master': 'Master (Bac+5)',
      'doctorat': 'Doctorat',
    };
    _showPickerSheet('Niveau d\'étude', niveaux, _niveauEtude, (v) {
      setState(() => _niveauEtude = v);
      _loadTalents();
    });
  }

  void _showDispoPicker() {
    const dispos = {
      'immediat': 'Disponible immédiatement',
      '1_mois': 'Dans 1 mois',
      '3_mois': 'Dans 3 mois',
    };
    _showPickerSheet('Disponibilité', dispos, _disponibilite, (v) {
      setState(() => _disponibilite = v);
      _loadTalents();
    });
  }

  void _showPickerSheet(
    String title,
    Map<String, String> options,
    String? selected,
    void Function(String?) onSelect,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (selected != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onSelect(null);
                },
                child: const Text('Réinitialiser ce filtre'),
              ),
            ...options.entries.map(
              (e) => ListTile(
                title: Text(e.value, style: GoogleFonts.inter(fontSize: 14)),
                trailing: selected == e.key ? const Icon(Icons.check_rounded, color: Color(0xFF1A56DB)) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  onSelect(e.key);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelNiveau(String n) {
    const map = {
      'bac': 'Bac',
      'bac2': 'Bac+2',
      'licence': 'Licence',
      'master': 'Master',
      'doctorat': 'Doctorat',
    };
    return map[n] ?? n;
  }

  String _labelDispo(String d) {
    const map = {
      'immediat': 'Disponible',
      '1_mois': '1 mois',
      '3_mois': '3 mois',
    };
    return map[d] ?? d;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? color.withValues(alpha: 0.12) : Colors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: isActive ? color : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

String _initial(String? nom) {
  final s = (nom ?? '').trim();
  if (s.isEmpty) return 'C';
  return s[0].toUpperCase();
}

class _TalentCard extends StatelessWidget {
  const _TalentCard({
    required this.talent,
    required this.onContact,
    this.mesOffres = const [],
    this.offrePreselectionneeId,
    this.onSignaler,
  });

  final Map<String, dynamic> talent;
  final List<Map<String, dynamic>> mesOffres;
  final String? offrePreselectionneeId;
  final void Function(String message, String? offreId) onContact;
  final VoidCallback? onSignaler;

  @override
  Widget build(BuildContext context) {
    final u = talent['utilisateur'] as Map<String, dynamic>? ?? {};
    final nom = u['nom'] as String? ?? 'Candidat';
    final photo = u['photo_url'] as String?;
    final adresse = u['adresse'] as String? ?? '';
    final niveau = talent['niveau_etude'] as String? ?? '';
    final dispo = talent['disponibilite'] as String? ?? '';
    final score = (talent['score_matching'] as num?)?.round();
    final comps = List<String>.from(talent['toutes_competences'] as List? ?? []);
    final highMatch = score != null && score >= 70;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: highMatch
                    ? const [Color(0xFFECFDF5), Color(0xFFD1FAE5)]
                    : const [Color(0xFFEFF6FF), Color(0xFFF0F9FF)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                if (score != null && score > 0)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _scoreColor(score),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: _scoreColor(score).withValues(alpha: 0.4),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '$score% match',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (score != null && score > 0) const SizedBox(height: 8),
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFF1A56DB),
                  backgroundImage: photo != null ? NetworkImage(photo) : null,
                  child: photo == null
                      ? Text(
                          nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  nom,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (adresse.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          adresse,
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dispo.isNotEmpty) ...[
                    _DispoBanner(dispo),
                    const SizedBox(height: 8),
                  ],
                  if (niveau.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.school_outlined, size: 13, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _cardLabelNiveau(niveau),
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  if (comps.isNotEmpty)
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        ...comps.take(4).map(
                          (c) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Text(
                              c,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1E40AF),
                              ),
                            ),
                          ),
                        ),
                        if (comps.length > 4)
                          Text(
                            '+${comps.length - 4}',
                            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (onSignaler != null) ...[
                  Material(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: onSignaler,
                      borderRadius: BorderRadius.circular(10),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.flag_outlined, size: 18, color: Color(0xFFDC2626)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.chat_outlined, size: 16),
                    label: Text('Contacter', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A56DB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showContactDialog(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int s) {
    if (s >= 80) return const Color(0xFF10B981);
    if (s >= 50) return const Color(0xFF1A56DB);
    return const Color(0xFFF59E0B);
  }

  String _cardLabelNiveau(String n) {
    const map = {
      'bac': 'Bac',
      'bac2': 'Bac+2',
      'licence': 'Licence',
      'master': 'Master',
      'doctorat': 'Doctorat',
    };
    return map[n] ?? n;
  }

  static String _objetPrefix(String key) {
    switch (key) {
      case 'entretien':
        return '[Entretien] ';
      case 'info':
        return '[Information] ';
      default:
        return '[Opportunité] ';
    }
  }

  void _showContactDialog(BuildContext context) {
    final ctrl = TextEditingController(
      text: 'Bonjour, votre profil correspond à nos besoins. '
          'Nous aimerions vous proposer une opportunité.',
    );
    String? offreChoisie = offrePreselectionneeId;
    final objetRef = <String>['opportunite'];
    showDialog<void>(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF1A56DB),
                backgroundImage: (talent['utilisateur']?['photo_url'] != null)
                    ? NetworkImage(talent['utilisateur']['photo_url'] as String)
                    : null,
                child: talent['utilisateur']?['photo_url'] == null
                    ? Text(
                        _initial(talent['utilisateur']?['nom']?.toString()),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contacter', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(
                      talent['utilisateur']?['nom']?.toString() ?? '',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Objet du message', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ObjetChip(
                      label: 'Opportunité',
                      selected: objetRef[0] == 'opportunite',
                      onTap: () => setDlg(() => objetRef[0] = 'opportunite'),
                    ),
                    _ObjetChip(
                      label: 'Entretien',
                      selected: objetRef[0] == 'entretien',
                      onTap: () => setDlg(() => objetRef[0] = 'entretien'),
                    ),
                    _ObjetChip(
                      label: 'Information',
                      selected: objetRef[0] == 'info',
                      onTap: () => setDlg(() => objetRef[0] = 'info'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (mesOffres.isNotEmpty) ...[
                  Text('Offre associée (optionnel)', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String?>(
                    value: offreChoisie,
                    decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                    hint: const Text('Aucune offre liée'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('— Aucune —')),
                      ...mesOffres.map(
                        (o) => DropdownMenuItem<String?>(
                          value: o['id']?.toString(),
                          child: Text(o['titre']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) => setDlg(() => offreChoisie = v),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: ctrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    hintText: 'Rédigez votre message...',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text('Annuler', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, size: 16),
              label: Text('Envoyer', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final body = ctrl.text.trim();
                final prefixed = '${_objetPrefix(objetRef[0])}$body';
                Navigator.pop(dCtx);
                onContact(prefixed, offreChoisie);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DispoBanner extends StatelessWidget {
  const _DispoBanner(this.dispo);
  final String dispo;

  @override
  Widget build(BuildContext context) {
    final label = switch (dispo) {
      'immediat' => 'Disponible immédiatement',
      '1_mois' => 'Disponible sous 1 mois',
      '3_mois' => 'Disponible sous 3 mois',
      _ => dispo,
    };
    final (c0, c1, fg) = switch (dispo) {
      'immediat' => (const Color(0xFF10B981), const Color(0xFF059669), Colors.white),
      '1_mois' => (const Color(0xFFF59E0B), const Color(0xFFD97706), Colors.white),
      '3_mois' => (const Color(0xFF64748B), const Color(0xFF475569), Colors.white),
      _ => (const Color(0xFF94A3B8), const Color(0xFF64748B), Colors.white),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c0, c1]),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: c0.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 15, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjetChip extends StatelessWidget {
  const _ObjetChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1A56DB).withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: selected ? const Color(0xFF1A56DB) : const Color(0xFFE2E8F0), width: selected ? 1.5 : 1),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? const Color(0xFF1A56DB) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}
