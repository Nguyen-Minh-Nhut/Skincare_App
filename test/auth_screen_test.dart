import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_app/screens/auth/auth_screen.dart';

void main() {
  testWidgets('login and registration screens display the app logo', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

    expect(find.bySemanticsLabel('Skincare App logo'), findsOneWidget);
    expect(find.text('Chào mừng trở lại!'), findsOneWidget);

    await tester.ensureVisible(find.text('Đăng ký ngay'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng ký ngay'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Skincare App logo'), findsOneWidget);
    expect(find.text('Tạo tài khoản mới'), findsOneWidget);
  });
  testWidgets(
    'provider logos and password visibility work in both auth modes',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
      for (final path in [
        'assets/brands/google.png',
        'assets/brands/facebook.png',
      ]) {
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                widget.image is AssetImage &&
                (widget.image as AssetImage).assetName == path,
          ),
          findsOneWidget,
        );
      }
      expect(find.text('Sắp ra mắt'), findsNothing);
      final password = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.hintText == 'Mật khẩu',
      );
      await tester.ensureVisible(password);
      await tester.enterText(password, 'example-password');
      expect(tester.widget<TextField>(password).obscureText, isTrue);
      await tester.tap(find.byTooltip('Hiện mật khẩu'));
      await tester.pump();
      expect(tester.widget<TextField>(password).obscureText, isFalse);
      expect(
        tester.widget<TextField>(password).controller!.text,
        'example-password',
      );
      await tester.tap(find.byTooltip('Ẩn mật khẩu'));
      await tester.pump();
      expect(tester.widget<TextField>(password).obscureText, isTrue);
      await tester.ensureVisible(find.text('Đăng ký ngay'));
      await tester.tap(find.text('Đăng ký ngay'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(password);
      expect(tester.widget<TextField>(password).obscureText, isTrue);
      expect(tester.widget<TextField>(password).controller!.text, isEmpty);
      await tester.tap(find.byTooltip('Hiện mật khẩu'));
      await tester.pump();
      expect(tester.widget<TextField>(password).obscureText, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
