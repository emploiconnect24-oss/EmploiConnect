import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../services/download_service.dart';
import '../../shared/widgets/status_badge.dart';
import '../../widgets/responsive_container.dart';
import 'widgets/admin_page_shimmer.dart';
import 'widgets/offre_actions_menu.dart';

class AdminJobsScreen extends StatefulWidget {
  const AdminJobsScreen({super.key, this.filterEntrepriseId});

  /// Si renseigné, seules les offres de cette entreprise sont listées.
  final String? filterEntrepriseId;

  @override
  State<AdminJobsScreen> createState() => _AdminJobsScreenState();
}

class _AdminJobsScreenState extends State<AdminJobsScreen> {
  final _admin = AdminService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _all = [];

  String _query = '';
  String _statusFilter = 'tous';
  String _cityFilter = 'toutes';
  String _sectorFilter = 'tous';
  String _activeTab = 'Toutes';
  int _currentPage = 1;
  static const int _perPage = 20;
  bool _exportingCsv = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _admin.getOffres(page: 1, limite: 200);
      final data = res['data'] as Map<String, dynamic>?;
      final raw = data?['offres'] as List<dynamic>? ?? const [];
      setState(() {
        _all = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _syncAdminBadges() {
    if (!mounted) return;
    context.read<AdminProvider>().loadDashboard();
  }

  String _entrepriseNom(Map<String, dynamic> o) {
    final e = o['entreprises'];
    if (e is Map) return e['nom_entreprise']?.toString() ?? '';
    if (e is List && e.isNotEmpty && e.first is Map) {
      return (e.first as Map)['nom_entreprise']?.toString() ?? '';
    }
    return o['nom_entreprise']?.toString() ?? '';
  }

  String _statusOf(Map<String, dynamic> o) {
    final raw = (o['statut']?.toString() ?? '').toLowerCase().trim();
    final ved = o['en_vedette'] == true;
    if (ved && (raw == 'active' || raw == 'publiee' || raw == 'publiée')) return 'En vedette';
    switch (raw) {
      case 'en_attente':
      case 'brouillon':
        return 'En attente';
      case 'publiee':
      case 'publiée':
      case 'active':
        return 'Publiée';
      case 'refusee':
      case 'refusée':
      case 'suspendue':
        return 'Refusée';
      case 'expiree':
      case 'expirée':
      case 'fermee':
        return 'Expirée';
      default:
        return raw.isEmpty ? '—' : raw;
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    final entFilter = widget.filterEntrepriseId?.trim();
    return _all.where((o) {
      if (entFilter != null && entFilter.isNotEmpty) {
        final eid = o['entreprise_id']?.toString() ?? '';
        if (eid != entFilter) return false;
      }
      final title = (o['titre']?.toString() ?? '').toLowerCase();
      final entreprise = _entrepriseNom(o).toLowerCase();
      final status = _statusOf(o);
      final city = (o['localisation']?.toString() ?? '').trim();
      final sector = (o['domaine']?.toString() ?? '').trim();

      if (q.isNotEmpty && !title.contains(q) && !entreprise.contains(q)) return false;
      if (_statusFilter != 'tous' && status != _statusFilter) return false;
      if (_cityFilter != 'toutes' && city.toLowerCase() != _cityFilter.toLowerCase()) return false;
      if (_sectorFilter != 'tous' && sector.toLowerCase() != _sectorFilter.toLowerCase()) return false;

      if (_activeTab == 'En attente' && status != 'En attente') return false;
      if (_activeTab == 'Publiées' && status != 'Publiée') return false;
      if (_activeTab == 'Refusées' && status != 'Refusée') return false;
      if (_activeTab == 'Expirées' && status != 'Expirée') return false;

      return true;
    }).toList();
  }

  Map<String, int> get _tabCounts {
    int pending = 0;
    int published = 0;
    int refused = 0;
    int expired = 0;
    for (final o in _all) {
      final s = _statusOf(o);
      if (s == 'En attente') pending++;
      if (s == 'Publiée') published++;
      if (s == 'Refusée') refused++;
      if (s == 'Expirée') expired++;
    }
    return {
      'Toutes': _all.length,
      'En attente': pending,
      'Publiées': published,
      'Refusées': refused,
      'Expirées': expired,
    };
  }

  int get _totalPages {
    final c = _filtered.length;
    if (c == 0) return 1;
    return (c / _perPage).ceil();
  }

  List<Map<String, dynamic>> get _paged {
    final list = _filtered;
    final start = (_currentPage - 1) * _perPage;
    if (start >= list.length) return const [];
    final end = (start + _perPage).clamp(0, list.length);
    return list.sublist(start, end);
  }

  List<String> _cities() {
    final set = <String>{};
    for (final o in _all) {
      final v = (o['localisation']?.toString() ?? '').trim();
      if (v.isNotEmpty) set.add(v);
    }
    final l = set.toList()..sort();
    return l;
  }

  List<String> _sectors() {
    final set = <String>{};
    for (final o in _all) {
      final v = (o['domaine']?.toString() ?? '').trim();
      if (v.isNotEmpty) set.add(v);
    }
    final l = set.toList()..sort();
    return l;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ResponsiveContainer(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: const AdminListScreenShimmer(showHeaderAction: false),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            FilledButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    final tabs = _tabCounts;
    final list = _paged;
    final totalFiltered = _filtered.length;
    final from = totalFiltered == 0 ? 0 : ((_currentPage - 1) * _perPage) + 1;
    final to = ((_currentPage - 1) * _perPage + list.length).clamp(0, totalFiltered);

    return ResponsiveContainer(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Gestion des Offres d\'emploi',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_all.length} offre(s) au total · $totalFiltered après filtres',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Validation, modification et modération des offres',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Rechercher une offre ou une entreprise...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() {
                      _query = v;
                      _currentPage = 1;
                    }),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _JobsFilter(
                        label: 'Statut',
                        value: _statusFilter,
                        items: const {
                          'tous': 'Tous',
                          'Publiée': 'Publiée',
                          'En attente': 'En attente',
                          'Refusée': 'Refusée',
                          'Expirée': 'Expirée',
                          'En vedette': 'En vedette',
                        },
                        onChanged: (v) => setState(() {
                          _statusFilter = v;
                          _currentPage = 1;
                        }),
                      ),
                      _JobsFilter(
                        label: 'Ville',
                        value: _cityFilter,
                        items: {
                          'toutes': 'Toutes',
                          ...{for (final city in _cities()) city.toLowerCase(): city},
                        },
                        onChanged: (v) => setState(() {
                          _cityFilter = v;
                          _currentPage = 1;
                        }),
                      ),
                      _JobsFilter(
                        label: 'Secteur',
                        value: _sectorFilter,
                        items: {
                          'tous': 'Tous',
                          ...{for (final s in _sectors()) s.toLowerCase(): s},
                        },
                        onChanged: (v) => setState(() {
                          _sectorFilter = v;
                          _currentPage = 1;
                        }),
                      ),
                      OutlinedButton.icon(
                        onPressed: _exportingCsv ? null : _exportCsv,
                        icon: _exportingCsv
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.download_outlined, size: 16),
                        label: Text(_exportingCsv ? 'Export…' : 'Exporter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tab in const ['Toutes', 'En attente', 'Publiées', 'Refusées', 'Expirées'])
                        ChoiceChip(
                          label: Text('$tab (${tabs[tab] ?? 0})'),
                          selected: _activeTab == tab,
                          onSelected: (_) => setState(() {
                            _activeTab = tab;
                            _currentPage = 1;
                          }),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: RefreshIndicator(
                    onRefresh: _load,
                    color: const Color(0xFF1A56DB),
                    child: list.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            children: [
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEFF6FF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.work_outline_rounded,
                                        color: Color(0xFF1A56DB),
                                        size: 40,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Aucune offre',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Aucune offre ne correspond aux filtres.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: 2 + list.length,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return const _OffresListHeaderRow();
                              }
                              if (index == list.length + 1) {
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                                  child: Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      Text(
                                        'Affichage $from-$to sur $totalFiltered offres',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            onPressed: _currentPage > 1
                                                ? () => setState(() => _currentPage--)
                                                : null,
                                            icon: const Icon(Icons.chevron_left),
                                          ),
                                          Text('Page $_currentPage / $_totalPages'),
                                          IconButton(
                                            onPressed: _currentPage < _totalPages
                                                ? () => setState(() => _currentPage++)
                                                : null,
                                            icon: const Icon(Icons.chevron_right),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }
                              final o = list[index - 1];
                              return _OffreListRow(
                                offre: o,
                                striped: index.isEven,
                                entrepriseNom: _entrepriseNom(o),
                                onAfterAction: () async {
                                  await _load();
                                  _syncAdminBadges();
                                },
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour exporter.')),
      );
      return;
    }
    const fileName = 'offres_emploiconnect.csv';
    setState(() => _exportingCsv = true);
    try {
      await DownloadService.downloadCsvFromApi(
        apiPathAndQuery: '/admin/offres/export/csv',
        token: token,
        fileName: fileName,
        context: context,
      );
      if (!mounted) return;
      DownloadService.showWebDownloadSnackBar(context, fileName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _exportingCsv = false);
    }
  }
}

class _OffresListHeaderRow extends StatelessWidget {
  const _OffresListHeaderRow();

  TextStyle _h() => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF64748B),
        letterSpacing: 0.4,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 4, child: Text('OFFRE', style: _h())),
          Expanded(flex: 2, child: Text('SECTEUR', style: _h())),
          Expanded(flex: 2, child: Text('VILLE', style: _h())),
          Expanded(flex: 2, child: Text('TYPE', style: _h())),
          Expanded(flex: 2, child: Text('STATUT', style: _h())),
          Expanded(flex: 1, child: Text('CAND.', style: _h())),
          Expanded(flex: 2, child: Text('DATE', style: _h())),
          SizedBox(width: 56, child: Center(child: Text('ACT.', style: _h()))),
        ],
      ),
    );
  }
}

