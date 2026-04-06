import 'package:flutter/material.dart';
import '../../services/candidat_settings_service.dart';
import '../../services/notifications_service.dart';
import '../../shared/widgets/theme_selector_tile.dart';

class CandidatSettingsScreen extends StatefulWidget {
  const CandidatSettingsScreen({super.key});

  @override
  State<CandidatSettingsScreen> createState() => _CandidatSettingsScreenState();
}

class _CandidatSettingsScreenState extends State<CandidatSettingsScreen> {
  final _nomCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _oldPasswordCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _settingsSvc = CandidatSettingsService();
  final _notifSvc = NotificationsService();
  bool _loading = true;
  String _emailReadonly = '';

  String _language = 'Français';
  String _timezone = 'Africa/Conakry';
  String _availability = 'Disponible immédiatement';

  bool _profileVisible = true;
  bool _visibleInTalentSearch = true;
  bool _allowRecruiterContact = true;
  bool _privateApplications = true;

  bool _notifStatusEmail = true;
  bool _notifMessagesEmail = true;
  bool _notifInApp = true;
  bool _notifOffresAlertesEmail = true;
  bool _notifTipsEmail = false;
  bool _notifWeeklySummary = true;

  final Set<String> _contracts = <String>{'CDI', 'CDD'};
  final Set<String> _cities = <String>{'Conakry'};
  final Set<String> _sectors = <String>{'Technologie'};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  static const _availChoices = [
    'Disponible immédiatement',
    'Disponible sous 2 semaines',
    'Disponible sous 1 mois',
  ];

