import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/download_service.dart';
import '../../services/recruteur_service.dart';
import '../../shared/widgets/status_badge.dart';
import '../../widgets/hover_scale.dart';
import '../../widgets/responsive_container.dart';
import '../../widgets/reveal_on_scroll.dart';
import '../recruteur/widgets/modifier_offre_dialog.dart';
import 'candidatures_offre_screen.dart';
import 'offre_form_screen.dart';

class _TabSpec {
  const _TabSpec({this.statut, required this.label, required this.statKey});
  final String? statut;
  final String label;
  final String statKey;
}

class MesOffresScreen extends StatefulWidget {
  const MesOffresScreen({super.key, this.onOpenCandidaturesForOffre});

  /// Si défini, « Candidatures » ouvre l’onglet shell avec ce filtre offre.
  final void Function(String offreId)? onOpenCandidaturesForOffre;

  @override
  State<MesOffresScreen> createState() => _MesOffresScreenState();
}

class _MesOffresScreenState extends State<MesOffresScreen> with SingleTickerProviderStateMixin {
  static const _tabs = <_TabSpec>[
    _TabSpec(statut: null, label: 'Toutes', statKey: 'total'),
    _TabSpec(statut: 'publiee', label: 'Actives', statKey: 'publiees'),
    _TabSpec(statut: 'en_attente', label: 'En attente', statKey: 'en_attente'),
    _TabSpec(statut: 'expiree', label: 'Expirées', statKey: 'expirees'),
    _TabSpec(statut: 'brouillon', label: 'Brouillons', statKey: 'brouillons'),
  ];

