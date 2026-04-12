import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/public_routes.dart';
import 'home_design_tokens.dart';
import 'home_nav_helpers.dart';

/// PRD §2 — Hero animé + carousel bannières (champs API : titre, sous_titre, texte_badge, image_url, CTA).
class HomeHeroPrdSection extends StatefulWidget {
  const HomeHeroPrdSection({
    super.key,
    required this.bannieres,
  });

  final List<Map<String, dynamic>> bannieres;

  @override
  State<HomeHeroPrdSection> createState() => _HomeHeroPrdSectionState();
}

class _HomeHeroPrdSectionState extends State<HomeHeroPrdSection> with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late AnimationController _floatCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _floatAnim;

  int _banniereIndex = 0;
  Timer? _banniereTimer;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _floatAnim = Tween<double>(begin: -8, end: 8)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _fadeCtrl.forward();
    _slideCtrl.forward();
    _armTimer();
  }

  void _armTimer() {
    _banniereTimer?.cancel();
    if (widget.bannieres.length > 1) {
      _banniereTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted) return;
        setState(() => _banniereIndex = (_banniereIndex + 1) % widget.bannieres.length);
      });
    }
  }

  @override
  void didUpdateWidget(covariant HomeHeroPrdSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bannieres.length != widget.bannieres.length) {
      _banniereIndex = 0;
      _armTimer();
    }
  }

  @override
  void dispose() {
    _banniereTimer?.cancel();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _ban =>
      widget.bannieres.isEmpty ? null : widget.bannieres[_banniereIndex.clamp(0, widget.bannieres.length - 1)];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    final ban = _ban;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 400),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF1A56DB),
            Color(0xFF2563EB),
            Color(0xFF0EA5E9),
          ],
          stops: [0.0, 0.35, 0.72, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: AnimatedBuilder(
              animation: _floatAnim,
              builder: (context, _) => Transform.translate(
                offset: Offset(0, _floatAnim.value),
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        HomeDesign.primaryLight.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [HomeDesign.primary.withValues(alpha: 0.2), Colors.transparent],
                ),
              ),
            ),
          ),
          ..._particules(context),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 60, vertical: 36),
            child: isMobile ? _buildMobile(context, ban) : _buildDesktop(context, ban),
          ),
        ],
      ),
    );
  }

  List<Widget> _particules(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    const positions = [
      [0.08, 0.15],
      [0.88, 0.12],
      [0.5, 0.72],
      [0.22, 0.62],
      [0.78, 0.48],
    ];
    return positions.asMap().entries.map((e) {
      final i = e.key;
      final p = e.value;
      return Positioned(
        left: p[0] * w,
        top: p[1] * 360,
        child: AnimatedBuilder(
          animation: _floatCtrl,
          builder: (context, _) => Transform.translate(
            offset: Offset(0, _floatAnim.value * (i.isEven ? 1 : -1)),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.28),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _badgeText(String? t) {
    final s = (t ?? '').trim().isEmpty ? 'Emploi en Guinée' : t!.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        s,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.95),
        ),
      ),
    );
  }

  Widget _buildDesktop(BuildContext context, Map<String, dynamic>? ban) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _badgeText(ban?['texte_badge']?.toString()),
                  const SizedBox(height: 20),
                  _titreHero(ban, 40),
                  const SizedBox(height: 16),
                  Text(
                    (ban?['sous_titre']?.toString().trim().isNotEmpty == true)
                        ? ban!['sous_titre'].toString()
                        : 'La plateforme intelligente qui connecte les meilleurs talents aux meilleures entreprises '
                            'de Guinée. Avec l\'IA pour vous.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.78),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      _ctaPrimaire(context, ban),
                      const SizedBox(width: 14),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.business_rounded, size: 18, color: Colors.white),
                        label: Text(
                          (ban?['label_cta_2']?.toString().trim().isNotEmpty == true)
                              ? ban!['label_cta_2'].toString()
                              : 'Recruter un talent',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.38)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final l = ban?['lien_cta_2']?.toString();
                          if (l != null && l.trim().isNotEmpty) {
                            navigateHomeLink(context, l);
                          } else {
                            Navigator.of(context).pushNamed('/register');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 32),
        SizedBox(width: 380, child: _buildCarousel(context, ban)),
      ],
    );
  }

  Widget _titreHero(Map<String, dynamic>? ban, double size) {
    final titre = (ban?['titre']?.toString().trim().isNotEmpty == true)
        ? ban!['titre'].toString()
        : 'Trouvez votre emploi idéal en Guinée';
    return Text(
      titre,
      style: GoogleFonts.poppins(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        height: 1.1,
      ),
    );
  }

  Widget _ctaPrimaire(BuildContext context, Map<String, dynamic>? ban) {
    final label = (ban?['label_cta_1']?.toString().trim().isNotEmpty == true)
        ? ban!['label_cta_1'].toString()
        : 'Voir les offres';
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: HomeDesign.gradientBrand,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: HomeDesign.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.search_rounded, size: 18, color: Colors.white),
        label: Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          final l = ban?['lien_cta_1']?.toString();
          if (l != null && l.trim().isNotEmpty) {
            navigateHomeLink(context, l);
          } else {
            Navigator.of(context).pushNamed(PublicRoutes.listPath);
          }
        },
      ),
    );
  }

  Widget _buildMobile(BuildContext context, Map<String, dynamic>? ban) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _badgeText(ban?['texte_badge']?.toString()),
        const SizedBox(height: 16),
        _titreHero(ban, 30),
        const SizedBox(height: 12),
        Text(
          (ban?['sous_titre']?.toString().trim().isNotEmpty == true)
              ? ban!['sous_titre'].toString()
              : 'La plateforme intelligente pour l\'emploi en Guinée.',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.75)),
        ),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: _ctaPrimaire(context, ban)),
        const SizedBox(height: 24),
        _buildCarousel(context, ban),
      ],
    );
  }

  Widget _buildCarousel(BuildContext context, Map<String, dynamic>? ban) {
    if (widget.bannieres.isEmpty) {
      return _illustrationDefaut();
    }
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.15, 0), end: Offset.zero).animate(anim),
              child: child,
            ),
          ),
          child: _carteBanniere(context, ban ?? widget.bannieres.first, key: ValueKey(_banniereIndex)),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.bannieres.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _banniereIndex ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _banniereIndex
                    ? HomeDesign.primaryLight
                    : Colors.white.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _carteBanniere(BuildContext context, Map<String, dynamic> b, {Key? key}) {
    final url = b['image_url']?.toString();
    final hasImg = url != null && url.isNotEmpty;
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (context, _) => Transform.translate(
        offset: Offset(0, _floatAnim.value * 0.35),
        child: Container(
          key: key,
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: hasImg
                ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
                : null,
            gradient: hasImg
                ? null
                : const LinearGradient(
                    colors: [
                      Color(0xFF1E40AF),
                      Color(0xFF1A56DB),
                      Color(0xFF38BDF8),
                    ],
                  ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 28, offset: const Offset(0, 14)),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if ((b['texte_badge']?.toString().trim().isNotEmpty ?? false))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      b['texte_badge'].toString(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if ((b['texte_badge']?.toString().trim().isNotEmpty ?? false)) const SizedBox(height: 8),
                Text(
                  b['titre']?.toString() ?? '',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                if ((b['sous_titre']?.toString().trim().isNotEmpty ?? false)) ...[
                  const SizedBox(height: 6),
                  Text(
                    b['sous_titre'].toString(),
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.75)),
                  ),
                ],
                if ((b['lien_cta_1']?.toString().trim().isNotEmpty ?? false)) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => navigateHomeLink(context, b['lien_cta_1']?.toString()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        (b['label_cta_1']?.toString().trim().isNotEmpty == true)
                            ? '${b['label_cta_1']} →'
                            : 'En savoir plus →',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: HomeDesign.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _illustrationDefaut() {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (context, _) => Transform.translate(
        offset: Offset(0, _floatAnim.value * 0.45),
        child: Container(
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A8A), Color(0xFF1A56DB), Color(0xFF0C4A6E)],
            ),
            boxShadow: [
              BoxShadow(
                color: HomeDesign.primary.withValues(alpha: 0.28),
                blurRadius: 36,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('👩‍💼', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 12),
                Text(
                  'Votre prochaine opportunité\nvous attend !',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
