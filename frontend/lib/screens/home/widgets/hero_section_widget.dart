import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HeroSectionWidget extends StatefulWidget {
  const HeroSectionWidget({super.key});

  @override
  State<HeroSectionWidget> createState() => _HeroSectionWidgetState();
}

class _HeroSectionWidgetState extends State<HeroSectionWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
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
      'subtitle': "Des milliers d'offres vérifiées vous attendent.\nPostulez en un clic, décrochez votre opportunité.",
    },
    {
      'badge': '⚡  Matching intelligent par IA',
      'title': "Votre CV Analysé\nPar l'Intelligence\nArtificielle",
      'subtitle': "Notre IA extrait vos compétences et vous\nrecommande les offres les plus pertinentes.",
    },
    {
      'badge': '🏢  Espace Recruteurs',
      'title': 'Recrutez les\nMeilleurs Talents\nde Guinée',
      'subtitle': 'Accédez à une base de candidats qualifiés.\nTrouvez le profil idéal en quelques minutes.',
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
      final nextPage = (_currentPage + 1) % heroImages.length;
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
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;
    final heroHeight = isMobile ? size.height * 0.75 : size.height;
    final compact = heroHeight < 640;

    return SizedBox(
      height: heroHeight,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: heroImages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (ctx, i) => CachedNetworkImage(
              imageUrl: heroImages[i],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => Container(color: const Color(0xFF0F172A)),
              errorWidget: (context, url, error) => Container(
                color: const Color(0xFF0F172A),
                child: const Icon(Icons.image_outlined, color: Colors.white24, size: 48),
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
              mainAxisAlignment: compact ? MainAxisAlignment.start : MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: compact ? 56 : 80),
                FadeInDown(
                  key: ValueKey(_currentPage),
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      heroContent[_currentPage]['badge']!,
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
                    heroContent[_currentPage]['title']!,
                    style: isMobile
                        ? GoogleFonts.poppins(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          )
                        : GoogleFonts.poppins(
                            fontSize: 54,
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
                    heroContent[_currentPage]['subtitle']!,
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
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: () {},
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.business_center_outlined, size: 18),
                        label: const Text('Recruter des Talents'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(210, 48),
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 34),
                  FadeInUp(
                    duration: const Duration(milliseconds: 700),
                    delay: const Duration(milliseconds: 500),
                    child: _buildSearchBar(isMobile),
                  ),
                  const Spacer(),
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
                          heroImages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            width: i == _currentPage ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _currentPage ? Colors.white : Colors.white.withValues(alpha: 0.4),
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
              decoration: InputDecoration(
                hintText: 'Titre du poste, compétence...',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () {},
              child: isMobile
                  ? const Icon(Icons.search, size: 18, color: Colors.white)
                  : Text(
                      'Rechercher',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
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
          style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}

