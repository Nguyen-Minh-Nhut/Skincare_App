import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skincare_app/firebase_options.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skincare_app/screens/home/scan_history.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('saved scan survives a fresh Android process', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('scan_e2e_uid');
    expect(uid, isNotNull, reason: 'Run scan_flow_test.dart first');
    final scans = await ScanHistoryStore.load(userId: uid!);
    expect(scans, hasLength(1));
    expect(File(scans.single.imagePath).existsSync(), isTrue);
    expect(scans.single.imageWidth, isPositive);
    expect(scans.single.regions.length, scans.single.acneCount);
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAuth.instance.useAuthEmulator(
      '127.0.0.1',
      9098,
      automaticHostMapping: false,
    );
    await FirebaseAuth.instance.signOut();
  });
}
