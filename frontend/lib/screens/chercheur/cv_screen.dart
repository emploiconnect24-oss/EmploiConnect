import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../services/cv_service.dart';
import '../../widgets/responsive_container.dart';
import '../../widgets/reveal_on_scroll.dart';
import '../../widgets/hover_scale.dart';

class CvScreen extends StatefulWidget {
  const CvScreen({super.key});

  @override
  State<CvScreen> createState() => _CvScreenState();
}

class _CvScreenState extends State<CvScreen> {
  final _cv = CvService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _uploading = false;
  String? _error;
  String? _lastFileName;

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
      final d = await _cv.getMonCv();
      setState(() {
        _data = d;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      final msg = e.toString();
      final noCv = msg.contains('404') || msg.contains('Aucun CV');
      setState(() {
        _data = null;
        _error = noCv ? null : msg;
        _loading = false;
      });
    }
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    final bytes = f.bytes;
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de lire le fichier')),
        );
      }
      return;
    }
    final name = f.name;
    setState(() => _lastFileName = name);
    setState(() => _uploading = true);
    try {
      await _cv.uploadCv(bytes, name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CV envoyé et analysé')),
        );
      }
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final scheme = Theme.of(context).colorScheme;
    const orange = Color(0xFFFF8A00);

    final nomFichier = _data?['nom_fichier']?.toString();
    final typeFichier = _data?['type_fichier']?.toString();
    final competences = _data?['competences_extrait'];
    final domaine = _data?['domaine_activite']?.toString();
    final niveau = _data?['niveau_experience']?.toString();

    return ResponsiveContainer(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Text(
              'Mon CV',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Téléversez votre CV pour améliorer les suggestions et le matching.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            RevealOnScroll(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Téléversement', style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      Text(
                        _lastFileName != null ? 'Dernier fichier choisi : $_lastFileName' : 'Formats acceptés : PDF, DOCX',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: HoverScale(
                              onTap: _uploading ? null : _pickAndUpload,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: _uploading ? null : _pickAndUpload,
                                icon: _uploading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.upload_file),
                                label: Text(_uploading ? 'Envoi…' : 'Téléverser un CV'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _uploading ? null : _load,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Actualiser'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Conseil : un CV à jour augmente la qualité du matching.',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      if (_error != null && _data == null) ...[
                        const SizedBox(height: 10),
                        Text(_error!, style: TextStyle(color: scheme.error)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_data == null && _error == null)
              Padding(
                padding: const EdgeInsets.only(top: 26),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.description_outlined, size: 46, color: scheme.onSurfaceVariant),
                      const SizedBox(height: 10),
                      const Text('Aucun CV pour le moment.', style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text(
                        'Téléversez votre CV pour extraire vos compétences automatiquement.',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (_data != null)
              RevealOnScroll(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Résumé', style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _InfoChip(icon: Icons.insert_drive_file, label: nomFichier ?? '—'),
                            _InfoChip(icon: Icons.article_outlined, label: 'Type : ${typeFichier ?? '—'}'),
                            if (domaine != null && domaine.isNotEmpty)
                              _InfoChip(icon: Icons.category_outlined, label: 'Domaine : $domaine'),
                            if (niveau != null && niveau.isNotEmpty)
                              _InfoChip(icon: Icons.trending_up, label: 'Niveau : $niveau'),
                          ],
                        ),
                        if (competences != null) ...[
                          const SizedBox(height: 12),
                          const Text('Compétences extraites', style: TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          Text(
                            competences.toString(),
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 22),
          ],
        ),
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
