import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/admin_service.dart';

class NewsletterAdminPage extends StatefulWidget {
  const NewsletterAdminPage({super.key});

  @override
  State<NewsletterAdminPage> createState() => _NewsletterAdminPageState();
}

class _NewsletterAdminPageState extends State<NewsletterAdminPage>
    with SingleTickerProviderStateMixin {
  final _admin = AdminService();
  final _sujetCtrl = TextEditingController();
  final _contenuCtrl = TextEditingController();

  List<Map<String, dynamic>> _abonnes = [];
  List<Map<String, dynamic>> _envois = [];
  int _totalAbonnes = 0;
  bool _isLoading = true;
  bool _isEnvoi = false;
  String? _message;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _sujetCtrl.dispose();
    _contenuCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      final abonnements = await _admin.getNewsletterAbonnes(actifsOnly: true);
      final historique = await _admin.getNewsletterHistorique(limite: 100);
      final data = abonnements['data'] as Map<String, dynamic>? ?? {};
      final listAbonnes = (data['abonnes'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final listEnvois = (historique['data'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final t = data['total'];
      if (!mounted) return;
      setState(() {
        _abonnes = listAbonnes;
        _envois = listEnvois;
        _totalAbonnes = t is int ? t : int.tryParse(t?.toString() ?? '') ?? listAbonnes.length;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _message = '$e';
      });
    }
  }

  Future<void> _envoyerManuel() async {
    final sujet = _sujetCtrl.text.trim();
    final contenu = _contenuCtrl.text.trim();
    if (sujet.isEmpty || contenu.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Renseignez le sujet et le contenu.')),
      );
      return;
    }
    setState(() => _isEnvoi = true);
    try {
      final res = await _admin.postNewsletterEnvoyer(sujet: sujet, contenu: contenu);
      if (!mounted) return;
      final ok = res['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? (ok ? 'Envoyé.' : 'Échec')),
          backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (ok) {
        _contenuCtrl.clear();
        _sujetCtrl.clear();
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isEnvoi = false);
    }
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Newsletter',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Gerez vos abonnes et envois',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A56DB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people_rounded, color: Color(0xFF1A56DB), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '$_totalAbonnes abonnes',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A56DB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabCtrl,
                labelColor: const Color(0xFF1A56DB),
                unselectedLabelColor: const Color(0xFF94A3B8),
                indicatorColor: const Color(0xFF1A56DB),
                tabs: const [
                  Tab(text: 'Abonnes'),
                  Tab(text: 'Envoyer'),
                  Tab(text: 'Historique'),
                ],
              ),
            ],
          ),
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_message!, style: const TextStyle(color: Color(0xFFB91C1C))),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildAbonnes(),
              _buildEnvoyer(),
              _buildHistorique(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAbonnes() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1A56DB)));
    }
    if (_abonnes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, color: Color(0xFFE2E8F0), size: 48),
            const SizedBox(height: 12),
            Text(
              'Aucun abonne pour le moment',
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8)),
            ),
            Text(
              'Les inscriptions viennent du footer',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1)),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _abonnes.length,
      itemBuilder: (ctx, i) {
        final ab = _abonnes[i];
        final email = ab['email']?.toString() ?? '';
        final nom = ab['nom']?.toString() ?? 'Anonyme';
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF1A56DB).withValues(alpha: 0.1),
            child: Text(
              email.isEmpty ? 'A' : email[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF1A56DB),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          title: Text(
            email,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            nom,
            style: GoogleFonts.inter(fontSize: 11),
          ),
          trailing: Text(
            _formatDate(ab['date_inscription']?.toString()),
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnvoyer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1A56DB).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Color(0xFF1A56DB), size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'La newsletter IA automatique est configuree dans Parametres > Contenu > Newsletter.\nIci vous pouvez envoyer une newsletter manuelle.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF1E40AF),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _sujetCtrl,
            decoration: InputDecoration(
              labelText: 'Sujet *',
              hintText: 'Ex: Nouvelles offres de la semaine',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contenuCtrl,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: 'Contenu *',
              hintText: 'Redigez votre newsletter...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF94A3B8), size: 14),
                const SizedBox(width: 8),
                Text(
                  'Sera envoye a $_totalAbonnes abonne(s) actif(s)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isEnvoi
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(
                _isEnvoi ? 'Envoi en cours...' : 'Envoyer maintenant',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isEnvoi ? null : _envoyerManuel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorique() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1A56DB)));
    }
    if (_envois.isEmpty) {
      return Center(
        child: Text(
          'Aucun envoi pour le moment',
          style: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _envois.length,
      itemBuilder: (ctx, i) {
        final e = _envois[i];
        final source = e['source']?.toString() ?? 'manuel';
        final ia = source == 'ia_auto' || source == 'hebdo';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (ia ? const Color(0xFF8B5CF6) : const Color(0xFF1A56DB)).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  ia ? Icons.auto_awesome_rounded : Icons.send_rounded,
                  color: ia ? const Color(0xFF8B5CF6) : const Color(0xFF1A56DB),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e['sujet']?.toString() ?? '',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${e['nb_destinataires'] ?? 0} envois · ${ia ? 'IA' : 'Manuel'} · ${_formatDate(e['date_envoi']?.toString())}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
