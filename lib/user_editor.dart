import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _imageMimeType = mimeType;
        });
      }
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
  Widget build(BuildContext context) {
    final bytes = _imageBytes ?? widget.user?.imageBytes;
    final ImageProvider? image = bytes == null ? null : MemoryImage(bytes);
    return AlertDialog(
      title: Text(widget.user == null ? 'Thêm người dùng' : 'Sửa người dùng'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 42,
                    backgroundImage: image,
                    child: image == null
                        ? const Icon(Icons.person, size: 42)
                        : null,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickingImage ? null : _pickImage,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    _pickingImage ? 'Đang chọn ảnh...' : 'Chọn ảnh đại diện',
                  ),
                ),
                if (_imageError != null)
                  Text(
                    _imageError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  maxLength: 254,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
                        ? null
                        : 'Nhập email hợp lệ';
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _fullName,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'Họ tên *'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nhập họ tên'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: widget.user == null
                        ? 'Mật khẩu *'
                        : 'Mật khẩu mới (để trống nếu giữ nguyên)',
                  ),
                  validator: (value) {
                    if (widget.user != null && (value == null || value.isEmpty)) {
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _pickingImage ? null : _save,
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
