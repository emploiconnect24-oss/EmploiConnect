import 'dart:convert';
import 'api_service.dart';

class OffresService {
  final ApiService _api = ApiService();

  Future<({List<Map<String, dynamic>> offres, int? total})> getOffres({
    String? statut,
    String? domaine,
    String? localisation,
    String? typeContrat,
    String? recherche,
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
      ...?((recherche == null || recherche.trim().isEmpty)
          ? null
          : {'recherche': recherche.trim()}),
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

  /// Liste publique (sans JWT) — page d’accueil, visiteurs.
  Future<({List<Map<String, dynamic>> offres, int? total})> getOffresPublic({
    int offset = 0,
    int limit = 12,
    String? recherche,
    String? entrepriseId,
  }) async {
    final qs = <String, String>{
      'offset': '$offset',
      'limit': '$limit',
      ...?((recherche == null || recherche.trim().isEmpty)
          ? null
          : {'recherche': recherche.trim()}),
      ...?((entrepriseId == null || entrepriseId.trim().isEmpty)
          ? null
          : {'entreprise_id': entrepriseId.trim()}),
    };
    final uri =
        '/offres?${qs.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
    final res = await _api.get(uri, useAuth: false);
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

  /// Détail offre sans JWT (offres publiées uniquement côté API).
  Future<Map<String, dynamic>> getOffreByIdPublic(String id) async {
    final res = await _api.get('/offres/$id', useAuth: false);
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
    final rawList = (data['data'] as List<dynamic>?) ?? (data['suggestions'] as List<dynamic>?);
    final list = rawList
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

  Future<Map<String, dynamic>> ameliorerDescription({
    required String descriptionOriginale,
    required String titrePoste,
    required List<String> competencesRequises,
    required String typeContrat,
  }) async {
    final res = await _api.post(
      '/recruteur/offres/ameliorer-description',
      body: {
        'description_originale': descriptionOriginale,
        'titre_poste': titrePoste,
        'competences_requises': competencesRequises,
        'type_contrat': typeContrat,
      },
      useAuth: true,
    );
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur amélioration IA');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<void> deleteOffre(String id) async {
    final res = await _api.delete('/offres/$id', useAuth: true);
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur suppression');
    }
  }

  Future<List<Map<String, dynamic>>> getSavedOffres() async {
    final res = await _api.get('/candidat/sauvegardes', useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur chargement sauvegardes');
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final data = (map['data'] as List<dynamic>? ?? const []);
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> saveOffre(String offreId) async {
    final res = await _api.post('/candidat/sauvegardes', body: {'offre_id': offreId}, useAuth: true);
    if (res.statusCode != 201) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur sauvegarde');
    }
  }

  Future<void> removeSavedOffre(String offreId) async {
    final res = await _api.delete('/candidat/sauvegardes/$offreId', useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur suppression sauvegarde');
    }
  }
}
