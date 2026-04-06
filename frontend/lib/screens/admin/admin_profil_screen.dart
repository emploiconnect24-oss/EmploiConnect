import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/responsive_container.dart';

/// Profil de l’administrateur connecté (API `/admin/profil`).
class AdminProfilScreen extends StatefulWidget {
  const AdminProfilScreen({super.key});

  @override
  State<AdminProfilScreen> createState() => _AdminProfilScreenState();
}

class _AdminProfilScreenState extends State<AdminProfilScreen> {
  final _svc = AdminService();
  Map<String, dynamic>? _profil;
  bool _loading = true;
  bool _saving = false;
  bool _isUploadingPhoto = false;
  bool _sendingEmailCode = false;
  bool _confirmingEmail = false;
  String? _error;
  /// Adresse pour laquelle un code a été envoyé (ne pas modifier sans annuler).
  String? _emailVerificationTarget;

  final _nomCtrl = TextEditingController();
  final _nouvelEmailCtrl = TextEditingController();
  final _codeEmailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _ancienMdpCtrl = TextEditingController();
  final _nvMdpCtrl = TextEditingController();
  final _confirmMdpCtrl = TextEditingController();

  static String _libelleNiveauAcces(String? raw) {
    final k = (raw ?? 'admin').toLowerCase().trim();
    switch (k) {
      case 'super_admin':
      case 'superadmin':
        return 'Super administrateur';
      case 'moderateur':
      case 'modérateur':
        // En base, la valeur par défaut historique « moderateur » = accès panneau admin complet.
        return 'Administrateur';
      case 'admin':
      default:
        return 'Administrateur';
    }
  }

  static String _sousTitreNiveau(String? raw) {
    final k = (raw ?? 'admin').toLowerCase().trim();
    if (k == 'super_admin' || k == 'superadmin') {
      return 'Tous les droits sur la plateforme';
    }
    return 'Accès complet au panneau d’administration';
  }

