import 'package:flutter/material.dart';

import '../../services/candidat_temoignage_service.dart';

/// Formulaire volontaire après recrutement (notification « Partagez votre expérience »).
class CandidatTemoignageScreen extends StatefulWidget {
  const CandidatTemoignageScreen({super.key, this.initialCandidatureId});

  final String? initialCandidatureId;

  @override
  State<CandidatTemoignageScreen> createState() => _CandidatTemoignageScreenState();
}

class _CandidatTemoignageScreenState extends State<CandidatTemoignageScreen> {
  final _svc = CandidatTemoignageService();
  final _textCtrl = TextEditingController();
  List<Map<String, dynamic>> _eligible = [];
  String? _selectedCandidatureId;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _svc.getEligible();
      if (!mounted) return;
      final initial = widget.initialCandidatureId?.trim();
      String? sel;
      if (initial != null && initial.isNotEmpty) {
        final ok = list.any((e) => (e['candidature_id']?.toString() ?? '') == initial);
        if (ok) sel = initial;
      }
      sel ??= list.isNotEmpty ? list.first['candidature_id']?.toString() : null;
      setState(() {
        _eligible = list;
        _selectedCandidatureId = sel;
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

  Future<void> _submit() async {
    final cid = _selectedCandidatureId?.trim();
    final msg = _textCtrl.text.trim();
    if (cid == null || cid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez une candidature acceptée.')),
      );
      return;
    }
    if (msg.length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum 20 caractères.')),
      );
      return;
    }
    if (msg.length > 800) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 800 caractères.')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await _svc.submit(candidatureId: cid, message: msg);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Merci ! Votre témoignage a été envoyé. Il apparaîtra sur la page d’accueil après validation par un administrateur.',
          ),
          backgroundColor: Color(0xFF059669),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partager mon expérience'),
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
              : _eligible.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Vous n’avez pas de candidature acceptée en attente de témoignage, '
                          'ou vous avez déjà partagé votre retour pour chaque embauche.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700, height: 1.45),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottom),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Votre retour aide les futurs candidats et valorise l’entreprise qui vous a recruté(e). '
                              'Après validation par la modération, il pourra être affiché sur la page d’accueil avec votre prénom / nom et photo de profil.',
                              style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 20),
                            LayoutBuilder(
                              builder: (context, c) {
                                return DropdownMenu<String>(
                                  width: c.maxWidth,
                                  key: ValueKey(_selectedCandidatureId ?? 'none'),
                                  initialSelection: _selectedCandidatureId,
                                  label: const Text('Candidature concernée'),
                                  dropdownMenuEntries: [
                                    for (final e in _eligible)
                                      DropdownMenuEntry<String>(
                                        value: e['candidature_id']?.toString() ?? '',
                                        label:
                                            '${e['entreprise_nom'] ?? 'Entreprise'} — ${e['offre_titre'] ?? 'Offre'}',
                                      ),
                                  ],
                                  onSelected: (v) {
                                    if (v != null && v.isNotEmpty) {
                                      setState(() => _selectedCandidatureId = v);
                                    }
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _textCtrl,
                              maxLines: 8,
                              maxLength: 800,
                              decoration: const InputDecoration(
                                labelText: 'Votre témoignage',
                                hintText:
                                    'Ex. : entretien bienveillant, délais de réponse, intégration… (20 à 800 caractères)',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: _sending ? null : _submit,
                              icon: _sending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.send_rounded),
                              label: Text(_sending ? 'Envoi…' : 'Envoyer pour validation'),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }
}
