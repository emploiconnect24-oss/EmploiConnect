/// Aucune plateforme reconnue (ne devrait pas arriver avec Flutter).
Future<({String? idToken, String? accessToken})> obtainGoogleTokensPlatform({
  required String clientIdFromBackend,
}) async {
  throw UnsupportedError('Google Sign-In non disponible sur cette plateforme.');
}

Future<void> signOutGooglePlatform({required String clientIdFromBackend}) async {}
