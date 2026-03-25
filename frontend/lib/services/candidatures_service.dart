import 'dart:convert';
import 'api_service.dart';

class CandidaturesService {
  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> getCandidatures({String? offreId}) async {
    final path = offreId != null
        ? '/candidatures?offre_id=${Uri.encodeQueryComponent(offreId)}'
        : '/candidatures';
    final res = await _api.get(path, useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur candidatures');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (data['candidatures'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    return list;
  }

  Future<Map<String, dynamic>> getCandidatureById(String id) async {
    final res = await _api.get('/candidatures/$id', useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Candidature introuvable');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<Map<String, dynamic>> postuler({
    required String offreId,
    String? lettreMotivation,
    String? cvId,
  }) async {
    final body = <String, dynamic>{
      'offre_id': offreId,
      ...?((lettreMotivation == null || lettreMotivation.isEmpty)
          ? null
          : {'lettre_motivation': lettreMotivation}),
      ...?(cvId == null ? null : {'cv_id': cvId}),
    };
    final res = await _api.post('/candidatures', body: body, useAuth: true);
    if (res.statusCode != 201) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur candidature');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<Map<String, dynamic>> updateStatut(String id, String statut) async {
    final res = await _api.patch('/candidatures/$id', body: {'statut': statut}, useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur mise à jour');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }
}
