import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/offres_service.dart';
import '../../services/candidatures_service.dart';
import '../../widgets/signalement_content_sheet.dart';

class OffreDetailScreen extends StatefulWidget {
  const OffreDetailScreen({super.key, required this.offreId});

  final String offreId;

  @override
  State<OffreDetailScreen> createState() => _OffreDetailScreenState();
}

class _OffreDetailScreenState extends State<OffreDetailScreen> {
  final _offres = OffresService();
  final _cand = CandidaturesService();
  final _lettreCtrl = TextEditingController();
  Map<String, dynamic>? _offre;
  bool _loading = true;
  String? _error;
  bool _postulant = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _lettreCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final o = await _offres.getOffreById(widget.offreId);
      setState(() {
        _offre = o;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _postuler() async {
    setState(() => _postulant = true);
    try {
      await _cand.postuler(
        offreId: widget.offreId,
        lettreMotivation: _lettreCtrl.text.trim().isEmpty ? null : _lettreCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Candidature envoyée')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _postulant = false);
    }
  }

  Future<void> _signaler() async {
    await showSignalementContentDialog(
      context,
      typeObjet: 'offre',
      objetId: widget.offreId,
      dialogTitle: 'Signaler cette offre',
      description:
          'Indiquez pourquoi cette offre vous semble inappropriée, trompeuse ou contraire aux règles de la plateforme.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role;
    final isChercheur = role == 'chercheur';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail offre'),
        actions: [
          if (isChercheur)
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              onPressed: _signaler,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _offre == null
                  ? const Center(child: Text('Introuvable'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _offre!['titre']?.toString() ?? '',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _offre!['localisation']?.toString() ?? '',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _offre!['description']?.toString() ?? '',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Exigences',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(_offre!['exigences']?.toString() ?? ''),
                          if (isChercheur) ...[
                            const SizedBox(height: 24),
                            TextField(
                              controller: _lettreCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Lettre de motivation (optionnel)',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 4,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _postulant ? null : _postuler,
                                child: _postulant
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Postuler'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }
}
