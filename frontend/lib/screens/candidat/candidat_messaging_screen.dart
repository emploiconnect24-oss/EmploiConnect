import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/candidat_provider.dart';
import '../../services/candidat_messages_service.dart';
import 'candidat_applications_screen.dart';

class CandidatMessagingScreen extends StatefulWidget {
  const CandidatMessagingScreen({
    super.key,
    this.initialPeerId,
    this.initialPeerName,
    this.initialPeerPhotoUrl,
  });

  final String? initialPeerId;
  final String? initialPeerName;
  final String? initialPeerPhotoUrl;

  @override
  State<CandidatMessagingScreen> createState() =>
      _CandidatMessagingScreenState();
}

class _CandidatMessagingScreenState extends State<CandidatMessagingScreen> {
  final _searchCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _svc = CandidatMessagesService();

  bool _showConversationOnMobile = false;
  List<_Conversation> _conversations = [];
  String? _selectedId;
  String? _lastTimestamp;
  Timer? _pollTimer;
  bool _loading = true;
  String? _error;

  String? _pendingPjUrl;
  String? _pendingPjNom;
  bool _uploadingPj = false;
  String? _activePeerPhotoUrl;
  bool _initialPeerHandled = false;
  bool _autreEcrit = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    // PRD étape 9 : rafraîchir la liste ou les messages sans bloquer l’UI.
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      if (_selectedId == null) {
        _silentRefreshInbox();
      } else {
        _pollNouveauxMessages();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    _pollTimer?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  _Conversation get _selected {
    if (_conversations.isEmpty) {
      return _Conversation(
        id: 'none',
        peerId: '',
        companyName: 'Aucune conversation',
        offerTitle: '',
        lastMessage: '',
        lastTime: '',
        unread: 0,
        messages: [],
      );
    }
    return _conversations.firstWhere(
      (c) => c.id == _selectedId,
      orElse: () => _conversations.first,
    );
  }

  List<_Conversation> get _filteredConversations {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _conversations;
    return _conversations.where((c) {
      return c.companyName.toLowerCase().contains(q) ||
          c.offerTitle.toLowerCase().contains(q) ||
          c.lastMessage.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    final pj = _pendingPjUrl;
    if (text.isEmpty && (pj == null || pj.isEmpty)) return;
    final idx = _conversations.indexWhere((c) => c.id == _selected.id);
    if (idx < 0) return;
    final conv = _conversations[idx];
    try {
      await _svc.sendMessage(
        conv.peerId,
        text,
        offreId: conv.offreId,
        pieceJointeUrl: pj,
        pieceJointeNom: _pendingPjNom,
      );
      if (!mounted) return;
      _messageCtrl.clear();
      setState(() {
        _pendingPjUrl = null;
        _pendingPjNom = null;
      });
      await _openConversation(conv.id);
      _scrollerEnBas();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _pickPieceJointe() async {
    final r = await FilePicker.platform.pickFiles(withData: true);
    if (r == null || r.files.isEmpty) return;
    final f = r.files.first;
    final bytes = f.bytes;
    if (bytes == null || bytes.isEmpty) return;
    setState(() => _uploadingPj = true);
    try {
      final res = await _svc.uploadPieceJointe(bytes, f.name);
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final url = data['url']?.toString();
      if (url == null || url.isEmpty) throw Exception('URL manquante');
      if (!mounted) return;
      setState(() {
        _pendingPjUrl = url;
        _pendingPjNom = data['nom']?.toString() ?? f.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _uploadingPj = false);
    }
  }

  Future<void> _pickImagePieceJointe() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (bytes.isEmpty) return;
    setState(() => _uploadingPj = true);
    try {
      final res = await _svc.uploadPieceJointe(bytes, x.name);
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

  _Msg _msgFromMap(Map<String, dynamic> m) {
    final iso = m['date_envoi']?.toString();
    return _Msg(
      id: m['id']?.toString(),
      sender: (m['is_mine'] == true) ? 'candidat' : 'recruteur',
      content: m['contenu']?.toString() ?? '',
      time: _fmtMsgTime(iso),
      dateIso: iso,
      read: m['est_lu'] == true,
      pieceJointeUrl: m['piece_jointe_url']?.toString(),
      pieceJointeNom: m['piece_jointe_nom']?.toString(),
    );
  }

  String _fmtMsgTime(String? iso) {
    if (iso == null || iso.isEmpty) return _nowLabel();
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return _nowLabel();
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }

  String _nowLabel() {
    final now = TimeOfDay.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmDeleteMessage(_Msg msg) async {
    final id = msg.id;
    if (id == null || id.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce message ?'),
        content: const Text(
          'Le message sera retiré de votre vue (suppression côté expéditeur).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _svc.deleteMessage(id);
      if (!mounted) return;
      final conv = _selected;
      await _openConversation(conv.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message supprimé')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_pendingPjNom != null && _pendingPjNom!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF1A56DB).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.attach_file_rounded,
                    color: Color(0xFF1A56DB),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _pendingPjNom!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF1A56DB),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _pendingPjUrl = null;
                      _pendingPjNom = null;
                    }),
                    child: const Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              GestureDetector(
                onTap: _uploadingPj ? null : _pickPieceJointe,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.attach_file_rounded,
                    color: _uploadingPj
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF64748B),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _uploadingPj ? null : _pickImagePieceJointe,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.image_outlined,
                    color: _uploadingPj
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF64748B),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _messageCtrl,
                  maxLines: null,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Écrire un message...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFFCBD5E1),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A56DB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final outerPad = EdgeInsets.fromLTRB(
      20,
      16,
      20,
      MediaQuery.of(context).size.width <= 900 ? 80 : 24,
    );
    return LayoutBuilder(
      builder: (context, c) {
        final isMobile = c.maxWidth < 900;
        if (isMobile) {
          return Padding(
            padding: outerPad,
            child: _showConversationOnMobile
                ? _buildConversationMobile()
                : _buildListMobile(),
          );
        }
        return Padding(
          padding: outerPad,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 360, child: _buildConversationsList()),
              const SizedBox(width: 12),
              Expanded(child: _buildConversationView()),
            ],
          ),
        );
      },
    );
  }

  Widget _listHeader({required bool mobile}) {
    return Row(
      children: [
        if (mobile && _showConversationOnMobile)
          IconButton(
            onPressed: () => setState(() => _showConversationOnMobile = false),
            icon: const Icon(Icons.arrow_back),
          ),
        const Text(
          'Messagerie',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _buildConversationsList() {
    final list = _filteredConversations;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _listHeader(mobile: false),
            const SizedBox(height: 10),
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Rechercher une conversation...',
                isDense: true,
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('Aucune conversation'))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final c = list[i];
                        final selected = _selectedId == c.id;
                        return InkWell(
                          onTap: () => _openConversation(c.id),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFEFF6FF)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                _ConversationAvatar(conv: c),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              c.companyName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            c.lastTime,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '💼 ${c.companyName} · ${c.offerTitle}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        c.lastMessage,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (c.unread > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(99),
                                      ),
                                    ),
                                    child: Text(
                                      '${c.unread}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationView() {
    final conv = _selected;
    if (_conversations.isEmpty) {
      return const Center(child: Text('Aucune conversation.'));
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                _HeaderPeerAvatar(conv: conv, photoUrl: _activePeerPhotoUrl),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💼 ${conv.companyName} · ${conv.offerTitle}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Conversation liée à votre candidature',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: conv.offreId == null
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => CandidatApplicationsScreen(
                                offreIdFilter: conv.offreId,
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.assignment_outlined, size: 16),
                  label: const Text('Voir candidature'),
                ),
              ],
            ),
            const Divider(height: 18),
            if (_autreEcrit)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        children: [
                          _PointAnimation(delai: 0),
                          SizedBox(width: 4),
                          _PointAnimation(delai: 150),
                          SizedBox(width: 4),
                          _PointAnimation(delai: 300),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                itemCount: conv.messages.length,
                itemBuilder: (_, i) {
                  final msg = conv.messages[i];
                  final isMe = msg.sender == 'candidat';
                  final isDateSeparator = _changementJour(conv.messages, i);
                  return Column(
                    children: [
                      if (isDateSeparator)
                        _buildSeparateurDate(_labelDate(msg.dateIso)),
                      _MessageBubble(
                        msg: msg,
                        isMe: isMe,
                        onLongPress: isMe && msg.id != null && msg.id!.isNotEmpty
                            ? () => _confirmDeleteMessage(msg)
                            : null,
                      ),
                    ],
                  );
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildListMobile() {
    final list = _filteredConversations;
    return Column(
      children: [
        _listHeader(mobile: true),
        const SizedBox(height: 10),
        TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Rechercher...',
            isDense: true,
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('Aucune conversation'))
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final c = list[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      leading: _ConversationAvatar(conv: c),
                      title: Text(c.companyName),
                      subtitle: Text(
                        '💼 ${c.companyName} · ${c.offerTitle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: c.unread > 0
                          ? CircleAvatar(
                              radius: 10,
                              backgroundColor: const Color(0xFFEF4444),
                              child: Text(
                                '${c.unread}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            )
                          : Text(
                              c.lastTime,
                              style: const TextStyle(fontSize: 12),
                            ),
                      onTap: () => _openConversation(c.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildConversationMobile() {
    return Column(
      children: [
        _listHeader(mobile: true),
        const SizedBox(height: 8),
        Expanded(child: _buildConversationView()),
      ],
    );
  }

  _Conversation _conversationFromRow(Map<String, dynamic> r, {List<_Msg>? messages}) {
    final peer = (r['peer'] as Map?)?.cast<String, dynamic>() ?? {};
    final id = r['conversation_id']?.toString() ?? '';
    final entNom = (r['entreprise_nom'] ?? '').toString().trim();
    return _Conversation(
      id: id,
      peerId: r['peer_id']?.toString() ?? '',
      companyName: entNom.isNotEmpty ? entNom : (peer['nom']?.toString() ?? 'Entreprise'),
      offerTitle: r['offre_titre']?.toString() ?? '',
      lastMessage: r['dernier_message']?.toString() ?? '',
      lastTime: _fmtHumanTime(r['date_dernier']?.toString()),
      unread: _asInt(r['nb_non_lus']),
      messages: messages ?? [],
      offreId: r['offre_id']?.toString(),
      logoUrl: (() {
        final fromEntreprise = r['entreprise_logo_url']?.toString();
        if (fromEntreprise != null && fromEntreprise.isNotEmpty) return fromEntreprise;
        final peerPhoto = peer['photo_url']?.toString();
        if (peerPhoto != null && peerPhoto.isNotEmpty) return peerPhoto;
        return null;
      })(),
    );
  }

  Future<void> _silentRefreshInbox() async {
    if (_loading) return;
    try {
      final rows = await _svc.getConversations();
      if (!mounted) return;
      final prevById = {for (final c in _conversations) c.id: c};
      final next = <_Conversation>[];
      for (final r in rows) {
        final fresh = _conversationFromRow(Map<String, dynamic>.from(r as Map));
        if (fresh.id.isEmpty) continue;
        final old = prevById[fresh.id];
        if (old != null) {
          old.lastMessage = fresh.lastMessage;
          old.lastTime = fresh.lastTime;
          old.unread = fresh.unread;
          old.offerTitle = fresh.offerTitle;
          old.companyName = fresh.companyName;
          old.logoUrl = fresh.logoUrl;
          next.add(old);
        } else {
          next.add(fresh);
        }
      }
      setState(() {
        _conversations = next;
        if (_selectedId != null && !next.any((c) => c.id == _selectedId)) {
          _selectedId = next.isNotEmpty ? next.first.id : null;
        }
      });
      if (mounted) {
        await context.read<CandidatProvider>().loadDashboardMetrics();
      }
    } catch (_) {}
  }

  Future<void> _loadConversations() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _svc.getConversations();
      final mapped = rows
          .map((r) => _conversationFromRow(Map<String, dynamic>.from(r as Map)))
          .where((c) => c.id.isNotEmpty)
          .toList();
      if (!mounted) return;
      final previousSelected = _selectedId;
      setState(() {
        _conversations = mapped;
        if (previousSelected != null && mapped.any((c) => c.id == previousSelected)) {
          _selectedId = previousSelected;
        } else {
          _selectedId = mapped.isNotEmpty ? mapped.first.id : null;
        }
        _loading = false;
      });
      await context.read<CandidatProvider>().loadDashboardMetrics();
      await _openInitialPeerIfAny();
      if (_selectedId != null) await _openConversation(_selectedId!);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openInitialPeerIfAny() async {
    if (_initialPeerHandled) return;
    final peerId = widget.initialPeerId?.trim() ?? '';
    if (peerId.isEmpty) {
      _initialPeerHandled = true;
      return;
    }
    context.read<CandidatProvider>().clearMessageriePrefill();
    _initialPeerHandled = true;
    final existing = _conversations.where((c) => c.peerId == peerId).toList();
    if (existing.isNotEmpty) {
      _selectedId = existing.first.id;
      return;
    }

    final fallbackId = 'prefill-$peerId';
    final conv = _Conversation(
      id: fallbackId,
      peerId: peerId,
      companyName: (widget.initialPeerName ?? 'Entreprise').trim(),
      offerTitle: 'Nouveau contact',
      lastMessage: '',
      lastTime: '',
      unread: 0,
      messages: [],
      logoUrl: widget.initialPeerPhotoUrl,
    );
    if (!mounted) return;
    setState(() {
      _conversations = [conv, ..._conversations];
      _selectedId = fallbackId;
    });
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  String _fmtHumanTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'maintenant';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${diff.inDays} j';
  }

  Future<void> _openConversation(String conversationId) async {
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx < 0) return;
    final conv = _conversations[idx];
    final thread = await _svc.getThread(conv.peerId);
    final data = (thread['data'] as Map?)?.cast<String, dynamic>() ?? {};
    final messages = List<Map<String, dynamic>>.from(
      data['messages'] ?? const [],
    );
    final interloc = data['interlocuteur'] as Map?;
    final photo = interloc?['photo_url']?.toString().trim();
    if (!mounted) return;
    setState(() {
      _selectedId = conversationId;
      _lastTimestamp = data['timestamp']?.toString();
      _activePeerPhotoUrl =
          (photo != null && photo.isNotEmpty) ? photo : null;
      _conversations[idx].messages
        ..clear()
        ..addAll(
          messages.map((m) => _msgFromMap(Map<String, dynamic>.from(m))),
        );
      _conversations[idx].unread = 0;
      if (MediaQuery.of(context).size.width < 900) {
        _showConversationOnMobile = true;
      }
    });
    _scrollerEnBas();
  }

  Future<void> _pollNouveauxMessages() async {
    if (_selectedId == null || _loading) return;
    final idx = _conversations.indexWhere((c) => c.id == _selectedId);
    if (idx < 0) return;
    final conv = _conversations[idx];
    try {
      final thread = await _svc.getThreadSince(
        conv.peerId,
        since: _lastTimestamp,
      );
      final data =
          (thread['data'] as Map?)?.cast<String, dynamic>() ?? const {};
      final incoming = List<Map<String, dynamic>>.from(
        data['messages'] ?? const [],
      );
      if (incoming.isEmpty) {
        _lastTimestamp = data['timestamp']?.toString() ?? _lastTimestamp;
        return;
      }
      if (!mounted) return;
      setState(() {
        _lastTimestamp = data['timestamp']?.toString() ?? _lastTimestamp;
        _conversations[idx].messages.addAll(
          incoming.map(
            (m) => _msgFromMap(Map<String, dynamic>.from(m)),
          ),
        );
        _autreEcrit = true;
      });
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() => _autreEcrit = false);
      });
      _scrollerEnBas();
    } catch (_) {}
  }

  void _scrollerEnBas() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  bool _changementJour(List<_Msg> messages, int index) {
    if (index == 0) return true;
    final d1 = messages[index].dateTime;
    final d2 = messages[index - 1].dateTime;
    if (d1 == null || d2 == null) return false;
    return d1.day != d2.day || d1.month != d2.month || d1.year != d2.year;
  }

  String _labelDate(String? iso) {
    try {
      if (iso == null || iso.isEmpty) return '';
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(dt.year, dt.month, dt.day);
      final diff = today.difference(target).inDays;
      if (diff == 0) return "Aujourd'hui";
      if (diff == 1) return 'Hier';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildSeparateurDate(String date) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            date,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
      ],
    ),
  );
}

class _Conversation {
  _Conversation({
    required this.id,
    required this.peerId,
    required this.companyName,
    required this.offerTitle,
    required this.lastMessage,
    required this.lastTime,
    required this.unread,
    required this.messages,
    this.offreId,
    this.logoUrl,
  });

  final String id;
  final String peerId;
  String companyName;
  String offerTitle;
  String lastMessage;
  String lastTime;
  int unread;
  final List<_Msg> messages;
  final String? offreId;
  String? logoUrl;

  String get initials {
    final parts = companyName.trim().split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _Msg {
  _Msg({
    this.id,
    required this.sender,
    required this.content,
    required this.time,
    this.dateIso,
    required this.read,
    this.pieceJointeUrl,
    this.pieceJointeNom,
  });
  final String? id;
  final String sender; // candidat | recruteur
  final String content;
  final String time;
  final String? dateIso;
  final bool read;
  final String? pieceJointeUrl;
  final String? pieceJointeNom;

  DateTime? get dateTime {
    final iso = dateIso;
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso)?.toLocal();
  }
}

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({
    required this.msg,
    required this.isMe,
    this.onLongPress,
  });

  final _Msg msg;
  final bool isMe;
  final VoidCallback? onLongPress;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: Offset(widget.isMe ? 0.3 : -0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.msg;
    final isMe = widget.isMe;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onLongPress: widget.onLongPress,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.52,
              ),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF1A56DB) : Colors.white,
                borderRadius: BorderRadius.circular(12).copyWith(
                  bottomRight: isMe ? const Radius.circular(2) : null,
                  bottomLeft: !isMe ? const Radius.circular(2) : null,
                ),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: isMe
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (msg.pieceJointeUrl != null && msg.pieceJointeUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: isMe ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () async {
                            final u = Uri.tryParse(msg.pieceJointeUrl!);
                            if (u != null && await canLaunchUrl(u)) {
                              await launchUrl(u, mode: LaunchMode.externalApplication);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.attach_file_rounded,
                                  size: 18,
                                  color: isMe ? Colors.white : const Color(0xFF1A56DB),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    (msg.pieceJointeNom != null && msg.pieceJointeNom!.isNotEmpty)
                                        ? msg.pieceJointeNom!
                                        : 'Pièce jointe',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isMe ? Colors.white : const Color(0xFF1A56DB),
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
                    ),
                  Text(
                    msg.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? Colors.white : const Color(0xFF0F172A),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg.time,
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe ? Colors.white70 : const Color(0xFF94A3B8),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg.read ? Icons.done_all_rounded : Icons.done_rounded,
                          size: 12,
                          color: msg.read ? Colors.white : Colors.white.withValues(alpha: 0.6),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PointAnimation extends StatefulWidget {
  const _PointAnimation({required this.delai});
  final int delai;

  @override
  State<_PointAnimation> createState() => _PointAnimationState();
}

class _PointAnimationState extends State<_PointAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0.35, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future<void>.delayed(Duration(milliseconds: widget.delai), () {
      if (!mounted) return;
      _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: const CircleAvatar(
        radius: 2.5,
        backgroundColor: Color(0xFF94A3B8),
      ),
    );
  }
}

class _HeaderPeerAvatar extends StatelessWidget {
  const _HeaderPeerAvatar({
    required this.conv,
    this.photoUrl,
  });

  final _Conversation conv;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final u = (photoUrl != null && photoUrl!.isNotEmpty)
        ? photoUrl!
        : (conv.logoUrl ?? '');
    if (u.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFFE2E8F0),
        backgroundImage: NetworkImage(u),
        onBackgroundImageError: (_, _) {},
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFE2E8F0),
      child: Text(
        conv.initials,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF334155),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({required this.conv});

  final _Conversation conv;

  @override
  Widget build(BuildContext context) {
    final u = conv.logoUrl;
    if (u != null && u.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFFE2E8F0),
        backgroundImage: NetworkImage(u),
        onBackgroundImageError: (error, stackTrace) {},
        child: null,
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFFE2E8F0),
      child: Text(
        conv.initials,
        style: const TextStyle(color: Color(0xFF334155)),
      ),
    );
  }
}
