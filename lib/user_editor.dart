import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'app_theme.dart';
import 'managed_user.dart';

class UserEditor extends StatefulWidget {
  const UserEditor({super.key, this.user});
  final ManagedUser? user;

  @override
  State<UserEditor> createState() => _UserEditorState();
}

class _UserEditorState extends State<UserEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  late final TextEditingController _fullName;
  late final TextEditingController _password;
  Uint8List? _imageBytes;
  String? _imageMimeType;
  String? _imageError;
  bool _pickingImage = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.user?.email);
    _fullName = TextEditingController(text: widget.user?.fullName);
    _password = TextEditingController();
  }

  @override
  void dispose() {
    _email.dispose();
    _fullName.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() {
      _pickingImage = true;
      _imageError = null;
    });
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 5 * 1024 * 1024) {
        setState(() => _imageError = 'Ảnh phải nhỏ hơn 5 MB.');
        return;
      }
      final extension = file.name.split('.').last.toLowerCase();
      final mimeType = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        'jpg' || 'jpeg' => 'image/jpeg',
        _ => null,
      };
      if (mimeType == null) {
        setState(() => _imageError = 'Chọn ảnh JPEG, PNG, GIF hoặc WebP.');
        return;
      }
      setState(() {
        _imageBytes = bytes;
        _imageMimeType = mimeType;
      });
    } catch (_) {
      if (mounted) setState(() => _imageError = 'Không thể chọn ảnh.');
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate() || _pickingImage) return;
    Navigator.of(context).pop(
      UserDraft(
        email: _email.text.trim().toLowerCase(),
        fullName: _fullName.text.trim(),
        password: _password.text,
        imageBytes: _imageBytes,
        imageMimeType: _imageMimeType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 520,
        maxHeight: MediaQuery.sizeOf(context).height * .9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF1EEFF), Color(0xFFFAF9FF)],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    widget.user == null
                        ? Icons.person_add_alt_1_rounded
                        : Icons.manage_accounts_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'THÔNG TIN HỒ SƠ',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 9,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.user == null
                            ? 'Thêm người dùng'
                            : 'Sửa người dùng',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F5FF),
                        border: Border.all(color: const Color(0xFFE9E3FC)),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          UserAvatar(
                            name: _fullName.text,
                            bytes: _imageBytes ?? widget.user?.imageBytes,
                            size: 70,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ảnh đại diện',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  'JPG, PNG, GIF, WebP · tối đa 5 MB',
                                  style: TextStyle(
                                    fontSize: 10,
                                    height: 1.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 32),
                                    alignment: Alignment.centerLeft,
                                  ),
                                  onPressed: _pickingImage ? null : _pickImage,
                                  icon: const Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 16,
                                  ),
                                  label: Text(
                                    _pickingImage
                                        ? 'Đang chọn ảnh...'
                                        : 'Chọn ảnh',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_imageError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _imageError!,
                        style: const TextStyle(
                          color: AppColors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      maxLength: 254,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        prefixIcon: Icon(
                          Icons.alternate_email_rounded,
                          size: 20,
                        ),
                        counterText: '',
                      ),
                      validator: (value) =>
                          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(value?.trim() ?? '')
                          ? null
                          : 'Nhập email hợp lệ',
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _fullName,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      maxLength: 120,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Họ tên *',
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          size: 20,
                        ),
                        counterText: '',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Nhập họ tên'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _password,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: widget.user == null
                            ? 'Mật khẩu *'
                            : 'Mật khẩu mới',
                        helperText: widget.user == null
                            ? 'Tối thiểu 6 ký tự'
                            : 'Để trống để giữ mật khẩu hiện tại',
                        helperStyle: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          tooltip: _showPassword
                              ? 'Ẩn mật khẩu'
                              : 'Hiện mật khẩu',
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 19,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (widget.user != null &&
                            (value == null || value.isEmpty)) {
                          return null;
                        }
                        return value != null && value.length >= 6
                            ? null
                            : 'Mật khẩu cần ít nhất 6 ký tự';
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _pickingImage ? null : _save,
                    icon: const Icon(Icons.check_rounded, size: 19),
                    label: const Text('Lưu'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