class _OffreListRow extends StatelessWidget {
  const _OffreListRow({
    required this.offre,
    required this.striped,
    required this.entrepriseNom,
    required this.onAfterAction,
  });

  final Map<String, dynamic> offre;
  final bool striped;
  final String entrepriseNom;
  final Future<void> Function() onAfterAction;

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final title = offre['titre']?.toString() ?? '-';
    final company = entrepriseNom.trim();
    final secteur = (offre['domaine']?.toString() ?? '-').trim();
    final ville = (offre['localisation']?.toString() ?? '-').trim();
    final type = (offre['type_contrat']?.toString() ?? '-').trim();
    final candidates =
        (offre['nb_candidatures'] ?? offre['nombre_candidatures'] ?? offre['candidatures_count'] ?? 0)
            .toString();
    final date = _fmtDate(offre['date_publication']?.toString() ?? offre['date_creation']?.toString());
    final bodyStyle = GoogleFonts.inter(fontSize: 12, color: const Color(0xFF374151));
    final muted = GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B));

    return ColoredBox(
      color: striped ? const Color(0xFFFAFAFA) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      company.isEmpty ? 'Entreprise inconnue' : company,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(secteur.isEmpty ? '-' : secteur, maxLines: 1, overflow: TextOverflow.ellipsis, style: bodyStyle),
              ),
              Expanded(
                flex: 2,
                child: Text(ville.isEmpty ? '-' : ville, maxLines: 1, overflow: TextOverflow.ellipsis, style: bodyStyle),
              ),
              Expanded(
                flex: 2,
                child: Text(type.isEmpty ? '-' : type, maxLines: 1, overflow: TextOverflow.ellipsis, style: bodyStyle),
              ),
              Expanded(
                flex: 2,
                child: StatusBadge(label: (offre['statut'] ?? '').toString()),
              ),
              Expanded(flex: 1, child: Text(candidates, style: bodyStyle)),
              Expanded(flex: 2, child: Text(date, style: bodyStyle)),
              SizedBox(
                width: 56,
                child: Center(
                  child: OffreActionsMenu(
                    offre: offre,
                    onRefresh: onAfterAction,
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _JobsFilter extends StatelessWidget {
  const _JobsFilter({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
        onChanged: (v) => onChanged(v ?? value),
      ),
    );
  }
}