  final _service = RecruteurService();
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _offres = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  String? _error;
  String _contractFilter = 'tous';
  String _cityFilter = 'toutes';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _load();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  int _statCount(String key) {
    final v = _stats[key];
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final spec = _tabs[_tabController.index];
      final q = _searchCtrl.text.trim();
      final r = await _service.getOffres(
        token,
        limite: 100,
        statut: spec.statut,
        recherche: q.isEmpty ? null : q,
      );
      if (!mounted) return;
      setState(() {
        _offres = List<Map<String, dynamic>>.from(r['data']?['offres'] ?? const []);
        _stats = Map<String, dynamic>.from(r['data']?['stats'] ?? const {});
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  List<Map<String, dynamic>> get _filtered {
    return _offres.where((o) {
      final type = (o['type_contrat']?.toString() ?? '').toLowerCase();
      final city = (o['localisation']?.toString() ?? '').toLowerCase().trim();
      if (_contractFilter != 'tous' && type != _contractFilter) return false;
      if (_cityFilter != 'toutes' && city != _cityFilter) return false;
      return true;
    }).toList();
  }

  List<String> get _cities {
    final set = <String>{};
    for (final o in _offres) {
      final city = (o['localisation']?.toString() ?? '').trim();
      if (city.isNotEmpty) set.add(city);
    }
    final list = set.toList()..sort();
    return list;
  }

  String _uiStatus(Map<String, dynamic> o) {
    final raw = (o['statut']?.toString() ?? '').toLowerCase();
    if (raw == 'en_attente') return 'En attente';
    if (raw == 'publiee' || raw == 'publiée' || raw == 'active') return 'Actives';
    if (raw == 'refusee' || raw == 'refusée' || raw == 'suspendue') return 'Expirées';
    if (raw == 'expiree' || raw == 'expirée' || raw == 'fermee') return 'Expirée';
    if (raw.contains('brouillon') || raw.contains('draft')) return 'Brouillons';
    return 'Actives';
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette offre ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Oui')),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    try {
      final token = context.read<AuthProvider>().token ?? '';
      await _service.deleteOffre(token, id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offre supprimée')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _duplicate(Map<String, dynamic> offer) async {
    final id = offer['id']?.toString() ?? '';
    if (id.isEmpty) return;
    try {
      final token = context.read<AuthProvider>().token ?? '';
      await _service.dupliquerOffre(token, id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offre dupliquée en brouillon ✅')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _closeOffer(Map<String, dynamic> offer) async {
    final id = offer['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clôturer cette offre ?'),
        content: const Text(
          'L\'offre ne sera plus visible par les candidats. Les candidatures reçues seront conservées.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Clôturer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    try {
      final token = context.read<AuthProvider>().token ?? '';
      await _service.cloturerOffre(token, id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offre clôturée')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _exportCsv() async {
    final token = context.read<AuthProvider>().token ?? '';
    try {
      await DownloadService.downloadCsvFromApi(
        apiPathAndQuery: '/recruteur/offres/export/csv',
        token: token,
        fileName: 'mes_offres.csv',
        context: context,
      );
      if (!mounted) return;
      DownloadService.showWebDownloadSnackBar(context, 'mes_offres.csv');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _openForm() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const OffreFormScreen()));
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_loading && _offres.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null && _offres.isEmpty) return Center(child: Text(_error!));

    final list = _filtered;

    return ResponsiveContainer(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mes offres d\'emploi',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text('Gérez toutes vos annonces de recrutement.', style: TextStyle(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _exportCsv,
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Exporter'),
                ),
                const SizedBox(width: 8),
                HoverScale(
                  onTap: _openForm,
                  child: FilledButton.icon(
                    onPressed: _openForm,
                    icon: const Icon(Icons.add),
                    label: const Text('Publier une offre'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RevealOnScroll(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: const Color(0xFF1A56DB),
                      unselectedLabelColor: scheme.onSurfaceVariant,
                      indicatorColor: const Color(0xFF1A56DB),
                      tabs: [
                        for (final t in _tabs)
                          Tab(text: '${t.label} (${_statCount(t.statKey)})'),
                      ],
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 320,
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Rechercher par titre...',
                                prefixIcon: Icon(Icons.search),
                                isDense: true,
                              ),
                              onChanged: _onSearchChanged,
                            ),
                          ),
                          SizedBox(
                            width: 180,
                            child: DropdownButtonFormField<String>(
                              initialValue: _contractFilter,
                              decoration: const InputDecoration(labelText: 'Contrat', isDense: true),
                              items: const [
                                DropdownMenuItem(value: 'tous', child: Text('Tous')),
                                DropdownMenuItem(value: 'cdi', child: Text('CDI')),
                                DropdownMenuItem(value: 'cdd', child: Text('CDD')),
                                DropdownMenuItem(value: 'stage', child: Text('Stage')),
                                DropdownMenuItem(value: 'freelance', child: Text('Freelance')),
                              ],
                              onChanged: (v) {
                                setState(() => _contractFilter = v ?? 'tous');
                              },
                            ),
                          ),
                          SizedBox(
                            width: 180,
                            child: DropdownButtonFormField<String>(
                              initialValue: _cityFilter,
                              decoration: const InputDecoration(labelText: 'Ville', isDense: true),
                              items: [
                                const DropdownMenuItem(value: 'toutes', child: Text('Toutes')),
                                ..._cities.map((c) => DropdownMenuItem(value: c.toLowerCase(), child: Text(c))),
                              ],
                              onChanged: (v) {
                                setState(() => _cityFilter = v ?? 'toutes');
                              },
                            ),
                          ),
                          if (_loading)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Text('${list.length} résultat(s)', style: TextStyle(color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (list.isEmpty && !_loading)
              Padding(
                padding: const EdgeInsets.only(top: 36),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.work_outline, size: 46, color: scheme.onSurfaceVariant),
                      const SizedBox(height: 10),
                      Text(
                        _searchCtrl.text.trim().isNotEmpty
                            ? 'Aucune offre pour « ${_searchCtrl.text.trim()} »'
                            : 'Aucune offre dans cette catégorie.',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      if (_tabController.index == 0)
                        FilledButton.icon(
                          onPressed: _openForm,
                          icon: const Icon(Icons.add),
                          label: const Text('Publier une offre'),
                        ),
                    ],
                  ),
                ),
              )
            else
              ...list.map(
                (o) => _OffreCard(
                  o,
                  statusUi: _uiStatus(o),
                  onDelete: _delete,
                  onDuplicate: () => _duplicate(o),
                  onClose: () => _closeOffer(o),
                  onRefresh: _load,
                  onOpenCandidaturesForOffre: widget.onOpenCandidaturesForOffre,
                ),
              ),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}

class _OffreCard extends StatelessWidget {
  const _OffreCard(
    this.o, {
    required this.statusUi,
    required this.onDelete,
    required this.onDuplicate,
    required this.onClose,
    required this.onRefresh,
    this.onOpenCandidaturesForOffre,
  });

  final Map<String, dynamic> o;
  final String statusUi;
  final Future<void> Function(String id) onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onClose;
  final Future<void> Function() onRefresh;
  final void Function(String offreId)? onOpenCandidaturesForOffre;

  void _openCandidatures(BuildContext context, String id, String titre) {
    if (onOpenCandidaturesForOffre != null && id.isNotEmpty) {
      onOpenCandidaturesForOffre!(id);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CandidaturesOffreScreen(offreId: id, titre: titre),
      ),
    );
  }

  void _showModifierDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => ModifierOffreDialog(offre: o, onSaved: () => onRefresh()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final id = o['id']?.toString() ?? '';
    final titre = o['titre']?.toString() ?? '';
    final statutRaw = o['statut']?.toString() ?? '';
    final statut = statutRaw.isEmpty ? statusUi : statutRaw;
    final loc = o['localisation']?.toString() ?? '';
    final contrat = o['type_contrat']?.toString() ?? '';
    final dateLim = o['date_limite']?.toString();
    final nbVues = (o['nb_vues'] is num) ? (o['nb_vues'] as num).round() : int.tryParse(o['nb_vues']?.toString() ?? '') ?? 0;
    final nbCands =
        (o['nb_candidatures'] is num) ? (o['nb_candidatures'] as num).round() : int.tryParse(o['nb_candidatures']?.toString() ?? '') ?? 0;
    final nonLues =
        (o['nb_non_lues'] is num) ? (o['nb_non_lues'] as num).round() : int.tryParse(o['nb_non_lues']?.toString() ?? '') ?? 0;
    final raisonRefus = o['raison_refus']?.toString();
    final enVedette = o['en_vedette'] == true;
    final stLower = statutRaw.toLowerCase();

    Color borderColor = const Color(0xFFE2E8F0);
    Color bgColor = Colors.white;
    Color accentLeft = const Color(0xFF1A56DB);
    if (stLower == 'publiee' || stLower == 'active') {
      borderColor = const Color(0xFF10B981).withValues(alpha: 0.35);
      bgColor = const Color(0xFFF0FDF4);
      accentLeft = const Color(0xFF10B981);
    } else if (stLower == 'en_attente') {
      borderColor = const Color(0xFFF59E0B).withValues(alpha: 0.35);
      bgColor = const Color(0xFFFFFBEB);
      accentLeft = const Color(0xFFF59E0B);
    } else if (stLower == 'refusee' || stLower == 'suspendue') {
      borderColor = const Color(0xFFEF4444).withValues(alpha: 0.35);
      bgColor = const Color(0xFFFFF5F5);
      accentLeft = const Color(0xFFEF4444);
    } else if (stLower == 'expiree' || stLower == 'expirée' || stLower == 'fermee' || stLower == 'fermée') {
      borderColor = const Color(0xFF8B5CF6).withValues(alpha: 0.35);
      bgColor = const Color(0xFFF5F3FF);
      accentLeft = const Color(0xFF8B5CF6);
    } else if (stLower.contains('brouillon') || stLower.contains('draft')) {
      accentLeft = const Color(0xFF64748B);
    }

    return RevealOnScroll(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: accentLeft.withValues(alpha: 0.14),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 5,
                decoration: BoxDecoration(
                  color: accentLeft,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A56DB).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.work_outline_rounded, color: Color(0xFF1A56DB), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titre.isEmpty ? 'Offre' : titre,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                StatusBadge(label: statut),
                                if (enVedette)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      '⭐ En vedette',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFB45309),
                                      ),
                                    ),
                                  ),
                                if (nonLues > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                                      ),
                                      borderRadius: BorderRadius.circular(100),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.mark_email_unread_rounded, size: 13, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$nonLues nouvelle${nonLues > 1 ? 's' : ''}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF94A3B8)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (action) {
                          if (action == 'cand') {
                            _openCandidatures(context, id, titre);
                          } else if (action == 'form') {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => OffreFormScreen(offreId: id)),
                            );
                          } else if (action == 'dup') {
                            onDuplicate();
                          } else if (action == 'close') {
                            onClose();
                          } else if (action == 'del') {
                            onDelete(id);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'cand', child: Text('Voir candidatures')),
                          const PopupMenuItem(value: 'form', child: Text('Édition complète')),
                          const PopupMenuItem(value: 'dup', child: Text('Dupliquer')),
                          if (stLower == 'publiee' || stLower == 'active')
                            const PopupMenuItem(value: 'close', child: Text('Clôturer')),
                          const PopupMenuItem(value: 'del', child: Text('Supprimer')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      if (loc.isNotEmpty) _InfoChip(Icons.location_on_outlined, loc),
                      if (contrat.isNotEmpty) _InfoChip(Icons.badge_outlined, _labelContrat(contrat)),
                      if (dateLim != null && dateLim.isNotEmpty)
                        _InfoChip(Icons.calendar_today_outlined, 'Jusqu\'au ${_fmtDate(dateLim)}'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatMini(Icons.visibility_outlined, '$nbVues', 'Vues', const Color(0xFF8B5CF6)),
                        Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
                        _StatMini(Icons.people_outline, '$nbCands', 'Candidats', const Color(0xFF1A56DB)),
                        Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
                        _StatMini(
                          Icons.mark_email_unread_outlined,
                          '$nonLues',
                          'Non lus',
                          nonLues > 0 ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                  if (stLower == 'en_attente') ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, size: 18, color: Color(0xFF92400E)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'En attente de validation par un administrateur',
                              style: TextStyle(fontSize: 12, color: scheme.onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if ((stLower == 'refusee' || stLower == 'suspendue') && raisonRefus != null && raisonRefus.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFEF4444), size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Motif du refus : $raisonRefus',
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF991B1B)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  ],
                ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                    border: Border.fromBorderSide(BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => _openCandidatures(context, id, titre),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFDBEAFE),
                          foregroundColor: const Color(0xFF1A56DB),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.people_outline_rounded, size: 16),
                        label: Text(
                          'Voir candidatures',
                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _showModifierDialog(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text(
                          'Modifier',
                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'ID: ${id.isEmpty ? '—' : id.substring(0, id.length < 8 ? id.length : 8)}',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                      ),
                    ],
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

  String _labelContrat(String c) {
    const map = {
      'cdi': 'CDI',
      'cdd': 'CDD',
      'stage': 'Stage',
      'freelance': 'Freelance',
      'temps_partiel': 'Temps partiel',
    };
    return map[c.toLowerCase()] ?? c;
  }

  String _fmtDate(String d) {
    try {
      final dt = DateTime.parse(d);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return d;
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 4),
          Text(text, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
        ],
      );
}

class _StatMini extends StatelessWidget {
  const _StatMini(this.icon, this.value, this.label, this.color);
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
          ),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
        ],
      );
}
