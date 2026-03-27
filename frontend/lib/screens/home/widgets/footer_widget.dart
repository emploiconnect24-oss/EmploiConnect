import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 980;
    final hPad = isMobile ? 24.0 : 80.0;

    return Container(
      color: const Color(0xFF0F172A),
      width: double.infinity,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)]),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 64, horizontal: hPad),
            child: isMobile ? const _FooterMobile() : const _FooterDesktop(),
          ),
          const Divider(color: Color(0x14FFFFFF), height: 1),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24, horizontal: hPad),
            child: isMobile ? const _FooterBottomMobile() : const _FooterBottomDesktop(),
          ),
        ],
      ),
    );
  }
}

class _FooterDesktop extends StatelessWidget {
  const _FooterDesktop();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _BrandCol()),
        SizedBox(width: 28),
        Expanded(flex: 2, child: _LinksColCandidat()),
        SizedBox(width: 28),
        Expanded(flex: 2, child: _LinksColEntreprise()),
        SizedBox(width: 28),
        Expanded(flex: 3, child: _ConnectCol()),
      ],
    );
  }
}

class _FooterMobile extends StatelessWidget {
  const _FooterMobile();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BrandCol(),
        SizedBox(height: 26),
        _LinksColCandidat(),
        SizedBox(height: 26),
        _LinksColEntreprise(),
        SizedBox(height: 26),
        _ConnectCol(),
      ],
    );
  }
}

class _BrandCol extends StatelessWidget {
  const _BrandCol();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.work_outline, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'EmploiConnect',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          "La plateforme intelligente de l'emploi en Guinée.",
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xCCFFFFFF), height: 1.6),
        ),
        const SizedBox(height: 14),
        Text(
          "Mettez en relation les talents et les entreprises avec une expérience moderne, fluide et sécurisée.",
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0x99FFFFFF), height: 1.6),
        ),
        const SizedBox(height: 16),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SocialBtn(icon: FontAwesomeIcons.linkedinIn),
            _SocialBtn(icon: FontAwesomeIcons.facebookF),
            _SocialBtn(icon: FontAwesomeIcons.xTwitter),
            _SocialBtn(icon: FontAwesomeIcons.instagram),
          ],
        ),
      ],
    );
  }
}

class _LinksColCandidat extends StatelessWidget {
  const _LinksColCandidat();

  @override
  Widget build(BuildContext context) {
    return _LinksCol(
      title: 'Pour les Candidats',
      accent: const Color(0xFF3B82F6),
      links: const [
        'Rechercher des offres',
        'Créer un compte',
        'Se connecter',
        'Conseils carrière',
        'Mon espace',
      ],
    );
  }
}

class _LinksColEntreprise extends StatelessWidget {
  const _LinksColEntreprise();

  @override
  Widget build(BuildContext context) {
    return _LinksCol(
      title: 'Pour les Entreprises',
      accent: const Color(0xFF10B981),
      links: const [
        'Publier une offre',
        'Espace Recruteur',
        'Nos solutions',
        'Comment ça marche',
        'Contactez-nous',
      ],
    );
  }
}

class _LinksCol extends StatelessWidget {
  const _LinksCol({
    required this.title,
    required this.accent,
    required this.links,
  });

  final String title;
  final Color accent;
  final List<String> links;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Container(
          width: 30,
          height: 3,
          decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(100)),
        ),
        const SizedBox(height: 12),
        for (final l in links) ...[
          _FooterLink(label: l),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ConnectCol extends StatefulWidget {
  const _ConnectCol();

  @override
  State<_ConnectCol> createState() => _ConnectColState();
}

class _ConnectColState extends State<_ConnectCol> {
  final TextEditingController _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Restez Connecté',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          'Recevez nos nouveautés et les tendances du marché de l’emploi.',
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0x99FFFFFF), height: 1.6),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _emailCtrl,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Votre email',
                  hintStyle: GoogleFonts.inter(color: const Color(0x77FFFFFF)),
                  filled: true,
                  fillColor: const Color(0x14FFFFFF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56DB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: () {},
                child: const Icon(Icons.arrow_forward),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _ContactLine(icon: Icons.mail_outline, text: 'contact@emploiconnect.gn'),
        const SizedBox(height: 8),
        const _ContactLine(icon: Icons.call_outlined, text: '+224 620 00 00 00'),
        const SizedBox(height: 8),
        const _ContactLine(icon: Icons.place_outlined, text: 'Conakry, République de Guinée'),
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
              const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF93C5FD)),
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
            style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0x99FFFFFF)),
          ),
        ),
      ],
    );
  }
}

class _SocialBtn extends StatefulWidget {
  const _SocialBtn({required this.icon});

  final IconData icon;

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
          onTap: () {},
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
  const _FooterLink({required this.label});

  final String label;

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
          // Lien placeholder sans URL métier pour l'instant.
          final uri = Uri.parse('https://emploiconnect.gn');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        child: Row(
          children: [
            Icon(Icons.chevron_right, size: 16, color: _hover ? const Color(0xFF3B82F6) : const Color(0xAAFFFFFF)),
            const SizedBox(width: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _hover ? const Color(0xFF3B82F6) : const Color(0xAAFFFFFF),
              ),
              child: Text(widget.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterBottomDesktop extends StatelessWidget {
  const _FooterBottomDesktop();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '© 2026 EmploiConnect. Tous droits réservés.',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0x99FFFFFF)),
            ),
            const SizedBox(height: 4),
            Text(
              'Projet académique — Licence Professionnelle Génie Logiciel',
              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0x77FFFFFF)),
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
  const _FooterBottomMobile();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '© 2026 EmploiConnect. Tous droits réservés.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0x99FFFFFF)),
        ),
        const SizedBox(height: 4),
        Text(
          'Projet académique — Licence Professionnelle Génie Logiciel',
          style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0x77FFFFFF)),
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

