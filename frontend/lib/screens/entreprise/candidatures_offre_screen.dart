import 'package:flutter/material.dart';
import '../../services/candidatures_service.dart';
import '../../services/cv_service.dart';

class CandidaturesOffreScreen extends StatefulWidget {
  const CandidaturesOffreScreen({
    super.key,
    required this.offreId,
    required this.titre,
  });

  final String offreId;
  final String titre;

  @override
  State<CandidaturesOffreScreen> createState() => _CandidaturesOffreScreenState();
}

class _CandidaturesOffreScreenState extends State<CandidaturesOffreScreen> {
  final _service = CandidaturesService();
  final _cvService = CvService();
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;

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
      final list = await _service.getCandidatures(offreId: widget.offreId);
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

  Future<void> _changerStatut(String id, String statut) async {
    try {
      await _service.updateStatut(id, statut);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Statut : $statut')),
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

  Future<void> _voirCv(String candidatureId) async {
    try {
      final url = await _cvService.getDownloadUrl(candidatureId: candidatureId);
      if (!mounted) return;
      if (url == null || url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun lien CV disponible')),
        );
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Lien du CV'),
          content: SelectableText(url),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titre),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _list.isEmpty
                  ? const Center(child: Text('Aucune candidature'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        itemCount: _list.length,
                        itemBuilder: (context, i) {
                          final c = _list[i];
                          final id = c['id']?.toString() ?? '';
                          final statut = c['statut']?.toString() ?? '';
                          final score = c['score_compatibilite'];
                          return ListTile(
                            title: Text('Candidature $id'),
                            subtitle: Text(
                              '$statut${score != null ? ' · Score: $score' : ''}',
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'cv') {
                                  _voirCv(id);
                                  return;
                                }
                                _changerStatut(id, v);
                              },
                              itemBuilder: (ctx) => const [
                                PopupMenuItem(value: 'cv', child: Text('Voir lien CV')),
                                PopupMenuItem(value: 'en_cours', child: Text('En cours')),
                                PopupMenuItem(value: 'acceptee', child: Text('Acceptée')),
                                PopupMenuItem(value: 'refusee', child: Text('Refusée')),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
