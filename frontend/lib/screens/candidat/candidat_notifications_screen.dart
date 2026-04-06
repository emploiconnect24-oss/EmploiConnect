import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/candidat_provider.dart';
import '../../services/notifications_service.dart';
import 'candidat_temoignage_screen.dart';

class CandidatNotificationsScreen extends StatefulWidget {
  const CandidatNotificationsScreen({super.key});

  @override
  State<CandidatNotificationsScreen> createState() => _CandidatNotificationsScreenState();
}

class _CandidatNotificationsScreenState extends State<CandidatNotificationsScreen> {
  final _svc = NotificationsService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

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
      final res = await _svc.getMesNotifications(limite: 100);
      final data = (res['data'] as Map?)?.cast<String, dynamic>() ?? {};
      if (!mounted) return;
      setState(() {
        _items = List<Map<String, dynamic>>.from(data['notifications'] ?? const []);
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final unread = _items.where((e) => e['est_lue'] != true).length;
    final pagePad = EdgeInsets.fromLTRB(
      20,
      16,
      20,
      MediaQuery.of(context).size.width <= 900 ? 80 : 24,
    );
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: pagePad,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
        Row(
          children: [
            const Text('Notifications', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(width: 10),
            if (unread > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                child: Text('$unread non lues', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            const Spacer(),
            OutlinedButton(
              onPressed: () async {
                await _svc.markAllRead();
                await _load();
              },
              child: const Text('Tout marquer comme lu'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Paramètres de notification à connecter (section 18).')),
                );
              },
              icon: const Icon(Icons.settings_outlined, size: 16),
              label: const Text('Paramètres'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Retrouvez ici les mises à jour sur vos candidatures, messages, alertes et recommandations.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 14),
        _group('AUJOURD\'HUI'),
        const SizedBox(height: 12),
        _group('HIER'),
        const SizedBox(height: 12),
        _group('CETTE SEMAINE'),
      ],
      ),
    );
  }

  Widget _group(String key) {
    final list = _items.where((n) => _groupOf(n['date_creation']?.toString()) == key).toList();
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          key,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        ...list.map(_tile),
      ],
    );
  }

  Widget _tile(Map<String, dynamic> item) {
    final theme = _theme(item['type']?.toString());
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: () async {
          final lien = item['lien']?.toString() ?? '';
          if (lien.contains('temoignage')) {
            final q = lien.indexOf('?');
            final cid = q >= 0
                ? Uri.splitQueryString(lien.substring(q + 1))['c']?.trim()
                : null;
            if (cid != null && cid.isNotEmpty && mounted) {
              await Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => CandidatTemoignageScreen(initialCandidatureId: cid),
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
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            }
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(theme.icon, size: 18, color: theme.fg),
        ),
        title: Text(
          item['message']?.toString() ?? item['titre']?.toString() ?? '',
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFF0F172A),
            fontWeight: item['est_lue'] == true ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Text(_timeAgo(item['date_creation']?.toString()), style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'read') {
              await _svc.markRead((item['id'] ?? '').toString());
              await _load();
            } else if (value == 'remove') {
              await _svc.remove((item['id'] ?? '').toString());
              await _load();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'read', child: Text('Marquer comme lu')),
            PopupMenuItem(value: 'remove', child: Text('Supprimer')),
          ],
        ),
      ),
    );
  }

  String _groupOf(String? iso) {
    if (iso == null || iso.isEmpty) return 'CETTE SEMAINE';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return 'CETTE SEMAINE';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'AUJOURD\'HUI';
    if (diff == 1) return 'HIER';
    return 'CETTE SEMAINE';
  }

  String _timeAgo(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'à l’instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    return 'il y a ${diff.inDays} j';
  }

  _NotifTheme _theme(String? type) {
    switch (type) {
      case 'message':
        return const _NotifTheme(
          icon: Icons.chat_bubble_outline,
          bg: Color(0xFFEFF6FF),
          fg: Color(0xFF1D4ED8),
        );
      case 'alerte':
      case 'alerte_emploi':
      case 'offre':
        return const _NotifTheme(
          icon: Icons.notifications_active_outlined,
          bg: Color(0xFFDBEAFE),
          fg: Color(0xFF1E40AF),
        );
      case 'candidature':
      case 'statut':
        return const _NotifTheme(
          icon: Icons.check_circle_outline,
          bg: Color(0xFFD1FAE5),
          fg: Color(0xFF047857),
        );
      default:
        return const _NotifTheme(
          icon: Icons.notifications_outlined,
          bg: Color(0xFFE2E8F0),
          fg: Color(0xFF334155),
        );
    }
  }

}

class _NotifTheme {
  const _NotifTheme({
    required this.icon,
    required this.bg,
    required this.fg,
  });

  final IconData icon;
  final Color bg;
  final Color fg;
}
