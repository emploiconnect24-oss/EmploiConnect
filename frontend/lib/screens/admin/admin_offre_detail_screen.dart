import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';

/// Détail offre admin — design PRD (statut, sections, valider / refuser).
class AdminOffreDetailScreen extends StatefulWidget {
  const AdminOffreDetailScreen({super.key, required this.offreId});

  final String offreId;

  @override
  State<AdminOffreDetailScreen> createState() => _AdminOffreDetailScreenState();
}

class _AdminOffreDetailScreenState extends State<AdminOffreDetailScreen> {
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
      final res = await _admin.getOffreAdmin(widget.offreId);
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

  String _normStatut(String? s) {
    final x = (s ?? '').toLowerCase().trim();
    if (x == 'publiee' || x == 'publiée' || x == 'active') return 'publiee';
    if (x == 'en_attente' || x == 'brouillon') return 'en_attente';
    if (x == 'refusee' || x == 'refusée' || x == 'suspendue') return 'refusee';
    if (x == 'expiree' || x == 'expirée' || x == 'fermee') return 'expiree';
    return x;
  }

  Map<String, dynamic> _entrepriseMap(Map<String, dynamic>? o) {
    if (o == null) return {};
    final e = o['entreprises'];
    if (e is Map) return Map<String, dynamic>.from(e);
    if (e is List && e.isNotEmpty && e.first is Map) {
      return Map<String, dynamic>.from(e.first as Map);
    }
    return {};
  }

  List<String> _compsList(Map<String, dynamic>? o) {
    if (o == null) return [];
    final raw = o['competences_requises'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  int? _int(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  Future<void> _valider() async {
    try {
      await _admin.patchOffreAdmin(widget.offreId, action: 'valider');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offre validée')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _refuser() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Refuser l’offre', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Motif du refus…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final motif = ctrl.text.trim();
    if (motif.isEmpty) return;
    try {
      await _admin.patchOffreAdmin(widget.offreId, action: 'refuser', raisonRefus: motif);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offre refusée')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1A56DB))),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF64748B),
          title: Text('Détail offre', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        ),
        body: Center(
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
        ),
      );
    }

    final o = _data!;
    final statutRaw = o['statut']?.toString() ?? '';
    final statut = _normStatut(statutRaw);
    final titre = o['titre']?.toString() ?? '—';
    final desc = o['description']?.toString() ?? '';
    final exig = o['exigences']?.toString() ?? '';
    final loc = o['localisation']?.toString() ?? '';
    final contrat = o['type_contrat']?.toString() ?? '';
    final domaine = o['domaine']?.toString() ?? '';
    final nbVues = _int(o['nb_vues']) ?? 0;
    final nbCands = _int(o['nb_candidatures']) ?? 0;
    final dateP = o['date_publication']?.toString();
    final dateLim = o['date_limite']?.toString();
    final sMin = _int(o['salaire_min']);
    final sMax = _int(o['salaire_max']);
    final devise = o['devise']?.toString() ?? 'GNF';
    final raison = o['raison_refus']?.toString();
    final vedette = o['en_vedette'] == true;
    final ent = _entrepriseMap(o);
    final comps = _compsList(o);

    late Color statutColor;
    late IconData statutIcon;
    late String statutLabel;
    switch (statut) {
      case 'publiee':
        statutColor = const Color(0xFF10B981);
        statutIcon = Icons.check_circle_rounded;
        statutLabel = 'Publiée';
        break;
      case 'en_attente':
        statutColor = const Color(0xFFF59E0B);
        statutIcon = Icons.hourglass_empty_rounded;
        statutLabel = 'En attente de validation';
        break;
      case 'refusee':
        statutColor = const Color(0xFFEF4444);
        statutIcon = Icons.cancel_rounded;
        statutLabel = 'Refusée';
        break;
      case 'expiree':
        statutColor = const Color(0xFF64748B);
        statutIcon = Icons.event_busy_rounded;
        statutLabel = 'Expirée';
        break;
      default:
        statutColor = const Color(0xFF94A3B8);
        statutIcon = Icons.circle_outlined;
        statutLabel = statutRaw.isEmpty ? '—' : statutRaw;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF64748B),
        title: Text(
          'Détails de l’offre',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          if (statut == 'en_attente') ...[
            TextButton.icon(
              icon: const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 18),
              label: Text(
                'Valider',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: _valider,
            ),
            TextButton.icon(
              icon: const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 18),
              label: Text(
                'Refuser',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: _refuser,
            ),
          ],
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: statutColor.withValues(alpha: 0.35)),
                boxShadow: const [
                  BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statutColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: statutColor.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statutIcon, size: 14, color: statutColor),
                            const SizedBox(width: 5),
                            Text(
                              statutLabel,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statutColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (vedette)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 4),
                              Text(
                                'En vedette',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    titre,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if ((ent['logo_url']?.toString() ?? '').isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            ent['logo_url'].toString(),
                            width: 28,
                            height: 28,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      if ((ent['logo_url']?.toString() ?? '').isNotEmpty) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ent['nom_entreprise']?.toString() ?? '—',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A56DB),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoTag(Icons.location_on_outlined, loc.isEmpty ? '—' : loc),
                      _InfoTag(Icons.work_outline_rounded, contrat.isEmpty ? '—' : contrat),
                      if (domaine.isNotEmpty) _InfoTag(Icons.category_outlined, domaine),
                      if (sMin != null)
                        _InfoTag(
                          Icons.payments_outlined,
                          '${_fmtSalary(sMin)} - ${_fmtSalary(sMax ?? sMin)} $devise',
                        ),
                      _InfoTag(Icons.visibility_outlined, '$nbVues vues'),
                      _InfoTag(Icons.people_outline_rounded, '$nbCands candidats'),
                    ],
                  ),
                  if ((dateP != null && dateP.isNotEmpty) ||
                      (dateLim != null && dateLim.isNotEmpty)) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        if (dateP != null && dateP.isNotEmpty)
                          Text(
                            'Publié le ${_formatDate(dateP)}',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                          ),
                        if (dateLim != null && dateLim.isNotEmpty)
                          Text(
                            'Expire le ${_formatDate(dateLim)}',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                          ),
                      ],
                    ),
                  ],
                  if (statut == 'refusee' && raison != null && raison.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFFEF4444), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Motif du refus : $raison',
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF991B1B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (desc.isNotEmpty)
              _DetailSection(
                titre: 'Description du poste',
                couleur: const Color(0xFF1A56DB),
                child: Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF374151),
                    height: 1.6,
                  ),
                ),
              ),
            if (desc.isNotEmpty) const SizedBox(height: 14),
            if (exig.isNotEmpty) ...[
              _DetailSection(
                titre: 'Exigences & profil recherché',
                couleur: const Color(0xFF10B981),
                child: Text(
                  exig,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF374151),
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (comps.isNotEmpty)
              _DetailSection(
                titre: 'Compétences requises',
                couleur: const Color(0xFF8B5CF6),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: comps
                      .map(
                        (c) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F3FF),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: const Color(0xFFDDD6FE)),
                          ),
                          child: Text(
                            c,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6D28D9),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _fmtSalary(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }

  String _formatDate(String d) {
    try {
      final dt = DateTime.parse(d).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return d;
    }
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.titre,
    required this.couleur,
    required this.child,
  });

  final String titre;
  final Color couleur;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: couleur,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titre,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF64748B)),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF374151)),
          ),
        ],
      ),
    );
  }
}
