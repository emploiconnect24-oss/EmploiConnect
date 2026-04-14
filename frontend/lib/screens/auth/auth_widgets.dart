// Composants partagés — PRD_AUTH_PAGES.md §4
// Emplacement : lib/screens/auth/auth_widgets.dart
// Import depuis login/register : import 'auth/auth_widgets.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../core/theme/theme_extension.dart';

// ── Logo Header (logo depuis GET /api/config/general) ───

class AuthLogoHeader extends StatefulWidget {
  const AuthLogoHeader({super.key, this.couleurTexte = const Color(0xFF0F172A)});

  final Color couleurTexte;

  @override
  State<AuthLogoHeader> createState() => _AuthLogoHeaderState();
}

class _AuthLogoHeaderState extends State<AuthLogoHeader> {
  String? _logoUrl;
  String _nomPlateforme = 'EmploiConnect';

  @override
  void initState() {
    super.initState();
    _loadBranding();
  }

  Future<void> _loadBranding() async {
    try {
      final uri = Uri.parse('$apiBaseUrl$apiPrefix/config/general');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200 || !mounted) return;
      final body = jsonDecode(res.body);
      if (body is! Map<String, dynamic>) return;
      final data = body['data'];
      final map = data is Map<String, dynamic>
          ? Map<String, dynamic>.from(data)
          : body;
      final url = (map['logo_url'] ?? map['site_logo'] ?? map['logo'])?.toString().trim();
      final nom = map['nom_plateforme']?.toString().trim();
      if (!mounted) return;
      setState(() {
        if (url != null && url.isNotEmpty) _logoUrl = url;
        if (nom != null && nom.isNotEmpty) _nomPlateforme = nom;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/landing',
        (route) => false,
      );
    },
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: _logoUrl == null
                ? const LinearGradient(
                    colors: [Color(0xFF1A56DB), Color(0xFF7C3AED)],
                  )
                : null,
            color: _logoUrl != null ? Theme.of(context).colorScheme.surface : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A56DB).withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _logoUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _logoUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => _fallbackE(),
                  ),
                )
              : _fallbackE(),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _nomPlateforme,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: widget.couleurTexte,
              ),
            ),
            Text(
              'Plateforme emploi · Guinée',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: widget.couleurTexte.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _fallbackE() => Center(
    child: Text(
      'E',
      style: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Colors.white,
      ),
    ),
  );
}

// ── Bouton Google ────────────────────────────────────────

class AuthBoutonGoogle extends StatelessWidget {
  const AuthBoutonGoogle({
    super.key,
    required this.label,
    required this.isLoading,
    this.onTap,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: ext.cardBorder),
          backgroundColor: cs.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        onPressed: isLoading ? null : onTap,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF4285F4),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        'G',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4285F4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Bouton principal ─────────────────────────────────────

class AuthBoutonPrincipal extends StatelessWidget {
  const AuthBoutonPrincipal({
    super.key,
    required this.label,
    required this.isLoading,
    this.onTap,
    this.couleur = const Color(0xFF1A56DB),
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onTap;
  final Color couleur;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: couleur,
        foregroundColor: Colors.white,
        elevation: 0,
        disabledBackgroundColor: const Color(0xFFCBD5E1),
        disabledForegroundColor: Colors.white70,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: isLoading ? null : onTap,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
    ),
  );
}

// ── Champ formulaire générique ───────────────────────────

class AuthChampFormulaire extends StatelessWidget {
  const AuthChampFormulaire({
    super.key,
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icone,
    this.obscure = false,
    this.suffixIcon,
    this.keyType,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
  });

  final TextEditingController ctrl;
  final String label;
  final String hint;
  final IconData icone;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType? keyType;
  final int maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyType,
          maxLines: obscure ? 1 : maxLines,
          validator: validator,
          onChanged: onChanged,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: cs.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: cs.onSurfaceVariant.withValues(alpha: 0.85),
            ),
            prefixIcon: Icon(icone, size: 18, color: cs.onSurfaceVariant),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: ext.inputFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: ext.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: ext.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Champ email ──────────────────────────────────────────

class AuthChampEmail extends StatelessWidget {
  const AuthChampEmail({super.key, required this.ctrl});

