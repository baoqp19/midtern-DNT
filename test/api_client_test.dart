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
            'user': {'id': 'user-id'},
          }),
          201,
        );
      }),
    );

    await api.login('admin@example.com', 'admin-password');
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
    expect(body['fullName'], 'Nguyễn Bảo');
    expect(body['password'], 'secret123');
    expect(body['avatarBase64'], '/9j/');
    expect(body['avatarContentType'], 'image/jpeg');
  });
}
