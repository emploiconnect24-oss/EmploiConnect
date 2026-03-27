import 'package:flutter/material.dart';

import '../../widgets/responsive_container.dart';

class RecruteurMessagerieScreen extends StatefulWidget {
  const RecruteurMessagerieScreen({super.key, this.candidatId});
  final String? candidatId;

  @override
  State<RecruteurMessagerieScreen> createState() => _RecruteurMessagerieScreenState();
}

class _RecruteurMessagerieScreenState extends State<RecruteurMessagerieScreen> {
  final _searchCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _showConversationOnMobile = false;

  final List<_Conversation> _conversations = _seedConversations();
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.candidatId ?? _conversations.first.id;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  _Conversation get _selected {
    final id = _selectedId;
    return _conversations.firstWhere(
      (c) => c.id == id,
      orElse: () => _conversations.first,
    );
  }

  List<_Conversation> get _filteredConversations {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _conversations;
    return _conversations.where((c) {
      return c.candidateName.toLowerCase().contains(q) ||
          c.candidateTitle.toLowerCase().contains(q) ||
          c.offerTitle.toLowerCase().contains(q) ||
          c.lastMessage.toLowerCase().contains(q);
    }).toList();
  }

  void _sendMessage() {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;
    final idx = _conversations.indexWhere((c) => c.id == _selected.id);
    if (idx < 0) return;
    setState(() {
      _conversations[idx].messages.add(
            _Msg(
              sender: 'entreprise',
              content: text,
              time: _nowLabel(),
            ),
          );
      _conversations[idx].lastMessage = text;
      _conversations[idx].lastTime = 'à l’instant';
      _conversations[idx].unread = false;
      _messageCtrl.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _nowLabel() {
    final now = TimeOfDay.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: LayoutBuilder(
        builder: (context, c) {
          final isMobile = c.maxWidth < 820;
          if (isMobile) {
            return _showConversationOnMobile ? _buildConversationMobile() : _buildListMobile();
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 340, child: _buildConversationsList()),
              const SizedBox(width: 12),
              Expanded(child: _buildConversationView()),
            ],
          );
        },
      ),
    );
  }

  Widget _header({required bool mobile}) {
    return Row(
      children: [
        if (mobile && _showConversationOnMobile)
          IconButton(
            onPressed: () => setState(() => _showConversationOnMobile = false),
            icon: const Icon(Icons.arrow_back),
          ),
        const Text('Messagerie', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Composer un nouveau message (API à brancher)')),
            );
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Nouveau message'),
        ),
      ],
    );
  }

  Widget _buildConversationsList() {
    final list = _filteredConversations;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _header(mobile: false),
            const SizedBox(height: 10),
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('Aucune conversation'))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final c = list[i];
                        final selected = c.id == _selected.id;
                        return InkWell(
                          onTap: () => setState(() => _selectedId = c.id),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFFEEF2FF) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFFDBEAFE),
                                  child: Text(c.initials, style: const TextStyle(color: Color(0xFF1D4ED8))),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              c.candidateName,
                                              style: const TextStyle(fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                          Text(
                                            c.lastTime,
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        c.lastMessage,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Color(0xFF64748B)),
                                      ),
                                      if (c.unread)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2),
                                          child: Text('● non lu', style: TextStyle(fontSize: 12, color: Color(0xFF1D4ED8))),
                                        ),
                                    ],
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFDBEAFE),
                  child: Text(conv.initials, style: const TextStyle(color: Color(0xFF1D4ED8))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${conv.candidateName} · ${conv.candidateTitle}',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text('Offre: ${conv.offerTitle}', style: const TextStyle(color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Profil'),
                ),
              ],
            ),
            const Divider(height: 18),
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                itemCount: conv.messages.length,
                itemBuilder: (context, i) {
                  final msg = conv.messages[i];
                  final isMe = msg.sender == 'entreprise';
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.55),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFF1A56DB) : Colors.white,
                        borderRadius: BorderRadius.circular(12).copyWith(
                          bottomRight: isMe ? const Radius.circular(2) : null,
                          bottomLeft: !isMe ? const Radius.circular(2) : null,
                        ),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            msg.content,
                            style: TextStyle(
                              fontSize: 14,
                              color: isMe ? Colors.white : const Color(0xFF0F172A),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg.time,
                            style: TextStyle(
                              fontSize: 11,
                              color: isMe ? Colors.white70 : const Color(0xFF94A3B8),
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
                IconButton(onPressed: () {}, icon: const Icon(Icons.attach_file)),
                Expanded(
                  child: TextField(
                    controller: _messageCtrl,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Écrire un message...',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
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
        _header(mobile: true),
        const SizedBox(height: 10),
        TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'Rechercher...', prefixIcon: Icon(Icons.search), isDense: true),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('Aucune conversation'))
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final c = list[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFDBEAFE),
                        child: Text(c.initials, style: const TextStyle(color: Color(0xFF1D4ED8))),
                      ),
                      title: Text(c.candidateName),
                      subtitle: Text(c.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Text(c.lastTime),
                      onTap: () => setState(() {
                        _selectedId = c.id;
                        _showConversationOnMobile = true;
                      }),
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
        _header(mobile: true),
        const SizedBox(height: 8),
        Expanded(child: _buildConversationView()),
      ],
    );
  }
}

class _Conversation {
  _Conversation({
    required this.id,
    required this.candidateName,
    required this.candidateTitle,
    required this.offerTitle,
    required this.lastMessage,
    required this.lastTime,
    required this.unread,
    required this.messages,
  });

  final String id;
  final String candidateName;
  final String candidateTitle;
  final String offerTitle;
  String lastMessage;
  String lastTime;
  bool unread;
  final List<_Msg> messages;

  String get initials {
    final parts = candidateName.trim().split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _Msg {
  _Msg({required this.sender, required this.content, required this.time});
  final String sender;
  final String content;
  final String time;
}

List<_Conversation> _seedConversations() {
  return [
    _Conversation(
      id: 'c1',
      candidateName: 'Mamadou Barry',
      candidateTitle: 'Développeur Flutter',
      offerTitle: 'Développeur Flutter Senior',
      lastMessage: 'Merci pour votre retour, je reste disponible.',
      lastTime: '2 min',
      unread: true,
      messages: [
        _Msg(sender: 'entreprise', content: 'Bonjour Mamadou, nous avons bien reçu votre candidature.', time: '10:30'),
        _Msg(sender: 'candidat', content: 'Merci pour votre retour ! Je suis très intéressé par le poste.', time: '10:45'),
      ],
    ),
    _Conversation(
      id: 'c2',
      candidateName: 'Aissatou Diallo',
      candidateTitle: 'UX Designer',
      offerTitle: 'Product Designer',
      lastMessage: 'Oui, je suis disponible pour un entretien.',
      lastTime: '1 h',
      unread: false,
      messages: [
        _Msg(sender: 'candidat', content: 'Bonjour, merci pour votre message.', time: '09:12'),
        _Msg(sender: 'entreprise', content: 'Seriez-vous disponible cette semaine ?', time: '09:22'),
      ],
    ),
    _Conversation(
      id: 'c3',
      candidateName: 'Ibrahima Bah',
      candidateTitle: 'Chef de projet',
      offerTitle: 'PM Senior',
      lastMessage: 'Merci, à bientôt.',
      lastTime: '3 h',
      unread: false,
      messages: [
        _Msg(sender: 'entreprise', content: 'Votre profil nous intéresse.', time: '08:10'),
        _Msg(sender: 'candidat', content: 'Merci, à bientôt.', time: '08:16'),
      ],
    ),
  ];
}
