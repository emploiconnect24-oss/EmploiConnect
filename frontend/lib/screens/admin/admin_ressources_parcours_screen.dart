import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../services/admin_service.dart';
import 'widgets/admin_page_shimmer.dart' show AdminListScreenShimmer;

/// Administration des ressources Parcours Carrière (PRD §3).
class AdminRessourcesParcoursScreen extends StatefulWidget {
  const AdminRessourcesParcoursScreen({super.key});

  @override
  State<AdminRessourcesParcoursScreen> createState() => _AdminRessourcesParcoursScreenState();
}

class _AdminRessourcesParcoursScreenState extends State<AdminRessourcesParcoursScreen> {
  final _admin = AdminService();
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;
  String _filtreCategorie = 'tous';

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
      final r = await _admin.getRessourcesParcoursAdmin();
      if (!mounted) return;
      setState(() {
        _list = List<Map<String, dynamic>>.from(r['data'] as List? ?? []);
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

  List<Map<String, dynamic>> get _filtrees => _filtreCategorie == 'tous'
      ? _list
      : _list.where((r) => r['categorie']?.toString() == _filtreCategorie).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Parcours Carrière', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800)),
                    Text('${_list.length} ressource(s)', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _dialogRessource(null),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nouvelle ressource'),
              ),
            ],
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('tous', 'Toutes'),
                _chip('cv', 'CV'),
                _chip('entretien', 'Entretien'),
                _chip('salaire', 'Salaire'),
                _chip('reconversion', 'Reconversion'),
                _chip('entrepreneuriat', 'Entrepreneuriat'),
                _chip('general', 'Général'),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const AdminListScreenShimmer(showHeaderAction: false, tableRows: 6)
              : _error != null
                  ? Center(child: Text(_error!))
                  : _filtrees.isEmpty
                      ? const Center(child: Text('Aucune ressource'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtrees.length,
                          itemBuilder: (ctx, i) {
                            final r = _filtrees[i];
                            final id = r['id']?.toString() ?? '';
                            final pub = r['est_publie'] == true;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                title: Text(r['titre']?.toString() ?? '—', style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text(
                                  '${r['type_ressource']} · ${r['categorie']} · ${pub ? 'Publié' : 'Brouillon'}',
                                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                ),
                                isThreeLine: false,
                                trailing: Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      tooltip: pub ? 'Dépublier' : 'Publier',
                                      onPressed: () async {
                                        try {
                                          await _admin.patchPublierRessourceParcoursAdmin(id, !pub);
                                          await _load();
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                          }
                                        }
                                      },
                                      icon: Icon(pub ? Icons.visibility_off_outlined : Icons.publish_rounded),
                                    ),
                                    IconButton(
                                      tooltip: 'Supprimer',
                                      onPressed: () async {
                                        final ok = await showDialog<bool>(
                                          context: context,
                                          builder: (c) => AlertDialog(
                                            title: const Text('Supprimer ?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
                                              FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Supprimer')),
                                            ],
                                          ),
                                        );
                                        if (ok != true) return;
                                        try {
                                          await _admin.deleteRessourceParcoursAdmin(id);
                                          await _load();
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                                    ),
                                  ],
                                ),
                                onTap: () => _dialogRessource(r),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _chip(String val, String label) {
    final sel = _filtreCategorie == val;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: sel,
        onSelected: (_) => setState(() => _filtreCategorie = val),
      ),
    );
  }

  Future<void> _dialogRessource(Map<String, dynamic>? existing) async {
    final titre = TextEditingController(text: existing?['titre']?.toString() ?? '');
    final description = TextEditingController(text: existing?['description']?.toString() ?? '');
    final contenu = TextEditingController(text: existing?['contenu']?.toString() ?? '');
    final urlExterne = TextEditingController(text: existing?['url_externe']?.toString() ?? '');
    final dureeCtrl = TextEditingController(
      text: existing?['duree_minutes'] != null ? '${existing!['duree_minutes']}' : '',
    );
    final tags = TextEditingController(text: (existing?['tags'] as List?)?.join(', ') ?? '');
    String type = existing?['type_ressource']?.toString() ?? 'article';
    String categorie = existing?['categorie']?.toString() ?? 'general';
    String niveau = existing?['niveau']?.toString() ?? 'tous';
    bool publie = existing?['est_publie'] == true;
    bool misEnAvant = existing?['est_mis_en_avant'] == true;
    PlatformFile? fichier;
    PlatformFile? couverture;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? 'Nouvelle ressource' : 'Modifier la ressource'),
          content: SizedBox(
            width: 520,
            height: MediaQuery.sizeOf(ctx).height * 0.82,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(controller: titre, decoration: const InputDecoration(labelText: 'Titre *')),
                  const SizedBox(height: 8),
                  TextField(controller: description, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(value: 'article', child: Text('Article')),
                      DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                      DropdownMenuItem(value: 'video_youtube', child: Text('Vidéo YouTube')),
                      DropdownMenuItem(value: 'video_interne', child: Text('Vidéo interne')),
                      DropdownMenuItem(value: 'conseil_ia', child: Text('Conseil IA')),
                    ],
                    onChanged: (v) => setS(() => type = v ?? type),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: categorie,
                    decoration: const InputDecoration(labelText: 'Catégorie'),
                    items: const [
                      DropdownMenuItem(value: 'cv', child: Text('CV')),
                      DropdownMenuItem(value: 'entretien', child: Text('Entretien')),
                      DropdownMenuItem(value: 'salaire', child: Text('Salaire')),
                      DropdownMenuItem(value: 'reconversion', child: Text('Reconversion')),
                      DropdownMenuItem(value: 'entrepreneuriat', child: Text('Entrepreneuriat')),
                      DropdownMenuItem(value: 'general', child: Text('Général')),
                    ],
                    onChanged: (v) => setS(() => categorie = v ?? categorie),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: niveau,
                    decoration: const InputDecoration(labelText: 'Niveau'),
                    items: const [
                      DropdownMenuItem(value: 'tous', child: Text('Tous')),
                      DropdownMenuItem(value: 'debutant', child: Text('Débutant')),
                      DropdownMenuItem(value: 'intermediaire', child: Text('Intermédiaire')),
                      DropdownMenuItem(value: 'avance', child: Text('Avancé')),
                    ],
                    onChanged: (v) => setS(() => niveau = v ?? niveau),
                  ),
                  if (type == 'article') ...[
                    const SizedBox(height: 8),
                    TextField(controller: contenu, decoration: const InputDecoration(labelText: 'Contenu article'), maxLines: 6),
                  ],
                  if (type == 'video_youtube') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: urlExterne,
                      onChanged: (_) => setS(() {}),
                      decoration: const InputDecoration(labelText: 'URL ou ID YouTube'),
                    ),
                    Builder(
                      builder: (context) {
                        final vid = YoutubePlayer.convertUrlToId(urlExterne.text.trim());
                        if (vid == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aperçu',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Image.network(
                                    'https://img.youtube.com/vi/$vid/hqdefault.jpg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: const Color(0xFFF1F5F9),
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.play_circle_outline_rounded, size: 48),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: dureeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Durée (minutes) — optionnel',
                      hintText: 'Ex : 12',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: tags, decoration: const InputDecoration(labelText: 'Tags (virgules)')),
                  const SizedBox(height: 8),
                  if (existing == null) ...[
                    OutlinedButton.icon(
                      onPressed: () async {
                        final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'mp4', 'webm']);
                        if (r != null && r.files.isNotEmpty) setS(() => fichier = r.files.first);
                      },
                      icon: const Icon(Icons.attach_file_rounded),
                      label: Text(fichier == null ? 'Fichier (PDF / vidéo)' : fichier!.name),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final r = await FilePicker.platform.pickFiles(type: FileType.image);
                        if (r != null && r.files.isNotEmpty) setS(() => couverture = r.files.first);
                      },
                      icon: const Icon(Icons.image_outlined),
                      label: Text(couverture == null ? 'Couverture (image)' : couverture!.name),
                    ),
                  ],
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Publier'),
                    value: publie,
                    onChanged: (v) => setS(() => publie = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mis en avant'),
                    value: misEnAvant,
                    onChanged: (v) => setS(() => misEnAvant = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                if (titre.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Le titre est obligatoire')));
                  return;
                }
                try {
                  if (existing == null) {
                    await _admin.createRessourceParcoursAdmin(
                      fields: {
                        'titre': titre.text.trim(),
                        'description': description.text.trim(),
                        'contenu': contenu.text.trim(),
                        'type_ressource': type,
                        'categorie': categorie,
                        'niveau': niveau,
                        'url_externe': urlExterne.text.trim(),
                        'tags': tags.text.trim(),
                        'duree_minutes': dureeCtrl.text.trim(),
                        'est_publie': publie.toString(),
                        'est_mis_en_avant': misEnAvant.toString(),
                      },
                      fichierBytes: fichier?.bytes,
                      fichierFilename: fichier?.name,
                      fichierMime: _mimeFromExt(fichier?.extension),
                      couvertureBytes: couverture?.bytes,
                      couvertureFilename: couverture?.name,
                      couvertureMime: _mimeFromExt(couverture?.extension),
                    );
                  } else {
                    final patch = <String, dynamic>{
                      'titre': titre.text.trim(),
                      'description': description.text.trim(),
                      'contenu': contenu.text.trim(),
                      'type_ressource': type,
                      'categorie': categorie,
                      'niveau': niveau,
                      'url_externe': urlExterne.text.trim(),
                      'tags': tags.text.trim().isEmpty ? [] : tags.text.split(',').map((e) => e.trim()).toList(),
                      'est_mis_en_avant': misEnAvant,
                    };
                    final dm = int.tryParse(dureeCtrl.text.trim());
                    if (dureeCtrl.text.trim().isNotEmpty && dm != null) {
                      patch['duree_minutes'] = dm;
                    }
                    await _admin.patchRessourceParcoursAdmin(existing['id'].toString(), patch);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _load();
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  String? _mimeFromExt(String? ext) {
    if (ext == null || ext.isEmpty) return null;
    final e = ext.toLowerCase().replaceAll('.', '');
    switch (e) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      default:
        return null;
    }
  }
}
