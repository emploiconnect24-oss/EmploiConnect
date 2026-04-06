import 'dart:convert';
import 'api_service.dart';

class CandidatDashboardService {
  final ApiService _api = ApiService();

  /// Vue d’ensemble + métriques (PRD ÉTAPE 3) — préféré à [getMetrics].
  Future<Map<String, dynamic>> getDashboard() async {
    final res = await _api.get('/candidat/dashboard', useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(
        ApiService.errorMessage(res) ?? 'Erreur chargement tableau de bord candidat',
      );
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<Map<String, dynamic>> getMetrics() async {
    final res = await _api.get('/candidat/dashboard/metrics', useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur chargement métriques candidat');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }
}

