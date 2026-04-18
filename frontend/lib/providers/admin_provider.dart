import 'dart:async';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import '../services/admin_service.dart';

/// Données agrégées admin (dashboard + rafraîchissement périodique).
/// L’auth passe par [ApiService] / [AuthService] (pas de token passé ici).
class AdminProvider extends ChangeNotifier {
  AdminProvider() : _service = AdminService();

  final AdminService _service;

  Map<String, dynamic>? dashboardResponse;
  List<Map<String, dynamic>> evolution7d = const [];
  bool isLoading = false;
  String? error;

  int usersEnAttente = 0;
  int offresEnAttente = 0;
  int signalementsEnAttente = 0;
  int temoignagesEnAttente = 0;
  /// Non exposé par l’API actuelle — reste à 0.
  int messagesNonLus = 0;

  /// Permissions sections (`GET /admin/sous-admins/mes-permissions`).
  bool adminAccessLoaded = false;
  bool adminEstSuper = false;
  Map<String, dynamic> adminPermsBySection = {};
  String? adminRoleLabel;
  /// Hex API `admin_roles.couleur` (ex. `#1A56DB`).
  String? adminRoleCouleurHex;

  /// Alias pratiques (shell « accès refusé », tests).
  bool get estSuperAdmin => adminEstSuper;
  String? get roleNom => adminRoleLabel;
  Map<String, dynamic> get permissions => adminPermsBySection;

  String? get nomAdmin => adminNom;
  String? get emailAdmin => adminEmail;

  static const Map<String, String> _kTitresSection = {
    'dashboard': 'Tableau de bord',
    'utilisateurs': 'Utilisateurs',
    'offres': 'Offres d’emploi',
    'entreprises': 'Entreprises',
    'candidatures': 'Candidatures',
    'signalements': 'Modération',
    'temoignages': 'Témoignages',
    'parcours': 'Parcours carrière',
    'statistiques': 'Statistiques',
    'recherche': 'Recherche',
    'messages': 'Messages',
    'bannieres': 'Bannières',
    'newsletter': 'Newsletter',
    'newsletter_envoi': 'Envoi newsletter',
    'illustrations': 'Illustrations',
    'messages_contact': 'Messages contact',
    'equipe': 'Équipe',
    'parametres': 'Paramètres',
    'apropos': 'À propos',
  };

  /// Sections visibles (`peut_voir`) — utile si l’API n’a pas renvoyé `role.nom`.
  List<String> get _sectionsVisibles {
    final out = <String>[];
    adminPermsBySection.forEach((k, v) {
      if (v is Map && v['peut_voir'] == true) out.add(k);
    });
    out.sort();
    return out;
  }

  String? get _roleNomInfereDepuisPermissions {
    if (adminEstSuper) return null;
    final keys = _sectionsVisibles;
    if (keys.isEmpty) return null;
    if (keys.length == 1) {
      return _kTitresSection[keys.single] ?? keys.single;
    }
    return 'Accès ${keys.length} modules';
  }

  /// Nom de rôle affichable : API d’abord, sinon déduction depuis les permissions.
  String get roleNomEffectif {
    final api = (adminRoleLabel ?? '').trim();
    if (api.isNotEmpty) return api;
    return (_roleNomInfereDepuisPermissions ?? '').trim();
  }

  /// Libellé long (topbar, en-têtes).
  String get libelleRoleLong {
    if (adminEstSuper) return 'Super Administrateur';
    final api = (adminRoleLabel ?? '').trim();
    if (api.isNotEmpty) return api;
    final inf = _roleNomInfereDepuisPermissions;
    if (inf != null && inf.isNotEmpty) return inf;
    return 'Compte d’équipe';
  }

  /// Libellé court (badge sidebar / topbar compact).
  String get libelleRoleCourt {
    if (adminEstSuper) return 'Super Admin';
    final api = (adminRoleLabel ?? '').trim();
    if (api.isNotEmpty) {
      final s = api;
      if (s.length <= 22) return s;
      return '${s.substring(0, 19)}…';
    }
    final inf = _roleNomInfereDepuisPermissions;
    if (inf != null && inf.isNotEmpty) {
      if (inf.length <= 22) return inf;
      return '${inf.substring(0, 19)}…';
    }
    return 'Équipe';
  }

  String get descriptionAcces {
    if (adminEstSuper) return 'Accès complet à la plateforme';
    final api = (adminRoleLabel ?? '').trim();
    if (api.isNotEmpty) return 'Accès limité : $api';
    final keys = _sectionsVisibles;
    if (keys.isNotEmpty) {
      final noms = keys
          .map((k) => _kTitresSection[k] ?? k)
          .take(4)
          .join(', ');
      final suffix = keys.length > 4 ? '…' : '';
      return 'Accès limité aux modules : $noms$suffix';
    }
    return 'Droits définis par le super administrateur';
  }

  static const Color _kBleuRole = Color(0xFF1A56DB);
  static const Color _kRougeSuper = Color(0xFFEF4444);

  Color get couleurRole {
    if (adminEstSuper) return _kRougeSuper;
    return _parseCouleurHex(adminRoleCouleurHex);
  }

  static Color _parseCouleurHex(String? raw) {
    if (raw == null) return _kBleuRole;
    var s = raw.trim();
    if (s.isEmpty) return _kBleuRole;
    if (s.startsWith('#')) s = s.substring(1);
    try {
      if (s.length == 6) return Color(int.parse('FF$s', radix: 16));
      if (s.length == 8) return Color(int.parse(s, radix: 16));
    } catch (_) {}
    return _kBleuRole;
  }

