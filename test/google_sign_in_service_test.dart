import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:skincare_app/services/google_sign_in_service.dart';

class _Account extends Fake implements GoogleSignInAccount {
  _Account(this.tokens);
  final GoogleSignInAuthentication tokens;
  @override
  Future<GoogleSignInAuthentication> get authentication async => tokens;
}

class _Tokens extends Fake implements GoogleSignInAuthentication {
  _Tokens(this.idToken, this.accessToken);
  @override
  final String? idToken;
  @override
  final String? accessToken;
}

class _Result extends Fake implements UserCredential {}

void main() {
  test('cancellation does not authenticate with Firebase', () async {
    final service = GoogleSignInService(
      login: () async => null,
      authenticate: (_) => throw StateError('Must not authenticate'),
    );
    expect(await service.signIn(), isNull);
  });

  testWidgets('interactive login can take longer than ten seconds', (
    tester,
  ) async {
    var completed = false;
    final service = GoogleSignInService(
      login: () async {
        await Future<void>.delayed(const Duration(seconds: 15));
        return null;
      },
    );
    final pending = service.signIn().then((_) => completed = true);
    await tester.pump(const Duration(seconds: 11));
    expect(completed, isFalse);
    await tester.pump(const Duration(seconds: 5));
    await pending;
    expect(completed, isTrue);
  });

  for (final idToken in [null, '']) {
    test(
      'missing ID token fails before Firebase authentication ($idToken)',
      () async {
        final service = GoogleSignInService(
          login: () async => _Account(_Tokens(idToken, 'access')),
          authenticate: (_) => throw StateError('Must not authenticate'),
        );
        await expectLater(
          service.signIn(),
          throwsA(
            isA<FirebaseAuthException>().having(
              (e) => e.code,
              'code',
              'google-id-token-missing',
            ),
          ),
        );
      },
    );
  }

  test('Google tokens are exchanged for Firebase credentials', () async {
    final expected = _Result();
    final service = GoogleSignInService(
      login: () async => _Account(_Tokens('id-token', 'access-token')),
      authenticate: (credential) async {
        expect(credential.providerId, 'google.com');
        expect(credential.idToken, 'id-token');
        expect(credential.accessToken, 'access-token');
        return expected;
      },
    );
    expect(await service.signIn(), same(expected));
  });
}
