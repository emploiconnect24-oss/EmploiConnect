import 'dart:convert';

import 'api_service.dart';

class CandidatTemoignageService {
  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> getEligible() async {
    final res = await _api.get('/candidat/temoignages/eligible', useAuth: true);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur');
    }
    final data = body['data'] as Map<String, dynamic>?;
    final raw = data?['items'] as List<dynamic>? ?? const [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> submit({required String candidatureId, required String message}) async {
    final res = await _api.post(
      '/candidat/temoignages',
      body: {'candidature_id': candidatureId, 'message': message},
      useAuth: true,
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Envoi impossible');
    }
  }
}
