# Facebook Login — Skincare App

## Implemented

- The Facebook button authenticates through Firebase and reuses the existing social profile/onboarding flow.
- Android uses the classic Facebook access token; iOS Limited Login uses an ID token with a fresh cryptographic nonce.
- Cancelling the Facebook dialog does not authenticate. Duplicate taps are blocked while sign-in is pending.
- Account collisions are surfaced; this flow does not silently merge users.
- Web uses Firebase's Facebook popup provider.
- The mobile SDK is configured with Meta App ID `964346813363293` and the provided Client Token. The App Secret belongs only in Firebase Console.

## Meta Android configuration

In App settings → Basic → Add platform → Android:

- Package name: `com.example.skincare_app`
- Default activity: `com.example.skincare_app.MainActivity`
- Debug key hash for this machine: `z012RNYTzfUUuFAAcR4q61SHfNU=`

Release and Google Play builds need their own signing certificate hashes.

Facebook Login → Settings → Valid OAuth Redirect URIs:

`https://myapp-7f561.firebaseapp.com/__/auth/handler`

While the Meta app is unpublished, test with an account assigned an app role.
For iOS, register bundle identifier `com.example.skincareApp` in Meta.

## Run and verify

Native SDK changes require a full rebuild; hot reload is insufficient:

```sh
flutter pub get
flutter run
```

On an Android device:

1. Tap Continue with Facebook, then cancel. Confirm the login screen is usable.
2. Sign in with a permitted Meta account. Confirm a Firebase user with provider `facebook.com` exists.
3. Confirm onboarding for a new user and the main screen for a completed skin profile.
4. Verify a previously registered email produces guidance to use the original sign-in method.

## Automated verification

`flutter test test/facebook_sign_in_service_test.dart` covers cancellation, failure, pending login, missing tokens, classic token exchange, Limited Login nonce matching/freshness, and account collision propagation.

Full device login still requires the Meta settings and an interactive Facebook account.
