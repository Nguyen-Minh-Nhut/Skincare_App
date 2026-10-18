import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skincare_app/widgets/care_routine_card.dart';
import 'package:skincare_app/theme/health_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> ready(CareRoutineModel model) async {
    while (model.loading) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('routine survives reload and separates periods and accounts', () async {
    SharedPreferences.setMockInitialValues({});
    final first = CareRoutineModel(userId: 'first');
    await ready(first);
    await first.toggle(0, 1);
    await first.updateTasks(1, ['Evening step']);
    await first.toggle(1, 0);
    final reloaded = CareRoutineModel(userId: 'first');
    final other = CareRoutineModel(userId: 'other');
    await ready(reloaded);
    await ready(other);
    expect(reloaded.completed[0], {1});
    expect(reloaded.completed[1], {0});
    expect(reloaded.tasks[1], ['Evening step']);
    expect(other.completed[0], isEmpty);
    expect(other.tasks[1].length, 3);
    first.dispose();
    reloaded.dispose();
    other.dispose();
  });
  test(
    'a new day resets completion while retaining customized tasks',
    () async {
      SharedPreferences.setMockInitialValues({
        'care_routine_v1_user': jsonEncode({
          'day': '2000-1-1',
          'tasks': [
            ['Morning'],
            ['Evening'],
          ],
          'done': [
            [0],
            [0],
          ],
        }),
      });
      final model = CareRoutineModel(userId: 'user');
      await ready(model);
      expect(model.completed.every((set) => set.isEmpty), isTrue);
      expect(model.tasks[0], ['Morning']);
      model.dispose();
    },
  );
  testWidgets(
    'routine switches periods without losing completion on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final model = CareRoutineModel(userId: 'user');
      await tester.runAsync(() => ready(model));
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: model,
            child: MaterialApp(
              theme: healthTheme(brightness),
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: CareRoutineCard(isEnglish: false),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Làm sạch dịu nhẹ'));
        await tester.pumpAndSettle();
        expect(model.completed[0].contains(0), isTrue);
        await tester.tap(find.text('Buổi tối'));
        await tester.pumpAndSettle();
        expect(find.text('0 / 3 bước hoàn thành'), findsOneWidget);
        await tester.tap(find.text('Buổi sáng'));
        await tester.pumpAndSettle();
        expect(find.text('1 / 3 bước hoàn thành'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.runAsync(() => model.toggle(0, 0));
      }
      await tester.pumpWidget(const SizedBox());
      model.dispose();
    },
  );
  testWidgets('today summary opens care and reflects shared completion', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final model = CareRoutineModel(userId: 'summary');
    await tester.runAsync(() => ready(model));
    var opened = false;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: model,
        child: MaterialApp(
          home: Scaffold(
            body: CareRoutineCard(
              isEnglish: false,
              compact: true,
              onOpenCare: () => opened = true,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Làm sạch dịu nhẹ'), findsNothing);
    expect(find.byTooltip('Chỉnh thói quen'), findsNothing);
    await tester.runAsync(() => model.toggle(0, 0));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3 bước hoàn thành'), findsOneWidget);
    await tester.tap(find.text('Mở Chăm sóc'));
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    model.dispose();
  });
}
