import 'package:flutter/material.dart';

import '../../app/public_routes.dart';
import '../../services/offres_service.dart';

/// Liste d’offres pour visiteurs non connectés.
class PublicOffresScreen extends StatefulWidget {
  const PublicOffresScreen({
    super.key,
    this.initialSearch,
    this.entrepriseId,
    this.entrepriseNom,
  });

  final String? initialSearch;
  /// Filtre serveur sur `entreprise_id` (lien depuis le bandeau « top entreprises »).
  final String? entrepriseId;
  final String? entrepriseNom;

  @override
  State<PublicOffresScreen> createState() => _PublicOffresScreenState();
}

class _PublicOffresScreenState extends State<PublicOffresScreen> {
  final _svc = OffresService();
  final _searchCtrl = TextEditingController();
  final List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _more = false;
  String? _error;
  static const _limit = 20;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null && widget.initialSearch!.trim().isNotEmpty) {
      _searchCtrl.text = widget.initialSearch!.trim();
    }
    _fetch(reset: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final startOffset = reset ? 0 : _items.length;
    final eid = widget.entrepriseId?.trim();
    try {
      final r = await _svc.getOffresPublic(
        offset: startOffset,
        limit: _limit,
        recherche: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        entrepriseId: (eid == null || eid.isEmpty) ? null : eid,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(r.offres);
        } else {
          _items.addAll(r.offres);
        }
        _more = r.offres.length >= _limit;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nomEnt = widget.entrepriseNom?.trim();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          (nomEnt != null && nomEnt.isNotEmpty) ? 'Offres — $nomEnt' : 'Offres d’emploi',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Rechercher une offre…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _fetch(reset: true),
                ),
              ),
              onSubmitted: (_) => _fetch(reset: true),
            ),
          ),
          Expanded(
            child: _loading && _items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
                    : _items.isEmpty
                        ? const Center(child: Text('Aucune offre pour le moment.'))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _items.length + (_more ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (i >= _items.length) {
                                return TextButton(
                                  onPressed: _more ? () => _fetch(reset: false) : null,
                                  child: const Text('Charger plus'),
                                );
                              }
                              final o = _items[i];
                              final id = o['id']?.toString() ?? '';
                              final ent = o['entreprises'];
                              final company = ent is Map
                                  ? (ent['nom_entreprise'] ?? 'Entreprise').toString()
                                  : 'Entreprise';
                              final logo = ent is Map ? (ent['logo_url']?.toString() ?? '') : '';
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFEFF6FF),
                                    backgroundImage:
                                        logo.isNotEmpty ? NetworkImage(logo) : null,
                                    child: logo.isEmpty
                                        ? Text(
                                            company.isNotEmpty ? company[0].toUpperCase() : 'E',
                                            style: const TextStyle(
                                              color: Color(0xFF1A56DB),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          )
                                        : null,
                                  ),
                                  title: Text(o['titre']?.toString() ?? 'Offre'),
                                  subtitle: Text(
                                    '$company · ${o['localisation'] ?? ''} · ${o['type_contrat'] ?? ''}',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: id.isEmpty
                                      ? null
                                      : () => Navigator.of(context)
                                          .pushNamed(PublicRoutes.offre(id)),
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
