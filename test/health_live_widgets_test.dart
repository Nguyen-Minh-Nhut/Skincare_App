import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_app/screens/home/scan_history.dart';
import 'package:skincare_app/widgets/health_navigation_bar.dart';
import 'package:skincare_app/widgets/scan_trend_card.dart';

void main() {
  testWidgets(
    'live navigation has four destinations in both themes and languages',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final dark in [false, true]) {
        for (final en in [false, true]) {
          var selected = -1;
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: HealthNavigationBar(
                  selectedIndex: 0,
                  onSelected: (index) => selected = index,
                  isEnglish: en,
                  isDark: dark,
                ),
              ),
            ),
          );
          expect(find.text(en ? 'Community' : 'Cộng đồng'), findsNothing);
          await tester.tap(find.text(en ? 'Personal' : 'Cá nhân'));
          expect(selected, 3);
          expect(
            find.text(en ? 'Skin tracking' : 'Theo dõi da'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  testWidgets('live chart uses saved counts, handles zero and opens history', (
    tester,
  ) async {
    var opened = false;
    SavedScan scan(String id, int count, int day) => SavedScan(
      id: id,
      userId: 'user',
      imagePath: '/unused.jpg',
      createdAt: DateTime(2026, 10, day),
      acneCount: count,
      level: '',
      morningRoutine: '',
      nightRoutine: '',
      activeIngredients: '',
      warning: '',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 340,
            child: ScanTrendCard(
              scans: [scan('new', 0, 18), scan('old', 12, 16)],
              isEnglish: false,
              onOpenHistory: () => opened = true,
            ),
          ),
        ),
      ),
    );
    expect(find.text('nốt được phát hiện · 18/10'), findsOneWidget);
    await tester.tap(find.text('16/10'));
    await tester.pumpAndSettle();
    expect(find.text('nốt được phát hiện · 16/10'), findsOneWidget);
    await tester.tap(find.byTooltip('Lịch sử soi da'));
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanTrendCard(
            scans: const [],
            isEnglish: true,
            onOpenHistory: () {},
          ),
        ),
      ),
    );
    expect(find.text('Start tracking your skin'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
