import 'package:flutter/material.dart';
import '../../widgets/responsive_container.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  int _sectionIndex = 0;
  bool _hasUnsavedChanges = false;
  bool _saving = false;

  final _platformNameCtrl = TextEditingController(text: 'EmploiConnect');
  final _contactEmailCtrl = TextEditingController(text: 'contact@emploiconnect.gn');
  final _contactPhoneCtrl = TextEditingController(text: '+224 620 00 00 00');
  final _addressCtrl = TextEditingController(text: 'Conakry, Guinée');

  bool _openRegistration = true;
  bool _autoValidation = false;
  int _maxOffersFree = 5;
  int _offerValidityDays = 30;

  bool _welcomeEmail = true;
  bool _weeklySummary = false;
  bool _newApplicationEmail = true;
  bool _validationEmail = true;

  bool _aiSuggestions = true;
  double _matchingThreshold = 70;

  bool _maintenanceMode = false;
  bool _admin2fa = false;
  double _sessionMinutes = 120;
  double _maxLoginAttempts = 5;

  static const List<_SettingsSection> _sections = [
    _SettingsSection('Général', Icons.tune_rounded),
    _SettingsSection('Comptes', Icons.people_alt_outlined),
    _SettingsSection('Notifications', Icons.notifications_active_outlined),
    _SettingsSection('IA & Matching', Icons.auto_awesome_outlined),
    _SettingsSection('Maintenance', Icons.build_outlined),
    _SettingsSection('Sécurité', Icons.shield_outlined),
  ];

  @override
  void dispose() {
    _platformNameCtrl.dispose();
    _contactEmailCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (_hasUnsavedChanges) return;
    setState(() => _hasUnsavedChanges = true);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _hasUnsavedChanges = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paramètres sauvegardés avec succès')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 86),
            child: LayoutBuilder(
              builder: (context, c) {
                final mobile = c.maxWidth < 960;
                if (mobile) {
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 14),
                      _buildSectionTabsMobile(),
                      const SizedBox(height: 12),
                      _buildSectionContent(),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 220,
                      child: Column(
                        children: [
                          _buildHeader(compact: true),
                          const SizedBox(height: 12),
                          _buildSectionMenuDesktop(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(top: 20, right: 20),
                        children: [
                          _buildSectionContent(),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Icon(
                    _hasUnsavedChanges ? Icons.circle : Icons.check_circle,
                    size: 14,
                    color: _hasUnsavedChanges ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _hasUnsavedChanges ? 'Modifications non sauvegardées' : 'Tous les changements sont sauvegardés',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _hasUnsavedChanges && !_saving ? _save : null,
                    icon: _saving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Sauvegarde...' : 'Sauvegarder'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({bool compact = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paramètres Plateforme',
          style: TextStyle(
            fontSize: compact ? 18 : 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Configurez la plateforme EmploiConnect',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildSectionTabsMobile() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_sections.length, (i) {
          final selected = i == _sectionIndex;
          return Padding(
            padding: EdgeInsets.only(right: i == _sections.length - 1 ? 0 : 8),
            child: ChoiceChip(
              label: Text(_sections[i].title),
              selected: selected,
              onSelected: (_) => setState(() => _sectionIndex = i),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSectionMenuDesktop() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: List.generate(_sections.length, (i) {
          final s = _sections[i];
          final selected = i == _sectionIndex;
          return ListTile(
            selected: selected,
            selectedTileColor: const Color(0xFFEFF6FF),
            leading: Icon(s.icon, color: selected ? const Color(0xFF1A56DB) : const Color(0xFF64748B)),
            title: Text(
              s.title,
              style: TextStyle(
                color: selected ? const Color(0xFF1A56DB) : const Color(0xFF334155),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            onTap: () => setState(() => _sectionIndex = i),
          );
        }),
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_sectionIndex) {
      case 0:
        return _buildGeneralSection();
      case 1:
        return _buildAccountsSection();
      case 2:
        return _buildNotificationsSection();
      case 3:
        return _buildAiSection();
      case 4:
        return _buildMaintenanceSection();
      case 5:
        return _buildSecuritySection();
      default:
        return _buildGeneralSection();
    }
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildGeneralSection() {
    return _sectionCard(
      title: 'Informations Générales',
      children: [
        TextField(
          controller: _platformNameCtrl,
          decoration: const InputDecoration(labelText: 'Nom de la plateforme'),
          onChanged: (_) => _markChanged(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _contactEmailCtrl,
          decoration: const InputDecoration(labelText: 'Email de contact'),
          onChanged: (_) => _markChanged(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _contactPhoneCtrl,
          decoration: const InputDecoration(labelText: 'Téléphone'),
          onChanged: (_) => _markChanged(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _addressCtrl,
          decoration: const InputDecoration(labelText: 'Adresse'),
          onChanged: (_) => _markChanged(),
        ),
      ],
    );
  }

  Widget _buildAccountsSection() {
    return _sectionCard(
      title: 'Gestion des Comptes',
      children: [
        SwitchListTile(
          value: _openRegistration,
          onChanged: (v) => setState(() {
            _openRegistration = v;
            _markChanged();
          }),
          title: const Text('Activer l’inscription libre'),
        ),
        SwitchListTile(
          value: _autoValidation,
          onChanged: (v) => setState(() {
            _autoValidation = v;
            _markChanged();
          }),
          title: const Text('Validation automatique des nouveaux comptes'),
        ),
        const SizedBox(height: 8),
        Text('Nombre max d’offres (gratuit) : $_maxOffersFree'),
        Slider(
          min: 1,
          max: 20,
          divisions: 19,
          value: _maxOffersFree.toDouble(),
          onChanged: (v) => setState(() {
            _maxOffersFree = v.round();
            _markChanged();
          }),
        ),
        Text('Durée de validité d’une offre : $_offerValidityDays jours'),
        Slider(
          min: 7,
          max: 90,
          divisions: 83,
          value: _offerValidityDays.toDouble(),
          onChanged: (v) => setState(() {
            _offerValidityDays = v.round();
            _markChanged();
          }),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return _sectionCard(
      title: 'Notifications Email',
      children: [
        SwitchListTile(
          value: _welcomeEmail,
          onChanged: (v) => setState(() {
            _welcomeEmail = v;
            _markChanged();
          }),
          title: const Text('Template email de bienvenue'),
        ),
        SwitchListTile(
          value: _newApplicationEmail,
          onChanged: (v) => setState(() {
            _newApplicationEmail = v;
            _markChanged();
          }),
          title: const Text('Notification nouvelles candidatures'),
        ),
        SwitchListTile(
          value: _weeklySummary,
          onChanged: (v) => setState(() {
            _weeklySummary = v;
            _markChanged();
          }),
          title: const Text('Résumé hebdomadaire'),
        ),
        SwitchListTile(
          value: _validationEmail,
          onChanged: (v) => setState(() {
            _validationEmail = v;
            _markChanged();
          }),
          title: const Text('Email de validation de compte'),
        ),
      ],
    );
  }

  Widget _buildAiSection() {
    return _sectionCard(
      title: 'IA & Matching',
      children: [
        SwitchListTile(
          value: _aiSuggestions,
          onChanged: (v) => setState(() {
            _aiSuggestions = v;
            _markChanged();
          }),
          title: const Text('Activer les suggestions automatiques'),
        ),
        const SizedBox(height: 8),
        Text('Seuil minimum score matching : ${_matchingThreshold.round()}%'),
        Slider(
          min: 0,
          max: 100,
          value: _matchingThreshold,
          onChanged: (v) => setState(() {
            _matchingThreshold = v;
            _markChanged();
          }),
        ),
      ],
    );
  }

  Widget _buildMaintenanceSection() {
    return _sectionCard(
      title: 'Maintenance',
      children: [
        SwitchListTile(
          value: _maintenanceMode,
          onChanged: (v) => setState(() {
            _maintenanceMode = v;
            _markChanged();
          }),
          title: const Text('Mode maintenance'),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                _markChanged();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache vidé')),
                );
              },
              icon: const Icon(Icons.cleaning_services_outlined),
              label: const Text('Vider le cache'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Derniers logs chargés')),
                );
              },
              icon: const Icon(Icons.bug_report_outlined),
              label: const Text('Voir les logs'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return _sectionCard(
      title: 'Sécurité',
      children: [
        Text('Durée de session : ${_sessionMinutes.round()} minutes'),
        Slider(
          min: 15,
          max: 480,
          divisions: 31,
          value: _sessionMinutes,
          onChanged: (v) => setState(() {
            _sessionMinutes = v;
            _markChanged();
          }),
        ),
        Text('Nombre max de tentatives : ${_maxLoginAttempts.round()}'),
        Slider(
          min: 3,
          max: 10,
          divisions: 7,
          value: _maxLoginAttempts,
          onChanged: (v) => setState(() {
            _maxLoginAttempts = v;
            _markChanged();
          }),
        ),
        SwitchListTile(
          value: _admin2fa,
          onChanged: (v) => setState(() {
            _admin2fa = v;
            _markChanged();
          }),
          title: const Text('Activer 2FA pour les admins'),
        ),
      ],
    );
  }
}

class _SettingsSection {
  const _SettingsSection(this.title, this.icon);
  final String title;
  final IconData icon;
}

