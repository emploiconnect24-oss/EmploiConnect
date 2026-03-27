import 'package:flutter/material.dart';
import '../../services/offres_service.dart';
import '../../widgets/hover_scale.dart';
import '../../widgets/responsive_container.dart';
import '../../widgets/reveal_on_scroll.dart';
import '../../widgets/status_chip.dart';
import 'candidatures_offre_screen.dart';
import 'offre_form_screen.dart';

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
  String _activeTab = 'Toutes';
  String _contractFilter = 'tous';
  String _cityFilter = 'toutes';

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

  String _uiStatus(Map<String, dynamic> o) {
    final raw = (o['statut']?.toString() ?? '').toLowerCase();
    if (raw.contains('attente')) return 'En attente';
    if (raw.contains('expire')) return 'Expirées';
    if (raw.contains('brouillon') || raw.contains('draft')) return 'Brouillons';
    if (raw.contains('inactive')) return 'Expirées';
    return 'Actives';
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    return _offres.where((o) {
      final titre = (o['titre']?.toString() ?? '').toLowerCase();
      final loc = (o['localisation']?.toString() ?? '').toLowerCase();
      final dom = (o['domaine']?.toString() ?? '').toLowerCase();
      final statusUi = _uiStatus(o);
      final type = (o['type_contrat']?.toString() ?? '').toLowerCase();
      final city = (o['localisation']?.toString() ?? '').toLowerCase().trim();
      if (q.isNotEmpty && !titre.contains(q) && !loc.contains(q) && !dom.contains(q)) {
        return false;
      }
      if (_activeTab != 'Toutes' && statusUi != _activeTab) return false;
      if (_contractFilter != 'tous' && type != _contractFilter) return false;
      if (_cityFilter != 'toutes' && city != _cityFilter) return false;
      return true;
    }).toList();
  }

  Map<String, int> get _counts {
    final map = <String, int>{
      'Toutes': _offres.length,
      'Actives': 0,
      'En attente': 0,
      'Expirées': 0,
      'Brouillons': 0,
    };
    for (final o in _offres) {
      final s = _uiStatus(o);
      map[s] = (map[s] ?? 0) + 1;
    }
    return map;
  }

  List<String> get _cities {
    final set = <String>{};
    for (final o in _offres) {
      final city = (o['localisation']?.toString() ?? '').trim();
      if (city.isNotEmpty) set.add(city);
    }
    final list = set.toList()..sort();
    return list;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offre supprimée')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _duplicate(Map<String, dynamic> offer) async {
    final body = <String, dynamic>{
      'titre': '${offer['titre'] ?? 'Offre'} (Copie)',
      'description': offer['description'] ?? '',
      'exigences': offer['exigences'] ?? '',
      'localisation': offer['localisation'],
      'domaine': offer['domaine'],
      'type_contrat': offer['type_contrat'],
      'salaire_min': offer['salaire_min'],
      'salaire_max': offer['salaire_max'],
      'devise': offer['devise'] ?? 'GNF',
    };
    try {
      await _service.createOffre(body);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offre dupliquée')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _closeOffer(Map<String, dynamic> offer) async {
    final id = offer['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clôturer cette offre ?'),
        content: const Text(
          'L\'offre ne sera plus visible par les candidats. Les candidatures reçues seront conservées.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Clôturer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.updateOffre(id, {'statut': 'inactive'});
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offre clôturée')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _openForm() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const OffreFormScreen()));
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final list = _filtered;
    final counts = _counts;

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
                        'Mes offres d\'emploi',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text('Gérez toutes vos annonces de recrutement.', style: TextStyle(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                HoverScale(
                  onTap: _openForm,
                  child: FilledButton.icon(
                    onPressed: _openForm,
                    icon: const Icon(Icons.add),
                    label: const Text('Publier une offre'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RevealOnScroll(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tab in const ['Toutes', 'Actives', 'En attente', 'Expirées', 'Brouillons'])
                            ChoiceChip(
                              label: Text('$tab (${counts[tab] ?? 0})'),
                              selected: _activeTab == tab,
                              onSelected: (_) => setState(() => _activeTab = tab),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 320,
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Rechercher...',
                                prefixIcon: Icon(Icons.search),
                                isDense: true,
                              ),
                              onChanged: (v) => setState(() => _query = v),
                            ),
                          ),
                          SizedBox(
                            width: 180,
                            child: DropdownButtonFormField<String>(
                              initialValue: _contractFilter,
                              decoration: const InputDecoration(labelText: 'Contrat', isDense: true),
                              items: const [
                                DropdownMenuItem(value: 'tous', child: Text('Tous')),
                                DropdownMenuItem(value: 'cdi', child: Text('CDI')),
                                DropdownMenuItem(value: 'cdd', child: Text('CDD')),
                                DropdownMenuItem(value: 'stage', child: Text('Stage')),
                                DropdownMenuItem(value: 'freelance', child: Text('Freelance')),
                              ],
                              onChanged: (v) => setState(() => _contractFilter = v ?? 'tous'),
                            ),
                          ),
                          SizedBox(
                            width: 180,
                            child: DropdownButtonFormField<String>(
                              initialValue: _cityFilter,
                              decoration: const InputDecoration(labelText: 'Ville', isDense: true),
                              items: [
                                const DropdownMenuItem(value: 'toutes', child: Text('Toutes')),
                                ..._cities.map((c) => DropdownMenuItem(value: c.toLowerCase(), child: Text(c))),
                              ],
                              onChanged: (v) => setState(() => _cityFilter = v ?? 'toutes'),
                            ),
                          ),
                          Text('${list.length} résultat(s)', style: TextStyle(color: scheme.onSurfaceVariant)),
                        ],
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
                      const Text('Aucune offre pour le moment.', style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text(
                        'Créez votre première offre et recevez des candidatures.',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _openForm,
                        icon: const Icon(Icons.add),
                        label: const Text('Publier une offre'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...list.map(
                (o) => _OffreCard(
                  o,
                  statusUi: _uiStatus(o),
                  onDelete: _delete,
                  onDuplicate: () => _duplicate(o),
                  onClose: () => _closeOffer(o),
                ),
              ),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}

class _OffreCard extends StatelessWidget {
  const _OffreCard(
    this.o, {
    required this.statusUi,
    required this.onDelete,
    required this.onDuplicate,
    required this.onClose,
  });

  final Map<String, dynamic> o;
  final String statusUi;
  final Future<void> Function(String id) onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final id = o['id']?.toString() ?? '';
    final titre = o['titre']?.toString() ?? '';
    final statut = o['statut']?.toString() ?? '';
    final loc = o['localisation']?.toString();
    final dom = o['domaine']?.toString();
    final contrat = o['type_contrat']?.toString();
    final sMin = o['salaire_min'];
    final sMax = o['salaire_max'];
    final vues = (o['vues'] ?? o['nombre_vues'] ?? 0).toString();
    final candidatures = (o['nombre_candidatures'] ?? o['candidatures_count'] ?? 0).toString();
    final nonLues = (o['candidatures_non_lues'] ?? o['nombre_non_lues'] ?? 0).toString();

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
                          [loc, contrat, salaire].where((e) => e != null && e.isNotEmpty).join(' · '),
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Domaine: ${dom ?? '-'}',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  StatusChip(value: statusUi.isEmpty ? statut : statusUi),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _StatChip(icon: Icons.visibility_outlined, label: '$vues vues'),
                  _StatChip(icon: Icons.people_outline, label: '$candidatures candidatures'),
                  _StatChip(icon: Icons.mark_email_unread_outlined, label: '$nonLues non lues'),
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
                    onPressed: onDuplicate,
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Dupliquer'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_outlined),
                    label: const Text('Clôturer'),
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

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
    );
  }
}
