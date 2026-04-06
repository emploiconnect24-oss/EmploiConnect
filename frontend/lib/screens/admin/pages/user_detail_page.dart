import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/admin_service.dart';

/// Détail utilisateur admin (données `/admin/utilisateurs/:id`).
class UserDetailPage extends StatefulWidget {
  const UserDetailPage({super.key, required this.userId});

  final String userId;

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  final AdminService _svc = AdminService();
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final res = await _svc.getUtilisateur(widget.userId);
      final raw = res['data'];
      setState(() {
        _user = raw is Map ? Map<String, dynamic>.from(raw) : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _chercheurMap() {
    final u = _user;
    if (u == null) return {};
    final ce = u['chercheurs_emploi'];
    if (ce is List && ce.isNotEmpty) {
      return Map<String, dynamic>.from(ce.first as Map);
    }
    if (ce is Map) return Map<String, dynamic>.from(ce);
    return {};
  }

  Map<String, dynamic> _entrepriseMap() {
    final u = _user;
    if (u == null) return {};
    final e = u['entreprises'];
    if (e is List && e.isNotEmpty) {
      return Map<String, dynamic>.from(e.first as Map);
    }
    if (e is Map) return Map<String, dynamic>.from(e);
    return {};
  }

  List<String> _competencesList(Map<String, dynamic> c) {
    final comp = c['competences'];
    if (comp is List) {
      return comp.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    if (comp is String && comp.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(comp);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        return [comp];
      }
    }
    return [];
  }

  List<Map<String, dynamic>> _mapList(dynamic raw) {
    if (raw is! List) return [];
    final out = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is Map) out.add(Map<String, dynamic>.from(e));
    }
    return out;
  }

