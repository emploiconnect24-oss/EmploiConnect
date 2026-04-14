import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../../config/api_config.dart';
import 'home_design_tokens.dart';

/// Section illustration homepage — image depuis `/api/illustration/active` (IA, manuelle ou Unsplash).
class HomeIllustrationSection extends StatefulWidget {
  const HomeIllustrationSection({super.key});

  @override
  State<HomeIllustrationSection> createState() => _HomeIllustrationSectionState();
}

class _HomeIllustrationSectionState extends State<HomeIllustrationSection> with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final Animation<double> _floatAnim;

  String? _imageUrl;
  String? _imageSource;
  bool _loadingImage = true;
  int _indexActuel = 1;
  int _totalImages = 1;
  int _heureProchain = 0;

  static const _bullets = <(String, String, String)>[
    ('🎯', 'Matching IA précis', 'Compatible avec votre profil'),
    ('⚡', 'Réponse rapide', 'Moins de 24h en moyenne'),
    ('🔒', 'Sécurisé', 'Vos données sont protégées'),
  ];

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -12, end: 12).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
    _loadIllustration();
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadIllustration() async {
    try {
      final uri = Uri.parse('$apiBaseUrl$apiPrefix/illustration/active');
      final res = await http.get(uri, headers: const {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        final url = data?['url_image'] as String?;
        final src = data?['source'] as String?;
        if (mounted) {
          setState(() {
            _imageUrl = (url != null && url.isNotEmpty) ? url : null;
            _imageSource = src;
            _indexActuel = (data?['index_actuel'] as int?) ?? 1;
            _totalImages = (data?['total'] as int?) ?? 1;
            _heureProchain = (data?['heure_prochain_changement'] as int?) ?? 0;
            _loadingImage = false;
          });
        }
        return;
      }
    } catch (_) {
      /* fallback visuel local */
    }
    if (mounted) {
      setState(() {
        _loadingImage = false;
      });
    }
  }

  Widget _buildPlaceholderBox() {
    return Container(
      width: 360,
      height: 400,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: HomeDesign.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(color: Color(0xFF1A56DB), strokeWidth: 2),
          ),
          const SizedBox(height: 12),
          Text(
            'Chargement illustration…',
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiFallback() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👩‍💼', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 8),
          const Text('🎉', style: TextStyle(fontSize: 40)),
        ],
      ),
    );
  }

  Widget _buildIllustrationVisual() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: 360,
          height: 400,
          child: _loadingImage
              ? _buildPlaceholderBox()
              : _imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        _imageUrl!,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return _buildPlaceholderBox();
                        },
                        errorBuilder: (_, _, _) => _buildEmojiFallback(),
                      ),
                    )
                  : _buildEmojiFallback(),
        ),
        if (_imageSource == 'dalle')
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'IA du jour',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        Positioned(
          top: 24,
          right: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: HomeDesign.primaryLight, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Offre acceptée !',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: HomeDesign.dark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 30,
          left: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🚀', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    'Score IA : 94%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: HomeDesign.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_totalImages > 1)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '$_indexActuel / $_totalImages · ${_heureProchain}h',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTexte({required bool narrow}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: HomeDesign.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            'Ils ont réussi grâce à nous',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: HomeDesign.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Des milliers de Guinéens\nont changé leur vie',
          style: GoogleFonts.poppins(
            fontSize: narrow ? 26 : 32,
            fontWeight: FontWeight.w800,
            color: HomeDesign.dark,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Chaque jour, des candidats trouvent leur emploi idéal et des entreprises '
          'recrutent les meilleurs talents grâce à EmploiConnect.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF64748B),
            height: 1.7,
          ),
        ),
        const SizedBox(height: 24),
        ..._bullets.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: HomeDesign.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text(item.$1, style: const TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$2,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: HomeDesign.dark,
                        ),
                      ),
                      Text(
                        item.$3,
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: HomeDesign.gradientBrand,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: HomeDesign.primary.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pushNamed('/register'),
            child: Text(
              'Rejoindre gratuitement',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 768;
    final padH = isMobile ? 20.0 : 60.0;
    final padV = isMobile ? 40.0 : 60.0;

    final illustration = AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, _) => Transform.translate(
        offset: Offset(0, _floatAnim.value),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: _buildIllustrationVisual(),
          ),
        ),
      ),
    );

    return ColoredBox(
      color: const Color(0xFFF0F7FF),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  illustration,
                  const SizedBox(height: 32),
                  _buildTexte(narrow: true),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _buildTexte(narrow: false)),
                  const SizedBox(width: 60),
                  Expanded(child: illustration),
                ],
              ),
      ),
    );
  }
}
