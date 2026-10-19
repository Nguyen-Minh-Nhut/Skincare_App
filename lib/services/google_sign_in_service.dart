import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';

class GoogleSignInService {
  GoogleSignInService({
    Future<GoogleSignInAccount?> Function()? login,
    Future<UserCredential> Function(OAuthCredential credential)? authenticate,
  }) : _login = login,
       _authenticate = authenticate;

  final Future<GoogleSignInAccount?> Function()? _login;
  final Future<UserCredential> Function(OAuthCredential credential)?
  _authenticate;
  static final GoogleSignIn _google = GoogleSignIn(
    scopes: ['email'],
    clientId: !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
        ? DefaultFirebaseOptions.ios.iosClientId
        : null,
  );

  Future<UserCredential?> signIn() async {
    if (kIsWeb && _login == null) {
      return FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    }
    // Account selection, browser login and 2FA are user-driven; do not time out
    // this dialog while the native SDK still has a sign-in in progress.
    final account = await (_login?.call() ?? _google.signIn());
    if (account == null) return null;
    final tokens = await account.authentication.timeout(
      const Duration(seconds: 30),
    );
    if (tokens.idToken == null || tokens.idToken!.isEmpty) {
      throw FirebaseAuthException(
        code: 'google-id-token-missing',
        message:
            'Google không trả về ID token. Cần kiểm tra OAuth client của ứng dụng.',
      );
    }
    final credential = GoogleAuthProvider.credential(
      idToken: tokens.idToken,
      accessToken: tokens.accessToken,
    );
    return (_authenticate?.call(credential) ??
            FirebaseAuth.instance.signInWithCredential(credential))
        .timeout(const Duration(seconds: 30));
  }
}
