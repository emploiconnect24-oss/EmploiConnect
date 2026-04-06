import 'package:flutter/material.dart';
import '../../services/alertes_service.dart';
import '../../services/notifications_service.dart';
import 'candidat_job_search_screen.dart';

class CandidatJobAlertsScreen extends StatefulWidget {
  const CandidatJobAlertsScreen({super.key});

  @override
  State<CandidatJobAlertsScreen> createState() => _CandidatJobAlertsScreenState();
}

class _CandidatJobAlertsScreenState extends State<CandidatJobAlertsScreen> {
  final _svc = AlertesService();
  final _notifSvc = NotificationsService();
  final _nomCtrl = TextEditingController();
  final _keywordsCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();

  String _sector = 'Technologie';
  String _city = 'Conakry';
  String _frequency = 'Immédiatement';
  final Set<String> _contracts = <String>{'CDI'};

  List<_AlerteEmploi> _alerts = <_AlerteEmploi>[];
  List<String> _history = <String>[];
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
      final rows = await _svc.listAlertes();
      final notifs = await _notifSvc.getMesNotifications(limite: 50);
      final nData = (notifs['data'] as Map?)?.cast<String, dynamic>() ?? {};
      final nList = List<Map<String, dynamic>>.from(nData['notifications'] ?? const []);
      final history = nList
          .where((n) => const ['alerte', 'alerte_emploi', 'offre'].contains(n['type']))
          .take(6)
          .map((n) => '📬 ${(n['message'] ?? n['titre'] ?? '').toString()}')
          .toList();
      final mapped = rows.map((r) {
        final types = (r['types_contrat'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
        final k = (r['mots_cles'] ?? '').toString();
        final city = (r['localisation'] ?? r['ville'] ?? '—').toString();
        final firstType = types.isEmpty ? (r['type_contrat']?.toString() ?? 'CDI') : types.first;
        final displayName = (r['nom'] ?? '').toString().trim().isNotEmpty
            ? (r['nom'] ?? '').toString().trim()
            : (k.isNotEmpty ? k : 'Alerte emploi');
        final derniere = r['derniere_notif']?.toString();
        return _AlerteEmploi(
          id: (r['id'] ?? '').toString(),
          name: displayName,
          summary:
              'Mots-clés: ${k.isEmpty ? '—' : k} · ${(r['secteur'] ?? r['domaine'] ?? '—')} · $city · $firstType',
          frequency: (r['frequence'] ?? 'Immédiatement').toString(),
          lastNotification: derniere != null && derniere.isNotEmpty ? derniere : null,
          isActive: r['est_active'] != false,
          keywords: k,
          city: city == '—' ? 'Conakry' : city,
          contract: firstType,
          secteur: (r['secteur'] ?? r['domaine'] ?? 'Technologie').toString(),
          typesContrat: types.isEmpty && r['type_contrat'] != null ? [r['type_contrat'].toString()] : types,
          salaireMin: r['salaire_min'],
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _alerts = mapped;
        _history = history;
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
  void dispose() {
    _nomCtrl.dispose();
    _keywordsCtrl.dispose();
    _salaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _createAlert() async {
    final nom = _nomCtrl.text.trim();
    final raw = _keywordsCtrl.text.trim();
    if (nom.isEmpty && raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indiquez un nom d’alerte ou des mots-clés.')),
      );
      return;
    }
    if (_contracts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez au moins un type de contrat.')),
      );
      return;
    }
    try {
      await _svc.createAlerte({
        if (nom.isNotEmpty) 'nom': nom,
        'mots_cles': raw.isEmpty ? null : raw,
        'secteur': _sector,
        'ville': _city,
        'localisation': _city,
        'domaine': _sector,
        'salaire_min': _salaryCtrl.text.trim().isEmpty ? null : double.tryParse(_salaryCtrl.text.trim()),
        'types_contrat': _contracts.toList(),
        'frequence': _frequency,
        'est_active': true,
      });
      if (!mounted) return;
      _nomCtrl.clear();
      _keywordsCtrl.clear();
      _salaryCtrl.clear();
      _contracts
        ..clear()
        ..add('CDI');
      _frequency = 'Immédiatement';
      _city = 'Conakry';
      _sector = 'Technologie';
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alerte créée avec succès.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final pagePad = EdgeInsets.fromLTRB(
      20,
      16,
      20,
      MediaQuery.of(context).size.width <= 900 ? 80 : 24,
    );
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: pagePad,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
        const Text('Alertes Emploi', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text(
          'Créez des alertes pour être notifié dès qu’une offre correspond à vos critères.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 8),
        Text(
          'Les alertes sont enregistrées sur le serveur (API candidat). Vous recevez des notifications lorsque de nouvelles offres correspondent à vos mots-clés et filtres.',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        _createForm(),
        const SizedBox(height: 16),
        const Text('Alertes actives', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (_alerts.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(child: Text('Aucune alerte active pour le moment.')),
          )
        else
          ..._alerts.map(_alertCard),
        const SizedBox(height: 16),
        const Text('Historique des notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _history
                .map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(h, style: const TextStyle(color: Color(0xFF334155))),
                  ),
                )
                .toList(),
          ),
        ),
      ],
      ),
    );
  }

  Widget _createForm() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Créer une alerte', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          TextField(
            controller: _nomCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom de l’alerte',
              hintText: 'Ex. Développeur mobile Conakry',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _keywordsCtrl,
            decoration: const InputDecoration(
              labelText: 'Mots-clés (optionnel si le nom suffit)',
              hintText: 'Flutter, Dart, Mobile',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  initialValue: _sector,
                  decoration: const InputDecoration(labelText: 'Secteur', isDense: true),
                  items: const ['Technologie', 'Finance', 'Télécom', 'Santé', 'Éducation']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _sector = v ?? _sector),
                ),
              ),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  initialValue: _city,
                  decoration: const InputDecoration(labelText: 'Ville', isDense: true),
                  items: const ['Conakry', 'Labé', 'Kindia', 'Kankan', 'Remote']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _city = v ?? _city),
                ),
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: _salaryCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Salaire min (optionnel)', isDense: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Type de contrat', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['CDI', 'CDD', 'Stage', 'Freelance']
                .map(
                  (t) => FilterChip(
                    label: Text(t),
                    selected: _contracts.contains(t),
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _contracts.add(t);
                        } else {
                          _contracts.remove(t);
                        }
                      });
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _frequency,
            decoration: const InputDecoration(labelText: 'Fréquence', isDense: true),
            items: const ['Immédiatement', 'Quotidien', 'Hebdomadaire']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _frequency = v ?? _frequency),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _createAlert,
            icon: const Icon(Icons.notifications_active_outlined, size: 16),
            label: const Text('Créer l’alerte'),
          ),
        ],
      ),
    );
  }

  Widget _alertCard(_AlerteEmploi alerte) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: alerte.isActive ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              color: alerte.isActive ? const Color(0xFF1A56DB) : const Color(0xFF94A3B8),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alerte.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(alerte.summary, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Fréquence: ${alerte.frequency}', style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
                    if (alerte.lastNotification != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Dernière notification: ${alerte.lastNotification}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Switch(
            value: alerte.isActive,
            onChanged: (v) async {
              try {
                await _svc.updateAlerte(alerte.id, {'est_active': v});
                if (!mounted) return;
                await _load();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            activeThumbColor: const Color(0xFF1A56DB),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'voir') {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CandidatJobSearchScreen(
                      initialKeyword: alerte.keywords,
                      initialVille: alerte.city,
                      initialContract: alerte.contract,
                    ),
                  ),
                );
                return;
              }
              if (value == 'modifier') {
                await _openEditAlerte(alerte);
                return;
              }
              if (value == 'supprimer') {
                try {
                  await _svc.deleteAlerte(alerte.id);
                  if (!mounted) return;
                  setState(() => _alerts.removeWhere((e) => e.id == alerte.id));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'voir', child: Text('Voir les offres')),
              PopupMenuItem(value: 'modifier', child: Text('Modifier')),
              PopupMenuItem(
                value: 'supprimer',
                child: Text('Supprimer', style: TextStyle(color: Color(0xFFEF4444))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openEditAlerte(_AlerteEmploi a) async {
    final nomCtrl = TextEditingController(text: a.name);
    final kwCtrl = TextEditingController(text: a.keywords ?? '');
    final salCtrl = TextEditingController(
      text: a.salaireMin is num ? '${a.salaireMin}' : '',
    );
    var sector = a.secteur;
    var city = a.city ?? 'Conakry';
    var frequency = a.frequency;
    final contracts = <String>{...a.typesContrat};

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Modifier l’alerte'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nomCtrl,
                  decoration: const InputDecoration(labelText: 'Nom', isDense: true),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: kwCtrl,
                  decoration: const InputDecoration(labelText: 'Mots-clés', isDense: true),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: sector,
                  decoration: const InputDecoration(labelText: 'Secteur', isDense: true),
                  items: const ['Technologie', 'Finance', 'Télécom', 'Santé', 'Éducation']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setLocal(() => sector = v ?? sector),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: city,
                  decoration: const InputDecoration(labelText: 'Ville', isDense: true),
                  items: const ['Conakry', 'Labé', 'Kindia', 'Kankan', 'Remote']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setLocal(() => city = v ?? city),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: salCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Salaire min (optionnel)', isDense: true),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: frequency,
                  decoration: const InputDecoration(labelText: 'Fréquence', isDense: true),
                  items: const ['Immédiatement', 'Quotidien', 'Hebdomadaire']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setLocal(() => frequency = v ?? frequency),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ['CDI', 'CDD', 'Stage', 'Freelance']
                      .map(
                        (t) => FilterChip(
                          label: Text(t),
                          selected: contracts.contains(t),
                          onSelected: (v) => setLocal(() {
                            if (v) {
                              contracts.add(t);
                            } else {
                              contracts.remove(t);
                            }
                          }),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) {
      nomCtrl.dispose();
      kwCtrl.dispose();
      salCtrl.dispose();
      return;
    }

    final nom = nomCtrl.text.trim();
    final kw = kwCtrl.text.trim();
    if (nom.isEmpty && kw.isEmpty) {
      nomCtrl.dispose();
      kwCtrl.dispose();
      salCtrl.dispose();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom ou mots-clés requis.')),
      );
      return;
    }
    if (contracts.isEmpty) {
      nomCtrl.dispose();
      kwCtrl.dispose();
      salCtrl.dispose();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Au moins un type de contrat.')),
      );
      return;
    }

    try {
      await _svc.updateAlerte(a.id, {
        if (nom.isNotEmpty) 'nom': nom,
        'mots_cles': kw.isEmpty ? null : kw,
        'secteur': sector,
        'ville': city,
        'localisation': city,
        'domaine': sector,
        'salaire_min': salCtrl.text.trim().isEmpty ? null : double.tryParse(salCtrl.text.trim()),
        'types_contrat': contracts.toList(),
        'frequence': frequency,
      });
      nomCtrl.dispose();
      kwCtrl.dispose();
      salCtrl.dispose();
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alerte mise à jour.')));
    } catch (e) {
      nomCtrl.dispose();
      kwCtrl.dispose();
      salCtrl.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _AlerteEmploi {
  _AlerteEmploi({
    required this.id,
    required this.name,
    required this.summary,
    required this.frequency,
    required this.lastNotification,
    required this.isActive,
    this.keywords,
    this.city,
    this.contract,
    this.secteur = 'Technologie',
    this.typesContrat = const ['CDI'],
    this.salaireMin,
  });

  final String id;
  final String name;
  final String summary;
  final String frequency;
  final String? lastNotification;
  final bool isActive;
  final String? keywords;
  final String? city;
  final String? contract;
  final String secteur;
  final List<String> typesContrat;
  final dynamic salaireMin;
}
