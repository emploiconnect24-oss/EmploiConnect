import 'package:flutter/material.dart';

import '../../services/candidatures_service.dart';
import '../../services/cv_service.dart';
import '../../widgets/responsive_container.dart';

class RecruteurCandidatureDetailScreen extends StatefulWidget {
  const RecruteurCandidatureDetailScreen({super.key, required this.candidatureId});
  final String candidatureId;

  @override
  State<RecruteurCandidatureDetailScreen> createState() => _RecruteurCandidatureDetailScreenState();
}

class _RecruteurCandidatureDetailScreenState extends State<RecruteurCandidatureDetailScreen> {
  final _service = CandidaturesService();
  final _cvService = CvService();
  final _notesCtrl = TextEditingController();
  final _visioCtrl = TextEditingController();

  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  String _status = 'recues';
  DateTime? _entretienDate;
  final List<String> _timeline = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _visioCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await _service.getCandidatureById(widget.candidatureId);
      setState(() {
        _data = d;
        _status = _normalizeStatus(d['statut']?.toString() ?? '');
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _normalizeStatus(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('accep')) return 'acceptes';
    if (s.contains('refus')) return 'refuses';
    if (s.contains('entretien')) return 'entretien';
    if (s.contains('cours') || s.contains('examen')) return 'en_examen';
    return 'recues';
  }

  String _label(String key) {
    switch (key) {
      case 'acceptes':
        return 'Accepté';
      case 'refuses':
        return 'Refusé';
      case 'entretien':
        return 'Entretien';
      case 'en_examen':
        return 'En examen';
      default:
        return 'Reçu';
    }
  }

  Future<void> _changeStatus(String backendStatus) async {
    try {
      await _service.updateStatut(widget.candidatureId, backendStatus);
      setState(() {
        _status = _normalizeStatus(backendStatus);
        _timeline.insert(0, 'Statut changé vers ${_label(_status)}');
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Statut mis à jour')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _pickInterviewDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 2)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d == null) return;
    if (!mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t == null) return;
    if (!mounted) return;
    final timeLabel = t.format(context);
    final dt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    setState(() {
      _entretienDate = dt;
      _timeline.insert(0, 'Entretien planifié le ${d.day}/${d.month}/${d.year} à $timeLabel');
    });
  }

  Future<void> _showCv() async {
    try {
      final url = await _cvService.getDownloadUrl(candidatureId: widget.candidatureId);
      if (!mounted) return;
      if (url == null || url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucun CV disponible')));
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Lien CV'),
          content: SelectableText(url),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 60) return const Color(0xFF1A56DB);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final d = _data ?? <String, dynamic>{};
    final fullName = (d['candidat_nom'] ?? d['nom'] ?? 'Candidat').toString();
    final offer = (d['offre_titre'] ?? d['titre_offre'] ?? 'Offre').toString();
    final email = (d['email'] ?? d['candidat_email'] ?? '-').toString();
    final phone = (d['telephone'] ?? d['candidat_telephone'] ?? '-').toString();
    final city = (d['ville'] ?? d['localisation'] ?? '-').toString();
    final dispo = (d['disponibilite'] ?? 'Non précisée').toString();
    final motivation = (d['lettre_motivation'] ?? 'Aucune lettre de motivation').toString();
    final score = (d['score_compatibilite'] as num?)?.toInt() ?? 0;
    final skills = ((d['competences'] as List?) ?? const ['Flutter', 'Communication'])
        .map((e) => e.toString())
        .toList();
    final exp = ((d['experiences'] as List?) ?? const ['2022-2025: Développeur Mobile', '2020-2022: Stagiaire Tech'])
        .map((e) => e.toString())
        .toList();
    final studies = ((d['formations'] as List?) ?? const ['Licence Informatique', 'Baccalauréat'])
        .map((e) => e.toString())
        .toList();

    return ResponsiveContainer(
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 20),
        children: [
          Row(
            children: [
              IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    Text('Candidature sur "$offer"'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              final twoCols = c.maxWidth >= 1100;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: const Color(0xFFDBEAFE),
                                      child: Text(
                                        fullName.trim().isEmpty ? '?' : fullName.trim()[0].toUpperCase(),
                                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E40AF)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                                          Text(offer),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _scoreColor(score).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text('$score% IA', style: TextStyle(color: _scoreColor(score), fontWeight: FontWeight.w800)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    Text('Email: $email'),
                                    Text('Téléphone: $phone'),
                                    Text('Ville: $city'),
                                    Text('Disponibilité: $dispo'),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text('Compétences détectées', style: TextStyle(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: skills.map((s) => Chip(label: Text(s))).toList(),
                                ),
                                const SizedBox(height: 12),
                                const Text('Expérience professionnelle', style: TextStyle(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 6),
                                ...exp.map((e) => ListTile(leading: const Icon(Icons.work_outline), title: Text(e), dense: true)),
                                const SizedBox(height: 8),
                                const Text('Formation', style: TextStyle(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 6),
                                ...studies.map((s) => ListTile(leading: const Icon(Icons.school_outlined), title: Text(s), dense: true)),
                                const SizedBox(height: 8),
                                ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  title: const Text('Lettre de motivation', style: TextStyle(fontWeight: FontWeight.w800)),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Text(motivation),
                                    ),
                                  ],
                                ),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    FilledButton.icon(
                                      onPressed: _showCv,
                                      icon: const Icon(Icons.description_outlined),
                                      label: const Text('Télécharger le CV'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.person_outline),
                                      label: const Text('Voir profil complet'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (twoCols) const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Statut & actions', style: TextStyle(fontWeight: FontWeight.w900)),
                                const SizedBox(height: 10),
                                _DetailStatusBadge(label: _label(_status), status: _status),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: _status,
                                  decoration: const InputDecoration(labelText: 'Changer le statut', isDense: true),
                                  items: const [
                                    DropdownMenuItem(value: 'recues', child: Text('Reçu')),
                                    DropdownMenuItem(value: 'en_examen', child: Text('En examen')),
                                    DropdownMenuItem(value: 'entretien', child: Text('Entretien')),
                                    DropdownMenuItem(value: 'acceptes', child: Text('Accepté')),
                                    DropdownMenuItem(value: 'refuses', child: Text('Refusé')),
                                  ],
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() => _status = v);
                                  },
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _notesCtrl,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    labelText: 'Notes internes',
                                    alignLabelWithHint: true,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _visioCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Lien visio (optionnel)',
                                    isDense: true,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: _pickInterviewDate,
                                  icon: const Icon(Icons.event_outlined),
                                  label: Text(_entretienDate == null
                                      ? 'Planifier entretien'
                                      : 'Entretien: ${_entretienDate!.day}/${_entretienDate!.month}/${_entretienDate!.year}'),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    FilledButton(
                                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                                      onPressed: () => _changeStatus('acceptee'),
                                      child: const Text('Accepter'),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                                      onPressed: () => _changeStatus('refusee'),
                                      child: const Text('Refuser'),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
                                      onPressed: () => _changeStatus('entretien'),
                                      child: const Text('Planifier entretien'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Raccourci messagerie à brancher section 14')),
                                    );
                                  },
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  label: const Text('Envoyer un message'),
                                ),
                                const Divider(height: 24),
                                const Text('Historique', style: TextStyle(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 8),
                                if (_timeline.isEmpty)
                                  const Text('Aucune action pour le moment.')
                                else
                                  ..._timeline.map((e) => ListTile(leading: const Icon(Icons.history), title: Text(e), dense: true)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DetailStatusBadge extends StatelessWidget {
  const _DetailStatusBadge({required this.label, required this.status});
  final String label;
  final String status;

  Color _bg() {
    switch (status) {
      case 'acceptes':
        return const Color(0xFFD1FAE5);
      case 'refuses':
        return const Color(0xFFFEE2E2);
      case 'entretien':
        return const Color(0xFFEDE9FE);
      case 'en_examen':
        return const Color(0xFFDBEAFE);
      default:
        return const Color(0xFFFFEDD5);
    }
  }

  Color _fg() {
    switch (status) {
      case 'acceptes':
        return const Color(0xFF047857);
      case 'refuses':
        return const Color(0xFFB91C1C);
      case 'entretien':
        return const Color(0xFF6D28D9);
      case 'en_examen':
        return const Color(0xFF1D4ED8);
      default:
        return const Color(0xFFB45309);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: _bg(), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: _fg(), fontWeight: FontWeight.w700)),
    );
  }
}
