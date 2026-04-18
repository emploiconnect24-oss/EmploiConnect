import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/admin_provider.dart';
import '../../../services/admin_service.dart';

class MessagesContactAdminPage extends StatefulWidget {
  const MessagesContactAdminPage({super.key});

  @override
  State<MessagesContactAdminPage> createState() => _MessagesContactAdminPageState();
}

class _MessagesContactAdminPageState extends State<MessagesContactAdminPage> {
  final _admin = AdminService();
  bool _loading = true;
  int _nonLus = 0;
  List<Map<String, dynamic>> _messages = const [];
  String? _iaEnCoursId;
  String? _reponseEnCoursId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _admin.getMessagesContactAdmin();
      final rows = res['data'] is List
          ? (res['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];
      final n = res['non_lus'];
      if (!mounted) return;
      setState(() {
        _messages = rows;
        _nonLus = n is int ? n : int.tryParse(n?.toString() ?? '') ?? 0;
        _loading = false;
      });
      context.read<AdminProvider>().updateNbMessagesContactNonLus(_nonLus);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages = const [];
        _nonLus = 0;
        _loading = false;
      });
      context.read<AdminProvider>().updateNbMessagesContactNonLus(0);
    }
  }

  Future<void> _marquerLu(String id) async {
    if (id.isEmpty) return;
    await _admin.patchMessageContactLu(id);
    if (!mounted) return;
    await _load();
  }

  Future<void> _envoyerReponse(Map<String, dynamic> msg, String reponse) async {
    final id = msg['id']?.toString() ?? '';
    if (id.isEmpty || reponse.isEmpty) return;
    setState(() => _reponseEnCoursId = id);
    try {
      final res = await _admin.postMessageContactRepondre(id, reponse: reponse);
      if (!mounted) return;
      final ok = res['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? (ok ? 'Reponse envoyee' : 'Echec envoi')),
          backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (ok) await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _reponseEnCoursId = null);
    }
  }

  Future<void> _repondreAvecIA(Map<String, dynamic> msg) async {
    final id = msg['id']?.toString() ?? '';
    if (id.isEmpty) return;
    setState(() => _iaEnCoursId = id);
    try {
      final res = await _admin.postMessageContactRepondreIa(id);
      if (!mounted) return;
      final ok = res['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? (ok ? 'Reponse IA envoyee' : 'Echec reponse IA')),
          backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (ok) await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _iaEnCoursId = null);
    }
  }

  Future<void> _showDialogRepondre(Map<String, dynamic> msg) async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Repondre a ${msg['nom'] ?? ''}'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A : ${msg['email'] ?? ''}',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: ctrl,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Votre reponse...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56DB),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () async {
              final texte = ctrl.text.trim();
              Navigator.pop(ctx);
              await _envoyerReponse(msg, texte);
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  String _formatDate(String? raw) {
    final dt = DateTime.tryParse(raw ?? '');
    if (dt == null) return '-';
    final d = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A56DB)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Text(
                'Messages de contact',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 10),
              if (_nonLus > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$_nonLus non lu(s)',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Actualiser'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_messages.isEmpty)
            Text(
              'Aucun message reçu pour le moment.',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
            )
          else
            ..._messages.map((m) {
              final id = m['id']?.toString() ?? '';
              final estLu = m['est_lu'] == true;
              final estRepondu = m['repondu_le'] != null;
              final reponseIa = m['reponse_ia']?.toString().trim() ?? '';
              final aReponseIa = reponseIa.isNotEmpty;
              final nom = m['nom']?.toString() ?? 'Inconnu';
              final email = m['email']?.toString() ?? '';
              final sujet = m['sujet']?.toString().trim() ?? '';
              final message = m['message']?.toString() ?? '';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: estLu ? const Color(0xFFE2E8F0) : const Color(0xFFEF4444).withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          estLu ? Icons.mark_email_read_outlined : Icons.mark_email_unread_outlined,
                          size: 17,
                          color: estLu ? const Color(0xFF94A3B8) : const Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$nom ($email)',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (!estLu)
                          TextButton(
                            onPressed: () => _marquerLu(id),
                            child: const Text('Marquer lu'),
                          ),
                      ],
                    ),
                    if (sujet.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        sujet,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A56DB),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569), height: 1.45),
                    ),
                    const SizedBox(height: 10),
                    if (estRepondu)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF10B981),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              aReponseIa ? 'Repondu par IA' : 'Repondu',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (estRepondu) const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          icon: _reponseEnCoursId == id
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.reply_rounded, size: 14),
                          label: Text(estRepondu ? 'Repondre a nouveau' : 'Repondre'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF1A56DB)),
                            foregroundColor: const Color(0xFF1A56DB),
                          ),
                          onPressed: _reponseEnCoursId == id ? null : () => _showDialogRepondre(m),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: _iaEnCoursId == id
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Icon(
                                  estRepondu && aReponseIa
                                      ? Icons.check_rounded
                                      : Icons.auto_awesome_rounded,
                                  size: 14,
                                ),
                          label: Text(
                            _iaEnCoursId == id
                                ? 'Envoi...'
                                : estRepondu && aReponseIa
                                    ? 'IA deja envoyee'
                                    : 'Reponse IA',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: estRepondu && aReponseIa
                                ? const Color(0xFF10B981).withValues(alpha: 0.6)
                                : const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          onPressed: (estRepondu && aReponseIa) || _iaEnCoursId == id
                              ? null
                              : () => _repondreAvecIA(m),
                        ),
                      ],
                    ),
                    if (estRepondu && aReponseIa) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Color(0xFF8B5CF6),
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Reponse IA envoyee',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF8B5CF6),
                                  ),
                                ),
                                const Spacer(),
                                if (m['repondu_le'] != null)
                                  Text(
                                    _formatDate(m['repondu_le']?.toString()),
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              reponseIa.length > 150 ? '${reponseIa.substring(0, 150)}...' : reponseIa,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
