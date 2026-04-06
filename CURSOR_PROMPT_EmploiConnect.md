# 🚀 PROMPT CURSOR — EmploiConnect Homepage Flutter
# Copie-colle ce prompt ENTIER dans le chat de Cursor

---

Tu es un expert Flutter senior avec une expertise en UI/UX design premium.
Je travaille sur le projet **EmploiConnect** — une plateforme intelligente de recherche d'emploi en Guinée, développée en Flutter.

Le PRD complet est disponible dans le fichier `PRD.md` à la racine du projet.
Le cahier des charges est disponible dans le fichier `cahier_des_charges.md`.

---

## 🎯 MISSION

Tu dois implémenter la **page d'accueil complète** (`HomeScreen`) de la plateforme EmploiConnect en Flutter.

L'objectif est simple : quand l'utilisateur ouvre l'application, il doit dire **"WAOUH"**.

Design premium, animations fluides, professionnel comme LinkedIn + Indeed + un site tech africain moderne.

---

## 📦 ÉTAPE 1 — INSTALLER LES DÉPENDANCES

Commence par mettre à jour `pubspec.yaml` avec ces packages :

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Navigation
  go_router: ^13.0.0

  # Fonts
  google_fonts: ^6.2.1

  # Images réseau avec cache
  cached_network_image: ^3.3.1

  # Animations premium
  animate_do: ^3.3.4
  lottie: ^3.1.0

  # Carousel / PageView indicator
  smooth_page_indicator: ^1.2.0

  # Icônes premium
  font_awesome_flutter: ^10.7.0

  # Loading skeleton
  shimmer: ^3.0.0

  # Dates relatives ("il y a 2 jours")
  timeago: ^3.6.1

  # Visibilité pour animations au scroll
  visibility_detector: ^0.4.0+2

  # URL launcher (liens footer)
  url_launcher: ^6.2.5

  # HTTP
  dio: ^5.4.0
```

Puis lance : `flutter pub get`

---

## 📁 ÉTAPE 2 — CRÉER LA STRUCTURE DE FICHIERS

Crée exactement cette arborescence dans `lib/` :

```
lib/
├── main.dart
├── app/
│   ├── router.dart
│   └── theme.dart
├── core/
│   └── constants/
│       ├── app_colors.dart
│       ├── app_text_styles.dart
│       └── app_spacing.dart
├── screens/
│   └── home/
│       ├── home_screen.dart
│       └── widgets/
│           ├── navbar_widget.dart
│           ├── hero_section_widget.dart
│           ├── platform_section_widget.dart
│           ├── tips_carousel_widget.dart
│           ├── solutions_section_widget.dart
│           ├── recent_jobs_section_widget.dart
│           └── footer_widget.dart
└── shared/
    └── widgets/
        ├── job_card_widget.dart
        ├── primary_button.dart
        ├── section_header.dart
        └── contract_badge.dart
```

---

## 🎨 ÉTAPE 3 — CRÉER LE SYSTÈME DE DESIGN

### `lib/core/constants/app_colors.dart`

```dart
import 'package:flutter/material.dart';

class AppColors {
  // Primaires
  static const Color primary        = Color(0xFF1A56DB);
  static const Color primaryDark    = Color(0xFF1E3A8A);
  static const Color primaryLight   = Color(0xFF3B82F6);
  static const Color accent         = Color(0xFF0EA5E9);

  // Textes
  static const Color textDark       = Color(0xFF0F172A);
  static const Color textMedium     = Color(0xFF334155);
  static const Color textLight      = Color(0xFF64748B);
  static const Color textWhite      = Color(0xFFFFFFFF);

  // Backgrounds
  static const Color bgWhite        = Color(0xFFFFFFFF);
  static const Color bgLight        = Color(0xFFF8FAFC);
  static const Color bgSection      = Color(0xFFF1F5F9);
  static const Color bgDark         = Color(0xFF0F172A);
  static const Color bgFooter       = Color(0xFF1E293B);

