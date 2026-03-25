import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _auth = AuthService();

  String? _token;
  Map<String, dynamic>? _user;
  bool _sessionLoaded = false;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  String? get role => _user?['role'] as String?;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  bool get sessionLoaded => _sessionLoaded;

  Future<void> loadSession() async {
    _token = await _auth.getToken();
    _user = await _auth.getUser();
    _sessionLoaded = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.logout();
    _token = null;
    _user = null;
    notifyListeners();
  }

  Future<(bool, String?)> login({required String email, required String motDePasse}) async {
    final (ok, msg) = await _auth.login(email: email, motDePasse: motDePasse);
    if (ok) await loadSession();
    return (ok, msg);
  }

  Future<(bool, String?)> register({
    required String email,
    required String motDePasse,
    required String nom,
    required String role,
    String? telephone,
    String? adresse,
  }) async {
    final (ok, msg) = await _auth.register(
      email: email,
      motDePasse: motDePasse,
      nom: nom,
      role: role,
      telephone: telephone,
      adresse: adresse,
    );
    if (ok) await loadSession();
    return (ok, msg);
  }
}
