import 'package:flutter/material.dart';
import '../../services/offres_service.dart';
import '../../widgets/responsive_container.dart';
import 'offre_detail_screen.dart';

class OffresListScreen extends StatefulWidget {
  const OffresListScreen({super.key});

  @override
  State<OffresListScreen> createState() => _OffresListScreenState();
}

class _OffresListScreenState extends State<OffresListScreen> {
  final _service = OffresService();
  final _domaineCtrl = TextEditingController();
  final _lieuCtrl = TextEditingController();
  List<Map<String, dynamic>> _offres = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _domaineCtrl.dispose();
    _lieuCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _service.getOffres(
        domaine: _domaineCtrl.text.trim().isEmpty ? null : _domaineCtrl.text.trim(),
        localisation: _lieuCtrl.text.trim().isEmpty ? null : _lieuCtrl.text.trim(),
      );
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

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _domaineCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Domaine',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _load(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _lieuCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Lieu',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _load(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _load,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, textAlign: TextAlign.center))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _offres.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 120),
                                  Center(child: Text('Aucune offre')),
                                ],
                              )
                            : ListView.separated(
                                itemCount: _offres.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 8),
                                itemBuilder: (context, i) {
                                  final o = _offres[i];
                                  final id = o['id']?.toString() ?? '';
                                  final titre = o['titre']?.toString() ?? '';
                                  final loc = o['localisation']?.toString();
                                  final ent = o['entreprises'];
                                  String? nomEnt;
                                  if (ent is Map) {
                                    nomEnt = ent['nom_entreprise']?.toString();
                                  }
                                  return Card(
                                    child: ListTile(
                                      title: Text(titre, maxLines: 2, overflow: TextOverflow.ellipsis),
                                      subtitle: Text(
                                        [nomEnt, loc].where((e) => e != null && e.isNotEmpty).join(' · '),
                                      ),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => OffreDetailScreen(offreId: id),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}
