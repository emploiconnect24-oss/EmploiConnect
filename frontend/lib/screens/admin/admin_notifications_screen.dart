import 'package:flutter/material.dart';
import '../../widgets/responsive_container.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  String _target = 'all';
  bool _scheduleLater = false;
  DateTime? _scheduledAt;
  String _template = 'Aucun template';

  final List<Map<String, String>> _history = [
    {
      'title': 'Maintenance planifiée',
      'target': 'Tous',
      'date': '27/03/2026 10:30',
      'status': 'Envoyé',
    },
    {
      'title': 'Nouvelle offre dans votre secteur',
      'target': 'Candidats',
      'date': '26/03/2026 16:20',
      'status': 'Envoyé',
    },
    {
      'title': 'Rappel compléter profil',
      'target': 'Recruteurs',
      'date': '25/03/2026 09:15',
      'status': 'Échec',
    },
  ];

  static const Map<String, String> _templates = {
    'Aucun template': '',
    'Nouvelle offre dans votre secteur': 'Une nouvelle offre correspondant à votre profil vient d’être publiée.',
    'Votre CV a été consulté': 'Bonne nouvelle ! Votre CV a récemment été consulté par un recruteur.',
    'Rappel de compléter votre profil': 'Pensez à compléter votre profil pour améliorer votre visibilité.',
    'Maintenance planifiée': 'Une maintenance est prévue ce soir entre 23h et 01h.',
  };

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _applyTemplate(String value) {
    setState(() {
      _template = value;
      final text = _templates[value] ?? '';
      if (text.isNotEmpty && _messageCtrl.text.trim().isEmpty) {
        _messageCtrl.text = text;
      }
      if (_titleCtrl.text.trim().isEmpty && value != 'Aucun template') {
        _titleCtrl.text = value;
      }
    });
  }

  void _sendNow() {
    if (_titleCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Titre et message requis')),
      );
      return;
    }
    setState(() {
      _history.insert(0, {
        'title': _titleCtrl.text.trim(),
        'target': _targetLabel(_target),
        'date': _formatDateTime(DateTime.now()),
        'status': 'Envoyé',
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification envoyée')),
    );
  }

  void _schedule() {
    if (_scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez une date de planification')),
      );
      return;
    }
    if (_titleCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Titre et message requis')),
      );
      return;
    }
    setState(() {
      _history.insert(0, {
        'title': _titleCtrl.text.trim(),
        'target': _targetLabel(_target),
        'date': _formatDateTime(_scheduledAt!),
        'status': 'Planifié',
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification planifiée')),
    );
  }

  String _targetLabel(String v) {
    switch (v) {
      case 'candidates':
        return 'Candidats';
      case 'recruiters':
        return 'Recruteurs';
      case 'one':
        return 'Utilisateur spécifique';
      default:
        return 'Tous';
    }
  }

  String _formatDateTime(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    final messageLength = _messageCtrl.text.characters.length;
    return ResponsiveContainer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications & Messages',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Composer, planifier et suivre les notifications plateforme',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, c) {
                final stack = c.maxWidth < 1040;
                if (stack) {
                  return Column(
                    children: [
                      _buildComposerCard(messageLength),
                      const SizedBox(height: 12),
                      _buildPreviewCard(),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 60, child: _buildComposerCard(messageLength)),
                    const SizedBox(width: 12),
                    Expanded(flex: 40, child: _buildPreviewCard()),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _buildHistoryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildComposerCard(int messageLength) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Composer une notification', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _template,
            decoration: const InputDecoration(labelText: 'Template'),
            items: _templates.keys
                .map((k) => DropdownMenuItem<String>(value: k, child: Text(k)))
                .toList(),
            onChanged: (v) => _applyTemplate(v ?? 'Aucun template'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Titre'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _messageCtrl,
            maxLines: 5,
            maxLength: 500,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Message',
              helperText: '$messageLength / 500',
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('Tous')),
              ButtonSegment(value: 'candidates', label: Text('Candidats')),
              ButtonSegment(value: 'recruiters', label: Text('Recruteurs')),
              ButtonSegment(value: 'one', label: Text('Spécifique')),
            ],
            selected: {_target},
            onSelectionChanged: (v) => setState(() => _target = v.first),
          ),
          if (_target == 'one') ...[
            const SizedBox(height: 10),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Email ou ID utilisateur',
              ),
            ),
          ],
          const SizedBox(height: 10),
          SwitchListTile(
            value: _scheduleLater,
            onChanged: (v) => setState(() => _scheduleLater = v),
            contentPadding: EdgeInsets.zero,
            title: const Text('Planifier pour plus tard'),
          ),
          if (_scheduleLater) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickDateTime,
              icon: const Icon(Icons.schedule_outlined),
              label: Text(
                _scheduledAt == null
                    ? 'Choisir date et heure'
                    : 'Planifié: ${_formatDateTime(_scheduledAt!)}',
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _scheduleLater ? _schedule : _sendNow,
                icon: Icon(_scheduleLater ? Icons.event_available : Icons.send_rounded),
                label: Text(_scheduleLater ? 'Planifier' : 'Envoyer maintenant'),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _titleCtrl.clear();
                  _messageCtrl.clear();
                  _template = 'Aucun template';
                  _scheduleLater = false;
                  _scheduledAt = null;
                  _target = 'all';
                }),
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Réinitialiser'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Aperçu notification', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Color(0xFF1A56DB),
                      child: Icon(Icons.notifications_active, size: 14, color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Text('EmploiConnect', style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _titleCtrl.text.trim().isEmpty ? 'Titre de la notification' : _titleCtrl.text.trim(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  _messageCtrl.text.trim().isEmpty ? 'Votre message apparaîtra ici.' : _messageCtrl.text.trim(),
                  style: const TextStyle(color: Color(0xFF334155)),
                ),
                const SizedBox(height: 10),
                Text(
                  'Destinataires: ${_targetLabel(_target)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Historique des notifications', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('TITRE')),
                DataColumn(label: Text('DESTINATAIRES')),
                DataColumn(label: Text('DATE')),
                DataColumn(label: Text('STATUT')),
              ],
              rows: _history
                  .map(
                    (h) => DataRow(
                      cells: [
                        DataCell(Text(h['title'] ?? '-')),
                        DataCell(Text(h['target'] ?? '-')),
                        DataCell(Text(h['date'] ?? '-')),
                        DataCell(_StatusBadge(status: h['status'] ?? '-')),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFFE2E8F0);
    Color fg = const Color(0xFF475569);
    if (status == 'Envoyé') {
      bg = const Color(0xFFD1FAE5);
      fg = const Color(0xFF065F46);
    } else if (status == 'Échec') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFF991B1B);
    } else if (status == 'Planifié') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(status, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
