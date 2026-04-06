# 🔄 MISE À JOUR PRD — EmploiConnect Auth
## Patch v1.3 — Cohérence Visuelle & Pages Auth Premium
**À APPLIQUER après PRD_AUTH_v2.md**
**Basé sur analyse visuelle de la homepage validée**
**Date : Mars 2026**

---

> ### ⚠️ INSTRUCTIONS POUR CURSOR
>
> Ce fichier est un **PATCH** qui complète et corrige le PRD_AUTH_v2.md.
> Les règles ici ont **priorité absolue** sur tout ce qui était écrit avant.
> Appliquer dans l'ordre : corrections homepage → puis pages auth.

---

## PARTIE 1 — CORRECTIONS HOMEPAGE (petites retouches)

### 1.1 Correction Navbar — Transparence sur le Hero

```dart
// ❌ PROBLÈME ACTUEL : la navbar a un fond blanc même sur le hero
// ✅ CORRECTION : navbar transparente sur le hero, blanche au scroll

// Dans navbar_widget.dart — le AppBar doit utiliser isScrolled
// qui vient du ScrollController de HomeScreen

// HomeScreen doit passer isScrolled à la navbar :
_scrollController.addListener(() {
  setState(() => _isScrolled = _scrollController.offset > 10);
});

// NavbarWidget :
AnimatedContainer(
  duration: Duration(milliseconds: 250),
  color: isScrolled
      ? Colors.white                    // blanc avec ombre au scroll
      : Colors.transparent,             // transparent sur le hero
  child: ...
)

// Ombre uniquement quand scrollé :
boxShadow: isScrolled
    ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: Offset(0, 2))]
    : [],

// Couleur du texte des liens nav (Accueil, Offres d'emploi) :
color: isScrolled ? Color(0xFF334155) : Colors.white

// Bouton Connexion :
// Sur hero (transparent) → outline blanc + texte blanc
// Après scroll → outline bleu + texte bleu
foregroundColor: isScrolled ? Color(0xFF1A56DB) : Colors.white,
side: BorderSide(color: isScrolled ? Color(0xFF1A56DB) : Colors.white),

// Bouton Inscription :
// Toujours bleu — ne change pas
backgroundColor: Color(0xFF1A56DB), foregroundColor: Colors.white,
```

### 1.2 Correction Bouton "Recruter des Talents" dans le Hero

```dart
// ❌ PROBLÈME : fond blanc opaque sur image sombre — très moche
// ✅ CORRECTION : outline blanc transparent

OutlinedButton.icon(
  icon: Icon(Icons.business_center_outlined, size: 18),
  label: Text("Recruter des Talents"),
  style: OutlinedButton.styleFrom(
    foregroundColor: Colors.white,
    side: BorderSide(color: Colors.white.withOpacity(0.85), width: 1.5),
    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    backgroundColor: Colors.white.withOpacity(0.08), // léger fond blanc translucide
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
  ),
  onPressed: () => context.push('/inscription-entreprise'),
),
```

### 1.3 Correction Boutons Secondaires des Cards Plateforme

```dart
// ❌ PROBLÈME : "Explorer les offres" et "Découvrir les solutions"
//              sont en gris neutre — pas cohérent avec la charte bleue

// ✅ CORRECTION : outline bleu pour tous les boutons secondaires des cards

OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: Color(0xFF1A56DB),
    side: BorderSide(color: Color(0xFF1A56DB), width: 1.5),
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
  ),
  onPressed: () => context.push('/offres'),
  child: Text("Explorer les offres"),
),
```

### 1.4 Correction Séparation Visuelle des Sections

```dart
// ❌ PROBLÈME : toutes les sections ont le même fond blanc
//              → impossible de distinguer visuellement où une section s'arrête

// ✅ CORRECTION : alternance de fonds
// Section Hero          : image de fond (ok)
// Section Plateforme    : Color(0xFFF8FAFC)  ← fond gris très léger
// Section Conseils      : Colors.white
// Section Solutions     : Color(0xFFF1F5F9)  ← fond slate très léger
// Section Offres        : Colors.white
// Footer                : Color(0xFF0F172A)  ← sombre

// Appliquer dans chaque widget de section :
// platform_section_widget.dart :
Container(color: Color(0xFFF8FAFC), ...)

// solutions_section_widget.dart :
Container(color: Color(0xFFF1F5F9), ...)
```

---

## PARTIE 2 — TOKENS DE DESIGN UNIFIÉS

