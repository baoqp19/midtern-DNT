import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giuaki2/api_client.dart';
import 'package:giuaki2/auth_screen.dart';
import 'package:giuaki2/managed_user.dart';
import 'package:giuaki2/user_editor.dart';

void main() {
  testWidgets('Admin login asks for email and password', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScreen(api: ApiClient(), onLoggedIn: () {}),
      ),
    );
    expect(find.text('Quản lý người dùng'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
  });

  testWidgets('New user form validates and returns required fields', (
    tester,
  ) async {
    UserDraft? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                result = await showDialog<UserDraft>(
                  context: context,
                  builder: (_) => const UserEditor(),
                );
              },
              child: const Text('Mở biểu mẫu'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở biểu mẫu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu'));
    await tester.pump();
    expect(find.text('Nhập email hợp lệ'), findsOneWidget);
    expect(find.text('Nhập họ tên'), findsOneWidget);
    expect(find.text('Mật khẩu cần ít nhất 6 ký tự'), findsOneWidget);
    expect(result, isNull);

    await tester.enterText(find.byType(TextFormField).at(0), 'bao@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'Nguyễn Bảo');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret123');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(result?.email, 'bao@example.com');
    expect(result?.fullName, 'Nguyễn Bảo');
    expect(result?.password, 'secret123');
  });
}
