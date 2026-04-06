import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/cv_service.dart';
import '../../services/recruteur_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/responsive_container.dart';
import '../../widgets/signalement_content_sheet.dart';
import 'recruteur_messagerie_connected_screen.dart';

class RecruteurCandidatureDetailScreen extends StatefulWidget {
  const RecruteurCandidatureDetailScreen({super.key, required this.candidatureId});
  final String candidatureId;

  @override
  State<RecruteurCandidatureDetailScreen> createState() => _RecruteurCandidatureDetailScreenState();
}

class _RecruteurCandidatureDetailScreenState extends State<RecruteurCandidatureDetailScreen> {
  final _service = RecruteurService();
  final _cvService = CvService();

  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  bool _savingAction = false;
  final List<String> _timeline = []; // événements locaux (UI)

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await _service.getCandidature(token, widget.candidatureId);
      final d = (res['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      setState(() {
        _data = d;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _labelStatut(String? raw) {
    final s = (raw ?? '').toLowerCase().trim();
    switch (s) {
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
      default:
        return (raw == null || raw.isEmpty) ? '—' : raw;
    }
  }

  Color _statutColor(String? raw) {
    final s = (raw ?? '').toLowerCase().trim();
    switch (s) {
      case 'acceptee':
        return const Color(0xFF10B981);
      case 'refusee':
        return const Color(0xFFEF4444);
      case 'entretien':
        return const Color(0xFF7C3AED);
      case 'en_cours':
        return const Color(0xFF1D4ED8);
      case 'en_attente':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  /// Libellés / icônes PRD §3 (carte profil candidat).
  ({Color color, String label, IconData icon}) _statutPresentation(String? raw) {
    final s = (raw ?? '').toLowerCase().trim();
    switch (s) {
      case 'en_attente':
        return (color: const Color(0xFFF59E0B), label: 'En attente de réponse', icon: Icons.hourglass_empty_rounded);
      case 'en_cours':
        return (color: const Color(0xFF1A56DB), label: 'Candidature en examen', icon: Icons.search_rounded);
      case 'entretien':
        return (color: const Color(0xFF8B5CF6), label: 'Entretien planifié', icon: Icons.event_available_rounded);
      case 'acceptee':
        return (color: const Color(0xFF10B981), label: 'Candidature acceptée ✓', icon: Icons.check_circle_rounded);
      case 'refusee':
        return (color: const Color(0xFFEF4444), label: 'Candidature refusée', icon: Icons.cancel_rounded);
      default:
        return (color: const Color(0xFF94A3B8), label: _labelStatut(raw), icon: Icons.circle_outlined);
    }
  }

  Future<void> _action(
    String action, {
    String? dateEntretien,
    String? lienVisio,
    String? raisonRefus,
    String? typeEntretien,
    String? lieuEntretien,
    String? notesEntretien,
  }) async {
    if (_savingAction) return;
    try {
      setState(() => _savingAction = true);
      final token = context.read<AuthProvider>().token ?? '';
      final res = await _service.actionCandidature(
        token,
        widget.candidatureId,
        action,
        dateEntretien: dateEntretien,
        lienVisio: lienVisio,
        raisonRefus: raisonRefus,
        typeEntretien: typeEntretien,
        lieuEntretien: lieuEntretien,
        notesEntretien: notesEntretien,
      );
      final saved = (res['data'] as Map?)?.cast<String, dynamic>();
      setState(() {
        if (saved != null) _data = saved;
        _timeline.insert(0, 'Action: $action');
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action appliquée')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _savingAction = false);
    }
  }

  String _normalizeEntretienType(String? raw) {
    final s = (raw ?? '').toLowerCase().trim();
    if (s.contains('present')) return 'presentiel';
    if (s.contains('tel') || s.contains('phone') || s == 'telephone') return 'telephone';
    if (s.isEmpty) return 'visio';
    return 'visio';
  }

  String _labelTypeEntretien(String t) {
    switch (t) {
      case 'presentiel':
        return 'Sur place';
      case 'telephone':
        return 'Téléphone';
      default:
        return 'Visioconférence';
    }
  }

  Future<void> _showPlanifierEntretienDialog() async {
    final d0 = _data ?? {};
    var day = DateTime.tryParse(d0['date_entretien']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 2));
    TimeOfDay time = TimeOfDay.fromDateTime(
      DateTime.tryParse(d0['date_entretien']?.toString() ?? '') ?? DateTime.now(),
    );
    String type = _normalizeEntretienType(d0['type_entretien']?.toString());
    final lienCtrl = TextEditingController(text: d0['lien_visio']?.toString() ?? '');
    final lieuCtrl = TextEditingController(text: d0['lieu_entretien']?.toString() ?? '');
    final notesCtrl = TextEditingController(text: d0['notes_entretien']?.toString() ?? '');
    final stepRef = <int>[0];

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final step = stepRef[0];
          final dt = DateTime(day.year, day.month, day.day, time.hour, time.minute);
          final isoPreview = dt.toIso8601String();
          final lv = type == 'visio' ? lienCtrl.text.trim() : null;
          final lu = (type == 'presentiel' || type == 'telephone') ? lieuCtrl.text.trim() : null;
          final notesPreview = notesCtrl.text.trim();

          Widget recapBlock() {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Récapitulatif', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 10),
                  _RecapLine(Icons.event_outlined, 'Date et heure', '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year} · ${time.format(ctx)}'),
                  _RecapLine(Icons.category_outlined, 'Type', _labelTypeEntretien(type)),
                  if (type == 'visio' && (lv ?? '').isNotEmpty)
                    _RecapLine(Icons.link, 'Lien visio', lv!),
                  if ((type == 'presentiel' || type == 'telephone') && (lu ?? '').isNotEmpty)
                    _RecapLine(type == 'presentiel' ? Icons.place_outlined : Icons.phone_outlined, type == 'presentiel' ? 'Lieu' : 'Coordonnées', lu!),
                  if (notesPreview.isNotEmpty)
                    _RecapLine(Icons.notes_outlined, 'Notes', notesPreview),
                ],
              ),
            );
          }

          return AlertDialog(
            title: Text(
              step == 0 ? 'Planifier un entretien' : 'Confirmer l\'entretien',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 420,
                child: step == 0
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Date', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12)),
                          const SizedBox(height: 6),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: day,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) setDlg(() => day = picked);
                            },
                            icon: const Icon(Icons.calendar_today_outlined, size: 18),
                            label: Text(
                              '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('Heure', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12)),
                          const SizedBox(height: 6),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showTimePicker(context: ctx, initialTime: time);
                              if (picked != null) setDlg(() => time = picked);
                            },
                            icon: const Icon(Icons.schedule, size: 18),
                            label: Text(time.format(ctx)),
                          ),
                          const SizedBox(height: 14),
                          Text('Type', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12)),
                          const SizedBox(height: 6),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'visio', label: Text('Visio'), icon: Icon(Icons.videocam_outlined, size: 16)),
                              ButtonSegment(value: 'presentiel', label: Text('Sur place'), icon: Icon(Icons.place_outlined, size: 16)),
                              ButtonSegment(value: 'telephone', label: Text('Tél.'), icon: Icon(Icons.phone_outlined, size: 16)),
                            ],
                            selected: {type},
                            onSelectionChanged: (s) => setDlg(() => type = s.first),
                          ),
                          const SizedBox(height: 12),
                          if (type == 'visio') ...[
                            TextField(
                              controller: lienCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Lien visio (Meet, Teams…)',
                                isDense: true,
                              ),
                            ),
                          ] else if (type == 'presentiel') ...[
                            TextField(
                              controller: lieuCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Adresse ou salle',
                                isDense: true,
                              ),
                            ),
                          ] else ...[
                            TextField(
                              controller: lieuCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Numéro ou indicatif (optionnel)',
                                isDense: true,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          TextField(
                            controller: notesCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Notes (visibles par le candidat dans la notification)',
                              alignLabelWithHint: true,
                              isDense: true,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Vérifiez les informations avant envoi au candidat.',
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 14),
                          recapBlock(),
                        ],
                      ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              if (step == 0)
                FilledButton(
                  onPressed: () => setDlg(() => stepRef[0] = 1),
                  child: const Text('Voir le récapitulatif'),
                )
              else ...[
                TextButton(onPressed: () => setDlg(() => stepRef[0] = 0), child: const Text('Modifier')),
                FilledButton(
                  onPressed: _savingAction
                      ? null
                      : () async {
                          final notes = notesPreview.isEmpty ? null : notesPreview;
                          Navigator.pop(ctx);
                          await _action(
                            'planifier_entretien',
                            dateEntretien: isoPreview,
                            lienVisio: lv,
                            typeEntretien: type,
                            lieuEntretien: lu,
                            notesEntretien: notes,
                          );
                        },
                  child: const Text('Confirmer et envoyer'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _showCv() async {
    try {
      final url = await _cvService.getDownloadUrl(candidatureId: widget.candidatureId);
      if (!mounted) return;
      if (url == null || url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucun CV disponible')));
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Lien CV'),
          content: SelectableText(url),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 60) return const Color(0xFF1A56DB);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  List<String> _asStringList(dynamic v) {
    if (v == null) return const [];
    if (v is List) return v.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return const [];
      // tentative: "a, b, c"
      if (s.contains(',')) return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      return [s];
    }
    return [v.toString()];
  }

  String _fmtDateTime(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Future<void> _confirmRefus() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refuser la candidature'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Raison (optionnel)',
            alignLabelWithHint: true,
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
    if (ok != true) return;
    await _action('refuser', raisonRefus: ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final d = _data ?? <String, dynamic>{};
    final chercheur = (d['chercheur'] as Map?)?.cast<String, dynamic>();
    final user = (chercheur?['utilisateur'] as Map?)?.cast<String, dynamic>();
    final offre = (d['offre'] as Map?)?.cast<String, dynamic>();
    final cv = (d['cv'] as Map?)?.cast<String, dynamic>();

    final fullName = (user?['nom'] ?? 'Candidat').toString();
    final offerTitle = (offre?['titre'] ?? 'Offre').toString();
    final email = (user?['email'] ?? '—').toString();
    final phone = (user?['telephone'] ?? '—').toString();
    final address = (user?['adresse'] ?? '—').toString();
    final city = (offre?['localisation'] ?? '—').toString();
    final dispo = (chercheur?['disponibilite'] ?? 'Non précisée').toString();
    final niveauEtude = (chercheur?['niveau_etude'] ?? '—').toString();
    final statut = d['statut']?.toString();
    final score = (d['score_compatibilite'] as num?)?.toInt() ?? 0;
    final motivation = (d['lettre_motivation'] ?? '').toString();
    final skills = _asStringList(chercheur?['competences'] ?? cv?['competences_extrait']);
    final entretienStr = d['date_entretien']?.toString();
    final entretienDt = entretienStr == null ? null : DateTime.tryParse(entretienStr);
    final lienVisio = d['lien_visio']?.toString();
    final typeEnt = d['type_entretien']?.toString();
    final lieuEnt = d['lieu_entretien']?.toString();
    final notesEnt = d['notes_entretien']?.toString();
    final createdStr = d['date_candidature']?.toString();
    final createdDt = createdStr == null ? null : DateTime.tryParse(createdStr);

    final headlineStyle = GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900);
    final subStyle = GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569));

    return ResponsiveContainer(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: const Color(0xFF0B1220),
              leading: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              actions: [
                IconButton(
                  tooltip: 'Signaler cette candidature',
                  icon: const Icon(Icons.flag_outlined, color: Colors.white),
                  onPressed: _loading
                      ? null
                      : () => showSignalementContentDialog(
                            context,
                            typeObjet: 'candidature',
                            objetId: widget.candidatureId,
                            dialogTitle: 'Signaler cette candidature',
                            description:
                                'Signalement réservé à la modération (fausse identité, CV frauduleux, contenu inapproprié, harcèlement, etc.).',
                          ),
                ),
              ],
              title: Text(
                'Détail candidature',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(92),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0B1220), Color(0xFF0F2A5F)],
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFDBEAFE),
                        child: Text(
                          fullName.trim().isEmpty ? '?' : fullName.trim()[0].toUpperCase(),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFF1E40AF)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            Text(
                              offerTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(color: const Color(0xFFBFDBFE), fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      _KpiPill(
                        label: 'Score IA',
                        value: '$score%',
                        color: _scoreColor(score),
                      ),
                      const SizedBox(width: 8),
                      _KpiPill(
                        label: 'Statut',
                        value: _labelStatut(statut),
                        color: _statutColor(statut),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                child: Builder(
                  builder: (_) {
                    if (_loading) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (_error != null) {
                      return _SectionCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
                              const SizedBox(width: 10),
                              Expanded(child: Text(_error!, style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
                              TextButton(onPressed: _load, child: const Text('Réessayer')),
                            ],
                          ),
                        ),
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, c) {
                        final twoCols = c.maxWidth >= 1100;
                        final st = _statutPresentation(statut);
                        final photoUrl = user?['photo_url']?.toString();

                        void openMessagerie() {
                          final peerId = user?['id']?.toString();
                          if (peerId == null || peerId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Utilisateur candidat introuvable.')),
                            );
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => RecruteurMessagerieConnectedScreen(
                                initialPeerId: peerId,
                                initialPeerName: fullName,
                              ),
                            ),
                          );
                        }

                        final profilCard = _CandidatProfilCard(
                          fullName: fullName,
                          email: email,
                          phone: phone,
                          address: address,
                          dispo: dispo,
                          niveauEtude: niveauEtude,
                          score: score,
                          statusColor: st.color,
                          statusLabel: st.label,
                          statusIcon: st.icon,
                          photoUrl: photoUrl,
                          createdDt: createdDt,
                          entretienDt: entretienDt,
                          typeEnt: typeEnt,
                          lienVisio: lienVisio,
                          lieuEnt: lieuEnt,
                          notesEnt: notesEnt,
                          fmtDateTime: _fmtDateTime,
                          scoreColor: _scoreColor(score),
                          onRefresh: _load,
                          onMessage: openMessagerie,
                        );

                        final actionsCard = _SectionCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text('Actions', style: headlineStyle)),
                                    if (_savingAction) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _ActionTile(
                                  title: 'Mettre en examen',
                                  subtitle: 'Passe la candidature en “En cours”.',
                                  icon: Icons.fact_check_outlined,
                                  color: const Color(0xFF1D4ED8),
                                  onTap: () => _action('mettre_en_examen'),
                                ),
                                const SizedBox(height: 8),
                                _ActionTile(
                                  title: 'Planifier un entretien',
                                  subtitle: entretienDt == null
                                      ? 'Date, heure, type (visio, présentiel, téléphone) et notes.'
                                      : _fmtDateTime(entretienDt),
                                  icon: Icons.event_available_outlined,
                                  color: const Color(0xFF7C3AED),
                                  onTap: _showPlanifierEntretienDialog,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                                        onPressed: _savingAction ? null : () => _action('accepter'),
                                        child: const Text('Accepter'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                                        onPressed: _savingAction ? null : _confirmRefus,
                                        child: const Text('Refuser'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );

                        final cvCard = _SectionCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('CV', style: headlineStyle),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.description_outlined, color: Color(0xFF1D4ED8)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        (cv?['nom_fichier'] ?? 'CV').toString(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    FilledButton.icon(
                                      onPressed: _showCv,
                                      icon: const Icon(Icons.download_outlined),
                                      label: const Text('Télécharger'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );

                        final offreCard = _SectionCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Offre concernée', style: headlineStyle),
                                const SizedBox(height: 10),
                                Text(
                                  offerTitle,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (city.isNotEmpty && city != '—')
                                      _InfoChip(icon: Icons.location_on_outlined, label: city),
                                    if ((offre?['type_contrat']?.toString() ?? '').isNotEmpty)
                                      _InfoChip(
                                        icon: Icons.badge_outlined,
                                        label: offre?['type_contrat']?.toString() ?? '',
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );

                        final lettreCard = _SectionCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Lettre de motivation', style: headlineStyle),
                                const SizedBox(height: 10),
                                if (motivation.trim().isEmpty)
                                  Text('Aucune lettre fournie.', style: subStyle)
                                else
                                  Text(motivation, style: GoogleFonts.inter(height: 1.35, color: const Color(0xFF0F172A))),
                              ],
                            ),
                          ),
                        );

                        final competencesCard = _SectionCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Compétences', style: headlineStyle),
                                const SizedBox(height: 10),
                                if (skills.isEmpty)
                                  Text('Aucune compétence fournie.', style: subStyle)
                                else
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: skills.map((s) => _SkillChip(text: s)).toList(),
                                  ),
                              ],
                            ),
                          ),
                        );

                        final historiqueCard = _SectionCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Historique', style: headlineStyle),
                                const SizedBox(height: 10),
                                if (_timeline.isEmpty)
                                  Text('Aucune action enregistrée côté UI.', style: subStyle)
                                else
                                  ..._timeline.map(
                                    (e) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.history, size: 18, color: Color(0xFF64748B)),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(e, style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );

                        // PRD §3 : gauche = profil + actions + CV ; droite = offre + lettre + compétences.
                        final leftCol = Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            profilCard,
                            const SizedBox(height: 12),
                            actionsCard,
                            const SizedBox(height: 12),
                            cvCard,
                          ],
                        );

                        final rightCol = Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            offreCard,
                            const SizedBox(height: 12),
                            lettreCard,
                            const SizedBox(height: 12),
                            competencesCard,
                          ],
                        );

                        if (!twoCols) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              leftCol,
                              const SizedBox(height: 12),
                              rightCol,
                              const SizedBox(height: 12),
                              historiqueCard,
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 38, child: leftCol),
                                const SizedBox(width: 16),
                                Expanded(flex: 62, child: rightCol),
                              ],
                            ),
                            const SizedBox(height: 12),
                            historiqueCard,
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// PRD §3 — Carte profil (avatar + score, statut, contact, message).
class _CandidatProfilCard extends StatelessWidget {
  const _CandidatProfilCard({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.dispo,
    required this.niveauEtude,
    required this.score,
    required this.statusColor,
    required this.statusLabel,
    required this.statusIcon,
    this.photoUrl,
    this.createdDt,
    this.entretienDt,
    this.typeEnt,
    this.lienVisio,
    this.lieuEnt,
    this.notesEnt,
    required this.fmtDateTime,
    required this.scoreColor,
    required this.onRefresh,
    required this.onMessage,
  });

  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String dispo;
  final String niveauEtude;
  final int score;
  final Color statusColor;
  final String statusLabel;
  final IconData statusIcon;
  final String? photoUrl;
  final DateTime? createdDt;
  final DateTime? entretienDt;
  final String? typeEnt;
  final String? lienVisio;
  final String? lieuEnt;
  final String? notesEnt;
  final String Function(DateTime) fmtDateTime;
  final Color scoreColor;
  final VoidCallback onRefresh;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;

