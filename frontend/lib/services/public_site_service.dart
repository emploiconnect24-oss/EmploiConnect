import 'dart:convert';

import 'api_service.dart';

/// Endpoints vitrine sans JWT (hors offres).
class PublicSiteService {
  final ApiService _api = ApiService();

  /// Top entreprises par nombre d’offres publiées (`GET /entreprises/top-public`).
  Future<List<Map<String, dynamic>>> getTopEntreprises({int limit = 12}) async {
    final res = await _api.get(
      '/entreprises/top-public?limit=$limit',
      useAuth: false,
    );
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur top entreprises');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final raw = data['data'] as List<dynamic>? ?? const [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Témoignages recrutés affichés sur l’accueil (`GET /temoignages/public`).
  Future<List<Map<String, dynamic>>> getTemoignagesPublic({int limit = 12}) async {
    final res = await _api.get(
      '/temoignages/public?limit=$limit',
      useAuth: false,
    );
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur témoignages');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final raw = data['data'] as List<dynamic>? ?? const [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
