import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_app/services/facebook_sign_in_service.dart';

class _CredentialResult extends Fake implements UserCredential {}

void main() {
  test('cancellation never authenticates with Firebase', () async {
    final service = FacebookSignInService(
      login: (_) async => LoginResult(status: LoginStatus.cancelled),
      authenticate: (_) => throw StateError('Must not authenticate'),
    );
    expect(await service.signIn(), isNull);
  });

  for (final status in [
    LoginStatus.failed,
    LoginStatus.operationInProgress,
    LoginStatus.success,
  ]) {
    test('$status without a token never authenticates', () async {
      final service = FacebookSignInService(
        login: (_) async => LoginResult(status: status),
        authenticate: (_) => throw StateError('Must not authenticate'),
      );
      await expectLater(
        service.signIn(),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  }

  test('classic token is exchanged as a Facebook access token', () async {
    final expected = _CredentialResult();
    final service = FacebookSignInService(
      login: (_) async => LoginResult(
        status: LoginStatus.success,
        accessToken: ClassicToken(
          tokenString: 'test-access-token',
          userId: 'test-user',
          applicationId: 'test-app',
          expires: DateTime.now().add(const Duration(hours: 1)),
          grantedPermissions: ['public_profile'],
          declinedPermissions: ['email'],
        ),
      ),
      authenticate: (credential) async {
        expect(credential.providerId, 'facebook.com');
        expect(credential.accessToken, 'test-access-token');
        expect(credential.idToken, isNull);
        return expected;
      },
    );
    expect(await service.signIn(), same(expected));
  });

  test(
    'limited login uses ID token and matching fresh nonce on each attempt',
    () async {
      final hashes = <String>[];
      final service = FacebookSignInService(
        login: (hash) async {
          hashes.add(hash);
          return LoginResult(
            status: LoginStatus.success,
            accessToken: LimitedToken(
              tokenString: 'test-id-token',
              userId: 'test-user',
              userName: 'Test',
              userEmail: null,
              nonce: hash,
            ),
          );
        },
        authenticate: (credential) async {
          expect(credential.providerId, 'facebook.com');
          expect(credential.signInMethod, 'oauth');
          expect(credential.idToken, 'test-id-token');
          expect(credential.accessToken, isNull);
          expect(
            sha256.convert(utf8.encode(credential.rawNonce!)).toString(),
            hashes.last,
          );
          return _CredentialResult();
        },
      );
      await service.signIn();
      await service.signIn();
      expect(hashes.toSet(), hasLength(2));
    },
  );

  test(
    'account collision is surfaced without linking or replacing accounts',
    () async {
      final service = FacebookSignInService(
        login: (hash) async => LoginResult(
          status: LoginStatus.success,
          accessToken: LimitedToken(
            tokenString: 'test-id-token',
            userId: 'test-user',
            userName: 'Test',
            userEmail: null,
            nonce: hash,
          ),
        ),
        authenticate: (_) async => throw FirebaseAuthException(
          code: 'account-exists-with-different-credential',
        ),
      );
      await expectLater(
        service.signIn(),
        throwsA(
          isA<FirebaseAuthException>().having(
            (error) => error.code,
            'code',
            'account-exists-with-different-credential',
          ),
        ),
      );
    },
  );
}
