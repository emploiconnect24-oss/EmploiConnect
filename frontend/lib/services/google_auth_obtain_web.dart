import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Web : popup OAuth ([GoogleSignIn.signIn]). Souvent **access_token** sans **id_token** ;
/// le backend accepte [access_token] et valide via tokeninfo + userinfo.
Future<({String? idToken, String? accessToken})> obtainGoogleTokensPlatform({
  required String clientIdFromBackend,
}) async {
  if (clientIdFromBackend.isEmpty) {
    return (idToken: null, accessToken: null);
  }

  debugPrint('[GoogleAuth] Web popup: GoogleSignIn (clientId + scopes openid)');

  final GoogleSignIn googleSignIn = GoogleSignIn(
    clientId: clientIdFromBackend,
    scopes: const <String>['email', 'profile', 'openid'],
  );

  try {
    await googleSignIn.signOut();
  } catch (e) {
    debugPrint('[GoogleAuth] Web popup: signOut (ignore): $e');
  }
  try {
    await googleSignIn.disconnect();
  } catch (_) {}

  debugPrint('[GoogleAuth] Web popup: signIn()…');
  final GoogleSignInAccount? account = await googleSignIn.signIn();
  if (account == null) {
    debugPrint('[GoogleAuth] Web popup: annulé');
    return (idToken: null, accessToken: null);
  }

  debugPrint('[GoogleAuth] Web popup: compte ${account.email}');
  final GoogleSignInAuthentication auth = await account.authentication;
  final String? idToken = auth.idToken;
  final String? accessToken = auth.accessToken;
  debugPrint(
    '[GoogleAuth] Web popup: idToken=${idToken != null && idToken.isNotEmpty ? "OK" : "NULL"} '
    'accessToken=${accessToken != null && accessToken.isNotEmpty ? "OK" : "NULL"}',
  );

  if ((idToken == null || idToken.isEmpty) &&
      (accessToken == null || accessToken.isEmpty)) {
    debugPrint('[GoogleAuth] Web popup: aucun jeton utilisable');
    return (idToken: null, accessToken: null);
  }

  return (idToken: idToken, accessToken: accessToken);
}

Future<void> signOutGooglePlatform({required String clientIdFromBackend}) async {
  if (clientIdFromBackend.isEmpty) return;
  final GoogleSignIn googleSignIn = GoogleSignIn(
    clientId: clientIdFromBackend,
    scopes: const <String>['email', 'profile', 'openid'],
  );
  try {
    await googleSignIn.signOut();
  } catch (e) {
    debugPrint('[GoogleAuth] Web popup signOut: $e');
  }
}
