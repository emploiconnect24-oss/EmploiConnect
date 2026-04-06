import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/app_config_provider.dart';
import '../../../app/public_routes.dart';

class HeroSectionWidget extends StatefulWidget {
  const HeroSectionWidget({super.key});

  @override
  State<HeroSectionWidget> createState() => _HeroSectionWidgetState();
}

class _HeroSectionWidgetState extends State<HeroSectionWidget> {
  final PageController _pageController = PageController();
  final TextEditingController _heroSearchCtrl = TextEditingController();
  int _currentPage = 0;
  int _slideCount = 3;
  Timer? _timer;

  final List<String> heroImages = [
    'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1920&q=80',
    'https://images.unsplash.com/photo-1542744173-8e7e53415bb0?w=1920&q=80',
    'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?w=1920&q=80',
  ];

  final List<Map<String, String>> heroContent = [
    {
      'badge': '🇬🇳  Plateforme N°1 en Guinée',
      'title': "Trouvez l'Emploi\nde Vos Rêves",
      'subtitle':
          "Des milliers d'offres vérifiées vous attendent.\nPostulez en un clic, décrochez votre opportunité.",
    },
    {
      'badge': '⚡  Matching intelligent par IA',
      'title': "Votre CV Analysé\nPar l'Intelligence\nArtificielle",
      'subtitle':
          "Notre IA extrait vos compétences et vous\nrecommande les offres les plus pertinentes.",
    },
    {
      'badge': '🏢  Espace Recruteurs',
      'title': 'Recrutez les\nMeilleurs Talents\nde Guinée',
      'subtitle':
          'Accédez à une base de candidats qualifiés.\nTrouvez le profil idéal en quelques minutes.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoplay();
  }

  void _startAutoplay() {
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!_pageController.hasClients || !mounted) return;
      final count = _slideCount <= 0 ? 1 : _slideCount;
      final nextPage = (_currentPage + 1) % count;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _heroSearchCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _openPublicOffres({String? initialSearch}) {
    final q = (initialSearch ?? _heroSearchCtrl.text).trim();
    Navigator.of(context).pushNamed(
      PublicRoutes.list(search: q.isEmpty ? null : q),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;
    // Hauteur bandeau réduite (plus de plein écran sur bureau) — cohérent avec la notice dimensions admin.
    final heroHeight = isMobile
        ? (size.height * 0.5).clamp(300.0, 400.0)
        : 440.0;
    final compact = heroHeight < 520;
    final showSearchInHero = !isMobile;
    final config = context.watch<AppConfigProvider>();
    final providerSlides = config.bannieres
        .where((s) => s['est_actif'] != false)
        .toList();
    final slides = providerSlides.isNotEmpty
        ? providerSlides
        : List.generate(heroImages.length, (i) {
            final content = heroContent[i];
            return <String, dynamic>{
              'image_url': heroImages[i],
              'texte_badge': content['badge'],
              'titre': content['title'],
              'sous_titre': content['subtitle'],
            };
          });
    _slideCount = slides.length;
    if (_currentPage >= _slideCount && _slideCount > 0) {
      _currentPage = 0;
    }

    return SizedBox(
      height: heroHeight,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (ctx, i) => Image.network(
              slides[i]['image_url']?.toString() ?? '',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              headers: const {'Cache-Control': 'no-cache'},
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF0F172A),
                child: const Icon(
                  Icons.image_outlined,
                  color: Colors.white24,
                  size: 48,
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.75),
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
          Positioned(
            right: -80,
            top: -80,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A56DB).withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            right: 100,
            bottom: 50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.10),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80),
            child: Column(
              mainAxisAlignment: compact
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: compact ? 44 : 72),
                FadeInDown(
                  key: ValueKey(_currentPage),
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      slides[_currentPage]['texte_badge']?.toString() ?? '',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 16 : 24),
                FadeInLeft(
                  key: ValueKey('title_$_currentPage'),
                  duration: const Duration(milliseconds: 700),
                  delay: const Duration(milliseconds: 150),
                  child: Text(
                    slides[_currentPage]['titre']?.toString() ?? '',
                    style: isMobile
                        ? GoogleFonts.poppins(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          )
                        : GoogleFonts.poppins(
                            fontSize: compact ? 40 : 54,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.15,
                          ),
                  ),
                ),
                SizedBox(height: compact ? 12 : 20),
                FadeInLeft(
                  key: ValueKey('sub_$_currentPage'),
                  duration: const Duration(milliseconds: 700),
                  delay: const Duration(milliseconds: 250),
                  child: Text(
                    slides[_currentPage]['sous_titre']?.toString() ?? '',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 15 : 18,
                      color: Colors.white.withValues(alpha: 0.80),
                      height: 1.6,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 18 : 40),
                FadeInUp(
                  key: ValueKey('cta_$_currentPage'),
                  duration: const Duration(milliseconds: 700),
                  delay: const Duration(milliseconds: 350),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: const Text('Trouver un Emploi'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(190, 48),
                          backgroundColor: const Color(0xFF1A56DB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 16,
                          ),
                          textStyle: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _openPublicOffres(),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(
                          Icons.business_center_outlined,
                          size: 18,
                        ),
                        label: const Text('Recruter des Talents'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(210, 48),
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.85),
                            width: 1.5,
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 16,
                          ),
                          textStyle: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/register'),
                      ),
                    ],
                  ),
                ),
                if (showSearchInHero) ...[
                  SizedBox(height: compact ? 16 : 28),
                  FadeInUp(
                    duration: const Duration(milliseconds: 700),
                    delay: const Duration(milliseconds: 500),
                    child: _buildSearchBar(isMobile),
                  ),
                  if (!compact) const Spacer() else const SizedBox(height: 10),
                ] else
                  const SizedBox(height: 12),
                FadeInUp(
                  duration: const Duration(milliseconds: 700),
                  delay: const Duration(milliseconds: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMobile && !compact) _buildHeroStats(),
                      SizedBox(height: compact ? 12 : 24),
                      Row(
                        children: List.generate(
                          slides.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            width: i == _currentPage ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _currentPage
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 16 : 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isMobile) {
    return Container(
      height: isMobile ? 56 : 60,
      constraints: const BoxConstraints(maxWidth: 600),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _heroSearchCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _openPublicOffres(),
              decoration: InputDecoration(
                hintText: 'Titre du poste, compétence...',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(6),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: () => _openPublicOffres(),
              child: isMobile
                  ? const Icon(Icons.search, size: 18, color: Colors.white)
                  : Text(
                      'Rechercher',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStats() {
    return const Row(
      children: [
        _StatItem(value: '500+', label: 'Offres actives'),
        SizedBox(width: 40),
        _StatItem(value: '1 200+', label: 'Candidats inscrits'),
        SizedBox(width: 40),
        _StatItem(value: '150+', label: 'Entreprises'),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