  // Borders
  static const Color border         = Color(0xFFE2E8F0);
  static const Color borderLight    = Color(0xFFF1F5F9);

  // Sémantiques
  static const Color success        = Color(0xFF10B981);
  static const Color successLight   = Color(0xFFD1FAE5);
  static const Color warning        = Color(0xFFF59E0B);
  static const Color warningLight   = Color(0xFFFEF3C7);
  static const Color error          = Color(0xFFEF4444);
  static const Color errorLight     = Color(0xFFFEE2E2);

  // Cards & surfaces
  static const Color cardShadow     = Color(0x14000000);
  static const Color overlay        = Color(0x80000000);
  static const Color overlayLight   = Color(0x40000000);

  // Gradient hero
  static const List<Color> heroGradient = [
    Color(0xCC0F172A),
    Color(0x801A3A8A),
  ];
}
```

### `lib/core/constants/app_text_styles.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle heroTitle = GoogleFonts.poppins(
    fontSize: 52, fontWeight: FontWeight.w800,
    color: AppColors.textWhite, height: 1.15,
  );
  static TextStyle heroTitleMobile = GoogleFonts.poppins(
    fontSize: 32, fontWeight: FontWeight.w800,
    color: AppColors.textWhite, height: 1.2,
  );
  static TextStyle heroSubtitle = GoogleFonts.inter(
    fontSize: 18, fontWeight: FontWeight.w400,
    color: Color(0xCCFFFFFF), height: 1.6,
  );
  static TextStyle sectionTitle = GoogleFonts.poppins(
    fontSize: 34, fontWeight: FontWeight.w700,
    color: AppColors.textDark, height: 1.2,
  );
  static TextStyle sectionTitleMobile = GoogleFonts.poppins(
    fontSize: 26, fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );
  static TextStyle sectionSubtitle = GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textLight, height: 1.6,
  );
  static TextStyle cardTitle = GoogleFonts.poppins(
    fontSize: 17, fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
  static TextStyle cardBody = GoogleFonts.inter(
    fontSize: 14, color: AppColors.textLight, height: 1.5,
  );
  static TextStyle buttonLabel = GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w600,
  );
  static TextStyle navLink = GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w500,
    color: AppColors.textMedium,
  );
  static TextStyle badge = GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w600,
  );
  static TextStyle footerTitle = GoogleFonts.poppins(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );
  static TextStyle footerLink = GoogleFonts.inter(
    fontSize: 14, color: Color(0xAAFFFFFF),
  );
  static TextStyle footerBody = GoogleFonts.inter(
    fontSize: 14, color: Color(0x99FFFFFF), height: 1.6,
  );
  static TextStyle copyright = GoogleFonts.inter(
    fontSize: 13, color: Color(0x66FFFFFF),
  );
}
```

---

## 🏠 ÉTAPE 4 — PAGE D'ACCUEIL PRINCIPALE

### `lib/screens/home/home_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'widgets/navbar_widget.dart';
import 'widgets/hero_section_widget.dart';
import 'widgets/platform_section_widget.dart';
import 'widgets/tips_carousel_widget.dart';
import 'widgets/solutions_section_widget.dart';
import 'widgets/recent_jobs_section_widget.dart';
import 'widgets/footer_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _isScrolled = _scrollController.offset > 50;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: NavbarWidget(isScrolled: _isScrolled),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: const [
            HeroSectionWidget(),
            PlatformSectionWidget(),
            TipsCarouselWidget(),
            SolutionsSectionWidget(),
            RecentJobsSectionWidget(),
            FooterWidget(),
          ],
        ),
      ),
    );
  }
}
```

---

## 🔝 ÉTAPE 5 — NAVBAR

### `lib/screens/home/widgets/navbar_widget.dart`

```dart
// Navbar avec effet glassmorphism au scroll
// - Fond transparent quand en haut de page (sur le hero)
// - Fond blanc avec ombre quand scrollé
// - Logo "EmploiConnect" avec icône briefcase colorée
// - Menu : Accueil | Offres d'emploi | Connexion (outline) | Inscription (filled bleu)
// - Mobile : hamburger → Drawer élégant avec gradient

