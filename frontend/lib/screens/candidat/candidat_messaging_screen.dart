import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/candidat_messages_service.dart';
import 'candidat_applications_screen.dart';

class CandidatMessagingScreen extends StatefulWidget {
  const CandidatMessagingScreen({super.key});

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

  void _sendMessage() {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;
    final idx = _conversations.indexWhere((c) => c.id == _selected.id);
    if (idx < 0) return;
    final conv = _conversations[idx];
    _svc
        .sendMessage(conv.peerId, text, offreId: conv.offreId)
        .then((_) => _openConversation(conv.id))
        .catchError((e) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        });
    _messageCtrl.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _nowLabel() {
    final now = TimeOfDay.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
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
                _ConversationAvatar(conv: conv),
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
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                itemCount: conv.messages.length,
                itemBuilder: (_, i) {
                  final msg = conv.messages[i];
                  final isMe = msg.sender == 'candidat';
                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.52,
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
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
                              color: isMe
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg.read ? '${msg.time} • lu' : msg.time,
                            style: TextStyle(
                              fontSize: 11,
                              color: isMe
                                  ? Colors.white70
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Envoi de pièce jointe à connecter.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.attach_file),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageCtrl,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Écrire votre message...',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Envoyer'),
                ),
              ],
            ),
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
      logoUrl: r['entreprise_logo_url']?.toString(),
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
      if (_selectedId != null) await _openConversation(_selectedId!);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
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
    final messages = List<Map<String, dynamic>>.from(
      (thread['data']?['messages']) ?? const [],
    );
    if (!mounted) return;
    setState(() {
      _selectedId = conversationId;
      _lastTimestamp = thread['data']?['timestamp']?.toString();
      _conversations[idx].messages
        ..clear()
        ..addAll(
          messages.map(
            (m) => _Msg(
              sender: (m['is_mine'] == true) ? 'candidat' : 'recruteur',
              content: m['contenu']?.toString() ?? '',
              time: _nowLabel(),
              read: m['est_lu'] == true,
              pieceJointeUrl: m['piece_jointe_url']?.toString(),
              pieceJointeNom: m['piece_jointe_nom']?.toString(),
            ),
          ),
        );
      _conversations[idx].unread = 0;
      if (MediaQuery.of(context).size.width < 900) {
        _showConversationOnMobile = true;
      }
    });
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
            (m) => _Msg(
              sender: (m['is_mine'] == true) ? 'candidat' : 'recruteur',
              content: m['contenu']?.toString() ?? '',
              time: _nowLabel(),
              read: m['est_lu'] == true,
              pieceJointeUrl: m['piece_jointe_url']?.toString(),
              pieceJointeNom: m['piece_jointe_nom']?.toString(),
            ),
          ),
        );
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollCtrl.hasClients) return;
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      });
    } catch (_) {}
  }
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
    required this.sender,
    required this.content,
    required this.time,
    required this.read,
    this.pieceJointeUrl,
    this.pieceJointeNom,
  });
  final String sender; // candidat | recruteur
  final String content;
  final String time;
  final bool read;
  final String? pieceJointeUrl;
  final String? pieceJointeNom;
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
        onBackgroundImageError: (context, error, stackTrace) {},
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