  String _formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) {
      return 'Pas encore enregistrée — sera mise à jour à votre prochaine connexion';
    }
    final d = DateTime.tryParse(iso);
    if (d == null) return '—';
    return DateFormat("dd/MM/yyyy 'à' HH:mm").format(d.toLocal());
  }

  String _formatDateCourt(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso);
    if (d == null) return '—';
    return DateFormat('dd/MM/yyyy').format(d.toLocal());
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _svc.getProfilAdmin();
      final data = res['data'];
      if (data is Map) {
        final m = Map<String, dynamic>.from(data);
        setState(() {
          _profil = m;
          _nomCtrl.text = m['nom']?.toString() ?? '';
          _telCtrl.text = m['telephone']?.toString() ?? '';
          _adresseCtrl.text = m['adresse']?.toString() ?? '';
          _emailVerificationTarget = null;
          _nouvelEmailCtrl.clear();
          _codeEmailCtrl.clear();
          _loading = false;
        });
        if (mounted) {
          context.read<AdminProvider>().syncProfilFromMap(m);
        }
      } else {
        setState(() {
          _error = 'Réponse invalide';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _mimeForExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_isUploadingPhoto) return;
    final picker = ImagePicker();
    XFile? file;
    try {
      file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Impossible d’ouvrir la galerie'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    if (file == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;

      var ext = 'jpg';
      final path = file.path;
      final dot = path.lastIndexOf('.');
      if (dot != -1 && dot < path.length - 1) {
        ext = path.substring(dot + 1).toLowerCase();
        if (ext == 'jpeg') ext = 'jpg';
      }

      var mime = _mimeForExtension(ext);
      final reported = file.mimeType;
      if (reported != null && reported.isNotEmpty) {
        final parts = reported.split('/');
        if (parts.length == 2) {
          mime = '${parts[0].toLowerCase()}/${parts[1].toLowerCase()}';
        }
      }

      final upRes = await _svc.uploadAdminPhoto(
        fileBytes: bytes,
        filename: 'photo.$ext',
        mimeType: mime,
      );
      final upData = upRes['data'];
      if (mounted &&
          upData is Map &&
          upData['photo_url'] != null &&
          upData['photo_url'].toString().trim().isNotEmpty) {
        context.read<AdminProvider>().updatePhoto(upData['photo_url'].toString());
      }
      await _load();
      if (mounted) await context.read<AuthProvider>().loadSession();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Photo mise à jour avec succès'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _saveProfil() async {
    setState(() => _saving = true);
    try {
      final res = await _svc.updateProfilAdmin(
        nom: _nomCtrl.text.trim(),
        telephone: _telCtrl.text.trim(),
        adresse: _adresseCtrl.text.trim(),
      );
      final data = res['data'];
      if (data is Map) {
        final m = Map<String, dynamic>.from(data);
        await AuthService().patchStoredUser({
          if (m['nom'] != null) 'nom': m['nom'],
        });
      }
      await _load();
      if (mounted) await context.read<AuthProvider>().loadSession();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profil mis à jour'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    if (_nvMdpCtrl.text != _confirmMdpCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
      );
      return;
    }
    try {
      await _svc.updateProfilAdmin(
        ancienMdp: _ancienMdpCtrl.text,
        nouveauMdp: _nvMdpCtrl.text,
      );
      _ancienMdpCtrl.clear();
      _nvMdpCtrl.clear();
      _confirmMdpCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Mot de passe modifié'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _envoyerCodeChangementEmail() async {
    final raw = _nouvelEmailCtrl.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indiquez la nouvelle adresse e-mail')),
      );
      return;
    }
    setState(() => _sendingEmailCode = true);
    try {
      await _svc.demandeChangementEmailAdmin(raw);
      if (!mounted) return;
      setState(() {
        _emailVerificationTarget = raw.toLowerCase();
        _nouvelEmailCtrl.text = raw;
        _codeEmailCtrl.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Code envoyé à $raw — valable 15 minutes'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingEmailCode = false);
    }
  }

  Future<void> _confirmerChangementEmail() async {
    final target = _emailVerificationTarget ?? _nouvelEmailCtrl.text.trim().toLowerCase();
    final code = _codeEmailCtrl.text.trim();
    if (target.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adresse e-mail manquante')),
      );
      return;
    }
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saisissez les 6 chiffres du code reçu par e-mail')),
      );
      return;
    }
    setState(() => _confirmingEmail = true);
    try {
      final res = await _svc.confirmerChangementEmailAdmin(nouvelEmail: target, code: code);
      final data = res['data'];
      if (data is Map) {
        final m = Map<String, dynamic>.from(data);
        await AuthService().patchStoredUser({
          if (m['email'] != null) 'email': m['email'],
          if (m['nom'] != null) 'nom': m['nom'],
        });
      }
      if (!mounted) return;
      setState(() {
        _emailVerificationTarget = null;
        _nouvelEmailCtrl.clear();
        _codeEmailCtrl.clear();
      });
      await _load();
      if (mounted) await context.read<AuthProvider>().loadSession();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Adresse e-mail mise à jour — connectez-vous avec la nouvelle adresse'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _confirmingEmail = false);
    }
  }

  void _annulerChangementEmail() {
    setState(() {
      _emailVerificationTarget = null;
      _nouvelEmailCtrl.clear();
      _codeEmailCtrl.clear();
    });
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _nouvelEmailCtrl.dispose();
    _codeEmailCtrl.dispose();
    _telCtrl.dispose();
    _adresseCtrl.dispose();
    _ancienMdpCtrl.dispose();
    _nvMdpCtrl.dispose();
    _confirmMdpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_loading) {
      return ResponsiveContainer(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: cs.primary),
              const SizedBox(height: 16),
              Text('Chargement du profil…', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }
    if (_error != null) {
      return ResponsiveContainer(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: cs.error),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
              FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    final admin = _profil?['admin'];
    final niveauRaw = admin is Map ? admin['niveau_acces']?.toString() : null;
    final niveauLibelle = _libelleNiveauAcces(niveauRaw);
    final niveauSousTitre = _sousTitreNiveau(niveauRaw);
    final photoUrl = _profil?['photo_url']?.toString();
    final nom = _profil?['nom']?.toString() ?? '';
    final derniere = _profil?['derniere_connexion']?.toString();

    return ResponsiveContainer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: LayoutBuilder(
          builder: (context, c) {
            final narrow = c.maxWidth < 900;
            final header = _buildHeader(context, nom, photoUrl, niveauLibelle, niveauSousTitre, _isUploadingPhoto);
            final quick = _buildQuickInfoCard(context, derniere, niveauLibelle, niveauSousTitre);
            final form = _buildInfosFormCard(context);
            final emailCard = _buildEmailChangeCard(context);
            final pwd = _buildPasswordCard(context);

            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: 20),
                  quick,
                  const SizedBox(height: 20),
                  form,
                  const SizedBox(height: 20),
                  emailCard,
                  const SizedBox(height: 20),
                  pwd,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 40,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      const SizedBox(height: 20),
                      quick,
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      form,
                      const SizedBox(height: 20),
                      emailCard,
                      const SizedBox(height: 20),
                      pwd,
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String nom,
    String? photoUrl,
    String niveauLibelle,
    String niveauSousTitre,
    bool uploading,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary,
              Color.lerp(cs.primary, cs.secondary, 0.35)!,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            children: [
              GestureDetector(
                onTap: uploading ? null : _pickAndUploadPhoto,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null || photoUrl.isEmpty
                            ? Text(
                                nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.w700),
                              )
                            : null,
                      ),
                    ),
                    if (uploading)
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        ),
                      ),
                    if (!uploading)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _pickAndUploadPhoto,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(Icons.photo_camera_rounded, size: 18, color: cs.primary),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                nom.isEmpty ? 'Administrateur' : nom,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  niveauLibelle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                niveauSousTitre,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email_outlined, size: 16, color: Colors.white.withValues(alpha: 0.85)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _profil?['email']?.toString() ?? '',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.95)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Membre depuis ${_formatDateCourt(_profil?['date_creation']?.toString())}',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.75)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickInfoCard(BuildContext context, String? derniereIso, String niveauLibelle, String niveauSousTitre) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_outlined, size: 22, color: cs.primary),
                const SizedBox(width: 10),
                Text(
                  'Aperçu du compte',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _quickTile(
              context,
              icon: Icons.history_rounded,
              iconBg: cs.primaryContainer,
              iconFg: cs.onPrimaryContainer,
              title: 'Dernière connexion',
              subtitle: _formatDateTime(derniereIso),
              multilineSubtitle: true,
            ),
            const SizedBox(height: 12),
            _quickTile(
              context,
              icon: Icons.verified_user_outlined,
              iconBg: cs.secondaryContainer,
              iconFg: cs.onSecondaryContainer,
              title: 'Niveau d’accès',
              subtitle: niveauLibelle,
              extra: niveauSousTitre,
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickTile(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconFg,
    required String title,
    required String subtitle,
    String? extra,
    bool multilineSubtitle = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: iconFg),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: multilineSubtitle ? 1.35 : null,
                  ),
                ),
                if (extra != null && extra.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    extra,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.85)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfosFormCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 22, color: cs.primary),
                const SizedBox(width: 10),
                Text(
                  'Informations personnelles',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Nom, téléphone et adresse postale. Pour l’e-mail de connexion, utilisez la section dédiée ci-dessous.',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _nomCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _telCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _adresseCtrl,
              maxLines: 3,
              minLines: 2,
              decoration: const InputDecoration(
                labelText: 'Adresse',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveProfil,
                icon: _saving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                      )
                    : const Icon(Icons.save_rounded, size: 20),
                label: Text(_saving ? 'Enregistrement…' : 'Enregistrer les modifications'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailChangeCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final actuel = _profil?['email']?.toString() ?? '';
    final codeEnvoye = _emailVerificationTarget != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mark_email_read_outlined, size: 22, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Adresse e-mail de connexion',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Un code à 6 chiffres est envoyé sur la nouvelle adresse pour confirmer que vous la contrôlez.',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 18, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Actuellement', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        SelectableText(actuel, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nouvelEmailCtrl,
              enabled: !codeEnvoye && !_sendingEmailCode,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: codeEnvoye ? 'Nouvelle adresse (verrouillée)' : 'Nouvelle adresse e-mail',
                prefixIcon: const Icon(Icons.forward_to_inbox_outlined),
                helperText: codeEnvoye ? 'Code envoyé à $_emailVerificationTarget' : null,
              ),
            ),
            if (codeEnvoye) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _codeEmailCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 8, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  labelText: 'Code reçu par e-mail',
                  counterText: '',
                  prefixIcon: Icon(Icons.pin_outlined),
                  hintText: '000000',
                ),
              ),
            ],
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (!codeEnvoye)
                  FilledButton.icon(
                    onPressed: _sendingEmailCode ? null : _envoyerCodeChangementEmail,
                    icon: _sendingEmailCode
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                        : const Icon(Icons.outgoing_mail, size: 18),
                    label: Text(_sendingEmailCode ? 'Envoi…' : 'Envoyer le code'),
                  )
                else ...[
                  FilledButton.icon(
                    onPressed: _confirmingEmail ? null : _confirmerChangementEmail,
                    icon: _confirmingEmail
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                        : const Icon(Icons.verified_outlined, size: 18),
                    label: Text(_confirmingEmail ? 'Vérification…' : 'Valider la nouvelle adresse'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _sendingEmailCode ? null : _envoyerCodeChangementEmail,
                    icon: _sendingEmailCode
                        ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh, size: 18),
                    label: const Text('Renvoyer le code'),
                  ),
                  TextButton(
                    onPressed: _annulerChangementEmail,
                    child: const Text('Annuler'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_person_outlined, size: 22, color: cs.primary),
                const SizedBox(width: 10),
                Text(
                  'Sécurité',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Choisissez un mot de passe fort (au moins 8 caractères).',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ancienMdpCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe actuel',
                prefixIcon: Icon(Icons.key_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nvMdpCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _confirmMdpCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmer le nouveau mot de passe',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _changePassword,
                icon: const Icon(Icons.shield_outlined, size: 20),
                label: const Text('Mettre à jour le mot de passe'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
