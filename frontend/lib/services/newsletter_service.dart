import 'dart:convert';

import 'api_service.dart';

class NewsletterService {
  final ApiService _api = ApiService();

  Future<({bool success, String? message, bool dejaAbonne})> subscribe({
    required String email,
    String? nom,
    String source = 'footer',
  }) async {
    final res = await _api.post(
      '/newsletter/subscribe',
      body: {
        'email': email.trim(),
        if (nom != null && nom.trim().isNotEmpty) 'nom': nom.trim(),
        'source': source,
      },
      useAuth: false,
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final ok = res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true;
    return (
      success: ok,
      message: body['message'] as String?,
      dejaAbonne: body['deja_abonne'] == true,
    );
  }
}
