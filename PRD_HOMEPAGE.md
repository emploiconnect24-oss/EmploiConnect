# PRD — EmploiConnect · Page d'Accueil Extraordinaire
## Product Requirements Document v9.0
**Stack : Flutter + Node.js/Express + Supabase**
**Outil : Cursor / Kirsoft AI**
**Date : Avril 2026**

---

## Vision

```
OBJECTIF :
Créer une page d'accueil qui donne envie dès la première seconde.
Professionnelle, animée, colorée, convaincante.
Quand quelqu'un arrive → il veut immédiatement s'inscrire.
```

---

## Palette de couleurs cohérente

```dart
// Design System EmploiConnect
static const primary   = Color(0xFF1A56DB); // Bleu principal
static const secondary = Color(0xFF7C3AED); // Violet
static const success   = Color(0xFF10B981); // Vert
static const warning   = Color(0xFFF59E0B); // Orange
static const dark      = Color(0xFF0F172A); // Noir profond
static const light     = Color(0xFFF8FAFC); // Blanc cassé

// Dégradés
static const gradientPrimary = LinearGradient(
  colors: [Color(0xFF1A56DB), Color(0xFF7C3AED)]);
static const gradientSuccess = LinearGradient(
  colors: [Color(0xFF10B981), Color(0xFF059669)]);
static const gradientWarm = LinearGradient(
  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]);
```

---

## Table des Matières

