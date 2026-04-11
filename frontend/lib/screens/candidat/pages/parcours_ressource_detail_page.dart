import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../services/candidat_parcours_service.dart';

/// Détail d’une ressource Parcours Carrière (publiée) — lecteur YouTube / WebView (PRD §4).
class ParcoursRessourceDetailPage extends StatefulWidget {
  const ParcoursRessourceDetailPage({super.key, required this.id, this.preview});

  final String id;
  final Map<String, dynamic>? preview;

  @override
  State<ParcoursRessourceDetailPage> createState() => _ParcoursRessourceDetailPageState();
}

class _ParcoursRessourceDetailPageState extends State<ParcoursRessourceDetailPage> {
  final _svc = CandidatParcoursService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  YoutubePlayerController? _ytCtrl;
  String? _ytVideoId;
  WebViewController? _internalWeb;
  String? _internalVideoUrl;

  @override
  void initState() {
    super.initState();
    _data = widget.preview;
    _syncMediaControllers();
    _fetch();
  }

  @override
  void dispose() {
    _ytCtrl?.dispose();
    super.dispose();
  }

  void _syncMediaControllers() {
    final d = _data;
    if (d == null) return;

    final type = d['type_ressource']?.toString() ?? '';
    final urlExterne = d['url_externe']?.toString() ?? '';
    final fichier = d['fichier_url']?.toString() ?? '';

    if (type == 'video_youtube' && urlExterne.isNotEmpty) {
      final id = YoutubePlayer.convertUrlToId(urlExterne);
      if (id != _ytVideoId) {
        _ytCtrl?.dispose();
        _ytVideoId = id;
        _ytCtrl = id != null
            ? YoutubePlayerController(
                initialVideoId: id,
                flags: const YoutubePlayerFlags(autoPlay: false, mute: false, enableCaption: false),
              )
            : null;
      }
    } else {
      _ytCtrl?.dispose();
      _ytCtrl = null;
      _ytVideoId = null;
    }

    if (type == 'video_interne' && fichier.isNotEmpty) {
      if (_internalVideoUrl != fichier) {
        _internalVideoUrl = fichier;
        _internalWeb = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadHtmlString(_html5VideoPage(fichier));
      }
    } else {
      _internalWeb = null;
      _internalVideoUrl = null;
    }
  }

  String _html5VideoPage(String src) {
    final esc = src.replaceAll('&', '&amp;').replaceAll('"', '&quot;').replaceAll("'", '&#39;');
    return '<!DOCTYPE html><html><head><meta charset="utf-8"/>'
        '<meta name="viewport" content="width=device-width,initial-scale=1"/></head>'
        '<body style="margin:0;background:#000;">'
        '<video controls playsinline style="width:100%;height:220px" src="$esc"></video>'
        '</body></html>';
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final body = await _svc.getRessource(widget.id);
      if (!mounted) return;
      setState(() {
        _data = body['data'] as Map<String, dynamic>?;
        _loading = false;
      });
      _syncMediaControllers();
      if (mounted) setState(() {});
      try {
        await _svc.marquerVue(widget.id);
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final u = Uri.tryParse(url);
    if (u == null) return;
    if (!await launchUrl(u, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d’ouvrir le lien')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _data?['titre']?.toString() ?? 'Ressource',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _loading && _data == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _data == null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final d = _data!;
    final type = d['type_ressource']?.toString() ?? '';
    final titre = d['titre']?.toString() ?? '';
    final desc = d['description']?.toString() ?? '';
    final contenu = d['contenu']?.toString() ?? '';
    final categorie = d['categorie']?.toString() ?? '';
    final niveau = d['niveau']?.toString() ?? '';
    final duree = d['duree_minutes'];
    final fichier = d['fichier_url']?.toString();

    return CustomScrollView(
      slivers: [
        if (type == 'video_youtube' && _ytCtrl != null && !kIsWeb)
          SliverToBoxAdapter(
            child: YoutubePlayerBuilder(
              player: YoutubePlayer(
                controller: _ytCtrl!,
                showVideoProgressIndicator: true,
                progressIndicatorColor: const Color(0xFF1A56DB),
                progressColors: const ProgressBarColors(playedColor: Color(0xFF1A56DB), handleColor: Color(0xFF1A56DB)),
              ),
              builder: (context, player) => player,
            ),
          ),
        if (type == 'video_youtube' && (kIsWeb || _ytCtrl == null))
          SliverToBoxAdapter(
            child: _youtubeFallback(d['url_externe']?.toString() ?? ''),
          ),
        if (type == 'video_interne' && _internalWeb != null)
          SliverToBoxAdapter(
            child: SizedBox(height: 220, child: WebViewWidget(controller: _internalWeb!)),
          ),
        if (type != 'video_youtube' && type != 'video_interne' && d['image_couverture'] != null)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Image.network(
                d['image_couverture'].toString(),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _BadgeInfo(_labelCategorie(categorie), _couleurCategorie(categorie)),
                    _BadgeInfo(_labelNiveau(niveau), const Color(0xFF64748B)),
                    if (duree != null) _BadgeInfo('⏱ $duree min', const Color(0xFF0EA5E9)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(titre, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(desc, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B), height: 1.6)),
                ],
                if (type == 'article' && contenu.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  SelectableText(contenu, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF374151), height: 1.7)),
                ],
                if (type == 'pdf' && fichier != null && fichier.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _openUrl(fichier),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text('Ouvrir le PDF'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
                if (type == 'conseil_ia')
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Conseil personnalisé IA — contenu administrable.',
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _youtubeFallback(String url) {
    final id = YoutubePlayer.convertUrlToId(url);
    final thumb = id != null ? 'https://img.youtube.com/vi/$id/hqdefault.jpg' : null;
    return Material(
      color: Colors.black,
      child: InkWell(
        onTap: url.isEmpty ? null : () => _openUrl(url),
        child: SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (thumb != null)
                Positioned.fill(
                  child: Image.network(thumb, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox()),
                ),
              const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 64),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Text(
                  kIsWeb ? 'Lecture sur YouTube (nouvel onglet)' : 'Lire la vidéo',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _labelCategorie(String c) => {
        'cv': 'CV',
        'entretien': 'Entretien',
        'salaire': 'Salaire',
        'reconversion': 'Reconversion',
        'entrepreneuriat': 'Entrepreneuriat',
        'general': 'Général',
      }[c] ??
      c;

  Color _couleurCategorie(String c) => {
        'cv': const Color(0xFF1A56DB),
        'entretien': const Color(0xFF8B5CF6),
        'salaire': const Color(0xFF10B981),
        'reconversion': const Color(0xFFF59E0B),
        'entrepreneuriat': const Color(0xFFEF4444),
      }[c] ??
      const Color(0xFF64748B);

  String _labelNiveau(String n) => {
        'debutant': 'Débutant',
        'intermediaire': 'Intermédiaire',
        'avance': 'Avancé',
        'tous': 'Tous niveaux',
      }[n] ??
      n;
}

class _BadgeInfo extends StatelessWidget {
  const _BadgeInfo(this.label, this.couleur);

  final String label;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: couleur.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: couleur)),
    );
  }
}