### 2.1 Référentiel Couleurs Officiel (basé sur la homepage validée)

```dart
// lib/core/constants/app_colors.dart — VERSION FINALE OFFICIELLE
// Ces couleurs sont extraites de la homepage validée.
// NE PAS dévier de ces valeurs dans les pages auth.

class AppColors {

  // ── COULEURS PRIMAIRES ──────────────────────────────────────
  static const Color primary       = Color(0xFF1A56DB); // Bleu principal (boutons, liens, focus)
  static const Color primaryDark   = Color(0xFF1E3A8A); // Bleu foncé (gradient)
  static const Color primaryDeep   = Color(0xFF0F172A); // Bleu très sombre (footer, gradient)
  static const Color primaryLight  = Color(0xFF3B82F6); // Bleu clair (hover states)
  static const Color accent        = Color(0xFF0EA5E9); // Cyan accent (gradient secondaire)

  // ── COULEURS TEXTE ──────────────────────────────────────────
  static const Color textDark      = Color(0xFF0F172A); // Titres principaux
  static const Color textMedium    = Color(0xFF334155); // Texte nav, corps principal
  static const Color textLight     = Color(0xFF64748B); // Sous-titres, labels secondaires
  static const Color textHint      = Color(0xFF94A3B8); // Hints, placeholders
  static const Color textDisabled  = Color(0xFFCBD5E1); // Texte désactivé

  // ── COULEURS FOND ───────────────────────────────────────────
  static const Color bgWhite       = Color(0xFFFFFFFF); // Fond principal
  static const Color bgLight       = Color(0xFFF8FAFC); // Fond sections alternées
  static const Color bgSection     = Color(0xFFF1F5F9); // Fond sections secondaires
  static const Color bgDark        = Color(0xFF0F172A); // Fond footer
  static const Color bgFooter      = Color(0xFF1E293B); // Fond footer alternatif

  // ── COULEURS BORDURES ───────────────────────────────────────
  static const Color border        = Color(0xFFE2E8F0); // Bordure standard
  static const Color borderLight   = Color(0xFFF1F5F9); // Bordure très légère
  static const Color borderFocus   = Color(0xFF1A56DB); // Bordure au focus (inputs)

  // ── COULEURS SÉMANTIQUES ────────────────────────────────────
  static const Color success       = Color(0xFF10B981); // Vert succès
  static const Color successBg     = Color(0xFFD1FAE5); // Fond vert clair
  static const Color successDark   = Color(0xFF065F46); // Texte vert foncé
  static const Color warning       = Color(0xFFF59E0B); // Orange avertissement
  static const Color warningBg     = Color(0xFFFEF3C7); // Fond orange clair
  static const Color error         = Color(0xFFEF4444); // Rouge erreur
  static const Color errorBg       = Color(0xFFFEE2E2); // Fond rouge clair
  static const Color info          = Color(0xFF1A56DB); // Bleu info

  // ── COULEURS ICÔNES CARDS ───────────────────────────────────
  // Card Candidat (bleu clair)
  static const Color candidatIconBg  = Color(0xFFEFF6FF); // Fond icône candidat
  static const Color candidatIcon    = Color(0xFF1A56DB); // Icône candidat
  // Card Recruteur (vert)
  static const Color recruteurIconBg = Color(0xFFECFDF5); // Fond icône recruteur
  static const Color recruteurIcon   = Color(0xFF10B981); // Icône recruteur

  // ── GRADIENTS ───────────────────────────────────────────────
  // Gradient panneau gauche auth (identique au footer)
  static const List<Color> authPanelGradient = [
    Color(0xFF0F172A),
    Color(0xFF1E3A8A),
    Color(0xFF1A56DB),
  ];
  static const List<double> authPanelStops = [0.0, 0.55, 1.0];

  // Gradient hero (identique à la homepage)
  static const List<Color> heroGradient = [
    Color(0xCC0F172A),  // overlay gauche plus sombre
    Color(0x660F172A),  // overlay droit plus clair
  ];

  // ── OMBRES ──────────────────────────────────────────────────
  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x06000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static List<BoxShadow> cardShadowHover = [
    BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 40, offset: Offset(0, 16)),
  ];
  static List<BoxShadow> navbarShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 2)),
  ];
}
```

### 2.2 Référentiel Typographie Officiel

