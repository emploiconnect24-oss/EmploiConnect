import 'package:flutter/foundation.dart';
import '../services/candidat_dashboard_service.dart';

class CandidatProvider with ChangeNotifier {
  final CandidatDashboardService _svc = CandidatDashboardService();

  bool _loading = false;
  Map<String, dynamic> _menuBadges = const {};
  Map<String, dynamic> _kpis = const {};
  Map<String, dynamic> _profile = const {};
  Map<String, dynamic> _overview = const {};
  String? _error;

  bool get loading => _loading;
  String? get error => _error;
  Map<String, dynamic> get menuBadges => _menuBadges;
  Map<String, dynamic> get kpis => _kpis;
  Map<String, dynamic> get profile => _profile;
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
}
