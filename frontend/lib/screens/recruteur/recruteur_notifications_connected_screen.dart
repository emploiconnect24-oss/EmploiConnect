import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/recruteur_provider.dart';
import '../../services/recruteur_service.dart';

/// Notifications recruteur — filtres, cartes typées, actions rapides.
class RecruteurNotificationsConnectedScreen extends StatefulWidget {
  const RecruteurNotificationsConnectedScreen({super.key});

  @override
  State<RecruteurNotificationsConnectedScreen> createState() => _RecruteurNotificationsConnectedScreenState();
}

class _RecruteurNotificationsConnectedScreenState extends State<RecruteurNotificationsConnectedScreen> {
  static const _primary = Color(0xFF1A56DB);

  final _svc = RecruteurService();
  List<Map<String, dynamic>> _notifs = [];
  int _nbNonLues = 0;
  bool _loading = true;
  String? _filterLu;
  String _filterType = 'all';
  Map<String, dynamic> _meta = {};

  static const _types = <String, String>{
    'all': 'Toutes',
    'candidature': 'Candidatures',
    'message': 'Messages',
    'offre': 'Offres',
    'systeme': 'Système',
    'alerte_emploi': 'Alertes',
    'validation_compte': 'Compte',
    'autre': 'Autres',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await _svc.getNotifications(
        token,
        limite: 50,
        lu: _filterLu,
        type: _filterType == 'all' ? null : _filterType,
      );
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final count = _asInt(data['nb_non_lues']);
      if (!mounted) return;
      context.read<RecruteurProvider>().updateNbNotifications(count);
      setState(() {
        _notifs = List<Map<String, dynamic>>.from(data['notifications'] ?? const []);
        _nbNonLues = count;
        _meta = Map<String, dynamic>.from(data['meta'] as Map? ?? {});
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  ({IconData icon, Color bg, Color fg}) _styleForType(String? t) {
    switch (t) {
      case 'candidature':
        return (icon: Icons.assignment_ind_outlined, bg: const Color(0xFFEFF6FF), fg: const Color(0xFF1D4ED8));
      case 'message':
        return (icon: Icons.chat_bubble_outline_rounded, bg: const Color(0xFFF5F3FF), fg: const Color(0xFF7C3AED));
      case 'offre':
        return (icon: Icons.work_outline_rounded, bg: const Color(0xFFECFDF5), fg: const Color(0xFF059669));
      case 'alerte_emploi':
        return (icon: Icons.notifications_active_outlined, bg: const Color(0xFFFFFBEB), fg: const Color(0xFFD97706));
      case 'validation_compte':
        return (icon: Icons.verified_user_outlined, bg: const Color(0xFFE0F2FE), fg: const Color(0xFF0369A1));
      default:
        return (icon: Icons.info_outline_rounded, bg: const Color(0xFFF1F5F9), fg: const Color(0xFF64748B));
    }
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (now.difference(d).inMinutes < 1) return 'À l\'instant';
      if (now.difference(d).inHours < 24) return 'Il y a ${now.difference(d).inHours} h';
      if (now.difference(d).inDays < 7) return 'Il y a ${now.difference(d).inDays} j';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _markOne(Map<String, dynamic> n) async {
    if (n['est_lue'] == true) return;
    final token = context.read<AuthProvider>().token ?? '';
    await _svc.marquerNotifLue(token, n['id']?.toString() ?? '');
    await _load();
  }

  Future<void> _allRead() async {
    final token = context.read<AuthProvider>().token ?? '';
    await _svc.marquerToutesLues(token);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final parType = Map<String, dynamic>.from(_meta['par_type'] as Map? ?? {});

    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: RefreshIndicator(
        color: _primary,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notifications',
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _nbNonLues > 0 ? '$_nbNonLues non lue(s)' : 'Vous êtes à jour',
                                style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
                              ),
                            ],
                          ),
                        ),
                        if (_nbNonLues > 0)
                          TextButton(
                            onPressed: _allRead,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text('Tout lu', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _LuChip(
                            label: 'Toutes',
                            selected: _filterLu == null,
                            onTap: () {
                              setState(() => _filterLu = null);
                              _load();
                            },
                          ),
                          _LuChip(
                            label: 'Non lues',
                            selected: _filterLu == 'false',
                            onTap: () {
                              setState(() => _filterLu = 'false');
                              _load();
                            },
                          ),
                          _LuChip(
                            label: 'Lues',
                            selected: _filterLu == 'true',
                            onTap: () {
                              setState(() => _filterLu = 'true');
                              _load();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Par type',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF64748B)),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: _types.entries.map((e) {
                    final key = e.key;
                    final label = e.value;
                    final n = key == 'all' ? null : _asInt(parType[key]);
                    final sel = _filterType == key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          n != null && n > 0 ? '$label ($n)' : label,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        selected: sel,
                        onSelected: (_) {
                          setState(() => _filterType = key);
                          _load();
                        },
                        selectedColor: const Color(0xFFDBEAFE),
                        checkmarkColor: _primary,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: _primary)),
              )
            else if (_notifs.isEmpty)
              SliverFillRemaining(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune notification',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Les alertes candidatures, messages et offres s’affichent ici.',
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final n = _notifs[i];
                      final type = n['type']?.toString();
                      final st = _styleForType(type);
                      final lue = n['est_lue'] == true;
                      final titre = n['titre']?.toString() ?? 'Notification';
                      final msg = n['message']?.toString() ?? '';
                      final date = n['date_creation']?.toString() ?? n['date_envoi_reel']?.toString();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _markOne(n),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: lue ? const Color(0xFFE2E8F0) : const Color(0xFFBFDBFE),
                                  width: lue ? 1 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: st.bg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(st.icon, color: st.fg, size: 22),
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
                                                  titre,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 15,
                                                    fontWeight: lue ? FontWeight.w500 : FontWeight.w700,
                                                    color: const Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ),
                                              if (!lue)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF1A56DB),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            msg,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              height: 1.4,
                                              color: const Color(0xFF64748B),
                                            ),
                                            maxLines: 4,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Text(
                                                _fmtDate(date),
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: const Color(0xFF94A3B8),
                                                ),
                                              ),
                                              if (type != null && type.isNotEmpty) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF1F5F9),
                                                    borderRadius: BorderRadius.circular(100),
                                                  ),
                                                  child: Text(
                                                    _types[type] ?? type,
                                                    style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                                                  ),
                                                ),
                                              ],
                                              const Spacer(),
                                              if (!lue)
                                                TextButton(
                                                  onPressed: () => _markOne(n),
                                                  child: Text('Marquer lu', style: GoogleFonts.inter(fontSize: 12)),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _notifs.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LuChip extends StatelessWidget {
  const _LuChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? Colors.white : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(100),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: selected ? const Color(0xFF1A56DB) : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
