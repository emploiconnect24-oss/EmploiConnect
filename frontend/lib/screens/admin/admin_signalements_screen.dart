import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import '../../widgets/responsive_container.dart';
import 'admin_candidature_detail_screen.dart';
import 'admin_offre_detail_screen.dart';
import 'pages/user_detail_page.dart';
import 'widgets/admin_page_shimmer.dart';

class AdminSignalementsScreen extends StatefulWidget {
  const AdminSignalementsScreen({super.key});

  @override
  State<AdminSignalementsScreen> createState() => _AdminSignalementsScreenState();
}

class _AdminSignalementsScreenState extends State<AdminSignalementsScreen> {
  final _admin = AdminService();
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;
  String _selectedType = 'Tous';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _syncAdminBadges() {
    if (!mounted) return;
    context.read<AdminProvider>().loadDashboard();
  }

  bool _canVoirRessource(Map<String, dynamic> s) {
    final id = (s['objet_id']?.toString() ?? '').trim();
    if (id.isEmpty) return false;
    final t = (s['type_objet']?.toString() ?? '').toLowerCase().trim();
    return t == 'offre' || t == 'profil' || t == 'utilisateur' || t == 'candidature';
  }

  void _ouvrirRessourceSignalee(Map<String, dynamic> s) {
    if (!mounted) return;
    final objetId = (s['objet_id']?.toString() ?? '').trim();
    if (objetId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identifiant de la ressource manquant.')),
      );
      return;
    }
    final t = (s['type_objet']?.toString() ?? '').toLowerCase().trim();
    switch (t) {
      case 'offre':
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => AdminOffreDetailScreen(offreId: objetId)),
        );
        return;
      case 'profil':
      case 'utilisateur':
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => UserDetailPage(userId: objetId)),
        );
        return;
      case 'candidature':
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => AdminCandidatureDetailScreen(candidatureId: objetId)),
        );
        return;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Type de ressource non pris en charge : ${t.isEmpty ? '?' : t}')),
        );
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _admin.getSignalements(limit: 100);
      setState(() {
        _list = r.signalements;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _cloturerSignalement(
    String id,
    String statut, {
    required String dialogTitle,
    required String successMessage,
  }) async {
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(dialogTitle),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    statut == 'traite'
                        ? 'Le dossier sera marqué comme traité. Vous pouvez expliquer la suite donnée aux parties (recommandé).'
                        : 'Le signalement sera classé sans suite. Vous pouvez préciser le motif pour le signalant et la personne concernée (recommandé).',
                    style: const TextStyle(fontSize: 13, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 5,
                    maxLength: 4000,
                    decoration: const InputDecoration(
                      labelText: 'Message de la modération',
                      hintText:
                          'Ex. : Après vérification, l’offre a été retirée. / Votre signalement ne constitue pas une infraction aux règles…',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Valider et notifier'),
            ),
          ],
        );
      },
    );

    final note = ok == true ? noteCtrl.text.trim() : '';
    noteCtrl.dispose();

    if (ok != true || !mounted) return;

    try {
      await _admin.traiterSignalement(
        id,
        statut,
        noteAdmin: note.isEmpty ? null : note,
      );
      await _load();
      _syncAdminBadges();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ResponsiveContainer(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: const AdminModerationShimmer(),
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

    final filtered = _filtered;
    final urgentCount = filtered.where((e) => _priorityOf(e) == _ReportPriority.urgent).length;
    final inProgressCount = filtered.where((e) => _priorityOf(e) == _ReportPriority.medium).length;
    final resolvedCount = filtered.where((e) => _priorityOf(e) == _ReportPriority.low).length;

    return ResponsiveContainer(
      child: RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFF1A56DB),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modération & Signalements',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '$urgentCount signalements urgents en attente de traitement',
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ModerationCounterCard(
                    title: 'Urgents',
                    count: urgentCount,
                    color: const Color(0xFFEF4444),
                    bgColor: const Color(0xFFFEE2E2),
                    icon: Icons.priority_high_rounded,
                  ),
                  _ModerationCounterCard(
                    title: 'En cours',
                    count: inProgressCount,
                    color: const Color(0xFFF59E0B),
                    bgColor: const Color(0xFFFEF3C7),
                    icon: Icons.timelapse_rounded,
                  ),
                  _ModerationCounterCard(
                    title: 'Résolus',
                    count: resolvedCount,
                    color: const Color(0xFF10B981),
                    bgColor: const Color(0xFFD1FAE5),
                    icon: Icons.verified_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in _allTypes)
                    ChoiceChip(
                      label: Text(type),
                      selected: _selectedType == type,
                      onSelected: (_) => setState(() => _selectedType = type),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(child: Text('Aucun signalement pour ce filtre.')),
                )
              else
                ...filtered.map(_buildReportCard),
            ],
          ),
        ),
      ),
    );
  }

  List<String> get _allTypes {
    final values = <String>{'Tous'};
    for (final s in _list) {
      values.add(_typeLabel(s));
    }
    final list = values.toList();
    list.sort();
    if (list.remove('Tous')) {
      list.insert(0, 'Tous');
    }
    return list;
  }

  List<Map<String, dynamic>> get _filtered {
    if (_selectedType == 'Tous') return _list;
    return _list.where((s) => _typeLabel(s) == _selectedType).toList();
  }

  String _typeLabel(Map<String, dynamic> s) {
    final objet = (s['type_objet']?.toString() ?? '').toLowerCase().trim();
    if (objet == 'offre') return 'Offre';
    if (objet == 'profil' || objet == 'utilisateur') return 'Profil';
    if (objet == 'candidature') return 'Candidature';
    final raison = (s['raison']?.toString() ?? '').toLowerCase();
    if (raison.contains('offre')) return 'Offre (motif texte)';
    if (raison.contains('contenu')) return 'Contenu inapproprié';
    if (raison.contains('compte')) return 'Compte suspect';
    if (raison.contains('spam')) return 'Spam';
    return 'Autre';
  }

  String? _objetContextLine(Map<String, dynamic> s) {
    final d = s['objet_details'];
    if (d is! Map) return null;
    final type = (s['type_objet']?.toString() ?? '').toLowerCase().trim();
    if (type == 'offre') {
      final titre = (d['titre'] ?? '').toString().trim();
      dynamic ent = d['entreprises'];
      if (ent is List && ent.isNotEmpty) ent = ent.first;
      final nom = ent is Map ? (ent['nom_entreprise'] ?? '').toString().trim() : '';
      final parts = <String>[if (titre.isNotEmpty) titre, if (nom.isNotEmpty) nom];
      return parts.isEmpty ? null : parts.join(' · ');
    }
    if (type == 'profil' || type == 'utilisateur') {
      final nom = (d['nom'] ?? '').toString().trim();
      final email = (d['email'] ?? '').toString().trim();
      final parts = <String>[if (nom.isNotEmpty) nom, if (email.isNotEmpty) email];
      return parts.isEmpty ? null : parts.join(' · ');
    }
    if (type == 'candidature') {
      dynamic off = d['offres_emploi'];
      if (off is List && off.isNotEmpty) off = off.first;
      final titre = off is Map ? (off['titre'] ?? '').toString().trim() : '';
      dynamic ch = d['chercheurs_emploi'];
      if (ch is List && ch.isNotEmpty) ch = ch.first;
      String cand = '';
      if (ch is Map) {
        dynamic u = ch['utilisateurs'];
        if (u is List && u.isNotEmpty) u = u.first;
        if (u is Map) cand = (u['nom'] ?? '').toString().trim();
      }
      final statut = (d['statut'] ?? '').toString().trim();
      final parts = <String>[
        if (titre.isNotEmpty) titre,
        if (cand.isNotEmpty) 'Candidat : $cand',
        if (statut.isNotEmpty) statut,
      ];
      return parts.isEmpty ? null : parts.join(' · ');
    }
    return null;
  }

  _ReportPriority _priorityOf(Map<String, dynamic> s) {
    final statut = (s['statut']?.toString() ?? '').toLowerCase();
    final count = int.tryParse((s['nombre_signalements'] ?? s['report_count'] ?? 1).toString()) ?? 1;
    if (statut == 'traite' || statut == 'rejete') return _ReportPriority.low;
    if (count >= 3) return _ReportPriority.urgent;
    return _ReportPriority.medium;
  }

  Widget _buildReportCard(Map<String, dynamic> s) {
    final id = s['id']?.toString() ?? '';
    final priority = _priorityOf(s);
    final type = _typeLabel(s);
    final statutRaw = (s['statut']?.toString() ?? '').toLowerCase();
    final estCloture = statutRaw == 'traite' || statutRaw == 'rejete';
    final noteModeration = (s['note_admin']?.toString() ?? '').trim();
    final reason = (s['raison']?.toString() ?? 'Aucun détail fourni').trim();
    final count = (s['nombre_signalements'] ?? s['report_count'] ?? 1).toString();
    final timeAgo = (s['il_y_a']?.toString() ?? s['created_at']?.toString() ?? 'Récemment').trim();
    final objetCtx = _objetContextLine(s);

    final leftColor = switch (priority) {
      _ReportPriority.urgent => const Color(0xFFEF4444),
      _ReportPriority.medium => const Color(0xFFF59E0B),
      _ReportPriority.low => const Color(0xFF10B981),
    };

    final priorityLabel = switch (priority) {
      _ReportPriority.urgent => 'URGENT',
      _ReportPriority.medium => 'MOYEN',
      _ReportPriority.low => 'RÉSOLU',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: leftColor, width: 4)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: leftColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    priorityLabel,
                    style: TextStyle(color: leftColor, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Text(type, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(timeAgo, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Signalé par $count utilisateur(s)',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"$reason"',
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontStyle: FontStyle.italic),
              ),
            ),
            if (objetCtx != null) ...[
              const SizedBox(height: 8),
              Text(
                objetCtx,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
            ],
            if (noteModeration.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Message modération (parties notifiées)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4ED8),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      noteModeration,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E3A5F), height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (_canVoirRessource(s))
                  OutlinedButton.icon(
                    onPressed: () => _ouvrirRessourceSignalee(s),
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('Voir'),
                  ),
                if (!estCloture) ...[
                  FilledButton.icon(
                    onPressed: () => _cloturerSignalement(
                      id,
                      'traite',
                      dialogTitle: 'Marquer comme traité',
                      successMessage: 'Dossier traité — notifications envoyées.',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Traiter le dossier'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _cloturerSignalement(
                      id,
                      'rejete',
                      dialogTitle: 'Classer sans suite',
                      successMessage: 'Signalement classé sans suite — notifications envoyées.',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF64748B),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    label: const Text('Classer sans suite'),
                  ),
                ],
              ],
            ),
            if (estCloture)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  statutRaw == 'traite' ? 'Statut : traité' : 'Statut : classé sans suite',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _ReportPriority { urgent, medium, low }

class _ModerationCounterCard extends StatelessWidget {
  const _ModerationCounterCard({
    required this.title,
    required this.count,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  final String title;
  final int count;
  final Color color;
  final Color bgColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
