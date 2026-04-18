import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../auth/auth_widgets.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _equipe = [];
  Map<String, dynamic> _config = {};
  bool _isLoading = true;

  int _nbCandidats = 0;
  int _nbEntreprises = 0;
  int _nbOffres = 0;
  late final AnimationController _statsCtrl;

  @override
  void initState() {
    super.initState();
    _statsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _loadAll();
  }

  @override
  void dispose() {
    _statsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$apiBaseUrl$apiPrefix/apropos')),
        http.get(Uri.parse('$apiBaseUrl$apiPrefix/apropos/equipe')),
        http.get(Uri.parse('$apiBaseUrl$apiPrefix/stats/homepage')),
        http.get(Uri.parse('$apiBaseUrl$apiPrefix/config/general')),
      ]);

      final sections = jsonDecode(responses[0].body) as Map<String, dynamic>;
      final equipe = jsonDecode(responses[1].body) as Map<String, dynamic>;
      final stats = jsonDecode(responses[2].body) as Map<String, dynamic>;
      final config = jsonDecode(responses[3].body) as Map<String, dynamic>;

      if (!mounted) return;
      final sRows = sections['data'] is List
          ? (sections['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];
      final eRows = equipe['data'] is List
          ? (equipe['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];
      final cfg = config['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(config['data'] as Map<String, dynamic>)
          : <String, dynamic>{};
      final sData = stats['data'] is Map ? Map<String, dynamic>.from(stats['data'] as Map) : <String, dynamic>{};

      int asInt(dynamic v) {
        if (v is int) return v;
        if (v is num) return v.round();
        return int.tryParse(v?.toString() ?? '') ?? 0;
      }

      setState(() {
        _sections = sRows;
        _equipe = eRows;
        _config = cfg;
        _nbCandidats = asInt(sData['candidats']);
        _nbEntreprises = asInt(sData['entreprises']);
        _nbOffres = asInt(sData['offres']);
        _isLoading = false;
      });
      _statsCtrl.forward(from: 0);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? _section(String key) {
    for (final s in _sections) {
      if (s['section']?.toString() == key) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A56DB)),
            )
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : const Color(0xFF374151),
                    ),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushNamed('/landing');
                      }
                    },
                  ),
                  title: AuthLogoHeader(couleurTexte: isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
                SliverToBoxAdapter(child: _buildHero(isMobile)),
                SliverToBoxAdapter(child: _buildStats(isMobile, isDark)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : 80,
                      vertical: 48,
                    ),
                    child: Column(
                      children: [
                        isMobile
                            ? Column(
                                children: [
                                  _buildSection('mission', isDark),
                                  const SizedBox(height: 16),
                                  _buildSection('vision', isDark),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(child: _buildSection('mission', isDark)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildSection('vision', isDark)),
                                ],
                              ),
                        const SizedBox(height: 16),
                        _buildSection('valeurs', isDark, pleineLargeur: true),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _buildEquipe(isMobile, isDark)),
                SliverToBoxAdapter(child: _buildContact(isMobile, isDark)),
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    color: const Color(0xFF0D1B3E),
                    child: Text(
                      '© 2026 ${_config['nom_plateforme'] ?? 'EmploiConnect'} · Guinée',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHero(bool isMobile) {
    final s = _section('hero');
    return Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '🇬🇳 La plateforme guinéenne de l\'emploi',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            s?['titre']?.toString() ?? 'À propos d\'EmploiConnect',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 28 : 44,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            s?['contenu']?.toString() ?? '',
            style: GoogleFonts.inter(
              fontSize: isMobile ? 14 : 17,
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStats(bool isMobile, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: 40),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Column(
        children: [
          Text(
            'Nos chiffres',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Des résultats réels, mesurés chaque jour',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _StatAnimee(
                ctrl: _statsCtrl,
                valeur: _nbCandidats,
                label: 'Candidats inscrits',
                icone: '👤',
                couleur: const Color(0xFF1A56DB),
              ),
              _StatAnimee(
                ctrl: _statsCtrl,
                valeur: _nbEntreprises,
                label: 'Entreprises partenaires',
                icone: '🏢',
                couleur: const Color(0xFF10B981),
              ),
              _StatAnimee(
                ctrl: _statsCtrl,
                valeur: _nbOffres,
                label: 'Offres publiées',
                icone: '💼',
                couleur: const Color(0xFF8B5CF6),
              ),
              _StatAnimee(
                ctrl: _statsCtrl,
                valeur: 98,
                label: '% Satisfaction',
                icone: '⭐',
                couleur: const Color(0xFFF59E0B),
                suffixe: '%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String section, bool isDark, {bool pleineLargeur = false}) {
    final s = _section(section);
    if (s == null) return const SizedBox.shrink();
    return Container(
      width: pleineLargeur ? double.infinity : null,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(s['icone']?.toString() ?? '📌', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s['titre']?.toString() ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            s['contenu']?.toString() ?? '',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipe(bool isMobile, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: 60),
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      child: Column(
        children: [
          Text(
            'Notre Équipe',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les personnes passionnées derrière EmploiConnect',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 40),
          if (_equipe.isEmpty)
            Text(
              'Équipe en cours de configuration...',
              style: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
            )
          else
            Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: _equipe
                  .map((m) => _CarteMembreEquipe(
                        membre: m,
                        isDark: isDark,
                        isMobile: isMobile,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildContact(bool isMobile, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: 60),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFF0F7FF), Colors.white],
        ),
      ),
      child: isMobile
          ? Column(
              children: [
                _infosContact(isDark),
                const SizedBox(height: 32),
                _FormContact(isDark: isDark),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _infosContact(isDark)),
                const SizedBox(width: 48),
                Expanded(flex: 3, child: _FormContact(isDark: isDark)),
              ],
            ),
    );
  }

  Widget _infosContact(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nous contacter',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Une question ? Un partenariat ? N\'hésitez pas à nous écrire.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        if ((_config['email_contact'] ?? '').toString().isNotEmpty)
          _InfoContactItem(
            icone: Icons.email_outlined,
            valeur: _config['email_contact'].toString(),
          ),
        if ((_config['telephone_contact'] ?? '').toString().isNotEmpty)
          _InfoContactItem(
            icone: Icons.phone_outlined,
            valeur: _config['telephone_contact'].toString(),
          ),
        if ((_config['adresse_contact'] ?? '').toString().isNotEmpty)
          _InfoContactItem(
            icone: Icons.location_on_outlined,
            valeur: _config['adresse_contact'].toString(),
          ),
      ],
    );
  }
}

class _StatAnimee extends StatelessWidget {
  const _StatAnimee({
    required this.ctrl,
    required this.valeur,
    required this.label,
    required this.icone,
    required this.couleur,
    this.suffixe = '+',
  });

  final AnimationController ctrl;
  final int valeur;
  final String label;
  final String icone;
  final Color couleur;
  final String suffixe;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: couleur.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: couleur.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(icone, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: ctrl,
            builder: (_, child) {
              final v = (valeur * ctrl.value).round();
              final txt = valeur == 0 ? 'Bientôt' : '$v$suffixe';
              return Text(
                txt,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: couleur,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CarteMembreEquipe extends StatefulWidget {
  const _CarteMembreEquipe({
    required this.membre,
    required this.isDark,
    required this.isMobile,
  });

  final Map<String, dynamic> membre;
  final bool isDark;
  final bool isMobile;

  @override
  State<_CarteMembreEquipe> createState() => _CarteMembreState();
}

class _CarteMembreState extends State<_CarteMembreEquipe> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final photo = widget.membre['photo_url']?.toString();
    final nom = widget.membre['nom']?.toString() ?? '';
    final poste = widget.membre['poste']?.toString() ?? '';
    final desc = widget.membre['description']?.toString() ?? '';
    final linkedin = widget.membre['linkedin']?.toString();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.isMobile ? double.infinity : 240,
        transform: Matrix4.translationValues(0, _hovered ? -6.0 : 0.0, 0),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? const Color(0xFF1A56DB).withValues(alpha: 0.4)
                : widget.isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? const Color(0xFF1A56DB).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _hovered ? 20 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: (photo == null || photo.isEmpty)
                      ? const LinearGradient(
                          colors: [Color(0xFF1A56DB), Color(0xFF7C3AED)],
                        )
                      : null,
                  border: Border.all(
                    color: const Color(0xFF1A56DB).withValues(alpha: 0.3),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A56DB).withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: (photo != null && photo.isNotEmpty)
                    ? ClipOval(
                        child: Image.network(
                          photo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) => _initiales(nom),
                        ),
                      )
                    : _initiales(nom),
              ),
              const SizedBox(height: 16),
              Text(
                nom,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              if (poste.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A56DB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    poste,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A56DB),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (linkedin != null && linkedin.isNotEmpty) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.tryParse(linkedin);
                    if (uri == null) return;
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A66C2).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.link_rounded, color: Color(0xFF0A66C2), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'LinkedIn',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0A66C2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _initiales(String nom) {
    final txt = nom
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0])
        .join()
        .toUpperCase();
    return Center(
      child: Text(
        txt.isEmpty ? 'EC' : txt,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoContactItem extends StatelessWidget {
  const _InfoContactItem({
    required this.icone,
    required this.valeur,
  });

  final IconData icone;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1A56DB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, color: const Color(0xFF1A56DB), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              valeur,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF374151),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormContact extends StatefulWidget {
  const _FormContact({required this.isDark});

  final bool isDark;

  @override
  State<_FormContact> createState() => _FormContactState();
}

class _FormContactState extends State<_FormContact> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _sujetCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _isSending = false;
  bool _envoye = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _sujetCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_envoye) return _buildSucces();
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Envoyer un message',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _champContact(
                    _nomCtrl,
                    'Votre nom *',
                    'Mamadou Barry',
                    Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _champContact(
                    _emailCtrl,
                    'Email *',
                    'votre@email.com',
                    Icons.email_outlined,
                    keyType: TextInputType.emailAddress,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _champContact(
              _sujetCtrl,
              'Sujet',
              'Ex: Partenariat, Question...',
              Icons.subject_rounded,
            ),
            const SizedBox(height: 12),
            _champContact(
              _msgCtrl,
              'Message *',
              'Décrivez votre demande...',
              Icons.message_outlined,
              maxLines: 4,
              validator: (v) => v == null || v.trim().isEmpty ? 'Message requis' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  _isSending ? 'Envoi...' : 'Envoyer le message',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56DB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSending ? null : _envoyer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSucces() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Message envoyé !',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Merci pour votre message.\nNous vous répondrons dans les plus brefs délais.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _champContact(
    TextEditingController ctrl,
    String label,
    String hint,
    IconData icone, {
    int maxLines = 1,
    TextInputType? keyType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: widget.isDark ? const Color(0xFFE2E8F0) : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyType,
          validator: validator ??
              (v) => label.endsWith('*') && (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1)),
            prefixIcon: maxLines == 1
                ? Icon(icone, size: 16, color: const Color(0xFF94A3B8))
                : null,
            filled: true,
            fillColor: widget.isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: widget.isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: widget.isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1A56DB), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);
    try {
      final res = await http.post(
        Uri.parse('$apiBaseUrl$apiPrefix/apropos/contact'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nom': _nomCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'sujet': _sujetCtrl.text.trim(),
          'message': _msgCtrl.text.trim(),
        }),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        setState(() => _envoye = true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message']?.toString() ?? 'Erreur'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
      if (mounted) setState(() => _isSending = false);
    }
  }
}
