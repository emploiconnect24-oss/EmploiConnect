import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/recruteur_provider.dart';
import '../../../services/download_service.dart';
import '../../../services/recruteur_service.dart';
import '../../../shared/widgets/ia_score_badge.dart';
import '../../../shared/widgets/status_badge.dart';
import '../recruteur_candidature_detail_screen.dart';

/// PRD §3 — Candidatures : liste / Kanban, filtres, export CSV.
class CandidaturesPage extends StatefulWidget {
  const CandidaturesPage({super.key, this.offreId, this.onShellNavigate});

  final String? offreId;
  final void Function(String route)? onShellNavigate;

  @override
  State<CandidaturesPage> createState() => _CandidaturesPageState();
}

class _CandidaturesPageState extends State<CandidaturesPage> {
  final RecruteurService _svc = RecruteurService();
  List<Map<String, dynamic>> _candidatures = [];
  Map<String, dynamic> _stats = {};
  Map<String, dynamic>? _kanban;
  bool _isLoading = true;
  bool _isKanbanView = false;
  bool _isExporting = false;
  String? _selectedStatut;
  final _searchCtrl = TextEditingController();
  String _recherche = '';
  Timer? _debounce;

  Future<void> _openDetail(String candidatureId) async {
    if (candidatureId.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            RecruteurCandidatureDetailScreen(candidatureId: candidatureId),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await _svc.getCandidatures(
        token,
        offreId: widget.offreId,
        statut: _selectedStatut,
        recherche: _recherche.isNotEmpty ? _recherche : null,
        vue: _isKanbanView ? 'kanban' : 'liste',
      );
      if (res['success'] == true && mounted) {
        final d = res['data'] as Map<String, dynamic>? ?? {};
        setState(() {
          _candidatures = List<Map<String, dynamic>>.from(
            d['candidatures'] ?? [],
          );
          _stats = Map<String, dynamic>.from(d['stats'] as Map? ?? {});
          _kanban = d['kanban'] != null
              ? Map<String, dynamic>.from(d['kanban'] as Map)
              : null;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _stat(String key) {
    final v = _stats[key];
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: const Color(0xFF1A56DB),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  if (!_isLoading) _buildStatChips(),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(60),
                        child: CircularProgressIndicator(
                          color: Color(0xFF1A56DB),
                        ),
                      ),
                    )
                  else if (_isKanbanView && _kanban != null)
                    _buildKanban()
                  else
                    _buildListe(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
    color: const Color(0xFFF8FAFC),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.offreId != null
                        ? 'Candidatures (offre)'
                        : 'Candidatures reçues',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '${_stat('total')} candidature(s) au total',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              icon: _isExporting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined, size: 16),
              label: Text(
                _isExporting ? 'Export...' : 'Exporter CSV',
                style: GoogleFonts.inter(fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isExporting ? null : _exportCsv,
            ),
            const SizedBox(width: 10),
            _buildViewSwitch(),
          ],
        ),
        const SizedBox(height: 12),
      ],
    ),
  );