```dart
// lib/core/constants/app_text_styles.dart — VERSION FINALE

class AppTextStyles {

  // ── TITRES HOMEPAGE (référence visuelle) ────────────────────
  static TextStyle heroTitle = GoogleFonts.poppins(
    fontSize: 54, fontWeight: FontWeight.w800,
    color: Colors.white, height: 1.15,
    letterSpacing: -0.5,
  );
  static TextStyle sectionTitle = GoogleFonts.poppins(
    fontSize: 34, fontWeight: FontWeight.w700,
    color: AppColors.textDark, height: 1.2,
  );
  static TextStyle sectionSubtitle = GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textLight, height: 1.6,
  );

  // ── TITRES AUTH (cohérents avec homepage) ───────────────────
  static TextStyle authTitle = GoogleFonts.poppins(
    fontSize: 30, fontWeight: FontWeight.w700,
    color: AppColors.textDark, height: 1.25,
  );
  static TextStyle authSubtitle = GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: AppColors.textLight, height: 1.5,
  );
  static TextStyle authPanelTitle = GoogleFonts.poppins(
    fontSize: 26, fontWeight: FontWeight.w700,
    color: Colors.white, height: 1.3,
  );
  static TextStyle authPanelBody = GoogleFonts.inter(
    fontSize: 14, color: Color(0xCCFFFFFF), height: 1.65,
  );

  // ── FORMULAIRES ─────────────────────────────────────────────
  static TextStyle inputLabel = GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w500,
    color: Color(0xFF374151),
  );
  static TextStyle inputText = GoogleFonts.inter(
    fontSize: 15, color: AppColors.textDark,
  );
  static TextStyle inputHint = GoogleFonts.inter(
    fontSize: 14, color: AppColors.textDisabled,
  );
  static TextStyle inputError = GoogleFonts.inter(
    fontSize: 12, color: AppColors.error,
  );
  static TextStyle linkText = GoogleFonts.inter(
    fontSize: 14, color: AppColors.primary,
    fontWeight: FontWeight.w600,
  );
  static TextStyle buttonLabel = GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // ── FOOTER ──────────────────────────────────────────────────
  static TextStyle footerTitle = GoogleFonts.poppins(
    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white,
  );
  static TextStyle footerLink = GoogleFonts.inter(
    fontSize: 14, color: Color(0x99FFFFFF),
  );
  static TextStyle copyright = GoogleFonts.inter(
    fontSize: 13, color: Color(0x66FFFFFF),
  );
}
```

### 2.3 Référentiel Espacements & Dimensions

```dart
// lib/core/constants/app_dimensions.dart

class AppDimensions {

  // ── BORDER RADIUS ───────────────────────────────────────────
  static const double radiusInput    = 10.0;  // Inputs auth
  static const double radiusButton   = 10.0;  // Boutons principaux
  static const double radiusCard     = 12.0;  // Cards homepage & auth
  static const double radiusCardLg   = 16.0;  // Cards images, photos
  static const double radiusBadge    = 100.0; // Badges et pills
  static const double radiusIcon     = 8.0;   // Containers icônes

  // ── HAUTEURS BOUTONS ────────────────────────────────────────
  static const double btnHeightLg    = 52.0;  // Bouton submit auth (pleine largeur)
  static const double btnHeightMd    = 46.0;  // Boutons standards
  static const double btnHeightSm    = 38.0;  // Petits boutons

  // ── PADDING INPUTS ──────────────────────────────────────────
  static const EdgeInsets inputPadding =
    EdgeInsets.symmetric(horizontal: 16, vertical: 15);

  // ── ESPACEMENTS SECTIONS ────────────────────────────────────
  static const double sectionPaddingV  = 80.0; // Padding vertical des sections
  static const double sectionPaddingH  = 80.0; // Padding horizontal desktop
  static const double sectionPaddingHm = 24.0; // Padding horizontal mobile

  // ── PANEL AUTH ──────────────────────────────────────────────
  static const double authPanelPaddingH  = 52.0; // Padding horizontal formulaire desktop
  static const double authPanelPaddingHm = 24.0; // Padding horizontal formulaire mobile
  static const double mobileHeaderHeight = 200.0; // Hauteur du MobileAuthHeader

  // ── NAVBAR ──────────────────────────────────────────────────
  static const double navbarHeight = 70.0;
}
```

---

## PARTIE 3 — PAGES AUTH PREMIUM (Mise à jour complète)

### 3.1 AuthTextField — Version Définitive avec Animations

