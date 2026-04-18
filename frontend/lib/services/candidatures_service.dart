import 'dart:convert';
import 'api_service.dart';

class CandidaturesService {
  final ApiService _api = ApiService();

  Future<
    ({List<Map<String, dynamic>> candidatures, Map<String, dynamic> stats})
  >
  getMesCandidatures({
    String? statut,
    int page = 1,
    int limite = 50,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limite': '$limite',
    };
    if (statut != null && statut.isNotEmpty && statut != 'all') {
      params['statut'] = statut;
    }
    final q = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    final res = await _api.get('/candidat/candidatures?$q', useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur candidatures');
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final data = (map['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final list = (data['candidatures'] as List<dynamic>? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final stats = (data['stats'] as Map?)?.cast<String, dynamic>() ?? const {};
    return (candidatures: list, stats: stats);
  }

  Future<List<Map<String, dynamic>>> getCandidatures({String? offreId}) async {
    final path = offreId != null
        ? '/candidatures?offre_id=${Uri.encodeQueryComponent(offreId)}'
        : '/candidatures';
    final res = await _api.get(path, useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur candidatures');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list =
        (data['candidatures'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    return list;
  }

  Future<Map<String, dynamic>> getCandidatureById(String id) async {
    final res = await _api.get('/candidatures/$id', useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(
        ApiService.errorMessage(res) ?? 'Candidature introuvable',
      );
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<Map<String, dynamic>> getAnalysePrePostulation(String offreId) async {
    final res = await _api.get(
      '/candidat/offres/${Uri.encodeComponent(offreId)}/analyse',
      useAuth: true,
    );
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Analyse indisponible');
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return (map['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> postuler({
    required String offreId,
    required String lettreMotivation,
    String? cvId,
  }) async {
    final lm = lettreMotivation.trim();
    if (lm.length < 100) {
      throw Exception(
        'La lettre de motivation doit contenir au moins 100 caractères.',
      );
    }
    if (lm.length > 4000) {
      throw Exception(
        'La lettre de motivation ne doit pas dépasser 4000 caractères.',
      );
    }
    final body = <String, dynamic>{
      'offre_id': offreId,
      'lettre_motivation': lm,
      ...?(cvId == null ? null : {'cv_id': cvId}),
    };
    final res = await _api.post('/candidatures', body: body, useAuth: true);
    if (res.statusCode != 201) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur candidature');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<Map<String, dynamic>> updateStatut(String id, String statut) async {
    final res = await _api.patch(
      '/candidatures/$id',
      body: {'statut': statut},
      useAuth: true,
    );
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur mise à jour');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }
}
