import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_app/screens/auth/password_reset_dialog.dart';

Future<void> open(
  WidgetTester tester,
  PasswordResetSender send, {
  String email = '',
  bool dark = false,
  double scale = 1,
}) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('preview'),
      child: MaterialApp(
        theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showPasswordResetDialog(
                context,
                initialEmail: email,
                sendResetEmail: send,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('validates email before sending and trims input', (tester) async {
    final emails = <String>[];
    await open(tester, (email) async {
      emails.add(email);
    });
    await tester.tap(find.text('Gửi liên kết đặt lại'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn chưa nhập email.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'abc@');
    await tester.tap(find.text('Gửi liên kết đặt lại'));
    await tester.pumpAndSettle();
    expect(find.text('Email chưa đúng định dạng.'), findsOneWidget);
    expect(emails, isEmpty);
    await tester.enterText(find.byType(TextFormField), '  test@example.com  ');
    await tester.tap(find.text('Gửi liên kết đặt lại'));
    await tester.pumpAndSettle();
    expect(emails, ['test@example.com']);
    expect(find.text('Kiểm tra hộp thư nhé'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.pump(const Duration(seconds: 60));
    await tester.tap(find.text('Gửi lại email'));
    await tester.pumpAndSettle();
    expect(emails, hasLength(2));
    await tester.tap(find.text('Xong'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'closing while email is focused does not dispose controller early',
    (tester) async {
      await open(tester, (_) async {});
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Quay lại'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(PasswordResetDialog), findsOneWidget);
    },
  );

  testWidgets('pending request cannot duplicate and can finish after closing', (
    tester,
  ) async {
    final pending = Completer<void>();
    var calls = 0;
    await open(tester, (_) {
      calls++;
      return pending.future;
    }, email: 'test@example.com');
    await tester.tap(find.text('Gửi liên kết đặt lại'));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    pending.completeError(
      FirebaseAuthException(code: 'network-request-failed'),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('network error is inline and retry works', (tester) async {
    var calls = 0;
    await open(tester, (_) async {
      if (++calls == 1) {
        throw FirebaseAuthException(code: 'network-request-failed');
      }
    }, email: 'test@example.com');
    await tester.tap(find.text('Gửi liên kết đặt lại'));
    await tester.pumpAndSettle();
    expect(find.text('Kiểm tra kết nối mạng rồi thử lại nhé.'), findsOneWidget);
    await tester.tap(find.text('Gửi liên kết đặt lại'));
    await tester.pumpAndSettle();
    expect(find.text('Kiểm tra hộp thư nhé'), findsOneWidget);
    await tester.tap(find.text('Xong'));
    await tester.pumpAndSettle();
  });

  testWidgets('small screen and large text with keyboard do not overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await open(tester, (_) async {}, dark: true, scale: 1.5);
    await tester.enterText(find.byType(TextFormField), 'test@example.com');
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Gửi liên kết đặt lại'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('timeout restores a usable form', (tester) async {
    await open(
      tester,
      (_) => Completer<void>().future,
      email: 'test@example.com',
    );
    await tester.tap(find.text('Gửi liên kết đặt lại'));
    await tester.pump(const Duration(seconds: 21));
    await tester.pumpAndSettle();
    expect(
      find.text('Phản hồi hơi lâu. Kiểm tra hộp thư trước khi gửi lại nhé.'),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('capture reset dialog preview', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const fontPath = String.fromEnvironment('PREVIEW_FONT');
    if (fontPath.isNotEmpty) {
      await tester.runAsync(() async {
        final loader = FontLoader('Roboto')
          ..addFont(
            File(
              fontPath,
            ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
          );
        await loader.load();
        final icons = FontLoader('packages/phosphor_flutter/PhosphorRegular')
          ..addFont(
            rootBundle.load('packages/phosphor_flutter/lib/fonts/Phosphor.ttf'),
          );
        await icons.load();
      });
    }
    await open(tester, (_) async {});
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('CAPTURE_RESET')) {
      final render = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('preview')),
      );
      final image = (await tester.runAsync(() => render.toImage()))!;
      final bytes = await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.png),
      );
      await tester.runAsync(
        () => File(
          '/tmp/skincare-password-reset.png',
        ).writeAsBytes(bytes!.buffer.asUint8List()),
      );
      image.dispose();
    }
  });
}
