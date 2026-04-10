import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/candidat_settings_service.dart';
import '../../services/notifications_service.dart';
import '../../shared/widgets/theme_selector_tile.dart';

class CandidatSettingsScreen extends StatefulWidget {
  const CandidatSettingsScreen({super.key});

  @override
  State<CandidatSettingsScreen> createState() => _CandidatSettingsScreenState();
}

class _CandidatSettingsScreenState extends State<CandidatSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final _nomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _pwdActuelCtrl = TextEditingController();
  final _pwdNouveauCtrl = TextEditingController();
  final _pwdConfirmCtrl = TextEditingController();

  final _settingsSvc = CandidatSettingsService();
  final _notifSvc = NotificationsService();

  bool _loading = true;
  bool _isSaving = false;
  bool _showPwd = false;
  String _emailReadonly = '';

  bool _notifEmail = true;
  bool _notifPush = true;
  bool _notifCandidatures = true;
  bool _notifMessages = true;
  bool _notifOffres = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nomCtrl.dispose();
    _telCtrl.dispose();
    _pwdActuelCtrl.dispose();
    _pwdNouveauCtrl.dispose();
    _pwdConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _settingsSvc.getSettings();
      final data = (res['data'] as Map?)?.cast<String, dynamic>() ?? const {};
      final compte =
          (data['compte'] as Map?)?.cast<String, dynamic>() ?? const {};
      final notif =
          (data['notifications'] as Map?)?.cast<String, dynamic>() ?? const {};
      if (!mounted) return;
      setState(() {
        _nomCtrl.text = (compte['nom'] ?? '').toString();
        _telCtrl.text = (compte['telephone'] ?? '').toString();
        _emailReadonly = (compte['email'] ?? '').toString();
        _notifEmail = notif['email_candidature'] != false;
        _notifPush = notif['notif_in_app'] != false;
        _notifCandidatures = notif['email_candidature'] != false;
        _notifMessages = notif['email_message'] != false;
        _notifOffres = notif['offres_alertes_email'] != false;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sauvegarderCompte() async {
    setState(() => _isSaving = true);
    try {
      await _settingsSvc.updateProfil(
        nom: _nomCtrl.text.trim(),
        telephone: _telCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Informations mises à jour'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _sauvegarderPreferences() async {
    try {
      await _notifSvc.savePreferences(
        emailCandidature: _notifCandidatures,
        emailMessage: _notifMessages,
        notifInApp: _notifPush,
        offresAlertesEmail: _notifOffres,
      );
    } catch (_) {}
  }

  Future<void> _changerMotDePasse() async {
    if (_pwdNouveauCtrl.text != _pwdConfirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les mots de passe ne correspondent pas'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_pwdNouveauCtrl.text.trim().length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le mot de passe doit contenir au moins 8 caractères'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _settingsSvc.updatePassword(
        oldPassword: _pwdActuelCtrl.text.trim(),
        newPassword: _pwdNouveauCtrl.text.trim(),
      );
      _pwdActuelCtrl.clear();
      _pwdNouveauCtrl.clear();
      _pwdConfirmCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Mot de passe modifié avec succès'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _confirmerSuppression() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Supprimer le compte ?',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Cette action est irréversible. Toutes vos données, candidatures et messages seront définitivement supprimés.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Suppression compte à connecter côté API.'),
                ),
              );
            },
            child: Text(
              'Supprimer définitivement',
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final w = MediaQuery.of(context).size.width;
    final compact = w < 380;
    final pagePad = EdgeInsets.fromLTRB(
      compact ? 12 : 20,
      compact ? 12 : 16,
      compact ? 12 : 20,
      w <= 900 ? 80 : 24,
    );
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(compact ? 12 : 20, compact ? 14 : 20, compact ? 12 : 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paramètres',
                style: GoogleFonts.poppins(
                  fontSize: compact ? 19 : 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                'Gérez votre compte et vos préférences',
                style: GoogleFonts.inter(
                  fontSize: compact ? 12 : 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                labelStyle: GoogleFonts.inter(
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w400,
                ),
                labelColor: const Color(0xFF1A56DB),
                unselectedLabelColor: const Color(0xFF94A3B8),
                indicatorColor: const Color(0xFF1A56DB),
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Compte'),
                  Tab(text: 'Notifications'),
                  Tab(text: 'Sécurité'),
                  Tab(text: 'Apparence'),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              SingleChildScrollView(
                padding: pagePad,
                child: Column(
                  children: [
                    _CarteSection(
                      titre: '📋 Informations du compte',
                      children: [
                        _InfoLecture(
                          icon: Icons.email_outlined,
                          label: 'Adresse email',
                          value: _emailReadonly,
                          note: 'Non modifiable',
                        ),
                        const SizedBox(height: 10),
                        const _InfoLecture(
                          icon: Icons.badge_outlined,
                          label: 'Rôle',
                          value: 'Chercheur d\'emploi',
                          badge: 'Actif',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _CarteSection(
                      titre: '✏️ Modifier mes informations',
                      children: [
                        _ChampForm(
                          ctrl: _nomCtrl,
                          label: 'Nom complet',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 12),
                        _ChampForm(
                          ctrl: _telCtrl,
                          label: 'Téléphone',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _BoutonSauvegarder(
                          label: 'Mettre à jour',
                          isSaving: _isSaving,
                          onPressed: _sauvegarderCompte,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _CarteSection(
                      titre: '⚠️ Zone de danger',
                      couleurBord: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Supprimer mon compte',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    'Cette action est irréversible. Toutes vos données seront supprimées.',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFEF4444)),
                                foregroundColor: const Color(0xFFEF4444),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _confirmerSuppression,
                              child: Text(
                                'Supprimer',
                                style: GoogleFonts.inter(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                padding: pagePad,
                child: Column(
                  children: [
                    _CarteSection(
                      titre: '📡 Canaux de notification',
                      children: [
                        _ToggleNotif(
                          icon: Icons.email_outlined,
                          couleur: const Color(0xFF1A56DB),
                          titre: 'Notifications par email',
                          sousTitre: 'Recevoir les alertes par email',
                          valeur: _notifEmail,
                          onChanged: (v) {
                            setState(() => _notifEmail = v);
                            _sauvegarderPreferences();
                          },
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _ToggleNotif(
                          icon: Icons.notifications_outlined,
                          couleur: const Color(0xFF8B5CF6),
                          titre: 'Notifications push',
                          sousTitre: 'Alertes en temps réel sur l\'application',
                          valeur: _notifPush,
                          onChanged: (v) {
                            setState(() => _notifPush = v);
                            _sauvegarderPreferences();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _CarteSection(
                      titre: '🔔 Types de notifications',
                      children: [
                        _ToggleNotif(
                          icon: Icons.assignment_outlined,
                          couleur: const Color(0xFF10B981),
                          titre: 'Candidatures',
                          sousTitre: 'Statut de vos candidatures',
                          valeur: _notifCandidatures,
                          onChanged: (v) {
                            setState(() => _notifCandidatures = v);
                            _sauvegarderPreferences();
                          },
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _ToggleNotif(
                          icon: Icons.chat_bubble_outline_rounded,
                          couleur: const Color(0xFF1A56DB),
                          titre: 'Messages',
                          sousTitre: 'Nouveaux messages reçus',
                          valeur: _notifMessages,
                          onChanged: (v) {
                            setState(() => _notifMessages = v);
                            _sauvegarderPreferences();
                          },
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _ToggleNotif(
                          icon: Icons.work_outline_rounded,
                          couleur: const Color(0xFFF59E0B),
                          titre: 'Nouvelles offres',
                          sousTitre: 'Offres correspondant à votre profil',
                          valeur: _notifOffres,
                          onChanged: (v) {
                            setState(() => _notifOffres = v);
                            _sauvegarderPreferences();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                padding: pagePad,
                child: _CarteSection(
                  titre: '🔐 Changer le mot de passe',
                  children: [
                    _ChampMdp(
                      ctrl: _pwdActuelCtrl,
                      label: 'Mot de passe actuel',
                      show: _showPwd,
                      onToggle: () => setState(() => _showPwd = !_showPwd),
                    ),
                    const SizedBox(height: 12),
                    _ChampMdp(
                      ctrl: _pwdNouveauCtrl,
                      label: 'Nouveau mot de passe',
                      show: _showPwd,
                      onToggle: () => setState(() => _showPwd = !_showPwd),
                    ),
                    const SizedBox(height: 12),
                    _ChampMdp(
                      ctrl: _pwdConfirmCtrl,
                      label: 'Confirmer le nouveau mot de passe',
                      show: _showPwd,
                      onToggle: () => setState(() => _showPwd = !_showPwd),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Conseils pour un mot de passe sécurisé :',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...const [
                            '✓ Au moins 8 caractères',
                            '✓ Lettres majuscules et minuscules',
                            '✓ Au moins un chiffre',
                            '✓ Au moins un caractère spécial',
                          ].map(
                            (c) => Text(
                              c,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _BoutonSauvegarder(
                      label: 'Changer le mot de passe',
                      isSaving: _isSaving,
                      onPressed: _changerMotDePasse,
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                padding: pagePad,
                child: const ThemeSelectorTile(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CarteSection extends StatelessWidget {
  const _CarteSection({
    required this.titre,
    required this.children,
    this.couleurBord,
  });

  final String titre;
  final List<Widget> children;
  final Color? couleurBord;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: couleurBord ?? const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titre,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      );
}

class _InfoLecture extends StatelessWidget {
  const _InfoLecture({
    required this.icon,
    required this.label,
    required this.value,
    this.badge,
    this.note,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? badge;
  final String? note;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    value.isEmpty ? '—' : value,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            if (note != null)
              Text(
                note!,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF94A3B8),
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      );
}

class _ChampForm extends StatelessWidget {
  const _ChampForm({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1A56DB), width: 1.5),
          ),
        ),
      );
}

class _ChampMdp extends StatelessWidget {
  const _ChampMdp({
    required this.ctrl,
    required this.label,
    required this.show,
    required this.onToggle,
  });

  final TextEditingController ctrl;
  final String label;
  final bool show;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: ctrl,
        obscureText: !show,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: Color(0xFF94A3B8),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
              color: const Color(0xFF94A3B8),
            ),
            onPressed: onToggle,
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      );
}

class _BoutonSauvegarder extends StatelessWidget {
  const _BoutonSauvegarder({
    required this.label,
    required this.isSaving,
    required this.onPressed,
  });

  final String label;
  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          icon: isSaving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save_rounded, size: 15),
          label: Text(
            isSaving ? 'Enregistrement...' : label,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: isSaving ? null : onPressed,
        ),
      );
}

class _ToggleNotif extends StatelessWidget {
  const _ToggleNotif({
    required this.icon,
    required this.couleur,
    required this.titre,
    required this.sousTitre,
    required this.valeur,
    required this.onChanged,
  });

  final IconData icon;
  final Color couleur;
  final String titre;
  final String sousTitre;
  final bool valeur;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: couleur, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  sousTitre,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Switch(value: valeur, onChanged: onChanged, activeThumbColor: couleur),
        ],
      );
}
