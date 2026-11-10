import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'managed_user.dart';

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const _configuredUrl = String.fromEnvironment('API_BASE_URL');
  static String get baseUrl {
    if (_configuredUrl.isNotEmpty) {
      return _configuredUrl.replaceAll(RegExp(r'/$'), '');
    }
    if (kIsWeb) return Uri.base.origin;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  final http.Client _client;
  String? token;
  String? adminEmail;

  Uri _url(String path) => Uri.parse('$baseUrl/api$path');
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<void> login(String email, String password) async {
    final response = await _client.post(
      _url('/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'matkhau': password}),
    );
    final data = _decode(response);
    token = data['token'] as String;
    adminEmail = email.trim().toLowerCase();
  }

  void logout() {
    token = null;
    adminEmail = null;
  }

  Future<List<ManagedUser>> listUsers() async {
    final response = await _client.get(_url('/users'), headers: _headers);
    final data = _decode(response);
    return (data['users'] as List)
        .map((item) => ManagedUser.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<String> createUser(UserDraft draft) async {
    final response = await _client.post(
      _url('/users'),
      headers: _headers,
      body: jsonEncode({
        'email': draft.email,
        'hoten': draft.fullName,
        'matkhau': draft.password,
        if (draft.imageBytes != null)
          'hinhanh': 'data:${draft.imageMimeType ?? 'image/jpeg'};base64,${base64Encode(draft.imageBytes!)}',
      }),
    );
    return (_decode(response)['user'] as Map<String, dynamic>)['_id'] as String;
  }

  Future<void> updateUser(ManagedUser user, UserDraft draft) async {
    final response = await _client.put(
      _url('/users/${user.id}'),
      headers: _headers,
      body: jsonEncode({
        'email': draft.email,
        'hoten': draft.fullName,
        if (draft.password.isNotEmpty) 'matkhau': draft.password,
        if (draft.imageBytes != null)
          'hinhanh': 'data:${draft.imageMimeType ?? 'image/jpeg'};base64,${base64Encode(draft.imageBytes!)}',
      }),
    );
    _decode(response);
  }

  Future<void> deleteUser(String id) async {
    final response = await _client.delete(
      _url('/users/$id'),
      headers: _headers,
    );
    _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Máy chủ trả về dữ liệu không hợp lệ (${response.statusCode}).',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['error'] as String? ??
            'Yêu cầu thất bại (${response.statusCode}).',
      );
    }
    return data;
  }
}
