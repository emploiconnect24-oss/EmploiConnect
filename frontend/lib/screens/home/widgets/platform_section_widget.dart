import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

class PlatformSectionWidget extends StatelessWidget {
  const PlatformSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    final candidateCard = _PlatformCard(
      icon: Icons.person_search_outlined,
      iconTint: const Color(0xFF1A56DB),
      title: 'Je suis Candidat',
      description:
          "Accédez aux offres d'emploi, améliorez votre CV et postulez rapidement aux opportunités qui vous correspondent.",
      primaryLabel: 'Créer mon compte',
      secondaryLabel: 'Explorer les offres',
      onPrimaryTap: () {},
      onSecondaryTap: () {},
    );

    final recruiterCard = _PlatformCard(
      icon: Icons.business_center_outlined,
      iconTint: const Color(0xFF10B981),
      title: 'Je suis Recruteur',
      description:
          'Publiez vos offres, recevez des candidatures qualifiées et recrutez plus vite grâce au matching intelligent.',
      primaryLabel: 'Publier une offre',
      secondaryLabel: 'Découvrir les solutions',
      onPrimaryTap: () {},
      onSecondaryTap: () {},
      aiBadge: true,
    );

    return Container(
      color: const Color(0xFFF8FAFC),
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80, vertical: isMobile ? 36 : 64),
        child: Column(
          children: [
            Text(
              'Une plateforme pensée pour tous',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 26 : 34,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Choisissez votre espace et profitez d’outils adaptés à vos besoins.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF64748B),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 26),
            if (isMobile)
              Column(
                children: [
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 200),
                    child: candidateCard,
                  ),
                  const SizedBox(height: 14),
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 300),
                    child: recruiterCard,
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                      child: candidateCard,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 300),
                      child: recruiterCard,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PlatformCard extends StatefulWidget {
  const _PlatformCard({
    required this.icon,
    required this.iconTint,
    required this.title,
    required this.description,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimaryTap,
    required this.onSecondaryTap,
    this.aiBadge = false,
  });

  final IconData icon;
  final Color iconTint;
  final String title;
  final String description;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimaryTap;
  final VoidCallback onSecondaryTap;
  final bool aiBadge;

  @override
  State<_PlatformCard> createState() => _PlatformCardState();
}

class _PlatformCardState extends State<_PlatformCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.08 : 0.04),
              blurRadius: _hovered ? 26 : 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: widget.iconTint.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.icon, color: widget.iconTint),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.title,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A56DB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: widget.onPrimaryTap,
                        child: Text(widget.primaryLabel),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1A56DB),
                          side: const BorderSide(color: Color(0xFF1A56DB), width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        onPressed: widget.onSecondaryTap,
                        child: Text(widget.secondaryLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (widget.aiBadge)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: const Color(0xFFD6E4FF)),
                  ),
                  child: Text(
                    'IA',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A56DB),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

