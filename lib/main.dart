import 'package:flutter/material.dart';

import 'api_client.dart';
import 'auth_screen.dart';
import 'users_screen.dart';

void main() => runApp(const UserAdminApp());

class UserAdminApp extends StatefulWidget {
  const UserAdminApp({super.key});

  @override
  State<UserAdminApp> createState() => _UserAdminAppState();
}

class _UserAdminAppState extends State<UserAdminApp> {
  final _api = ApiClient();
  bool _signedIn = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý người dùng',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2855B8)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F8FC),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: _signedIn
          ? UsersScreen(
              api: _api,
              onLogout: () => setState(() {
                _api.logout();
                _signedIn = false;
              }),
            )
          : AuthScreen(
              api: _api,
              onLoggedIn: () => setState(() => _signedIn = true),
            ),
    );
  }
}