```dart
// lib/screens/auth/widgets/auth_text_field.dart
// VERSION DÉFINITIVE — remplace tout ce qui existait avant

class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;
  final bool enabled;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
    this.onChanged,
    this.enabled = true,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: _isFocused
              ? [BoxShadow(
                  color: const Color(0xFF1A56DB).withOpacity(0.12),
                  blurRadius: 0,
                  spreadRadius: 3,
                  offset: Offset.zero,
                )]
              : [],
        ),
        child: TextFormField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: widget.onChanged,
          enabled: widget.enabled,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFFCBD5E1),
            ),
            filled: true,
            fillColor: _isFocused
                ? Colors.white
                : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 15,
            ),
            prefixIcon: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                widget.prefixIcon,
                size: 20,
                color: _isFocused
                    ? const Color(0xFF1A56DB)
                    : const Color(0xFF94A3B8),
              ),
            ),
            suffixIcon: widget.suffixIcon,

            // Bordures — 4 états
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1A56DB), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2.0),
            ),

            // Style du message d'erreur
            errorStyle: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFFEF4444),
            ),
            errorMaxLines: 2,
          ),
        ),
      ),
    );
  }
}
```

### 3.2 AuthSubmitButton — Avec Effet Hover et Loading Premium

```dart
// lib/screens/auth/widgets/auth_submit_button.dart

class AuthSubmitButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isLoading;
  final VoidCallback? onPressed;
  final Color? backgroundColor;

  const AuthSubmitButton({
    super.key,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.onPressed,
    this.backgroundColor,
  });

  @override
  State<AuthSubmitButton> createState() => _AuthSubmitButtonState();
}

class _AuthSubmitButtonState extends State<AuthSubmitButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit:  (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isHovered
                ? [const Color(0xFF1E40AF), const Color(0xFF1A56DB)]
                : [const Color(0xFF1A56DB), const Color(0xFF1A56DB)],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: _isHovered && !widget.isLoading
              ? [BoxShadow(
                  color: const Color(0xFF1A56DB).withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )]
              : [],
        ),
        child: ElevatedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
            disabledBackgroundColor: Colors.transparent,
          ),
          child: widget.isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 18, color: Colors.white),
                      const SizedBox(width: 10),
                    ],
                    Text(widget.label, style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: Colors.white,
                    )),
                  ],
                ),
        ),
      ),
    );
  }
}
```

### 3.3 LeftIllustrationPanel — Version Définitive

```dart
// lib/screens/auth/widgets/left_illustration_panel.dart

class LeftIllustrationPanel extends StatelessWidget {
  final String imageUrl;
  final String? quote;
  final String? authorName;
  final String? authorRole;
  final String? authorInitial;
  final List<Map<String, String>>? stats;
  final Widget? customContent;

  const LeftIllustrationPanel({
    super.key,
    required this.imageUrl,
    this.quote,
    this.authorName,
    this.authorRole,
    this.authorInitial,
    this.stats,
    this.customContent,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInLeft(
      duration: const Duration(milliseconds: 700),
      child: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E3A8A),
              Color(0xFF1A56DB),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [

            // ── Cercles décoratifs ────────────────────────────
            Positioned(top: -80, right: -80, child: _decorCircle(320, 0.07)),
            Positioned(bottom: 80, left: -60, child: _decorCircle(220, 0.05)),
            Positioned(bottom: -40, right: 60, child: _decorCircle(140, 0.09)),

            // ── Contenu principal ────────────────────────────
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(44, 40, 44, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Logo blanc
                    _whiteLogo(),
                    const SizedBox(height: 44),

                    // Photo immersive
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        height: 240,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 240,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(child: CircularProgressIndicator(
                            color: Colors.white54, strokeWidth: 2)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 240,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.image_outlined,
                            color: Colors.white24, size: 48),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Contenu custom OU témoignage
                    if (customContent != null)
                      customContent!
                    else if (quote != null)
                      _quoteCard(),

                    // Stats (si fournies)
                    if (stats != null) ...[
                      const SizedBox(height: 32),
                      _statsRow(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorCircle(double size, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(opacity),
    ),
  );

  Widget _whiteLogo() => Row(children: [
    Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: const Icon(Icons.work_outline, color: Colors.white, size: 20),
    ),
    const SizedBox(width: 10),
    Text('EmploiConnect', style: GoogleFonts.poppins(
      fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
    )),
  ]);

  Widget _quoteCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.12)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.format_quote_rounded, color: Colors.white38, size: 28),
      const SizedBox(height: 8),
      Text(quote!, style: GoogleFonts.inter(
        color: Colors.white.withOpacity(0.85),
        fontSize: 14, height: 1.65,
      )),
      const SizedBox(height: 14),
      Row(children: [
        CircleAvatar(
          radius: 18, backgroundColor: const Color(0xFF1A56DB),
          child: Text(
            authorInitial ?? (authorName?.substring(0, 1) ?? 'A'),
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(authorName ?? '', style: GoogleFonts.inter(
            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600,
          )),
          Text(authorRole ?? '', style: GoogleFonts.inter(
            color: Colors.white60, fontSize: 11,
          )),
        ]),
      ]),
    ]),
  );

  Widget _statsRow() => Row(
    children: stats!.map((s) => Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s['value']!, style: GoogleFonts.poppins(
          fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white,
        )),
        Text(s['label']!, style: GoogleFonts.inter(
          fontSize: 11, color: Colors.white60,
        )),
      ]),
    )).toList(),
  );
}
```