  final TextEditingController ctrl;

  @override
  Widget build(BuildContext context) => AuthChampFormulaire(
    ctrl: ctrl,
    label: 'Adresse email *',
    hint: 'votre@email.com',
    icone: Icons.email_outlined,
    keyType: TextInputType.emailAddress,
    validator: (v) {
      if (v == null || v.trim().isEmpty) return 'Email requis';
      final email = v.trim();
      final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
      if (!ok) return 'Email invalide';
      return null;
    },
  );
}

// ── Champ mot de passe ───────────────────────────────────

class AuthChampMotDePasse extends StatelessWidget {
  const AuthChampMotDePasse({
    super.key,
    required this.ctrl,
    this.label = 'Mot de passe *',
    required this.visible,
    required this.onToggle,
    this.validator,
    this.onChanged,
  });

  final TextEditingController ctrl;
  final String label;
  final bool visible;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) => AuthChampFormulaire(
    ctrl: ctrl,
    label: label,
    hint: '••••••••',
    icone: Icons.lock_outline_rounded,
    obscure: !visible,
    onChanged: onChanged,
    suffixIcon: IconButton(
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 18,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onPressed: onToggle,
    ),
    validator:
        validator ??
        (v) {
          if (v == null || v.length < 8) {
            return 'Minimum 8 caractères';
          }
          return null;
        },
  );
}

// ── Séparateur ───────────────────────────────────────────

class AuthSeparateur extends StatelessWidget {
  const AuthSeparateur({super.key, required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) {
    final ext = context.themeExt;
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(child: Divider(color: ext.cardBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            texte,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Divider(color: ext.cardBorder)),
      ],
    );
  }
}

// ── Carte erreur ─────────────────────────────────────────

class AuthCarteErreur extends StatelessWidget {
  const AuthCarteErreur({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    final msgColor = context.isDark ? const Color(0xFFFECACA) : const Color(0xFF991B1B);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ext.errorBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: cs.error.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: cs.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: msgColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carte rôle ───────────────────────────────────────────

class AuthCarteRole extends StatelessWidget {
  const AuthCarteRole({
    super.key,
    required this.emoji,
    required this.titre,
    required this.desc,
    required this.couleur,
    required this.isSelected,
    required this.onTap,
  });

  final String emoji;
  final String titre;
  final String desc;
  final Color couleur;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.themeExt;
    return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? couleur.withValues(alpha: 0.08) : cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? couleur : ext.cardBorder,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: couleur.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 10),
          Text(
            titre,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? couleur : cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (isSelected) ...[
            const SizedBox(height: 8),
            Icon(Icons.check_circle_rounded, color: couleur, size: 20),
          ],
        ],
      ),
    ),
  );
  }
}

// ── Force du mot de passe ────────────────────────────────

class AuthForceMotDePasse extends StatelessWidget {
  const AuthForceMotDePasse({super.key, required this.mdp});

  final String mdp;

  int get _score {
    if (mdp.isEmpty) return 0;
    var s = 0;
    if (mdp.length >= 8) s++;
    if (mdp.length >= 12) s++;
    if (RegExp('[A-Z]').hasMatch(mdp)) s++;
    if (RegExp('[0-9]').hasMatch(mdp)) s++;
    if (RegExp(r'[!@#$%]').hasMatch(mdp)) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    if (mdp.isEmpty) return const SizedBox(height: 4);
    final score = _score;
    const couleurs = <Color>[
      Color(0xFFEF4444),
      Color(0xFFF59E0B),
      Color(0xFFF59E0B),
      Color(0xFF10B981),
      Color(0xFF10B981),
    ];
    const labels = ['Très faible', 'Faible', 'Moyen', 'Fort', 'Très fort'];
    final i = score.clamp(0, 4);
    final couleur = couleurs[i];

    final track = context.themeExt.cardBorder;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(
              5,
              (j) => Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    color: j < score ? couleur : track,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          labels[i],
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: couleur,
          ),
        ),
      ],
    );
  }
}
