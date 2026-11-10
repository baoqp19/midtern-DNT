import 'package:flutter/material.dart';

import 'api_client.dart';
import 'app_theme.dart';
import 'managed_user.dart';
import 'user_editor.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key, required this.api, required this.onLogout});
  final ApiClient api;
  final VoidCallback onLogout;

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late Future<List<ManagedUser>> _users;
  final _searchController = TextEditingController();
  String _search = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() => _users = widget.api.listUsers();

  Future<void> _edit([ManagedUser? user]) async {
    if (_busy) return;
    final draft = await showDialog<UserDraft>(
      context: context,
      builder: (_) => UserEditor(user: user),
    );
    if (draft == null || !mounted) return;
    setState(() => _busy = true);
    try {
      if (user == null) {
        await widget.api.createUser(draft);
      } else {
        await widget.api.updateUser(user, draft);
      }
      _showMessage(
        user == null ? 'Đã thêm người dùng.' : 'Đã cập nhật người dùng.',
      );
    } catch (error) {
      _showMessage('Không thể lưu: $error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _refresh();
        });
      }
    }
  }

  Future<void> _delete(ManagedUser user) async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.person_remove_outlined,
          color: AppColors.red,
          size: 36,
        ),
        title: const Text('Xóa người dùng?'),
        content: Text(
          'Xóa tài khoản ${user.email} và ảnh đại diện? Thao tác này không thể hoàn tác.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.api.deleteUser(user.id);
      _showMessage('Đã xóa người dùng.');
    } catch (error) {
      _showMessage('Không thể xóa: $error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _refresh();
        });
      }
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _search = '');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: FutureBuilder<List<ManagedUser>>(
      future: _users,
      builder: (context, snapshot) {
        final users = snapshot.data ?? [];
        final withPhoto = users.where((user) => user.imageBytes != null).length;
        final visible = users
            .where(
              (user) =>
                  user.fullName.toLowerCase().contains(_search) ||
                  user.email.toLowerCase().contains(_search),
            )
            .toList();
        return LayoutBuilder(
          builder: (context, constraints) {
            final sidebar = constraints.maxWidth >= 1100;
            return Row(
              children: [
                if (sidebar) _sidebar(users.length),
                Expanded(
                  child: SafeArea(
                    child: LayoutBuilder(
                      builder: (context, bodyConstraints) {
                        final narrow = bodyConstraints.maxWidth < 650;
                        return ListView(
                          padding: EdgeInsets.all(narrow ? 18 : 36),
                          children: [
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 1160,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (!sidebar) ...[
                                      Row(
                                        children: [
                                          const BrandMark(),
                                          const Spacer(),
                                          IconButton(
                                            tooltip: 'Đăng xuất',
                                            onPressed: widget.onLogout,
                                            icon: const Icon(
                                              Icons.logout_rounded,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 30),
                                    ],
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'KHÔNG GIAN QUẢN TRỊ  /  NGƯỜI DÙNG',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 1,
                                                  color: AppColors.muted,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Quản lý người dùng',
                                                style: TextStyle(
                                                  fontSize: narrow ? 26 : 32,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: -.9,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'Mọi hồ sơ, trong một không gian.',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.muted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (!narrow) ...[
                                          const SizedBox(width: 18),
                                          _addButton(),
                                        ],
                                      ],
                                    ),
                                    if (narrow) ...[
                                      const SizedBox(height: 22),
                                      _addButton(),
                                    ],
                                    const SizedBox(height: 28),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _StatCard(
                                            label: 'Tổng người dùng',
                                            value: users.length,
                                            icon: Icons.people_alt_outlined,
                                            color: AppColors.primary,
                                            background: AppColors.lavender,
                                            primary: true,
                                            compact: narrow,
                                          ),
                                        ),
                                        SizedBox(width: narrow ? 10 : 18),
                                        Expanded(
                                          child: _StatCard(
                                            label: 'Có ảnh đại diện',
                                            value: withPhoto,
                                            icon: Icons.photo_camera_outlined,
                                            color: AppColors.teal,
                                            background: AppColors.mint,
                                            compact: narrow,
                                          ),
                                        ),
                                        SizedBox(width: narrow ? 10 : 18),
                                        Expanded(
                                          child: _StatCard(
                                            label: 'Chưa có ảnh',
                                            value: users.length - withPhoto,
                                            icon: Icons.person_outline_rounded,
                                            color: AppColors.orange,
                                            background: AppColors.peach,
                                            compact: narrow,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 28),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                          color: AppColors.line,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: LayoutBuilder(
                                        builder: (context, panelConstraints) {
                                          final table =
                                              panelConstraints.maxWidth >= 820;
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Padding(
                                                padding: EdgeInsets.all(
                                                  narrow ? 18 : 24,
                                                ),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      children: [
                                                        const Expanded(
                                                          child: Text(
                                                            'Danh sách người dùng',
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize: 17,
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 5,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: AppColors
                                                                .lavender,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  9,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            '${visible.length}',
                                                            style:
                                                                const TextStyle(
                                                                  color: AppColors
                                                                      .primary,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        IconButton(
                                                          tooltip: 'Tải lại',
                                                          onPressed: _busy
                                                              ? null
                                                              : () => setState(
                                                                  _refresh,
                                                                ),
                                                          icon: const Icon(
                                                            Icons
                                                                .refresh_rounded,
                                                            size: 21,
                                                            color:
                                                                AppColors.muted,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 18),
                                                    TextField(
                                                      controller:
                                                          _searchController,
                                                      decoration: InputDecoration(
                                                        hintText: 'Tìm theo họ tên hoặc email',
                                                        prefixIcon: const Icon(
                                                          Icons.search_rounded,
                                                          size: 22,
                                                        ),
                                                        suffixIcon:
                                                            _search.isEmpty
                                                            ? null
                                                            : IconButton(
                                                                tooltip: 'Xóa tìm kiếm',
                                                                onPressed:
                                                                    _clearSearch,
                                                                icon: const Icon(
                                                                  Icons
                                                                      .close_rounded,
                                                                  size: 19,
                                                                ),
                                                              ),
                                                      ),
                                                      onChanged: (value) =>
                                                          setState(
                                                            () => _search = value
                                                                .trim()
                                                                .toLowerCase(),
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (_busy)
                                                const LinearProgressIndicator(
                                                  minHeight: 2,
                                                ),
                                              if (snapshot.hasError)
                                                _message(
                                                  Icons.cloud_off_rounded,
                                                  'Chưa tải được danh sách',
                                                  '${snapshot.error}',
                                                  action: TextButton.icon(
                                                    onPressed: () =>
                                                        setState(_refresh),
                                                    icon: const Icon(
                                                      Icons.refresh_rounded,
                                                    ),
                                                    label: const Text(
                                                      'Thử lại',
                                                    ),
                                                  ),
                                                )
                                              else if (!snapshot.hasData)
                                                const Padding(
                                                  padding: EdgeInsets.all(64),
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                )
                                              else if (visible.isEmpty)
                                                _message(
                                                  _search.isEmpty
                                                      ? Icons
                                                            .people_outline_rounded
                                                      : Icons
                                                            .search_off_rounded,
                                                  _search.isEmpty
                                                      ? 'Bắt đầu với người dùng đầu tiên'
                                                      : 'Chưa tìm thấy người dùng',
                                                  _search.isEmpty
                                                      ? 'Thêm hồ sơ để lưu thông tin và ảnh đại diện.'
                                                      : 'Thử tìm bằng một họ tên hoặc email khác.',
                                                  action: _search.isEmpty
                                                      ? TextButton.icon(
                                                          onPressed: _busy
                                                              ? null
                                                              : () => _edit(),
                                                          icon: const Icon(
                                                            Icons.add_rounded,
                                                          ),
                                                          label: const Text(
                                                            'Thêm người dùng',
                                                          ),
                                                        )
                                                      : TextButton(
                                                          onPressed:
                                                              _clearSearch,
                                                          child: const Text(
                                                            'Xóa tìm kiếm',
                                                          ),
                                                        ),
                                                )
                                              else ...[
                                                if (table)
                                                  Container(
                                                    color: const Color(
                                                      0xFFFAFAFD,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 24,
                                                          vertical: 14,
                                                        ),
                                                    child: const Row(
                                                      children: [
                                                        Expanded(
                                                          flex: 3,
                                                          child: _ColumnLabel(
                                                            'NGƯỜI DÙNG',
                                                          ),
                                                        ),
                                                        Expanded(
                                                          flex: 3,
                                                          child: _ColumnLabel(
                                                            'EMAIL',
                                                          ),
                                                        ),
                                                        Expanded(
                                                          flex: 2,
                                                          child: _ColumnLabel(
                                                            'MẬT KHẨU',
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 94,
                                                          child: _ColumnLabel(
                                                            'THAO TÁC',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                for (
                                                  var i = 0;
                                                  i < visible.length;
                                                  i++
                                                ) ...[
                                                  if (i > 0 || !table)
                                                    const Divider(),
                                                  _userRow(visible[i], table),
                                                ],
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 24,
                                                        vertical: 16,
                                                      ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        border: Border(
                                                          top: BorderSide(
                                                            color:
                                                                AppColors.line,
                                                          ),
                                                        ),
                                                      ),
                                                  child: Text(
                                                    'Hiển thị ${visible.length} / ${users.length} người dùng',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.muted,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      'UserHub  ·  Quản lý gọn gàng, cập nhật dễ dàng',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ),
  );

  Widget _addButton() => FilledButton.icon(
    onPressed: _busy ? null : () => _edit(),
    icon: const Icon(Icons.add_rounded, size: 20),
    label: const Text('Thêm người dùng'),
  );

  Widget _userRow(ManagedUser user, bool table) => Padding(
    padding: EdgeInsets.symmetric(horizontal: table ? 24 : 18, vertical: 20),
    child: table
        ? Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    UserAvatar(
                      name: user.fullName,
                      bytes: user.imageBytes,
                      size: 44,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ),
              const Expanded(flex: 2, child: _PasswordBadge()),
              _actions(user),
            ],
          )
        : Column(
            children: [
              Row(
                children: [
                  UserAvatar(name: user.fullName, bytes: user.imageBytes),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const _PasswordBadge(),
                  const Spacer(),
                  _actions(user),
                ],
              ),
            ],
          ),
  );

  Widget _actions(ManagedUser user) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: 'Sửa ${user.fullName}',
        onPressed: _busy ? null : () => _edit(user),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.lavender,
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        icon: const Icon(Icons.edit_outlined, size: 19),
      ),
      const SizedBox(width: 8),
      IconButton(
        tooltip: 'Xóa ${user.fullName}',
        onPressed: _busy ? null : () => _delete(user),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.pink,
          foregroundColor: AppColors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        icon: const Icon(Icons.delete_outline_rounded, size: 19),
      ),
    ],
  );

  Widget _message(
    IconData icon,
    String title,
    String subtitle, {
    Widget? action,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.lavender,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 34, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: AppColors.muted,
          ),
        ),
        if (action != null) ...[const SizedBox(height: 15), action],
      ],
    ),
  );

  Widget _sidebar(int count) => Container(
    width: 236,
    color: AppColors.navy,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BrandMark(dark: true),
            const SizedBox(height: 52),
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text(
                'QUẢN LÝ',
                style: TextStyle(
                  color: Color(0xFF9AA6CB),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.people_alt_outlined,
                    size: 21,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Người dùng',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .17),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (MediaQuery.sizeOf(context).height >= 760)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF263051),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFB4A8FF),
                      size: 24,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Mọi hồ sơ\ntrong tầm tay.',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Một nơi cho thông tin\nvà những kết nối.',
                      style: TextStyle(
                        color: Color(0xFFB1BDDE),
                        fontSize: 11,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 28),
            const Divider(color: Color(0xFF303B5E)),
            const SizedBox(height: 22),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8D1FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: AppColors.primary,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'admin',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Quản trị viên',
                      style: TextStyle(fontSize: 11, color: Color(0xFFADB9D9)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: widget.onLogout,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFBBC5E0),
                alignment: Alignment.centerLeft,
              ),
              icon: const Icon(Icons.logout_rounded, size: 17),
              label: const Text('Đăng xuất', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ColumnLabel extends StatelessWidget {
  const _ColumnLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.muted,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: .8,
    ),
  );
}

class _PasswordBadge extends StatelessWidget {
  const _PasswordBadge();
  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.muted),
      SizedBox(width: 7),
      Text(
        '••••••',
        style: TextStyle(
          color: AppColors.muted,
          letterSpacing: 2,
          fontSize: 12,
        ),
      ),
    ],
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
    required this.compact,
    this.primary = false,
  });
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color background;
  final bool primary;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    height: compact ? 150 : 128,
    padding: EdgeInsets.all(compact ? 14 : 22),
    decoration: BoxDecoration(
      gradient: primary
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, Color(0xFF8B79F5)],
            )
          : null,
      color: primary ? null : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: primary ? null : Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 7 : 8),
              decoration: BoxDecoration(
                color: primary
                    ? Colors.white.withValues(alpha: .18)
                    : background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: primary ? Colors.white : color,
                size: compact ? 18 : 20,
              ),
            ),
            if (!compact) ...[
              const Spacer(),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.7,
                  color: primary ? Colors.white : AppColors.ink,
                ),
              ),
            ],
          ],
        ),
        if (compact) ...[
          const SizedBox(height: 10),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: primary ? Colors.white : AppColors.ink,
            ),
          ),
        ],
        const Spacer(),
        Text(
          label,
          maxLines: 2,
          style: TextStyle(
            fontSize: compact ? 11 : 12,
            height: 1.4,
            color: primary ? const Color(0xFFE8E3FF) : AppColors.muted,
          ),
        ),
      ],
    ),
  );
}
