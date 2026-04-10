import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';

import '../../providers/auth_provider.dart';
import '../../providers/recruteur_provider.dart';
import '../../services/download_service.dart';
import '../../services/recruteur_service.dart';

/// Messagerie recruteur — conversations groupées + bulles envoyées / reçues.
class RecruteurMessagerieConnectedScreen extends StatefulWidget {
  const RecruteurMessagerieConnectedScreen({
    super.key,
    this.initialPeerId,
    this.initialPeerName,
    this.onShellNavigate,
  });

  /// Permet d’ouvrir directement une conversation (ex: depuis Talents / Candidature).
  final String? initialPeerId;
  final String? initialPeerName;

  /// Navigation “shell” (routes internes dashboard recruteur).
  final void Function(String route)? onShellNavigate;

  @override
  State<RecruteurMessagerieConnectedScreen> createState() => _RecruteurMessagerieConnectedScreenState();
}

class _RecruteurMessagerieConnectedScreenState extends State<RecruteurMessagerieConnectedScreen> {
  static const _primary = Color(0xFF1A56DB);
  static const _bg = Color(0xFFF8FAFC);

  final _svc = RecruteurService();
  final _msgCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _newPeerSearchCtrl = TextEditingController();

  List<Map<String, dynamic>> _convs = [];
  List<Map<String, dynamic>> _messages = [];
  String? _activeUserId;
  String? _activePeerName;
  String? _activePeerPhotoUrl;
  bool _loading = true;
  bool _sending = false;
  String _search = '';
  bool _searchingPeers = false;
  List<Map<String, dynamic>> _peerResults = [];
  /// candidatures = API type=tous (postulés puis élargissement) ; postule = uniquement postulés ; talents = recherche talents.
  String _peerScope = 'candidatures';

