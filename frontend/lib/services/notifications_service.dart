import 'dart:convert';
import 'api_service.dart';

class NotificationsService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getMesNotifications({
    int page = 1,
    int limite = 30,
    bool nonLuesSeulement = false,
  }) async {
    final qs =
        '?page=$page&limite=$limite&non_lues_seulement=${nonLuesSeulement ? 'true' : 'false'}';
    final res = await _api.get('/notifications/mes$qs', useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(ApiService.errorMessage(res) ?? 'Erreur notifications');
    }
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<void> markAllRead() async {
    final res = await _api.patch(
      '/notifications/tout-lire/action',
      useAuth: true,
    );
    if (res.statusCode != 200) {
      throw Exception(
        ApiService.errorMessage(res) ?? 'Erreur marquage notifications',
      );
    }
  }

  Future<void> markRead(String id) async {
    final res = await _api.patch('/notifications/$id', useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(
        ApiService.errorMessage(res) ?? 'Erreur marquage notification',
      );
    }
  }

  Future<void> remove(String id) async {
    final res = await _api.delete('/notifications/$id', useAuth: true);
    if (res.statusCode != 200) {
      throw Exception(
        ApiService.errorMessage(res) ?? 'Erreur suppression notification',
      );
    }
  }

  Future<void> savePreferences({
    required bool emailCandidature,
    required bool emailMessage,
    required bool notifInApp,
    bool? offresAlertesEmail,
    bool? resumeHebdo,
    bool? conseilsEmail,
  }) async {
    final res = await _api.post(
      '/notifications/parametres',
      useAuth: true,
      body: {
        'email_candidature': emailCandidature,
        'email_message': emailMessage,
        'notif_in_app': notifInApp,
        if (offresAlertesEmail != null) 'offres_alertes_email': offresAlertesEmail,
        if (resumeHebdo != null) 'resume_hebdo': resumeHebdo,
        if (conseilsEmail != null) 'conseils_email': conseilsEmail,
      },
    );
    if (res.statusCode != 200) {
      throw Exception(
        ApiService.errorMessage(res) ??
            'Erreur sauvegarde préférences notifications',
      );
    }
  }
}
