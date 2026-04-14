import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../../config/api_config.dart';
import '../../../shared/widgets/logo_widget.dart';
import '../../../app/public_routes.dart';
import '../../../services/newsletter_service.dart';

class FooterWidget extends StatefulWidget {
  const FooterWidget({super.key});

  @override
  State<FooterWidget> createState() => _FooterWidgetState();
}

class _FooterWidgetState extends State<FooterWidget> {
  Map<String, String> _footer = const {};

  @override
  void initState() {
    super.initState();
    _loadFooter();
  }

  Future<void> _loadFooter() async {
    try {
      final res = await http.get(
        Uri.parse('$apiBaseUrl$apiPrefix/config/footer'),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = body['data'];
        if (!mounted) return;
        if (data is Map) {
          setState(() {
            _footer = data.map(
              (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
            );
          });
        }
      }
    } catch (_) {
      // Garde les valeurs par défaut
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 768;
    final hPad = isMobile ? 20.0 : 40.0;

    return Container(
      color: const Color(0xFF0D1B3E),
      width: double.infinity,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, 36, hPad, isMobile ? 24 : 32),
            child: isMobile
                ? _FooterMobile(footer: _footer)
                : _FooterDesktop(footer: _footer),
          ),
          const Divider(color: Color(0x14FFFFFF), height: 1),
          Padding(
            padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 20, horizontal: hPad),
            child: isMobile
                ? _FooterBottomMobile(brandName: _footer['platform_name'] ?? 'EmploiConnect')
                : _FooterBottomDesktop(brandName: _footer['platform_name'] ?? 'EmploiConnect'),
          ),
        ],
      ),
    );
  }
}

class _FooterDesktop extends StatelessWidget {
  const _FooterDesktop({required this.footer});
  final Map<String, String> footer;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _BrandCol(footer: footer, compact: false)),
        SizedBox(width: 24),
        Expanded(flex: 2, child: _LinksColCandidat()),
        SizedBox(width: 24),
        Expanded(flex: 2, child: _LinksColEntreprise()),
        SizedBox(width: 24),
        Expanded(flex: 3, child: _ConnectCol(footer: footer)),
      ],
    );
  }
}

class _FooterMobile extends StatelessWidget {
  const _FooterMobile({required this.footer});
  final Map<String, String> footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BrandCol(footer: footer, compact: true),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _LinksColCandidat(compact: true)),
            const SizedBox(width: 16),
            Expanded(child: _LinksColEntreprise(compact: true)),
          ],
        ),
        const SizedBox(height: 20),
        _ConnectCol(footer: footer),
      ],
    );
  }
}

class _BrandCol extends StatelessWidget {
  const _BrandCol({required this.footer, this.compact = false});
  final Map<String, String> footer;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LogoWidget(
          height: compact ? 32 : 40,
          fallbackTextColor: Colors.white,
          fallbackAccentColor: const Color(0xFF60A5FA),
        ),
        SizedBox(height: compact ? 10 : 14),
        Text(
          (footer['footer_tagline']?.trim().isNotEmpty ?? false)
              ? footer['footer_tagline']!
              : "La plateforme intelligente de l'emploi en Guinée.",
          style: GoogleFonts.inter(
            fontSize: compact ? 12 : 14,
            color: const Color(0xCCFFFFFF),
            height: 1.5,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 14),
          Text(
            "Mettez en relation les talents et les entreprises avec une expérience moderne, fluide et sécurisée.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0x99FFFFFF),
              height: 1.6,
            ),
          ),
        ],
        SizedBox(height: compact ? 12 : 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SocialBtn(
              icon: FontAwesomeIcons.linkedinIn,
              url: footer['footer_linkedin'],
            ),
            _SocialBtn(
              icon: FontAwesomeIcons.facebookF,
              url: footer['footer_facebook'],
            ),
            _SocialBtn(
              icon: FontAwesomeIcons.xTwitter,
              url: footer['footer_twitter'],
            ),
            _SocialBtn(
              icon: FontAwesomeIcons.instagram,
              url: footer['footer_instagram'],
            ),
          ],
        ),
      ],
    );
  }
}