1. [Header — Logo + Navigation renforcés](#1-header)
2. [Hero Section — Bannière principale animée](#2-hero-section)
3. [Mini-bannières défilantes publicitaires](#3-mini-bannières-défilantes)
4. [Section Statistiques animées](#4-statistiques-animées)
5. [Section Solutions/Fonctionnalités](#5-solutions--fonctionnalités)
6. [Section Témoignages](#6-témoignages)
7. [Section CTA finale](#7-cta-finale)
8. [Footer extraordinaire](#8-footer)
9. [Admin — Gestion bannières publicitaires](#9-admin--bannières-publicitaires)

---

## 1. Header

```dart
// frontend/lib/screens/home/widgets/header_widget.dart

class HeaderWidget extends StatefulWidget {
  const HeaderWidget({super.key});
  @override
  State<HeaderWidget> createState() => _HeaderState();
}

class _HeaderState extends State<HeaderWidget> {
  bool _scrolled = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(
        horizontal: 40, vertical: 14),
      decoration: BoxDecoration(
        color: _scrolled
            ? Colors.white
            : Colors.transparent,
        boxShadow: _scrolled ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20, offset: const Offset(0, 4))
        ] : [],
      ),
      child: Row(children: [

        // ── Logo agrandi ─────────────────────────────
        Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A56DB), Color(0xFF7C3AED)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(
                color: const Color(0xFF1A56DB).withOpacity(0.3),
                blurRadius: 12, offset: const Offset(0, 4))]),
            child: const Center(child: Text('E',
              style: TextStyle(
                color: Colors.white, fontSize: 22,
                fontWeight: FontWeight.w900)))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text('EmploiConnect',
              style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A))),
            Text('Guinée · Plateforme d\'emploi',
              style: GoogleFonts.inter(
                fontSize: 9, color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500)),
          ]),
        ]),
        const Spacer(),

        // ── Navigation ───────────────────────────────
        if (MediaQuery.of(context).size.width > 900) ...[
          _NavItem('Offres d\'emploi',
            () => context.push('/offres')),
          _NavItem('Entreprises',
            () => context.push('/entreprises')),
          _NavItem('Parcours Carrière',
            () => context.push('/parcours')),
          _NavItem('À propos',
            () => context.push('/about')),
          const SizedBox(width: 20),
        ],

        // ── Boutons Auth ─────────────────────────────
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF1A56DB)),
            foregroundColor: const Color(0xFF1A56DB),
            padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8))),
          onPressed: () => context.push('/login'),
          child: Text('Connexion', style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600))),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A56DB), Color(0xFF7C3AED)]),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(
              color: const Color(0xFF1A56DB).withOpacity(0.3),
              blurRadius: 12, offset: const Offset(0, 4))]),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8))),
            onPressed: () => context.push('/register'),
            child: Text('S\'inscrire gratuitement',
              style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: Colors.white)))),
      ]));
  }
}

class _NavItem extends StatefulWidget {
  final String titre; final VoidCallback onTap;
  const _NavItem(this.titre, this.onTap);
  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit:  (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(
            color: _hovered
                ? const Color(0xFF1A56DB)
                : Colors.transparent,
            width: 2))),
        child: Text(widget.titre, style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w500,
          color: _hovered
              ? const Color(0xFF1A56DB)
              : const Color(0xFF374151))))));
}
```

---

## 2. Hero Section

```dart
// frontend/lib/screens/home/widgets/hero_section.dart

class HeroSection extends StatefulWidget {
  final List<Map<String, dynamic>> bannieres;
  const HeroSection({super.key, required this.bannieres});
  @override
  State<HeroSection> createState() => _HeroState();
}

class _HeroState extends State<HeroSection>
    with TickerProviderStateMixin {

  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late AnimationController _floatCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;
  late Animation<double>   _floatAnim;

  int _banniereIndex = 0;
  Timer? _banniereTimer;

  @override
  void initState() {
    super.initState();

    // Animation d'entrée
    _fadeCtrl  = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 800));
    _slideCtrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 800));
    _floatCtrl = AnimationController(vsync: this,
      duration: const Duration(seconds: 3))
      ..repeat(reverse: true);

    _fadeAnim  = Tween<double>(begin: 0, end: 1)
      .animate(CurvedAnimation(
        parent: _fadeCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3), end: Offset.zero)
      .animate(CurvedAnimation(
        parent: _slideCtrl, curve: Curves.easeOut));
    _floatAnim = Tween<double>(begin: -8, end: 8)
      .animate(CurvedAnimation(
        parent: _floatCtrl, curve: Curves.easeInOut));

    _fadeCtrl.forward();
    _slideCtrl.forward();

    // Auto-défilement bannières
    if (widget.bannieres.length > 1) {
      _banniereTimer = Timer.periodic(
        const Duration(seconds: 5), (_) {
        setState(() {
          _banniereIndex =
            (_banniereIndex + 1) % widget.bannieres.length;
        });
      });
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _floatCtrl.dispose();
    _banniereTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 600),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D1B3E),
            Color(0xFF1A2F5E),
            Color(0xFF2D1B69),
          ])),
      child: Stack(children: [

        // ── Cercles décoratifs animés ──────────────
        Positioned(top: -80, right: -80,
          child: AnimatedBuilder(
            animation: _floatAnim,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _floatAnim.value),
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    const Color(0xFF7C3AED).withOpacity(0.3),
                    Colors.transparent,
                  ]))))),
        ),
        Positioned(bottom: -60, left: -60,
          child: Container(
            width: 250, height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF1A56DB).withOpacity(0.2),
                Colors.transparent,
              ])))),

        // ── Particules flottantes ──────────────────
        ..._buildParticules(),

        // ── Contenu principal ──────────────────────
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 60,
            vertical: 80),
          child: isMobile
              ? _buildMobile()
              : _buildDesktop()),
      ]));
  }

  Widget _buildDesktop() => Row(
    crossAxisAlignment: CrossAxisAlignment.center, children: [

    // ── Texte gauche ─────────────────────────────
    Expanded(child: FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.4))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('🇬🇳 N°1 de l\'emploi en Guinée',
                style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: const Color(0xFF10B981))),
            ])),
          const SizedBox(height: 20),

          // Titre principal
          RichText(text: TextSpan(children: [
            TextSpan(
              text: 'Trouvez votre\n',
              style: GoogleFonts.poppins(
                fontSize: 52, fontWeight: FontWeight.w900,
                color: Colors.white, height: 1.1)),
            TextSpan(
              text: 'emploi idéal ',
              style: GoogleFonts.poppins(
                fontSize: 52, fontWeight: FontWeight.w900,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [Color(0xFF60A5FA), Color(0xFFA78BFA)])
                  .createShader(
                    const Rect.fromLTWH(0, 0, 400, 70)),
                height: 1.1)),
            TextSpan(
              text: 'en\nGuinée',
              style: GoogleFonts.poppins(
                fontSize: 52, fontWeight: FontWeight.w900,
                color: Colors.white, height: 1.1)),
          ])),
          const SizedBox(height: 20),

          Text(
            'La plateforme intelligente qui connecte les '
            'meilleurs talents aux meilleures entreprises '
            'de Guinée. Avec l\'IA pour vous.',
            style: GoogleFonts.inter(
              fontSize: 16, color: Colors.white70,
              height: 1.6)),
          const SizedBox(height: 32),

          // Stats rapides
          Row(children: [
            _StatHero('500+', 'Entreprises'),
            const SizedBox(width: 24),
            _StatHero('2000+', 'Candidats'),
            const SizedBox(width: 24),
            _StatHero('150+', 'Offres actives'),
          ]),
          const SizedBox(height: 32),

          // Boutons CTA
          Row(children: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.4),
                  blurRadius: 20, offset: const Offset(0, 8))]),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.search_rounded,
                  size: 18, color: Colors.white),
                label: Text('Voir les offres',
                  style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
                onPressed: () => context.push('/offres'))),
            const SizedBox(width: 14),
            OutlinedButton.icon(
              icon: const Icon(Icons.business_rounded,
                size: 18, color: Colors.white),
              label: Text('Recruter un talent',
                style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: Colors.white38),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
              onPressed: () => context.push('/register-recruteur')),
          ]),
        ])))),

    const SizedBox(width: 40),

    // ── Bannière carousel droite ──────────────────
    SizedBox(
      width: 380,
      child: _buildCarouselBannieres()),
  ]);

  Widget _buildCarouselBannieres() {
    if (widget.bannieres.isEmpty) {
      return _buildIllustrationDefaut();
    }

    return Column(children: [
      // Carousel principal
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.2, 0),
              end: Offset.zero).animate(anim),
            child: child)),
        child: _buildCarteBanniere(
          widget.bannieres[_banniereIndex],
          key: ValueKey(_banniereIndex))),
      const SizedBox(height: 12),

      // Indicateurs
      Row(mainAxisAlignment: MainAxisAlignment.center, children:
        List.generate(widget.bannieres.length, (i) =>
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _banniereIndex ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == _banniereIndex
                  ? const Color(0xFF10B981)
                  : Colors.white30,
              borderRadius: BorderRadius.circular(100))))),
    ]);
  }

  Widget _buildCarteBanniere(
      Map<String, dynamic> b, {Key? key}) =>
    Container(
      key: key,
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: b['image_url'] != null
            ? DecorationImage(
                image: NetworkImage(b['image_url'] as String),
                fit: BoxFit.cover)
            : null,
        gradient: b['image_url'] == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A56DB).withOpacity(0.8),
                  const Color(0xFF7C3AED).withOpacity(0.8),
                ]) : null,
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 30, offset: const Offset(0, 15))]),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.6),
            ])),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
          if (b['badge'] != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(100)),
              child: Text(b['badge'] as String,
                style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w800,
                  color: Colors.white))),
          const SizedBox(height: 8),
          Text(b['titre'] as String? ?? '',
            style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.w800,
              color: Colors.white)),
          if (b['description'] != null) ...[
            const SizedBox(height: 6),
            Text(b['description'] as String,
              style: GoogleFonts.inter(
                fontSize: 13, color: Colors.white70)),
          ],
          if (b['lien'] != null) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => context.push(b['lien'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8)),
                child: Text('En savoir plus →',
                  style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A56DB))))),
          ],
        ])));

  Widget _buildIllustrationDefaut() => AnimatedBuilder(
    animation: _floatAnim,
    builder: (_, __) => Transform.translate(
      offset: Offset(0, _floatAnim.value * 0.5),
      child: Container(
        height: 360,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A5F), Color(0xFF2D1B69)]),
          boxShadow: [BoxShadow(
            color: const Color(0xFF1A56DB).withOpacity(0.3),
            blurRadius: 40, offset: const Offset(0, 20))]),
        child: Stack(children: [
          // Illustration personne heureuse
          Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('👩‍💼', style: const TextStyle(fontSize: 80)),
            const SizedBox(height: 16),
            Text('Votre prochaine opportunité\nvous attend !',
              style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: Colors.white, height: 1.4),
              textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _MiniStat('🏆', '500+', 'Offres'),
              const SizedBox(width: 20),
              _MiniStat('⭐', '98%', 'Satisfaction'),
              const SizedBox(width: 20),
              _MiniStat('🚀', '24h', 'Réponse'),
            ]),
          ])),

          // Badges flottants
          Positioned(top: 20, right: 20,
            child: _BadgeFlottant('🎯 IA intégrée',
              const Color(0xFF10B981))),
          Positioned(bottom: 30, left: 20,
            child: _BadgeFlottant('✅ Gratuit',
              const Color(0xFFF59E0B))),
        ]))));

  Widget _buildMobile() => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    // Badge
    Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.15),
        borderRadius: BorderRadius.circular(100)),
      child: Text('🇬🇳 N°1 de l\'emploi en Guinée',
        style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: const Color(0xFF10B981)))),
    const SizedBox(height: 16),

    Text('Trouvez votre\nemploi idéal',
      style: GoogleFonts.poppins(
        fontSize: 36, fontWeight: FontWeight.w900,
        color: Colors.white, height: 1.1)),
    const SizedBox(height: 12),

    Text(
      'La plateforme intelligente pour l\'emploi en Guinée.',
      style: GoogleFonts.inter(
        fontSize: 14, color: Colors.white70)),
    const SizedBox(height: 24),

    SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12))),
        onPressed: () => context.push('/offres'),
        child: Text('Voir les offres',
          style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: Colors.white)))),
  ]);

  List<Widget> _buildParticules() {
    final positions = [
      [0.1, 0.2], [0.9, 0.1], [0.5, 0.8],
      [0.2, 0.7], [0.8, 0.6], [0.3, 0.4],
    ];
    return positions.asMap().entries.map((entry) {
      final i = entry.key;
      final pos = entry.value;
      return Positioned(
        left: pos[0] * MediaQuery.of(context).size.width,
        top:  pos[1] * 500,
        child: AnimatedBuilder(
          animation: _floatCtrl,
          builder: (_, __) => Transform.translate(
            offset: Offset(0,
              _floatAnim.value * (i % 2 == 0 ? 1 : -1)),
            child: Container(
              width: 4, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle)))));
    }).toList();
  }
}

class _StatHero extends StatelessWidget {
  final String nombre, label;
  const _StatHero(this.nombre, this.label);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(nombre, style: GoogleFonts.poppins(
      fontSize: 24, fontWeight: FontWeight.w900,
      color: Colors.white)),
    Text(label, style: GoogleFonts.inter(
      fontSize: 11, color: Colors.white54)),
  ]);
}

class _MiniStat extends StatelessWidget {
  final String emoji, valeur, label;
  const _MiniStat(this.emoji, this.valeur, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 20)),
    Text(valeur, style: GoogleFonts.poppins(
      fontSize: 14, fontWeight: FontWeight.w800,
      color: Colors.white)),
    Text(label, style: GoogleFonts.inter(
      fontSize: 10, color: Colors.white54)),
  ]);
}

class _BadgeFlottant extends StatelessWidget {
  final String texte; final Color couleur;
  const _BadgeFlottant(this.texte, this.couleur);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: couleur,
      borderRadius: BorderRadius.circular(100),
      boxShadow: [BoxShadow(
        color: couleur.withOpacity(0.4),
        blurRadius: 10, offset: const Offset(0, 4))]),
    child: Text(texte, style: GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w700,
      color: Colors.white)));
}
```

---

## 3. Mini-bannières défilantes

```dart
// frontend/lib/screens/home/widgets/ticker_bannieres.dart
// Défilement horizontal automatique de mini-bannières pub

class TickerBannieres extends StatefulWidget {
  final List<Map<String, dynamic>> bannieres;
  const TickerBannieres({super.key, required this.bannieres});
  @override
  State<TickerBannieres> createState() => _TickerState();
}

class _TickerState extends State<TickerBannieres>
    with SingleTickerProviderStateMixin {

  late ScrollController _scrollCtrl;
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _scrollTimer = Timer.periodic(
      const Duration(milliseconds: 30), (_) {
      if (!_scrollCtrl.hasClients) return;
      final max = _scrollCtrl.position.maxScrollExtent;
      final cur = _scrollCtrl.offset;
      if (cur >= max) {
        _scrollCtrl.jumpTo(0);
      } else {
        _scrollCtrl.animateTo(
          cur + 1,
          duration: const Duration(milliseconds: 30),
          curve: Curves.linear);
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [...widget.bannieres,
      ...widget.bannieres]; // Dupliquer pour loop infini

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B3E), Color(0xFF1A2F5E)])),
      child: Row(children: [
        // Label fixe
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 0),
          color: const Color(0xFF1A56DB),
          child: Row(children: [
            const Icon(Icons.campaign_rounded,
              color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text('INFO',
              style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w900,
                color: Colors.white, letterSpacing: 1)),
          ])),

        // Défilement
        Expanded(child: ListView.builder(
          controller:    _scrollCtrl,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.isEmpty ? 1 : items.length,
          itemBuilder: (ctx, i) {
            if (items.isEmpty) {
              return _TickerItem(
                '🚀 Bienvenue sur EmploiConnect — '
                'La plateforme N°1 de l\'emploi en Guinée !',
                const Color(0xFF10B981));
            }
            final item = items[i];
            return _TickerItem(
              item['titre'] as String? ?? '',
              _couleurTicker(i));
          })),
      ]));
  }

  Color _couleurTicker(int i) {
    final couleurs = [
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFF0EA5E9),
    ];
    return couleurs[i % couleurs.length];
  }
}

class _TickerItem extends StatelessWidget {
  final String texte; final Color couleur;
  const _TickerItem(this.texte, this.couleur);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(children: [
      Container(
        width: 6, height: 6,
        decoration: BoxDecoration(
          color: couleur, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Text(texte, style: GoogleFonts.inter(
        fontSize: 12, color: Colors.white70,
        fontWeight: FontWeight.w500)),
      const SizedBox(width: 30),
      Container(
        width: 1, height: 20,
        color: Colors.white12),
    ]));
}
```

---

## 4. Statistiques animées

```dart
// frontend/lib/screens/home/widgets/stats_section.dart

class StatsSection extends StatefulWidget {
  const StatsSection({super.key});
  @override
  State<StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends State<StatsSection>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  bool _visible = false;

  final _stats = [
    {'icone': '🏢', 'nombre': 500,  'label': 'Entreprises',
     'couleur': const Color(0xFF1A56DB)},
    {'icone': '👤', 'nombre': 2000, 'label': 'Candidats',
     'couleur': const Color(0xFF10B981)},
    {'icone': '💼', 'nombre': 150,  'label': 'Offres actives',
     'couleur': const Color(0xFF8B5CF6)},
    {'icone': '✅', 'nombre': 98,   'label': '% Satisfaction',
     'couleur': const Color(0xFFF59E0B)},
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 2000));
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _visible = true);
        _ctrl.forward();
      }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 60, vertical: 60),
    color: Colors.white,
    child: Column(children: [

      // Titre section
      Text('Des chiffres qui parlent',
        style: GoogleFonts.poppins(
          fontSize: 32, fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A))),
      const SizedBox(height: 8),
      Text('La confiance de milliers de Guinéens',
        style: GoogleFonts.inter(
          fontSize: 15, color: const Color(0xFF64748B))),
      const SizedBox(height: 40),

      // Stats grid
      Wrap(
        spacing: 20, runSpacing: 20,
        alignment: WrapAlignment.center,
        children: _stats.map((s) {
          final couleur = s['couleur'] as Color;
          final nombre  = s['nombre'] as int;

          return AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final valeur =
                (_ctrl.value * nombre).round();
              return Container(
                width: 200,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: couleur.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: couleur.withOpacity(0.2))),
                child: Column(children: [
                  Text(s['icone'] as String,
                    style: const TextStyle(fontSize: 36)),
                  const SizedBox(height: 12),
                  Text(
                    nombre == 98
                        ? '$valeur%'
                        : '$valeur+',
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: couleur)),
                  Text(s['label'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500)),
                ]));
            });
        }).toList()),
    ]));
}
```

---

## 5. Solutions / Fonctionnalités

```dart
// frontend/lib/screens/home/widgets/solutions_section.dart

class SolutionsSection extends StatelessWidget {
  const SolutionsSection({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 60, vertical: 80),
    color: const Color(0xFFF8FAFC),
    child: Column(children: [

      // Header
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A56DB).withOpacity(0.1),
          borderRadius: BorderRadius.circular(100)),
        child: Text('✨ Propulsé par l\'IA',
          style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: const Color(0xFF1A56DB)))),
      const SizedBox(height: 16),
      Text('Pourquoi choisir EmploiConnect ?',
        style: GoogleFonts.poppins(
          fontSize: 32, fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A)),
        textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text(
        'Des fonctionnalités intelligentes pour vous '
        'aider à réussir votre carrière',
        style: GoogleFonts.inter(
          fontSize: 15, color: const Color(0xFF64748B)),
        textAlign: TextAlign.center),
      const SizedBox(height: 48),

      // Grille solutions
      Wrap(
        spacing: 20, runSpacing: 20,
        alignment: WrapAlignment.center,
        children: [
          _CarteFeature(
            emoji:   '🤖',
            titre:   'IA de matching',
            desc:    'Claude analyse votre profil et vous '
                     'propose les offres les plus compatibles.',
            couleur: const Color(0xFF1A56DB),
            badge:   'Populaire'),
          _CarteFeature(
            emoji:   '📄',
            titre:   'Créateur de CV',
            desc:    'Générez un CV professionnel en quelques '
                     'minutes avec nos modèles.',
            couleur: const Color(0xFF10B981)),
          _CarteFeature(
            emoji:   '🎤',
            titre:   'Simulateur d\'entretien',
            desc:    'Préparez-vous avec notre IA qui simule '
                     'de vrais entretiens.',
            couleur: const Color(0xFF8B5CF6),
            badge:   'Nouveau'),
          _CarteFeature(
            emoji:   '💰',
            titre:   'Calculateur de salaire',
            desc:    'Connaissez votre valeur sur le marché '
                     'guinéen grâce à l\'IA.',
            couleur: const Color(0xFFF59E0B)),
          _CarteFeature(
            emoji:   '🔔',
            titre:   'Alertes emploi',
            desc:    'Recevez les nouvelles offres qui '
                     'correspondent à votre profil.',
            couleur: const Color(0xFF0EA5E9)),
          _CarteFeature(
            emoji:   '🏆',
            titre:   'Parcours Carrière',
            desc:    'Guides, ressources et conseils pour '
                     'développer vos compétences.',
            couleur: const Color(0xFFEF4444)),
        ]),
    ]));
}

class _CarteFeature extends StatefulWidget {
  final String emoji, titre, desc; final Color couleur;
  final String? badge;
  const _CarteFeature({required this.emoji, required this.titre,
    required this.desc, required this.couleur, this.badge});
  @override
  State<_CarteFeature> createState() => _CarteFeatureState();
}

class _CarteFeatureState extends State<_CarteFeature> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit:  (_) => setState(() => _hovered = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 280,
      padding: const EdgeInsets.all(24),
      transform: Matrix4.identity()
        ..translate(0.0, _hovered ? -6.0 : 0.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hovered
              ? widget.couleur.withOpacity(0.4)
              : const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(
          color: _hovered
              ? widget.couleur.withOpacity(0.15)
              : Colors.black.withOpacity(0.05),
          blurRadius: _hovered ? 24 : 10,
          offset: const Offset(0, 8))]),
      child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: widget.couleur.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(widget.emoji,
              style: const TextStyle(fontSize: 26)))),
          const SizedBox(height: 16),
          Text(widget.titre, style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text(widget.desc, style: GoogleFonts.inter(
            fontSize: 13, color: const Color(0xFF64748B),
            height: 1.5)),
        ]),
        if (widget.badge != null)
          Positioned(top: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: widget.couleur,
                borderRadius: BorderRadius.circular(100)),
              child: Text(widget.badge!,
                style: GoogleFonts.inter(
                  fontSize: 9, fontWeight: FontWeight.w800,
                  color: Colors.white)))),
      ])));
}
```

---

## 6. Témoignages

```dart
// frontend/lib/screens/home/widgets/temoignages_section.dart

class TemoignagesSection extends StatefulWidget {
  final List<Map<String, dynamic>> temoignages;
  const TemoignagesSection({super.key, required this.temoignages});
  @override
  State<TemoignagesSection> createState() =>
    _TemoignagesSectionState();
}

class _TemoignagesSectionState extends State<TemoignagesSection> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.temoignages.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        setState(() =>
          _index = (_index + 1) % widget.temoignages.length);
      });
    }
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 60, vertical: 80),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0D1B3E), Color(0xFF1A2F5E)])),
    child: Column(children: [

      Text('Ce que disent nos utilisateurs',
        style: GoogleFonts.poppins(
          fontSize: 32, fontWeight: FontWeight.w800,
          color: Colors.white),
        textAlign: TextAlign.center),
      const SizedBox(height: 40),

      if (widget.temoignages.isEmpty)
        _buildTemoignageDefaut()
      else
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _buildCarteTemoignage(
            widget.temoignages[_index],
            key: ValueKey(_index))),
      const SizedBox(height: 20),

      if (widget.temoignages.length > 1)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.temoignages.length, (i) =>
            GestureDetector(
              onTap: () => setState(() => _index = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(
                  horizontal: 4),
                width: i == _index ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _index
                      ? const Color(0xFF10B981)
                      : Colors.white30,
                  borderRadius:
                    BorderRadius.circular(100))))),
    ]));

  Widget _buildCarteTemoignage(
      Map<String, dynamic> t, {Key? key}) =>
    Container(
      key: key,
      constraints: const BoxConstraints(maxWidth: 700),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.15))),
      child: Column(children: [
        Text('❝', style: GoogleFonts.poppins(
          fontSize: 48, color: const Color(0xFF10B981),
          height: 1)),
        const SizedBox(height: 12),
        Text(t['message'] as String? ?? '',
          style: GoogleFonts.inter(
            fontSize: 16, color: Colors.white,
            height: 1.7, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center,
          children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF1A56DB),
            backgroundImage: t['photo'] != null
                ? NetworkImage(t['photo'] as String)
                : null,
            child: t['photo'] == null
                ? Text((t['nom'] as String? ?? '?')[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700))
                : null),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(t['nom'] as String? ?? '',
              style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: Colors.white)),
            Text(t['poste'] as String? ?? '',
              style: GoogleFonts.inter(
                fontSize: 12, color: Colors.white54)),
          ]),
        ]),
      ]));

  Widget _buildTemoignageDefaut() => Container(
    constraints: const BoxConstraints(maxWidth: 600),
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20)),
    child: Column(children: [
      const Text('❝', style: TextStyle(
        fontSize: 40, color: Color(0xFF10B981))),
      const SizedBox(height: 12),
      Text(
        'EmploiConnect m\'a aidé à trouver mon emploi '
        'en seulement 2 semaines ! L\'IA a parfaitement '
        'compris mon profil.',
        style: GoogleFonts.inter(
          fontSize: 15, color: Colors.white,
          height: 1.7, fontStyle: FontStyle.italic),
        textAlign: TextAlign.center),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center,
        children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xFF10B981),
          child: Text('M', style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700))),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text('Mamadou Diallo',
            style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: Colors.white)),
          Text('Développeur · Conakry',
            style: GoogleFonts.inter(
              fontSize: 11, color: Colors.white54)),
        ]),
      ]),
    ]));
}
```

---

## 7. CTA finale

```dart
// frontend/lib/screens/home/widgets/cta_section.dart

class CTASection extends StatelessWidget {
  const CTASection({super.key});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(
      horizontal: 60, vertical: 60),
    padding: const EdgeInsets.symmetric(
      horizontal: 60, vertical: 60),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A56DB), Color(0xFF7C3AED)]),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(
        color: const Color(0xFF1A56DB).withOpacity(0.3),
        blurRadius: 40, offset: const Offset(0, 20))]),
    child: Column(children: [
      Text('🚀', style: const TextStyle(fontSize: 48)),
      const SizedBox(height: 16),
      Text('Prêt à changer votre vie ?',
        style: GoogleFonts.poppins(
          fontSize: 36, fontWeight: FontWeight.w900,
          color: Colors.white),
        textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Text(
        'Rejoignez des milliers de Guinéens qui ont '
        'trouvé leur emploi idéal grâce à EmploiConnect.',
        style: GoogleFonts.inter(
          fontSize: 16, color: Colors.white70, height: 1.6),
        textAlign: TextAlign.center),
      const SizedBox(height: 32),
      Wrap(
        spacing: 16, runSpacing: 16,
        alignment: WrapAlignment.center,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add_rounded,
              size: 18, color: Color(0xFF1A56DB)),
            label: Text('Je cherche un emploi',
              style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: const Color(0xFF1A56DB))),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 28, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
            onPressed: () => context.push('/register')),
          OutlinedButton.icon(
            icon: const Icon(Icons.business_rounded,
              size: 18, color: Colors.white),
            label: Text('Je recrute',
              style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: Colors.white)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: Colors.white70),
              padding: const EdgeInsets.symmetric(
                horizontal: 28, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
            onPressed: () =>
              context.push('/register-recruteur')),
        ]),
    ]));
}
```

---

## 8. Footer

```dart
// frontend/lib/screens/home/widgets/footer_widget.dart

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF0D1B3E),
    child: Column(children: [

      // ── Contenu principal ────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(60, 60, 60, 40),
        child: Wrap(
          spacing: 40, runSpacing: 40,
          children: [

          // Logo + description
          SizedBox(width: 280, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A56DB),
                             Color(0xFF7C3AED)]),
                  borderRadius: BorderRadius.circular(10)),
                child: const Center(child: Text('E',
                  style: TextStyle(
                    color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.w900)))),
              const SizedBox(width: 10),
              Text('EmploiConnect',
                style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: Colors.white)),
            ]),
            const SizedBox(height: 14),
            Text(
              'La plateforme intelligente de l\'emploi '
              'en Guinée. Connectons les talents aux '
              'meilleures opportunités.',
              style: GoogleFonts.inter(
                fontSize: 13, color: Colors.white54,
                height: 1.6)),
            const SizedBox(height: 20),
            // Réseaux sociaux
            Row(children: [
              _SocialBtn('f', 'Facebook'),
              const SizedBox(width: 10),
              _SocialBtn('in', 'LinkedIn'),
              const SizedBox(width: 10),
              _SocialBtn('tw', 'Twitter'),
            ]),
          ])),

          // Liens candidats
          _ColonneFooter('Pour les candidats', [
            'Rechercher un emploi',
            'Créer mon CV',
            'Simulateur d\'entretien',
            'Calculateur de salaire',
            'Parcours Carrière',
          ]),

          // Liens recruteurs
          _ColonneFooter('Pour les entreprises', [
            'Publier une offre',
            'Rechercher des talents',
            'Tarifs',
            'Témoignages',
          ]),

          // Contact
          _ColonneFooter('Contact', [
            '📍 Conakry, Guinée',
            '📧 contact@emploiconnect.gn',
            '📞 +224 XX XX XX XX',
            '🕒 Lun-Ven 8h-18h',
          ]),
        ])),

      // ── Séparateur ───────────────────────────────
      Container(
        height: 1,
        color: Colors.white.withOpacity(0.08)),

      // ── Bas de footer ────────────────────────────
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 60, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
          Text(
            '© 2025 EmploiConnect · Guinée · '
            'Tous droits réservés',
            style: GoogleFonts.inter(
              fontSize: 12, color: Colors.white38)),
          Row(children: [
            _LienFooter('Politique de confidentialité'),
            const SizedBox(width: 20),
            _LienFooter('Conditions d\'utilisation'),
            const SizedBox(width: 20),
            _LienFooter('Mentions légales'),
          ]),
        ])),
    ]));
}

class _ColonneFooter extends StatelessWidget {
  final String titre; final List<String> liens;
  const _ColonneFooter(this.titre, this.liens);
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titre, style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: Colors.white)),
      const SizedBox(height: 14),
      ...liens.map((l) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(l, style: GoogleFonts.inter(
          fontSize: 12, color: Colors.white54)))),
    ]));
}

class _SocialBtn extends StatelessWidget {
  final String initiale, nom;
  const _SocialBtn(this.initiale, this.nom);
  @override
  Widget build(BuildContext context) => Container(
    width: 34, height: 34,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: Colors.white.withOpacity(0.15))),
    child: Center(child: Text(initiale,
      style: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: Colors.white54))));
}

class _LienFooter extends StatelessWidget {
  final String texte;
  const _LienFooter(this.texte);
  @override
  Widget build(BuildContext context) => Text(texte,
    style: GoogleFonts.inter(
      fontSize: 11, color: Colors.white38));
}
```

---

## 9. Admin — Bannières publicitaires

### Migration SQL

```sql
-- Supabase SQL Editor
ALTER TABLE bannieres_homepage
  ADD COLUMN IF NOT EXISTS type_banniere TEXT DEFAULT 'hero'
    CHECK (type_banniere IN ('hero', 'ticker', 'pub'));
ADD COLUMN IF NOT EXISTS badge TEXT;
ADD COLUMN IF NOT EXISTS lien TEXT;
ADD COLUMN IF NOT EXISTS ordre INTEGER DEFAULT 0;

-- Bannières ticker (mini-bannières défilantes)
-- type_banniere = 'ticker' → apparaît dans le ticker en haut
-- type_banniere = 'hero'   → apparaît dans le carousel principal
-- type_banniere = 'pub'    → apparaît en sidebar
```

### Flutter Admin — Ajout type bannière

```dart
// Dans admin_bannieres_page.dart
// Ajouter sélecteur de type :

DropdownButtonFormField<String>(
  value: _type,
  decoration: const InputDecoration(
    labelText: 'Type de bannière'),
  items: const [
    DropdownMenuItem(value: 'hero',
      child: Text('🖼️ Hero (carousel principal)')),
    DropdownMenuItem(value: 'ticker',
      child: Text('📢 Ticker (défilement info)')),
    DropdownMenuItem(value: 'pub',
      child: Text('📣 Publicitaire (sidebar)')),
  ],
  onChanged: (v) => setState(() => _type = v ?? 'hero')),
```

---

## Page d'accueil principale — Assembler tout

```dart
// frontend/lib/screens/home/home_page.dart

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _bannieres    = [];
  List<Map<String, dynamic>> _temoignages  = [];
  List<Map<String, dynamic>> _tickerItems  = [];
  bool _isLoading = true;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Charger bannières + témoignages depuis l'API
      final banRes = await http.get(Uri.parse(
        '${ApiConfig.baseUrl}/api/bannieres'));
      final temRes = await http.get(Uri.parse(
        '${ApiConfig.baseUrl}/api/temoignages'));

      if (banRes.statusCode == 200) {
        final body = jsonDecode(banRes.body);
        final all  = List<Map<String, dynamic>>.from(
          body['data'] ?? []);
        setState(() {
          _bannieres   = all.where((b) =>
            b['type_banniere'] == 'hero').toList();
          _tickerItems = all.where((b) =>
            b['type_banniere'] == 'ticker').toList();
        });
      }

      if (temRes.statusCode == 200) {
        final body = jsonDecode(temRes.body);
        setState(() => _temoignages =
          List<Map<String, dynamic>>.from(
            body['data'] ?? []));
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(
              color: Color(0xFF1A56DB)))
          : CustomScrollView(
              controller: _scrollCtrl,
              slivers: [

              // Header fixe
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.white,
                toolbarHeight: 70,
                flexibleSpace: FlexibleSpaceBar(
                  background: HeaderWidget())),

              // Ticker défilant
              SliverToBoxAdapter(
                child: TickerBannieres(
                  bannieres: _tickerItems)),

              // Hero section
              SliverToBoxAdapter(
                child: HeroSection(
                  bannieres: _bannieres)),

              // Statistiques
              SliverToBoxAdapter(
                child: const StatsSection()),

              // Solutions
              SliverToBoxAdapter(
                child: const SolutionsSection()),

              // Témoignages
              SliverToBoxAdapter(
                child: TemoignagesSection(
                  temoignages: _temoignages)),

              // CTA
              SliverToBoxAdapter(
                child: const CTASection()),

              // Footer
              SliverToBoxAdapter(
                child: const FooterWidget()),
            ]));
  }
}
```

---

## Critères d'Acceptation

- [ ] Header avec grand logo + navigation responsive
- [ ] Hero section avec gradient sombre + animations
- [ ] Carousel bannières (images de personnes heureuses)
- [ ] Ticker défilant avec infos publicitaires
- [ ] Statistiques avec compteur animé
- [ ] Section 6 fonctionnalités avec hover effect
- [ ] Témoignages avec carousel automatique
- [ ] Section CTA avec dégradé
- [ ] Footer professionnel avec 4 colonnes
- [ ] Admin : créer bannières hero + ticker + pub
- [ ] Responsive mobile + desktop

---

*PRD EmploiConnect v9.0 — Page d'accueil extraordinaire*
*Cursor / Kirsoft AI — Phase 23*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
