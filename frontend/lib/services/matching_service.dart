import 'dart:convert';

import 'api_service.dart';

class MatchingService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getScore(String offreId) async {
    final res = await _api.post(
      '/matching/score',
      body: {'offre_id': offreId},
      useAuth: true,
    );
    return _parseJson(res.body, res.statusCode, 'Erreur calcul score IA');
  }

  Future<Map<String, dynamic>> getScoresMultiples(List<String> offreIds) async {
    final ids = offreIds.where((e) => e.trim().isNotEmpty).join(',');
    if (ids.isEmpty) return {'success': true, 'data': <String, dynamic>{}};
    final res = await _api.get('/matching/scores-offres?offre_ids=$ids', useAuth: true);
    return _parseJson(res.body, res.statusCode, 'Erreur calcul scores IA');
  }

  Future<Map<String, dynamic>> analyserCV() async {
    final res = await _api.post('/cv/analyser', body: {}, useAuth: true);
    return _parseJson(res.body, res.statusCode, 'Erreur analyse CV');
  }

  Future<Map<String, dynamic>> getSuggestions({int limite = 10}) async {
    final res = await _api.get('/offres/suggestions?limite=$limite', useAuth: true);
    return _parseJson(res.body, res.statusCode, 'Erreur suggestions IA');
  }

  /// PRD §6 : score profil + conseils + offres scorées.
  Future<Map<String, dynamic>> getRecommandationsIa({int limite = 24}) async {
    final res = await _api.get(
      '/candidat/recommandations?limite=$limite',
      useAuth: true,
    );
    return _parseJson(res.body, res.statusCode, 'Erreur recommandations IA');
  }

  Map<String, dynamic> _parseJson(String body, int status, String fallbackMessage) {
    final parsed = jsonDecode(body) as Map<String, dynamic>;
    if (status >= 400) {
      throw Exception(parsed['message']?.toString() ?? fallbackMessage);
    }
    return parsed;
  }
}

