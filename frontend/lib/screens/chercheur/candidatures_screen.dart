import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/candidatures_service.dart';
import '../../widgets/responsive_container.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/reveal_on_scroll.dart';

class CandidaturesScreen extends StatefulWidget {
  const CandidaturesScreen({super.key});

  @override
  State<CandidaturesScreen> createState() => _CandidaturesScreenState();
}

class _CandidaturesScreenState extends State<CandidaturesScreen> {
  final _service = CandidaturesService();
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  String _statutFilter = 'tous';

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
      final list = await _service.getCandidatures();
      setState(() {
        _list = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _annuler(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la candidature ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Oui')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _service.updateStatut(id, 'annulee');
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Candidature annulée')),
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
    final scheme = Theme.of(context).colorScheme;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    final fmt = DateFormat('dd/MM/yyyy');

    final q = _query.trim().toLowerCase();
    final filtered = _list.where((c) {
      final statut = c['statut']?.toString() ?? '';
      final offre = c['offres_emploi'];
      String titre = '';
      if (offre is Map) titre = offre['titre']?.toString() ?? '';
      final t = titre.toLowerCase();
      if (q.isNotEmpty && !t.contains(q)) return false;
      if (_statutFilter != 'tous' && statut != _statutFilter) return false;
      return true;
    }).toList();

    return ResponsiveContainer(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Text(
              'Candidatures',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Suivez vos candidatures et leurs statuts.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            RevealOnScroll(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 320,
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Rechercher (titre offre)',
                            prefixIcon: Icon(Icons.search),
                            isDense: true,
                          ),
                          onChanged: (v) => setState(() => _query = v),
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: DropdownButtonFormField<String>(
                          initialValue: _statutFilter,
                          decoration: const InputDecoration(
                            labelText: 'Statut',
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'tous', child: Text('Tous')),
                            DropdownMenuItem(value: 'en_attente', child: Text('En attente')),
                            DropdownMenuItem(value: 'traitee', child: Text('Traitée')),
                            DropdownMenuItem(value: 'annulee', child: Text('Annulée')),
                            DropdownMenuItem(value: 'acceptee', child: Text('Acceptée')),
                            DropdownMenuItem(value: 'refusee', child: Text('Refusée')),
                          ],
                          onChanged: (v) => setState(() => _statutFilter = v ?? 'tous'),
                        ),
                      ),
                      Text(
                        '${filtered.length} candidature(s)',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_list.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 36),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.assignment_outlined, size: 46, color: scheme.onSurfaceVariant),
                      const SizedBox(height: 10),
                      const Text('Aucune candidature.', style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text(
                        'Postulez à une offre pour la voir apparaître ici.',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 26),
                child: Center(
                  child: Text(
                    'Aucune candidature ne correspond aux filtres.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              ...filtered.map((c) {
                final id = c['id']?.toString() ?? '';
                final statut = c['statut']?.toString() ?? '';
                final score = c['score_compatibilite'];
                final offre = c['offres_emploi'];
                String titre = '';
                if (offre is Map) titre = offre['titre']?.toString() ?? '';
                final dateStr = c['date_candidature']?.toString();
                DateTime? d;
                if (dateStr != null) {
                  try {
                    d = DateTime.parse(dateStr);
                  } catch (_) {}
                }
                return RevealOnScroll(
                  child: Card(
                    child: ListTile(
                      title: Text(titre.isEmpty ? 'Offre' : titre),
                      subtitle: Text(d != null ? fmt.format(d) : 'Date inconnue'),
                      trailing: Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (score != null) Chip(label: Text('$score%')),
                          StatusChip(value: statut),
                          if (statut != 'annulee' && statut != 'acceptee' && statut != 'refusee')
                            TextButton(
                              onPressed: () => _annuler(id),
                              child: const Text('Annuler'),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}