### 3.4 MobileAuthHeader — Version Définitive

```dart
// lib/screens/auth/widgets/mobile_auth_header.dart

class MobileAuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const MobileAuthHeader({
    super.key, required this.title, required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF1A56DB)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(children: [
        // Cercle décoratif
        Positioned(right: -50, top: -50, child: Container(
          width: 200, height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.06),
          ),
        )),
        Positioned(left: -30, bottom: -30, child: Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.04),
          ),
        )),
        // Contenu
        Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Icon(Icons.work_outline, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Text('EmploiConnect', style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
              )),
            ]),
            const SizedBox(height: 14),
            Text(title, style: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white,
            )),
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.inter(
              fontSize: 13, color: Colors.white.withOpacity(0.75),
            )),
          ],
        )),
      ]),
    );
  }
}
```

---

## PARTIE 4 — ANIMATIONS COHÉRENTES

### 4.1 Durées Standard (à appliquer PARTOUT)

```dart
// lib/core/constants/app_animations.dart

class AppAnimations {
  // Durées
  static const Duration fast    = Duration(milliseconds: 200); // hover, focus
  static const Duration normal  = Duration(milliseconds: 350); // transitions page
  static const Duration medium  = Duration(milliseconds: 500); // apparitions
  static const Duration slow    = Duration(milliseconds: 700); // entrées panel
  static const Duration slower  = Duration(milliseconds: 900); // hero

  // Courbes
  static const Curve standard  = Curves.easeOut;
  static const Curve enter     = Curves.easeOut;
  static const Curve exit      = Curves.easeIn;
  static const Curve bounce    = Curves.elasticOut;
  static const Curve smooth    = Curves.easeInOut;

  // Délais stagger (pour listes de cartes)
  static Duration stagger(int index) =>
      Duration(milliseconds: 80 * index);
}
```

### 4.2 Animations d'Entrée par Page

```dart
// LOGIN SCREEN
// Panneau gauche  : FadeInLeft(700ms, delay: 0ms)
// Panneau droit   : FadeInRight(700ms, delay: 150ms)
// Titre           : FadeInDown(500ms, delay: 200ms)
// Champ email     : FadeInUp(500ms, delay: 250ms)
// Champ mdp       : FadeInUp(500ms, delay: 300ms)
// Options         : FadeInUp(500ms, delay: 350ms)
// Bouton submit   : FadeInUp(500ms, delay: 400ms)
// Cards signup    : FadeInUp(500ms, delay: 500ms)

// REGISTER SCREEN
// Panneau gauche  : FadeInLeft(700ms)
// En-tête form    : FadeInDown(500ms, delay: 150ms)
// Barre progress  : FadeInUp(400ms, delay: 200ms)
// Champs (step 1) : stagger FadeInUp (delay: 80ms entre chaque)
// Boutons nav     : FadeInUp(400ms, delay: 350ms)

// FORGOT PASSWORD
// Icône centrale  : ZoomIn(600ms, delay: 200ms)
// Titre           : FadeInDown(500ms, delay: 300ms)
// Champ           : FadeInUp(500ms, delay: 400ms)
// Bouton          : FadeInUp(500ms, delay: 500ms)

// ÉTAT SUCCÈS (toutes pages)
// Container       : FadeInUp(600ms)
// Icône           : ElasticIn(800ms) — effet rebond
// Texte titre     : FadeInUp(500ms, delay: 200ms)
// Texte corps     : FadeInUp(500ms, delay: 300ms)
// Boutons         : FadeInUp(500ms, delay: 400ms)
```

