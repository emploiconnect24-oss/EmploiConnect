import 'package:flutter/material.dart';

import '../../widgets/responsive_container.dart';

class RecruteurNotificationsScreen extends StatefulWidget {
  const RecruteurNotificationsScreen({super.key});

  @override
  State<RecruteurNotificationsScreen> createState() => _RecruteurNotificationsScreenState();
}

class _RecruteurNotificationsScreenState extends State<RecruteurNotificationsScreen> {
  String _filter = 'tous';

  final List<_NotifItem> _items = [
    _NotifItem(
      type: 'candidatures',
      title: 'Nouvelle candidature',
      message: 'Mamadou Barry a postulé à "Développeur Flutter".',
      time: 'il y a 5 min',
      group: 'AUJOURD\'HUI',
      unread: true,
      route: '/dashboard-recruteur/candidatures',
    ),
    _NotifItem(
      type: 'messages',
      title: 'Message reçu',
      message: 'Aissatou Diallo vous a envoyé un message.',
      time: 'il y a 23 min',
      group: 'AUJOURD\'HUI',
      unread: true,
      route: '/dashboard-recruteur/messages',
    ),
    _NotifItem(
      type: 'offres',
      title: 'Offre bientôt expirée',
      message: '"Chef de projet" expire dans 3 jours.',
      time: 'il y a 1 h',
      group: 'AUJOURD\'HUI',
      unread: false,
      route: '/dashboard-recruteur/offres',
    ),
    _NotifItem(
      type: 'candidatures',
      title: 'Nouvelle candidature',
      message: 'Sekou Kouyaté a postulé à "Data Analyst".',
      time: 'hier 14:32',
      group: 'HIER',
      unread: false,
      route: '/dashboard-recruteur/candidatures',
    ),
    _NotifItem(
      type: 'systeme',
      title: 'Offre validée',
      message: 'Votre offre "Data Analyst" a été validée par l\'admin.',
      time: 'hier 09:15',
      group: 'HIER',
      unread: false,
      route: '/dashboard-recruteur/offres',
    ),
    _NotifItem(
      type: 'messages',
      title: 'Message reçu',
      message: 'Ibrahima Bah vous répond sur la disponibilité.',
      time: 'lundi 18:24',
      group: 'CETTE SEMAINE',
      unread: false,
      route: '/dashboard-recruteur/messages',
    ),
  ];

  List<_NotifItem> get _filtered {
    if (_filter == 'tous') return _items;
    return _items.where((e) => e.type == _filter).toList();
  }

  void _markAllRead() {
    setState(() {
      for (final n in _items) {
        n.unread = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Toutes les notifications sont lues')));
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<_NotifItem>>{};
    for (final n in _filtered) {
      groups.putIfAbsent(n.group, () => []).add(n);
    }

    return ResponsiveContainer(
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 20),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notifications', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    SizedBox(height: 4),
                    Text('Suivez les activités importantes de votre espace recruteur.'),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _markAllRead,
                icon: const Icon(Icons.done_all),
                label: const Text('Marquer tout comme lu'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _filterChip('tous', 'Tous'),
                  _filterChip('candidatures', 'Candidatures'),
                  _filterChip('messages', 'Messages'),
                  _filterChip('offres', 'Offres'),
                  _filterChip('systeme', 'Système'),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ouvrir préférences via Paramètres (section 17)')),
                    ),
                    icon: const Icon(Icons.tune),
                    label: const Text('Préférences'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_filtered.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Aucune notification pour ce filtre.')),
              ),
            )
          else
            ...groups.entries.map((entry) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      ...entry.value.map(_tile),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == key,
      onSelected: (_) => setState(() => _filter = key),
    );
  }

  Widget _tile(_NotifItem n) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: _bg(n.type),
        child: Icon(_icon(n.type), color: _fg(n.type), size: 18),
      ),
      title: Row(
        children: [
          Expanded(child: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700))),
          if (n.unread)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text('●', style: TextStyle(color: Color(0xFF1D4ED8))),
            ),
        ],
      ),
      subtitle: Text('${n.message}\n${n.time}', style: const TextStyle(height: 1.35)),
      isThreeLine: true,
      onTap: () {
        setState(() => n.unread = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navigation vers ${n.route} (branchée dans le shell)')),
        );
      },
    );
  }

  IconData _icon(String type) {
    switch (type) {
      case 'candidatures':
        return Icons.person_add_alt_1;
      case 'messages':
        return Icons.chat_bubble_outline;
      case 'offres':
        return Icons.work_outline;
      default:
        return Icons.notifications_none;
    }
  }

  Color _bg(String type) {
    switch (type) {
      case 'candidatures':
        return const Color(0xFFD1FAE5);
      case 'messages':
        return const Color(0xFFDBEAFE);
      case 'offres':
        return const Color(0xFFFEF3C7);
      default:
        return const Color(0xFFE2E8F0);
    }
  }

  Color _fg(String type) {
    switch (type) {
      case 'candidatures':
        return const Color(0xFF047857);
      case 'messages':
        return const Color(0xFF1D4ED8);
      case 'offres':
        return const Color(0xFF92400E);
      default:
        return const Color(0xFF475569);
    }
  }
}

class _NotifItem {
  _NotifItem({
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    required this.group,
    required this.unread,
    required this.route,
  });

  final String type;
  final String title;
  final String message;
  final String time;
  final String group;
  bool unread;
  final String route;
}
