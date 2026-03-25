import 'package:flutter/material.dart';
import '../../services/offres_service.dart';
import 'offre_detail_screen.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  final _service = OffresService();
  List<Map<String, dynamic>> _items = [];
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
      final list = await _service.getSuggestions(limit: 20);
      setState(() {
        _items = list;
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
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text(
          'Ajoutez un CV pour obtenir des suggestions personnalisées.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final o = _items[i];
          final id = o['id']?.toString() ?? '';
          final titre = o['titre']?.toString() ?? '';
          final score = o['score_compatibilite'];
          final ent = o['entreprises'];
          String? nomEnt;
          if (ent is Map) nomEnt = ent['nom_entreprise']?.toString();
          return ListTile(
            title: Text(titre),
            subtitle: Text(nomEnt ?? ''),
            trailing: score != null
                ? Chip(
                    label: Text('${score is int ? score : (score as num).round()} %'),
                  )
                : null,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => OffreDetailScreen(offreId: id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