class _LinksColCandidat extends StatelessWidget {
  const _LinksColCandidat({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _LinksCol(
      compact: compact,
      title: 'Pour les Candidats',
      accent: const Color(0xFF3B82F6),
      entries: [
        (
          label: 'Rechercher des offres',
          onTap: () =>
              Navigator.of(context).pushNamed(PublicRoutes.listPath),
        ),
        (
          label: 'Créer un compte',
          onTap: () => Navigator.of(context).pushNamed('/register'),
        ),
        (
          label: 'Se connecter',
          onTap: () => Navigator.of(context).pushNamed('/login'),
        ),
        (label: 'Conseils carrière', onTap: null),
        (
          label: 'À propos',
          onTap: () => Navigator.of(context).pushNamed('/a-propos'),
        ),
        (
          label: 'Mon espace',
          onTap: () => Navigator.of(context).pushNamed('/login'),
        ),
      ],
    );
  }
}

class _LinksColEntreprise extends StatelessWidget {
  const _LinksColEntreprise({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _LinksCol(
      compact: compact,
      title: 'Pour les Entreprises',
      accent: const Color(0xFF10B981),
      entries: [
        (
          label: 'Publier une offre',
          onTap: () => Navigator.of(context).pushNamed('/register'),
        ),
        (
          label: 'Espace Recruteur',
          onTap: () => Navigator.of(context).pushNamed('/login'),
        ),
        (
          label: 'Nos solutions',
          onTap: () => Navigator.of(context).pushNamed('/landing'),
        ),
        (
          label: 'Comment ça marche',
          onTap: () => Navigator.of(context).pushNamed('/landing'),
        ),
        (
          label: 'À propos',
          onTap: () => Navigator.of(context).pushNamed('/a-propos'),
        ),
        (label: 'Contactez-nous', onTap: null),
      ],
    );
  }
}

typedef _FooterLinkEntry = ({String label, VoidCallback? onTap});

class _LinksCol extends StatelessWidget {
  const _LinksCol({
    required this.title,
    required this.accent,
    required this.entries,
    this.compact = false,
  });

  final String title;
  final Color accent;
  final List<_FooterLinkEntry> entries;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final titleSize = compact ? 12.0 : 16.0;
    final barW = compact ? 24.0 : 30.0;
    final gapAfterTitle = compact ? 6.0 : 8.0;
    final gapAfterBar = compact ? 8.0 : 12.0;
    final gapBetweenLinks = compact ? 6.0 : 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: titleSize,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: gapAfterTitle),
        Container(
          width: barW,
          height: compact ? 2 : 3,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        SizedBox(height: gapAfterBar),
        for (final e in entries) ...[
          _FooterLink(label: e.label, onTap: e.onTap, compact: compact),
          SizedBox(height: gapBetweenLinks),
        ],
      ],
    );
  }
}

class _ConnectCol extends StatefulWidget {
  const _ConnectCol({required this.footer});
  final Map<String, String> footer;

  @override
  State<_ConnectCol> createState() => _ConnectColState();
}

