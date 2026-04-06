import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recruteur_provider.dart';
import '../../services/recruteur_service.dart';
import '../../services/users_service.dart';
import '../../shared/widgets/image_upload_widget.dart';
import '../../widgets/reveal_on_scroll.dart';

/// Profil entreprise — design soigné + tous les champs persistés via `/users/me`.
class EntrepriseProfileScreen extends StatefulWidget {
  const EntrepriseProfileScreen({super.key});

  @override
  State<EntrepriseProfileScreen> createState() => _EntrepriseProfileScreenState();
}

class _EntrepriseProfileScreenState extends State<EntrepriseProfileScreen> {
  static const _primary = Color(0xFF1A56DB);
  static const _surface = Color(0xFFF8FAFC);
  static const _border = Color(0xFFE2E8F0);

  final _users = UsersService();
  final _recruteur = RecruteurService();
  final _formKey = GlobalKey<FormState>();

  final _nomCtrl = TextEditingController();
  final _sloganCtrl = TextEditingController();
  final _secteurCtrl = TextEditingController();
  final _tailleCtrl = TextEditingController();
  final _anneeCtrl = TextEditingController();
  final _siteCtrl = TextEditingController();
  final _emailPublicCtrl = TextEditingController();
  final _telPublicCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  final _missionCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();
  final _banniereCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _twitterCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _hasUnsavedChanges = false;
  String? _error;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _profil;
  Map<String, dynamic> _stats = {};
  List<String> _values = [];
  Set<String> _benefits = {};