  Widget _buildViewSwitch() => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.all(3),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ViewBtn(
          icon: Icons.list_rounded,
          label: 'Liste',
          selected: !_isKanbanView,
          onTap: () {
            setState(() => _isKanbanView = false);
            _load();
          },
        ),
        _ViewBtn(
          icon: Icons.view_kanban_outlined,
          label: 'Kanban',
          selected: _isKanbanView,
          onTap: () {
            setState(() => _isKanbanView = true);
            _load();
          },
        ),
      ],
    ),
  );

  Widget _buildStatChips() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _StatChip('Toutes', null, _stat('total'), _selectedStatut, _setStatut),
        _StatChip(
          'En attente',
          'en_attente',
          _stat('en_attente'),
          _selectedStatut,
          _setStatut,
          color: const Color(0xFF1A56DB),
        ),
        _StatChip(
          'En examen',
          'en_cours',
          _stat('en_cours'),
          _selectedStatut,
          _setStatut,
          color: const Color(0xFFF59E0B),
        ),
        _StatChip(
          'Entretien',
          'entretien',
          _stat('entretien'),
          _selectedStatut,
          _setStatut,
          color: const Color(0xFF8B5CF6),
        ),
        _StatChip(
          'Acceptées',
          'acceptee',
          _stat('acceptees'),
          _selectedStatut,
          _setStatut,
          color: const Color(0xFF10B981),
        ),
        _StatChip(
          'Refusées',
          'refusee',
          _stat('refusees'),
          _selectedStatut,
          _setStatut,
          color: const Color(0xFFEF4444),
        ),
      ],
    ),
  );

  Widget _buildSearchBar() => TextField(
    controller: _searchCtrl,
    decoration: InputDecoration(
      hintText: 'Rechercher un candidat...',
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: const Color(0xFFCBD5E1),
      ),
      prefixIcon: const Icon(
        Icons.search_rounded,
        color: Color(0xFF94A3B8),
        size: 18,
      ),
      suffixIcon: _recherche.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear, size: 16, color: Color(0xFF94A3B8)),
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _recherche = '');
                _load();
              },
            )
          : null,
      filled: true,
      fillColor: Colors.white,
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
    ),
    onChanged: (v) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), () {
        setState(() => _recherche = v);
        _load();
      });
    },
  );

  Widget _buildListe() {
    if (_candidatures.isEmpty) return _buildEmptyState();
    return Column(
      children: _candidatures
          .map(
            (c) => _CandidatureListCard(
              candidature: c,
              onAction: _handleAction,
              onOpenDetail: () => _openDetail(c['id']?.toString() ?? ''),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEmptyState() => Container(
    margin: const EdgeInsets.only(top: 40),
    child: Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.people_outline_rounded,
            color: Color(0xFF1A56DB),
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Aucune candidature',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _selectedStatut == null
              ? 'Vous n\'avez pas encore reçu de candidatures.\nPubliez des offres pour attirer des talents !'
              : 'Aucune candidature avec ce statut.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF64748B),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        if (_selectedStatut == null) ...[
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Publier une offre'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56DB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => widget.onShellNavigate?.call(
              '/dashboard-recruteur/offres/nouvelle',
            ),
          ),
        ],
      ],
    ),
  );

  Widget _buildKanban() {
    if (_kanban == null) return _buildEmptyState();
    final colonnes = [
      _KanbanCol('Reçues', 'en_attente', const Color(0xFF1A56DB)),
      _KanbanCol('Examen', 'en_cours', const Color(0xFFF59E0B)),
      _KanbanCol('Entretien', 'entretien', const Color(0xFF8B5CF6)),
      _KanbanCol('Acceptées', 'acceptees', const Color(0xFF10B981)),
      _KanbanCol('Refusées', 'refusees', const Color(0xFFEF4444)),
    ];
    return SizedBox(
      height: 560,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: colonnes
            .map(
              (col) => _KanbanColumn(
                col: col,
                items: List<Map<String, dynamic>>.from(
                  _kanban![col.key] as List? ?? [],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final parts = <String>[];
      if (widget.offreId != null && widget.offreId!.isNotEmpty) {
        parts.add('offre_id=${Uri.encodeQueryComponent(widget.offreId!)}');
      }
      if (_selectedStatut != null && _selectedStatut!.isNotEmpty) {
        parts.add('statut=${Uri.encodeQueryComponent(_selectedStatut!)}');
      }
      final q = parts.isEmpty ? '' : '?${parts.join('&')}';
      await DownloadService.downloadCsvFromApi(
        apiPathAndQuery: '/recruteur/candidatures/export/csv$q',
        token: token,
        fileName:
            'candidatures_${DateTime.now().toIso8601String().split('T').first}.csv',
        context: context,
      );
      if (!mounted) return;
      DownloadService.showWebDownloadSnackBar(context, 'candidatures.csv');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur export: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleAction(
    String id,
    String action, {
    String? dateEntretien,
    String? lienVisio,
    String? raisonRefus,
  }) async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await _svc.actionCandidature(
        token,
        id,
        action,
        dateEntretien: dateEntretien,
        lienVisio: lienVisio,
        raisonRefus: raisonRefus,
      );
      if (res['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Action effectuée',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        await _load();
        if (!mounted) return;
        final token2 = context.read<AuthProvider>().token ?? '';
        await context.read<RecruteurProvider>().refreshCounts(token2);
      }
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

  void _setStatut(String? v) {
    setState(() => _selectedStatut = v);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(
    this.label,
    this.value,
    this.count,
    this.selected,
    this.onSelect, {
    this.color = const Color(0xFF64748B),
  });

  final String label;
  final String? value;
  final int count;
  final String? selected;
  final void Function(String?) onSelect;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isSel = selected == value;
    final c = color;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelect(value),
          borderRadius: BorderRadius.circular(100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSel ? c : Colors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: isSel ? c : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSel ? Colors.white : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isSel
                        ? Colors.white.withValues(alpha: 0.25)
                        : c.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSel ? Colors.white : c,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewBtn extends StatelessWidget {
  const _ViewBtn({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: selected ? const Color(0xFF1A56DB) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected
                  ? const Color(0xFF1A56DB)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    ),
  );
}

class _KanbanCol {
  const _KanbanCol(this.label, this.key, this.color);
  final String label;
  final String key;
  final Color color;
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({required this.col, required this.items});

  final _KanbanCol col;
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) => Container(
    width: 240,
    margin: const EdgeInsets.only(right: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: col.color.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: col.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                col.label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: col.color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: col.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${items.length}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: col.color,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.all(8),
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Aucune',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  )
                : ListView(
                    children: items
                        .map((c) => _KanbanMiniCard(c: c, color: col.color))
                        .toList(),
                  ),
          ),
        ),
      ],
    ),
  );
}

class _KanbanMiniCard extends StatelessWidget {
  const _KanbanMiniCard({required this.c, required this.color});

  final Map<String, dynamic> c;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final nom = c['chercheur']?['utilisateur']?['nom'] ?? 'Candidat';
    final poste = c['offre']?['titre'] ?? '';
    final score = (c['score_compatibilite'] as num?)?.round();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nom,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (poste.toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              poste.toString(),
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF94A3B8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (score != null && score > 0) ...[
            const SizedBox(height: 6),
            Text(
              '$score%',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CandidatureListCard extends StatelessWidget {
  const _CandidatureListCard({
    required this.candidature,
    required this.onAction,
    required this.onOpenDetail,
  });

  final Map<String, dynamic> candidature;
  final Future<void> Function(
    String id,
    String action, {
    String? dateEntretien,
    String? lienVisio,
    String? raisonRefus,
  })
  onAction;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final nom = candidature['chercheur']?['utilisateur']?['nom'] ?? 'Candidat';
    final email = candidature['chercheur']?['utilisateur']?['email'] ?? '';
    final photo =
        candidature['chercheur']?['utilisateur']?['photo_url'] as String?;
    final poste = candidature['offre']?['titre'] ?? '';
    final statut = candidature['statut'] as String? ?? '';
    final score = (candidature['score_compatibilite'] as num?)?.round();
    final date = _fmtDate(candidature['date_candidature']?.toString());
    final id = candidature['id']?.toString() ?? '';
    final niveau = candidature['chercheur']?['niveau_etude'] as String?;

    Color cardBg = Colors.white;
    if (statut == 'en_attente') cardBg = const Color(0xFFFAFAFF);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpenDetail,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: statut == 'en_attente'
                  ? const Color(0xFF1A56DB).withValues(alpha: 0.15)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFF1A56DB),
                          backgroundImage: photo != null
                              ? NetworkImage(photo)
                              : null,
                          child: photo == null
                              ? Text(
                                  nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _statusColor(statut),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  nom,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              StatusBadge(label: statut),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            email,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.work_outline_rounded,
                                size: 13,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  poste.toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF475569),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                date,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                          if (niveau != null && niveau.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.school_outlined,
                                  size: 13,
                                  color: Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _labelNiveau(niveau),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (score != null && score > 0) ...[
                      IAScoreBadge(score: score),
                      const SizedBox(width: 8),
                    ],
                    const Spacer(),
                    ..._buildActions(context, id, statut),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext ctx, String id, String statut) {
    switch (statut) {
      case 'en_attente':
        return [
          _ActionButton(
            label: 'Examiner',
            icon: Icons.visibility_outlined,
            color: const Color(0xFF1A56DB),
            onTap: () => onAction(id, 'mettre_en_examen'),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            label: 'Refuser',
            icon: Icons.close_rounded,
            color: const Color(0xFFEF4444),
            outlined: true,
            onTap: () => _showRefuserDialog(ctx, id),
          ),
        ];
      case 'en_cours':
        return [
          _ActionButton(
            label: 'Entretien',
            icon: Icons.event_outlined,
            color: const Color(0xFF8B5CF6),
            onTap: () => _showEntretienDialog(ctx, id),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            label: 'Refuser',
            icon: Icons.close_rounded,
            color: const Color(0xFFEF4444),
            outlined: true,
            onTap: () => _showRefuserDialog(ctx, id),
          ),
        ];
      case 'entretien':
        return [
          _ActionButton(
            label: 'Accepter',
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF10B981),
            onTap: () => onAction(id, 'accepter'),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            label: 'Refuser',
            icon: Icons.close_rounded,
            color: const Color(0xFFEF4444),
            outlined: true,
            onTap: () => _showRefuserDialog(ctx, id),
          ),
        ];
      default:
        return [];
    }
  }

  void _showRefuserDialog(BuildContext ctx, String id) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Motif du refus',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Raison...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dCtx);
              onAction(id, 'refuser', raisonRefus: ctrl.text);
            },
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
  }

  void _showEntretienDialog(BuildContext ctx, String id) {
    final dateCtrl = TextEditingController();
    final lienCtrl = TextEditingController();
    showDialog<void>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Planifier un entretien',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateCtrl,
              decoration: const InputDecoration(
                labelText: 'Date / heure',
                hintText: 'AAAA-MM-JJThh:mm',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: lienCtrl,
              decoration: const InputDecoration(
                labelText: 'Lien visio (optionnel)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dCtx);
              onAction(
                id,
                'planifier_entretien',
                dateEntretien: dateCtrl.text.isNotEmpty ? dateCtrl.text : null,
                lienVisio: lienCtrl.text.isNotEmpty ? lienCtrl.text : null,
              );
            },
            child: const Text('Planifier'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'acceptee':
        return const Color(0xFF10B981);
      case 'refusee':
        return const Color(0xFFEF4444);
      case 'entretien':
        return const Color(0xFF8B5CF6);
      case 'en_cours':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF1A56DB);
    }
  }

  String _fmtDate(String? d) {
    if (d == null || d.isEmpty) return '';
    try {
      final dt = DateTime.parse(d).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays == 0) return 'Aujourd\'hui';
      if (diff.inDays == 1) return 'Hier';
      if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  String _labelNiveau(String n) {
    const map = {
      'bac': 'Baccalauréat',
      'bac2': 'Bac+2',
      'licence': 'Licence (Bac+3)',
      'master': 'Master (Bac+5)',
      'doctorat': 'Doctorat',
    };
    return map[n] ?? n;
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.outlined = false,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => outlined
      ? OutlinedButton.icon(
          icon: Icon(icon, size: 14),
          label: Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color.withValues(alpha: 0.4)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: onTap,
        )
      : ElevatedButton.icon(
          icon: Icon(icon, size: 14),
          label: Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: onTap,
        );
}