  /// Notifications non lues (GET `/notifications/mes` → `nb_non_lues`).
  int nbNotificationsNonLues = 0;
  /// Messages de contact non lus (GET `/admin/messages-contact` → `non_lus`).
  int nbMessagesContactNonLus = 0;

  /// Profil admin connecté (GET `/admin/profil`) — pour avatar TopBar / Sidebar sans recharger.
  String? adminNom;
  String? adminEmail;
  String? adminPhotoUrl;

  Timer? _refreshTimer;

  Map<String, dynamic>? get dashboardData =>
      dashboardResponse?['data'] as Map<String, dynamic>?;

  Map<String, dynamic>? get statsNested =>
      dashboardData?['stats'] as Map<String, dynamic>?;

  void _applyProfilFromApi(dynamic data) {
    if (data is! Map) {
      adminNom = null;
      adminEmail = null;
      adminPhotoUrl = null;
      return;
    }
    final m = Map<String, dynamic>.from(data);
    adminNom = m['nom']?.toString().trim();
    if (adminNom != null && adminNom!.isEmpty) adminNom = null;
    adminEmail = m['email']?.toString().trim();
    if (adminEmail != null && adminEmail!.isEmpty) adminEmail = null;
    final p = m['photo_url']?.toString().trim();
    adminPhotoUrl = (p == null || p.isEmpty) ? null : p;
  }

  /// Après upload photo réussi — met à jour TopBar / Sidebar sans recharger la page.
  void updatePhoto(String newPhotoUrl) {
    final t = newPhotoUrl.trim();
    adminPhotoUrl = t.isEmpty ? null : t;
    notifyListeners();
  }

  /// Synchronise nom / email / photo depuis une map profil (ex. après GET `/admin/profil`).
  void syncProfilFromMap(Map<String, dynamic> m) {
    _applyProfilFromApi(m);
    notifyListeners();
  }

  void updateNbNotifications(int nb) {
    nbNotificationsNonLues = nb;
    notifyListeners();
  }

  void updateNbMessagesContactNonLus(int nb) {
    nbMessagesContactNonLus = nb < 0 ? 0 : nb;
    notifyListeners();
  }

  Future<void> refreshMessagesContactNonLus({bool notify = true}) async {
    try {
      final contact = await _service.getMessagesContactAdmin();
      nbMessagesContactNonLus = _i(contact['non_lus']);
      if (notify) notifyListeners();
    } catch (_) {
      // Conserver la dernière valeur connue si l'endpoint échoue.
    }
  }

  bool peutVoirSection(String? section) {
    if (section == null || section.isEmpty) return true;
    if (!adminAccessLoaded) return true;
    if (adminEstSuper) return true;
    final p = adminPermsBySection[section];
    if (p is Map && p['peut_voir'] == true) return true;
    return false;
  }

  Future<void> loadAdminAccess({bool force = false}) async {
    if (force) {
      adminAccessLoaded = false;
    }
    if (adminAccessLoaded && !force) return;
    try {
      final res = await _service.getMesPermissionsAdmin();
      final data = res['data'];
      if (data is Map) {
        adminEstSuper = data['est_super_admin'] == true;
        final perms = data['permissions'];
        if (perms is Map) {
          adminPermsBySection = Map<String, dynamic>.from(perms);
        } else {
          adminPermsBySection = <String, dynamic>{};
        }
        final role = data['role'];
        if (role is Map) {
          adminRoleLabel = role['nom']?.toString();
          final c = role['couleur']?.toString().trim();
          adminRoleCouleurHex = (c == null || c.isEmpty) ? null : c;
        } else {
          adminRoleLabel = null;
          adminRoleCouleurHex = null;
        }
      }
    } catch (_) {
      // Ne pas promouvoir en super admin : évite « accès complet » mensonger.
      adminEstSuper = false;
      adminPermsBySection = {};
      adminRoleLabel = null;
      adminRoleCouleurHex = null;
    }
    adminAccessLoaded = true;
    notifyListeners();
  }

  void resetAdminAccess() {
    adminAccessLoaded = false;
    adminEstSuper = false;
    adminPermsBySection = {};
    adminRoleLabel = null;
    adminRoleCouleurHex = null;
  }

  Future<void> loadDashboard() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      try {
        await loadAdminAccess();
      } catch (_) {
        // Rôle / sections : ne pas bloquer le tableau de bord
      }

      final dash = await _service.getDashboard();
      final week = await _service.getStatistiques(periode: '7d');
      final dataWeek = week['data'] as Map<String, dynamic>?;
      final ev = (dataWeek?['evolution_par_jour'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const <Map<String, dynamic>>[];

      dashboardResponse = dash;
      evolution7d = ev;

      final data = dash['data'] as Map<String, dynamic>?;
      final stats = data?['stats'] as Map<String, dynamic>?;
      final u = stats?['utilisateurs'] as Map<String, dynamic>?;
      final o = stats?['offres'] as Map<String, dynamic>?;

      usersEnAttente = _i(u?['en_attente']);
      offresEnAttente = _i(o?['en_attente']);
      signalementsEnAttente = _i(dash['nombre_signalements_en_attente']);
      temoignagesEnAttente = _i(dash['nombre_temoignages_en_attente']);

      try {
        final profil = await _service.getProfilAdmin();
        _applyProfilFromApi(profil['data']);
      } catch (_) {
        // Dashboard reste utilisable si /admin/profil échoue
      }

      try {
        final mes = await _service.getMesNotifications(limite: 1);
        final d = mes['data'];
        if (d is Map) {
          nbNotificationsNonLues = _i(d['nb_non_lues']);
        }
      } catch (_) {
        // Badge reste inchangé si l’endpoint échoue
      }
      await refreshMessagesContactNonLus(notify: false);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  static int _i(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      loadDashboard();
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
