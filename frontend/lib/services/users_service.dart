import 'dart:convert';
import 'api_service.dart';

class UsersService {
  final ApiService _api = ApiService();

  Future<({Map<String, dynamic> user, Map<String, dynamic>? profil})> getMe() async {
    final res = await _api.get('/users/me', useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Profil introuvable');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final user = Map<String, dynamic>.from(data['user'] as Map);
    final profil = data['profil'] != null
        ? Map<String, dynamic>.from(data['profil'] as Map)
        : null;
    return (user: user, profil: profil);
  }

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> body) async {
    final res = await _api.patch('/users/me', body: body, useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur mise à jour');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(data['user'] as Map);
  }
}
