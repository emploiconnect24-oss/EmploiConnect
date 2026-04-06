import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/recruteur_provider.dart';
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
  bool _loading = true;
  bool _sending = false;
  String _search = '';
  bool _searchingPeers = false;
  List<Map<String, dynamic>> _peerResults = [];
  /// candidatures = API type=tous (postulés puis élargissement) ; postule = uniquement postulés ; talents = recherche talents.
  String _peerScope = 'candidatures';

  String? _pendingPjUrl;
  String? _pendingPjNom;
  bool _uploadingPj = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
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
    final convs = List<Map<String, dynamic>>.from(res['data'] ?? const []);
    final unreadSum = convs.fold<int>(0, (s, c) => s + _asInt(c['nb_non_lus']));
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
    if (!mounted) return;
    setState(() {
      _activeUserId = userId;
      _activePeerName = name;
      _messages = List<Map<String, dynamic>>.from(res['data']?['messages'] ?? const []);
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
    if (_activeUserId == null || txt.isEmpty || _sending) return;
    setState(() => _sending = true);
    final token = context.read<AuthProvider>().token ?? '';
    try {
      await _svc.envoyerMessage(
        token,
        _activeUserId!,
        txt,
        pieceJointeUrl: _pendingPjUrl,
        pieceJointeNom: _pendingPjNom,
      );
      _msgCtrl.clear();
      setState(() {
        _pendingPjUrl = null;
        _pendingPjNom = null;
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
      builder: (ctx) => AlertDialog(
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
                    onSelected: (v) {
                      if (!v) return;
                      setState(() {
                        _peerScope = 'candidatures';
                        _peerResults = [];
                      });
                      _searchPeers(_newPeerSearchCtrl.text);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Uniquement postulés'),
                    selected: _peerScope == 'postule',
                    onSelected: (v) {
                      if (!v) return;
                      setState(() {
                        _peerScope = 'postule';
                        _peerResults = [];
                      });
                      _searchPeers(_newPeerSearchCtrl.text);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Talents'),
                    selected: _peerScope == 'talents',
                    onSelected: (v) {
                      if (!v) return;
                      setState(() {
                        _peerScope = 'talents';
                        _peerResults = [];
                      });
                      _searchPeers(_newPeerSearchCtrl.text);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _newPeerSearchCtrl,
                onChanged: _searchPeers,
                decoration: const InputDecoration(
                  hintText: 'Rechercher un candidat (nom ou email)…',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              if (_searchingPeers) const LinearProgressIndicator(),
              if (!_searchingPeers && _peerResults.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Tape au moins 2 caractères.\n'
                    '« Postulés + élargissement » : candidats ayant postulé, puis tous les chercheurs si vide.\n'
                    '« Uniquement postulés » : filtre strict sur tes offres.',
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
                  child: Text(
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
              final pjUrl = m['piece_jointe_url']?.toString();
              final pjNom = m['piece_jointe_nom']?.toString();
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
                        Material(
                          color: mine ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: () async {
                              final u = Uri.tryParse(pjUrl);
                              if (u != null && await canLaunchUrl(u)) {
                                await launchUrl(u, mode: LaunchMode.externalApplication);
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.attach_file_rounded,
                                    size: 18,
                                    color: mine ? Colors.white : _primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      (pjNom != null && pjNom.isNotEmpty) ? pjNom : 'Pièce jointe',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: mine ? Colors.white : _primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        text,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.35,
                          color: mine ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
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
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => setState(() {
                            _pendingPjUrl = null;
                            _pendingPjNom = null;
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
