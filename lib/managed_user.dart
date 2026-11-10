import 'dart:convert';
import 'dart:typed_data';

class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.imageBytes,
  });

  final String id;
  final String email;
  final String fullName;
  final Uint8List? imageBytes;

  factory ManagedUser.fromJson(Map<String, dynamic> json) => ManagedUser(
    id: json['_id'] as String,
    email: json['email'] as String,
    fullName: json['hoten'] as String,
    imageBytes: (json['hinhanh'] as String? ?? '').isEmpty
        ? null
        : base64Decode((json['hinhanh'] as String).split(',').last),
  );
}

class UserDraft {
  const UserDraft({
    required this.email,
    required this.fullName,
    required this.password,
    this.imageBytes,
    this.imageMimeType,
  });

  final String email;
  final String fullName;
  final String password;
  final List<int>? imageBytes;
  final String? imageMimeType;
}
