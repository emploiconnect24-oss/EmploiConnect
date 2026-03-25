import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class CvService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> uploadCv(List<int> bytes, String filename) async {
    final streamed = await _api.postMultipart(
      '/cv/upload',
      fileBytes: bytes,
      filename: filename,
      useAuth: true,
    );
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur upload CV');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<Map<String, dynamic>> getMonCv() async {
    final res = await _api.get('/cv/me', useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Aucun CV');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<String?> getDownloadUrl({String? candidatureId}) async {
    final path = candidatureId != null
        ? '/cv/download-url?candidature_id=${Uri.encodeQueryComponent(candidatureId)}'
        : '/cv/download-url';
    final res = await _api.get(path, useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'URL indisponible');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['url'] as String?;
  }
}