### 4.3 Règles d'Animations — À Respecter Absolument

```
✅ FAIRE :
  - Toujours FadeIn + Slide combinés (jamais l'un sans l'autre)
  - Stagger de 80ms entre éléments d'une même liste
  - AnimatedContainer pour les changements de couleur (inputs, boutons)
  - AnimatedSwitcher pour les changements de contenu (étapes stepper)
  - Transition de page : Fade 350ms (GoRouter CustomTransitionPage)

❌ NE PAS FAIRE :
  - Animations > 900ms (trop lent)
  - Bounces sur les formulaires (trop ludique, pas professionnel)
  - Plusieurs animations simultanées sans délai
  - Animations sur les messages d'erreur (doit apparaître immédiatement)
  - Scale > 1.05 sur hover (trop agressif)
```

---

## PARTIE 5 — CHECKLIST COHÉRENCE FINALE

### 5.1 Vérification Couleurs — Contrôle Point par Point

```
Pages Auth vs Homepage — Doit être IDENTIQUE :

┌─────────────────────────────┬──────────────┬─────────────────┐
│ Élément                     │ Homepage     │ Pages Auth      │
├─────────────────────────────┼──────────────┼─────────────────┤
│ Bouton principal (bg)       │ #1A56DB ✓    │ #1A56DB ← vér. │
│ Bouton principal (text)     │ blanc ✓      │ blanc ← vér.    │
│ Bouton outline (border)     │ #1A56DB ✓    │ #1A56DB ← vér. │
│ Bouton outline (text)       │ #1A56DB ✓    │ #1A56DB ← vér. │
│ Lien cliquable              │ #1A56DB ✓    │ #1A56DB ← vér. │
│ Icône card candidat (bg)    │ #EFF6FF ✓    │ #EFF6FF ← vér. │
│ Icône card candidat         │ #1A56DB ✓    │ #1A56DB ← vér. │
│ Icône card recruteur (bg)   │ #ECFDF5 ✓    │ #ECFDF5 ← vér. │
│ Icône card recruteur        │ #10B981 ✓    │ #10B981 ← vér. │
│ Font titres                 │ Poppins w700 │ Poppins w700    │
│ Font corps                  │ Inter        │ Inter           │
│ Gradient sombre             │ #0F172A base │ #0F172A base    │
│ Gradient bleu foncé         │ #1E3A8A mid  │ #1E3A8A mid     │
│ Gradient bleu               │ #1A56DB end  │ #1A56DB end     │
│ Fond section alternée       │ #F8FAFC ✓    │ N/A             │
│ Texte secondaire            │ #64748B ✓    │ #64748B ← vér. │
│ Bordure input               │ N/A          │ #E2E8F0         │
│ Focus input                 │ N/A          │ #1A56DB         │
└─────────────────────────────┴──────────────┴─────────────────┘
```

### 5.2 Instructions Finales pour Cursor

```
ORDRE D'IMPLÉMENTATION RECOMMANDÉ :

1. Mettre à jour app_colors.dart avec les valeurs de la Partie 2.1
2. Mettre à jour app_text_styles.dart avec la Partie 2.2
3. Créer app_dimensions.dart et app_animations.dart
4. Appliquer les corrections homepage (Partie 1)
5. Recréer AuthTextField avec la version Partie 3.1
6. Recréer AuthSubmitButton avec la version Partie 3.2
7. Recréer LeftIllustrationPanel avec la version Partie 3.3
8. Recréer MobileAuthHeader avec la version Partie 3.4
9. Appliquer les animations sur LoginScreen (Partie 4.2)
10. Appliquer les animations sur RegisterCandidatScreen
11. Appliquer les animations sur ForgotPasswordScreen
12. Vérifier la checklist Partie 5.1 point par point

RÉSULTAT ATTENDU :
→ Homepage et pages auth visuellement identiques en termes de style
→ Mêmes couleurs, mêmes fonts, mêmes border-radius, mêmes ombres
→ Transitions fluides entre la homepage et les pages auth
→ Utilisateur ne remarque aucune rupture visuelle en naviguant
```

---

*PATCH v1.3 — EmploiConnect Auth — Cohérence Visuelle*
*À appliquer après PRD_AUTH_v2.md*
*BARRY YOUSSOUF · DIALLO ISMAILA — Guinée 2025-2026*
