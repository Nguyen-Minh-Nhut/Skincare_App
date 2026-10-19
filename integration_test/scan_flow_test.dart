import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skincare_app/firebase_options.dart';
import 'package:skincare_app/main.dart';
import 'package:skincare_app/screens/app_provider.dart';
import 'package:skincare_app/screens/home/scan_history.dart';
import 'package:skincare_app/screens/profile/scan_history_screen.dart';
import 'package:skincare_app/services/scan_input_check.dart';

class FixturePicker extends ImagePickerPlatform {
  FixturePicker(this.path);
  final String path;
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => XFile(path);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('local login, real face guard, TFLite scan, save and history reload', (
    tester,
  ) async {
    Future<void> until(Finder finder, {int seconds = 30}) async {
      final end = DateTime.now().add(Duration(seconds: seconds));
      while (finder.evaluate().isEmpty && DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      if (finder.evaluate().isEmpty) {
        debugPrint(
          'Visible text: ${tester.widgetList<Text>(find.byType(Text)).map((w) => w.data).whereType<String>().take(30).join(' | ')}',
        );
      }
      expect(finder, findsWidgets);
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final auth = FirebaseAuth.instance;
    await auth.useAuthEmulator('127.0.0.1', 9098, automaticHostMapping: false);
    FirebaseFirestore.instance.useFirestoreEmulator(
      '127.0.0.1',
      8085,
      automaticHostMapping: false,
    );
    const email = 'scan-flow@example.test', password = 'Local-test-only-201!';
    try {
      await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code != 'email-already-in-use') rethrow;
      await auth.signInWithEmailAndPassword(email: email, password: password);
    }
    final uid = auth.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'skinType': 'Da thường',
      'name': 'Local scan test',
    });
    await ScanHistoryStore.deleteForUser(uid);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('scan_e2e_uid', uid);
    await auth.signOut();
    final bytes = (await rootBundle.load(
      'integration_test/fixtures/face.jpg',
    )).buffer.asUint8List();
    final face = img.decodeImage(bytes)!;
    final normalized = Uint8List.fromList(
      img.encodeJpg(img.bakeOrientation(face)),
    );
    expect(await ScanInputCheck().validate(normalized), isNull);
    final blank = img.Image(width: 400, height: 400);
    img.fill(blank, color: img.ColorRgb8(100, 130, 160));
    expect(
      await ScanInputCheck().validate(Uint8List.fromList(img.encodeJpg(blank))),
      'no-face',
    );
    final collage = img.Image(width: face.width * 2, height: face.height);
    img.compositeImage(collage, face);
    img.compositeImage(collage, face, dstX: face.width);
    expect(
      await ScanInputCheck().validate(
        Uint8List.fromList(img.encodeJpg(collage)),
      ),
      'multiple-faces',
    );
    final upsideDown = img.copyRotate(face, angle: 180);
    expect(
      await ScanInputCheck().validate(
        Uint8List.fromList(img.encodeJpg(upsideDown)),
      ),
      isNotNull,
    );
    final file = await File(
      '${(await getTemporaryDirectory()).path}/scan_fixture.jpg',
    ).writeAsBytes(normalized);
    ImagePickerPlatform.instance = FixturePicker(file.path);
    final provider = AppProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: provider, child: const MyApp()),
    );
    await until(find.text('Chào mừng trở lại!'));
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), email);
    await tester.enterText(fields.at(1), password);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.ensureVisible(find.text('Đăng nhập').first);
    await tester.tap(find.text('Đăng nhập').first);
    await until(find.text('Hôm nay'));
    debugPrint('SCAN_E2E: login completed');
    await tester.tap(find.text('Theo dõi da').last);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(find.text('Mở quét thử nghiệm'));
    await tester.tap(find.text('Mở quét thử nghiệm'));
    await until(find.text('Chọn ảnh'));
    debugPrint('SCAN_E2E: scan screen opened');
    // Model loading disables the chooser until both real interpreters are ready.
    final end = DateTime.now().add(const Duration(seconds: 120));
    while (tester
                .widget<OutlinedButton>(
                  find.widgetWithText(OutlinedButton, 'Chọn ảnh'),
                )
                .onPressed ==
            null &&
        DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    debugPrint('SCAN_E2E: model readiness checked');
    await tester.tap(find.text('Chọn ảnh'));
    await until(find.text('Ảnh đủ điều kiện để quét thử nghiệm.'));
    debugPrint('SCAN_E2E: selected image validated');
    await tester.ensureVisible(find.text('Phân tích ảnh'));
    await tester.tap(find.text('Phân tích ảnh'));
    final inferenceEnd = DateTime.now().add(const Duration(seconds: 120));
    while (find
            .textContaining('vùng nghi ngờ được phát hiện')
            .evaluate()
            .isEmpty &&
        DateTime.now().isBefore(inferenceEnd)) {
      expect(find.textContaining('Phân tích thất bại.'), findsNothing);
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.textContaining('vùng nghi ngờ được phát hiện'), findsOneWidget);
    debugPrint('SCAN_E2E: inference completed');
    await tester.scrollUntilVisible(
      find.text('Lưu kết quả'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Lưu kết quả'));
    await until(find.text('Đã lưu'));
    final scans = await ScanHistoryStore.load(userId: uid);
    expect(scans, hasLength(1));
    expect(scans.single.imageWidth, face.width);
    expect(scans.single.regions.length, scans.single.acneCount);
    expect(File(scans.single.imagePath).existsSync(), isTrue);
    await tester.scrollUntilVisible(
      find.text('Xem lịch sử'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Xem lịch sử'));
    await until(find.byType(ScanHistoryScreen));
    expect(find.textContaining('Kết quả thử nghiệm'), findsOneWidget);
    // Recreate app widgets and reload preferences from disk.
    await tester.pumpWidget(const SizedBox());
    await prefs.reload();
    expect(await ScanHistoryStore.load(userId: uid), hasLength(1));
    provider.dispose();
    await auth.signOut();
    // Credentials stay inside the local emulator; this run never uses production auth.
  });
}
