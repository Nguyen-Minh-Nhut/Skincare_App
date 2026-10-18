import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

/// Exchanges Facebook credentials through Firebase; never stores Facebook tokens.
class FacebookSignInService {
  FacebookSignInService({
    Future<LoginResult> Function(String hashedNonce)? login,
    Future<UserCredential> Function(OAuthCredential credential)? authenticate,
  }) : _login = login,
       _authenticate = authenticate;

  final Future<LoginResult> Function(String hashedNonce)? _login;
  final Future<UserCredential> Function(OAuthCredential credential)?
  _authenticate;

  Future<UserCredential?> signIn() async {
    if (kIsWeb && _login == null) {
      return FirebaseAuth.instance.signInWithPopup(
        FacebookAuthProvider()..addScope('email'),
      );
    }
    if (_login == null &&
        defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      throw FirebaseAuthException(
        code: 'unsupported-platform',
        message:
            'Vui lòng đăng nhập Facebook trên Android, iPhone hoặc bản web.',
      );
    }
    final random = Random.secure();
    final rawNonce = base64UrlEncode(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    // The interactive dialog must allow time for passwords and two-factor auth.
    final result =
        await (_login?.call(hashedNonce) ??
            FacebookAuth.instance.login(
              permissions: ['email', 'public_profile'],
              loginTracking: LoginTracking.limited,
              nonce: defaultTargetPlatform == TargetPlatform.iOS
                  ? hashedNonce
                  : null,
            ));
    if (result.status == LoginStatus.cancelled) return null;
    if (result.status == LoginStatus.operationInProgress) {
      throw FirebaseAuthException(
        code: 'facebook-in-progress',
        message:
            'Một lần đăng nhập Facebook đang mở. Hãy hoàn tất hoặc đóng cửa sổ đó.',
      );
    }
    final token = result.accessToken;
    if (result.status != LoginStatus.success ||
        token == null ||
        token.tokenString.isEmpty) {
      throw FirebaseAuthException(
        code: 'facebook-login-failed',
        message:
            'Facebook chưa cho phép đăng nhập. Vui lòng thử lại hoặc kiểm tra cấu hình ứng dụng Meta.',
      );
    }
    // Limited Login returns an ID token, not a classic Graph API access token.
    final credential = token.type == AccessTokenType.limited
        ? OAuthProvider(
            'facebook.com',
          ).credential(idToken: token.tokenString, rawNonce: rawNonce)
        : FacebookAuthProvider.credential(token.tokenString);
    return (_authenticate?.call(credential) ??
            FirebaseAuth.instance.signInWithCredential(credential))
        .timeout(const Duration(seconds: 20));
  }
}
