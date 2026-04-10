import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../providers/admin_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../shared/widgets/image_upload_widget.dart';
import '../../shared/widgets/theme_selector_tile.dart';
import '../../widgets/responsive_container.dart';
import 'widgets/admin_page_shimmer.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _admin = AdminService();
  int _sectionIndex = 0;
  bool _hasUnsavedChanges = false;
  bool _saving = false;
  bool _loadingParams = true;
  String? _loadError;

  final _platformNameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _citationsTableauBordCandidatCtrl = TextEditingController();
  final _citationsApiUrlCustomCtrl = TextEditingController();
  final _contactEmailCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _maintenanceMessageCtrl = TextEditingController();
  final _colorPrimaryCtrl = TextEditingController();
  final _faviconUrlCtrl = TextEditingController();
  final _logoUrlCtrl = TextEditingController();
  final _rapidApiKeyCtrl = TextEditingController();
  final _similarityHostCtrl = TextEditingController();
  final _parserHostCtrl = TextEditingController();
  final _topicTaggingHostCtrl = TextEditingController();
  final _openaiKeyCtrl = TextEditingController();
  final _anthropicApiKeyCtrl = TextEditingController();
  final _footerLinkedinCtrl = TextEditingController();
  final _footerFacebookCtrl = TextEditingController();
  final _footerTwitterCtrl = TextEditingController();
  final _footerInstagramCtrl = TextEditingController();
  final _footerWhatsappCtrl = TextEditingController();
  final _footerEmailCtrl = TextEditingController();
  final _footerPhoneCtrl = TextEditingController();
  final _footerAdresseCtrl = TextEditingController();
  final _footerTaglineCtrl = TextEditingController();
  final _ipsBlockedCtrl = TextEditingController();
  final _smtpHostCtrl = TextEditingController();
  final _smtpPortCtrl = TextEditingController();
  final _smtpUserCtrl = TextEditingController();
  final _smtpPasswordCtrl = TextEditingController();
  final _emailSenderNameCtrl = TextEditingController();
  final _tplWelcomeSubjectCtrl = TextEditingController();
  final _tplWelcomeBodyCtrl = TextEditingController();
  final _tplCandidatureSubjectCtrl = TextEditingController();
  final _tplValidationSubjectCtrl = TextEditingController();
  final _publicAppUrlCtrl = TextEditingController();
  final _emailWrapperCtrl = TextEditingController();
  final _emailMailAccentCtrl = TextEditingController();
  final _tplResetMdpSubjectCtrl = TextEditingController();
  final _tplAlerteOffreSubjectCtrl = TextEditingController();
  final _tplResumeHebdoMailSubjectCtrl = TextEditingController();
  final _tplAnalyseCvSubjectCtrl = TextEditingController();

  String _iaProvider = 'rapidapi';
  bool _openRegistration = false;
  bool _autoValidation = false;
  /// Si true : à la publication, les offres passent en ligne sans modération (paramètre global plateforme).
  bool _offresPublicationAuto = false;
  int _maxOffersFree = 0;
  int _offerValidityDays = 0;

  bool _weeklySummary = false;
  bool _newApplicationEmail = false;
  bool _validationEmail = false;
  bool _emailMessages = true;
  bool _emailOffreModeration = true;
  bool _emailAdminAlerts = true;
  bool _emailConfirmationCandidature = true;
  bool _emailCompteRejete = true;
  bool _emailStatutCandidature = true;
  bool _emailSignalementResolution = true;
  bool _emailSignalementConcerne = true;
  bool _emailAnnulationCandidatureRecruteur = true;
  bool _emailServiceActif = false;
  bool _emailResetMdp = true;
  bool _emailAlerteEmploiPlat = true;
  bool _emailAnalyseCvPlat = true;

  bool _aiSuggestions = false;
  double _matchingThreshold = 0;

  bool _maintenanceMode = false;
  bool _admin2fa = false;
  double _sessionMinutes = 0;
  double _maxLoginAttempts = 0;
  double _jwtExpirationHours = 24;

  List<Map<String, dynamic>> _bannieres = [];
  bool _bannieresLoading = false;
  bool _iaTestLoading = false;
  String? _iaTestMessage;
  Map<String, dynamic>? _iaTestResult;
  bool _isTestingIA = false;
  String _iaAmeliorationProvider = 'anthropic';
  String _anthropicModel = 'claude-haiku-4-5-20251001';
  bool _iaMatchingActif = true;

  static const Set<String> _iaAmeliorationProvidersAllowed = {
    'anthropic',
    'openai',
    'local',
    'aucun',
  };

  static const Set<String> _knownAnthropicModels = {
    'claude-haiku-4-5-20251001',
    'claude-sonnet-4-6',
  };
  bool _smtpTestLoading = false;
  String? _smtpTestMessage;

  bool _citationsApiActive = false;
  /// zenquotes | quotable | custom
  String _citationsApiSource = 'zenquotes';

  static const Set<String> _citationsApiSourcesAllowed = {
    'zenquotes',
    'quotable',
    'custom',
  };

  /// Modèles affichés lorsque la BDD a une valeur vide (variables remplies à l’envoi par le serveur).
  static const String _defaultEmailWrapperHtml = r'''<!DOCTYPE html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width"/></head>
<body style="margin:0;background:#f1f5f9;font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="padding:24px 12px;">
<tr><td align="center">
<table role="presentation" width="600" style="max-width:600px;background:#ffffff;border-radius:14px;overflow:hidden;box-shadow:0 4px 24px rgba(15,23,42,.08);">
<tr><td style="background:{{couleur_primaire}};padding:22px 26px;color:#ffffff;font-size:20px;font-weight:700;">{{plateforme}}</td></tr>
<tr><td style="padding:28px 26px;color:#334155;font-size:15px;line-height:1.6;">{{CONTENU}}</td></tr>
<tr><td style="padding:18px 26px;background:#f8fafc;color:#64748b;font-size:12px;line-height:1.5;">Cet e-mail a été envoyé par {{plateforme}}. Ne répondez pas si l’expéditeur est une adresse technique.</td></tr>
</table>
</td></tr>
</table></body></html>''';

  static const List<_SettingsSection> _sections = [
    _SettingsSection('Général', Icons.tune_rounded),
    _SettingsSection('Logo', Icons.image_outlined),
    _SettingsSection('Bannières', Icons.view_carousel_outlined),
    _SettingsSection('Comptes', Icons.people_alt_outlined),
    _SettingsSection('Notifications', Icons.notifications_active_outlined),
    _SettingsSection('IA & Matching', Icons.auto_awesome_outlined),
    _SettingsSection('Sécurité', Icons.shield_outlined),
    _SettingsSection('Pied de page', Icons.language_outlined),
    _SettingsSection('Maintenance', Icons.build_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _loadParametres();
  }

  dynamic _param(Map<String, dynamic>? grouped, String cle) {
    if (grouped == null) return null;
    for (final entry in grouped.values) {
      if (entry is Map<String, dynamic>) {
        final cell = entry[cle];
        if (cell is Map && cell.containsKey('valeur')) return cell['valeur'];
      }
      if (entry is List) {
        for (final p in entry) {
          if (p is Map && p['cle'] == cle) return p['valeur'];
        }
      }
    }
    return null;
  }

  bool _boolFromParam(dynamic v) {
    if (v == true || v == 1) return true;
    if (v == false || v == 0) return false;
    if (v is String) {
      final s = v.toLowerCase().trim();
      return s == 'true' || s == '1';
    }
    return false;
  }

  /// Préférence absente en BDD (migration pas encore appliquée) → activé.
  bool _boolNotifDefaultTrue(dynamic v) {
    if (v == null) return true;
    return _boolFromParam(v);
  }

  /// Si les champs templates sont vides en base, propose des sujets / enveloppe avec {{variables}} valides côté API.
  void _applyRecommendedEmailTemplatesIfStoredEmpty() {
    void fill(TextEditingController c, String v) {
      if (c.text.trim().isEmpty) c.text = v;
    }

    fill(_emailWrapperCtrl, _defaultEmailWrapperHtml);
    fill(
      _tplResetMdpSubjectCtrl,
      'Réinitialisation de votre mot de passe — {{plateforme}}',
    );
    fill(
      _tplAlerteOffreSubjectCtrl,
      'Nouvelle offre pour vous : {{titre_offre}} — {{plateforme}}',
    );
    fill(
      _tplResumeHebdoMailSubjectCtrl,
      'Votre résumé hebdomadaire — {{plateforme}}',
    );
    fill(
      _tplAnalyseCvSubjectCtrl,
      'Analyse de votre CV terminée — {{plateforme}}',
    );
    fill(_tplWelcomeSubjectCtrl, 'Bienvenue sur {{plateforme}}, {{nom}} !');
    fill(
      _tplWelcomeBodyCtrl,
      'Bonjour {{nom}},\n\n'
      'Votre compte sur {{plateforme}} a bien été créé (rôle : {{role}}). Vous pouvez vous connecter avec {{email}}.\n\n'
      'Cordialement,\nL’équipe {{plateforme}}',
    );
    fill(
      _tplCandidatureSubjectCtrl,
      'Nouvelle candidature pour « {{titre_offre}} » — {{plateforme}}',
    );
    fill(
      _tplValidationSubjectCtrl,
      'Votre compte {{plateforme}} est validé',
    );
  }

  Future<void> _refreshBannieres() async {
    setState(() => _bannieresLoading = true);
    try {
      final r = await _admin.getBannieresAdmin();
      final list = r['data'];
      final next = (list is List ? list : [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (mounted) {
        setState(() {
          _bannieres = next;
          _bannieresLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _bannieresLoading = false);
    }
  }

  Future<void> _refreshAllBannieres() async {
    await _refreshBannieres();
    if (!mounted) return;
    await context.read<AppConfigProvider>().reload();
  }

  Future<void> _loadParametres() async {
    setState(() {
      _loadingParams = true;
      _loadError = null;
    });
    try {
      final res = await _admin.getParametres();
      final grouped = res['data'] as Map<String, dynamic>?;
      if (!mounted) return;

      final ipsVal = _param(grouped, 'ips_bloquees');
      String ipsText = '';
      if (ipsVal is List) {
        ipsText = ipsVal.map((e) => e.toString()).join('\n');
      } else if (ipsVal is String) {
        try {
          final dec = jsonDecode(ipsVal) as List<dynamic>?;
          ipsText = dec?.map((e) => e.toString()).join('\n') ?? '';
        } catch (_) {
          ipsText = ipsVal;
        }
      }

      setState(() {
        _platformNameCtrl.text =
            _param(grouped, 'nom_plateforme')?.toString() ?? '';
        _descriptionCtrl.text =
            _param(grouped, 'description_plateforme')?.toString() ?? '';
        _citationsTableauBordCandidatCtrl.text =
            _param(grouped, 'citations_tableau_bord_candidat')?.toString() ?? '';
        _citationsApiActive = _boolFromParam(
          _param(grouped, 'citations_api_active'),
        );
        final rawSrc =
            _param(grouped, 'citations_api_source')?.toString().toLowerCase().trim() ??
            'zenquotes';
        _citationsApiSource = _citationsApiSourcesAllowed.contains(rawSrc)
            ? rawSrc
            : 'zenquotes';
        _citationsApiUrlCustomCtrl.text =
            _param(grouped, 'citations_api_url_custom')?.toString() ?? '';
        _contactEmailCtrl.text =
            _param(grouped, 'email_contact')?.toString() ?? '';
        _contactPhoneCtrl.text =
            _param(grouped, 'telephone_contact')?.toString() ?? '';
        _addressCtrl.text =
            _param(grouped, 'adresse_contact')?.toString() ?? '';
        _maintenanceMessageCtrl.text =
            _param(grouped, 'message_maintenance')?.toString() ?? '';
        _colorPrimaryCtrl.text =
            _param(grouped, 'couleur_primaire')?.toString() ?? '#1A56DB';
        _faviconUrlCtrl.text = _param(grouped, 'favicon_url')?.toString() ?? '';
        _logoUrlCtrl.text = _param(grouped, 'logo_url')?.toString() ?? '';
        _rapidApiKeyCtrl.text =
            _param(grouped, 'rapidapi_key')?.toString() ?? '';
        _similarityHostCtrl.text =
            _param(grouped, 'rapidapi_similarity_host')?.toString() ?? '';
        _parserHostCtrl.text =
            _param(grouped, 'rapidapi_resume_parser_host')?.toString() ?? '';
        _topicTaggingHostCtrl.text =
            _param(grouped, 'rapidapi_topic_tagging_host')?.toString() ?? '';
        _openaiKeyCtrl.text =
            _param(grouped, 'openai_api_key')?.toString() ?? '';
        _anthropicApiKeyCtrl.text =
            _param(grouped, 'anthropic_api_key')?.toString() ?? '';
        final provA =
            _param(grouped, 'ia_amelioration_provider')?.toString().toLowerCase().trim() ??
            'anthropic';
        final normalizedProv = provA == 'aucun' ? 'local' : provA;
        _iaAmeliorationProvider =
            _iaAmeliorationProvidersAllowed.contains(normalizedProv) ? normalizedProv : 'anthropic';
        _iaMatchingActif =
            _boolNotifDefaultTrue(_param(grouped, 'ia_matching_actif'));
        final am =
            _param(grouped, 'anthropic_model')?.toString().trim() ?? '';
        _anthropicModel = am.isNotEmpty ? am : 'claude-haiku-4-5-20251001';
        _iaProvider = _param(grouped, 'ia_provider')?.toString() ?? 'rapidapi';
        _footerLinkedinCtrl.text =
            _param(grouped, 'footer_linkedin')?.toString() ?? '';
        _footerFacebookCtrl.text =
            _param(grouped, 'footer_facebook')?.toString() ?? '';
        _footerTwitterCtrl.text =
            _param(grouped, 'footer_twitter')?.toString() ?? '';
        _footerInstagramCtrl.text =
            _param(grouped, 'footer_instagram')?.toString() ?? '';
        _footerWhatsappCtrl.text =
            _param(grouped, 'footer_whatsapp')?.toString() ?? '';
        _footerEmailCtrl.text =
            _param(grouped, 'footer_email')?.toString() ?? '';
        _footerPhoneCtrl.text =
            _param(grouped, 'footer_telephone')?.toString() ?? '';
        _footerAdresseCtrl.text =
            _param(grouped, 'footer_adresse')?.toString() ?? '';
        _footerTaglineCtrl.text =
            _param(grouped, 'footer_tagline')?.toString() ?? '';
        _ipsBlockedCtrl.text = ipsText;
        _smtpHostCtrl.text =
            _param(grouped, 'email_smtp_host')?.toString() ?? '';
        _smtpPortCtrl.text =
            _param(grouped, 'email_smtp_port')?.toString() ?? '587';
        _smtpUserCtrl.text =
            _param(grouped, 'email_smtp_user')?.toString() ?? '';
        _smtpPasswordCtrl.text =
            _param(grouped, 'email_smtp_password')?.toString() ?? '';
        _emailSenderNameCtrl.text =
            _param(grouped, 'email_nom_expediteur')?.toString() ??
            'EmploiConnect';
        _tplWelcomeSubjectCtrl.text =
            _param(grouped, 'template_bienvenue_sujet')?.toString() ?? '';
        _tplWelcomeBodyCtrl.text =
            _param(grouped, 'template_bienvenue_corps')?.toString() ?? '';
        _tplCandidatureSubjectCtrl.text =
            _param(grouped, 'template_candidature_sujet')?.toString() ?? '';
        _tplValidationSubjectCtrl.text =
            _param(grouped, 'template_validation_sujet')?.toString() ?? '';
        _publicAppUrlCtrl.text =
            _param(grouped, 'url_application_publique')?.toString() ?? '';
        _emailWrapperCtrl.text =
            _param(grouped, 'email_template_wrapper_html')?.toString() ?? '';
        _emailMailAccentCtrl.text =
            _param(grouped, 'email_couleur_primaire')?.toString() ?? '#1A56DB';
        _tplResetMdpSubjectCtrl.text =
            _param(grouped, 'template_reset_mdp_sujet')?.toString() ?? '';
        _tplAlerteOffreSubjectCtrl.text =
            _param(grouped, 'template_alerte_offre_sujet')?.toString() ?? '';
        _tplResumeHebdoMailSubjectCtrl.text =
            _param(grouped, 'template_resume_hebdo_sujet')?.toString() ?? '';
        _tplAnalyseCvSubjectCtrl.text =
            _param(grouped, 'template_analyse_cv_sujet')?.toString() ?? '';

        _applyRecommendedEmailTemplatesIfStoredEmpty();

        _openRegistration = _boolFromParam(
          _param(grouped, 'inscription_libre'),
        );
        _autoValidation = !_boolFromParam(
          _param(grouped, 'validation_manuelle_comptes'),
        );
        _offresPublicationAuto = _boolFromParam(
          _param(grouped, 'offres_publication_auto'),
        );
        _maxOffersFree = (_param(grouped, 'max_offres_gratuit') is int)
            ? _param(grouped, 'max_offres_gratuit') as int
            : int.tryParse(
                    _param(grouped, 'max_offres_gratuit')?.toString() ?? '',
                  ) ??
                  0;
        _offerValidityDays =
            (_param(grouped, 'duree_validite_offre_jours') is int)
            ? _param(grouped, 'duree_validite_offre_jours') as int
            : int.tryParse(
                    _param(grouped, 'duree_validite_offre_jours')?.toString() ??
                        '',
                  ) ??
                  0;
        _newApplicationEmail = _boolFromParam(
          _param(grouped, 'notif_email_candidature'),
        );
        _validationEmail = _boolFromParam(
          _param(grouped, 'notif_email_validation'),
        );
        _emailMessages = _boolNotifDefaultTrue(
          _param(grouped, 'notif_email_messages'),
        );
        _emailOffreModeration = _boolNotifDefaultTrue(
          _param(grouped, 'notif_email_offre_moderation'),
        );
        _emailAdminAlerts = _boolNotifDefaultTrue(
          _param(grouped, 'notif_email_alertes_admin'),
        );
        _emailConfirmationCandidature = _boolNotifDefaultTrue(
          _param(grouped, 'notif_email_confirmation_candidature'),
        );
        _emailCompteRejete = _boolNotifDefaultTrue(
          _param(grouped, 'notif_email_compte_rejete'),
        );
        _emailStatutCandidature = _boolNotifDefaultTrue(
          _param(grouped, 'notif_email_statut_candidature'),
        );
        _emailSignalementResolution = _boolNotifDefaultTrue(
          _param(grouped, 'notif_email_signalement_resolution'),
        );
        _emailSignalementConcerne = _boolNotifDefaultTrue(
          _param(grouped, 'notif_email_signalement_concerne'),
        );
        _emailAnnulationCandidatureRecruteur = _boolNotifDefaultTrue(
          _param(grouped, 'notif_email_annulation_candidature_recruteur'),
        );
        _emailResetMdp = _boolNotifDefaultTrue(
          _param(grouped, 'notif_email_reset_mdp'),
        );
        _emailAlerteEmploiPlat = _boolNotifDefaultTrue(
          _param(grouped, 'notif_email_alerte_emploi'),
        );
        _emailAnalyseCvPlat = _boolNotifDefaultTrue(
          _param(grouped, 'notif_email_analyse_cv'),
        );
        _weeklySummary = () {
          final er = _param(grouped, 'notif_email_resume_hebdo');
          if (er != null) return _boolFromParam(er);
          return _boolFromParam(_param(grouped, 'notif_resume_hebdo'));
        }();
        _emailServiceActif = _boolFromParam(
          _param(grouped, 'email_service_actif'),
        );
        _aiSuggestions = _boolFromParam(
          _param(grouped, 'suggestions_automatiques'),
        );
        final seuil = _param(grouped, 'seuil_matching_minimum');
        _matchingThreshold = (seuil is int)
            ? seuil.toDouble()
            : double.tryParse(seuil?.toString() ?? '') ?? 0;
        _maintenanceMode = _boolFromParam(_param(grouped, 'mode_maintenance'));
        final session = _param(grouped, 'duree_session_minutes');
        _sessionMinutes = (session is int)
            ? session.toDouble()
            : double.tryParse(session?.toString() ?? '') ?? 0;
        final maxT = _param(grouped, 'max_tentatives_connexion');
        _maxLoginAttempts = (maxT is int)
            ? maxT.toDouble()
            : double.tryParse(maxT?.toString() ?? '') ?? 0;
        final jwtH = _param(grouped, 'jwt_expiration_heures');
        _jwtExpirationHours = (jwtH is int)
            ? jwtH.toDouble()
            : double.tryParse(jwtH?.toString() ?? '') ?? 24;
        _admin2fa = _boolFromParam(_param(grouped, 'twofa_admin_actif'));

        _loadingParams = false;
        _hasUnsavedChanges = false;
      });
      await _refreshBannieres();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _loadingParams = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _platformNameCtrl.dispose();
    _descriptionCtrl.dispose();
    _citationsTableauBordCandidatCtrl.dispose();
    _citationsApiUrlCustomCtrl.dispose();
    _contactEmailCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _addressCtrl.dispose();
    _maintenanceMessageCtrl.dispose();
    _colorPrimaryCtrl.dispose();
    _faviconUrlCtrl.dispose();
    _logoUrlCtrl.dispose();
    _rapidApiKeyCtrl.dispose();
    _similarityHostCtrl.dispose();
    _parserHostCtrl.dispose();
    _topicTaggingHostCtrl.dispose();
    _openaiKeyCtrl.dispose();
    _anthropicApiKeyCtrl.dispose();
    _footerLinkedinCtrl.dispose();
    _footerFacebookCtrl.dispose();
    _footerTwitterCtrl.dispose();
    _footerInstagramCtrl.dispose();
    _footerWhatsappCtrl.dispose();
    _footerEmailCtrl.dispose();
    _footerPhoneCtrl.dispose();
    _footerAdresseCtrl.dispose();
    _footerTaglineCtrl.dispose();
    _ipsBlockedCtrl.dispose();
    _smtpHostCtrl.dispose();
    _smtpPortCtrl.dispose();
    _smtpUserCtrl.dispose();
    _smtpPasswordCtrl.dispose();
    _emailSenderNameCtrl.dispose();
    _tplWelcomeSubjectCtrl.dispose();
    _tplWelcomeBodyCtrl.dispose();
    _tplCandidatureSubjectCtrl.dispose();
    _tplValidationSubjectCtrl.dispose();
    _publicAppUrlCtrl.dispose();
    _emailWrapperCtrl.dispose();
    _emailMailAccentCtrl.dispose();
    _tplResetMdpSubjectCtrl.dispose();
    _tplAlerteOffreSubjectCtrl.dispose();
    _tplResumeHebdoMailSubjectCtrl.dispose();
    _tplAnalyseCvSubjectCtrl.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (_hasUnsavedChanges) return;
    setState(() => _hasUnsavedChanges = true);
  }

  List<String> _ipsListFromText() {
    return _ipsBlockedCtrl.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _admin.updateParametres([
        {'cle': 'nom_plateforme', 'valeur': _platformNameCtrl.text.trim()},
        {
          'cle': 'description_plateforme',
          'valeur': _descriptionCtrl.text.trim(),
        },
        {
          'cle': 'citations_tableau_bord_candidat',
          'valeur': _citationsTableauBordCandidatCtrl.text,
        },
        {'cle': 'citations_api_active', 'valeur': _citationsApiActive},
        {'cle': 'citations_api_source', 'valeur': _citationsApiSource},
        {
          'cle': 'citations_api_url_custom',
          'valeur': _citationsApiUrlCustomCtrl.text.trim(),
        },
        {'cle': 'email_contact', 'valeur': _contactEmailCtrl.text.trim()},
        {'cle': 'telephone_contact', 'valeur': _contactPhoneCtrl.text.trim()},
        {'cle': 'adresse_contact', 'valeur': _addressCtrl.text.trim()},
        {'cle': 'couleur_primaire', 'valeur': _colorPrimaryCtrl.text.trim()},
        {'cle': 'favicon_url', 'valeur': _faviconUrlCtrl.text.trim()},
        {'cle': 'inscription_libre', 'valeur': _openRegistration},
        {'cle': 'validation_manuelle_comptes', 'valeur': !_autoValidation},
        {'cle': 'offres_publication_auto', 'valeur': _offresPublicationAuto},
        {'cle': 'max_offres_gratuit', 'valeur': _maxOffersFree},
        {'cle': 'duree_validite_offre_jours', 'valeur': _offerValidityDays},
        {'cle': 'notif_email_candidature', 'valeur': _newApplicationEmail},
        {'cle': 'notif_email_validation', 'valeur': _validationEmail},
        {'cle': 'notif_email_messages', 'valeur': _emailMessages},
        {'cle': 'notif_email_offre_moderation', 'valeur': _emailOffreModeration},
        {'cle': 'notif_email_alertes_admin', 'valeur': _emailAdminAlerts},
        {
          'cle': 'notif_email_confirmation_candidature',
          'valeur': _emailConfirmationCandidature,
        },
        {'cle': 'notif_email_compte_rejete', 'valeur': _emailCompteRejete},
        {
          'cle': 'notif_email_statut_candidature',
          'valeur': _emailStatutCandidature,
        },
        {
          'cle': 'notif_email_signalement_resolution',
          'valeur': _emailSignalementResolution,
        },
        {
          'cle': 'notif_email_signalement_concerne',
          'valeur': _emailSignalementConcerne,
        },
        {
          'cle': 'notif_email_annulation_candidature_recruteur',
          'valeur': _emailAnnulationCandidatureRecruteur,
        },
        {'cle': 'notif_email_reset_mdp', 'valeur': _emailResetMdp},
        {'cle': 'notif_email_alerte_emploi', 'valeur': _emailAlerteEmploiPlat},
        {'cle': 'notif_email_analyse_cv', 'valeur': _emailAnalyseCvPlat},
        {'cle': 'notif_email_resume_hebdo', 'valeur': _weeklySummary},
        {'cle': 'notif_resume_hebdo', 'valeur': _weeklySummary},
        {'cle': 'url_application_publique', 'valeur': _publicAppUrlCtrl.text.trim()},
        {'cle': 'email_template_wrapper_html', 'valeur': _emailWrapperCtrl.text},
        {'cle': 'email_couleur_primaire', 'valeur': _emailMailAccentCtrl.text.trim()},
        {
          'cle': 'template_reset_mdp_sujet',
          'valeur': _tplResetMdpSubjectCtrl.text.trim(),
        },
        {
          'cle': 'template_alerte_offre_sujet',
          'valeur': _tplAlerteOffreSubjectCtrl.text.trim(),
        },
        {
          'cle': 'template_resume_hebdo_sujet',
          'valeur': _tplResumeHebdoMailSubjectCtrl.text.trim(),
        },
        {
          'cle': 'template_analyse_cv_sujet',
          'valeur': _tplAnalyseCvSubjectCtrl.text.trim(),
        },
        {'cle': 'email_service_actif', 'valeur': _emailServiceActif},
        {'cle': 'email_smtp_host', 'valeur': _smtpHostCtrl.text.trim()},
        {'cle': 'smtp_host', 'valeur': _smtpHostCtrl.text.trim()},
        {
          'cle': 'email_smtp_port',
          'valeur': int.tryParse(_smtpPortCtrl.text.trim()) ?? 587,
        },
        {
          'cle': 'smtp_port',
          'valeur': int.tryParse(_smtpPortCtrl.text.trim()) ?? 587,
        },
        {'cle': 'email_smtp_user', 'valeur': _smtpUserCtrl.text.trim()},
        {'cle': 'smtp_user', 'valeur': _smtpUserCtrl.text.trim()},
        {'cle': 'email_smtp_password', 'valeur': _smtpPasswordCtrl.text.trim()},
        {'cle': 'smtp_password', 'valeur': _smtpPasswordCtrl.text.trim()},
        {'cle': 'email_from', 'valeur': _smtpUserCtrl.text.trim()},
        {'cle': 'email_nom', 'valeur': _emailSenderNameCtrl.text.trim()},
        {
          'cle': 'email_nom_expediteur',
          'valeur': _emailSenderNameCtrl.text.trim(),
        },
        {
          'cle': 'template_bienvenue_sujet',
          'valeur': _tplWelcomeSubjectCtrl.text.trim(),
        },
        {'cle': 'template_bienvenue_corps', 'valeur': _tplWelcomeBodyCtrl.text},
        {
          'cle': 'template_candidature_sujet',
          'valeur': _tplCandidatureSubjectCtrl.text.trim(),
        },
        {
          'cle': 'template_validation_sujet',
          'valeur': _tplValidationSubjectCtrl.text.trim(),
        },
        {'cle': 'suggestions_automatiques', 'valeur': _aiSuggestions},
        {'cle': 'seuil_matching_minimum', 'valeur': _matchingThreshold.round()},
        {'cle': 'ia_provider', 'valeur': _iaProvider},
        {'cle': 'rapidapi_key', 'valeur': _rapidApiKeyCtrl.text.trim()},
        {
          'cle': 'rapidapi_similarity_host',
          'valeur': _similarityHostCtrl.text.trim(),
        },
        {
          'cle': 'rapidapi_resume_parser_host',
          'valeur': _parserHostCtrl.text.trim(),
        },
        {
          'cle': 'rapidapi_topic_tagging_host',
          'valeur': _topicTaggingHostCtrl.text.trim(),
        },
        {'cle': 'openai_api_key', 'valeur': _openaiKeyCtrl.text.trim()},
        {'cle': 'anthropic_api_key', 'valeur': _anthropicApiKeyCtrl.text.trim()},
        {'cle': 'anthropic_model', 'valeur': _anthropicModel.trim()},
        {'cle': 'ia_amelioration_provider', 'valeur': _iaAmeliorationProvider},
        {'cle': 'ia_matching_provider', 'valeur': _iaAmeliorationProvider},
        {'cle': 'ia_matching_actif', 'valeur': _iaMatchingActif},
        {'cle': 'mode_maintenance', 'valeur': _maintenanceMode},
        {
          'cle': 'message_maintenance',
          'valeur': _maintenanceMessageCtrl.text.trim(),
        },
        {'cle': 'duree_session_minutes', 'valeur': _sessionMinutes.round()},
        {
          'cle': 'max_tentatives_connexion',
          'valeur': _maxLoginAttempts.round(),
        },
        {'cle': 'jwt_expiration_heures', 'valeur': _jwtExpirationHours.round()},
        {'cle': 'twofa_admin_actif', 'valeur': _admin2fa},
        {'cle': 'ips_bloquees', 'valeur': _ipsListFromText()},
        {'cle': 'footer_linkedin', 'valeur': _footerLinkedinCtrl.text.trim()},
        {'cle': 'footer_facebook', 'valeur': _footerFacebookCtrl.text.trim()},
        {'cle': 'footer_twitter', 'valeur': _footerTwitterCtrl.text.trim()},
        {'cle': 'footer_instagram', 'valeur': _footerInstagramCtrl.text.trim()},
        {'cle': 'footer_whatsapp', 'valeur': _footerWhatsappCtrl.text.trim()},
        {'cle': 'footer_email', 'valeur': _footerEmailCtrl.text.trim()},
        {'cle': 'footer_telephone', 'valeur': _footerPhoneCtrl.text.trim()},
        {'cle': 'footer_adresse', 'valeur': _footerAdresseCtrl.text.trim()},
        {'cle': 'footer_tagline', 'valeur': _footerTaglineCtrl.text.trim()},
      ]);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _hasUnsavedChanges = false;
      });
      context.read<AdminProvider>().loadDashboard();
      await _loadParametres();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paramètres sauvegardés avec succès')),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _testIa() async {
    setState(() {
      _iaTestLoading = true;
      _iaTestMessage = null;
      _iaTestResult = null;
    });
    try {
      final res = await _admin.testerConnexionIA();
      if (!mounted) return;
      setState(() {
        _iaTestLoading = false;
        _iaTestMessage = res['success'] == true
            ? 'Connexion API vérifiée.'
            : (res['message']?.toString() ?? 'Échec du test');
        _iaTestResult = res;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _iaTestLoading = false;
        _iaTestMessage = e.toString();
        _iaTestResult = null;
      });
    }
  }

  Future<void> _testerIaTexteApropos() async {
    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expirée : reconnectez-vous.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isTestingIA = true);
    try {
      final uri = Uri.parse('$apiBaseUrl$apiPrefix/admin/parametres/test-ia-apropos');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'texte_original':
              '[TEXTE DE TEST] Je suis développeur mobile avec quelques années d\'expérience.',
          'titre_poste': 'Développeur Mobile',
          'competences': ['Flutter', 'Dart', 'Firebase'],
        }),
      );
      if (!mounted) return;
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      if (res.statusCode >= 200 &&
          res.statusCode < 300 &&
          body?['success'] == true) {
        final data = body!['data'] as Map<String, dynamic>?;
        final resultat = data?['texte_ameliore']?.toString() ?? '';
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✅ IA opérationnelle !',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Texte test :',
                        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                      ),
                      Text(
                        '[TEXTE DE TEST] Je suis développeur mobile...',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.maxFinite,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 12, color: Color(0xFF7C3AED)),
                          const SizedBox(width: 4),
                          Text(
                            'Résultat amélioré :',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6D28D9),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        child: Text(
                          resultat,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF374151),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      } else {
        final msg = body?['message']?.toString() ?? 'Erreur ${res.statusCode}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isTestingIA = false);
    }
  }

  Future<void> _testSmtp() async {
    final auth = context.read<AuthProvider>();
    final email = auth.user?['email']?.toString();
    setState(() {
      _smtpTestLoading = true;
      _smtpTestMessage = null;
    });
    try {
      final res = await _admin.testerSMTP(
        destinataire: (email != null && email.isNotEmpty) ? email : null,
      );
      if (!mounted) return;
      final msg = res['message']?.toString()
          ?? (res['success'] == true ? 'OK' : 'Échec');
      setState(() {
        _smtpTestLoading = false;
        _smtpTestMessage = msg;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _smtpTestLoading = false;
        _smtpTestMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _onReorderBanniere(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final item = _bannieres.removeAt(oldIndex);
      _bannieres.insert(newIndex, item);
    });
    final ordre = List.generate(
      _bannieres.length,
      (i) => <String, dynamic>{'id': _bannieres[i]['id'], 'ordre': i + 1},
    );
    try {
      await _admin.reordonnerBannieresAdmin(ordre);
      if (!mounted) return;
      await context.read<AppConfigProvider>().reload();
    } catch (_) {
      await _refreshBannieres();
    }
  }

  Future<void> _showAddBanniereDialog({Map<String, dynamic>? banniere}) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _BanniereDialog(
        banniere: banniere,
        onSave: (payload) async {
          try {
            final id = banniere?['id']?.toString();
            if (id == null || id.isEmpty) {
              await _admin.createBanniereAdmin(
                fields: payload.map(
                  (k, v) => MapEntry(k, (v ?? '').toString()),
                ),
              );
            } else {
              await _admin.updateBanniereAdmin(id, payload);
            }
            if (!mounted) return;
            await _refreshAllBannieres();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  id == null ? 'Bannière créée' : 'Bannière mise à jour',
                ),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(e.toString())));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingParams) {
      return ResponsiveContainer(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: const AdminSettingsShimmer(),
        ),
      );
    }
    if (_loadError != null) {
      return ResponsiveContainer(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadParametres,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    return ResponsiveContainer(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 86),
            child: LayoutBuilder(
              builder: (context, c) {
                final mobile = c.maxWidth < 960;
                if (mobile) {
                  return RefreshIndicator(
                    color: const Color(0xFF1A56DB),
                    onRefresh: _loadParametres,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 14),
                        _buildSectionTabsMobile(),
                        const SizedBox(height: 12),
                        _buildSectionContent(),
                      ],
                    ),
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 228,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(compact: true),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ClipRect(
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildSectionMenuDesktop(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: RefreshIndicator(
                        color: const Color(0xFF1A56DB),
                        onRefresh: _loadParametres,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 8, right: 8, bottom: 8),
                          children: [_buildSectionContent()],
                        ),
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
            child: Material(
              elevation: 8,
              shadowColor: Colors.black26,
              color: Colors.white,
              child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Icon(
                    _hasUnsavedChanges ? Icons.circle : Icons.check_circle,
                    size: 14,
                    color: _hasUnsavedChanges
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _hasUnsavedChanges
                        ? 'Modifications non sauvegardées'
                        : 'Tous les changements sont sauvegardés',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _hasUnsavedChanges && !_saving ? _save : null,
                    icon: _saving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Sauvegarde...' : 'Sauvegarder'),
                  ),
                ],
              ),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(_sections.length, (i) {
          final s = _sections[i];
          final selected = i == _sectionIndex;
          return Material(
            color: Colors.transparent,
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              selected: selected,
              selectedTileColor: const Color(0xFFEFF6FF),
              leading: Icon(
                s.icon,
                size: 22,
                color: selected
                    ? const Color(0xFF1A56DB)
                    : const Color(0xFF64748B),
              ),
              title: Text(
                s.title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: selected
                      ? const Color(0xFF1A56DB)
                      : const Color(0xFF334155),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              onTap: () => setState(() => _sectionIndex = i),
            ),
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
        return _buildLogoSection();
      case 2:
        return _buildBannieresSection();
      case 3:
        return _buildAccountsSection();
      case 4:
        return _buildNotificationsSection();
      case 5:
        return _buildAiSection();
      case 6:
        return _buildSecuritySection();
      case 7:
        return _buildFooterSection();
      case 8:
        return _buildMaintenanceSection();
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
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _labelWithTooltip(String label, String tooltip) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _InfoTooltip(tooltip),
      ],
    );
  }

  Widget _metricLabelWithTooltip({
    required String label,
    required String tooltip,
    required String valueText,
  }) {
    return Row(
      children: [
        Expanded(child: _labelWithTooltip(label, tooltip)),
        const SizedBox(width: 10),
        Text(
          valueText,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralSection() {
    return _sectionCard(
      title: 'Informations Générales',
      children: [
        const ThemeSelectorTile(),
        const SizedBox(height: 14),
        TextField(
          controller: _platformNameCtrl,
          decoration: const InputDecoration(labelText: 'Nom de la plateforme'),
          onChanged: (_) => _markChanged(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _descriptionCtrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Description'),
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
          decoration: const InputDecoration(labelText: 'Adresse (contact)'),
          onChanged: (_) => _markChanged(),
        ),
        const Divider(height: 28),
        const Text(
          'Tableau de bord candidat',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 6),
        const Text(
          'Une citation par ligne sert de repli si l’API externe est désactivée ou indisponible. '
          'Le serveur en choisit une par jour (variée par compte). Si le profil est complété à moins de 45 %, '
          'des messages d’encouragement sont mélangés aux citations locales uniquement.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _citationsTableauBordCandidatCtrl,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'Citations motivation (une par ligne)',
            alignLabelWithHint: true,
            hintText:
                'Le succès appartient à ceux qui commencent.\nChaque candidature est un pas vers votre réussite.',
          ),
          onChanged: (_) => _markChanged(),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _citationsApiActive,
          onChanged: (v) => setState(() {
            _citationsApiActive = v;
            _markChanged();
          }),
          title: _labelWithTooltip(
            'Citation du jour via API externe',
            'Si activé, le backend interroge le fournisseur choisi (HTTP, sans clé pour ZenQuotes / Quotable). '
            'En cas d’erreur ou de timeout, les lignes ci-dessus sont utilisées.',
          ),
        ),
        if (_citationsApiActive) ...[
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: _citationsApiSource,
            decoration: const InputDecoration(
              labelText: 'Fournisseur API',
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                value: 'zenquotes',
                child: Text('ZenQuotes (gratuit, sans clé)'),
              ),
              DropdownMenuItem(
                value: 'quotable',
                child: Text('Quotable (gratuit, sans clé)'),
              ),
              DropdownMenuItem(
                value: 'custom',
                child: Text('URL personnalisée (GET → JSON)'),
              ),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _citationsApiSource = v;
                _markChanged();
              });
            },
          ),
          if (_citationsApiSource == 'custom') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _citationsApiUrlCustomCtrl,
              decoration: const InputDecoration(
                labelText: 'URL complète (https://…)',
                hintText: 'https://api.example.com/quote',
                helperText:
                    'Réponse attendue : tableau [{ "q", "a" }] ou objet { "content", "author" }.',
              ),
              onChanged: (_) => _markChanged(),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildLogoSection() {
    return _sectionCard(
      title: 'Logo et identité',
      children: [
        ImageUploadWidget(
          currentImageUrl: _logoUrlCtrl.text.isEmpty ? null : _logoUrlCtrl.text,
          uploadUrl: '$apiBaseUrl$apiPrefix/admin/parametres/upload-logo',
          fieldName: 'logo',
          title: 'Logo principal',
          dimensionsInfo: '400 × 200 px (ratio 2:1)',
          acceptedFormats: 'PNG, SVG, WEBP, JPG',
          maxSizeMb: 5,
          previewHeight: 70,
          onUploaded: (url) {
            () async {
              setState(() {
                _logoUrlCtrl.text = url;
                _markChanged();
              });
              context.read<AppConfigProvider>().updateLogo(url);
              await context.read<AppConfigProvider>().reload();
              await _loadParametres();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Logo mis à jour ! Vérifiez la page d\'accueil.'),
                    ],
                  ),
                  backgroundColor: Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 4),
                ),
              );
            }();
          },
        ),
        const SizedBox(height: 16),
        ImageUploadWidget(
          currentImageUrl: _faviconUrlCtrl.text.isEmpty
              ? null
              : _faviconUrlCtrl.text,
          uploadUrl: '$apiBaseUrl$apiPrefix/admin/parametres/upload-logo',
          fieldName: 'logo',
          title: 'Favicon',
          dimensionsInfo: '32 × 32 px (format carré)',
          acceptedFormats: 'PNG, SVG, WEBP',
          maxSizeMb: 1,
          previewHeight: 40,
          onUploaded: (url) {
            () async {
              setState(() {
                _faviconUrlCtrl.text = url;
                _markChanged();
              });
              await _admin.updateParametres([
                {'cle': 'favicon_url', 'valeur': url},
              ]);
              await context.read<AppConfigProvider>().updateFavicon(url);
              await context.read<AppConfigProvider>().reload();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Favicon mis à jour. Rechargez l’onglet si besoin.',
                  ),
                  backgroundColor: Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }();
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _colorPrimaryCtrl,
          decoration: const InputDecoration(
            labelText: 'Couleur primaire (hex)',
            hintText: '#1A56DB',
          ),
          onChanged: (_) => _markChanged(),
        ),
      ],
    );
  }

  Widget _buildBannieresSection() {
    if (_bannieresLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return _sectionCard(
      title: 'Bannières page d’accueil',
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.aspect_ratio_outlined, color: Color(0xFF1D4ED8), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Dimensions recommandées : 1920 × 440 px (bande large, ratio ≈ 4,4:1). '
                  'Sur l’accueil, la zone visible fait environ 440 px de haut sur bureau et 300–400 px sur mobile : '
                  'placez texte et visuels importants au centre. Évitez le 16:9 plein cadre (trop haut rogné).',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    height: 1.45,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            FilledButton.icon(
              onPressed: _showAddBanniereDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: _refreshBannieres,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Actualiser'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_bannieres.isEmpty)
          Text(
            'Aucune bannière. Les visiteurs verront les données par défaut côté accueil si l’API est vide.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _bannieres.length,
            onReorder: _onReorderBanniere,
            itemBuilder: (context, i) {
              final b = _bannieres[i];
              final id = b['id']?.toString() ?? '$i';
              return Card(
                key: ValueKey(id),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.drag_handle),
                  title: Text(
                    b['titre']?.toString() ?? 'Sans titre',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    b['image_url']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: b['est_actif'] == true,
                        onChanged: (v) async {
                          try {
                            await _admin.updateBanniereAdmin(id, {
                              'est_actif': v,
                            });
                            await _refreshAllBannieres();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text('$e')));
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF1A56DB),
                        ),
                        onPressed: () => _showAddBanniereDialog(banniere: b),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFEF4444),
                        ),
                        onPressed: () async {
                          try {
                            await _admin.deleteBanniereAdmin(id);
                            await _refreshAllBannieres();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text('$e')));
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
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
          title: _labelWithTooltip(
            'Activer l’inscription libre',
            "Permet à n'importe qui de créer un compte (candidat/entreprise).",
          ),
        ),
        SwitchListTile(
          value: _autoValidation,
          onChanged: (v) => setState(() {
            _autoValidation = v;
            _markChanged();
          }),
          title: _labelWithTooltip(
            'Validation automatique des nouveaux comptes',
            'Si activé, les nouveaux comptes sont validés automatiquement. Sinon, un admin doit valider.',
          ),
        ),
        SwitchListTile(
          value: _offresPublicationAuto,
          onChanged: (v) => setState(() {
            _offresPublicationAuto = v;
            _markChanged();
          }),
          title: _labelWithTooltip(
            'Publication automatique des nouvelles offres',
            'Si activé, lorsqu’une entreprise clique sur « Publier », l’offre est mise en ligne tout de suite (statut publiée). Si désactivé, l’offre reste en attente de validation admin. Les notifications admin peuvent quand même être envoyées.',
          ),
        ),
        const SizedBox(height: 8),
        _metricLabelWithTooltip(
          label: 'Nombre max d’offres actives (gratuit)',
          tooltip:
              'Nombre max d’offres actives autorisées pour un compte entreprise gratuit. Au-delà: refus côté backend.',
          valueText: '$_maxOffersFree',
        ),
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
        _metricLabelWithTooltip(
          label: 'Durée de validité d’une offre',
          tooltip:
              "Après ce délai, l'offre peut expirer automatiquement (si aucune date limite n'est fournie).",
          valueText: '$_offerValidityDays jours',
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          title: 'Préférences de notifications',
          children: [
            SwitchListTile(
              value: _newApplicationEmail,
              onChanged: (v) => setState(() {
                _newApplicationEmail = v;
                _markChanged();
              }),
              title: _labelWithTooltip(
                'Email à chaque candidature',
                "L'entreprise reçoit un email à chaque nouvelle candidature (nécessite SMTP).",
              ),
            ),
            SwitchListTile(
              value: _validationEmail,
              onChanged: (v) => setState(() {
                _validationEmail = v;
                _markChanged();
              }),
              title: _labelWithTooltip(
                'Email de validation de compte',
                'Envoie un email lorsque le compte est validé par un administrateur (nécessite SMTP).',
              ),
            ),
            SwitchListTile(
              value: _weeklySummary,
              onChanged: (v) => setState(() {
                _weeklySummary = v;
                _markChanged();
              }),
              title: _labelWithTooltip(
                'Résumé hebdomadaire (email)',
                'Envoie chaque semaine un email aux candidats qui ont activé l’option dans leur profil (cron lundi, si SMTP actif).',
              ),
            ),
            SwitchListTile(
              value: _emailResetMdp,
              onChanged: (v) => setState(() {
                _emailResetMdp = v;
                _markChanged();
              }),
              title: _labelWithTooltip(
                'Email réinitialisation mot de passe',
                'Lien sécurisé « mot de passe oublié » (1 h).',
              ),
            ),
            SwitchListTile(
              value: _emailAlerteEmploiPlat,
              onChanged: (v) => setState(() {
                _emailAlerteEmploiPlat = v;
                _markChanged();
              }),
              title: _labelWithTooltip(
                'Email alertes emploi',
                'Quand une offre est publiée et correspond aux critères d’alerte d’un candidat.',
              ),
            ),
            SwitchListTile(
              value: _emailAnalyseCvPlat,
              onChanged: (v) => setState(() {
                _emailAnalyseCvPlat = v;
                _markChanged();
              }),
              title: _labelWithTooltip(
                'Email fin d’analyse CV',
                'Après analyse IA du CV (upload ou relance).',
              ),
            ),
            const Divider(height: 24),
            Text(
              'Autres emails (messagerie, modération, alertes)',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              value: _emailMessages,
              onChanged: (v) => setState(() {
                _emailMessages = v;
                _markChanged();
              }),
              title: _labelWithTooltip(
                'Email pour nouveaux messages',
                'Envoie un email au destinataire (respecte aussi « notifications par email » dans le profil utilisateur).',
              ),
            ),
            SwitchListTile(
              value: _emailOffreModeration,
              onChanged: (v) => setState(() {
                _emailOffreModeration = v;
                _markChanged();
              }),
              title: _labelWithTooltip(
                'Email modération des offres',
                'Le recruteur reçoit un email quand l’admin valide, refuse ou met en vedette une offre.',
              ),
            ),
            SwitchListTile(
              value: _emailAdminAlerts,
              onChanged: (v) => setState(() {
                _emailAdminAlerts = v;
                _markChanged();
              }),
              title: _labelWithTooltip(
                'Emails d’alerte aux administrateurs',
                'Nouvelle inscription à valider, offre en attente, signalement : copie par email pour chaque admin actif.',
              ),
            ),
            SwitchListTile(
              value: _emailConfirmationCandidature,
              onChanged: (v) => setState(() {
                _emailConfirmationCandidature = v;
                _markChanged();
              }),
              title: _labelWithTooltip(
                'Confirmation candidature (candidat)',
                'Email au candidat après chaque candidature enregistrée.',
              ),
            ),
            SwitchListTile(
              value: _emailCompteRejete,
              onChanged: (v) => setState(() {
                _emailCompteRejete = v;
                _markChanged();
              }),
              title: _labelWithTooltip(
                'Email compte rejeté',
                'Envoie un email si un administrateur rejette une inscription.',
              ),
            ),
            SwitchListTile(
              value: _emailStatutCandidature,
              onChanged: (v) => setState(() {
                _emailStatutCandidature = v;
                _markChanged();
              }),
              title: _labelWithTooltip(
                'Email évolution candidature (candidat)',
                'Quand le recruteur ou l’admin change le statut (examen, entretien, acceptée, refusée), le candidat reçoit un email et une notification in-app.',
              ),
            ),
            SwitchListTile(
              value: _emailSignalementResolution,
              onChanged: (v) => setState(() {
                _emailSignalementResolution = v;
                _markChanged();
              }),
              title: _labelWithTooltip(
                'Email résolution signalement',
                'Quand un admin traite ou classe un signalement, l’auteur du signalement reçoit un email et une notification in-app.',
              ),
            ),
            SwitchListTile(
              value: _emailSignalementConcerne,
              onChanged: (v) => setState(() {
                _emailSignalementConcerne = v;
                _markChanged();
              }),
              title: _labelWithTooltip(
                'Email personne concernée (signalement)',
                'Quand la modération clôture le dossier, la personne concernée (auteur de l’offre, du profil signalé ou candidat lié à la candidature) reçoit aussi un email et une notification in-app — sauf si c’est la même personne que le signalant.',
              ),
            ),
            SwitchListTile(
              value: _emailAnnulationCandidatureRecruteur,
              onChanged: (v) => setState(() {
                _emailAnnulationCandidatureRecruteur = v;
                _markChanged();
              }),
              title: _labelWithTooltip(
                'Email annulation candidature (recruteur)',
                'Si le candidat retire sa candidature, le compte entreprise reçoit un email et une notification in-app.',
              ),
            ),
          ],
        ),
        _sectionCard(
          title: 'Service SMTP',
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Text(
                'Pour envoyer de vrais emails, configurez SMTP (Gmail, SendGrid, Mailgun…).',
                style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              value: _emailServiceActif,
              onChanged: (v) => setState(() {
                _emailServiceActif = v;
                _markChanged();
              }),
              title: _labelWithTooltip(
                'Activer l’envoi d’emails',
                'Active/désactive l’envoi SMTP sur la plateforme.',
              ),
              subtitle: const Text('Nécessite une configuration SMTP valide'),
            ),
            TextField(
              controller: _smtpHostCtrl,
              decoration: const InputDecoration(
                labelText: 'Hôte SMTP (ex: smtp.gmail.com)',
              ),
              onChanged: (_) => _markChanged(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _smtpPortCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Port SMTP'),
              onChanged: (_) => _markChanged(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _smtpUserCtrl,
              decoration: const InputDecoration(
                labelText: 'Email expéditeur SMTP',
              ),
              onChanged: (_) => _markChanged(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _smtpPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mot de passe SMTP'),
              onChanged: (_) => _markChanged(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailSenderNameCtrl,
              decoration: const InputDecoration(labelText: 'Nom expéditeur'),
              onChanged: (_) => _markChanged(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: _smtpTestLoading ? null : _testSmtp,
                  icon: _smtpTestLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.outgoing_mail, size: 18),
                  label: const Text('Tester SMTP (envoi)'),
                ),
              ],
            ),
            if (_smtpTestMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _smtpTestMessage!,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ],
        ),
        _sectionCard(
          title: 'Emails transactionnels — liens & enveloppe',
          children: [
            const Text(
              'URL utilisée dans les liens (reset MDP, alertes, etc.). Ex. https://app.votredomaine.gn',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _publicAppUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL application publique',
              ),
              onChanged: (_) => _markChanged(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailMailAccentCtrl,
              decoration: const InputDecoration(
                labelText: 'Couleur accent emails (hex)',
                hintText: '#1A56DB',
              ),
              onChanged: (_) => _markChanged(),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enveloppe HTML : placez {{CONTENU}} (ou {{contenu}}) pour le corps. '
              '{{plateforme}} et {{couleur_primaire}} sont remplacés automatiquement (alignés sur la couleur accent ci-dessus).',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailWrapperCtrl,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Wrapper HTML (optionnel)',
                alignLabelWithHint: true,
              ),
              onChanged: (_) => _markChanged(),
            ),
            const SizedBox(height: 12),
            const Text(
              'Sujets : laisser vide = texte par défaut côté serveur. Syntaxe : {{nom_variable}} (espaces autorisés dans les accolades).',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tplResetMdpSubjectCtrl,
              decoration: const InputDecoration(
                labelText: 'Sujet — reset mot de passe',
                helperText: '{{plateforme}}, {{nom}}',
              ),
              onChanged: (_) => _markChanged(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tplAlerteOffreSubjectCtrl,
              decoration: const InputDecoration(
                labelText: 'Sujet — alerte offre',
                helperText:
                    '{{titre_offre}} ou {{poste}}, {{entreprise_nom}}, {{nom}}, {{plateforme}}',
              ),
              onChanged: (_) => _markChanged(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tplResumeHebdoMailSubjectCtrl,
              decoration: const InputDecoration(
                labelText: 'Sujet — résumé hebdo',
                helperText: '{{plateforme}}, {{nom}}, {{nb_offres}}',
              ),
              onChanged: (_) => _markChanged(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tplAnalyseCvSubjectCtrl,
              decoration: const InputDecoration(
                labelText: 'Sujet — analyse CV',
                helperText: '{{plateforme}}, {{nom}}',
              ),
              onChanged: (_) => _markChanged(),
            ),
          ],
        ),
        _sectionCard(
          title: 'Template email de bienvenue',
          children: [
            const Text(
              'Bienvenue / validation : {{nom}}, {{email}}, {{role}}, {{plateforme}}',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Candidature (e-mail au recruteur) : {{titre_offre}}, {{poste}}, {{offre_titre}}, {{candidat_nom}}, {{plateforme}} (synonymes acceptés).',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tplWelcomeSubjectCtrl,
              decoration: const InputDecoration(
                labelText: 'Sujet',
                hintText: 'Bienvenue sur EmploiConnect, {{nom}} !',
              ),
              onChanged: (_) => _markChanged(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tplWelcomeBodyCtrl,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Corps du message',
                alignLabelWithHint: true,
                hintText: 'Bonjour {{nom}},\n\nVotre compte {{role}} est prêt. Connectez-vous avec {{email}}.\n\nL’équipe EmploiConnect',
              ),
              onChanged: (_) => _markChanged(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tplCandidatureSubjectCtrl,
              decoration: const InputDecoration(
                labelText: 'Sujet email candidature',
                hintText: 'Nouvelle candidature pour « {{titre_offre}} »',
                helperText: '{{titre_offre}} = titre du poste affiché dans le sujet',
              ),
              onChanged: (_) => _markChanged(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tplValidationSubjectCtrl,
              decoration: const InputDecoration(
                labelText: 'Sujet email validation',
                hintText: 'Votre compte entreprise est validé',
              ),
              onChanged: (_) => _markChanged(),
            ),
          ],
        ),
      ],
    );
  }

  String _anthropicModelForDropdown() {
    final m = _anthropicModel.trim();
    if (m.isEmpty) return 'claude-haiku-4-5-20251001';
    return m;
  }

  List<DropdownMenuItem<String>> _anthropicModelDropdownItems() {
    final m = _anthropicModel.trim();
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(
        value: 'claude-haiku-4-5-20251001',
        child: Text('Claude Haiku (rapide, économique)'),
      ),
      const DropdownMenuItem(
        value: 'claude-sonnet-4-6',
        child: Text('Claude Sonnet (meilleur résultat)'),
      ),
    ];
    if (m.isNotEmpty && !_knownAnthropicModels.contains(m)) {
      items.add(
        DropdownMenuItem(
          value: m,
          child: Text(
            m,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
    return items;
  }

  Widget _buildAiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          title: 'Guide RapidAPI (3 APIs)',
          children: [
            const Text(
              'Abonnez-vous aux 3 APIs RapidAPI suivantes, avec une seule clé :',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            _infoLine(
              'Resume Parser',
              'resume-parser3.p.rapidapi.com (POST /resume/parse)',
            ),
            _infoLine(
              'Text Similarity',
              'twinword-text-similarity-v1.p.rapidapi.com (GET /similarity)',
            ),
            _infoLine(
              'Topic Tagging',
              'twinword-topic-tagging1.p.rapidapi.com (GET /classify)',
            ),
          ],
        ),
        _sectionCard(
          title: 'Provider',
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'rapidapi', label: Text('RapidAPI')),
                ButtonSegment(value: 'openai', label: Text('OpenAI')),
                ButtonSegment(value: 'local', label: Text('Local')),
              ],
              selected: {_iaProvider},
              onSelectionChanged: (s) {
                setState(() {
                  _iaProvider = s.first;
                  _markChanged();
                });
              },
            ),
          ],
        ),
        _sectionCard(
          title: 'Clés RapidAPI',
          children: [
            TextField(
              controller: _rapidApiKeyCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Clé RapidAPI',
                suffixIcon: _InfoTooltip(
                  'Clé API utilisée pour les 3 services RapidAPI. Elle est stockée chiffrée côté backend.',
                ),
              ),
              onChanged: (_) => _markChanged(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _similarityHostCtrl,
              decoration: const InputDecoration(
                labelText:
                    'Host similarité (ex: twinword-text-similarity-v1.p.rapidapi.com)',
              ),
              onChanged: (_) => _markChanged(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _parserHostCtrl,
              decoration: const InputDecoration(
                labelText: 'Host parser CV (ex: resume-parser3.p.rapidapi.com)',
              ),
              onChanged: (_) => _markChanged(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _topicTaggingHostCtrl,
              decoration: const InputDecoration(
                labelText:
                    'Host extraction mots-clés (ex: twinword-topic-tagging1.p.rapidapi.com)',
              ),
              onChanged: (_) => _markChanged(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _iaTestLoading ? null : _testIa,
                  icon: _iaTestLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.wifi_tethering, size: 18),
                  label: const Text('Tester la connexion'),
                ),
              ],
            ),
            if (_iaTestMessage != null) ...[
              const SizedBox(height: 10),
              Text(_iaTestMessage!, style: GoogleFonts.inter(fontSize: 13)),
            ],
            if (_iaTestResult != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _iaTestResult!['success'] == true
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _iaTestResult!['success'] == true
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _iaTestResult!['message']?.toString() ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _iaTestResult!['success'] == true
                            ? const Color(0xFF065F46)
                            : const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...(((_iaTestResult!['data']?['tests'] as Map?)?.entries ?? const [])
                        .map((e) {
                      final value = e.value;
                      final status = value is Map
                          ? (value['status'] as String? ?? '')
                          : '';
                      final isOk = status.startsWith('✅');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              isOk
                                  ? Icons.check_circle_outline
                                  : Icons.warning_amber_outlined,
                              size: 14,
                              color: isOk
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${e.key.toString().toUpperCase()} : $status',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList()),
                  ],
                ),
              ),
            ],
          ],
        ),
        _sectionCard(
          title: 'Intelligence Artificielle — Amélioration textes',
          children: [
            Text(
              'Utilisée pour améliorer le champ « À propos » des candidats. '
              'Enregistrez les paramètres avant de tester si vous venez de les modifier.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _iaAmeliorationProvider,
              decoration: const InputDecoration(
                labelText: 'Provider IA',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'anthropic',
                  child: Text('🟣 Anthropic Claude (Recommandé)'),
                ),
                DropdownMenuItem(
                  value: 'openai',
                  child: Text('🟢 OpenAI ChatGPT'),
                ),
                DropdownMenuItem(
                  value: 'local',
                  child: Text('⚙️ Texte de secours local (Sans IA)'),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _iaAmeliorationProvider = v;
                  _markChanged();
                });
              },
            ),
            const SizedBox(height: 16),
            if (_iaAmeliorationProvider == 'anthropic') ...[
              TextField(
                controller: _anthropicApiKeyCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Clé API Anthropic',
                  hintText: 'sk-ant-api03-...',
                ),
                onChanged: (_) => _markChanged(),
              ),
              const SizedBox(height: 4),
              Text(
                'Obtenir sur console.anthropic.com → API Keys',
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _anthropicModelForDropdown(),
                decoration: const InputDecoration(labelText: 'Modèle Claude'),
                items: _anthropicModelDropdownItems(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _anthropicModel = v;
                    _markChanged();
                  });
                },
              ),
            ],
            if (_iaAmeliorationProvider == 'openai') ...[
              TextField(
                controller: _openaiKeyCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Clé API OpenAI',
                  hintText: 'sk-proj-...',
                ),
                onChanged: (_) => _markChanged(),
              ),
              const SizedBox(height: 4),
              Text(
                'Obtenir sur platform.openai.com → API Keys',
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Modèle utilisé : GPT-3.5-turbo',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_iaAmeliorationProvider == 'local')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mode local : l\'amélioration de texte utilisera des règles prédéfinies sans IA externe.',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 24),
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scoring IA des offres',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Claude analyse la compatibilité profil ↔ offre',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _iaMatchingActif,
                  activeThumbColor: const Color(0xFF8B5CF6),
                  onChanged: (v) {
                    setState(() {
                      _iaMatchingActif = v;
                      _markChanged();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF7C3AED),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Claude utilise la même clé pour améliorer les textes ET calculer la compatibilité des offres.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF6D28D9),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_iaAmeliorationProvider != 'local') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Le test utilise un texte d\'exemple fictif (pas de données de candidats réels).',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: _isTestingIA
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.play_arrow_rounded, size: 16),
                  label: Text(_isTestingIA ? 'Test en cours...' : 'Tester l\'IA'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF8B5CF6)),
                    foregroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isTestingIA ? null : _testerIaTexteApropos,
                ),
              ),
            ],
          ],
        ),
        _sectionCard(
          title: 'Matching',
          children: [
            SwitchListTile(
              value: _aiSuggestions,
              onChanged: (v) => setState(() {
                _aiSuggestions = v;
                _markChanged();
              }),
              title: _labelWithTooltip(
                'Suggestions automatiques',
                'Active les suggestions automatiques (recommandations) basées sur le matching.',
              ),
            ),
            _metricLabelWithTooltip(
              label: 'Seuil minimum de matching',
              tooltip:
                  'Les offres sous ce score ne sont pas suggérées (filtre de pertinence).',
              valueText: '${_matchingThreshold.round()}%',
            ),
            Slider(
              min: 0,
              max: 100,
              value: _matchingThreshold.clamp(0, 100),
              onChanged: (v) => setState(() {
                _matchingThreshold = v;
                _markChanged();
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoLine(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return _sectionCard(
      title: 'Sécurité',
      children: [
        _metricLabelWithTooltip(
          label: 'Durée de session',
          tooltip:
              'Durée avant déconnexion automatique (inactivité / expiration session).',
          valueText: '${_sessionMinutes.round()} min',
        ),
        Slider(
          min: 15,
          max: 1440,
          divisions: 45,
          value: _sessionMinutes.clamp(15, 1440),
          onChanged: (v) => setState(() {
            _sessionMinutes = v;
            _markChanged();
          }),
        ),
        _metricLabelWithTooltip(
          label: 'Tentatives max connexion',
          tooltip:
              'Blocage temporaire après N échecs de connexion (limitation anti-bruteforce).',
          valueText: '${_maxLoginAttempts.round()}',
        ),
        Slider(
          min: 3,
          max: 10,
          divisions: 7,
          value: _maxLoginAttempts.clamp(3, 10),
          onChanged: (v) => setState(() {
            _maxLoginAttempts = v;
            _markChanged();
          }),
        ),
        _metricLabelWithTooltip(
          label: 'Expiration JWT',
          tooltip: 'Durée de validité du token JWT (heures).',
          valueText: '${_jwtExpirationHours.round()} h',
        ),
        Slider(
          min: 1,
          max: 168,
          divisions: 40,
          value: _jwtExpirationHours.clamp(1, 168),
          onChanged: (v) => setState(() {
            _jwtExpirationHours = v;
            _markChanged();
          }),
        ),
        SwitchListTile(
          value: _admin2fa,
          onChanged: (v) => setState(() {
            _admin2fa = v;
            _markChanged();
          }),
          title: _labelWithTooltip(
            '2FA pour les administrateurs',
            'Ajoute une seconde étape (TOTP type Google Authenticator) pour les comptes admin.',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'IPs bloquées (une par ligne)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            _InfoTooltip(
              'Ces adresses IP ne peuvent pas accéder à l’API (blocage global).',
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _ipsBlockedCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: '192.168.1.1',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _markChanged(),
        ),
      ],
    );
  }

  Widget _buildFooterSection() {
    return _sectionCard(
      title: 'Pied de page et réseaux',
      children: [
        Text(
          "Ces informations s'affichent directement dans le footer de la page d'accueil.",
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 14),
        _sectionCard(
          title: 'Contact public',
          children: [
            _footerField(
              controller: _footerTaglineCtrl,
              label: 'Tagline',
              hint: "La plateforme intelligente de l'emploi en Guinée",
              tooltip: 'Texte accrocheur affiché sous le logo dans le footer.',
            ),
            _footerField(
              controller: _footerEmailCtrl,
              label: 'Email public',
              hint: 'contact@example.com',
              tooltip: 'Email affiché dans le footer (contact public).',
            ),
            _footerField(
              controller: _footerPhoneCtrl,
              label: 'Téléphone public',
              hint: '+224 620 00 00 00',
              tooltip: 'Téléphone affiché dans le footer (contact public).',
            ),
            _footerField(
              controller: _footerAdresseCtrl,
              label: 'Adresse',
              hint: 'Conakry, République de Guinée',
              maxLines: 2,
              tooltip: 'Adresse affichée dans le footer (contact public).',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Réseaux sociaux',
          children: [
            _footerField(
              controller: _footerLinkedinCtrl,
              label: 'LinkedIn URL',
              hint: 'https://linkedin.com/company/emploiconnect',
              tooltip: 'URL de votre page LinkedIn.',
            ),
            _footerField(
              controller: _footerFacebookCtrl,
              label: 'Facebook URL',
              hint: 'https://facebook.com/emploiconnect',
              tooltip: 'URL de votre page Facebook.',
            ),
            _footerField(
              controller: _footerTwitterCtrl,
              label: 'Twitter / X URL',
              hint: 'https://twitter.com/emploiconnect',
              tooltip: 'URL de votre compte Twitter/X.',
            ),
            _footerField(
              controller: _footerInstagramCtrl,
              label: 'Instagram URL',
              hint: 'https://instagram.com/emploiconnect',
              tooltip: 'URL de votre compte Instagram.',
            ),
            _footerField(
              controller: _footerWhatsappCtrl,
              label: 'WhatsApp',
              hint: '+224 620 00 00 00',
              tooltip:
                  'Numéro WhatsApp Business (format international recommandé).',
            ),
          ],
        ),
      ],
    );
  }

  Widget _footerField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String tooltip,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: _InfoTooltip(tooltip),
        ),
        onChanged: (_) => _markChanged(),
      ),
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
          title: _labelWithTooltip(
            'Mode maintenance',
            'Affiche un bandeau et bloque les APIs publiques (admin/auth/health restent accessibles).',
          ),
        ),
        TextField(
          controller: _maintenanceMessageCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Message affiché',
            suffixIcon: _InfoTooltip(
              'Message affiché dans la bannière maintenance (haut de l’app).',
            ),
          ),
          onChanged: (_) => _markChanged(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  await _admin.viderCacheParametres();
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Cache vidé')));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              icon: const Icon(Icons.cleaning_services_outlined),
              label: const Text('Vider le cache'),
            ),
          ],
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

class _InfoTooltip extends StatelessWidget {
  const _InfoTooltip(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      preferBelow: false,
      textStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: const Icon(
        Icons.info_outline_rounded,
        size: 16,
        color: Color(0xFF94A3B8),
      ),
    );
  }
}

class _BanniereDialog extends StatefulWidget {
  const _BanniereDialog({required this.onSave, this.banniere});

  final Map<String, dynamic>? banniere;
  final Future<void> Function(Map<String, dynamic>) onSave;

  @override
  State<_BanniereDialog> createState() => _BanniereDialogState();
}

class _BanniereDialogState extends State<_BanniereDialog> {
  final _titreCtrl = TextEditingController();
  final _sousTitreCtrl = TextEditingController();
  final _badgeCtrl = TextEditingController();
  final _labelCta1Ctrl = TextEditingController();
  final _lienCta1Ctrl = TextEditingController();
  final _labelCta2Ctrl = TextEditingController();
  final _lienCta2Ctrl = TextEditingController();
  String? _imageUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.banniere;
    if (b != null) {
      _titreCtrl.text = b['titre']?.toString() ?? '';
      _sousTitreCtrl.text = b['sous_titre']?.toString() ?? '';
      _badgeCtrl.text = b['texte_badge']?.toString() ?? '';
      _labelCta1Ctrl.text = b['label_cta_1']?.toString() ?? '';
      _lienCta1Ctrl.text = b['lien_cta_1']?.toString() ?? '';
      _labelCta2Ctrl.text = b['label_cta_2']?.toString() ?? '';
      _lienCta2Ctrl.text = b['lien_cta_2']?.toString() ?? '';
      _imageUrl = b['image_url']?.toString();
    }
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _sousTitreCtrl.dispose();
    _badgeCtrl.dispose();
    _labelCta1Ctrl.dispose();
    _lienCta1Ctrl.dispose();
    _labelCta2Ctrl.dispose();
    _lienCta2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 640,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                children: [
                  Text(
                    widget.banniere == null
                        ? 'Ajouter une bannière'
                        : 'Modifier la bannière',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dialogLabel('Image de fond *'),
                    const SizedBox(height: 8),
                    ImageUploadWidget(
                      currentImageUrl: _imageUrl,
                      uploadUrl:
                          '$apiBaseUrl$apiPrefix/admin/bannieres/upload-image',
                      fieldName: 'image',
                      title: 'Image de bannière',
                      dimensionsInfo:
                          '1920 × 440 px (bande large) — affichage accueil ≈ 440 px haut (bureau), 300–400 px (mobile)',
                      acceptedFormats: 'JPG, PNG, WEBP',
                      maxSizeMb: 10,
                      previewHeight: 120,
                      onUploaded: (url) => setState(() => _imageUrl = url),
                    ),
                    const SizedBox(height: 16),
                    _dialogLabel('Badge'),
                    const SizedBox(height: 6),
                    _dialogField(
                      _badgeCtrl,
                      'Ex: 🇬🇳 Plateforme N°1 en Guinée',
                    ),
                    const SizedBox(height: 14),
                    _dialogLabel('Titre principal *'),
                    const SizedBox(height: 6),
                    _dialogField(
                      _titreCtrl,
                      'Ex: Trouvez l\'Emploi de Vos Rêves',
                    ),
                    const SizedBox(height: 14),
                    _dialogLabel('Sous-titre'),
                    const SizedBox(height: 6),
                    _dialogField(
                      _sousTitreCtrl,
                      'Description courte',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    _dialogLabel('Bouton principal (CTA 1)'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _dialogField(_labelCta1Ctrl, 'Label CTA 1'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dialogField(
                            _lienCta1Ctrl,
                            'Lien CTA 1 (ex: /offres)',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _dialogLabel('Bouton secondaire (CTA 2)'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _dialogField(_labelCta2Ctrl, 'Label CTA 2'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dialogField(_lienCta2Ctrl, 'Lien CTA 2'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed:
                          (_isSaving || _imageUrl == null || _imageUrl!.isEmpty)
                          ? null
                          : () async {
                              setState(() => _isSaving = true);
                              await widget.onSave({
                                'image_url': _imageUrl,
                                'texte_badge': _badgeCtrl.text.trim(),
                                'titre': _titreCtrl.text.trim(),
                                'sous_titre': _sousTitreCtrl.text.trim(),
                                'label_cta_1': _labelCta1Ctrl.text.trim(),
                                'lien_cta_1': _lienCta1Ctrl.text.trim(),
                                'label_cta_2': _labelCta2Ctrl.text.trim(),
                                'lien_cta_2': _lienCta2Ctrl.text.trim(),
                              });
                              if (!mounted) return;
                              Navigator.pop(context);
                            },
                      child: Text(
                        widget.banniere == null
                            ? 'Créer la bannière'
                            : 'Sauvegarder',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogLabel(String text) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF374151),
    ),
  );

  Widget _dialogField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
  }) => TextFormField(
    controller: ctrl,
    maxLines: maxLines,
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1A56DB), width: 1.5),
      ),
    ),
  );
}