class _ConnectColState extends State<_ConnectCol> {
  final TextEditingController _emailCtrl = TextEditingController();
  final _newsletter = NewsletterService();
  bool _nlLoading = false;
  bool _nlSuccess = false;
  String? _nlMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _subscribe() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _nlLoading = true;
      _nlMessage = null;
    });
    final r = await _newsletter.subscribe(email: email, source: 'footer');
    if (!mounted) return;
    setState(() {
      _nlLoading = false;
      _nlSuccess = r.success;
      _nlMessage = r.message ?? (r.success ? 'Merci !' : 'Erreur');
    });
    if (r.success) _emailCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.email_outlined, color: Color(0xFF1A56DB), size: 20),
            const SizedBox(width: 8),
            Text(
              'Restez informé !',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Recevez les nouvelles offres et les tendances du marché de l’emploi en Guinée.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0x99FFFFFF),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        if (_nlSuccess)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _nlMessage ?? 'Inscription réussie !',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'votre@email.com',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0x77FFFFFF)),
                    filled: true,
                    fillColor: const Color(0x14FFFFFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0x33FFFFFF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0x33FFFFFF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1A56DB), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: (_) => _subscribe(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56DB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _nlLoading ? null : _subscribe,
                  child: _nlLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.arrow_forward),
                ),
              ),
            ],
          ),
        const SizedBox(height: 14),
        _ContactLine(
          icon: Icons.mail_outline,
          text: widget.footer['footer_email']?.trim().isNotEmpty == true
              ? widget.footer['footer_email']!
              : 'contact@example.com',
        ),
        const SizedBox(height: 8),
        _ContactLine(
          icon: Icons.call_outlined,
          text: widget.footer['footer_telephone']?.trim().isNotEmpty == true
              ? widget.footer['footer_telephone']!
              : '+224 620 00 00 00',
        ),
        const SizedBox(height: 8),
        _ContactLine(
          icon: Icons.place_outlined,
          text: widget.footer['footer_adresse']?.trim().isNotEmpty == true
              ? widget.footer['footer_adresse']!
              : 'Conakry, République de Guinée',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x24FFFFFF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 16,
                color: Color(0xFF93C5FD),
              ),
              const SizedBox(width: 8),
              Text(
                'Données sécurisées',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xCCFFFFFF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0x99FFFFFF)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: const Color(0x99FFFFFF),
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialBtn extends StatefulWidget {
  const _SocialBtn({required this.icon, this.url});

  final IconData icon;
  final String? url;

  @override
  State<_SocialBtn> createState() => _SocialBtnState();
}

class _SocialBtnState extends State<_SocialBtn> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: () async {
            final raw = widget.url?.trim() ?? '';
            if (raw.isEmpty) return;
            final uri = Uri.tryParse(raw);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hover ? const Color(0x333B82F6) : const Color(0x1FFFFFFF),
            ),
            child: Icon(widget.icon, size: 16, color: const Color(0xCCFFFFFF)),
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatefulWidget {
  const _FooterLink({required this.label, this.onTap, this.compact = false});

  final String label;
  final VoidCallback? onTap;
  final bool compact;

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () async {
          if (widget.onTap != null) {
            widget.onTap!();
            return;
          }
          final uri = Uri.parse('https://emploiconnect.gn');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        child: Row(
          children: [
            Icon(
              Icons.chevron_right,
              size: widget.compact ? 14 : 16,
              color: _hover ? const Color(0xFF3B82F6) : const Color(0xAAFFFFFF),
            ),
            SizedBox(width: widget.compact ? 4 : 6),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.inter(
                  fontSize: widget.compact ? 11 : 14,
                  color: _hover
                      ? const Color(0xFF3B82F6)
                      : const Color(0xAAFFFFFF),
                ),
                child: Text(
                  widget.label,
                  maxLines: widget.compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterBottomDesktop extends StatelessWidget {
  const _FooterBottomDesktop({required this.brandName});

  final String brandName;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '© 2026 $brandName. Tous droits réservés.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0x99FFFFFF),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Projet académique — Licence Professionnelle Génie Logiciel',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0x77FFFFFF),
              ),
            ),
          ],
        ),
        Row(
          children: const [
            _LegalLink('Mentions légales'),
            _Dot(),
            _LegalLink('Confidentialité'),
            _Dot(),
            _LegalLink('CGU'),
          ],
        ),
      ],
    );
  }
}

class _FooterBottomMobile extends StatelessWidget {
  const _FooterBottomMobile({required this.brandName});

  final String brandName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '© 2026 $brandName. Tous droits réservés.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0x99FFFFFF),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Projet académique — Licence Professionnelle Génie Logiciel',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: const Color(0x77FFFFFF),
          ),
        ),
        const SizedBox(height: 10),
        const Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _LegalLink('Mentions légales'),
            _Dot(),
            _LegalLink('Confidentialité'),
            _Dot(),
            _LegalLink('CGU'),
          ],
        ),
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xAAFFFFFF)),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return const Text('·', style: TextStyle(color: Color(0x66FFFFFF)));
  }
}
