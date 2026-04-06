import 'package:flutter/material.dart';

import '../../services/offres_service.dart';

/// Détail offre vitrine + CTA connexion pour postuler.
class PublicOfferDetailScreen extends StatefulWidget {
  const PublicOfferDetailScreen({super.key, required this.offreId});

  final String offreId;

  @override
  State<PublicOfferDetailScreen> createState() => _PublicOfferDetailScreenState();
}

class _PublicOfferDetailScreenState extends State<PublicOfferDetailScreen> {
  final _svc = OffresService();
  Map<String, dynamic>? _offre;
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
      final o = await _svc.getOffreByIdPublic(widget.offreId);
      if (mounted) setState(() {
        _offre = o;
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

  void _needAccount() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Connexion requise'),
        content: const Text(
          'Pour postuler à cette offre, créez un compte candidat ou connectez-vous.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushNamed('/register');
            },
            child: const Text('Créer un compte'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushNamed('/login');
            },
            child: const Text('Me connecter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _offre == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Offre')),
        body: Center(child: Text(_error ?? 'Introuvable')),
      );
    }
    final o = _offre!;
    final ent = o['entreprises'];
    final company = ent is Map ? (ent['nom_entreprise']?.toString() ?? 'Entreprise') : 'Entreprise';
    final logo = ent is Map ? (ent['logo_url']?.toString() ?? '') : '';
    final banner = ent is Map ? (ent['banniere_url']?.toString() ?? '') : '';
    final title = o['titre']?.toString() ?? 'Offre';
    final description = o['description']?.toString() ?? '';
    final exigences = o['exigences']?.toString() ?? '';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: banner.isNotEmpty ? 160 : 0,
            pinned: true,
            flexibleSpace: banner.isNotEmpty
                ? FlexibleSpaceBar(
                    background: Image.network(
                      banner,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A56DB)),
                    ),
                  )
                : null,
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFEFF6FF),
                      backgroundImage: logo.isNotEmpty ? NetworkImage(logo) : null,
                      child: logo.isEmpty
                          ? Text(
                              company.isNotEmpty ? company[0].toUpperCase() : 'E',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A56DB),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(company, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          Text(
                            '${o['localisation'] ?? ''} · ${o['type_contrat'] ?? ''}',
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (ent is Map && (ent['description']?.toString().isNotEmpty == true)) ...[
                  const SizedBox(height: 20),
                  const Text('L’entreprise', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(ent['description'].toString()),
                ],
                const SizedBox(height: 20),
                const Text('Description du poste', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 8),
                Text(description.isEmpty ? '—' : description),
                const SizedBox(height: 16),
                const Text('Exigences', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 8),
                Text(exigences.isEmpty ? '—' : exigences),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _needAccount,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF1A56DB),
            ),
            child: const Text('Postuler — connexion requise'),
          ),
        ),
      ),
    );
  }
}
