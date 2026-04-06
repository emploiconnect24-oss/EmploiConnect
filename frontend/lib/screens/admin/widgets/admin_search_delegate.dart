import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/admin_service.dart';
import '../admin_offre_detail_screen.dart';
import '../pages/user_detail_page.dart';

/// Recherche admin (GET `/admin/recherche`) avec debounce ~400 ms.
class AdminSearchDelegate extends SearchDelegate<void> {
  AdminSearchDelegate(this._admin, {required this.resultsContext});

  final AdminService _admin;
  /// Contexte sous-jacent (shell admin) pour ouvrir les fiches après fermeture de la recherche.
  final BuildContext resultsContext;

  @override
  String get searchFieldLabel => 'Recherche globale';

  @override
  List<Widget>? buildActions(BuildContext context) {
    if (query.isEmpty) return null;
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    return _DebouncedAdminSearchBody(
      query: query,
      admin: _admin,
      resultsContext: resultsContext,
      onClose: () => close(context, null),
    );
  }

  static void openResult(BuildContext context, Map<String, dynamic> r) {
    final type = r['type']?.toString();
    final id = r['id']?.toString();
    if (id == null || id.isEmpty) return;

    if (type == 'offre') {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => AdminOffreDetailScreen(offreId: id)),
      );
      return;
    }
    if (type == 'entreprise') {
      final uid = r['utilisateur_id']?.toString();
      if (uid == null || uid.isEmpty) return;
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => UserDetailPage(userId: uid)),
      );
      return;
    }
    if (type == 'utilisateur') {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => UserDetailPage(userId: id)),
      );
    }
  }
}

class _DebouncedAdminSearchBody extends StatefulWidget {
  const _DebouncedAdminSearchBody({
    required this.query,
    required this.admin,
    required this.resultsContext,
    required this.onClose,
  });

  final String query;
  final AdminService admin;
  final BuildContext resultsContext;
  final VoidCallback onClose;

  @override
  State<_DebouncedAdminSearchBody> createState() => _DebouncedAdminSearchBodyState();
}

class _DebouncedAdminSearchBodyState extends State<_DebouncedAdminSearchBody> {
  Timer? _debounce;
  Future<Map<String, dynamic>>? _future;
  String _lastScheduled = '';

  @override
  void initState() {
    super.initState();
    _schedule(widget.query.trim());
  }

  @override
  void didUpdateWidget(covariant _DebouncedAdminSearchBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _schedule(widget.query.trim());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _schedule(String q) {
    _debounce?.cancel();
    if (q.length < 2) {
      setState(() {
        _future = null;
        _lastScheduled = q;
      });
      return;
    }
    _lastScheduled = q;
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted || _lastScheduled != q) return;
      setState(() {
        _future = widget.admin.rechercheGlobale(q);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.query.trim();
    if (q.length < 2) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Saisissez au moins 2 caractères',
            style: TextStyle(color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final fut = _future;
    if (fut == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: fut,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(snap.error.toString(), textAlign: TextAlign.center),
            ),
          );
        }
        final body = snap.data;
        final data = body?['data'];
        final raw = (data is Map ? data['resultats'] : null) as List<dynamic>? ?? const [];
        final list = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (list.isEmpty) {
          return const Center(
            child: Text('Aucun résultat', style: TextStyle(color: Color(0xFF64748B))),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final r = list[i];
            final type = r['type']?.toString() ?? '';
            final titre = r['titre']?.toString() ?? '—';
            final sous = r['sous_titre']?.toString() ?? '';
            IconData icon = Icons.search;
            Color c = const Color(0xFF94A3B8);
            switch (type) {
              case 'utilisateur':
                icon = Icons.person_outlined;
                c = const Color(0xFF1A56DB);
                break;
              case 'offre':
                icon = Icons.work_outline;
                c = const Color(0xFF10B981);
                break;
              case 'entreprise':
                icon = Icons.business_outlined;
                c = const Color(0xFF8B5CF6);
                break;
            }
            return ListTile(
              leading: Icon(icon, color: c),
              title: Text(titre, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(sous, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () {
                widget.onClose();
                final outer = widget.resultsContext;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (outer.mounted) AdminSearchDelegate.openResult(outer, r);
                });
              },
            );
          },
        );
      },
    );
  }
}
