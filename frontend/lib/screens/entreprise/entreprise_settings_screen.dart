import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/users_service.dart';
import '../../shared/widgets/theme_selector_tile.dart';
import '../../widgets/responsive_container.dart';
import '../../widgets/reveal_on_scroll.dart';

class EntrepriseSettingsScreen extends StatefulWidget {
  const EntrepriseSettingsScreen({super.key, this.onOpenEntrepriseProfile});

  /// Navigation vers l’écran « Profil entreprise » (ex. shell recruteur).
  final VoidCallback? onOpenEntrepriseProfile;

  @override
  State<EntrepriseSettingsScreen> createState() => _EntrepriseSettingsScreenState();
}

class _EntrepriseSettingsScreenState extends State<EntrepriseSettingsScreen> {
  final _service = UsersService();
  final _formKey = GlobalKey<FormState>();
  final _securityKey = GlobalKey<FormState>();

  final _nomEntrepriseCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _secteurCtrl = TextEditingController();
  final _tailleCtrl = TextEditingController();
  final _siteCtrl = TextEditingController();
  final _adresseSiegeCtrl = TextEditingController();
  final _logoUrlCtrl = TextEditingController();

  final _pwdCtrl = TextEditingController();
  final _pwdConfirmCtrl = TextEditingController();
  final _deleteConfirmCtrl = TextEditingController();
  bool _obscurePwd = true;
  bool _obscureConfirm = true;
  String _language = 'Français';
  String _timezone = 'Africa/Conakry';

  bool _notifNewApplications = true;
  bool _notifMessages = true;
  bool _notifOfferExpiry = true;
  bool _notifWeeklySummary = false;
  bool _notifPush = true;