  static const _benefitsOptions = [
    'Assurance maladie',
    'Transport',
    'Logement',
    'Formation',
    'Bonus annuel',
    'Téléphone professionnel',
    'Repas',
    'Congés payés',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _sloganCtrl.dispose();
    _secteurCtrl.dispose();
    _tailleCtrl.dispose();
    _anneeCtrl.dispose();
    _siteCtrl.dispose();
    _emailPublicCtrl.dispose();
    _telPublicCtrl.dispose();
    _adresseCtrl.dispose();
    _aboutCtrl.dispose();
    _missionCtrl.dispose();
    _logoCtrl.dispose();
    _banniereCtrl.dispose();
    _linkedinCtrl.dispose();
    _facebookCtrl.dispose();
    _twitterCtrl.dispose();
    _instagramCtrl.dispose();
    _whatsappCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  InputDecoration _fieldDeco(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20, color: const Color(0xFF94A3B8)) : null,
      filled: true,
      fillColor: Colors.white,
      labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
      hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final me = await _users.getMe();
      Map<String, dynamic> stats = {};
      if (token.isNotEmpty) {
        try {
          final pr = await _recruteur.getProfil(token);
          if (pr['success'] == true) {
            stats = Map<String, dynamic>.from(pr['data']?['stats'] as Map? ?? {});
          }
        } catch (_) {}
      }

      _user = me.user;
      _profil = me.profil ?? <String, dynamic>{};
      _stats = stats;

      final p = _profil!;
      _nomCtrl.text = p['nom_entreprise']?.toString() ?? me.user['nom']?.toString() ?? '';
      _sloganCtrl.text = p['slogan']?.toString() ?? '';
      _secteurCtrl.text = p['secteur_activite']?.toString() ?? '';
      _tailleCtrl.text = p['taille_entreprise']?.toString() ?? '';
      _anneeCtrl.text = p['annee_fondation']?.toString() ?? '';
      _siteCtrl.text = p['site_web']?.toString() ?? '';
      _emailPublicCtrl.text = p['email_public']?.toString() ?? me.user['email']?.toString() ?? '';
      _telPublicCtrl.text = p['telephone_public']?.toString() ?? me.user['telephone']?.toString() ?? '';
      _adresseCtrl.text = p['adresse_siege']?.toString() ?? me.user['adresse']?.toString() ?? '';
      _aboutCtrl.text = p['description']?.toString() ?? '';
      _missionCtrl.text = p['mission']?.toString() ?? '';
      _logoCtrl.text = p['logo_url']?.toString() ?? '';
      _banniereCtrl.text = p['banniere_url']?.toString() ?? p['cover_url']?.toString() ?? '';
      _linkedinCtrl.text = p['linkedin']?.toString() ?? '';
      _facebookCtrl.text = p['facebook']?.toString() ?? '';
      _twitterCtrl.text = p['twitter']?.toString() ?? '';
      _instagramCtrl.text = p['instagram']?.toString() ?? '';
      _whatsappCtrl.text = p['whatsapp_business']?.toString() ?? '';
      _values = ((p['valeurs'] as List?) ?? const []).map((e) => e.toString()).toList();
      _benefits = (((p['avantages'] as List?) ?? const []).map((e) => e.toString())).toSet();

      if (mounted) {
        setState(() {
          _loading = false;
          _hasUnsavedChanges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    final recruteur = context.read<RecruteurProvider>();
    setState(() => _saving = true);
    try {
      await _users.updateMe({
        'nom': _nomCtrl.text.trim(),
        'telephone': _telPublicCtrl.text.trim().isEmpty ? null : _telPublicCtrl.text.trim(),
        'adresse': _adresseCtrl.text.trim().isEmpty ? null : _adresseCtrl.text.trim(),
        'nom_entreprise': _nomCtrl.text.trim(),
        'slogan': _sloganCtrl.text.trim().isEmpty ? null : _sloganCtrl.text.trim(),
        'secteur_activite': _secteurCtrl.text.trim().isEmpty ? null : _secteurCtrl.text.trim(),
        'taille_entreprise': _tailleCtrl.text.trim().isEmpty ? null : _tailleCtrl.text.trim(),
        'annee_fondation': _anneeCtrl.text.trim().isEmpty ? null : _anneeCtrl.text.trim(),
        'site_web': _siteCtrl.text.trim().isEmpty ? null : _siteCtrl.text.trim(),
        'email_public': _emailPublicCtrl.text.trim().isEmpty ? null : _emailPublicCtrl.text.trim(),
        'telephone_public': _telPublicCtrl.text.trim().isEmpty ? null : _telPublicCtrl.text.trim(),
        'adresse_siege': _adresseCtrl.text.trim().isEmpty ? null : _adresseCtrl.text.trim(),
        'description': _aboutCtrl.text.trim().isEmpty ? null : _aboutCtrl.text.trim(),
        'mission': _missionCtrl.text.trim().isEmpty ? null : _missionCtrl.text.trim(),
        'logo_url': _logoCtrl.text.trim().isEmpty ? null : _logoCtrl.text.trim(),
        'banniere_url': _banniereCtrl.text.trim().isEmpty ? null : _banniereCtrl.text.trim(),
        'linkedin': _linkedinCtrl.text.trim().isEmpty ? null : _linkedinCtrl.text.trim(),
        'facebook': _facebookCtrl.text.trim().isEmpty ? null : _facebookCtrl.text.trim(),
        'twitter': _twitterCtrl.text.trim().isEmpty ? null : _twitterCtrl.text.trim(),
        'instagram': _instagramCtrl.text.trim().isEmpty ? null : _instagramCtrl.text.trim(),
        'whatsapp_business': _whatsappCtrl.text.trim().isEmpty ? null : _whatsappCtrl.text.trim(),
        'valeurs': _values,
        'avantages': _benefits.toList(),
      });
      if (!mounted) return;
      await auth.loadSession();
      recruteur.updateProfil({
        'logo_url': _logoCtrl.text.trim(),
        'banniere_url': _banniereCtrl.text.trim(),
      });
      final token = auth.token ?? '';
      if (token.isNotEmpty) {
        await recruteur.refresh(token);
      }
      if (!mounted) return;
      setState(() => _hasUnsavedChanges = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: const Color(0xFF10B981),
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text('Profil enregistré', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int _n(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  /// Un seul `setState` au passage « propre » → « modifié », pour ne pas reconstruire
  /// tout le formulaire à chaque caractère (sinon perte de focus / curseur).
  void _markDirty() {
    if (_hasUnsavedChanges) return;
    if (mounted) setState(() => _hasUnsavedChanges = true);
  }

  void _showApercuPublic() {
    final ban = _banniereCtrl.text.trim();
    final lg = _logoCtrl.text.trim();
    final nom = _nomCtrl.text.trim().isEmpty ? 'Votre entreprise' : _nomCtrl.text.trim();
    final slogan = _sloganCtrl.text.trim();
    final about = _aboutCtrl.text.trim();
    final site = _siteCtrl.text.trim();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Aperçu public', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 2.8,
                    child: ban.isNotEmpty
                        ? Image.network(ban, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _previewBannerFallback())
                        : _previewBannerFallback(),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFFEFF6FF),
                      backgroundImage: lg.isNotEmpty ? NetworkImage(lg) : null,
                      child: lg.isEmpty
                          ? Text(
                              nom.isNotEmpty ? nom[0].toUpperCase() : 'E',
                              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: _primary),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nom, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                          if (slogan.isNotEmpty)
                            Text(slogan, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
                if (about.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text('À propos', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(about, style: GoogleFonts.inter(height: 1.4, color: const Color(0xFF334155)), maxLines: 12, overflow: TextOverflow.ellipsis),
                ],
                if (site.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.language_rounded, size: 18, color: _primary),
                      const SizedBox(width: 6),
                      Expanded(child: Text(site, style: GoogleFonts.inter(color: _primary, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Aperçu indicatif : les candidats voient une page dédiée selon les données publiées.',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
      ),
    );
  }

  Widget _previewBannerFallback() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)]),
      ),
      child: Icon(Icons.apartment_rounded, size: 48, color: Colors.white24),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
          ],
        ),
      );
    }

    final email = _user?['email']?.toString() ?? '—';
    final banniere = _banniereCtrl.text.trim().isEmpty ? null : _banniereCtrl.text.trim();
    final logo = _logoCtrl.text.trim().isEmpty ? null : _logoCtrl.text.trim();

    return ColoredBox(
      color: _surface,
      child: RefreshIndicator(
        color: _primary,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: banniere == null
                          ? const LinearGradient(
                              colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      image: banniere != null
                          ? DecorationImage(image: NetworkImage(banniere), fit: BoxFit.cover)
                          : null,
                    ),
                    child: banniere == null
                        ? Center(
                            child: Icon(Icons.apartment_rounded, size: 56, color: Colors.white.withValues(alpha: 0.35)),
                          )
                        : null,
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: -36,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFFEFF6FF),
                            backgroundImage: logo != null ? NetworkImage(logo) : null,
                            child: logo == null
                                ? Text(
                                    _nomCtrl.text.isNotEmpty ? _nomCtrl.text[0].toUpperCase() : 'E',
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: _primary,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 42),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Profil entreprise',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Informations visibles aux candidats et partenaires',
                                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: logo != null || _nomCtrl.text.isNotEmpty ? 52 : 48)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _StatPill(icon: Icons.work_outline, label: 'Offres', value: '${_n(_stats['nb_offres'])}'),
                      _StatPill(icon: Icons.people_outline, label: 'Candidatures', value: '${_n(_stats['nb_candidatures'])}'),
                      _StatPill(icon: Icons.mail_outline, label: 'Compte', value: email, compact: true),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionTitle(icon: Icons.palette_outlined, title: 'Identité visuelle', subtitle: 'Logo, bannière, nom'),
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ImageUploadWidget(
                                currentImageUrl: banniere,
                                uploadUrl: '$apiBaseUrl$apiPrefix/recruteur/profil/banniere',
                                fieldName: 'banniere',
                                title: 'Bannière',
                                dimensionsInfo: '1200 × 400 px recommandé',
                                acceptedFormats: 'JPG, PNG, WEBP',
                                maxSizeMb: 10,
                                previewHeight: 100,
                                onUploaded: (url) => setState(() {
                                  _banniereCtrl.text = url;
                                  _hasUnsavedChanges = true;
                                }),
                              ),
                              const SizedBox(height: 16),
                              ImageUploadWidget(
                                currentImageUrl: logo,
                                uploadUrl: '$apiBaseUrl$apiPrefix/recruteur/profil/logo',
                                fieldName: 'logo',
                                title: 'Logo',
                                dimensionsInfo: 'Carré, min. 200 px',
                                acceptedFormats: 'PNG, JPG, WEBP',
                                maxSizeMb: 5,
                                previewHeight: 88,
                                onUploaded: (url) => setState(() {
                                  _logoCtrl.text = url;
                                  _hasUnsavedChanges = true;
                                }),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _nomCtrl,
                                decoration: _fieldDeco('Nom de l\'entreprise *', icon: Icons.business),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                                onChanged: (_) => _markDirty(),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _sloganCtrl,
                                maxLength: 120,
                                decoration: _fieldDeco('Slogan / accroche', hint: 'Une phrase qui vous distingue', icon: Icons.format_quote),
                                onChanged: (_) => _markDirty(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionTitle(
                          icon: Icons.info_outline,
                          title: 'Informations générales',
                          subtitle: 'Secteur, contact public, localisation',
                        ),
                        _card(
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _secteurCtrl,
                                decoration: _fieldDeco('Secteur d\'activité', icon: Icons.category_outlined),
                                onChanged: (_) => _markDirty(),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _tailleCtrl,
                                decoration: _fieldDeco('Taille (ex. 10–50 employés)', icon: Icons.groups_outlined),
                                onChanged: (_) => _markDirty(),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _anneeCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _fieldDeco('Année de fondation', icon: Icons.calendar_today_outlined),
                                onChanged: (_) => _markDirty(),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _siteCtrl,
                                decoration: _fieldDeco('Site web', hint: 'https://...', icon: Icons.language),
                                onChanged: (_) => _markDirty(),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _emailPublicCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _fieldDeco('Email public', icon: Icons.alternate_email),
                                onChanged: (_) => _markDirty(),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _telPublicCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: _fieldDeco('Téléphone public', icon: Icons.phone_outlined),
                                onChanged: (_) => _markDirty(),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _adresseCtrl,
                                maxLines: 3,
                                decoration: _fieldDeco('Adresse du siège', icon: Icons.place_outlined),
                                onChanged: (_) => _markDirty(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionTitle(icon: Icons.auto_stories_outlined, title: 'Culture & marque employeur', subtitle: 'Description, mission, valeurs'),
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _aboutCtrl,
                                maxLines: 5,
                                decoration: _fieldDeco('À propos', hint: 'Histoire, activités, ambiance...', icon: Icons.article_outlined),
                                onChanged: (_) => _markDirty(),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _missionCtrl,
                                maxLines: 3,
                                decoration: _fieldDeco('Mission', icon: Icons.flag_outlined),
                                onChanged: (_) => _markDirty(),
                              ),
                              const SizedBox(height: 16),
                              Text('Valeurs (max. 5)', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _valueCtrl,
                                      decoration: _fieldDeco('Ajouter une valeur', icon: Icons.add_circle_outline),
                                      onFieldSubmitted: (_) => _addValue(),
                                      onChanged: (_) => _markDirty(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(onPressed: _addValue, child: const Text('Ajouter')),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _values
                                    .map(
                                      (v) => Chip(
                                        label: Text(v, style: GoogleFonts.inter(fontSize: 12)),
                                        onDeleted: () => setState(() {
                                          _values.remove(v);
                                          _hasUnsavedChanges = true;
                                        }),
                                        deleteIconColor: const Color(0xFFEF4444),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 16),
                              Text('Avantages proposés', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _benefitsOptions
                                    .map(
                                      (b) => FilterChip(
                                        label: Text(b, style: GoogleFonts.inter(fontSize: 12)),
                                        selected: _benefits.contains(b),
                                        onSelected: (v) => setState(() {
                                          v ? _benefits.add(b) : _benefits.remove(b);
                                          _hasUnsavedChanges = true;
                                        }),
                                        selectedColor: const Color(0xFFD1FAE5),
                                        checkmarkColor: const Color(0xFF065F46),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionTitle(icon: Icons.share_outlined, title: 'Réseaux sociaux', subtitle: 'Liens vers vos pages officielles'),
                        _card(
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _linkedinCtrl,
                                decoration: _fieldDeco('LinkedIn', icon: Icons.link),
                                onChanged: (_) => _markDirty(),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _facebookCtrl,
                                decoration: _fieldDeco('Facebook', icon: Icons.link),
                                onChanged: (_) => _markDirty(),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _twitterCtrl,
                                decoration: _fieldDeco('Twitter / X', icon: Icons.link),
                                onChanged: (_) => _markDirty(),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _instagramCtrl,
                                decoration: _fieldDeco('Instagram', icon: Icons.link),
                                onChanged: (_) => _markDirty(),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _whatsappCtrl,
                                decoration: _fieldDeco('WhatsApp Business', icon: Icons.chat),
                                onChanged: (_) => _markDirty(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListenableBuilder(
                          listenable: Listenable.merge([
                            _nomCtrl,
                            _sloganCtrl,
                            _secteurCtrl,
                            _tailleCtrl,
                          ]),
                          builder: (context, _) {
                            return RevealOnScroll(
                              child: _card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.visibility_outlined, color: _primary.withValues(alpha: 0.9)),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Aperçu',
                                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _nomCtrl.text.trim().isEmpty ? 'Nom entreprise' : _nomCtrl.text.trim(),
                                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                                    ),
                                    if (_sloganCtrl.text.trim().isNotEmpty)
                                      Text(
                                        _sloganCtrl.text.trim(),
                                        style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${_secteurCtrl.text.trim().isEmpty ? '—' : _secteurCtrl.text.trim()} · ${_tailleCtrl.text.trim().isEmpty ? '—' : _tailleCtrl.text.trim()}',
                                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _apercuPublicCta(),
                        if (_hasUnsavedChanges) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Modifications non enregistrées',
                            style: GoogleFonts.inter(color: Theme.of(context).colorScheme.error, fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _saving ? null : _load,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text('Réinitialiser', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: _saving ? null : _save,
                                style: FilledButton.styleFrom(
                                  backgroundColor: _primary,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.save_outlined, size: 20),
                                label: Text(
                                  _saving ? 'Enregistrement…' : 'Enregistrer',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addValue() {
    final v = _valueCtrl.text.trim();
    if (v.isEmpty || _values.length >= 5 || _values.contains(v)) return;
    setState(() {
      _values.add(v);
      _valueCtrl.clear();
      _hasUnsavedChanges = true;
    });
  }

  /// PRD §7 — CTA dégradé « Aperçu profil public » en bas du formulaire.
  Widget _apercuPublicCta() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFEFF6FF), Color(0xFFF0F9FF)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _showApercuPublic,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.preview_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aperçu du profil public',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Voir comment les candidats voient votre entreprise',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return RevealOnScroll(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF1A56DB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label, required this.value, this.compact = false});

  final IconData icon;
  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: compact ? 280 : 160),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1A56DB)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                Text(
                  value,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
