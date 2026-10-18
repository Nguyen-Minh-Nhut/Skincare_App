import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/home/scan_history.dart';

class AccountDeletion {
  static bool usesPassword(User user) =>
      user.providerData.any((provider) => provider.providerId == 'password');

  static Future<void> delete(User user, String password) async {
    if (usesPassword(user)) {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password),
      );
    } else if (user.providerData.any((p) => p.providerId == 'google.com')) {
      if (kIsWeb) {
        await user.reauthenticateWithPopup(GoogleAuthProvider());
      } else {
        final account = await GoogleSignIn().signIn();
        if (account == null) {
          throw FirebaseAuthException(code: 'cancelled');
        }
        final auth = await account.authentication;
        await user.reauthenticateWithCredential(
          GoogleAuthProvider.credential(
            accessToken: auth.accessToken,
            idToken: auth.idToken,
          ),
        );
      }
    } else {
      throw FirebaseAuthException(code: 'unsupported-provider');
    }

    // Finish cleanup while authorization is still available. Each step can be
    // retried if a network error interrupts deletion; Auth is deleted last.
    final db = FirebaseFirestore.instance;
    final ref = db.collection('users').doc(user.uid);
    final profile = await ref.get();
    final username = profile.data()?['username'] as String?;
    for (final name in ['wardrobe', 'notifications']) {
      while (true) {
        final page = await ref.collection(name).limit(400).get();
        if (page.docs.isEmpty) break;
        final batch = db.batch();
        for (final document in page.docs) {
          batch.delete(document.reference);
        }
        await batch.commit();
      }
    }
    await ScanHistoryStore.deleteForUser(user.uid);
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.remove('care_routine_v1_${user.uid}')) {
      throw StateError('Could not remove local routine');
    }
    if (!await prefs.remove('meow_sessions_${user.uid}')) {
      throw StateError('Could not remove local chat history');
    }
    final batch = db.batch()..delete(ref);
    if (username != null && username.isNotEmpty) {
      final alias = db.collection('usernames').doc(username);
      final existing = await alias.get();
      if (existing.data()?['uid'] == user.uid) batch.delete(alias);
    }
    await batch.commit();
    await user.delete();
  }
}