  bool _privacyProfileVisible = true;
  bool _privacyShowSalaryByDefault = true;
  bool _privacyAllowDirectContact = true;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nomEntrepriseCtrl.dispose();
    _descriptionCtrl.dispose();
    _secteurCtrl.dispose();
    _tailleCtrl.dispose();
    _siteCtrl.dispose();
    _adresseSiegeCtrl.dispose();
    _logoUrlCtrl.dispose();
    _pwdCtrl.dispose();
    _pwdConfirmCtrl.dispose();
    _deleteConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _service.getMe();
      final user = r.user;
      final profil = r.profil ?? <String, dynamic>{};
      _nomEntrepriseCtrl.text = profil['nom_entreprise']?.toString() ?? '';
      _descriptionCtrl.text = profil['description']?.toString() ?? '';
      _secteurCtrl.text = profil['secteur_activite']?.toString() ?? '';
      _tailleCtrl.text = profil['taille_entreprise']?.toString() ?? '';
      _siteCtrl.text = profil['site_web']?.toString() ?? '';
      _adresseSiegeCtrl.text = profil['adresse_siege']?.toString() ?? '';
      _logoUrlCtrl.text = profil['logo_url']?.toString() ?? '';
      _language = user['langue_interface']?.toString() ?? 'Français';
      _timezone = user['fuseau_horaire']?.toString() ?? 'Africa/Conakry';
      _notifNewApplications = user['notif_nouvelles_candidatures'] as bool? ?? true;
      _notifMessages = user['notif_messages_recus'] as bool? ?? true;
      _notifOfferExpiry = user['notif_offres_expiration'] as bool? ?? true;
      _notifWeeklySummary = user['notif_resume_hebdo'] as bool? ?? false;
      _notifPush = user['notif_push'] as bool? ?? true;
      _privacyProfileVisible = user['privacy_profile_visible'] as bool? ?? true;
      _privacyShowSalaryByDefault = user['privacy_show_salary_default'] as bool? ?? true;
      _privacyAllowDirectContact = user['privacy_allow_direct_contact'] as bool? ?? true;
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _service.updateMe({
        'langue_interface': _language,
        'fuseau_horaire': _timezone,
        'notif_nouvelles_candidatures': _notifNewApplications,
        'notif_messages_recus': _notifMessages,
        'notif_offres_expiration': _notifOfferExpiry,
        'notif_resume_hebdo': _notifWeeklySummary,
        'notif_push': _notifPush,
        'privacy_profile_visible': _privacyProfileVisible,
        'privacy_show_salary_default': _privacyShowSalaryByDefault,
        'privacy_allow_direct_contact': _privacyAllowDirectContact,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Préférences enregistrées')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openDangerDialog({required bool delete}) async {
    _deleteConfirmCtrl.clear();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(delete ? 'Supprimer définitivement le compte ?' : 'Désactiver temporairement le compte ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              delete
                  ? 'Cette action est irréversible. Tapez SUPPRIMER pour confirmer.'
                  : 'Votre compte sera temporairement désactivé.',
            ),
            if (delete) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _deleteConfirmCtrl,
                decoration: const InputDecoration(labelText: 'Tapez SUPPRIMER'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: delete ? const Color(0xFFDC2626) : const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (delete && _deleteConfirmCtrl.text.trim() != 'SUPPRIMER') {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Confirmation invalide')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: Text(delete ? 'Supprimer' : 'Désactiver'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    try {
      if (delete) {
        await _service.deleteMe();
      } else {
        await _service.deactivateMe();
      }
      if (!mounted) return;
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(delete ? 'Compte supprimé' : 'Compte désactivé')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveEntreprise() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await _service.updateMe({
        'nom_entreprise': _nomEntrepriseCtrl.text.trim().isEmpty ? null : _nomEntrepriseCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
        'secteur_activite': _secteurCtrl.text.trim().isEmpty ? null : _secteurCtrl.text.trim(),
        'taille_entreprise': _tailleCtrl.text.trim().isEmpty ? null : _tailleCtrl.text.trim(),
        'site_web': _siteCtrl.text.trim().isEmpty ? null : _siteCtrl.text.trim(),
        'adresse_siege': _adresseSiegeCtrl.text.trim().isEmpty ? null : _adresseSiegeCtrl.text.trim(),
        'logo_url': _logoUrlCtrl.text.trim().isEmpty ? null : _logoUrlCtrl.text.trim(),
      });
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paramètres entreprise mis à jour')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    if (_saving) return;
    if (!(_securityKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await _service.updateMe({
        'mot_de_passe': _pwdCtrl.text,
      });
      if (!mounted) return;
      _pwdCtrl.clear();
      _pwdConfirmCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe mis à jour')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user ?? const <String, dynamic>{};
    final email = user['email']?.toString() ?? '—';
    final role = user['role']?.toString() ?? '—';

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            FilledButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;

    return ResponsiveContainer(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Text(
              'Paramètres',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Gérez les informations de votre entreprise et la sécurité du compte.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            RevealOnScroll(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Compte', style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      _ReadOnlyField(
                        icon: Icons.email_outlined,
                        label: 'Adresse email',
                        value: email,
                        note: 'Non modifiable',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.business_center_outlined, color: Color(0xFF94A3B8), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Rôle',
                                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                                  ),
                                  Text(
                                    role.toLowerCase().contains('recruteur') ? 'Recruteur / Entreprise' : role,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                'Vérifié ✓',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A56DB),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.onOpenEntrepriseProfile != null) ...[
                        const SizedBox(height: 12),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onOpenEntrepriseProfile,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF1A56DB).withValues(alpha: 0.06),
                                    const Color(0xFF0EA5E9).withValues(alpha: 0.03),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF1A56DB).withValues(alpha: 0.22)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.business_rounded, color: Color(0xFF1A56DB), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Gérer le profil de votre entreprise',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1A56DB),
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF1A56DB)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        'Astuce : configurez vos notifications et votre confidentialité pour mieux piloter vos recrutements.',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const ThemeSelectorTile(),
            const SizedBox(height: 12),
            // SECTION 1 : Infos compte
            RevealOnScroll(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('1) Informations du compte', style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: email,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Email du compte',
                            prefixIcon: Icon(Icons.mail_outline),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nomEntrepriseCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nom entreprise',
                            prefixIcon: Icon(Icons.apartment_outlined),
                            isDense: true,
                          ),
                          validator: (v) {
                            final s = (v ?? '').trim();
                            if (s.isEmpty) return null;
                            if (s.length > 200) return 'Max 200 caractères';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _secteurCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Secteur d’activité',
                            prefixIcon: Icon(Icons.category_outlined),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _tailleCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Taille entreprise',
                            prefixIcon: Icon(Icons.groups_outlined),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _language,
                          decoration: const InputDecoration(
                            labelText: 'Langue interface',
                            prefixIcon: Icon(Icons.translate),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Français', child: Text('Français')),
                            DropdownMenuItem(value: 'English', child: Text('English')),
                          ],
                          onChanged: (v) => setState(() => _language = v ?? 'Français'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _timezone,
                          decoration: const InputDecoration(
                            labelText: 'Fuseau horaire',
                            prefixIcon: Icon(Icons.schedule),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Africa/Conakry', child: Text('Africa/Conakry')),
                            DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                          ],
                          onChanged: (v) => setState(() => _timezone = v ?? 'Africa/Conakry'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _siteCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Site web',
                            prefixIcon: Icon(Icons.link),
                            isDense: true,
                          ),
                          validator: (v) {
                            final s = (v ?? '').trim();
                            if (s.isEmpty) return null;
                            final ok = Uri.tryParse(s);
                            if (ok == null || !(ok.hasScheme && ok.host.isNotEmpty)) {
                              return 'URL invalide (ex: https://entreprise.com)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _adresseSiegeCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Adresse siège',
                            prefixIcon: Icon(Icons.place_outlined),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _logoUrlCtrl,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Logo URL',
                            prefixIcon: Icon(Icons.image_outlined),
                            isDense: true,
                          ),
                          validator: (v) {
                            final s = (v ?? '').trim();
                            if (s.isEmpty) return null;
                            final ok = Uri.tryParse(s);
                            if (ok == null || !(ok.hasScheme && ok.host.isNotEmpty)) {
                              return 'URL invalide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            prefixIcon: Icon(Icons.subject_outlined),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _saving ? null : _load,
                                child: const Text('Réinitialiser'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _saving ? null : _saveEntreprise,
                                icon: _saving
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.check),
                                label: Text(_saving ? 'Enregistrement…' : 'Sauvegarder section'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // SECTION 2 : Préférences notifications
            RevealOnScroll(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('2) Préférences de notification', style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: _notifNewApplications,
                        onChanged: (v) => setState(() => _notifNewApplications = v),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Email : nouvelles candidatures'),
                      ),
                      SwitchListTile(
                        value: _notifMessages,
                        onChanged: (v) => setState(() => _notifMessages = v),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Email : messages reçus'),
                      ),
                      SwitchListTile(
                        value: _notifOfferExpiry,
                        onChanged: (v) => setState(() => _notifOfferExpiry = v),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Email : offre bientôt expirée'),
                      ),
                      SwitchListTile(
                        value: _notifWeeklySummary,
                        onChanged: (v) => setState(() => _notifWeeklySummary = v),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Email : résumé hebdomadaire'),
                      ),
                      SwitchListTile(
                        value: _notifPush,
                        onChanged: (v) => setState(() => _notifPush = v),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Push notifications'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // SECTION 3 : Confidentialité
            RevealOnScroll(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('3) Confidentialité', style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: _privacyProfileVisible,
                        onChanged: (v) => setState(() => _privacyProfileVisible = v),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Visibilité du profil entreprise'),
                      ),
                      SwitchListTile(
                        value: _privacyShowSalaryByDefault,
                        onChanged: (v) => setState(() => _privacyShowSalaryByDefault = v),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Afficher le salaire par défaut'),
                      ),
                      SwitchListTile(
                        value: _privacyAllowDirectContact,
                        onChanged: (v) => setState(() => _privacyAllowDirectContact = v),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Permettre le contact direct candidat'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // SECTION 4 : Facturation
            RevealOnScroll(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('4) Facturation (futur)', style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.workspace_premium_outlined),
                        title: Text('Plan actuel : Gratuit'),
                        subtitle: Text('Upgrade vers plan Pro disponible prochainement'),
                      ),
                      OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.upgrade),
                        label: const Text('Upgrade vers Pro (bientôt)'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Sécurité (mot de passe)
            RevealOnScroll(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Form(
                    key: _securityKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sécurité', style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pwdCtrl,
                          obscureText: _obscurePwd,
                          decoration: InputDecoration(
                            labelText: 'Nouveau mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline),
                            isDense: true,
                            suffixIcon: IconButton(
                              tooltip: _obscurePwd ? 'Afficher' : 'Masquer',
                              onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                              icon: Icon(_obscurePwd ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                          validator: (v) {
                            final s = (v ?? '');
                            if (s.isEmpty) return null; // pas obligatoire
                            if (s.length < 8) return 'Minimum 8 caractères';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pwdConfirmCtrl,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Confirmer le mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline),
                            isDense: true,
                            suffixIcon: IconButton(
                              tooltip: _obscureConfirm ? 'Afficher' : 'Masquer',
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                          validator: (v) {
                            final pwd = _pwdCtrl.text;
                            final confirm = (v ?? '');
                            if (pwd.isEmpty && confirm.isEmpty) return null;
                            if (pwd.isEmpty) return 'Entrez un mot de passe';
                            if (confirm.isEmpty) return 'Confirmez le mot de passe';
                            if (pwd != confirm) return 'Les mots de passe ne correspondent pas';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Laissez vide si vous ne voulez pas changer le mot de passe.',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _saving
                                ? null
                                : () {
                                    if (_pwdCtrl.text.isEmpty && _pwdConfirmCtrl.text.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Renseignez un nouveau mot de passe')),
                                      );
                                      return;
                                    }
                                    _changePassword();
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: scheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.security),
                            label: const Text('Mettre à jour'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // SECTION 5 : Danger zone
            RevealOnScroll(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('5) Danger Zone', style: TextStyle(fontWeight: FontWeight.w900, color: scheme.error)),
                      const SizedBox(height: 8),
                      const Text('Actions sensibles sur votre compte entreprise.'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _openDangerDialog(delete: false),
                            icon: const Icon(Icons.pause_circle_outline),
                            label: const Text('Désactiver temporairement'),
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _openDangerDialog(delete: true),
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Supprimer définitivement'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saving ? null : _savePreferences,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Enregistrer préférences'),
              ),
            ),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.icon,
    required this.label,
    required this.value,
    this.note,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF94A3B8), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          if (note != null)
            Text(
              note!,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}

