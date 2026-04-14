import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/public_routes.dart';
import 'home_design_tokens.dart';
import 'home_nav_helpers.dart';

/// Carrousel bannières pub (bas de page). Si la BDD est vide → 3 visuels placeholder + animations.
class HomePubBannieresSection extends StatefulWidget {
  const HomePubBannieresSection({super.key, required this.bannieres});

  final List<Map<String, dynamic>> bannieres;

  @override
  State<HomePubBannieresSection> createState() => _HomePubBannieresSectionState();
}

class _HomePubBannieresSectionState extends State<HomePubBannieresSection>
    with TickerProviderStateMixin {
  int _index = 0;
  Timer? _timer;
  /// Initialisé tout de suite — pas de `late`, évite tout accès avant init.
  final PageController _pageCtrl = PageController(viewportFraction: 0.88);

  AnimationController? _scaleCtrl;
  AnimationController? _fadeCtrl;
  Animation<double> _scaleAnim = const AlwaysStoppedAnimation<double>(1);
  Animation<double> _fadeAnim = const AlwaysStoppedAnimation<double>(1);

  /// Visuels professionnels (Unsplash) — utilisés uniquement si aucune pub en base.
  static final List<Map<String, dynamic>> _defaults = [
    {
      'image_url': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=900&q=80',
      'titre': 'Trouvez votre emploi idéal',
      'sous_titre': 'Des milliers d\'opportunités vous attendent en Guinée',
      'badge': '🚀 Nouveau',
      'couleur': 0xFF1A56DB,
      '_placeholder': true,
    },
    {
      'image_url': 'https://images.unsplash.com/photo-1521737711867-e3b97375f902?w=900&q=80',
      'titre': 'Recrutez les meilleurs talents',
      'sous_titre': 'EmploiConnect met en relation profils et entreprises',
      'badge': '⭐ Top recruteurs',
      'couleur': 0xFF2563EB,
      '_placeholder': true,
    },
    {
      'image_url': 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=900&q=80',
      'titre': 'Développez votre carrière',
      'sous_titre': 'Parcours carrière, simulateur IA, outils modernes',
      'badge': '✨ Propulsé par l’IA',
      'couleur': 0xFF1E40AF,
      '_placeholder': true,
    },
  ];

  static List<Map<String, dynamic>> _sorted(List<Map<String, dynamic>> raw) {
    final copy = List<Map<String, dynamic>>.from(raw);
    copy.sort((a, b) {
      final oa = (a['ordre_pub'] is num) ? (a['ordre_pub'] as num).toInt() : int.tryParse('${a['ordre_pub']}') ?? 0;
      final ob = (b['ordre_pub'] is num) ? (b['ordre_pub'] as num).toInt() : int.tryParse('${b['ordre_pub']}') ?? 0;
      if (oa != ob) return oa.compareTo(ob);
      final pa = (a['ordre'] is num) ? (a['ordre'] as num).toInt() : 0;
      final pb = (b['ordre'] is num) ? (b['ordre'] as num).toInt() : 0;
      return pa.compareTo(pb);
    });
    return copy;
  }

  List<Map<String, dynamic>> get _items {
    final fromDb = _sorted(widget.bannieres);
    return fromDb.isNotEmpty ? fromDb : List<Map<String, dynamic>>.from(_defaults);
  }

  void _armTimer() {
    _timer?.cancel();
    _timer = null;
    final n = _items.length;
    if (n < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _nextPage());
  }

  void _nextPage() {
    if (!mounted || !_pageCtrl.hasClients) return;
    final len = _items.length;
    if (len < 2) return;
    final cur = _pageCtrl.page?.round() ?? _index;
    final next = (cur + 1) % len;
    _pageCtrl.animateToPage(
      next,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
    );
    _scaleCtrl?.forward(from: 0);
    _fadeCtrl?.forward(from: 0);
  }

  void _goToPage(int i) {
    if (!_pageCtrl.hasClients) return;
    _pageCtrl.animateToPage(
      i,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
    _scaleCtrl?.forward(from: 0);
    _fadeCtrl?.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _scaleCtrl!, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(parent: _fadeCtrl!, curve: Curves.easeOut),
    );
    _scaleCtrl!.forward();
    _fadeCtrl!.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _armTimer());
  }

  @override
  void didUpdateWidget(covariant HomePubBannieresSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bannieres.length != widget.bannieres.length) {
      _armTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    _scaleCtrl?.dispose();
    _fadeCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 768;

    var h = isMobile ? 200.0 : 260.0;
    for (final b in items) {
      if (b['_placeholder'] == true) continue;
      final v = (b['hauteur_px'] is num)
          ? (b['hauteur_px'] as num).toDouble()
          : double.tryParse('${b['hauteur_px'] ?? ''}') ?? 200;
      if (v > h) h = v;
    }
    h = h.clamp(160.0, 320.0);

    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 32 : 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Annonces & offres spéciales',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.w800,
                            color: HomeDesign.dark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Découvrez nos partenaires et actualités',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile)
                    Row(
                      children: [
                        _BoutonNav(
                          icone: Icons.arrow_back_ios_new_rounded,
                          onTap: () {
                            final len = items.length;
                            if (len < 2) return;
                            final prev = (_index - 1 + len) % len;
                            _goToPage(prev);
                          },
                        ),
                        const SizedBox(width: 8),
                        _BoutonNav(
                          icone: Icons.arrow_forward_ios_rounded,
                          onTap: _nextPage,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 20 : 24),
            SizedBox(
              height: h,
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) {
                  setState(() => _index = i);
                  _scaleCtrl?.forward(from: 0);
                  _fadeCtrl?.forward(from: 0);
                },
                itemCount: items.length,
                itemBuilder: (ctx, i) {
                  final isActive = i == _index;
                  final item = items[i];
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    margin: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: isActive ? 0 : 12,
                    ),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_scaleAnim, _fadeAnim]),
                      builder: (context, child) {
                        final scale = isActive ? _scaleAnim.value : 0.95;
                        final opacity = isActive ? _fadeAnim.value.clamp(0.0, 1.0) : 0.9;
                        return Transform.scale(
                          scale: scale,
                          child: Opacity(
                            opacity: opacity,
                            child: child,
                          ),
                        );
                      },
                      child: _CartePub(
                        item: item,
                        isActive: isActive,
                        index: i,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(
                  items.length,
                  (i) => GestureDetector(
                    onTap: () => _goToPage(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _index == i ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: _index == i
                            ? const LinearGradient(
                                colors: [Color(0xFF1A56DB), Color(0xFF38BDF8)],
                              )
                            : null,
                        color: _index != i ? const Color(0xFFCBD5E1) : null,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_index + 1} / ${items.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
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

class _CartePub extends StatefulWidget {
  const _CartePub({
    required this.item,
    required this.isActive,
    required this.index,
  });

  final Map<String, dynamic> item;
  final bool isActive;
  final int index;

  @override
  State<_CartePub> createState() => _CartePubState();
}

class _CartePubState extends State<_CartePub> with SingleTickerProviderStateMixin {
  AnimationController? _shimmerCtrl;
  Animation<double> _shimmerAnim = const AlwaysStoppedAnimation<double>(0);

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _shimmerAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerCtrl!, curve: Curves.linear),
    );
    if (widget.isActive) _shimmerCtrl!.repeat();
  }

  @override
  void didUpdateWidget(covariant _CartePub oldWidget) {
    super.didUpdateWidget(oldWidget);
    final c = _shimmerCtrl;
    if (c == null) return;
    if (widget.isActive && !oldWidget.isActive) {
      c.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      c.stop();
      c.reset();
    }
  }

  @override
  void dispose() {
    _shimmerCtrl?.dispose();
    super.dispose();
  }

  Color _accentColor(Map<String, dynamic> item) {
    final hex = item['couleur_badge']?.toString().trim();
    if (hex != null && hex.isNotEmpty) {
      var h = hex.startsWith('#') ? hex.substring(1) : hex;
      if (h.length == 8) h = h.substring(2);
      if (h.length == 6) {
        final parsed = int.tryParse(h, radix: 16);
        if (parsed != null) return Color(0xFF000000 | parsed);
      }
    }
    final c = item['couleur'];
    if (c is int) return Color(c);
    if (c is num) return Color(c.toInt());
    return HomeDesign.primary;
  }

  void _onCardTap(BuildContext context) {
    final m = widget.item;
    final placeholder = m['_placeholder'] == true;
    final lien = (m['lien_externe'] ?? m['lien_cta_1'])?.toString().trim() ?? '';
    if (!placeholder && lien.isNotEmpty) {
      navigateHomeLink(context, lien);
      return;
    }
    Navigator.of(context).pushNamed(PublicRoutes.listPath);
  }

  @override
  Widget build(BuildContext context) {
    final couleur = _accentColor(widget.item);
    final imgUrl = (widget.item['image_url'] ?? widget.item['image'])?.toString();
    final titre = widget.item['titre']?.toString() ?? '';
    final desc = (widget.item['sous_titre'] ?? widget.item['desc'] ?? widget.item['description'])?.toString();
    final badge = (widget.item['texte_badge'] ?? widget.item['badge'])?.toString();
    final placeholder = widget.item['_placeholder'] == true;
    final lien = (widget.item['lien_externe'] ?? widget.item['lien_cta_1'])?.toString().trim() ?? '';
    final showCta = widget.isActive && (placeholder || lien.isNotEmpty);
    final ctaRaw = (widget.item['label_cta_1'] ?? widget.item['texte_bouton'])?.toString().trim();
    final ctaLabel = (ctaRaw != null && ctaRaw.isNotEmpty) ? ctaRaw : 'Découvrir';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onCardTap(context),
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imgUrl != null && imgUrl.isNotEmpty)
                Image.network(
                  imgUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: couleur.withValues(alpha: 0.35),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                              : null,
                          color: Colors.white54,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, _, _) => _degradFallback(couleur),
                )
              else
                _degradFallback(couleur),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
              if (widget.isActive && _shimmerCtrl != null)
                AnimatedBuilder(
                  animation: _shimmerAnim,
                  builder: (context, _) {
                    return IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: [
                              (_shimmerAnim.value - 0.4).clamp(0.0, 1.0),
                              _shimmerAnim.value.clamp(0.0, 1.0),
                              (_shimmerAnim.value + 0.4).clamp(0.0, 1.0),
                            ],
                            colors: const [
                              Colors.transparent,
                              Color(0x12FFFFFF),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 170;
                  return Padding(
                    padding: EdgeInsets.all(compact ? 14 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                    if (badge != null && badge.isNotEmpty) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 10 : 12,
                          vertical: compact ? 4 : 5,
                        ),
                        decoration: BoxDecoration(
                          color: couleur,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: couleur.withValues(alpha: 0.45),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.inter(
                            fontSize: compact ? 10 : 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 6 : 10),
                    ],
                    AnimatedOpacity(
                      opacity: widget.isActive ? 1 : 0.72,
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        titre,
                        style: GoogleFonts.poppins(
                          fontSize: compact ? 16 : 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.2,
                          shadows: const [
                            Shadow(color: Color(0x8F000000), blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                    if (desc != null && desc.isNotEmpty) ...[
                      SizedBox(height: compact ? 4 : 6),
                      Text(
                        desc,
                        style: GoogleFonts.inter(
                          fontSize: compact ? 11 : 13,
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.4,
                        ),
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (showCta && !compact) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          '$ctaLabel →',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: couleur,
                          ),
                        ),
                      ),
                    ],
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${widget.index + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _degradFallback(Color couleur) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            couleur,
            couleur.withValues(alpha: 0.65),
            HomeDesign.primaryLight.withValues(alpha: 0.9),
          ],
        ),
      ),
    );
  }
}

class _BoutonNav extends StatelessWidget {
  const _BoutonNav({required this.icone, required this.onTap});

  final IconData icone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icone, size: 16, color: const Color(0xFF374151)),
        ),
      ),
    );
  }
}
