import 'dart:async';

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

  /// Notifications non lues (GET `/notifications/mes` → `nb_non_lues`).
  int nbNotificationsNonLues = 0;

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

  Future<void> loadDashboard() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
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
