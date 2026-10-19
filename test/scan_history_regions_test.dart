import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_app/screens/home/scan_history.dart';

void main() {
  final scan = SavedScan(
    id: 'scan',
    userId: 'u',
    imagePath: '/local.jpg',
    createdAt: DateTime(2026, 10, 19),
    acneCount: 1,
    level: 'experimental',
    morningRoutine: '',
    nightRoutine: '',
    activeIngredients: '',
    warning: 'limited',
    imageWidth: 640,
    imageHeight: 480,
    regions: const [
      {'left': 12, 'top': 24, 'width': 20, 'height': 30, 'confidence': .8},
    ],
  );
  test('saved region coordinates and dimensions survive JSON round trip', () {
    final restored = SavedScan.fromJson(scan.toJson());
    expect(restored.regions, scan.regions);
    expect(restored.imageWidth, 640);
    expect(restored.imageHeight, 480);
    expect(restored.acneCount, 1);
  });
  test('legacy scan history without regions remains readable', () {
    final legacy = scan.toJson()
      ..remove('regions')
      ..remove('imageWidth')
      ..remove('imageHeight');
    final restored = SavedScan.fromJson(legacy);
    expect(restored.regions, isEmpty);
    expect(restored.imageWidth, isNull);
    expect(restored.id, 'scan');
  });
}