  String? _pendingPjUrl;
  String? _pendingPjNom;
  int? _pendingPjSize;
  bool _uploadingPj = false;
  String? _downloadingPjUrl;
  double? _downloadingPjProgress;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) async {
      if (!mounted) return;
      await _loadConversations();
      if (_activeUserId != null && (_activePeerName ?? '').isNotEmpty) {
        await _open(_activeUserId!, _activePeerName ?? '');
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    _searchCtrl.dispose();
    _newPeerSearchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  Future<void> _loadConversations() async {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) return;
    final res = await _svc.getConversations(token);
    final data = (res['data'] as Map?)?.cast<String, dynamic>();
    final convRows = data?['conversations'] ?? res['data'] ?? const [];
    final convs = List<Map<String, dynamic>>.from(convRows);
    final unreadSum = _asInt(data?['total_non_lus']) > 0
        ? _asInt(data?['total_non_lus'])
        : convs.fold<int>(0, (s, c) => s + _asInt(c['nb_non_lus']));
    if (!mounted) return;
    context.read<RecruteurProvider>().updateNbMessages(unreadSum);
    setState(() {
      _convs = convs;
      _loading = false;
    });

    // Auto-open conversation if requested (best effort).
    final targetId = widget.initialPeerId;
    if (targetId != null && targetId.isNotEmpty && _activeUserId == null) {
      final match = convs.cast<Map>().where((c) {
        final peer = (c['peer'] as Map?)?.cast<String, dynamic>();
        return peer?['id']?.toString() == targetId;
      }).toList();
      final name = match.isNotEmpty
          ? ((match.first['peer'] as Map?)?['nom']?.toString() ?? widget.initialPeerName ?? '')
          : (widget.initialPeerName ?? '');
      await _open(targetId, name);
    }
  }

  List<Map<String, dynamic>> get _filteredConvs {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _convs;
    return _convs.where((c) {
      final peer = c['peer'] as Map<String, dynamic>? ?? {};
      final nom = (peer['nom'] ?? '').toString().toLowerCase();
      final last = (c['dernier_message'] ?? '').toString().toLowerCase();
      return nom.contains(q) || last.contains(q);
    }).toList();
  }

  Future<void> _open(String userId, String name) async {
    final token = context.read<AuthProvider>().token ?? '';
    final res = await _svc.getMessages(token, userId);
    final data = (res['data'] as Map?)?.cast<String, dynamic>() ?? {};
    final interlocuteur = (data['interlocuteur'] as Map?)?.cast<String, dynamic>();
    String? photo = interlocuteur?['photo_url']?.toString();
    if (photo == null || photo.isEmpty) {
      final conv = _convs.cast<Map<String, dynamic>?>().firstWhere(
            (c) => (c?['peer'] as Map?)?['id']?.toString() == userId,
            orElse: () => null,
          );
      final peer = (conv?['peer'] as Map?)?.cast<String, dynamic>();
      photo = peer?['photo_url']?.toString();
    }
    if (!mounted) return;
    setState(() {
      _activeUserId = userId;
      _activePeerName = name;
      _activePeerPhotoUrl = (photo != null && photo.isNotEmpty) ? photo : null;
      _messages = List<Map<String, dynamic>>.from(data['messages'] ?? const []);
    });
    await _loadConversations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  Future<void> _pickImagePieceJointe() async {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) return;
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (bytes.isEmpty) return;
    setState(() => _uploadingPj = true);
    try {
      final res = await _svc.uploadMessagePieceJointe(token, bytes, x.name);
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final url = data['url']?.toString();
      if (url == null || url.isEmpty) throw Exception('URL manquante');
      if (!mounted) return;
      setState(() {
        _pendingPjUrl = url;
        _pendingPjNom = data['nom']?.toString() ?? x.name;
        _pendingPjSize = bytes.length;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _uploadingPj = false);
    }
  }

  Future<void> _pickPieceJointe() async {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) return;
    final r = await FilePicker.platform.pickFiles(withData: true);
    if (r == null || r.files.isEmpty) return;
    final f = r.files.first;
    final bytes = f.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de lire ce fichier sur cette plateforme.')),
      );
      return;
    }
    final name = f.name;
    setState(() => _uploadingPj = true);
    try {
      final res = await _svc.uploadMessagePieceJointe(token, bytes, name);
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final url = data['url']?.toString();
      if (url == null || url.isEmpty) throw Exception('URL manquante');
      if (!mounted) return;
      setState(() {
        _pendingPjUrl = url;
        _pendingPjNom = data['nom']?.toString() ?? name;
        _pendingPjSize = bytes.length;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _uploadingPj = false);
    }
  }

  Future<void> _send() async {
    final txt = _msgCtrl.text.trim();
    final hasAttachment = _pendingPjUrl != null && _pendingPjUrl!.isNotEmpty;
    if (_activeUserId == null || _sending || (txt.isEmpty && !hasAttachment)) return;
    setState(() => _sending = true);
    final token = context.read<AuthProvider>().token ?? '';
    try {
      final fallbackContent = hasAttachment
          ? '📎 ${_pendingPjNom ?? 'Pièce jointe'}${_pendingPjSize != null ? ' (${_formatBytes(_pendingPjSize!)})' : ''}'
          : '';
      await _svc.envoyerMessage(
        token,
        _activeUserId!,
        txt.isNotEmpty ? txt : fallbackContent,
        pieceJointeUrl: _pendingPjUrl,
        pieceJointeNom: _pendingPjNom,
      );
      _msgCtrl.clear();
      setState(() {
        _pendingPjUrl = null;
        _pendingPjNom = null;
        _pendingPjSize = null;
      });
      await _open(_activeUserId!, _activePeerName ?? '');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _searchPeers(String q) async {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) return;
    final txt = q.trim();
    if (txt.length < 2) {
      if (!mounted) return;
      setState(() => _peerResults = []);
      return;
    }
    setState(() => _searchingPeers = true);
    try {
      List<Map<String, dynamic>> rows = [];
      if (_peerScope == 'talents') {
        final res = await _svc.getTalents(token, recherche: txt, limite: 10);
        final data = (res['data'] as Map?)?.cast<String, dynamic>() ?? {};
        final talents = List<Map<String, dynamic>>.from(data['talents'] ?? const []);
        rows = talents
            .map((t) => (t['utilisateur'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{})
            .where((u) => (u['id']?.toString() ?? '').isNotEmpty)
            .toList();
      } else {
        final apiType = _peerScope == 'postule' ? 'postule' : 'tous';
        final res = await _svc.searchMessagePeers(token, txt, type: apiType);
        rows = List<Map<String, dynamic>>.from(res['data'] ?? const []);
      }
      if (!mounted) return;
      setState(() => _peerResults = rows);
    } finally {
      if (mounted) setState(() => _searchingPeers = false);
    }
  }

  Future<void> _showNewMessageDialog() async {
    _newPeerSearchCtrl.text = '';
    setState(() => _peerResults = []);
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          Future<void> runSearch(String value) async {
            await _searchPeers(value);
            if (ctx.mounted) setDlg(() {});
          }

          final query = _newPeerSearchCtrl.text.trim();
          final tooShort = query.isNotEmpty && query.length < 2;

          return AlertDialog(
            title: Text('Nouveau message', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Postulés + élargissement'),
                          selected: _peerScope == 'candidatures',
                          onSelected: (v) async {
                            if (!v) return;
                            setDlg(() {
                              _peerScope = 'candidatures';
                              _peerResults = [];
                            });
                            await runSearch(_newPeerSearchCtrl.text);
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Uniquement postulés'),
                          selected: _peerScope == 'postule',
                          onSelected: (v) async {
                            if (!v) return;
                            setDlg(() {
                              _peerScope = 'postule';
                              _peerResults = [];
                            });
                            await runSearch(_newPeerSearchCtrl.text);
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Talents'),
                          selected: _peerScope == 'talents',
                          onSelected: (v) async {
                            if (!v) return;
                            setDlg(() {
                              _peerScope = 'talents';
                              _peerResults = [];
                            });
                            await runSearch(_newPeerSearchCtrl.text);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _newPeerSearchCtrl,
                      onChanged: (v) async => runSearch(v),
                      onSubmitted: (v) async => runSearch(v),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un candidat (nom ou email)…',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: IconButton(
                          tooltip: 'Rechercher',
                          onPressed: _searchingPeers ? null : () async => runSearch(_newPeerSearchCtrl.text),
                          icon: const Icon(Icons.arrow_forward_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_searchingPeers) const LinearProgressIndicator(),
                    if (!_searchingPeers && _peerResults.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          tooShort
                              ? 'Tape au moins 2 caractères.'
                              : (query.isEmpty
                                    ? 'Tape au moins 2 caractères.\n'
                                          '« Postulés + élargissement » : candidats ayant postulé, puis tous les chercheurs si vide.\n'
                                          '« Uniquement postulés » : filtre strict sur tes offres.'
                                    : 'Aucun candidat trouvé pour cette recherche.'),
                          style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (_peerResults.isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 340),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _peerResults.length,
                          itemBuilder: (c2, i) {
                            final u = _peerResults[i];
                            final uid = u['id']?.toString() ?? '';
                            final nom = u['nom']?.toString() ?? 'Utilisateur';
                            final email = u['email']?.toString() ?? '';
                            final photo = u['photo_url']?.toString();
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFEFF6FF),
                                backgroundImage: photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
                                child: (photo == null || photo.isEmpty)
                                    ? Text(
                                        nom.trim().isEmpty ? '?' : nom.trim()[0].toUpperCase(),
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: _primary),
                                      )
                                    : null,
                              ),
                              title: Text(nom, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                              subtitle: Text(email, style: GoogleFonts.inter(color: const Color(0xFF64748B))),
                              onTap: uid.isEmpty
                                  ? null
                                  : () async {
                                      Navigator.pop(ctx);
                                      await _open(uid, nom);
                                    },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
            ],
          );
        },
      ),
    );
  }

  String _fmtTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (now.difference(d).inDays == 0) {
        return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      }
      if (now.difference(d).inDays < 7) {
        const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
        return days[d.weekday - 1];
      }
      return '${d.day}/${d.month}';
    } catch (_) {
      return '';
    }
  }

  String _fileExt(String? nameOrUrl) {
    final s = (nameOrUrl ?? '').toLowerCase();
    final clean = s.split('?').first.split('#').first;
    final idx = clean.lastIndexOf('.');
    if (idx <= -1 || idx >= clean.length - 1) return '';
    return clean.substring(idx + 1);
  }

  bool _isImageAttachment({String? name, String? url}) {
    const imageExt = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'};
    final e1 = _fileExt(name);
    final e2 = _fileExt(url);
    return imageExt.contains(e1) || imageExt.contains(e2);
  }

  IconData _fileIconForExt(String ext) {
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart_rounded;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes o';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)} MB';
  }

  String _mimeFromNameOrUrl(String? value) {
    final ext = _fileExt(value).toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _downloadAttachment(String url, String? name) async {
    if (_downloadingPjUrl != null) return;
    final fileName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : 'piece-jointe-${DateTime.now().millisecondsSinceEpoch}';
    try {
      setState(() {
        _downloadingPjUrl = url;
        _downloadingPjProgress = 0;
      });
      final urlsToTry = <String>{
        url,
        ..._bucketFallbackUrls(url),
      }.toList();
      DioException? lastDioErr;
      Exception? lastErr;
      var downloaded = false;
      for (final candidate in urlsToTry) {
        try {
          await DownloadService.downloadFileFromUrl(
            url: candidate,
            fileName: fileName,
            mimeType: _mimeFromNameOrUrl(name ?? candidate),
            context: context,
            onProgress: (received, total) {
              if (!mounted) return;
              if (total <= 0) return;
              setState(() {
                _downloadingPjProgress = received / total;
              });
            },
          );
          lastDioErr = null;
          lastErr = null;
          downloaded = true;
          break;
        } on DioException catch (e) {
          lastDioErr = e;
          continue;
        } catch (e) {
          lastErr = Exception('$e');
          continue;
        }
      }
      if (lastDioErr != null) throw lastDioErr;
      if (lastErr != null) throw lastErr;
      if (!downloaded) {
        throw Exception('Téléchargement impossible');
      }
      if (!mounted) return;
      DownloadService.showWebDownloadSnackBar(context, fileName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur téléchargement: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloadingPjUrl = null;
          _downloadingPjProgress = null;
        });
      }
    }
  }

  List<String> _bucketFallbackUrls(String url) {
    try {
      final u = Uri.parse(url);
      final seg = u.pathSegments;
      final i = seg.indexOf('public');
      if (i < 0 || i + 2 >= seg.length) return const [];
      final objectBase = seg.sublist(0, i + 1);
      final currentBucket = seg[i + 1];
      final filePathSeg = seg.sublist(i + 2);
      const buckets = ['logos', 'cv-files', 'avatars', 'messages'];
      return buckets
          .where((b) => b != currentBucket)
          .map((b) => u.replace(pathSegments: [...objectBase, b, ...filePathSeg]).toString())
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _deleteMessage(String id) async {
    if (id.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce message ?'),
        content: const Text('Cette action est immédiate et retirera le message de la conversation.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) return;
    try {
      await _svc.deleteMessage(token, id);
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m['id']?.toString() == id);
      });
      await _loadConversations();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur suppression: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    final wide = MediaQuery.of(context).size.width >= 900;
    final myId = context.watch<AuthProvider>().user?['id']?.toString();

    final body = wide
        ? Row(
            children: [
              _buildSidebar(),
              Container(width: 1, color: const Color(0xFFE2E8F0)),
              Expanded(child: _buildThread(myId)),
            ],
          )
        : _activeUserId == null
            ? _buildSidebar()
            : Column(
                children: [
                  Material(
                    color: Colors.white,
                    child: ListTile(
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => setState(() {
                          _activeUserId = null;
                          _messages = [];
                        }),
                      ),
                      title: Text(_activePeerName ?? 'Conversation', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  Expanded(child: _buildThread(myId)),
                ],
              );

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(child: body),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: MediaQuery.of(context).size.width >= 900 ? 340 : double.infinity,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Messagerie',
                        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        _showNewMessageDialog();
                      },
                      icon: const Icon(Icons.add_comment_outlined, size: 18),
                      label: const Text('Nouveau'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primary,
                        side: const BorderSide(color: Color(0xFFBFDBFE)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_convs.length} conversation(s)',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Rechercher…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              color: _primary,
              onRefresh: _loadConversations,
              child: _filteredConvs.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 48),
                        Icon(Icons.chat_bubble_outline_rounded, size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            _convs.isEmpty ? 'Aucun message pour le moment' : 'Aucun résultat',
                            style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                          ),
                        ),
                        if (_convs.isEmpty) ...[
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: FilledButton.icon(
                              onPressed: _showNewMessageDialog,
                              icon: const Icon(Icons.search_rounded),
                              label: const Text('Nouveau message'),
                              style: FilledButton.styleFrom(
                                backgroundColor: _primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: OutlinedButton.icon(
                              onPressed: _loadConversations,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Actualiser'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    )
                  : ListView.builder(
                      itemCount: _filteredConvs.length,
                      itemBuilder: (ctx, i) {
                        final c = _filteredConvs[i];
                        final peer = c['peer'] as Map<String, dynamic>? ?? {};
                        final uid = peer['id']?.toString() ?? '';
                        final nom = peer['nom']?.toString() ?? 'Utilisateur';
                        final photo = peer['photo_url']?.toString();
                        final last = c['dernier_message']?.toString() ?? '';
                        final nUnread = _asInt(c['nb_non_lus']);
                        final sel = _activeUserId == uid;
                        final offreTitre = c['offre_titre']?.toString();

                        return Material(
                          color: sel ? const Color(0xFFEFF6FF) : Colors.transparent,
                          child: InkWell(
                            onTap: uid.isEmpty ? null : () => _open(uid, nom),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: const Color(0xFFEFF6FF),
                                        backgroundImage: photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
                                        child: photo == null || photo.isEmpty
                                            ? Text(
                                                nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w700,
                                                  color: _primary,
                                                ),
                                              )
                                            : null,
                                      ),
                                      if (nUnread > 0)
                                        Positioned(
                                          right: -2,
                                          top: -2,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEF4444),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '$nUnread',
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                nom,
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              _fmtTime(c['date_dernier']?.toString()),
                                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                                            ),
                                          ],
                                        ),
                                        if (offreTitre != null && offreTitre.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Offre : $offreTitre',
                                            style: GoogleFonts.inter(fontSize: 11, color: _primary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        const SizedBox(height: 2),
                                        Text(
                                          last,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: const Color(0xFF64748B),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThread(String? myId) {
    if (_activeUserId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Sélectionnez une conversation',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos échanges avec les candidats apparaissent ici.',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (MediaQuery.of(context).size.width >= 900)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFEFF6FF),
                  backgroundImage: (_activePeerPhotoUrl?.isNotEmpty == true)
                      ? NetworkImage(_activePeerPhotoUrl!)
                      : null,
                  child: (_activePeerPhotoUrl?.isNotEmpty == true)
                      ? null
                      : Text(
                          (_activePeerName ?? 'C').isNotEmpty ? _activePeerName![0].toUpperCase() : 'C',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: _primary),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_activePeerName ?? 'Conversation', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                      Text('Discussion sécurisée', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: _messages.length,
            itemBuilder: (ctx, i) {
              final m = _messages[i];
              final mine = m['is_mine'] == true || m['expediteur_id']?.toString() == myId;
              final text = m['contenu']?.toString() ?? '';
              final pjUrl = (m['fichier_url'] ?? m['piece_jointe_url'])?.toString();
              final pjNom = (m['fichier_nom'] ?? m['piece_jointe_nom'])?.toString();
              final hasPj = pjUrl != null && pjUrl.isNotEmpty;
              final isImagePj = hasPj && _isImageAttachment(name: pjNom, url: pjUrl);
              final ext = _fileExt(pjNom?.isNotEmpty == true ? pjNom : pjUrl).toUpperCase();
              final isAutoAttachmentLabel = text.startsWith('📎 ');
              final msgId = m['id']?.toString() ?? '';

              bool isImageOnlyMessage(Map<String, dynamic> row) {
                final rowText = row['contenu']?.toString() ?? '';
                final rowUrl = row['piece_jointe_url']?.toString();
                final rowNom = row['piece_jointe_nom']?.toString();
                final rowHasPj = rowUrl != null && rowUrl.isNotEmpty;
                final rowIsImage = rowHasPj && _isImageAttachment(name: rowNom, url: rowUrl);
                final rowAuto = rowText.startsWith('📎 ');
                return rowIsImage && (rowText.isEmpty || rowAuto);
              }

              if (isImageOnlyMessage(m)) {
                int before = 0;
                for (int k = i - 1; k >= 0; k--) {
                  final prev = _messages[k];
                  final prevMine = prev['is_mine'] == true || prev['expediteur_id']?.toString() == myId;
                  if (prevMine != mine || !isImageOnlyMessage(prev)) break;
                  before++;
                }
                if (before % 4 != 0) return const SizedBox.shrink();

                final group = <Map<String, dynamic>>[];
                for (int k = i; k < _messages.length && group.length < 4; k++) {
                  final row = _messages[k];
                  final rowMine = row['is_mine'] == true || row['expediteur_id']?.toString() == myId;
                  if (rowMine != mine || !isImageOnlyMessage(row)) break;
                  group.add(row);
                }

                final groupTime = _fmtTime(group.last['date_envoi']?.toString());
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: mine ? _primary : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(mine ? 16 : 4),
                        bottomRight: Radius.circular(mine ? 4 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: mine ? null : Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: group.map((row) {
                            final rowUrl = row['piece_jointe_url']?.toString() ?? '';
                            final rowId = row['id']?.toString() ?? '';
                            return Stack(
                              children: [
                                InkWell(
                                  onTap: () async {
                                    final u = Uri.tryParse(rowUrl);
                                    if (u != null && await canLaunchUrl(u)) {
                                      await launchUrl(u, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 134,
                                      height: 134,
                                      child: Image.network(
                                        rowUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: mine ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFEFF6FF),
                                          alignment: Alignment.center,
                                          child: Icon(Icons.broken_image_outlined, color: mine ? Colors.white70 : const Color(0xFF64748B)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (mine && rowId.isNotEmpty)
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: PopupMenuButton<String>(
                                      tooltip: 'Actions',
                                      color: Colors.white,
                                      icon: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.35),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.more_horiz_rounded, size: 14, color: Colors.white),
                                      ),
                                      onSelected: (v) async {
                                        if (v == 'delete') await _deleteMessage(rowId);
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Text('Supprimer l’image'),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          groupTime,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: mine ? Colors.white70 : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final t = _fmtTime(m['date_envoi']?.toString());
              return Align(
                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: mine ? _primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(mine ? 16 : 4),
                      bottomRight: Radius.circular(mine ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: mine ? null : Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (pjUrl != null && pjUrl.isNotEmpty) ...[
                        if (isImagePj)
                          Stack(
                            children: [
                              InkWell(
                                onTap: () async {
                                  final u = Uri.tryParse(pjUrl);
                                  if (u != null && await canLaunchUrl(u)) {
                                    await launchUrl(u, mode: LaunchMode.externalApplication);
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxHeight: 260, maxWidth: 320),
                                    child: Image.network(
                                      pjUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: 120,
                                        width: 220,
                                        color: mine ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFEFF6FF),
                                        alignment: Alignment.center,
                                        child: Icon(Icons.broken_image_outlined, color: mine ? Colors.white70 : const Color(0xFF64748B)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (mine && msgId.isNotEmpty)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: PopupMenuButton<String>(
                                    tooltip: 'Actions',
                                    color: Colors.white,
                                    icon: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.35),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.more_horiz_rounded, size: 16, color: Colors.white),
                                    ),
                                    onSelected: (v) async {
                                      if (v == 'delete') await _deleteMessage(msgId);
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Text('Supprimer l’image'),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: mine ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                              border: mine ? null : Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: Icon(_fileIconForExt(ext.toLowerCase()), color: mine ? Colors.white : _primary),
                              title: Text(
                                (pjNom != null && pjNom.isNotEmpty) ? pjNom : 'Pièce jointe',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: mine ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              subtitle: Text(
                                ext.isNotEmpty ? ext : 'Fichier',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: mine ? Colors.white70 : const Color(0xFF64748B),
                                ),
                              ),
                              trailing: IconButton(
                                tooltip: 'Télécharger',
                                icon: Icon(Icons.download_rounded, color: mine ? Colors.white : _primary),
                                onPressed: () async {
                                  await _downloadAttachment(pjUrl, pjNom);
                                },
                              ),
                              onTap: () async {
                                final u = Uri.tryParse(pjUrl);
                                if (u != null && await canLaunchUrl(u)) {
                                  await launchUrl(u, mode: LaunchMode.externalApplication);
                                }
                              },
                            ),
                          ),
                        const SizedBox(height: 8),
                      ],
                      if (text.isNotEmpty && !(hasPj && isAutoAttachmentLabel))
                        Text(
                          text,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            height: 1.35,
                            color: mine ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      if (mine && msgId.isNotEmpty)
                        Align(
                          alignment: Alignment.centerRight,
                          child: PopupMenuButton<String>(
                            icon: Icon(Icons.more_horiz_rounded, size: 18, color: mine ? Colors.white70 : const Color(0xFF94A3B8)),
                            onSelected: (v) async {
                              if (v == 'delete') await _deleteMessage(msgId);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('Supprimer le message'),
                              ),
                            ],
                          ),
                        ),
                      if (hasPj && _downloadingPjUrl == pjUrl && _downloadingPjProgress != null) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _downloadingPjProgress!.clamp(0, 1),
                          minHeight: 5,
                          backgroundColor: mine ? Colors.white24 : const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            mine ? Colors.white : _primary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        t,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: mine ? Colors.white70 : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_pendingPjUrl != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file_outlined, color: _primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _pendingPjNom ?? 'Pièce jointe',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_pendingPjSize != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              _formatBytes(_pendingPjSize!),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => setState(() {
                            _pendingPjUrl = null;
                            _pendingPjNom = null;
                            _pendingPjSize = null;
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Joindre un fichier',
                      onPressed: _uploadingPj || _activeUserId == null ? null : _pickPieceJointe,
                      icon: _uploadingPj
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.attach_file_rounded, color: Color(0xFF64748B)),
                    ),
                    IconButton(
                      tooltip: 'Joindre une image',
                      onPressed: _uploadingPj || _activeUserId == null ? null : _pickImagePieceJointe,
                      icon: const Icon(Icons.image_outlined, color: Color(0xFF64748B)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _msgCtrl,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Écrire un message…',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: _primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                  onPressed: _sending ? null : _send,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 22),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
