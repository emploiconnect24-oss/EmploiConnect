import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/admin_provider.dart';
import '../../../services/admin_service.dart';

const _kSectionMeta = <String, String>{
  'dashboard': 'Tableau de bord',
  'utilisateurs': 'Utilisateurs',
  'offres': 'Offres',
  'entreprises': 'Entreprises',
  'candidatures': 'Candidatures',
  'signalements': 'Signalements',
  'temoignages': 'Témoignages',
  'parcours': 'Parcours carrière',
  'statistiques': 'Statistiques',
  'recherche': 'Recherche globale',
  'messages': 'Notifications / messages',
  'bannieres': 'Bannières',
  'newsletter': 'Newsletter',
  'newsletter_envoi': 'Envoi newsletter',
  'illustrations': 'Illustrations IA',
  'apropos': 'Page À propos',
};

Color _hexColor(String? hex) {
  var h = (hex ?? '#1A56DB').replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  return Color(int.tryParse(h, radix: 16) ?? 0xFF1A56DB);
}

class SousAdminsPage extends StatefulWidget {
  const SousAdminsPage({super.key});

  @override
  State<SousAdminsPage> createState() => _SousAdminsPageState();
}

class _SousAdminsPageState extends State<SousAdminsPage> with SingleTickerProviderStateMixin {
  final _service = AdminService();
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _roles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final admins = await _service.getSousAdmins();
      final roles = await _service.getAdminRoles();
      if (mounted) {
        setState(() {
          _admins = admins;
          _roles = roles;
          _loading = false;
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

  Future<void> _dialogCreer() async {
    final nomCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final mdpCtrl = TextEditingController();
    final rolesAssignable =
        _roles.where((r) => (r['nom']?.toString() ?? '') != 'Super Admin').toList();
    String? roleId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Nouveau compte admin', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomCtrl,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: mdpCtrl,
                  decoration: const InputDecoration(labelText: 'Mot de passe (8+ car.)'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Rôle'),
                  value: roleId, // ignore: deprecated_member_use
                  items: rolesAssignable
                      .map(
                        (r) => DropdownMenuItem<String>(
                          value: r['id']?.toString(),
                          child: Text(r['nom']?.toString() ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setLocal(() => roleId = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;
    try {
      await _service.postSousAdmin(
        nom: nomCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        motDePasse: mdpCtrl.text,
        roleId: roleId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compte créé')));
      await _load();
      if (!mounted) return;
      await context.read<AdminProvider>().loadAdminAccess(force: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _dialogModifier(Map<String, dynamic> admin) async {
    final nomCtrl = TextEditingController(text: admin['nom']?.toString() ?? '');
    final mdpCtrl = TextEditingController();
    String? roleId = (admin['role'] is Map) ? (admin['role'] as Map)['id']?.toString() : null;
    var actif = admin['est_actif'] != false;
    final rolesAssignable =
        _roles.where((r) => (r['nom']?.toString() ?? '') != 'Super Admin').toList();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Modifier le compte', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomCtrl,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Compte actif'),
                  value: actif,
                  onChanged: (v) => setLocal(() => actif = v),
                ),
                TextField(
                  controller: mdpCtrl,
                  decoration: const InputDecoration(labelText: 'Nouveau mot de passe (optionnel)'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Rôle'),
                  value: roleId, // ignore: deprecated_member_use
                  items: rolesAssignable
                      .map(
                        (r) => DropdownMenuItem<String>(
                          value: r['id']?.toString(),
                          child: Text(r['nom']?.toString() ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setLocal(() => roleId = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;
    try {
      await _service.putSousAdmin(
        admin['id'].toString(),
        nom: nomCtrl.text.trim(),
        roleId: roleId,
        estActif: actif,
        nouveauMdp: mdpCtrl.text.isEmpty ? null : mdpCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mis à jour')));
      await _load();
      if (!mounted) return;
      await context.read<AdminProvider>().loadAdminAccess(force: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _desactiver(Map<String, dynamic> admin) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Désactiver ce compte ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _service.deleteSousAdmin(admin['id'].toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compte désactivé')));
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _sauverRole(Map<String, dynamic> role, Map<String, Map<String, bool>> perms) async {
    final id = role['id']?.toString();
    if (id == null) return;
    final rows = perms.entries
        .map(
          (e) => {
            'section': e.key,
            'peut_voir': e.value['peut_voir'] ?? false,
            'peut_modifier': e.value['peut_modifier'] ?? false,
            'peut_supprimer': e.value['peut_supprimer'] ?? false,
          },
        )
        .toList();
    try {
      await _service.putRolePermissions(id, rows);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissions enregistrées')));
      await _load();
      if (!mounted) return;
      await context.read<AdminProvider>().loadAdminAccess(force: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gestion des accès admin',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Comptes limités et rôles personnalisables',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _loading ? null : _dialogCreer,
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: const Text('Nouveau compte'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1A56DB),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                TabBar(
                  controller: _tabCtrl,
                  labelColor: const Color(0xFF1A56DB),
                  unselectedLabelColor: const Color(0xFF94A3B8),
                  indicatorColor: const Color(0xFF1A56DB),
                  tabs: const [
                    Tab(text: 'Comptes admins'),
                    Tab(text: 'Rôles & permissions'),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444))),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A56DB)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _admins.length,
                        itemBuilder: (ctx, i) {
                          final a = _admins[i];
                          final role = a['role'] is Map ? Map<String, dynamic>.from(a['role'] as Map) : null;
                          final superA = a['est_super_admin'] == true;
                          final actif = a['est_actif'] != false;
                          final nom = a['nom']?.toString() ?? '';
                          final email = a['email']?.toString() ?? '';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _hexColor(role?['couleur']?.toString()).withValues(alpha: 0.15),
                                child: Text(
                                  nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: superA ? const Color(0xFFEF4444) : const Color(0xFF1A56DB),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(child: Text(nom, style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                                  if (superA)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                      child: Text(
                                        'Super Admin',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(email, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                                  if (role != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        role['nom']?.toString() ?? '',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _hexColor(role['couleur']?.toString()),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: superA
                                  ? Chip(
                                      label: Text(actif ? 'Actif' : 'Off', style: const TextStyle(fontSize: 11)),
                                    )
                                  : PopupMenuButton<String>(
                                      onSelected: (v) {
                                        if (v == 'edit') _dialogModifier(a);
                                        if (v == 'off') _desactiver(a);
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(value: 'edit', child: Text('Modifier')),
                                        PopupMenuItem(value: 'off', child: Text('Désactiver')),
                                      ],
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
              _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A56DB)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _roles.length,
                        itemBuilder: (ctx, i) {
                          final role = _roles[i];
                          final nom = role['nom']?.toString() ?? '';
                          final isSuper = nom == 'Super Admin';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              title: Text(nom, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                role['description']?.toString() ?? '',
                                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                              ),
                              children: [
                                if (isSuper)
                                  const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text('Permissions gérées automatiquement (tout accès).'),
                                  )
                                else
                                  _RolePermEditor(
                                    role: role,
                                    onSave: (p) => _sauverRole(role, p),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RolePermEditor extends StatefulWidget {
  const _RolePermEditor({
    required this.role,
    required this.onSave,
  });

  final Map<String, dynamic> role;
  final Future<void> Function(Map<String, Map<String, bool>> perms) onSave;

  @override
  State<_RolePermEditor> createState() => _RolePermEditorState();
}

class _RolePermEditorState extends State<_RolePermEditor> {
  late Map<String, Map<String, bool>> _perms;

  @override
  void initState() {
    super.initState();
    _perms = {};
    final raw = widget.role['permissions'];
    if (raw is List) {
      for (final p in raw) {
        if (p is! Map) continue;
        final sec = p['section']?.toString();
        if (sec == null || sec.isEmpty) continue;
        _perms[sec] = {
          'peut_voir': p['peut_voir'] == true,
          'peut_modifier': p['peut_modifier'] == true,
          'peut_supprimer': p['peut_supprimer'] == true,
        };
      }
    }
    for (final sec in _kSectionMeta.keys) {
      _perms.putIfAbsent(
        sec,
        () => {'peut_voir': false, 'peut_modifier': false, 'peut_supprimer': false},
      );
    }
  }

  void _toggle(String sec, String key) {
    setState(() {
      final m = _perms.putIfAbsent(
        sec,
        () => {'peut_voir': false, 'peut_modifier': false, 'peut_supprimer': false},
      );
      m[key] = !(m[key] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget row(String sec) {
      final label = _kSectionMeta[sec] ?? sec;
      final m = _perms[sec]!;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 13))),
            Checkbox(
              value: m['peut_voir'] ?? false,
              onChanged: (_) => _toggle(sec, 'peut_voir'),
            ),
            Checkbox(
              value: m['peut_modifier'] ?? false,
              onChanged: (_) => _toggle(sec, 'peut_modifier'),
            ),
            Checkbox(
              value: m['peut_supprimer'] ?? false,
              onChanged: (_) => _toggle(sec, 'peut_supprimer'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: Row(
            children: [
              const Expanded(child: SizedBox()),
              SizedBox(
                width: 48,
                child: Text('Voir', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10)),
              ),
              SizedBox(
                width: 48,
                child: Text('Mod.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10)),
              ),
              SizedBox(
                width: 48,
                child: Text('Supp.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10)),
              ),
            ],
          ),
        ),
        ..._kSectionMeta.keys.map(row),
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: () async {
              await widget.onSave(_perms);
            },
            child: const Text('Enregistrer ce rôle'),
          ),
        ),
      ],
    );
  }
}