class NavbarWidget extends StatelessWidget {
  final bool isScrolled;
  const NavbarWidget({super.key, required this.isScrolled});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isScrolled ? Colors.white : Colors.transparent,
        boxShadow: isScrolled
            ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: Offset(0, 2))]
            : [],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              // Logo
              _buildLogo(isScrolled),
              const Spacer(),
              if (!isMobile) _buildDesktopMenu(context, isScrolled),
              if (isMobile) _buildMobileMenuButton(context, isScrolled),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isScrolled) {
    return Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.work_outline, color: Colors.white, size: 20),
      ),
      SizedBox(width: 10),
      Text(
        "EmploiConnect",
        style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: isScrolled ? Color(0xFF0F172A) : Colors.white,
        ),
      ),
    ]);
  }

  Widget _buildDesktopMenu(BuildContext context, bool isScrolled) {
    final textColor = isScrolled ? Color(0xFF334155) : Colors.white;
    return Row(children: [
      _NavItem(label: "Accueil", icon: Icons.home_outlined, color: textColor),
      SizedBox(width: 32),
      _NavItem(label: "Offres d'emploi", icon: Icons.work_outline, color: textColor),
      SizedBox(width: 32),
      // Bouton Connexion
      OutlinedButton.icon(
        icon: Icon(Icons.login_outlined, size: 16),
        label: Text("Connexion"),
        style: OutlinedButton.styleFrom(
          foregroundColor: isScrolled ? Color(0xFF1A56DB) : Colors.white,
          side: BorderSide(color: isScrolled ? Color(0xFF1A56DB) : Colors.white),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {},
      ),
      SizedBox(width: 12),
      // Bouton Inscription
      ElevatedButton.icon(
        icon: Icon(Icons.person_add_outlined, size: 16),
        label: Text("Inscription"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF1A56DB),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: () {},
      ),
    ]);
  }

  // Mobile : Drawer avec gradient sombre et liens animés
  Widget _buildMobileMenuButton(BuildContext context, bool isScrolled) {
    return IconButton(
      icon: Icon(Icons.menu_rounded, color: isScrolled ? Color(0xFF0F172A) : Colors.white, size: 28),
      onPressed: () => Scaffold.of(context).openEndDrawer(),
    );
  }
}
```

---

## 🎬 ÉTAPE 6 — HERO SECTION (L'EFFET "WAOUH" PRINCIPAL)

### `lib/screens/home/widgets/hero_section_widget.dart`

```dart
// Cette section DOIT impressionner. Voici exactement ce qu'il faut faire :

// STRUCTURE : Stack avec 4 couches
// Couche 1 (bas) : PageView d'images qui défilent en fond
// Couche 2 : Gradient sombre (overlay) pour lisibilité
// Couche 3 : Particules décoratives ou formes géométriques animées subtiles
// Couche 4 (haut) : Contenu (texte + boutons + barre recherche + dots)

class HeroSectionWidget extends StatefulWidget {
  const HeroSectionWidget({super.key});
  @override
  State<HeroSectionWidget> createState() => _HeroSectionWidgetState();
}

