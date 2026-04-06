import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class UsersService {
  final ApiService _api = ApiService();

  Future<
      ({
        Map<String, dynamic> user,
        Map<String, dynamic>? profil,
        Map<String, dynamic>? completionProfil,
      })> getMe() async {
    final res = await _api.get('/users/me', useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Profil introuvable');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final user = Map<String, dynamic>.from(data['user'] as Map);
    final profil = data['profil'] != null
        ? Map<String, dynamic>.from(data['profil'] as Map)
        : null;
    final completionProfil = data['completion_profil'] != null
        ? Map<String, dynamic>.from(data['completion_profil'] as Map)
        : null;
    return (
      user: user,
      profil: profil,
      completionProfil: completionProfil,
    );
  }

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> body) async {
    final res = await _api.patch('/users/me', body: body, useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur mise à jour');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(data['user'] as Map);
  }

  Future<void> deactivateMe() async {
    final res = await _api.patch(
      '/users/me/deactivate',
      body: const {},
      useAuth: true,
    );
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur désactivation');
    }
  }

  Future<void> deleteMe() async {
    final res = await _api.delete('/users/me', useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur suppression');
    }
  }

  Future<String> uploadMyPhoto({
    required List<int> bytes,
    required String filename,
  }) async {
    final streamed = await _api.postMultipart(
      '/users/me/photo',
      fileBytes: bytes,
      filename: filename,
      fieldName: 'photo',
      useAuth: true,
    );
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur upload photo');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final photoUrl = ((data['data'] as Map?)?['photo_url'] ?? '').toString();
    if (photoUrl.isEmpty) {
      throw Exception('URL photo manquante');
    }
    return photoUrl;
  }

  /// Enregistre un token FCM (mobile / web) pour les push backend.
  Future<void> registerPushToken(String token, {String plateforme = 'android'}) async {
    final res = await _api.post(
      '/users/me/push-token',
      body: {'token': token, 'plateforme': plateforme},
      useAuth: true,
    );
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur enregistrement push');
    }
  }

  Future<void> unregisterPushToken([String? token]) async {
    final res = await _api.delete(
      '/users/me/push-token',
      useAuth: true,
      body: token != null ? {'token': token} : null,
    );
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur suppression push');
    }
  }
}
