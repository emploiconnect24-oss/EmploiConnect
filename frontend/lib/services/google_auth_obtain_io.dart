import 'package:google_sign_in/google_sign_in.dart';

/// Android / iOS / desktop : [clientIdFromBackend] = Web client ID (serverClientId).
Future<({String? idToken, String? accessToken})> obtainGoogleTokensPlatform({
  required String clientIdFromBackend,
}) async {
  if (clientIdFromBackend.isEmpty) {
    return (idToken: null, accessToken: null);
  }

  final GoogleSignIn gsi = GoogleSignIn(
    scopes: const <String>['email', 'profile'],
    clientId: null,
    serverClientId: clientIdFromBackend,
  );

  await gsi.signOut();
  final GoogleSignInAccount? account = await gsi.signIn();
  if (account == null) {
    return (idToken: null, accessToken: null);
  }

  final GoogleSignInAuthentication auth = await account.authentication;
  return (idToken: auth.idToken, accessToken: auth.accessToken);
}

Future<void> signOutGooglePlatform({required String clientIdFromBackend}) async {
  if (clientIdFromBackend.isEmpty) return;
  final GoogleSignIn gsi = GoogleSignIn(
    scopes: const <String>['email', 'profile'],
    clientId: null,
    serverClientId: clientIdFromBackend,
  );
  await gsi.signOut();
}
