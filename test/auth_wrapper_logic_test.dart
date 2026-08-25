import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_app/screens/auth/auth_wrapper.dart';

void main() {
  group('resolveSignedInDestination', () {
    test('keeps an authenticated user in the app when Firestore fails', () {
      expect(
        resolveSignedInDestination(
          firestoreFailed: true,
          documentExists: false,
        ),
        SignedInDestination.main,
      );
    });

    test('sends a user without a profile to onboarding', () {
      expect(
        resolveSignedInDestination(
          firestoreFailed: false,
          documentExists: false,
        ),
        SignedInDestination.introduction,
      );
    });

    test('accepts only a completed skin profile', () {
      expect(
        resolveSignedInDestination(
          firestoreFailed: false,
          documentExists: true,
          userData: const {'skinType': 'Da dầu'},
        ),
        SignedInDestination.main,
      );
      expect(
        resolveSignedInDestination(
          firestoreFailed: false,
          documentExists: true,
          userData: const {'skinType': 'Chưa xác định'},
        ),
        SignedInDestination.introduction,
      );
    });
  });
}
