import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../providers/admin_provider.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../shared/widgets/image_upload_widget.dart';
import '../../shared/widgets/theme_selector_tile.dart';
import '../../widgets/responsive_container.dart';
import 'widgets/admin_page_shimmer.dart';
import 'widgets/illustration_ia_settings_widget.dart';
import '../auth/admin_two_factor_code_dialog.dart';

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
  final _newsletterFeatureSemaineCtrl = TextEditingController();
  final _newsletterPromptBaseCtrl = TextEditingController();
  final _contexteLibreCtrl = TextEditingController();

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
  bool _newsletterActif = true;
  bool _newsletterIaActif = false;
  int _newsletterIaSeuilOffres = 3;
  String _newsletterType = 'hebdomadaire';
  bool _isLancerIA = false;
  String? _resultatIA;
  bool _resultatOk = false;
  bool _contenuLoading = false;
  int _newsletterAbonnesActifs = 0;
  List<Map<String, dynamic>> _aproposSections = [];

  bool _aiSuggestions = false;
  double _matchingThreshold = 0;

  bool _maintenanceMode = false;
  bool _admin2fa = false;
  double _sessionMinutes = 0;
  double _maxLoginAttempts = 0;
  double _jwtExpirationHours = 24;

  bool _twoFaUserActif = false;
  bool _twoFaSetupPending = false;
  bool _twoFaStatusLoading = false;
  bool _twoFaActionLoading = false;

  List<Map<String, dynamic>> _bannieres = [];
  bool _bannieresLoading = false;
  bool _iaTestLoading = false;
  String? _iaTestMessage;
  Map<String, dynamic>? _iaTestResult;
  bool _isTestingIA = false;
  String _iaAmeliorationProvider = 'anthropic';
  String _anthropicModel = 'claude-haiku-4-5-20251001';
  bool _iaMatchingActif = true;
  bool _iaSimulateurParcoursActif = true;
  bool _iaCalculateurParcoursActif = true;

  bool _apiTestClaudeEnCours = false;
  bool _apiTestOpenaiEnCours = false;
  bool _apiTestDalleEnCours = false;
  String? _apiTestClaudeMsg;
  String? _apiTestOpenaiMsg;
  String? _apiTestDalleMsg;
  bool _apiTestClaudeOk = false;
  bool _apiTestOpenaiOk = false;
  bool _apiTestDalleOk = false;

  final _googleClientIdCtrl = TextEditingController();
  final _googleClientSecretCtrl = TextEditingController();
  final _googleProjetCtrl = TextEditingController();
  final _googleDomainesCtrl = TextEditingController();
  final _appUrlProdCtrl = TextEditingController();
  bool _googleOauthActif = true;
  String _googleRolesDefaut = 'chercheur';
  bool _isTesting = false;
  bool _isSavingOAuth = false;
  String _redirectUriAuto = '';
  Map<String, dynamic>? _testResultat;
  bool _guideExpanded = false;

  /// Infra (Super Admin) — affichage masqué + buckets.
  Map<String, dynamic> _configServeur = {};
  Map<String, bool> _bucketExists = {};
  Map<String, bool> _bucketPublic = {};
  bool _testSupabaseEnCours = false;
  bool? _testSupabaseOk;
  String? _testSupabaseResultat;
  final _serverPortInfraCtrl = TextEditingController();
  bool _savingInfra = false;
  String _portEnvHint = '';

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
    _SettingsSection('Authentification', Icons.login_rounded),
    _SettingsSection('Notifications', Icons.notifications_active_outlined),
    _SettingsSection('IA & Matching', Icons.auto_awesome_outlined),
    _SettingsSection('Sécurité', Icons.shield_outlined),
    _SettingsSection('Contenu', Icons.article_outlined),
    _SettingsSection('Pied de page', Icons.language_outlined),
    _SettingsSection('Infrastructure', Icons.dns_rounded),
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
        _iaSimulateurParcoursActif =
            _boolNotifDefaultTrue(_param(grouped, 'ia_simulateur_actif'));
        _iaCalculateurParcoursActif =
            _boolNotifDefaultTrue(_param(grouped, 'ia_calculateur_actif'));
        _googleClientIdCtrl.text =
            _param(grouped, 'google_client_id')?.toString() ?? '';
        _googleClientSecretCtrl.text =
            _param(grouped, 'google_client_secret')?.toString() ?? '';
        _googleOauthActif = _boolNotifDefaultTrue(_param(grouped, 'google_oauth_actif'));
        final grd =
            _param(grouped, 'google_roles_defaut')?.toString().trim().toLowerCase() ??
            'chercheur';
        _googleRolesDefaut = grd == 'entreprise' ? 'entreprise' : 'chercheur';
        _googleDomainesCtrl.text =
            _param(grouped, 'google_domaines_autorises')?.toString() ?? '';
        _googleProjetCtrl.text =
            _param(grouped, 'google_projet_id')?.toString() ?? '';
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
        _newsletterActif = () {
          final v = _param(grouped, 'newsletter_actif');
          if (v == null) return true;
          return _boolFromParam(v);
        }();
        _newsletterIaActif = _boolFromParam(
          _param(grouped, 'newsletter_ia_actif'),
        );
        _newsletterIaSeuilOffres =
            int.tryParse(_param(grouped, 'newsletter_ia_seuil_offres')?.toString() ?? '') ?? 3;
        _newsletterFeatureSemaineCtrl.text =
            _param(grouped, 'newsletter_feature_semaine')?.toString() ?? '';
        _newsletterPromptBaseCtrl.text =
            _param(grouped, 'newsletter_prompt_base')?.toString() ?? '';
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
        _serverPortInfraCtrl.text =
            _param(grouped, 'server_port')?.toString() ?? '';

        _loadingParams = false;
        _hasUnsavedChanges = false;
      });
      await _loadOAuthConfig();
      await _refreshContentSectionData();
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
    _googleClientIdCtrl.dispose();
    _googleClientSecretCtrl.dispose();
    _googleProjetCtrl.dispose();
    _googleDomainesCtrl.dispose();
    _appUrlProdCtrl.dispose();
    _serverPortInfraCtrl.dispose();
    _newsletterFeatureSemaineCtrl.dispose();
    _newsletterPromptBaseCtrl.dispose();
    _contexteLibreCtrl.dispose();
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
        {'cle': 'newsletter_actif', 'valeur': _newsletterActif},
        {'cle': 'newsletter_ia_actif', 'valeur': _newsletterIaActif},
        {'cle': 'newsletter_ia_seuil_offres', 'valeur': _newsletterIaSeuilOffres},
        {
          'cle': 'newsletter_feature_semaine',
          'valeur': _newsletterFeatureSemaineCtrl.text.trim(),
        },
        {
          'cle': 'newsletter_prompt_base',
          'valeur': _newsletterPromptBaseCtrl.text.trim(),
        },
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
        {'cle': 'ia_simulateur_actif', 'valeur': _iaSimulateurParcoursActif},
        {'cle': 'ia_calculateur_actif', 'valeur': _iaCalculateurParcoursActif},
        {'cle': 'google_oauth_actif', 'valeur': _googleOauthActif},
        {'cle': 'google_roles_defaut', 'valeur': _googleRolesDefaut},
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
        {'cle': 'app_url_prod', 'valeur': _appUrlProdCtrl.text.trim()},
        {'cle': 'server_port', 'valeur': _serverPortInfraCtrl.text.trim()},
      ]);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _hasUnsavedChanges = false;
      });
      context.read<AdminProvider>().loadDashboard();
      await _loadParametres();
      if (!mounted) return;
      await context.read<AppConfigProvider>().reload();
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

  Future<void> _testApiClaudeIsole() async {
    setState(() {
      _apiTestClaudeEnCours = true;
      _apiTestClaudeMsg = null;
    });
    try {
      final m = await _admin.postAdminTestIa('anthropic');
      if (!mounted) return;
      setState(() {
        _apiTestClaudeOk = m['success'] == true;
        _apiTestClaudeMsg = _apiTestClaudeOk
            ? (m['message']?.toString() ?? 'Claude OK')
            : (m['message']?.toString() ?? 'Échec');
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _apiTestClaudeOk = false;
          _apiTestClaudeMsg = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _apiTestClaudeEnCours = false);
    }
  }

  Future<void> _testApiOpenaiIsole() async {
    setState(() {
      _apiTestOpenaiEnCours = true;
      _apiTestOpenaiMsg = null;
    });
    try {
      final m = await _admin.postAdminTestIa('openai');
      if (!mounted) return;
      setState(() {
        _apiTestOpenaiOk = m['success'] == true;
        _apiTestOpenaiMsg = _apiTestOpenaiOk
            ? (m['message']?.toString() ?? 'OpenAI OK')
            : (m['message']?.toString() ?? 'Échec');
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _apiTestOpenaiOk = false;
          _apiTestOpenaiMsg = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _apiTestOpenaiEnCours = false);
    }
  }

  Future<void> _testApiDalleIsole() async {
    setState(() {
      _apiTestDalleEnCours = true;
      _apiTestDalleMsg = null;
    });
    try {
      final m = await _admin.postAdminTestDalle();
      if (!mounted) return;
      setState(() {
        _apiTestDalleOk = m['success'] == true;
        _apiTestDalleMsg = _apiTestDalleOk
            ? (m['message']?.toString() ?? 'DALL-E OK')
            : (m['message']?.toString() ?? 'Échec');
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _apiTestDalleOk = false;
          _apiTestDalleMsg = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _apiTestDalleEnCours = false);
    }
  }

  Widget _iaStatusBadgeRow({
    required String label,
    required bool actif,
    required bool cleConfigure,
  }) {
    final bg = actif
        ? const Color(0xFFECFDF5)
        : cleConfigure
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFF8FAFC);
    final border = actif
        ? const Color(0xFF10B981)
        : cleConfigure
            ? const Color(0xFFF59E0B)
            : const Color(0xFFE2E8F0);
    final icon = actif
        ? Icons.check_circle_rounded
        : cleConfigure
            ? Icons.warning_rounded
            : Icons.cancel_rounded;
    final iconColor = actif
        ? const Color(0xFF10B981)
        : cleConfigure
            ? const Color(0xFFF59E0B)
            : const Color(0xFF94A3B8);
    final subtitle = actif
        ? 'Actif'
        : cleConfigure
            ? 'Clé présente'
            : 'Non configuré';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: actif
                        ? const Color(0xFF10B981)
                        : cleConfigure
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _boutonTestApi({
    required String label,
    required Color couleur,
    required bool enCours,
    required VoidCallback onTap,
    String? resultat,
    required bool resultatOk,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          icon: enCours
              ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: couleur))
              : Icon(Icons.play_arrow_rounded, size: 14, color: couleur),
          label: Text(
            enCours ? 'Test…' : label,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: couleur),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: couleur.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: enCours ? null : onTap,
        ),
        if (resultat != null) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: resultatOk ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              resultat,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: resultatOk ? const Color(0xFF065F46) : const Color(0xFF991B1B),
              ),
            ),
          ),
        ],
      ],
    );
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
              onTap: () {
                setState(() => _sectionIndex = i);
                if (i == 7) {
                  unawaited(_refreshTwoFaStatus());
                }
                if (i == 10) {
                  _fetchInfraData();
                }
              },
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
        return _buildAuthSection();
      case 5:
        return _buildNotificationsSection();
      case 6:
        return _buildAiSection();
      case 7:
        return _buildSecuritySection();
      case 8:
        return _buildContentSection();
      case 9:
        return _buildFooterSection();
      case 10:
        return _buildInfrastructureSection();
      case 11:
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
        mainAxisSize: MainAxisSize.min,
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

  Future<void> _refreshContentSectionData() async {
    if (!mounted) return;
    setState(() => _contenuLoading = true);
    try {
      final results = await Future.wait([
        _admin.getAproposSectionsAdmin(),
        _admin.getNewsletterAbonnes(actifsOnly: true),
      ]);
      if (!mounted) return;
      final apropos = results[0] as List<Map<String, dynamic>>;
      final newsletter = results[1] as Map<String, dynamic>;
      final d = newsletter['data'] as Map<String, dynamic>? ?? {};
      final t = d['total'];
      setState(() {
        _aproposSections = apropos;
        _newsletterAbonnesActifs = t is int ? t : int.tryParse(t?.toString() ?? '') ?? 0;
        _contenuLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _contenuLoading = false);
    }
  }

  Future<void> _editAproposSection(Map<String, dynamic> section) async {
    final titreCtrl = TextEditingController(text: section['titre']?.toString() ?? '');
    final contenuCtrl = TextEditingController(text: section['contenu']?.toString() ?? '');
    final iconeCtrl = TextEditingController(text: section['icone']?.toString() ?? '');
    bool estActif = section['est_actif'] != false;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Modifier section À propos'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: iconeCtrl, decoration: const InputDecoration(labelText: 'Icône (emoji)')),
                const SizedBox(height: 8),
                TextField(controller: titreCtrl, decoration: const InputDecoration(labelText: 'Titre')),
                const SizedBox(height: 8),
                TextField(
                  controller: contenuCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Contenu'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Section active'),
                  value: estActif,
                  onChanged: (v) => setModalState(() => estActif = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                final id = section['id']?.toString() ?? '';
                if (id.isEmpty) return;
                await _admin.putAproposSection(id, {
                  'titre': titreCtrl.text.trim(),
                  'contenu': contenuCtrl.text.trim(),
                  'icone': iconeCtrl.text.trim(),
                  'est_actif': estActif,
                });
                if (!mounted) return;
                Navigator.pop(ctx);
                await _refreshContentSectionData();
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    titreCtrl.dispose();
    contenuCtrl.dispose();
    iconeCtrl.dispose();
  }

  Future<void> _saveNewsletterPromptBase() async {
    try {
      final r = await _admin.updateParametres([
        {
          'cle': 'newsletter_prompt_base',
          'valeur': _newsletterPromptBaseCtrl.text.trim(),
        },
      ]);
      if (!mounted) return;
      final ok = r['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Prompt de base IA enregistré.' : 'Échec enregistrement prompt.'),
          backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _saveNewsletterFeatureSemaine() async {
    try {
      final r = await _admin.updateParametres([
        {
          'cle': 'newsletter_feature_semaine',
          'valeur': _newsletterFeatureSemaineCtrl.text.trim(),
        },
      ]);
      final ok = r['success'] == true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Feature de la semaine enregistrée.' : 'Échec enregistrement feature.'),
          backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        ),
      );
      if (ok) {
        setState(() => _hasUnsavedChanges = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Color _couleurType(String type) {
    switch (type) {
      case 'nouvelles_offres':
        return const Color(0xFF1A56DB);
      case 'hebdomadaire':
        return const Color(0xFF8B5CF6);
      case 'admin':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF1A56DB);
    }
  }

  IconData _iconeType(String type) {
    switch (type) {
      case 'nouvelles_offres':
        return Icons.work_outline_rounded;
      case 'hebdomadaire':
        return Icons.calendar_today_rounded;
      case 'admin':
        return Icons.edit_note_rounded;
      default:
        return Icons.email_rounded;
    }
  }

  String _descriptionType(String type) {
    switch (type) {
      case 'nouvelles_offres':
        return 'Claude met en avant les nouvelles offres de la semaine + 1 conseil rapide.';
      case 'hebdomadaire':
        return 'Mix complet : offres + conseils carrière + outils IA + partenaires + feature semaine.';
      case 'admin':
        return 'Campagne libre : vous guidez Claude avec vos instructions, il rédige la newsletter.';
      default:
        return '';
    }
  }

  Future<void> _lancerNewsletterIA() async {
    setState(() {
      _isLancerIA = true;
      _resultatIA = null;
    });
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final body = <String, dynamic>{
        'declencheur': _newsletterType,
      };
      if (_newsletterType == 'admin' && _contexteLibreCtrl.text.trim().isNotEmpty) {
        body['contexte_libre'] = _contexteLibreCtrl.text.trim();
      }

      final res = await http
          .post(
            Uri.parse('$apiBaseUrl$apiPrefix/admin/newsletter/ia/generer'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(minutes: 3));

      final respBody = jsonDecode(res.body);
      setState(() {
        _resultatOk = respBody['success'] == true;
        _resultatIA = respBody['success'] == true
            ? 'Newsletter "${respBody['sujet']}" envoyée a ${respBody['nb_envois']} abonnes.'
            : '${respBody['message']}';
      });
      await _refreshContentSectionData();
    } catch (e) {
      setState(() {
        _resultatOk = false;
        _resultatIA = 'Erreur: $e';
      });
    } finally {
      if (mounted) setState(() => _isLancerIA = false);
    }
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          title: 'Page « À propos »',
          children: [
            Text(
              'Modifiez les sections publiques (hero, mission, vision, etc.) directement depuis cet onglet.',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/a-propos'),
                    icon: const Icon(Icons.visibility_rounded, size: 16),
                    label: const Text('Voir la page'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _refreshContentSectionData,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Actualiser'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_contenuLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(minHeight: 2),
              )
            else if (_aproposSections.isEmpty)
              const Text('Aucune section trouvée.')
            else
              ..._aproposSections.map(
                (s) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Text(s['icone']?.toString() ?? '📄'),
                  title: Text(s['titre']?.toString() ?? s['section']?.toString() ?? ''),
                  subtitle: Text('Section: ${s['section'] ?? ''}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    onPressed: () => _editAproposSection(s),
                  ),
                ),
              ),
          ],
        ),
        _sectionCard(
          title: 'Newsletter',
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_rounded, color: Color(0xFF1A56DB), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    '$_newsletterAbonnesActifs abonné(s) actif(s)',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A56DB),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _newsletterActif,
              onChanged: (v) => setState(() {
                _newsletterActif = v;
                _markChanged();
              }),
              title: const Text('Newsletter active'),
              subtitle: const Text('Permet les inscriptions depuis le footer.'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _newsletterIaActif,
              onChanged: (v) => setState(() {
                _newsletterIaActif = v;
                _markChanged();
              }),
              title: const Text('Newsletter IA automatique'),
              subtitle: const Text('Déclenchements auto + hebdo via cron.'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _newsletterIaSeuilOffres.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Seuil nouvelles offres (IA auto)',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() {
                      _newsletterIaSeuilOffres = int.tryParse(v) ?? 3;
                      _markChanged();
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _newsletterFeatureSemaineCtrl,
              decoration: InputDecoration(
                labelText: 'Feature IA de la semaine (optionnel)',
                hintText: 'Ex: Nouveau simulateur d\'entretien disponible !',
                isDense: true,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save_rounded, size: 16),
                  onPressed: _saveNewsletterFeatureSemaine,
                ),
              ),
              onChanged: (_) => _markChanged(),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF1A56DB).withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF1A56DB), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Instructions de base pour l\'IA',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A56DB),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Claude lit ces instructions avant chaque newsletter. '
                    'Il doit se baser uniquement sur les donnees reelles de la plateforme.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _newsletterPromptBaseCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Ex: Tu es le responsable communication d\'EmploiConnect...',
                hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              onChanged: (_) => _markChanged(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 14),
                    label: const Text('Reinitialiser'),
                    onPressed: () {
                      const defaut = 'Tu es le responsable communication d\'EmploiConnect, la plateforme N1 de l\'emploi en Guinee. Rédige des newsletters professionnelles basees uniquement sur les donnees reelles de la plateforme. Ne jamais inventer d\'offres ou d\'entreprises. Adapte le contenu au contexte guineen.';
                      setState(() {
                        _newsletterPromptBaseCtrl.text = defaut;
                        _markChanged();
                      });
                      _saveNewsletterPromptBase();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save_rounded, size: 14),
                    label: const Text('Sauvegarder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A56DB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    onPressed: _saveNewsletterPromptBase,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Type de newsletter IA',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _newsletterType,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'hebdomadaire',
                  child: Row(children: [Text('📅 '), Text('Hebdomadaire (mix complet)')]),
                ),
                DropdownMenuItem(
                  value: 'nouvelles_offres',
                  child: Row(children: [Text('💼 '), Text('Nouvelles offres')]),
                ),
                DropdownMenuItem(
                  value: 'admin',
                  child: Row(children: [Text('✏️ '), Text('Campagne libre')]),
                ),
              ],
              onChanged: (v) => setState(() => _newsletterType = v ?? 'hebdomadaire'),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _couleurType(_newsletterType).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _couleurType(_newsletterType).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(_iconeType(_newsletterType), color: _couleurType(_newsletterType), size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _descriptionType(_newsletterType),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _couleurType(_newsletterType),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: _newsletterType == 'admin'
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contexte / Instructions pour l\'IA',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _contexteLibreCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Ex: Mets en avant nos nouvelles fonctionnalites IA...',
                            hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    )
                  : const SizedBox(),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isLancerIA
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 16),
                label: Text(
                  _isLancerIA ? 'Generation en cours...' : 'Lancer la newsletter IA',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _couleurType(_newsletterType),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLancerIA ? null : _lancerNewsletterIA,
              ),
            ),
            const SizedBox(height: 8),
            if (_resultatIA != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _resultatOk ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _resultatOk ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                      color: _resultatOk ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _resultatIA!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _resultatOk ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
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
                    [
                      (b['type_banniere'] ?? 'hero').toString(),
                      if ((b['type_banniere'] ?? '').toString().toLowerCase() != 'ticker')
                        (b['image_url']?.toString().isNotEmpty == true)
                            ? 'Image'
                            : 'Sans image',
                    ].join(' · '),
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

  Widget _buildGuideEtapes() {
    const etapes = [
      '1. Ouvrir Google Cloud Console > APIs & Services > Credentials.',
      '2. Creer un OAuth Client ID de type Application Web.',
      '3. Renseigner l URI de redirection ci-dessous dans Google.',
      '4. Copier Client ID et Client Secret dans ce formulaire.',
      '5. Activer Google OAuth si vous voulez afficher le bouton Google.',
      '6. Tester la configuration avec le bouton Tester.',
      '7. Sauvegarder pour appliquer en production.',
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: etapes.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              e,
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF374151), height: 1.35),
            ),
          ),
        ).toList(),
      ),
    );
  }

  Future<void> _testerOAuth() async {
    setState(() {
      _isTesting = true;
      _testResultat = null;
    });
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.post(
        Uri.parse('$apiBaseUrl$apiPrefix/admin/oauth/test'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() => _testResultat = Map<String, dynamic>.from(jsonDecode(res.body) as Map));
    } catch (e) {
      if (!mounted) return;
      setState(() => _testResultat = {
        'success': false,
        'etapes': [
          {'ok': false, 'message': 'Erreur: $e'},
        ],
      });
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _sauvegarderOAuth() async {
    setState(() => _isSavingOAuth = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final payload = <String, dynamic>{
        'google_client_id': _googleClientIdCtrl.text.trim(),
        'google_oauth_actif': _googleOauthActif,
        'google_roles_defaut': _googleRolesDefaut,
        'google_domaines_autorises': _googleDomainesCtrl.text.trim(),
        'google_projet_id': _googleProjetCtrl.text.trim(),
        'google_redirect_uri': _redirectUriAuto.trim(),
        'app_url_prod': _appUrlProdCtrl.text.trim(),
      };
      if (_googleClientSecretCtrl.text.trim().isNotEmpty && _googleClientSecretCtrl.text.trim() != '********') {
        payload['google_client_secret'] = _googleClientSecretCtrl.text.trim();
      }

      final res = await http.post(
        Uri.parse('$apiBaseUrl$apiPrefix/admin/oauth/sauvegarder'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (body['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Config Google OAuth sauvegardee'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (_googleClientSecretCtrl.text.trim() != '********' && _googleClientSecretCtrl.text.trim().isNotEmpty) {
          setState(() => _googleClientSecretCtrl.text = '********');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message']?.toString() ?? 'Echec sauvegarde OAuth'),
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
      if (mounted) setState(() => _isSavingOAuth = false);
    }
  }

  Future<void> _loadOAuthConfig() async {
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final res = await http.get(
        Uri.parse('$apiBaseUrl$apiPrefix/admin/oauth/config'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['success'] != true || !mounted) return;
      final d = body['data'] as Map<String, dynamic>? ?? {};
      setState(() {
        _googleClientIdCtrl.text = d['google_client_id']?.toString() ?? '';
        _googleClientSecretCtrl.text = (d['google_client_secret_configure'] == true
                || (d['google_client_secret'] ?? '').toString().isNotEmpty)
            ? '********'
            : '';
        _googleOauthActif = (d['google_oauth_actif'] ?? '').toString().toLowerCase() == 'true';
        final role = d['google_roles_defaut']?.toString().trim().toLowerCase() ?? 'chercheur';
        _googleRolesDefaut = role == 'entreprise' ? 'entreprise' : 'chercheur';
        _googleDomainesCtrl.text = d['google_domaines_autorises']?.toString() ?? '';
        _googleProjetCtrl.text = d['google_projet_id']?.toString() ?? '';
        _appUrlProdCtrl.text = d['app_url_prod']?.toString() ?? '';
        _redirectUriAuto = d['redirect_uri_auto']?.toString() ?? '';
      });
    } catch (_) {
      // ignore
    }
  }

  Widget _buildAuthSection() {
    final clientIdOk = _googleClientIdCtrl.text.trim().isNotEmpty;
    final secretOk = _googleClientSecretCtrl.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          title: 'Statut actuel',
          children: [
            Row(
              children: [
                Expanded(
                  child: _BadgeStatut(label: 'Client ID', configure: clientIdOk),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BadgeStatut(label: 'Client Secret', configure: secretOk),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _googleOauthActif,
              onChanged: (v) => setState(() => _googleOauthActif = v),
              title: const Text('Google OAuth active'),
              subtitle: const Text('Affiche "Se connecter avec Google".'),
            ),
          ],
        ),
        _sectionCard(
          title: 'Guide de configuration',
          children: [
            InkWell(
              onTap: () => setState(() => _guideExpanded = !_guideExpanded),
              child: Row(
                children: [
                  const Icon(Icons.help_outline_rounded, color: Color(0xFF1A56DB), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Comment creer des identifiants Google OAuth ?',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A56DB),
                      ),
                    ),
                  ),
                  Icon(
                    _guideExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: const Color(0xFF1A56DB),
                    size: 18,
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: _guideExpanded ? _buildGuideEtapes() : const SizedBox(),
            ),
          ],
        ),
        _sectionCard(
          title: 'Identifiants Google Cloud',
          children: [
            TextField(
              controller: _googleClientIdCtrl,
              decoration: const InputDecoration(
                labelText: 'Client ID *',
                hintText: 'xxx.apps.googleusercontent.com',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _googleClientSecretCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Client Secret *',
                hintText: 'GOCSPX-xxxxx',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1A56DB).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'URI de redirection a copier dans Google Cloud',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A56DB),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _redirectUriAuto.isEmpty ? 'Chargement...' : _redirectUriAuto,
                          style: GoogleFonts.robotoMono(fontSize: 11, color: const Color(0xFF0F172A)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        onPressed: _redirectUriAuto.isEmpty
                            ? null
                            : () {
                                Clipboard.setData(ClipboardData(text: _redirectUriAuto));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('URI copiee'),
                                    backgroundColor: Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        _sectionCard(
          title: 'Checklist mise en production',
          children: [
            TextField(
              controller: _appUrlProdCtrl,
              decoration: const InputDecoration(
                labelText: 'URL du site en production',
                hintText: 'Ex: https://emploiconnect.gn',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 4),
            Text(
              'Cette URL est utilisee pour calculer l URI de redirection Google en production.',
              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 8),
            if (_appUrlProdCtrl.text.trim().isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'URI de redirection production :',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF065F46),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_appUrlProdCtrl.text.trim().replaceAll(RegExp(r"/+$"), "")}/api/auth/google/callback',
                            style: GoogleFonts.robotoMono(fontSize: 11, color: const Color(0xFF065F46)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 14),
                          color: const Color(0xFF10B981),
                          onPressed: () {
                            final uri = '${_appUrlProdCtrl.text.trim().replaceAll(RegExp(r"/+$"), "")}/api/auth/google/callback';
                            Clipboard.setData(ClipboardData(text: uri));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('URI copiee'),
                                backgroundColor: Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'Etapes pour la mise en production :',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            const _ChecklistItem(
              numero: '1',
              titre: 'Heberger le site',
              desc: 'Sur un serveur avec un vrai domaine (ex: emploiconnect.gn).',
            ),
            const _ChecklistItem(
              numero: '2',
              titre: 'Mettre a jour l URI de redirection',
              desc: 'Google Cloud Console > Identifiants > ajouter l URI de production.',
            ),
            const _ChecklistItem(
              numero: '3',
              titre: 'Passer en mode Production',
              desc: 'Ecran consentement OAuth > Publier l application > tous les emails autorises.',
            ),
            const _ChecklistItem(
              numero: '4',
              titre: 'Verifier l application (optionnel)',
              desc: 'Si >100 utilisateurs, demander la verification Google.',
            ),
            const _ChecklistItem(
              numero: '5',
              titre: 'Tester en production',
              desc: 'Tester avec un email non test; la connexion Google doit fonctionner.',
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text('Ouvrir Google Cloud Console'),
                onPressed: () async {
                  final uri = Uri.parse('https://console.cloud.google.com/apis/credentials');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF92400E), size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'En mode Test Google, seuls les emails ajoutes dans Google Cloud Console peuvent se connecter.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF92400E),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        _sectionCard(
          title: 'Configuration avancee',
          children: [
            DropdownButtonFormField<String>(
              initialValue: _googleRolesDefaut,
              decoration: const InputDecoration(labelText: 'Role nouveaux comptes'),
              items: const [
                DropdownMenuItem(value: 'chercheur', child: Text('Candidat')),
                DropdownMenuItem(value: 'entreprise', child: Text('Recruteur')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _googleRolesDefaut = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _googleDomainesCtrl,
              decoration: const InputDecoration(
                labelText: 'Domaines email autorises (optionnel)',
                hintText: 'Ex: gmail.com, orange-guinee.com',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _googleProjetCtrl,
              decoration: const InputDecoration(
                labelText: 'Google Projet ID (optionnel)',
              ),
            ),
          ],
        ),
        _sectionCard(
          title: 'Test et sauvegarde',
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: _isTesting
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4285F4)),
                          )
                        : const Icon(Icons.play_arrow_rounded, size: 16),
                    label: Text(_isTesting ? 'Test...' : 'Tester'),
                    onPressed: _isTesting ? null : _testerOAuth,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: _isSavingOAuth
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded, size: 16),
                    label: Text(_isSavingOAuth ? 'Sauvegarde...' : 'Sauvegarder'),
                    onPressed: _isSavingOAuth ? null : _sauvegarderOAuth,
                  ),
                ),
              ],
            ),
            if (_testResultat != null) ...[
              const SizedBox(height: 12),
              ...((_testResultat!['etapes'] as List?) ?? const []).map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        e['ok'] == true ? Icons.check_circle_rounded : Icons.warning_rounded,
                        color: e['ok'] == true ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e['message']?.toString() ?? '',
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF374151)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
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
    final hasAnthropicKey = _anthropicApiKeyCtrl.text.trim().isNotEmpty;
    final hasOpenaiKey = _openaiKeyCtrl.text.trim().isNotEmpty;
    final claudeActifBadge =
        hasAnthropicKey && (_iaMatchingActif || _iaAmeliorationProvider == 'anthropic');
    final openaiActifBadge = hasOpenaiKey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          title: 'Statut des APIs IA',
          children: [
            Row(
              children: [
                Expanded(
                  child: _iaStatusBadgeRow(
                    label: 'Claude (Anthropic)',
                    actif: claudeActifBadge,
                    cleConfigure: hasAnthropicKey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _iaStatusBadgeRow(
                    label: 'OpenAI',
                    actif: openaiActifBadge,
                    cleConfigure: hasOpenaiKey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF1A56DB), size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Si les deux clés sont renseignées, le backend utilise le provider choisi pour le texte/matching, '
                      'puis bascule automatiquement sur l’autre en cas d’échec.',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF1E40AF), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Tests rapides (clés réelles en base — enregistrez d’abord si besoin)',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 220,
                  child: _boutonTestApi(
                    label: 'Tester Claude',
                    couleur: const Color(0xFF7C3AED),
                    enCours: _apiTestClaudeEnCours,
                    onTap: _testApiClaudeIsole,
                    resultat: _apiTestClaudeMsg,
                    resultatOk: _apiTestClaudeOk,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: _boutonTestApi(
                    label: 'Tester OpenAI',
                    couleur: const Color(0xFF10B981),
                    enCours: _apiTestOpenaiEnCours,
                    onTap: _testApiOpenaiIsole,
                    resultat: _apiTestOpenaiMsg,
                    resultatOk: _apiTestOpenaiOk,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: _boutonTestApi(
                    label: 'Tester DALL-E',
                    couleur: const Color(0xFFF59E0B),
                    enCours: _apiTestDalleEnCours,
                    onTap: _testApiDalleIsole,
                    resultat: _apiTestDalleMsg,
                    resultatOk: _apiTestDalleOk,
                  ),
                ),
              ],
            ),
          ],
        ),
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
                    Expanded(
                      child: Text(
                        'Modèle utilisé : GPT-3.5-turbo. La même clé OpenAI sert aussi pour DALL-E '
                        '(section Illustration homepage ci-dessous).',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF065F46),
                          height: 1.35,
                        ),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.psychology_rounded, color: Color(0xFF8B5CF6), size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Simulateur d\'entretien (Parcours Carrière)',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                      ),
                      Text(
                        'Génération et évaluation des questions via Claude',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _iaSimulateurParcoursActif,
                  activeThumbColor: const Color(0xFF8B5CF6),
                  onChanged: (v) {
                    setState(() {
                      _iaSimulateurParcoursActif = v;
                      _markChanged();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calculate_rounded, color: Color(0xFF10B981), size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calculateur de salaire (Parcours Carrière)',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                      ),
                      Text(
                        'Estimation salariale indicative (GNF) via Claude',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _iaCalculateurParcoursActif,
                  activeThumbColor: const Color(0xFF10B981),
                  onChanged: (v) {
                    setState(() {
                      _iaCalculateurParcoursActif = v;
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
          title: 'Illustration de la homepage',
          children: [
            Text(
              'Image affichée dans la section « Ils ont réussi grâce à nous » (page d’accueil publique).',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 14),
            const IllustrationIaSettingsWidget(),
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

  Future<void> _refreshTwoFaStatus() async {
    setState(() => _twoFaStatusLoading = true);
    try {
      final m = await _admin.get2faStatus();
      final d = m['data'];
      if (!mounted) return;
      if (d is Map) {
        setState(() {
          _twoFaUserActif = d['twofa_actif'] == true;
          _twoFaSetupPending = d['setup_pending'] == true;
          _twoFaStatusLoading = false;
        });
      } else {
        setState(() => _twoFaStatusLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _twoFaStatusLoading = false);
    }
  }

  Future<void> _openMonTwoFaSetup() async {
    if (!_admin2fa) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activez d’abord « 2FA pour les administrateurs » ci-dessus, puis enregistrez.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _twoFaActionLoading = true);
    try {
      final r = await _admin.get2faSetup();
      if (!mounted) return;
      if (r['success'] != true) {
        throw Exception(r['message']?.toString() ?? 'Impossible de préparer le 2FA');
      }
      final d = r['data'];
      final qrUrl = d is Map ? d['qrCodeDataUrl']?.toString() : null;
      if (qrUrl == null || qrUrl.isEmpty) throw Exception('QR code indisponible');

      final qrBytes = !qrUrl.startsWith('data:image')
          ? null
          : () {
              final i = qrUrl.indexOf(',');
              if (i <= 0) return null;
              return base64Decode(qrUrl.substring(i + 1));
            }();

      final codeCtrl = TextEditingController();
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Configurer le 2FA', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '1. Scannez le QR avec Google Authenticator ou Authy.\n'
                  '2. Entrez le code à 6 chiffres pour confirmer.',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                if (qrBytes != null)
                  Center(child: Image.memory(qrBytes, width: 200, height: 200))
                else
                  const Text('Impossible d’afficher le QR code.'),
                const SizedBox(height: 12),
                TextField(
                  controller: codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  decoration: const InputDecoration(
                    labelText: 'Code',
                    counterText: '',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                final code = codeCtrl.text.trim();
                if (code.length < 6) return;
                try {
                  final ar = await _admin.post2faActiver(code);
                  if (!ctx.mounted) return;
                  if (ar['success'] == true) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('2FA activé sur votre compte.'),
                        backgroundColor: Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    await _refreshTwoFaStatus();
                  } else {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(ar['message']?.toString() ?? 'Erreur')),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );
      codeCtrl.dispose();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _twoFaActionLoading = false);
    }
  }

  Future<void> _desactiverMonTwoFa() async {
    final ok = await showAdminTwoFactorCodeDialog(
      context,
      submit: (code) async {
        try {
          final m = await _admin.post2faDesactiver(code);
          return (m['success'] == true, m['message']?.toString());
        } catch (e) {
          return (false, e.toString());
        }
      },
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('2FA désactivé sur votre compte.'),
          backgroundColor: Color(0xFF64748B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _refreshTwoFaStatus();
    }
  }

  Widget _buildSecuritySection() {
    return _sectionCard(
      title: 'Sécurité',
      children: [
        _metricLabelWithTooltip(
          label: 'Durée de session',
          tooltip:
              'Inactivité côté appli (déconnexion si aucune interaction pendant ce délai). '
              'Côté API, la durée du JWT est le minimum entre cette valeur et « Expiration JWT ».',
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
            'Autorise l’activation TOTP par admin. Les secrets restent en base (accès service_role uniquement).',
          ),
        ),
        const Divider(height: 28),
        Text(
          'Mon authentification à deux facteurs',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        if (_twoFaStatusLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(minHeight: 2),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _twoFaUserActif ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _twoFaUserActif
                    ? const Color(0xFF10B981).withValues(alpha: 0.35)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _twoFaUserActif ? Icons.verified_user_rounded : Icons.security_outlined,
                  color: _twoFaUserActif ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _twoFaUserActif
                        ? '2FA activé sur votre compte administrateur.'
                        : (_twoFaSetupPending
                              ? 'Configuration en cours : terminez avec le code à 6 chiffres.'
                              : '2FA non activé — recommandé pour sécuriser l’accès admin.'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _twoFaUserActif ? const Color(0xFF065F46) : const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: _twoFaActionLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(_twoFaUserActif ? Icons.lock_open_rounded : Icons.qr_code_rounded, size: 16),
            label: Text(_twoFaUserActif ? 'Désactiver mon 2FA' : 'Activer mon 2FA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _twoFaUserActif ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _twoFaActionLoading
                ? null
                : () {
                    if (_twoFaUserActif) {
                      unawaited(_desactiverMonTwoFa());
                    } else {
                      unawaited(_openMonTwoFaSetup());
                    }
                  },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Google Authenticator, Authy ou toute appli compatible TOTP.',
          style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
        ),
        const Divider(height: 28),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF1A56DB), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'IPs bloquées — comment ça marche',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A56DB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '• Une adresse par ligne (ou liste JSON côté API).\n'
                '• Correspondance stricte avec l’IP client (détection via X-Forwarded-For si proxy).\n'
                '• Ces adresses reçoivent 403 sur toutes les routes /api (dès le middleware).\n'
                '• Utile pour bloquer une source d’abus après sauvegarde des paramètres.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF374151),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                'Liste des IPs bloquées',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
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
            hintText: '192.168.1.100\n10.0.0.1',
            filled: true,
            fillColor: Color(0xFFF8FAFC),
            contentPadding: EdgeInsets.all(12),
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

  Future<void> _fetchInfraData({bool showTestSpinner = false}) async {
    if (!context.read<AdminProvider>().estSuperAdmin) return;
    if (showTestSpinner && mounted) {
      setState(() => _testSupabaseEnCours = true);
    }
    try {
      final body = await _admin.getInfraTest();
      if (!mounted) return;
      if (body['success'] == true) {
        final raw = body['data'];
        if (raw is Map) {
          final dm = Map<String, dynamic>.from(raw);
          final bucketsRaw = dm['buckets'];
          final exists = <String, bool>{};
          final pub = <String, bool>{};
          if (bucketsRaw is Map) {
            bucketsRaw.forEach((k, v) {
              final name = k.toString();
              if (v is Map) {
                final m = Map<String, dynamic>.from(v);
                exists[name] = m['exists'] == true;
                pub[name] = m['public'] == true;
              }
            });
          }
          setState(() {
            _configServeur = {
              'supabase_url': dm['supabase_url']?.toString() ?? '',
              'service_role_configured': dm['service_role_configured'] == true,
              'jwt_configured': dm['jwt_configured'] == true,
            };
            _bucketExists = exists;
            _bucketPublic = pub;
            _portEnvHint = dm['port_env']?.toString() ?? '';
            final bddPort = dm['server_port_bdd']?.toString() ?? '';
            if (bddPort.isNotEmpty && _serverPortInfraCtrl.text.trim().isEmpty) {
              _serverPortInfraCtrl.text = bddPort;
            }
            if (showTestSpinner) {
              _testSupabaseOk = true;
              _testSupabaseResultat = 'Connexion Supabase opérationnelle.';
            }
          });
          return;
        }
      }
      if (mounted && showTestSpinner) {
        setState(() {
          _testSupabaseOk = false;
          _testSupabaseResultat =
              body['message']?.toString() ?? 'Impossible de joindre l’API infra.';
        });
      }
    } catch (e) {
      if (mounted && showTestSpinner) {
        setState(() {
          _testSupabaseOk = false;
          _testSupabaseResultat = 'Erreur : $e';
        });
      }
    } finally {
      if (mounted && showTestSpinner) {
        setState(() => _testSupabaseEnCours = false);
      }
    }
  }

  Future<void> _sauvegarderInfra() async {
    if (!context.read<AdminProvider>().estSuperAdmin) return;
    setState(() => _savingInfra = true);
    try {
      final port = _serverPortInfraCtrl.text.trim();
      final batch = <Map<String, dynamic>>[
        {'cle': 'app_url_prod', 'valeur': _appUrlProdCtrl.text.trim()},
        {'cle': 'server_port', 'valeur': port},
      ];
      final r = await _admin.updateParametres(batch);
      if (!mounted) return;
      final ok = r['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Configuration enregistrée.'
                : (r['message']?.toString() ?? 'Erreur lors de l’enregistrement'),
          ),
          backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (ok) await _fetchInfraData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _savingInfra = false);
    }
  }

  Widget _buildInfrastructureSection() {
    final superOnly = context.watch<AdminProvider>().estSuperAdmin;
    if (!superOnly) {
      return _sectionCard(
        title: 'Infrastructure',
        children: [
          Text(
            'Cette section est réservée au super administrateur.',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
          ),
        ],
      );
    }

    final svcOk = _configServeur['service_role_configured'] == true;
    final jwtOk = _configServeur['jwt_configured'] == true;
    final supaUrl = _configServeur['supabase_url']?.toString() ?? '';

    Widget ligneLecture({
      required String label,
      required String valeur,
      required IconData icone,
      bool estOk = false,
    }) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valeur,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: estOk ? const Color(0xFF065F46) : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final bucketNames = _bucketExists.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionCard(
          title: 'Infrastructure',
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_rounded, color: Color(0xFF92400E), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Section réservée au super administrateur.\n'
                      'SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY et JWT_SECRET '
                      'doivent rester dans le fichier .env du serveur : les stocker en base '
                      'créerait un paradoxe (il faut déjà être connecté pour les lire).',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF92400E),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Base de données Supabase',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            Text(
              'Lecture seule — valeurs sensibles dans .env',
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 12),
            ligneLecture(
              label: 'SUPABASE_URL (masquée)',
              valeur: supaUrl.isEmpty ? 'Non chargée — ouvrez cet onglet ou testez la connexion' : supaUrl,
              icone: Icons.link_rounded,
            ),
            const SizedBox(height: 10),
            ligneLecture(
              label: 'SERVICE_ROLE_KEY',
              valeur: svcOk ? 'Configurée' : 'Non configurée',
              icone: Icons.vpn_key_rounded,
              estOk: svcOk,
            ),
            const SizedBox(height: 10),
            ligneLecture(
              label: 'JWT_SECRET',
              valeur: jwtOk ? '••••••••••••••••' : 'Non configuré',
              icone: Icons.security_rounded,
              estOk: jwtOk,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: _testSupabaseEnCours
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A56DB)),
                      )
                    : const Icon(Icons.wifi_tethering_rounded, size: 16),
                label: Text(_testSupabaseEnCours ? 'Test en cours…' : 'Tester la connexion Supabase'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1A56DB)),
                  foregroundColor: const Color(0xFF1A56DB),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _testSupabaseEnCours ? null : () => _fetchInfraData(showTestSpinner: true),
              ),
            ),
            if (_testSupabaseResultat != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (_testSupabaseOk == true)
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testSupabaseOk == true
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded,
                      color: _testSupabaseOk == true
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testSupabaseResultat!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _testSupabaseOk == true
                              ? const Color(0xFF065F46)
                              : const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        _sectionCard(
          title: 'Configuration du serveur',
          children: [
            TextField(
              controller: _appUrlProdCtrl,
              onChanged: (_) => _markChanged(),
              decoration: InputDecoration(
                labelText: 'URL publique du site (app_url_prod)',
                hintText: 'https://emploiconnect.gn',
                suffixIcon: _InfoTooltip(
                  'Utilisée pour les e-mails, newsletters et redirections OAuth.',
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _serverPortInfraCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => _markChanged(),
              decoration: InputDecoration(
                labelText: 'Port du serveur (server_port en base)',
                hintText: '3000',
                suffixIcon: _InfoTooltip(
                  'Valeur documentaire / cohérence avec l’admin. '
                  'Le port réel du processus vient de la variable PORT (.env). '
                  '${_portEnvHint.isNotEmpty ? 'PORT actuel : $_portEnvHint.' : ''}',
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _savingInfra
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded, size: 16),
                label: const Text('Sauvegarder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56DB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _savingInfra ? null : _sauvegarderInfra,
              ),
            ),
          ],
        ),
        _sectionCard(
          title: 'Buckets Storage',
          children: [
            Text(
              'État des buckets Supabase (existence + public)',
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 10),
            if (bucketNames.isEmpty)
              Text(
                'Aucune donnée — ouvrez cet onglet ou lancez un test.',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
              )
            else
              ...bucketNames.map((name) {
                final ex = _bucketExists[name] == true;
                final pub = _bucketPublic[name] == true;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        ex ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: ex ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        !ex
                            ? 'Absent'
                            : (pub ? 'Public' : 'Privé'),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: !ex
                              ? const Color(0xFFEF4444)
                              : (pub ? const Color(0xFF10B981) : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
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

/// Client ID / Secret Google : affichage masqué si déjà en base, sinon saisie + [Enregistrer] (un paramètre à la fois).
class _AdminGoogleCleTile extends StatefulWidget {
  const _AdminGoogleCleTile({
    required this.cle,
    required this.label,
    required this.hint,
    required this.isSecret,
    required this.loadedValue,
    required this.onSave,
  });

  final String cle;
  final String label;
  final String hint;
  final bool isSecret;
  final String loadedValue;
  final Future<bool> Function(String cle, String valeur) onSave;

  @override
  State<_AdminGoogleCleTile> createState() => _AdminGoogleCleTileState();
}

class _AdminGoogleCleTileState extends State<_AdminGoogleCleTile> {
  final TextEditingController _ctrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  bool get _configured {
    final v = widget.loadedValue.trim();
    if (v.isEmpty) return false;
    if (widget.isSecret) return true;
    return v.contains('apps.googleusercontent.com');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _AdminGoogleCleTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadedValue != widget.loadedValue) {
      _ctrl.clear();
    }
  }

  void _startEdit() {
    setState(() {
      _editing = true;
      if (!widget.isSecret) {
        _ctrl.text = widget.loadedValue.trim();
      } else {
        _ctrl.clear();
      }
    });
  }

  Future<void> _submit() async {
    final v = _ctrl.text.trim();
    if (v.isEmpty) return;
    setState(() => _saving = true);
    final ok = await widget.onSave(widget.cle, v);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      setState(() {
        _editing = false;
        _ctrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_configured && !_editing) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: double.infinity),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF065F46),
                      ),
                    ),
                    Text(
                      '••••••••••••••••••••',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Clé configurée',
                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF10B981)),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _saving ? null : _startEdit,
                child: Text(
                  'Modifier',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A56DB),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: double.infinity),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  obscureText: widget.isSecret,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFCBD5E1)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56DB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Enregistrer'),
              ),
            ],
          ),
        ),
        if (_editing && _configured)
          TextButton(
            onPressed: _saving
                ? null
                : () => setState(() {
                      _editing = false;
                      _ctrl.clear();
                    }),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
            ),
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

class _BadgeStatut extends StatelessWidget {
  const _BadgeStatut({required this.label, required this.configure});

  final String label;
  final bool configure;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: configure ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: configure
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            configure ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: configure ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            size: 14,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: configure ? const Color(0xFF065F46) : const Color(0xFF991B1B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({
    required this.numero,
    required this.titre,
    required this.desc,
  });

  final String numero;
  final String titre;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Color(0xFF4285F4),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                numero,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _banniereGuideDimensions(String type) {
  final t = type.toLowerCase();
  if (t == 'ticker') {
    return _BanniereGuideCarte(
      titre: 'Dimensions (rendu réel) — Ticker',
      items: const [
        _BanniereDimData('Hauteur', '40 px (fixe, `TickerBannieresWidget`)'),
        _BanniereDimData('Largeur', '100 % du viewport'),
        _BanniereDimData('Contenu', 'Texte uniquement (titre / sous-titre défilants)'),
        _BanniereDimData('Image', 'Non affichée sur la page d’accueil pour ce type'),
      ],
    );
  }
  if (t == 'pub') {
    return _BanniereGuideCarte(
      titre: 'Dimensions (rendu réel) — Grande bannière pub',
      items: const [
        _BanniereDimData('Hauteur affichée', '260 px (bureau, ≥768 px) ; 200 px (mobile)'),
        _BanniereDimData('Hauteur BDD', '`hauteur_px` utilisé jusqu’à 320 px, clamp 160–320'),
        _BanniereDimData('Carrousel', '`viewportFraction` 0,88 → carte ≈ 88 % largeur − marges'),
        _BanniereDimData('Image', '`BoxFit.cover`, centrage `Alignment.center`'),
        _BanniereDimData('Fichier conseillé', '≥ 900 × 260 px (même ratio), JPG / PNG / WebP'),
        _BanniereDimData('Poids max', '2 Mo (upload admin)'),
      ],
    );
  }
  return _BanniereGuideCarte(
    titre: 'Dimensions (rendu réel) — Hero',
    items: const [
      _BanniereDimData('Zone section', 'Hauteur min. 400 px (`HomeHeroPrdSection`)'),
      _BanniereDimData('Carte desktop', '380 px de large, hauteur min. 220 px, `BoxFit.cover`'),
      _BanniereDimData('Carte mobile', 'Pleine largeur, hauteur min. 220 px'),
      _BanniereDimData('Fichier conseillé', '≈ 1920 × 500 px à 560 px (paysage)'),
      _BanniereDimData('Poids max', '3 Mo (upload admin)'),
    ],
  );
}

class _BanniereDimData {
  const _BanniereDimData(this.label, this.valeur);
  final String label;
  final String valeur;
}

class _BanniereGuideCarte extends StatelessWidget {
  const _BanniereGuideCarte({
    required this.titre,
    required this.items,
  });

  final String titre;
  final List<_BanniereDimData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1A56DB).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF1A56DB), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  titre,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A56DB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 108,
                    child: Text(
                      e.label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.valeur,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
  final _largeurPxCtrl = TextEditingController(text: '900');
  final _hauteurPxCtrl = TextEditingController(text: '260');
  final _lienExterneCtrl = TextEditingController();
  final _ordrePubCtrl = TextEditingController(text: '0');
  final _couleurBadgeCtrl = TextEditingController(text: '#1A56DB');
  String? _imageUrl;
  bool _isSaving = false;
  String _typeBanniere = 'hero';

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
      _largeurPxCtrl.text = '${b['largeur_px'] ?? 320}';
      _hauteurPxCtrl.text = '${b['hauteur_px'] ?? 180}';
      _lienExterneCtrl.text = b['lien_externe']?.toString() ?? '';
      _ordrePubCtrl.text = '${b['ordre_pub'] ?? 0}';
      final t = b['type_banniere']?.toString().toLowerCase().trim();
      if (t != null && (t == 'ticker' || t == 'pub' || t == 'hero')) {
        _typeBanniere = t;
      }
      final cb = b['couleur_badge']?.toString().trim();
      if (cb != null && cb.isNotEmpty) {
        _couleurBadgeCtrl.text = cb;
      }
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
    _largeurPxCtrl.dispose();
    _hauteurPxCtrl.dispose();
    _lienExterneCtrl.dispose();
    _ordrePubCtrl.dispose();
    _couleurBadgeCtrl.dispose();
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
                    _dialogLabel('Type d\'emplacement'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _typeBanniere,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'hero', child: Text('Hero (carrousel accueil)')),
                        DropdownMenuItem(value: 'ticker', child: Text('Ticker (bandeau défilant)')),
                        DropdownMenuItem(value: 'pub', child: Text('Publicité (réserve)')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        final prev = _typeBanniere;
                        setState(() {
                          _typeBanniere = v;
                          if (v == 'pub' && prev != 'pub') {
                            _largeurPxCtrl.text = '900';
                            _hauteurPxCtrl.text = '260';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _typeBanniere == 'ticker'
                          ? 'Le ticker défile le texte du titre (et du sous-titre si renseigné). Aucune image nécessaire.'
                          : 'Hero et pub : image fortement recommandée (upload ci-dessous).',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: _banniereGuideDimensions(_typeBanniere),
                    ),
                    const SizedBox(height: 12),
                    if (_typeBanniere == 'pub') ...[
                      const SizedBox(height: 14),
                      _dialogLabel('Dimensions recommandées (carrousel pub)'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _dialogField(_largeurPxCtrl, 'Largeur (px)', keyboard: TextInputType.number),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _dialogField(_hauteurPxCtrl, 'Hauteur (px)', keyboard: TextInputType.number),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Color(0xFF92400E), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Les champs largeur / hauteur alimentent `hauteur_px` côté carrousel (voir encadré bleu : 260 px / 200 px selon l’écran).',
                                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF92400E)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _dialogLabel('Lien de redirection (prioritaire sur CTA 1 pour la pub)'),
                      const SizedBox(height: 6),
                      _dialogField(
                        _lienExterneCtrl,
                        'https://… ou /public/offres',
                      ),
                      const SizedBox(height: 12),
                      _dialogLabel('Ordre dans le carrousel pub'),
                      const SizedBox(height: 6),
                      _dialogField(_ordrePubCtrl, '0 = premier', keyboard: TextInputType.number),
                    ],
                    if (_typeBanniere != 'ticker') ...[
                      const SizedBox(height: 16),
                      _dialogLabel('Image de fond *'),
                      const SizedBox(height: 8),
                      ImageUploadWidget(
                        currentImageUrl: _imageUrl,
                        uploadUrl:
                            '$apiBaseUrl$apiPrefix/admin/bannieres/upload-image',
                        fieldName: 'image',
                        title: 'Image de bannière',
                        dimensionsInfo: _typeBanniere == 'pub'
                            ? '900×260 px recommandé — affichage 260 px (bureau) / 200 px (mobile), cover centré'
                            : '≈1920×500 px — hero zone min. 400 px haut, carte ~380×220+ px, cover',
                        acceptedFormats: 'JPG, PNG, WEBP',
                        maxSizeMb: _typeBanniere == 'pub' ? 2 : 3,
                        previewHeight: 120,
                        onUploaded: (url) => setState(() => _imageUrl = url),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _dialogLabel('Titre principal *'),
                    const SizedBox(height: 6),
                    _dialogField(
                      _titreCtrl,
                      'Ex: Trouvez l\'Emploi de Vos Rêves',
                    ),
                    if (_typeBanniere != 'ticker') ...[
                      const SizedBox(height: 14),
                      _dialogLabel('Badge'),
                      const SizedBox(height: 6),
                      _dialogField(
                        _badgeCtrl,
                        'Ex: 🇬🇳 Plateforme N°1 en Guinée',
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _dialogField(
                              _couleurBadgeCtrl,
                              'Couleur badge (hex, ex: #1A56DB)',
                            ),
                          ),
                        ],
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
                    ] else ...[
                      const SizedBox(height: 14),
                      _dialogLabel('Sous-titre (optionnel, affiché dans le ticker)'),
                      const SizedBox(height: 6),
                      _dialogField(
                        _sousTitreCtrl,
                        'Texte additionnel dans la bande',
                        maxLines: 2,
                      ),
                    ],
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
                      onPressed: (_isSaving ||
                              _titreCtrl.text.trim().isEmpty ||
                              (_typeBanniere != 'ticker' &&
                                  (_imageUrl == null || _imageUrl!.isEmpty)))
                          ? null
                          : () async {
                              setState(() => _isSaving = true);
                              await widget.onSave({
                                if (_typeBanniere != 'ticker' ||
                                    (_imageUrl != null &&
                                        _imageUrl!.trim().isNotEmpty))
                                  'image_url': _imageUrl,
                                'type_banniere': _typeBanniere,
                                'texte_badge': _badgeCtrl.text.trim(),
                                'titre': _titreCtrl.text.trim(),
                                'sous_titre': _sousTitreCtrl.text.trim(),
                                'label_cta_1': _labelCta1Ctrl.text.trim(),
                                'lien_cta_1': _lienCta1Ctrl.text.trim(),
                                'label_cta_2': _labelCta2Ctrl.text.trim(),
                                'lien_cta_2': _lienCta2Ctrl.text.trim(),
                                'largeur_px': _largeurPxCtrl.text.trim(),
                                'hauteur_px': _hauteurPxCtrl.text.trim(),
                                'lien_externe': _lienExterneCtrl.text.trim(),
                                'ordre_pub': _ordrePubCtrl.text.trim(),
                                'couleur_badge': _couleurBadgeCtrl.text.trim(),
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
    TextInputType? keyboard,
  }) => TextFormField(
    controller: ctrl,
    maxLines: maxLines,
    keyboardType: keyboard,
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
