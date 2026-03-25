import 'dart:convert';
import 'api_service.dart';

class SignalementsService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> signaler({
    required String typeObjet,
    required String objetId,
    required String raison,
  }) async {
    final res = await _api.post(
      '/signalements',
      body: {
        'type_objet': typeObjet,
        'objet_id': objetId,
        'raison': raison,
      },
      useAuth: true,
    );
    if (res.statusCode != 201) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur signalement');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }
}
