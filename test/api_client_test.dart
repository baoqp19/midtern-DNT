import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:giuaki2/api_client.dart';
import 'package:giuaki2/managed_user.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('Create user sends credentials and avatar to MongoDB API', () async {
    final requests = <http.Request>[];
    final api = ApiClient(
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/api/login') {
          return http.Response(jsonEncode({'token': 'sample-token'}), 200);
        }
        return http.Response(
          jsonEncode({
            'user': {'_id': 'user-id'},
          }),
          201,
        );
      }),
    );

    await api.login('admin', 'admin123');
    expect(jsonDecode(requests.first.body), {
      'taikhoan': 'admin',
      'matkhau': 'admin123',
    });
    final id = await api.createUser(
      const UserDraft(
        email: 'bao@example.com',
        fullName: 'Nguyễn Bảo',
        password: 'secret123',
        imageBytes: [0xff, 0xd8, 0xff],
        imageMimeType: 'image/jpeg',
      ),
    );

    expect(id, 'user-id');
    expect(requests.last.url.path, '/api/users');
    expect(requests.last.headers['authorization'], 'Bearer sample-token');
    final body = jsonDecode(requests.last.body) as Map<String, dynamic>;
    expect(body['email'], 'bao@example.com');
    expect(body['hoten'], 'Nguyễn Bảo');
    expect(body['matkhau'], 'secret123');
    expect(body['hinhanh'], 'data:image/jpeg;base64,/9j/');
    expect(body.keys.toSet(), {'email', 'matkhau', 'hoten', 'hinhanh'});
  });
}
