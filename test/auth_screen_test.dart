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

    await tester.tap(find.text('Đăng ký ngay'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Skincare App logo'), findsOneWidget);
    expect(find.text('Tạo tài khoản mới'), findsOneWidget);
  });
}