class _HeroSectionWidgetState extends State<HeroSectionWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  // IMAGES HERO — Utilise des images Unsplash haute qualité
  // Remplace par des assets locaux si disponibles
  final List<String> heroImages = [
    'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?w=1920&q=80',  // Équipe bureau
    'https://images.unsplash.com/photo-1542744173-8e7e53415bb0?w=1920&q=80',  // Réunion professionnelle
    'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?w=1920&q=80',  // Candidat entretien
  ];

  // TEXTES HERO — Un texte différent pour chaque slide
  final List<Map<String, String>> heroContent = [
    {
      'badge': '🇬🇳  Plateforme N°1 en Guinée',
      'title': 'Trouvez l\'Emploi\nde Vos Rêves',
      'subtitle': 'Des milliers d\'offres vérifiées vous attendent.\nPostulez en un clic, décrochez votre opportunité.',
    },
    {
      'badge': '⚡  Matching intelligent par IA',
      'title': 'Votre CV Analysé\nPar l\'Intelligence\nArtificielle',
      'subtitle': 'Notre IA extrait vos compétences et vous\nrecommande les offres les plus pertinentes.',
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
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % heroImages.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;
    final heroHeight = isMobile ? size.height * 0.75 : size.height;

    return SizedBox(
      height: heroHeight,
      child: Stack(
        children: [
          // ── COUCHE 1 : Images en fond ──
          PageView.builder(
            controller: _pageController,
            itemCount: heroImages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (ctx, i) => CachedNetworkImage(
              imageUrl: heroImages[i],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (ctx, url) => Container(color: Color(0xFF0F172A)),
              errorWidget: (ctx, url, err) => Container(
                color: Color(0xFF0F172A),
                child: Icon(Icons.image_outlined, color: Colors.white24, size: 48),
              ),
            ),
          ),

          // ── COUCHE 2 : Gradient overlay ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withOpacity(0.75),
                  Colors.black.withOpacity(0.45),
                ],
              ),
            ),
          ),

          // ── COUCHE 3 : Éléments décoratifs (cercles flous) ──
          Positioned(
            right: -80, top: -80,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1A56DB).withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            right: 100, bottom: 50,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0EA5E9).withOpacity(0.10),
              ),
            ),
          ),

          // ── COUCHE 4 : Contenu principal ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 80), // espace sous la navbar

                // Badge animé
                FadeInDown(
                  key: ValueKey(_currentPage),
                  duration: Duration(milliseconds: 600),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      heroContent[_currentPage]['badge']!,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Titre principal animé
                FadeInLeft(
                  key: ValueKey('title_$_currentPage'),
                  duration: Duration(milliseconds: 700),
                  delay: Duration(milliseconds: 150),
                  child: Text(
                    heroContent[_currentPage]['title']!,
                    style: isMobile
                        ? GoogleFonts.poppins(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)
                        : GoogleFonts.poppins(fontSize: 54, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15),
                  ),
                ),

                SizedBox(height: 20),

                // Sous-titre animé
                FadeInLeft(
                  key: ValueKey('sub_$_currentPage'),
                  duration: Duration(milliseconds: 700),
                  delay: Duration(milliseconds: 250),
                  child: Text(
                    heroContent[_currentPage]['subtitle']!,
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 15 : 18,
                      color: Colors.white.withOpacity(0.80),
                      height: 1.6,
                    ),
                  ),
                ),

                SizedBox(height: 40),

                // Boutons CTA animés
                FadeInUp(
                  key: ValueKey('cta_$_currentPage'),
                  duration: Duration(milliseconds: 700),
                  delay: Duration(milliseconds: 350),
                  child: Wrap(
                    spacing: 16, runSpacing: 12,
                    children: [
                      // CTA Principal
                      ElevatedButton.icon(
                        icon: Icon(Icons.search_rounded, size: 18),
                        label: Text("Trouver un Emploi"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1A56DB),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: () {},
                      ),
                      // CTA Secondaire
                      OutlinedButton.icon(
                        icon: Icon(Icons.business_center_outlined, size: 18),
                        label: Text("Recruter des Talents"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withOpacity(0.7), width: 1.5),
                          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40),

                // Barre de recherche rapide
                FadeInUp(
                  duration: Duration(milliseconds: 700),
                  delay: Duration(milliseconds: 500),
                  child: _buildSearchBar(isMobile),
                ),

                Spacer(),

                // Stats + Dots indicator
                FadeInUp(
                  duration: Duration(milliseconds: 700),
                  delay: Duration(milliseconds: 600),
                  child: Column(
                    children: [
                      // Stats rapides
                      if (!isMobile) _buildHeroStats(),
                      SizedBox(height: 24),
                      // Page indicator dots
                      Row(
                        children: List.generate(heroImages.length, (i) => AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          margin: EdgeInsets.only(right: 8),
                          width: i == _currentPage ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _currentPage ? Colors.white : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        )),
                      ),
                      SizedBox(height: 40),
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
      height: 60,
      constraints: BoxConstraints(maxWidth: 600),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: Offset(0, 10))],
      ),
      child: Row(children: [
        SizedBox(width: 16),
        Icon(Icons.search_rounded, color: Color(0xFF64748B)),
        SizedBox(width: 12),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: "Titre du poste, compétence...",
              hintStyle: GoogleFonts.inter(color: Color(0xFF94A3B8), fontSize: 14),
              border: InputBorder.none,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.all(6),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1A56DB),
              padding: EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: () {},
            child: Text("Rechercher", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeroStats() {
    return Row(children: [
      _StatItem(value: "500+", label: "Offres actives"),
      SizedBox(width: 40),
      _StatItem(value: "1 200+", label: "Candidats inscrits"),
      SizedBox(width: 40),
      _StatItem(value: "150+", label: "Entreprises"),
    ]);
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  const _StatItem({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
      Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.7))),
    ],
  );
}
```

---

## 🏢 ÉTAPE 7 — SECTION PLATEFORME

### `lib/screens/home/widgets/platform_section_widget.dart`

```dart
// Section avec fond blanc, titre centré, 2 cards côte à côte
// Card Candidat (gauche) : icône bleu, titre, description, boutons
// Card Recruteur (droite) : icône vert, titre, description, boutons
// Chaque card a : bordure subtile, hover effect (elevation), icon container coloré

// Layout responsive :
// - Desktop/Tablet (>900px) : Row avec 2 cards
// - Mobile (<900px) : Column avec 2 cards empilées

// Les cards ont un badge "IA" en haut à droite pour la card Recruteur
// Animation : FadeInUp avec delay 200ms en décalé entre les 2 cards
```

---

## 💡 ÉTAPE 8 — CARROUSEL CONSEILS

### `lib/screens/home/widgets/tips_carousel_widget.dart`

```dart
// Fond coloré léger (bgSection #F1F5F9)
// Titre centré
// ListView horizontal en autoplay continu
// 8 cartes minimum : alternance couleurs fond bleu clair / vert clair
// Chaque carte : 280x160px, radius 12, icône + titre + tag catégorie
// MouseRegion pour pause au hover (Flutter Web)
// Sur mobile : drag/swipe natif

// CONTENU DES CARTES :
// [Candidat] Optimisez votre CV · [Candidat] Préparez vos entretiens
// [Candidat] Personnalisez vos lettres · [Candidat] Activez votre réseau
// [Recruteur] Rédigez des offres claires · [Recruteur] Répondez rapidement
// [Recruteur] Valorisez votre marque · [Recruteur] Définissez vos critères
```

---

## ✨ ÉTAPE 9 — SECTION SOLUTIONS

### `lib/screens/home/widgets/solutions_section_widget.dart`

```dart
// Fond blanc
// Titre + sous-titre centrés
// GridView : 3 col desktop / 2 col tablet / 1 col mobile
// 6 cartes avec animation FadeInUp au scroll (VisibilityDetector)
// Chaque carte : icône dans container coloré + titre + description
// Hover effect (MouseRegion) : translateY(-8) + shadow augmentée

// LES 6 SOLUTIONS :
// 1. Recherche Intelligente  - Icons.search_rounded         - bleu
// 2. Candidature Express     - Icons.flash_on_outlined      - orange
// 3. Espace Recruteur Pro    - Icons.business_center_outlined - violet
// 4. Alertes Emploi          - Icons.notifications_outlined  - rouge
// 5. Conseils Personnalisés  - Icons.lightbulb_outline       - jaune
// 6. Profil IA Optimisé      - Icons.psychology_outlined     - vert

// Stagger delay : chaque carte apparaît avec 100ms de décalage
```

---

## 💼 ÉTAPE 10 — SECTION OFFRES RÉCENTES

### `lib/screens/home/widgets/recent_jobs_section_widget.dart`

```dart
// Fond bgLight (#F8FAFC)
// Titre "Dernières Offres d'Emploi" + sous-titre
// FutureBuilder qui appelle jobService.getRecentJobs(limit: 6)
// En attendant les données : Shimmer loading (3 skeleton cards)
// Grille responsive : 3/2/1 colonnes
// Chaque card : JobCardWidget (voir ci-dessous)
// En bas : bouton "Voir toutes les offres →"

// DONNÉES MOCK pour l'instant (si API pas encore prête) :
// Créer une liste de 6 offres fictives avec des données réalistes guinéennes
// Ex: Développeur Flutter · Conakry · CDI · Société Orange Guinée
//     Comptable Senior · Conakry · CDI · Ecobank Guinée
//     Chef de projet · Kindia · CDD · ONG Plan International
//     Data Analyst · Conakry · Stage · MTN Guinée
//     Ingénieur réseau · Conakry · CDI · Sotelgui
//     RH Manager · Labé · CDI · Groupe Hadja Binta

// JobCardWidget doit avoir :
// - Logo entreprise (initiales colorées si pas de logo)
// - Titre poste (bold, bleu au hover)
// - Entreprise + Localisation (avec icônes)
// - Badge type contrat (CDI=vert, CDD=orange, Stage=bleu, Freelance=violet)
// - Résumé tronqué 2 lignes
// - Date relative ("il y a 2 jours")
// - Bouton "Voir les détails" → JobDetailScreen
// - Hover : card se lève légèrement + ombre
```

---

## 🦶 ÉTAPE 11 — FOOTER PREMIUM

### `lib/screens/home/widgets/footer_widget.dart`

```dart
// Le footer doit être IMPRESSIONNANT. Fond sombre #1E293B.
// Structure complète :

Container(
  color: Color(0xFF0F172A),  // fond très sombre
  child: Column(children: [

    // ─── BANDE SUPÉRIEURE COLORÉE ───
    // Container gradient bleu → bleu clair, hauteur 4px tout en haut

    // ─── CORPS PRINCIPAL DU FOOTER (4 colonnes) ───
    Padding(
      padding: EdgeInsets.symmetric(vertical: 64, horizontal: 80 ou 24),
      child: ResponsiveRow(  // Row desktop, Column mobile
        children: [

          // COLONNE 1 — BRANDING (30% de la largeur)
          Column(children: [
            // Logo blanc (icon + texte)
            // Tagline : "La plateforme intelligente de l'emploi en Guinée"
            // Texte corps : description courte en blanc70
            // Réseaux sociaux : 4 boutons circulaires (LinkedIn, Facebook, Twitter, Instagram)
            // Style boutons : 42x42, fond white12, icon white60, hover white20
          ]),

          // COLONNE 2 — LIENS CANDIDATS (20%)
          Column(children: [
            // Titre "Pour les Candidats" (blanc, bold, 16px)
            // Ligne décorative bleue sous le titre (3px, 30px de large)
            // Liste de liens avec petit icône chevron :
            // • Rechercher des offres
            // • Créer un compte
            // • Se connecter
            // • Conseils carrière
            // • Mon espace
          ]),

          // COLONNE 3 — LIENS ENTREPRISES (20%)
          Column(children: [
            // Titre "Pour les Entreprises"
            // Ligne décorative verte
            // Liens :
            // • Publier une offre
            // • Espace Recruteur
            // • Nos solutions
            // • Comment ça marche
            // • Contactez-nous
          ]),

          // COLONNE 4 — CONTACT + NEWSLETTER (30%)
          Column(children: [
            // Titre "Restez Connecté"
            // Texte description newsletter

            // FORMULAIRE NEWSLETTER
            // Row: TextField (fond white10) + bouton arrow bleu
            // TextField style : fond sombre, texte blanc, radius 8, no border

            // INFOS CONTACT avec icônes :
            // 📧 contact@emploiconnect.gn
            // 📞 +224 620 00 00 00
            // 📍 Conakry, République de Guinée

            // BADGE SÉCURITÉ :
            // Petit container avec icône shield + "Données sécurisées"
          ]),
        ],
      ),
    ),

    // ─── DIVIDER ───
    Divider(color: Colors.white12, height: 1),

    // ─── BARRE INFÉRIEURE ───
    Padding(
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 80 ou 24),
      child: Row( // ou Column sur mobile
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Gauche : Logo miniature + Copyright
          // "© 2026 EmploiConnect. Tous droits réservés."
          // "Projet académique — Licence Professionnelle Génie Logiciel"

          // Droite : Liens légaux (séparés par des points ·)
          // Mentions légales · Confidentialité · CGU
        ],
      ),
    ),
  ]),
)

