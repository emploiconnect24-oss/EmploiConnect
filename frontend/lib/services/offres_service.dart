import 'dart:convert';
import 'api_service.dart';

class OffresService {
  final ApiService _api = ApiService();

  Future<({List<Map<String, dynamic>> offres, int? total})> getOffres({
    String? statut,
    String? domaine,
    String? localisation,
    String? typeContrat,
    bool mesOffres = false,
    int offset = 0,
    int limit = 20,
  }) async {
    final q = <String, String>{
      'offset': '$offset',
      'limit': '$limit',
      ...?(statut == null ? null : {'statut': statut}),
      ...?((domaine == null || domaine.isEmpty) ? null : {'domaine': domaine}),
      ...?((localisation == null || localisation.isEmpty)
          ? null
          : {'localisation': localisation}),
      ...?((typeContrat == null || typeContrat.isEmpty)
          ? null
          : {'type_contrat': typeContrat}),
      ...?(mesOffres ? {'mes': '1'} : null),
    };
    final uri = '/offres?${q.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
    final res = await _api.get(uri, useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur chargement offres');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (data['offres'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    final total = data['total'] as int?;
    return (offres: list, total: total);
  }

  Future<Map<String, dynamic>> getOffreById(String id) async {
    final res = await _api.get('/offres/$id', useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Offre introuvable');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<List<Map<String, dynamic>>> getSuggestions({int limit = 15}) async {
    final res = await _api.get('/offres/suggestions?limit=$limit', useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur suggestions');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (data['suggestions'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    return list;
  }

  Future<Map<String, dynamic>> createOffre(Map<String, dynamic> body) async {
    final res = await _api.post('/offres', body: body, useAuth: true);
    if (res.statusCode != 201) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur création offre');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<Map<String, dynamic>> updateOffre(String id, Map<String, dynamic> body) async {
    final res = await _api.patch('/offres/$id', body: body, useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur mise à jour');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<void> deleteOffre(String id) async {
    final res = await _api.delete('/offres/$id', useAuth: true);
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur suppression');
    }
  }
}
