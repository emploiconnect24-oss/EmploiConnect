import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

const _keyToken = 'emploiconnect_token';
const _keyUser = 'emploiconnect_user';

class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  Future<void> saveSession(String token, Map<String, dynamic> user) async {
    final prefs = await _prefs;
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user));
  }

  Future<String?> getToken() async {
    final prefs = await _prefs;
    return prefs.getString(_keyToken);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyUser);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Met à jour les champs utilisateur stockés localement (ex. après changement d’e-mail en profil admin).
  Future<void> patchStoredUser(Map<String, dynamic> updates) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyUser);
    if (raw == null) return;
    try {
      final cur = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      updates.forEach((k, v) {
        if (v != null) cur[k] = v;
      });
      await prefs.setString(_keyUser, jsonEncode(cur));
    } catch (_) {}
  }

  Future<void> logout() async {
    final prefs = await _prefs;
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }

  Future<bool> get isLoggedIn async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<(bool, String?)> register({
    required String email,
    required String motDePasse,
    required String nom,
    required String role,
    String? telephone,
    String? adresse,
  }) async {
    final res = await ApiService().post('/auth/register', body: {
      'email': email,
      'mot_de_passe': motDePasse,
      'nom': nom,
      'role': role,
      ...?(telephone == null ? null : {'telephone': telephone}),
      ...?(adresse == null ? null : {'adresse': adresse}),
    });
    if (res.statusCode == 201) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final token = data['token'] as String?;
      final user = data['user'] as Map<String, dynamic>?;
      if (token != null && user != null) {
        await saveSession(token, user);
        return (true, null);
      }
    }
    final msg = ApiService.errorMessage(res) ?? 'Erreur lors de l\'inscription';
    return (false, msg);
  }

  Future<(bool, String?)> login({
    required String email,
    required String motDePasse,
  }) async {
    final res = await ApiService().post('/auth/login', body: {
      'email': email,
      'mot_de_passe': motDePasse,
    });
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final token = data['token'] as String?;
      final user = data['user'] as Map<String, dynamic>?;
      if (token != null && user != null) {
        await saveSession(token, user);
        return (true, null);
      }
    }
    final msg = ApiService.errorMessage(res) ?? 'Email ou mot de passe incorrect';
    return (false, msg);
  }

  /// Demande de lien de réinitialisation (réponse générique côté API).
  Future<(bool ok, String? message)> forgotPassword(String email) async {
    final res = await ApiService().post(
      '/auth/forgot-password',
      body: {'email': email.trim().toLowerCase()},
    );
    if (res.statusCode == 200) return (true, null);
    return (false, ApiService.errorMessage(res));
  }

  Future<(bool ok, String? message)> resetPassword({
    required String token,
    required String motDePasse,
  }) async {
    final res = await ApiService().post(
      '/auth/reset-password',
      body: {'token': token, 'mot_de_passe': motDePasse},
    );
    if (res.statusCode == 200) return (true, null);
    return (false, ApiService.errorMessage(res));
  }
}
