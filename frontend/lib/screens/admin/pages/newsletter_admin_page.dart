import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/admin_service.dart';

/// Abonnés newsletter + envoi d’e-mail groupé (PRD §3).
class NewsletterAdminPage extends StatefulWidget {
  const NewsletterAdminPage({super.key});

  @override
  State<NewsletterAdminPage> createState() => _NewsletterAdminPageState();
}

class _NewsletterAdminPageState extends State<NewsletterAdminPage> {
  final _admin = AdminService();
  final _sujetCtrl = TextEditingController();
  final _contenuCtrl = TextEditingController();

  List<Map<String, dynamic>> _abonnes = [];
  int _total = 0;
  bool _loading = true;
  bool _envoi = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _sujetCtrl.dispose();
    _contenuCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final res = await _admin.getNewsletterAbonnes(actifsOnly: true);
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final list = (data['abonnes'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final t = data['total'];
      if (!mounted) return;
      setState(() {
        _abonnes = list;
        _total = t is int ? t : int.tryParse(t?.toString() ?? '') ?? list.length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = '$e';
      });
    }
  }

  Future<void> _envoyer() async {
    final sujet = _sujetCtrl.text.trim();
    final contenu = _contenuCtrl.text.trim();
    if (sujet.isEmpty || contenu.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Renseignez le sujet et le contenu HTML/texte.')),
      );
      return;
    }
    setState(() => _envoi = true);
    try {
      final res = await _admin.postNewsletterEnvoyer(sujet: sujet, contenu: contenu);
      if (!mounted) return;
      final ok = res['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? (ok ? 'Envoyé.' : 'Échec')),
          backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Newsletter',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          Text(
            '$_total abonné(s) actif(s). Les e-mails partent via SMTP (paramètres plateforme).',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          if (_message != null)
            Text(_message!, style: const TextStyle(color: Color(0xFFB91C1C))),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Card(
                    child: _loading
                        ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                        : ListView.separated(
                            itemCount: _abonnes.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (ctx, i) {
                              final a = _abonnes[i];
                              final em = a['email']?.toString() ?? '';
                              final nom = a['nom']?.toString();
                              return ListTile(
                                dense: true,
                                title: Text(em, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                subtitle: nom != null && nom.isNotEmpty ? Text(nom) : null,
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Campagne', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _sujetCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Sujet',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: TextField(
                              controller: _contenuCtrl,
                              maxLines: null,
                              expands: true,
                              decoration: const InputDecoration(
                                labelText: 'Contenu (HTML autorisé)',
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(),
                              ),
                              textAlignVertical: TextAlignVertical.top,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _envoi ? null : _envoyer,
                            icon: _envoi
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.send_rounded),
                            label: const Text('Envoyer à tous les abonnés actifs'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
