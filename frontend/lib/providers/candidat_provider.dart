import 'package:flutter/foundation.dart';
import '../services/candidat_dashboard_service.dart';

class CandidatProvider with ChangeNotifier {
  final CandidatDashboardService _svc = CandidatDashboardService();

  bool _loading = false;
  Map<String, dynamic> _menuBadges = const {};
  Map<String, dynamic> _kpis = const {};
  Map<String, dynamic> _profile = const {};
  Map<String, dynamic> _overview = const {};
  Map<String, String>? _messageriePrefill;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;
  Map<String, dynamic> get menuBadges => _menuBadges;
  Map<String, dynamic> get kpis => _kpis;
  Map<String, dynamic> get profile => _profile;
  Map<String, String>? get messageriePrefill => _messageriePrefill;
  /// Données étendues du GET /candidat/dashboard (offres récentes, candidatures, stats…).
  Map<String, dynamic> get overview => _overview;

  /// % complétion profil — même logique que GET /users/me (sidebar, dashboard, profil).
  int get profileCompletionPercent {
    final k = _kpis['profile_completion'];
    if (k is int) return k.clamp(0, 100);
    if (k is num) return k.round().clamp(0, 100);
    final cp = _overview['completion_profil'];
    if (cp is Map && cp['pourcentage'] is num) {
      return (cp['pourcentage'] as num).round().clamp(0, 100);
    }
    return 0;
  }

  int badge(String key) {
    final v = _menuBadges[key];
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  Future<void> loadDashboardMetrics() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _svc.getDashboard();
      final data = (res['data'] as Map?)?.cast<String, dynamic>() ?? {};
      _overview = data;
      _menuBadges =
          (data['menu_badges'] as Map?)?.cast<String, dynamic>() ?? const {};
      _kpis = (data['kpis'] as Map?)?.cast<String, dynamic>() ?? const {};
      _profile = (data['profile'] as Map?)?.cast<String, dynamic>() ?? const {};
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void recalculerCompletion(Map<String, dynamic> profil) {
    int pts = 0;
    final u = (profil['utilisateur'] as Map?)?.cast<String, dynamic>() ?? {};
    if ((u['photo_url'] as String?)?.isNotEmpty == true) pts += 15;
    if ((u['nom'] as String?)?.isNotEmpty == true) pts += 10;
    if ((u['telephone'] as String?)?.isNotEmpty == true) pts += 5;
    if ((u['adresse'] as String?)?.isNotEmpty == true) pts += 5;
    if ((profil['titre_poste'] as String?)?.isNotEmpty == true) pts += 10;
    if ((profil['about'] as String?)?.isNotEmpty == true) pts += 10;

    final comps = profil['competences'] as List? ?? const [];
    if (comps.isNotEmpty) pts += 10;

    final cv = profil['cv'] as Map?;
    if (cv?['fichier_url'] != null) pts += 20;

    final analyse = cv?['analyse'] as Map?;
    if ((analyse?['competences'] as List? ?? const []).isNotEmpty) pts += 10;

    if ((profil['disponibilite'] as String?)?.isNotEmpty == true) pts += 5;

    final next = pts.clamp(0, 100);
    _kpis = {
      ..._kpis,
      'profile_completion': next,
    };
    notifyListeners();
  }

  void setMessageriePrefill({
    required String peerId,
    required String nom,
    String? photoUrl,
  }) {
    _messageriePrefill = {
      'peerId': peerId,
      'nom': nom,
      if (photoUrl != null && photoUrl.trim().isNotEmpty) 'photoUrl': photoUrl.trim(),
    };
    notifyListeners();
  }

  void clearMessageriePrefill() {
    _messageriePrefill = null;
    notifyListeners();
  }
}
