import 'package:flutter/material.dart';
import '../../services/offres_service.dart';
import '../../widgets/responsive_container.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/reveal_on_scroll.dart';
import '../../widgets/hover_scale.dart';
import 'offre_form_screen.dart';
import 'candidatures_offre_screen.dart';

class MesOffresScreen extends StatefulWidget {
  const MesOffresScreen({super.key});

  @override
  State<MesOffresScreen> createState() => _MesOffresScreenState();
}

class _MesOffresScreenState extends State<MesOffresScreen> {
  final _service = OffresService();
  List<Map<String, dynamic>> _offres = [];
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
      final r = await _service.getOffres(mesOffres: true, limit: 50);
      setState(() {
        _offres = r.offres;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette offre ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Oui')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteOffre(id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offre supprimée')),
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

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    return _offres.where((o) {
      final titre = (o['titre']?.toString() ?? '').toLowerCase();
      final loc = (o['localisation']?.toString() ?? '').toLowerCase();
      final dom = (o['domaine']?.toString() ?? '').toLowerCase();
      final statut = o['statut']?.toString() ?? '';

      if (q.isNotEmpty && !titre.contains(q) && !loc.contains(q) && !dom.contains(q)) {
        return false;
      }
      if (_statutFilter != 'tous' && statut != _statutFilter) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const orange = Color(0xFFFF8A00);

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final list = _filtered;

    return ResponsiveContainer(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mes offres',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Publiez, modifiez et suivez vos offres en un coup d’œil.',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                HoverScale(
                  onTap: () => _openForm(),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _openForm,
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvelle offre'),
                  ),
                ),
              ],
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
                            labelText: 'Rechercher (titre / lieu / domaine)',
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
                            DropdownMenuItem(value: 'active', child: Text('Actives')),
                            DropdownMenuItem(value: 'inactive', child: Text('Inactives')),
                          ],
                          onChanged: (v) => setState(() => _statutFilter = v ?? 'tous'),
                        ),
                      ),
                      Text(
                        '${list.length} offre(s)',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 36),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.work_outline, size: 46, color: scheme.onSurfaceVariant),
                      const SizedBox(height: 10),
                      const Text(
                        'Aucune offre pour le moment.',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Créez votre première offre et recevez des candidatures.',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: orange,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _openForm,
                        icon: const Icon(Icons.add),
                        label: const Text('Créer une offre'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...list.map((o) => _OffreCard(o, onDelete: _delete)),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }

  Future<void> _openForm() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const OffreFormScreen()),
    );
    if (!mounted) return;
    await _load();
  }
}

class _OffreCard extends StatelessWidget {
  const _OffreCard(this.o, {required this.onDelete});

  final Map<String, dynamic> o;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final id = o['id']?.toString() ?? '';
    final titre = o['titre']?.toString() ?? '';
    final statut = o['statut']?.toString() ?? '';
    final loc = o['localisation']?.toString();
    final dom = o['domaine']?.toString();
    final sMin = o['salaire_min'];
    final sMax = o['salaire_max'];

    String salaire = '';
    if (sMin != null || sMax != null) {
      final minStr = sMin?.toString();
      final maxStr = sMax?.toString();
      if (minStr != null && maxStr != null) {
        salaire = '$minStr - $maxStr GNF';
      } else if (minStr != null) {
        salaire = 'À partir de $minStr GNF';
      } else if (maxStr != null) {
        salaire = 'Jusqu’à $maxStr GNF';
      }
    }

    return RevealOnScroll(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titre.isEmpty ? 'Offre' : titre,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          [dom, loc, salaire].where((e) => e != null && e.isNotEmpty).join(' · '),
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  StatusChip(value: statut),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CandidaturesOffreScreen(offreId: id, titre: titre),
                        ),
                      );
                    },
                    icon: const Icon(Icons.assignment_outlined),
                    label: const Text('Candidatures'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => OffreFormScreen(offreId: id)),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Modifier'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onDelete(id),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Supprimer'),
                    style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
