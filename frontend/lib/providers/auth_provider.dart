import 'package:flutter/material.dart';
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

  /// [role] : uniquement à l’inscription (register). À la connexion (login), laisser `null` : le rôle vient de la BDD.
  Future<(bool ok, String? message, bool pendingValidation)> loginWithGoogle({
    String? role,
  }) async {
    final (ok, msg, pending) = await _auth.loginWithGoogle(role: role);
    if (ok) await loadSession();
    return (ok, msg, pending);
  }

  /// Après login / register réussi : [HomeShellScreen] lit le rôle en session et affiche candidat, recruteur ou admin.
  void navigateToAuthenticatedHome(BuildContext context) {
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
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
