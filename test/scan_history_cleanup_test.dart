import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skincare_app/screens/home/scan_history.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'account cleanup removes only its own scans, including missing images',
    () async {
      final directory = await Directory.systemTemp.createTemp('scan_cleanup_');
      addTearDown(() => directory.delete(recursive: true));
      final ownImage = await File(
        '${directory.path}/own.jpg',
      ).writeAsString('own');
      final otherImage = await File(
        '${directory.path}/other.jpg',
      ).writeAsString('other');
      final other = jsonEncode({
        'userId': 'other',
        'imagePath': otherImage.path,
      });
      SharedPreferences.setMockInitialValues({
        'saved_skin_scans_v1': [
          jsonEncode({'userId': 'own', 'imagePath': ownImage.path}),
          jsonEncode({
            'userId': 'own',
            'imagePath': '${directory.path}/missing.jpg',
          }),
          other,
          'invalid json',
        ],
      });
      await ScanHistoryStore.deleteForUser('own');
      expect(await ownImage.exists(), isFalse);
      expect(await otherImage.exists(), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('saved_skin_scans_v1'), [
        other,
        'invalid json',
      ]);
      await ScanHistoryStore.deleteForUser('own');
      expect(prefs.getStringList('saved_skin_scans_v1'), [
        other,
        'invalid json',
      ]);
    },
  );
}
