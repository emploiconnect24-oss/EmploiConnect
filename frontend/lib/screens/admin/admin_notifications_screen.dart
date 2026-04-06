import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import '../../shared/widgets/logo_widget.dart';
import '../../widgets/responsive_container.dart';
import 'widgets/admin_page_shimmer.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _admin = AdminService();
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _destinataireIdCtrl = TextEditingController();

  String _target = 'all';
  bool _scheduleLater = false;
  DateTime? _scheduledAt;
  String _template = 'Aucun template';
  bool _loadingHistory = true;
  bool _sending = false;
  String? _historyError;
  List<Map<String, dynamic>> _historyRows = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _onPullRefresh() async {
    await _loadHistory();
    if (mounted) await context.read<AdminProvider>().loadDashboard();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loadingHistory = true;
      _historyError = null;
    });
    try {
      final res = await _admin.getNotificationsAdmin(page: 1, limite: 50);
      final data = res['data'] as Map<String, dynamic>?;
      final raw = data?['notifications'] as List<dynamic>? ?? const [];
      setState(() {
        _historyRows = raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _loadingHistory = false;
      });
    } catch (e) {
      setState(() {
        _historyError = e.toString();
        _loadingHistory = false;
      });
    }
  }

  static const Map<String, String> _templates = {
    'Aucun template': '',
    'Nouvelle offre dans votre secteur':
        'Une nouvelle offre correspondant à votre profil vient d’être publiée.',
    'Votre CV a été consulté':
        'Bonne nouvelle ! Votre CV a récemment été consulté par un recruteur.',
    'Rappel de compléter votre profil':
        'Pensez à compléter votre profil pour améliorer votre visibilité.',
    'Maintenance planifiée':
        'Une maintenance est prévue ce soir entre 23h et 01h.',
  };

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    _destinataireIdCtrl.dispose();
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
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
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

  Future<void> _sendNow() async {
    if (_titleCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Titre et message requis')));
      return;
    }
    if (_target == 'one' && _destinataireIdCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID utilisateur requis pour un envoi individuel'),
        ),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final typeDest = switch (_target) {
        'candidates' => 'chercheurs',
        'recruiters' => 'entreprises',
        'one' => 'individuel',
        _ => 'tous',
      };
      await _admin.envoyerNotification(
        titre: _titleCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
        typeDestinataire: typeDest,
        destinataireId: _target == 'one'
            ? _destinataireIdCtrl.text.trim()
            : null,
        type: 'systeme',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notification envoyée')));
      await _loadHistory();
      if (mounted) await context.read<AdminProvider>().loadDashboard();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _schedule() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('La planification n’est pas encore disponible côté API.'),
      ),
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

  String _destinataireApiLabel(String? v) {
    switch (v) {
      case 'chercheurs':
        return 'Candidats';
      case 'entreprises':
        return 'Recruteurs';
      case 'individuel':
        return 'Individuel';
      case 'tous':
        return 'Tous';
      default:
        return v ?? '—';
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

  Widget _buildEnvoiHistoriqueTab(int messageLength) {
    return RefreshIndicator(
      color: const Color(0xFF1A56DB),
      onRefresh: _onPullRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Envoi & historique admin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Composer et suivre les envois plateforme',
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
                    Expanded(
                      flex: 60,
                      child: _buildComposerCard(messageLength),
                    ),
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

  @override
  Widget build(BuildContext context) {
    final messageLength = _messageCtrl.text.characters.length;
    return DefaultTabController(
      length: 2,
      child: ResponsiveContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Messages reçus et envois plateforme',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const TabBar(
              labelColor: Color(0xFF1A56DB),
              unselectedLabelColor: Color(0xFF64748B),
              indicatorColor: Color(0xFF1A56DB),
              tabs: [
                Tab(text: 'Mes notifications'),
                Tab(text: 'Envoi & historique'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _MesNotificationsRecuesPanel(
                    admin: _admin,
                    onBadgeRefresh: () =>
                        context.read<AdminProvider>().loadDashboard(),
                  ),
                  _buildEnvoiHistoriqueTab(messageLength),
                ],
              ),
            ),
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
          const Text(
            'Composer une notification',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
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
            TextField(
              controller: _destinataireIdCtrl,
              decoration: const InputDecoration(
                labelText: 'UUID utilisateur (destinataire)',
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
                onPressed: _sending
                    ? null
                    : (_scheduleLater ? _schedule : _sendNow),
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _scheduleLater
                            ? Icons.event_available
                            : Icons.send_rounded,
                      ),
                label: Text(
                  _scheduleLater ? 'Planifier' : 'Envoyer maintenant',
                ),
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
          const Text(
            'Aperçu notification',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
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
                const Row(children: [LogoWidget(height: 24)]),
                const SizedBox(height: 10),
                Text(
                  _titleCtrl.text.trim().isEmpty
                      ? 'Titre de la notification'
                      : _titleCtrl.text.trim(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  _messageCtrl.text.trim().isEmpty
                      ? 'Votre message apparaîtra ici.'
                      : _messageCtrl.text.trim(),
                  style: const TextStyle(color: Color(0xFF334155)),
                ),
                const SizedBox(height: 10),
                Text(
                  'Destinataires: ${_targetLabel(_target)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Historique des notifications',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Actualiser',
                onPressed: _loadingHistory ? null : _loadHistory,
                icon: _loadingHistory
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_historyError != null) ...[
            Text(
              _historyError!,
              style: const TextStyle(color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _loadingHistory ? null : _loadHistory,
              child: const Text('Réessayer'),
            ),
          ] else if (_loadingHistory && _historyRows.isEmpty)
            const AdminNotificationsHistoryShimmer()
          else if (_historyRows.isEmpty)
            const Text(
              'Aucune notification admin enregistrée.',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('TITRE')),
                  DataColumn(label: Text('DESTINATAIRES')),
                  DataColumn(label: Text('DATE')),
                  DataColumn(label: Text('STATUT')),
                ],
                rows: _historyRows.map((h) {
                  final iso = h['date_envoi_reel']?.toString();
                  final dt = iso != null ? DateTime.tryParse(iso) : null;
                  final dateStr = dt != null
                      ? DateFormat(
                          'dd/MM/yyyy HH:mm',
                          'fr_FR',
                        ).format(dt.toLocal())
                      : '—';
                  return DataRow(
                    cells: [
                      DataCell(Text(h['titre']?.toString() ?? '—')),
                      DataCell(
                        Text(
                          _destinataireApiLabel(
                            h['type_destinataire']?.toString(),
                          ),
                        ),
                      ),
                      DataCell(Text(dateStr)),
                      const DataCell(_StatusBadge(status: 'Envoyé')),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _MesNotificationsRecuesPanel extends StatefulWidget {
  const _MesNotificationsRecuesPanel({
    required this.admin,
    required this.onBadgeRefresh,
  });

  final AdminService admin;
  final VoidCallback onBadgeRefresh;

  @override
  State<_MesNotificationsRecuesPanel> createState() =>
      _MesNotificationsRecuesPanelState();
}

class _MesNotificationsRecuesPanelState
    extends State<_MesNotificationsRecuesPanel> {
  bool _loading = true;
  String? _error;
  String _filtre = 'toutes';
  List<Map<String, dynamic>> _rows = [];
  int _nbNonLues = 0;

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
      final res = await widget.admin.getMesNotifications(
        nonLuesSeulement: _filtre == 'non_lues',
        limite: 50,
      );
      final data = res['data'] as Map<String, dynamic>?;
      final raw = data?['notifications'] as List<dynamic>? ?? const [];
      setState(() {
        _rows = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _nbNonLues = (data?['nb_non_lues'] is int)
            ? data!['nb_non_lues'] as int
            : int.tryParse(data?['nb_non_lues']?.toString() ?? '') ?? 0;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    try {
      await widget.admin.marquerToutesNotificationsLues();
      if (!mounted) return;
      context.read<AdminProvider>().updateNbNotifications(0);
      widget.onBadgeRefresh();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _markOneRead(String id) async {
    try {
      await widget.admin.marquerNotificationLue(id);
      if (!mounted) return;
      widget.onBadgeRefresh();
      await _load();
    } catch (_) {
      /* ignore */
    }
  }

  Future<void> _deleteOne(String id) async {
    try {
      await widget.admin.supprimerNotification(id);
      if (!mounted) return;
      widget.onBadgeRefresh();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  String _formatRelative(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
      return 'Il y a ${diff.inDays} jour(s)';
    } catch (_) {
      return '';
    }
  }

  IconData _iconForType(String? t) {
    switch (t) {
      case 'candidature':
        return Icons.assignment_outlined;
      case 'offre':
        return Icons.work_outline;
      case 'message':
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF1A56DB),
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_nbNonLues > 0)
                          Text(
                            '$_nbNonLues non lue(s)',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1A56DB),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_nbNonLues > 0)
                    TextButton.icon(
                      onPressed: _markAllRead,
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('Tout marquer lu'),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Toutes'),
                    selected: _filtre == 'toutes',
                    onSelected: (_) {
                      setState(() => _filtre = 'toutes');
                      _load();
                    },
                  ),
                  ChoiceChip(
                    label: Text('Non lues ($_nbNonLues)'),
                    selected: _filtre == 'non_lues',
                    onSelected: (_) {
                      setState(() => _filtre = 'non_lues');
                      _load();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _load,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_rows.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none_outlined,
                        color: Color(0xFF1A56DB),
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucune notification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Text(
                      'Vous êtes à jour.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, i) {
                  final n = _rows[i];
                  final estLue = n['est_lue'] == true;
                  final id = n['id']?.toString() ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: estLue ? Colors.white : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: estLue
                                ? const Color(0xFFE2E8F0)
                                : const Color(
                                    0xFF1A56DB,
                                  ).withValues(alpha: 0.2),
                          ),
                        ),
                        leading: Icon(
                          _iconForType(n['type']?.toString()),
                          color: const Color(0xFF1A56DB),
                        ),
                        title: Text(
                          n['titre']?.toString() ?? '—',
                          style: TextStyle(
                            fontWeight: estLue
                                ? FontWeight.w400
                                : FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n['message']?.toString() ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              _formatRelative(n['date_creation']?.toString()),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'lire') _markOneRead(id);
                            if (v == 'suppr') _deleteOne(id);
                          },
                          itemBuilder: (_) => [
                            if (!estLue)
                              const PopupMenuItem(
                                value: 'lire',
                                child: Text('Marquer comme lue'),
                              ),
                            const PopupMenuItem(
                              value: 'suppr',
                              child: Text(
                                'Supprimer',
                                style: TextStyle(color: Color(0xFFEF4444)),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          if (!estLue) _markOneRead(id);
                        },
                      ),
                    ),
                  );
                }, childCount: _rows.length),
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
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
