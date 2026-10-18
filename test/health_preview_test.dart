import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_app/preview/health_preview.dart';

void main() {
  testWidgets(
    'compact preview navigates scans and community without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MeowSkinPreview());
      await tester.pumpAndSettle();
      expect(find.text('Điểm làn da'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Quét AI'));
      await tester.pumpAndSettle();
      expect(find.text('Quét da AI'), findsOneWidget);
      await tester.tap(find.text('Thử kết quả mẫu'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Kết quả minh họa'), 180);
      expect(find.text('Kết quả minh họa'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cộng đồng').last);
      await tester.pumpAndSettle();
      expect(find.text('Hôm nay da bạn thế nào?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