    return _SectionCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Profil candidat', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900))),
                IconButton(tooltip: 'Actualiser', onPressed: onRefresh, icon: const Icon(Icons.refresh)),
              ],
            ),
            const SizedBox(height: 4),
            Center(
              child: SizedBox(
                width: 104,
                height: 92,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: const Color(0xFF1A56DB).withValues(alpha: 0.12),
                      backgroundImage: hasPhoto ? NetworkImage(photoUrl!.trim()) : null,
                      onBackgroundImageError: hasPhoto ? (error, stackTrace) {} : null,
                      child: !hasPhoto
                          ? Text(
                              fullName.trim().isEmpty ? '?' : fullName.trim()[0].toUpperCase(),
                              style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w800, color: const Color(0xFF1A56DB)),
                            )
                          : null,
                    ),
                    if (score > 0)
                      Positioned(
                        top: -2,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [scoreColor, scoreColor.withValues(alpha: 0.78)],
                            ),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome_rounded, size: 10, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(
                                '$score%',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              fullName,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 13, color: statusColor),
                    const SizedBox(width: 5),
                    Text(statusLabel, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (email.isNotEmpty && email != '—') _ContactRowProfil(icon: Icons.email_outlined, text: email),
            if (phone.isNotEmpty && phone != '—') _ContactRowProfil(icon: Icons.phone_outlined, text: phone),
            if (address.isNotEmpty && address != '—') _ContactRowProfil(icon: Icons.location_on_outlined, text: address),
            _ContactRowProfil(icon: Icons.schedule_outlined, text: 'Dispo : $dispo'),
            if (niveauEtude.isNotEmpty && niveauEtude != '—') _ContactRowProfil(icon: Icons.school_outlined, text: niveauEtude),
            if (createdDt != null) _ContactRowProfil(icon: Icons.event_outlined, text: 'Reçue : ${fmtDateTime(createdDt!)}'),
            if (entretienDt != null) _ContactRowProfil(icon: Icons.event_available_outlined, text: 'Entretien : ${fmtDateTime(entretienDt!)}'),
            if (typeEnt != null && typeEnt!.trim().isNotEmpty) _ContactRowProfil(icon: Icons.category_outlined, text: 'Type : $typeEnt'),
            if (lieuEnt != null && lieuEnt!.trim().isNotEmpty) _ContactRowProfil(icon: Icons.place_outlined, text: lieuEnt!.trim()),
            if (lienVisio != null && lienVisio!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Lien visio', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12)),
              SelectableText(lienVisio!.trim(), style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1D4ED8))),
            ],
            if (notesEnt != null && notesEnt!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notes entretien', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 12)),
              Text(notesEnt!.trim(), style: GoogleFonts.inter(color: const Color(0xFF334155))),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onMessage,
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: Text('Envoyer un message', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRowProfil extends StatelessWidget {
  const _ContactRowProfil({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), height: 1.35))),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0F172A), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
    );
  }
}

class _KpiPill extends StatelessWidget {
  const _KpiPill({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.72), fontSize: 10, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF334155)),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: const Color(0xFF1E40AF))),
    );
  }
}

class _RecapLine extends StatelessWidget {
  const _RecapLine(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF64748B))),
                Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