  String _offreTitreFromCandidature(Map<String, dynamic> c) {
    final o = c['offres_emploi'];
    if (o is Map) return o['titre']?.toString() ?? 'Offre supprimée';
    return 'Offre supprimée';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _loadUser, child: const Text('Réessayer')),
              ],
            ),
          ),
        ),
      );
    }
    if (_user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: Text('Utilisateur non trouvé')),
      );
    }

    final role = _user!['role'] as String? ?? '';
    final nom = _user!['nom']?.toString() ?? '';
    final email = _user!['email']?.toString() ?? '';
    final photo = _user!['photo_url']?.toString();
    final tel = _user!['telephone']?.toString() ?? '';
    final ville = _user!['adresse']?.toString() ?? '';
    final actif = _user!['est_actif'] == true;
    final valide = _user!['est_valide'] == true;
    final roleColor = _roleAccent(role);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroBanner(
              context,
              roleColor: roleColor,
              photo: photo,
              nom: nom,
              bannerUrl: role == 'entreprise'
                  ? _entrepriseMap()['banniere_url']?.toString()
                  : null,
              brandLogoUrl: role == 'entreprise'
                  ? _entrepriseMap()['logo_url']?.toString()
                  : null,
              brandName: role == 'entreprise'
                  ? (_entrepriseMap()['nom_entreprise']?.toString() ?? '')
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
              child: LayoutBuilder(
                builder: (context, c) {
                  final wide = c.maxWidth >= 900;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nom.isEmpty ? '—' : nom,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _RoleBadge(role),
                          _AccountStatusBadge(actif: actif, valide: valide),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _buildUserInfoGrid(
                        email: email,
                        tel: tel,
                        ville: ville,
                        dateC: _user!['date_creation']?.toString(),
                        dateCo: _user!['derniere_connexion']?.toString(),
                        valide: valide,
                      ),
                      if (_user!['raison_blocage'] != null &&
                          (_user!['raison_blocage'] as String)
                              .toString()
                              .isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.block_outlined,
                                  color: Color(0xFFEF4444), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Motif de blocage : ${_user!['raison_blocage']}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF991B1B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _buildActionsCard(),
                      const SizedBox(height: 20),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildRightColumn(role)),
                          ],
                        )
                      else
                        _buildRightColumn(role),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _roleAccent(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFF8B5CF6);
      case 'entreprise':
        return const Color(0xFF1A56DB);
      default:
        return const Color(0xFF10B981);
    }
  }

  Widget _entrepriseLogoFallback({
    required Color roleColor,
    required String name,
  }) {
    return Container(
      width: 80,
      height: 80,
      color: const Color(0xFFEFF6FF),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: roleColor,
        ),
      ),
    );
  }

  Widget _buildHeroBanner(
    BuildContext context, {
    required Color roleColor,
    required String? photo,
    required String nom,
    String? bannerUrl,
    String? brandLogoUrl,
    String? brandName,
  }) {
    final b = bannerUrl?.trim();
    final hasBanner = b != null && b.isNotEmpty;
    final logo = brandLogoUrl?.trim();
    final hasBrandLogo = logo != null && logo.isNotEmpty;
    final initialName = (brandName != null && brandName.trim().isNotEmpty)
        ? brandName.trim()
        : nom;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 180,
          decoration: hasBanner
              ? BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(b),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.35),
                      BlendMode.darken,
                    ),
                  ),
                )
              : BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      roleColor,
                      roleColor.withValues(alpha: 0.65),
                    ],
                  ),
                ),
          padding: const EdgeInsets.fromLTRB(4, 8, 8, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topRight,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_user!['est_valide'] == false)
                          _HeroActionChip(
                            icon: Icons.check_circle_outline,
                            label: 'Valider',
                            onTap: () => _doAction('valider'),
                          ),
                        if (_user!['est_actif'] == false &&
                            _user!['est_valide'] == true) ...[
                          const SizedBox(width: 6),
                          _HeroActionChip(
                            icon: Icons.lock_open_rounded,
                            label: 'Activer',
                            onTap: () => _doAction('debloquer'),
                          ),
                        ],
                        if (_user!['est_actif'] == true &&
                            _user!['est_valide'] == true) ...[
                          const SizedBox(width: 6),
                          _HeroActionChip(
                            icon: Icons.block_rounded,
                            label: 'Bloquer',
                            onTap: _showBloquerDialog,
                          ),
                        ],
                        const SizedBox(width: 6),
                        _HeroActionChip(
                          icon: Icons.delete_outline_rounded,
                          label: 'Supprimer',
                          subtle: true,
                          onTap: _confirmDelete,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 28,
          bottom: -40,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: hasBrandLogo ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: hasBrandLogo ? BorderRadius.circular(12) : null,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x20000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: hasBrandLogo
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      logo,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _entrepriseLogoFallback(
                        roleColor: roleColor,
                        name: initialName,
                      ),
                    ),
                  )
                : CircleAvatar(
                    radius: 44,
                    backgroundColor: roleColor.withValues(alpha: 0.12),
                    backgroundImage: photo != null && photo.isNotEmpty
                        ? NetworkImage(photo)
                        : null,
                    child: photo == null || photo.isEmpty
                        ? Text(
                            initialName.isNotEmpty
                                ? initialName[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: roleColor,
                            ),
                          )
                        : null,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoGrid({
    required String email,
    required String tel,
    required String ville,
    required String? dateC,
    required String? dateCo,
    required bool valide,
  }) {
    final items = <_InfoTileData>[
      _InfoTileData(Icons.email_outlined, 'Email', email.isEmpty ? '—' : email),
      _InfoTileData(
        Icons.phone_outlined,
        'Téléphone',
        tel.isEmpty ? '—' : tel,
      ),
      _InfoTileData(
        Icons.location_on_outlined,
        'Ville / adresse',
        ville.isEmpty ? '—' : ville,
      ),
      _InfoTileData(
        Icons.calendar_today_outlined,
        'Inscrit le',
        _formatDate(dateC),
      ),
      _InfoTileData(
        Icons.access_time_rounded,
        'Dernière connexion',
        dateCo != null && dateCo.isNotEmpty ? _formatDate(dateCo) : 'Jamais',
      ),
      _InfoTileData(
        Icons.verified_outlined,
        'Compte validé',
        valide ? 'Oui' : 'Non',
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final n = c.maxWidth > 720 ? 3 : 2;
        return GridView.count(
          crossAxisCount: n,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: c.maxWidth / n / 78,
          children: items
              .map(
                (e) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(e.icon, size: 14, color: const Color(0xFF94A3B8)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              e.label,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF94A3B8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.value,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildRightColumn(String role) {
    return Column(
      children: [
        if (role == 'chercheur') ...[
          _buildChercheurInfoCard(),
          const SizedBox(height: 16),
          _buildCandidaturesCard(),
        ],
        if (role == 'entreprise') ...[
          _buildEntrepriseInfoCard(),
          const SizedBox(height: 16),
          _buildOffresCard(),
        ],
        if (role == 'admin') _buildAdminInfoCard(),
      ],
    );
  }

  Widget _buildActionsCard() => _AdminCard(
        title: 'Actions',
        child: Column(
          children: [
            if (_user!['est_valide'] == false)
              _ActionBtn(
                'Valider le compte',
                Icons.check_circle_outline,
                const Color(0xFF10B981),
                () => _doAction('valider'),
              ),
            if (_user!['est_actif'] == true && _user!['est_valide'] == true)
              _ActionBtn(
                'Bloquer le compte',
                Icons.block_outlined,
                const Color(0xFFF59E0B),
                _showBloquerDialog,
              ),
            if (_user!['est_actif'] == false && _user!['est_valide'] == true)
              _ActionBtn(
                'Débloquer le compte',
                Icons.lock_open_outlined,
                const Color(0xFF10B981),
                () => _doAction('debloquer'),
              ),
            const SizedBox(height: 8),
            _ActionBtn(
              'Supprimer le compte',
              Icons.delete_outline,
              const Color(0xFFEF4444),
              _confirmDelete,
              isDanger: true,
            ),
          ],
        ),
      );

  Widget _buildChercheurInfoCard() {
    final c = _chercheurMap();
    final skills = _competencesList(c);
    return _AdminCard(
      title: 'Profil Candidat',
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          _ProfileChip(
            Icons.school_outlined,
            'Études',
            c['niveau_etude']?.toString().isNotEmpty == true
                ? c['niveau_etude'].toString()
                : 'Non précisé',
          ),
          _ProfileChip(
            Icons.schedule_outlined,
            'Disponibilité',
            c['disponibilite']?.toString().isNotEmpty == true
                ? c['disponibilite'].toString()
                : 'Non précisé',
          ),
          _ProfileChip(
            Icons.person_outlined,
            'Genre',
            c['genre']?.toString().isNotEmpty == true
                ? c['genre'].toString()
                : 'Non précisé',
          ),
          ...skills.take(6).map(
                (skill) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    skill,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF1E40AF),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildCandidaturesCard() {
    final cands = _mapList(_user!['candidatures']);
    return _AdminCard(
      title: 'Candidatures (${cands.length})',
      child: cands.isEmpty
          ? Text(
              'Aucune candidature',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF94A3B8),
              ),
            )
          : Column(
              children: cands.take(5).map((c) {
                final statut = c['statut']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _statutColor(statut),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _offreTitreFromCandidature(c),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF334155),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _StatutTextBadge(label: statut),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildEntrepriseInfoCard() {
    final e = _entrepriseMap();
    return _AdminCard(
      title: 'Profil Entreprise',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            e['nom_entreprise']?.toString() ?? '—',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          if (e['secteur_activite'] != null &&
              e['secteur_activite'].toString().trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                e['secteur_activite'].toString(),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          const SizedBox(height: 12),
          _InfoRow(
            Icons.business_outlined,
            e['taille_entreprise']?.toString().isNotEmpty == true
                ? e['taille_entreprise'].toString()
                : 'Taille non précisée',
          ),
          if (e['site_web'] != null &&
              e['site_web'].toString().trim().isNotEmpty)
            _InfoRow(Icons.language_outlined, e['site_web'].toString()),
          if (e['description'] != null &&
              e['description'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              e['description'].toString(),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOffresCard() {
    final offres = _mapList(_user!['offres']);
    return _AdminCard(
      title: 'Offres publiées (${offres.length})',
      child: offres.isEmpty
          ? Text(
              'Aucune offre publiée',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF94A3B8),
              ),
            )
          : Column(
              children: offres.take(5).map((o) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          o['titre']?.toString() ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF334155),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatutTextBadge(label: o['statut']?.toString() ?? ''),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildAdminInfoCard() => _AdminCard(
        title: 'Compte administrateur',
        child: Text(
          'Ce compte dispose des droits d’administration sur la plateforme.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF64748B),
            height: 1.5,
          ),
        ),
      );

  String _formatDate(String? d) {
    if (d == null || d.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(d).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return 'N/A';
    }
  }

  Color _statutColor(String? s) {
    switch (s) {
      case 'acceptee':
        return const Color(0xFF10B981);
      case 'refusee':
        return const Color(0xFFEF4444);
      case 'entretien':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF1A56DB);
    }
  }

  Future<void> _doAction(String action, {String? raison}) async {
    try {
      await _svc.patchUtilisateur(
        widget.userId,
        action: action,
        raison: raison,
      );
      if (!mounted) return;
      await _loadUser();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _showBloquerDialog() {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Bloquer ce compte',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextFormField(
          controller: ctrl,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'Raison du blocage...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              elevation: 0,
            ),
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(dialogContext);
              await _doAction('bloquer', raison: ctrl.text.trim());
            },
            child: Text(
              'Bloquer',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Supprimer ce compte ?',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Action irréversible. Toutes les données seront perdues.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _svc.deleteUtilisateur(widget.userId);
                if (!mounted) return;
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: const Color(0xFFEF4444),
                  ),
                );
              }
            },
            child: Text(
              'Supprimer',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTileData {
  const _InfoTileData(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
}

class _HeroActionChip extends StatelessWidget {
  const _HeroActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtle = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: subtle
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: subtle ? 0.25 : 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 14),
            ],
            child,
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn(
    this.label,
    this.icon,
    this.color,
    this.onTap, {
    this.isDanger = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: Icon(icon, size: 16, color: color),
            label: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: color,
                fontWeight: isDanger ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: color.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: onTap,
          ),
        ),
      );
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge(this.role);

  final String role;

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color text;
    switch (role) {
      case 'chercheur':
        bg = const Color(0xFFEFF6FF);
        text = const Color(0xFF1E40AF);
        break;
      case 'entreprise':
        bg = const Color(0xFFECFDF5);
        text = const Color(0xFF065F46);
        break;
      default:
        bg = const Color(0xFF0F172A);
        text = Colors.white;
    }
    final label = role == 'chercheur'
        ? 'Chercheur'
        : role == 'entreprise'
            ? 'Entreprise'
            : role == 'admin'
                ? 'Admin'
                : role;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}

class _AccountStatusBadge extends StatelessWidget {
  const _AccountStatusBadge({required this.actif, required this.valide});

  final bool actif;
  final bool valide;

  @override
  Widget build(BuildContext context) {
    late String label;
    late Color bg;
    late Color text;
    if (!valide) {
      label = 'En attente';
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFF92400E);
    } else if (!actif) {
      label = 'Bloqué';
      bg = const Color(0xFFFEE2E2);
      text = const Color(0xFF991B1B);
    } else {
      label = 'Actif';
      bg = const Color(0xFFD1FAE5);
      text = const Color(0xFF065F46);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}

class _StatutTextBadge extends StatelessWidget {
  const _StatutTextBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }
}
