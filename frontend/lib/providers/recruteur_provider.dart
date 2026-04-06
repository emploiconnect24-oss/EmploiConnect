import 'package:flutter/material.dart';

import '../services/recruteur_service.dart';

class RecruteurProvider extends ChangeNotifier {
  final RecruteurService _svc = RecruteurService();

  Map<String, dynamic>? dashboardData;
  Map<String, dynamic>? profil;

  int nbOffresActives = 0;
  int nbCandidatures = 0;
  int nbCandidEnAttente = 0;
  int nbMessagesNonLus = 0;
  int nbNotificationsNonLues = 0;

  bool isLoading = false;
  bool isLoaded = false;
  String? error;

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  Future<void> loadAll(String token) async {
    if (token.isEmpty) {
      error = 'Token manquant';
      notifyListeners();
      return;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _svc.getDashboard(token).catchError((_) => <String, dynamic>{'success': false, 'data': {}}),
        _svc.getProfil(token).catchError((_) => <String, dynamic>{'success': false, 'data': {}}),
        _svc.getNotifications(token).catchError((_) => <String, dynamic>{'success': false, 'data': {}}),
      ]);

      final dashRes = results[0];
      final profilRes = results[1];
      final notifRes = results[2];

      if (dashRes['success'] == true) {
        final dash = dashRes['data'] as Map<String, dynamic>? ?? {};
        dashboardData = dash;
        final stats = dash['stats'] as Map<String, dynamic>? ?? {};
        nbOffresActives = _asInt(stats['offres_actives']);
        nbCandidatures = _asInt(stats['total_candidatures']);
        nbCandidEnAttente = _asInt(stats['candidatures_en_attente']);
        nbMessagesNonLus = _asInt(stats['messages_non_lus']);
      } else {
        error = dashRes['message']?.toString();
      }
      if (profilRes['success'] == true) {
        profil = profilRes['data'] as Map<String, dynamic>?;
      }
      if (notifRes['success'] == true) {
        final notifs = notifRes['data'] as Map<String, dynamic>? ?? {};
        nbNotificationsNonLues = _asInt(notifs['nb_non_lues']);
      }
      isLoaded = true;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCounts(String token) async {
    try {
      final dash = await _svc.getDashboard(token);
      final stats = dash['data']?['stats'] as Map<String, dynamic>? ?? {};
      nbOffresActives = _asInt(stats['offres_actives']);
      nbCandidatures = _asInt(stats['total_candidatures']);
      nbCandidEnAttente = _asInt(stats['candidatures_en_attente']);
      nbMessagesNonLus = _asInt(stats['messages_non_lus']);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refresh(String token) async {
    isLoaded = false;
    await loadAll(token);
  }

  void updateNbMessages(int n) {
    nbMessagesNonLus = n;
    notifyListeners();
  }

  void updateNbNotifications(int n) {
    nbNotificationsNonLues = n;
    notifyListeners();
  }

  void updateProfil(Map<String, dynamic> data) {
    profil = {...?profil, ...data};
    notifyListeners();
  }
}
