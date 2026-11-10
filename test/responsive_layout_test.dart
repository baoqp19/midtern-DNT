import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giuaki2/api_client.dart';
import 'package:giuaki2/app_theme.dart';
import 'package:giuaki2/auth_screen.dart';
import 'package:giuaki2/user_editor.dart';
import 'package:giuaki2/users_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('Roboto');
    for (final weight in ['regular', 'medium', 'bold', 'black']) {
      loader.addFont(rootBundle.load('assets/fonts/roboto-$weight.ttf'));
    }
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  Future<void> preview(
    WidgetTester tester,
    Widget home,
    Size size,
    String name,
  ) async {
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          theme: buildAppTheme(),
          debugShowCheckedModeBanner: false,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.takeException(),
      isNull,
      reason: '$name must fit the viewport',
    );
    if (const bool.fromEnvironment('UI_PREVIEWS')) {
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final rendered = await boundary.toImage();
        final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/ui-preview/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        rendered.dispose();
      });
    }
  }

  for (final entry in {
    'desktop': const Size(1440, 1000),
    'mobile': const Size(390, 844),
    'short-desktop': const Size(1440, 600),
    'small-phone': const Size(360, 740),
  }.entries) {
    testWidgets('Login fits ${entry.key}', (tester) async {
      await preview(
        tester,
        AuthScreen(api: ApiClient(), onLoggedIn: () {}),
        entry.value,
        'login-${entry.key}',
      );
      expect(find.text('Đăng nhập'), findsOneWidget);
    });

    testWidgets('User list fits ${entry.key}', (tester) async {
      final api = ApiClient(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'users': [
                {
                  '_id': '1',
                  'email': 'minhanh@example.com',
                  'hoten': 'Nguyễn Minh Anh',
                  'hinhanh': '',
                },
                {
                  '_id': '2',
                  'email': 'quocbao@example.com',
                  'hoten': 'Trần Quốc Bảo',
                  'hinhanh': '',
                },
                {
                  '_id': '3',
                  'email': 'hoangphuong@example.com',
                  'hoten': 'Lê Hoàng Phương',
                  'hinhanh': '',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      await preview(
        tester,
        UsersScreen(api: api, onLogout: () {}),
        entry.value,
        'users-${entry.key}',
      );
      expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
      expect(find.byTooltip('Sửa Nguyễn Minh Anh'), findsOneWidget);
      expect(find.byTooltip('Xóa Nguyễn Minh Anh'), findsOneWidget);
    });
  }

  testWidgets('User editor fits a phone', (tester) async {
    await preview(
      tester,
      const Scaffold(body: UserEditor()),
      const Size(390, 844),
      'editor-mobile',
    );
    expect(find.text('Lưu'), findsOneWidget);
  });
}
