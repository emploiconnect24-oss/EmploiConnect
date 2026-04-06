import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import 'admin_offre_detail_screen.dart';
import 'pages/user_detail_page.dart';

/// Détail d’une candidature pour la modération (lié aux signalements).
class AdminCandidatureDetailScreen extends StatefulWidget {
  const AdminCandidatureDetailScreen({super.key, required this.candidatureId});

  final String candidatureId;

  @override
  State<AdminCandidatureDetailScreen> createState() => _AdminCandidatureDetailScreenState();
}

class _AdminCandidatureDetailScreenState extends State<AdminCandidatureDetailScreen> {
  final _admin = AdminService();
  Map<String, dynamic>? _data;
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
      final res = await _admin.getCandidatureAdmin(widget.candidatureId);
      final d = res['data'];
      setState(() {
        _data = d is Map ? Map<String, dynamic>.from(d) : null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Map<String, dynamic>? _firstMap(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is List && v.isNotEmpty && v.first is Map) {
      return Map<String, dynamic>.from(v.first as Map);
    }
    return null;
  }

  String _statutLabel(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'en_attente':
        return 'En attente';
      case 'en_cours':
        return 'En cours';
      case 'entretien':
        return 'Entretien';
      case 'acceptee':
        return 'Acceptée';
      case 'refusee':
        return 'Refusée';
      case 'annulee':
        return 'Annulée';
      default:
        return raw?.isNotEmpty == true ? raw! : '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Candidature signalée'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('Réessayer')),
                      ],
                    ),
                  ),
                )
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final c = _data ?? {};
    final ch = _firstMap(c['chercheurs_emploi']);
    final u = _firstMap(ch?['utilisateurs']);
    final candName = (u?['nom'] ?? '').toString().trim();
    final candEmail = (u?['email'] ?? '').toString().trim();
    final userId = (u?['id'] ?? '').toString().trim();

    final off = _firstMap(c['offres_emploi']);
    final titre = (off?['titre'] ?? '').toString().trim();
    final loc = (off?['localisation'] ?? '').toString().trim();
    final contrat = (off?['type_contrat'] ?? '').toString().trim();
    final offreId = (off?['id'] ?? c['offre_id'] ?? '').toString().trim();
    final ent = _firstMap(off?['entreprises']);
    final entNom = (ent?['nom_entreprise'] ?? '').toString().trim();

    final lettre = (c['lettre_motivation'] ?? '').toString().trim();
    final raisonRefus = (c['raison_refus'] ?? '').toString().trim();
    final score = c['score_compatibilite'];
    final scoreStr = score is num ? score.toStringAsFixed(1) : (score?.toString() ?? '');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _card(
            title: 'Statut',
            child: Text(
              _statutLabel(c['statut']?.toString()),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
          ),
          if (scoreStr.isNotEmpty) ...[
            const SizedBox(height: 12),
            _card(
              title: 'Score compatibilité (IA)',
              child: Text(scoreStr, style: const TextStyle(fontSize: 15, color: Color(0xFF334155))),
            ),
          ],
          const SizedBox(height: 12),
          _card(
            title: 'Candidat',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candName.isEmpty ? '—' : candName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
                if (candEmail.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(candEmail, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                ],
                if (userId.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(builder: (_) => UserDetailPage(userId: userId)),
                      );
                    },
                    icon: const Icon(Icons.person_outlined, size: 18),
                    label: const Text('Fiche utilisateur'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            title: 'Offre',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre.isEmpty ? '—' : titre,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
                if (entNom.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(entNom, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                ],
                if (loc.isNotEmpty || contrat.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      [loc, contrat].where((e) => e.isNotEmpty).join(' · '),
                      style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    ),
                  ),
                if (offreId.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(builder: (_) => AdminOffreDetailScreen(offreId: offreId)),
                      );
                    },
                    icon: const Icon(Icons.work_outline, size: 18),
                    label: const Text('Modérer l’offre'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            title: 'Dates',
            child: Text(
              [
                if (c['date_candidature'] != null) 'Candidature : ${c['date_candidature']}',
                if (c['date_modification'] != null) 'Dernière mise à jour : ${c['date_modification']}',
              ].where((e) => e.isNotEmpty).join('\n'),
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
          ),
          if (lettre.isNotEmpty) ...[
            const SizedBox(height: 12),
            _card(
              title: 'Lettre de motivation',
              child: Text(lettre, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.45)),
            ),
          ],
          if (raisonRefus.isNotEmpty) ...[
            const SizedBox(height: 12),
            _card(
              title: 'Motif de refus (recruteur)',
              child: Text(raisonRefus, style: const TextStyle(fontSize: 14, color: Color(0xFF991B1B), height: 1.45)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.3),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