  Future<void> _loadSettings() async {
    try {
      final res = await _settingsSvc.getSettings();
      final data = (res['data'] as Map?)?.cast<String, dynamic>() ?? const {};
      final compte =
          (data['compte'] as Map?)?.cast<String, dynamic>() ?? const {};
      final conf =
          (data['confidentialite'] as Map?)?.cast<String, dynamic>() ??
          const {};
      final notif =
          (data['notifications'] as Map?)?.cast<String, dynamic>() ?? const {};
      final rech =
          (data['recherche_emploi'] as Map?)?.cast<String, dynamic>() ??
          const {};

      void setFromList(Set<String> target, List<dynamic>? raw, List<String> allowed) {
        final s = (raw ?? [])
            .map((e) => e.toString())
            .where((e) => allowed.contains(e))
            .toSet();
        target
          ..clear()
          ..addAll(s.isEmpty ? {allowed.first} : s);
      }

      setState(() {
        _nomCtrl.text = (compte['nom'] ?? '').toString();
        _telephoneCtrl.text = (compte['telephone'] ?? '').toString();
        _adresseCtrl.text = (compte['adresse'] ?? '').toString();
        _emailReadonly = (compte['email'] ?? '').toString();
        _language = (compte['langue_interface'] ?? 'Français').toString();
        _timezone = (compte['fuseau_horaire'] ?? 'Africa/Conakry').toString();

        _profileVisible = conf['profil_visible'] == true;
        _visibleInTalentSearch = conf['visible_recherche_talents'] != false;
        _allowRecruiterContact = conf['recevoir_propositions'] == true;
        _privateApplications = conf['candidatures_confidentielles'] == true;

        _notifStatusEmail = notif['email_candidature'] != false;
        _notifMessagesEmail = notif['email_message'] != false;
        _notifInApp = notif['notif_in_app'] != false;
        _notifOffresAlertesEmail = notif['offres_alertes_email'] != false;
        _notifTipsEmail = notif['conseils_email'] == true;
        _notifWeeklySummary = notif['resume_hebdo'] == true;

        _availability = (rech['disponibilite'] ?? _availChoices.first).toString();
        _salaryCtrl.text = (rech['salaire_souhaite'] ?? '').toString();

        setFromList(
          _contracts,
          rech['types_contrat'] as List?,
          const ['CDI', 'CDD', 'Stage', 'Freelance'],
        );
        setFromList(
          _cities,
          rech['villes'] as List?,
          const ['Conakry', 'Labé', 'Kankan', 'Kindia', 'Remote'],
        );
        setFromList(
          _sectors,
          rech['secteurs'] as List?,
          const ['Technologie', 'Finance', 'Télécom', 'Santé', 'Éducation'],
        );

        _loading = false;
      });
      _oldPasswordCtrl.text = '';
      _passwordCtrl.text = '';
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _availabilityItems {
    if (_availChoices.contains(_availability)) return _availChoices.toList();
    return [_availability, ..._availChoices];
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _telephoneCtrl.dispose();
    _adresseCtrl.dispose();
    _oldPasswordCtrl.dispose();
    _passwordCtrl.dispose();
    _salaryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final pagePad = EdgeInsets.fromLTRB(
      20,
      16,
      20,
      MediaQuery.of(context).size.width <= 900 ? 80 : 24,
    );
    return RefreshIndicator(
      onRefresh: _loadSettings,
      child: ListView(
        padding: pagePad,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
        const Text(
          'Paramètres du compte',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Gérez vos préférences, votre confidentialité et vos notifications.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 14),
        _sectionCard(
          title: 'Informations du compte',
          child: Column(
            children: [
              TextField(
                controller: _nomCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  isDense: true,
                  suffixIcon: Icon(Icons.lock_outline, size: 18),
                ),
                child: Text(
                  _emailReadonly.isEmpty ? '—' : _emailReadonly,
                  style: const TextStyle(height: 1.35),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _telephoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _adresseCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _oldPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe actuel',
                  hintText: '••••••••',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  hintText: '••••••••',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('lang_$_language'),
                      initialValue: _language,
                      decoration: const InputDecoration(
                        labelText: 'Langue',
                        isDense: true,
                      ),
                      items: const ['Français', 'English']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _language = v ?? _language),
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('tz_$_timezone'),
                      initialValue: _timezone,
                      decoration: const InputDecoration(
                        labelText: 'Fuseau horaire',
                        isDense: true,
                      ),
                      items: const ['Africa/Conakry', 'Europe/Paris', 'UTC']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _timezone = v ?? _timezone),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Confidentialité & Visibilité',
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _profileVisible,
                onChanged: (v) => setState(() => _profileVisible = v),
                title: const Text('Mon profil est visible par les recruteurs'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _visibleInTalentSearch,
                onChanged: (v) => setState(() => _visibleInTalentSearch = v),
                title: const Text(
                  'Afficher mon profil dans la recherche de talents',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _allowRecruiterContact,
                onChanged: (v) => setState(() => _allowRecruiterContact = v),
                title: const Text(
                  'Recevoir des propositions de contact des recruteurs',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _privateApplications,
                onChanged: (v) => setState(() => _privateApplications = v),
                title: const Text('Mes candidatures sont confidentielles'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const ThemeSelectorTile(),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Préférences de notification',
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _notifStatusEmail,
                onChanged: (v) => setState(() => _notifStatusEmail = v),
                title: const Text('Email: changement statut candidature'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _notifMessagesEmail,
                onChanged: (v) => setState(() => _notifMessagesEmail = v),
                title: const Text('Email: nouveaux messages'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _notifInApp,
                onChanged: (v) => setState(() => _notifInApp = v),
                title: const Text('Notifications dans l’application'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _notifOffresAlertesEmail,
                onChanged: (v) => setState(() => _notifOffresAlertesEmail = v),
                title: const Text('Email : alertes nouvelles offres'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _notifTipsEmail,
                onChanged: (v) => setState(() => _notifTipsEmail = v),
                title: const Text('Email: conseils et ressources'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _notifWeeklySummary,
                onChanged: (v) => setState(() => _notifWeeklySummary = v),
                title: const Text('Résumé hebdomadaire de vos candidatures'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Préférences de recherche d’emploi',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Types de contrat préférés',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _multiChips(
                values: const ['CDI', 'CDD', 'Stage', 'Freelance'],
                selected: _contracts,
              ),
              const SizedBox(height: 10),
              const Text(
                'Villes préférées',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _multiChips(
                values: const ['Conakry', 'Labé', 'Kankan', 'Kindia', 'Remote'],
                selected: _cities,
              ),
              const SizedBox(height: 10),
              const Text(
                'Secteurs préférés',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _multiChips(
                values: const [
                  'Technologie',
                  'Finance',
                  'Télécom',
                  'Santé',
                  'Éducation',
                ],
                selected: _sectors,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                key: ValueKey('avail_$_availability'),
                initialValue: _availabilityItems.contains(_availability)
                    ? _availability
                    : _availabilityItems.first,
                decoration: const InputDecoration(
                  labelText: 'Disponibilité',
                  isDense: true,
                ),
                items: _availabilityItems
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _availability = v ?? _availability),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _salaryCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Salaire souhaité (optionnel, confidentiel)',
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Données & Confidentialité',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export des données RGPD à connecter.'),
                    ),
                  );
                },
                icon: const Icon(Icons.download_outlined, size: 16),
                label: const Text('Télécharger mes données'),
              ),
              OutlinedButton.icon(
                onPressed: () => _openDeleteDialog(),
                icon: const Icon(Icons.delete_forever_outlined, size: 16),
                label: const Text('Supprimer mon compte'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Danger Zone',
          danger: true,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Compte désactivé temporairement (placeholder).',
                      ),
                    ),
                  );
                },
                child: const Text('Désactiver temporairement'),
              ),
              FilledButton.tonalIcon(
                onPressed: _openDeleteDialog,
                icon: const Icon(Icons.warning_amber_rounded, size: 16),
                label: const Text('Supprimer définitivement'),
                style: FilledButton.styleFrom(
                  foregroundColor: const Color(0xFFB91C1C),
                  backgroundColor: const Color(0xFFFEE2E2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await _settingsSvc.updateProfil(
                  nom: _nomCtrl.text.trim(),
                  telephone: _telephoneCtrl.text.trim(),
                  adresse: _adresseCtrl.text.trim(),
                  langueInterface: _language,
                  fuseauHoraire: _timezone,
                  disponibilite: _availability,
                );
                await _settingsSvc.updateConfidentialite(
                  profilVisible: _profileVisible,
                  recevoirPropositions: _allowRecruiterContact,
                  visibleRechercheTalents: _visibleInTalentSearch,
                  candidaturesConfidentielles: _privateApplications,
                );
                await _notifSvc.savePreferences(
                  emailCandidature: _notifStatusEmail,
                  emailMessage: _notifMessagesEmail,
                  notifInApp: _notifInApp,
                  offresAlertesEmail: _notifOffresAlertesEmail,
                  resumeHebdo: _notifWeeklySummary,
                  conseilsEmail: _notifTipsEmail,
                );
                await _settingsSvc.updateRechercheEmploi(
                  typesContrat: _contracts.toList(),
                  villes: _cities.toList(),
                  secteurs: _sectors.toList(),
                  salaireSouhaite: _salaryCtrl.text.trim().isEmpty
                      ? null
                      : _salaryCtrl.text.trim(),
                );
                if (_oldPasswordCtrl.text.trim().isNotEmpty &&
                    _passwordCtrl.text.trim().isNotEmpty) {
                  await _settingsSvc.updatePassword(
                    oldPassword: _oldPasswordCtrl.text.trim(),
                    newPassword: _passwordCtrl.text.trim(),
                  );
                }
                if (!mounted) return;
                await _loadSettings();
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('Préférences enregistrées.')),
                );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            icon: const Icon(Icons.save_outlined, size: 16),
            label: const Text('Enregistrer'),
          ),
        ),
      ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    bool danger = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: danger ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: danger ? const Color(0xFFB91C1C) : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _multiChips({
    required List<String> values,
    required Set<String> selected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values
          .map(
            (v) => FilterChip(
              label: Text(v),
              selected: selected.contains(v),
              onSelected: (on) {
                setState(() {
                  if (on) {
                    selected.add(v);
                  } else {
                    selected.remove(v);
                  }
                });
              },
            ),
          )
          .toList(),
    );
  }

  Future<void> _openDeleteDialog() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pour confirmer, saisissez "SUPPRIMER".'),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'SUPPRIMER',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              ctx,
              ctrl.text.trim().toUpperCase() == 'SUPPRIMER',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Suppression du compte à connecter côté API.'),
      ),
    );
  }
}
