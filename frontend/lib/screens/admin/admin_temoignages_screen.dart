import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import '../../widgets/responsive_container.dart';
import 'pages/user_detail_page.dart';
import 'widgets/admin_page_shimmer.dart';

/// Modération des témoignages recrutement (publication accueil après validation).
class AdminTemoignagesScreen extends StatefulWidget {
  const AdminTemoignagesScreen({super.key});

  @override
  State<AdminTemoignagesScreen> createState() => _AdminTemoignagesScreenState();
}

class _AdminTemoignagesScreenState extends State<AdminTemoignagesScreen> {
  final _admin = AdminService();
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;
  String _filtreApi = 'en_attente';

  static const _filtres = <({String label, String api})>[
    (label: 'En attente', api: 'en_attente'),
    (label: 'Publiés', api: 'approuve'),
    (label: 'Refusés', api: 'refuse'),
    (label: 'Tous', api: 'all'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _syncBadges() {
    if (!mounted) return;
    context.read<AdminProvider>().loadDashboard();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _admin.getTemoignagesAdmin(statut: _filtreApi, limit: 100);
      if (!mounted) return;
      setState(() {
        _list = r.temoignages;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _statutLabel(String? s) {
    switch (s) {
      case 'en_attente':
        return 'En attente';
      case 'approuve':
        return 'Publié';
      case 'refuse':
        return 'Refusé';
      default:
        return s ?? '—';
    }
  }

  Color _statutColor(String? s) {
    switch (s) {
      case 'en_attente':
        return const Color(0xFFF59E0B);
      case 'approuve':
        return const Color(0xFF059669);
      case 'refuse':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  Future<void> _refuser(Map<String, dynamic> row) async {
    final id = row['id']?.toString();
    if (id == null || id.isEmpty) return;

    final motif = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Refuser le témoignage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Optionnel : motif communiqué au candidat dans sa notification.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 3,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Motif',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                ctrl.dispose();
                Navigator.pop(ctx, null);
              },
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              onPressed: () {
                final t = ctrl.text.trim();
                ctrl.dispose();
                Navigator.pop(ctx, t);
              },
              child: const Text('Refuser'),
            ),
          ],
        );
      },
    );

    if (motif == null || !mounted) return;
    try {
      await _admin.modererTemoignage(
        id,
        action: 'refuser',
        noteModeration: motif.isEmpty ? null : motif,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Témoignage refusé.'), backgroundColor: Color(0xFF059669)),
      );
      _syncBadges();
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    }
  }

  Future<void> _approuver(String id) async {
    try {
      await _admin.modererTemoignage(id, action: 'approuver');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Témoignage publié sur l’accueil.'), backgroundColor: Color(0xFF059669)),
      );
      _syncBadges();
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Témoignages recrutement',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Actualiser',
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in _filtres)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f.label),
                        selected: _filtreApi == f.api,
                        onSelected: (sel) {
                          if (!sel) return;
                          setState(() => _filtreApi = f.api);
                          _load();
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const AdminListScreenShimmer(showHeaderAction: false)
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              FilledButton(onPressed: _load, child: const Text('Réessayer')),
                            ],
                          ),
                        )
                      : _list.isEmpty
                          ? const Center(
                              child: Text(
                                'Aucun témoignage dans cette catégorie.',
                                style: TextStyle(color: Color(0xFF64748B)),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _list.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final row = _list[i];
                                final id = row['id']?.toString() ?? '';
                                final msg = (row['message']?.toString() ?? '').trim();
                                final statut = row['statut_moderation']?.toString();
                                final cand = row['candidat'] is Map
                                    ? Map<String, dynamic>.from(row['candidat'] as Map)
                                    : <String, dynamic>{};
                                final ent = row['entreprise'] is Map
                                    ? Map<String, dynamic>.from(row['entreprise'] as Map)
                                    : <String, dynamic>{};
                                final candId = cand['id']?.toString();
                                final pending = statut == 'en_attente';

                                return Card(
                                  elevation: 0,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _statutColor(statut).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                _statutLabel(statut),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: _statutColor(statut),
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            if (candId != null && candId.isNotEmpty)
                                              TextButton.icon(
                                                onPressed: () {
                                                  Navigator.of(context).push<void>(
                                                    MaterialPageRoute<void>(
                                                      builder: (_) => UserDetailPage(userId: candId),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(Icons.person_outline, size: 18),
                                                label: const Text('Profil'),
                                              ),
                                            if (pending) ...[
                                              IconButton.filledTonal(
                                                tooltip: 'Publier',
                                                onPressed: id.isEmpty ? null : () => _approuver(id),
                                                icon: const Icon(Icons.check_rounded),
                                                style: IconButton.styleFrom(
                                                  foregroundColor: const Color(0xFF059669),
                                                ),
                                              ),
                                              IconButton.filledTonal(
                                                tooltip: 'Refuser',
                                                onPressed: id.isEmpty ? null : () => _refuser(row),
                                                icon: const Icon(Icons.close_rounded),
                                                style: IconButton.styleFrom(
                                                  foregroundColor: const Color(0xFFDC2626),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${cand['nom'] ?? 'Candidat'} · ${ent['nom_entreprise'] ?? 'Entreprise'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        if (cand['email'] != null &&
                                            (cand['email'].toString().isNotEmpty))
                                          Text(
                                            cand['email'].toString(),
                                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                          ),
                                        const SizedBox(height: 10),
                                        Text(
                                          msg.length > 280 ? '${msg.substring(0, 280)}…' : msg,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            height: 1.45,
                                            color: Color(0xFF334155),
                                          ),
                                        ),
                                        if (row['note_moderation'] != null &&
                                            row['note_moderation'].toString().trim().isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Text(
                                            'Note modération : ${row['note_moderation']}',
                                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
      ),
    );
  }
}
