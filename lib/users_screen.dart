import 'package:flutter/material.dart';

import 'api_client.dart';
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
  String _search = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
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
    if (_busy || user.email == widget.api.adminEmail) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa người dùng?'),
        content: Text(
          'Xóa tài khoản ${user.email} và ảnh đại diện? Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
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
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: () => setState(_refresh),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3),
              )
            : null,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : () => _edit(),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Thêm người dùng'),
                ),
                const SizedBox(height: 14),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm theo họ tên hoặc email',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) =>
                      setState(() => _search = value.trim().toLowerCase()),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: FutureBuilder<List<ManagedUser>>(
                    future: _users,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Không tải được người dùng: ${snapshot.error}',
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final users = snapshot.data!;
                      final visible = users
                          .where(
                            (user) =>
                                user.fullName.toLowerCase().contains(_search) ||
                                user.email.toLowerCase().contains(_search),
                          )
                          .toList();
                      if (visible.isEmpty) {
                        return Center(
                          child: Text(
                            users.isEmpty
                                ? 'Chưa có người dùng.'
                                : 'Không tìm thấy người dùng phù hợp.',
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final user = visible[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundImage: user.imageBytes == null ? null : MemoryImage(user.imageBytes!),
                                    child: user.imageBytes == null ? const Icon(Icons.person) : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.fullName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          user.email,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Text('Mật khẩu: ••••••'),
                                      ],
                                    ),
                                  ),
                                  if (user.email != widget.api.adminEmail) ...[
                                    IconButton(
                                      tooltip: 'Sửa ${user.fullName}',
                                      onPressed: _busy
                                          ? null
                                          : () => _edit(user),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'Xóa ${user.fullName}',
                                      onPressed: _busy
                                          ? null
                                          : () => _delete(user),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

