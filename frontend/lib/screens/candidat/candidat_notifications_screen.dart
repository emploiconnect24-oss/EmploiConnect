import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/candidat_provider.dart';
import '../../services/notifications_service.dart';
import 'candidat_temoignage_screen.dart';
import 'pages/parcours_ressource_detail_page.dart';

class CandidatNotificationsScreen extends StatefulWidget {
  const CandidatNotificationsScreen({super.key});

  @override
  State<CandidatNotificationsScreen> createState() =>
      _CandidatNotificationsScreenState();
}

class _CandidatNotificationsScreenState
    extends State<CandidatNotificationsScreen> {
  final _svc = NotificationsService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _actionNotification(String action, Map<String, dynamic> notif) async {
    final id = (notif['id'] ?? '').toString();
    if (id.isEmpty) return;
    try {
      switch (action) {
        case 'lire':
          await _svc.markRead(id);
          break;
        case 'non_lue':
          await _svc.markUnread(id);
          break;
        case 'supprimer':
          final confirme = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Text(
                'Supprimer cette notification ?',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'Supprimer',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
          if (confirme != true) return;
          await _svc.remove(id);
          break;
      }
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _svc.getMesNotifications(limite: 100);
      final data = (res['data'] as Map?)?.cast<String, dynamic>() ?? {};
      if (!mounted) return;
      setState(() {
        _items = List<Map<String, dynamic>>.from(
          data['notifications'] ?? const [],
        );
        _loading = false;
      });
      await context.read<CandidatProvider>().loadDashboardMetrics();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _marquerToutLu() async {
    try {
      await _svc.markAllRead();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final nbNonLues = _items.where((e) => e['est_lue'] != true).length;
    final bottomInset = MediaQuery.of(context).size.width <= 900 ? 80.0 : 24.0;

    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                color: Colors.white,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            '$nbNonLues non lue(s)',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (nbNonLues > 0)
                      TextButton.icon(
                        icon: const Icon(Icons.done_all_rounded, size: 16),
                        label: const Text('Tout lire'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1A56DB),
                          textStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: _marquerToutLu,
                      ),
                  ],
                ),
              ),
            ),
            if (_items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: _buildEmpty(),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Retrouvez ici les mises à jour sur vos candidatures, messages et alertes.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                        );
                      }
                      final item = _items[i - 1];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _NotifTile(
                          item: item,
                          onTap: () => _onTapNotif(item),
                          onAction: (action) => _actionNotification(action, item),
                        ),
                      );
                    },
                    childCount: _items.length + 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _onTapNotif(Map<String, dynamic> item) async {
    final lien = item['lien']?.toString() ?? '';
    if (lien.contains('parcours') && lien.contains('ressource=')) {
      final q = lien.contains('?') ? lien.substring(lien.indexOf('?') + 1) : '';
      final rid = Uri.splitQueryString(q)['ressource']?.trim();
      if (rid != null && rid.isNotEmpty && mounted) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ParcoursRessourceDetailPage(id: rid),
          ),
        );
      }
    }
    if (lien.contains('temoignage')) {
      final q = lien.indexOf('?');
      final cid = q >= 0
          ? Uri.splitQueryString(lien.substring(q + 1))['c']?.trim()
          : null;
      if (cid != null && cid.isNotEmpty && mounted) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) =>
                CandidatTemoignageScreen(initialCandidatureId: cid),
          ),
        );
      }
    }
    if (item['est_lue'] != true) {
      final id = (item['id'] ?? '').toString();
      if (id.isNotEmpty) {
        try {
          await _svc.markRead(id);
          if (!mounted) return;
          await _load();
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF1A56DB),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune notification',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous serez notifié des mises à jour\nde vos candidatures ici.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.item,
    required this.onTap,
    required this.onAction,
  });

  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final ValueChanged<String> onAction;

  static String _fmtDate(dynamic v) {
    final s = v?.toString();
    if (s == null || s.isEmpty) return '';
    final d = DateTime.tryParse(s)?.toLocal();
    if (d == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final lue = item['est_lue'] == true;
    final type = item['type']?.toString();
    final titre = (item['titre'] ?? '').toString();
    final corps = (item['message'] ?? '').toString();
    final couleur = _notifColor(type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: lue ? Colors.white : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: lue
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFF1A56DB).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _notifIcon(type),
                  color: couleur,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre.isNotEmpty ? titre : corps,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: lue ? FontWeight.w500 : FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: titre.isNotEmpty ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (titre.isNotEmpty && corps.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        corps,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _fmtDate(item['date_creation']),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: lue
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF1A56DB),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                offset: const Offset(0, 30),
                itemBuilder: (_) => [
                  if (!lue)
                    PopupMenuItem<String>(
                      value: 'lire',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.done_rounded,
                            size: 16,
                            color: Color(0xFF1A56DB),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Marquer comme lu',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (lue)
                    PopupMenuItem<String>(
                      value: 'non_lue',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.mark_email_unread_outlined,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Marquer comme non lu',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'supprimer',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Supprimer',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: onAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _notifColor(String? type) {
  switch (type) {
    case 'candidature':
    case 'statut':
      return const Color(0xFF1A56DB);
    case 'entretien':
      return const Color(0xFF8B5CF6);
    case 'acceptee':
      return const Color(0xFF10B981);
    case 'refusee':
      return const Color(0xFFEF4444);
    case 'message':
      return const Color(0xFF0EA5E9);
    default:
      return const Color(0xFFF59E0B);
  }
}

IconData _notifIcon(String? type) {
  switch (type) {
    case 'candidature':
    case 'statut':
      return Icons.assignment_outlined;
    case 'entretien':
      return Icons.event_available_rounded;
    case 'acceptee':
      return Icons.check_circle_outline_rounded;
    case 'refusee':
      return Icons.cancel_outlined;
    case 'message':
      return Icons.chat_bubble_outline_rounded;
    default:
      return Icons.notifications_outlined;
  }
}
