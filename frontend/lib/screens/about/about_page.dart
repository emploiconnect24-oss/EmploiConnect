import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme_extension.dart';
import '../auth/auth_widgets.dart';
import '../../services/api_service.dart';

/// Page « À propos » (contenu API `/apropos`).
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final _api = ApiService();
  List<Map<String, dynamic>> _sections = [];
  bool _isLoading = true;
  String _nomPlateforme = 'EmploiConnect';
  String _emailContact = '';
  String _telephoneContact = '';
  String _adresseContact = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final resAbout = await _api.get('/apropos', useAuth: false);
      final resGen = await _api.get('/config/general', useAuth: false);

      if (resAbout.statusCode == 200) {
        final body = jsonDecode(resAbout.body) as Map<String, dynamic>;
        final list = body['data'];
        if (!mounted) return;
        setState(() {
          _sections = list is List
              ? list.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              : [];
        });
      }

      if (resGen.statusCode == 200) {
        final g = jsonDecode(resGen.body);
        if (g is Map<String, dynamic> && g['data'] is Map && mounted) {
          final d = Map<String, dynamic>.from(g['data'] as Map);
          final np = d['nom_plateforme']?.toString().trim();
          setState(() {
            if (np != null && np.isNotEmpty) _nomPlateforme = np;
            _emailContact = d['email_contact']?.toString() ?? '';
            _telephoneContact = d['telephone_contact']?.toString() ?? '';
            _adresseContact = d['adresse_contact']?.toString() ?? '';
          });
        }
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? _section(String s) {
    for (final x in _sections) {
      if (x['section'] == s) return x;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final hero = _section('hero');
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  backgroundColor: cs.surface,
                  toolbarHeight: 64,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
                    onPressed: () => Navigator.of(context).canPop()
                        ? Navigator.of(context).pop()
                        : Navigator.of(context).pushNamed('/landing'),
                  ),
                  title: AuthLogoHeader(couleurTexte: cs.onSurface),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 48 : 80),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A56DB), Color(0xFF4F46E5)],
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              hero?['icone'] as String? ?? '🏢',
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          hero?['titre'] as String? ?? 'À propos d\'EmploiConnect',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 28 : 40,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          hero?['contenu'] as String? ?? '',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 14 : 17,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: 60),
                    child: Column(
                      children: [
                        if (isMobile) ...[
                          _buildSection('mission'),
                          const SizedBox(height: 20),
                          _buildSection('vision'),
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildSection('mission')),
                              const SizedBox(width: 20),
                              Expanded(child: _buildSection('vision')),
                            ],
                          ),
                        const SizedBox(height: 20),
                        _buildSection('valeurs', pleineLargeur: true),
                        const SizedBox(height: 20),
                        _buildSection('equipe', pleineLargeur: true),
                        const SizedBox(height: 20),
                        _buildStats(),
                        const SizedBox(height: 20),
                        _buildContact(),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                    color: const Color(0xFF0D1B3E),
                    child: Text(
                      '© 2026 $_nomPlateforme · Guinée',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSection(String section, {bool pleineLargeur = false}) {
    final s = _section(section);
    if (s == null) return const SizedBox();
    final cs = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    return Container(
      width: pleineLargeur ? double.infinity : null,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ext.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(s['icone'] as String? ?? '📌', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s['titre'] as String? ?? '',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            s['contenu'] as String? ?? '',
            style: GoogleFonts.inter(fontSize: 14, color: cs.onSurfaceVariant, height: 1.7),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1A56DB), Color(0xFF4F46E5)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              '$_nomPlateforme en chiffres',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: const [
                _StatAbout('🏢', '500+', 'Entreprises'),
                _StatAbout('👥', '2000+', 'Candidats'),
                _StatAbout('💼', '150+', 'Offres actives'),
                _StatAbout('⭐', '98%', 'Satisfaction'),
              ],
            ),
          ],
        ),
      );

  Widget _buildContact() {
    final s = _section('contact');
    final cs = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ext.infoBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(s?['icone'] as String? ?? '📞', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                s?['titre'] as String? ?? 'Contact',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            s?['contenu'] as String? ?? '',
            style: GoogleFonts.inter(fontSize: 14, color: cs.onSurfaceVariant, height: 1.7),
          ),
          if (_emailContact.trim().isNotEmpty ||
              _telephoneContact.trim().isNotEmpty ||
              _adresseContact.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Coordonnées (paramètres plateforme)',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 8),
            if (_emailContact.trim().isNotEmpty)
              _AboutContactLine(icon: Icons.email_outlined, text: _emailContact.trim()),
            if (_telephoneContact.trim().isNotEmpty)
              _AboutContactLine(icon: Icons.phone_outlined, text: _telephoneContact.trim()),
            if (_adresseContact.trim().isNotEmpty)
              _AboutContactLine(icon: Icons.place_outlined, text: _adresseContact.trim()),
          ],
        ],
      ),
    );
  }
}

class _AboutContactLine extends StatelessWidget {
  const _AboutContactLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              text,
              style: GoogleFonts.inter(fontSize: 14, color: cs.onSurface, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatAbout extends StatelessWidget {
  const _StatAbout(this.emoji, this.val, this.label);
  final String emoji;
  final String val;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          Text(val, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.white60)),
        ],
      );
}
