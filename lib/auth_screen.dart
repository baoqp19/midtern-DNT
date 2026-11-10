import 'package:flutter/material.dart';

import 'api_client.dart';
import 'app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.api, required this.onLoggedIn});
  final ApiClient api;
  final VoidCallback onLoggedIn;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.login(_username.text.trim(), _password.text);
      widget.onLoggedIn();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0EDFF), Color(0xFFF7F8FD), Color(0xFFE7F6F1)],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(wide ? 40 : 20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.navy.withValues(alpha: .08),
                              blurRadius: 60,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: wide
                            ? IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Expanded(child: _WelcomePanel()),
                                    Expanded(child: _form(wide)),
                                  ],
                                ),
                              )
                            : _form(wide),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget _form(bool wide) => Padding(
    padding: EdgeInsets.all(wide ? 44 : 28),
    child: AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!wide) ...[const BrandMark(), const SizedBox(height: 32)],
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'KHÔNG GIAN QUẢN TRỊ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppColors.teal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Quản lý người dùng',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Chào mừng trở lại! Đăng nhập để bắt đầu quản lý hồ sơ của bạn.',
              style: TextStyle(
                color: AppColors.muted,
                height: 1.6,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _username,
              enabled: !_busy,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Tài khoản admin',
                prefixIcon: Icon(Icons.person_outline_rounded, size: 21),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Nhập tài khoản admin'
                  : null,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _password,
              enabled: !_busy,
              obscureText: !_showPassword,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 21),
                suffixIcon: IconButton(
                  tooltip: _showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                ),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Nhập mật khẩu' : null,
              onFieldSubmitted: (_) => _login(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.pink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppColors.red,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.red,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 26),
            FilledButton(
              onPressed: _busy ? null : _login,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_busy)
                    const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Text('Đăng nhập'),
                  if (!_busy) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 16,
                  color: AppColors.muted,
                ),
                SizedBox(width: 7),
                Text(
                  'Dành cho quản trị viên',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF5142BB), Color(0xFF7965EE)],
      ),
    ),
    padding: const EdgeInsets.all(40),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const BrandMark(dark: true),
        const SizedBox(height: 44),
        const Text(
          'Mọi hồ sơ.\nMột không gian.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 38,
            height: 1.2,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.3,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Sắp xếp thông tin, cập nhật dễ dàng\nvà quản lý người dùng theo cách của bạn.',
          style: TextStyle(color: Color(0xFFDDD6FF), fontSize: 14, height: 1.7),
        ),
        const SizedBox(height: 32),
        const ExcludeSemantics(child: _ProfileArtwork()),
        const SizedBox(height: 24),
        const Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: Color(0xFFBFEFDF),
            ),
            SizedBox(width: 9),
            Text(
              'Gọn gàng hơn. Thuận tiện hơn.',
              style: TextStyle(fontSize: 12, color: Color(0xFFE1DCFF)),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ProfileArtwork extends StatelessWidget {
  const _ProfileArtwork();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 170,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: 4,
          top: -14,
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: .14),
                width: 24,
              ),
            ),
          ),
        ),
        Positioned(
          left: 10,
          right: 30,
          top: 0,
          child: _card(AppColors.mint, AppColors.teal, 180),
        ),
        Positioned(
          left: 32,
          right: 8,
          top: 88,
          child: _card(AppColors.peach, AppColors.orange, 130),
        ),
        Positioned(
          right: 0,
          top: 64,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFBDEEDC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.teal,
              size: 24,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _card(Color color, Color iconColor, double lineWidth) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF302379).withValues(alpha: .12),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.person_rounded, color: iconColor, size: 27),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 8,
                width: lineWidth,
                decoration: BoxDecoration(
                  color: const Color(0xFFDAD7ED),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 7,
                width: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEDF6),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