// COULEURS FOOTER :
// Fond principal : #0F172A
// Texte corps : rgba(255,255,255,0.60)
// Texte titres : rgba(255,255,255,1.0) bold
// Liens hover : #3B82F6 (bleu clair) avec transition 200ms
// Icônes sociaux hover : scale(1.1) + fond blue.withOpacity(0.3)
// Divider : rgba(255,255,255,0.08)
```

---

## 🎭 ÉTAPE 12 — ANIMATIONS GLOBALES

Applique ces animations partout de façon cohérente :

```dart
// Au scroll (VisibilityDetector) :
// - FadeInUp : toutes les sections au scroll
// - Durée standard : 600ms
// - Stagger : 100ms entre les éléments d'une même section

// Hover (MouseRegion - Flutter Web) :
// - Cards : translateY(-6px) + shadow augmentée, 200ms
// - Boutons nav : underline qui glisse, 200ms
// - Liens footer : color → #3B82F6, 200ms
// - Icônes sociales : scale(1.1), 150ms

// Hero :
// - Transition de slides : 1000ms easeInOut
// - Contenu par slide : FadeInDown (badge) + FadeInLeft (titre) + FadeInUp (boutons)
// - Key unique par slide pour reset l'animation à chaque changement

// Loading :
// - Shimmer sur les JobCards en attente de données
// - Skeleton : même layout que la vraie card mais avec blocs gris animés
```

---

## ✅ ÉTAPE 13 — VÉRIFICATIONS FINALES

Avant de terminer, vérifie ces points :

1. **Responsive** : tester visuellement à 375px (mobile), 768px (tablet), 1280px (desktop)
2. **Navbar transparente** sur le hero, blanche avec ombre après scroll
3. **Hero** : les images sont bien en fond, texte lisible, dots fonctionnels
4. **Section offres** : données mock en place si API pas prête, shimmer visible au chargement
5. **Footer** : 4 colonnes desktop, empilement propre sur mobile, newsletter field fonctionnel
6. **Toutes les fonts** : Google Fonts chargées (Poppins pour titres, Inter pour corps)
7. **Aucune erreur** dans la console Flutter
8. **hot reload** fonctionne sur toutes les sections

---

## 📝 NOTES IMPORTANTES

- Le nom officiel du projet est **EmploiConnect** (pas JobConnect)
- C'est un projet académique : **Licence Professionnelle Génie Logiciel**, Guinée, 2025-2026
- La plateforme cible le **marché guinéen** — les données mock doivent refléter la réalité locale (entreprises guinéennes, villes de Guinée)
- La composante **IA / NLP** (analyse CV, matching) est prévue mais sera implémentée séparément — se concentrer sur l'UI pour l'instant
- Utilise des **données mock réalistes** pour les offres d'emploi en attendant l'API
- Le design doit être **aussi beau que possible** — c'est un projet de soutenance académique

---

**Commence par l'Étape 1 (pubspec.yaml) et implémente chaque étape dans l'ordre.**
**Montre-moi le résultat après chaque section principale.**
