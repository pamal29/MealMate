import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mealmate/features/auth/auth_service.dart';

void main() {
  const user = {
    'id': 'u1',
    'name': 'Student',
    'email': 'student@example.com',
    'role': 'student',
  };
  tearDown(AuthService.logout);

  test('Login sends backend contract and profile uses bearer token', () async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/login')) {
        expect(request.method, 'POST');
        expect(jsonDecode(request.body), {
          'email': 'student@example.com',
          'password': ' secret ',
        });
        return http.Response(
          jsonEncode({'token': 'jwt-token', 'user': user}),
          200,
        );
      }
      expect(request.url.path, '/api/auth/me');
      expect(request.method, 'GET');
      expect(request.headers['Authorization'], 'Bearer jwt-token');
      return http.Response(jsonEncode({'user': user}), 200);
    });
    await AuthService.login(
      ' Student@Example.com ',
      ' secret ',
      client: client,
    );
    expect(AuthService.token, 'jwt-token');
    expect(await AuthService.profile(client: client), user);
  });

  test('Register submits role and accepts 201 session', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/auth/register');
      expect(jsonDecode(request.body), {
        'name': 'Owner',
        'email': 'owner@example.com',
        'password': 'secret123',
        'role': 'shop_owner',
      });
      return http.Response(
        jsonEncode({
          'token': 'owner-token',
          'user': {...user, 'role': 'shop_owner'},
        }),
        201,
      );
    });
    await AuthService.register(
      ' Owner ',
      'Owner@Example.com',
      'secret123',
      role: 'shop_owner',
      client: client,
    );
    expect(AuthService.user?['role'], 'shop_owner');
  });

  test(
    'Duplicate registration shows backend message without a session',
    () async {
      await expectLater(
        AuthService.register(
          'Student',
          'student@example.com',
          'secret123',
          client: MockClient(
            (_) async =>
                http.Response('{"message":"Email already registered"}', 409),
          ),
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Email already registered',
          ),
        ),
      );
      expect(AuthService.token, isNull);
    },
  );

  test('Rejected login clears any previous session', () async {
    AuthService.token = 'old-token';
    AuthService.user = user;
    await expectLater(
      AuthService.login(
        'student@example.com',
        'wrong',
        client: MockClient((_) async => http.Response('{}', 401)),
      ),
      throwsA(isA<AuthException>()),
    );
    expect(AuthService.token, isNull);
    expect(AuthService.user, isNull);
  });

  test('Expired bearer token clears session', () async {
    AuthService.token = 'expired';
    AuthService.user = user;
    await expectLater(
      AuthService.profile(
        client: MockClient((_) async => http.Response('{}', 401)),
      ),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('expired'),
        ),
      ),
    );
    expect(AuthService.token, isNull);
    expect(AuthService.user, isNull);
  });

  test('Malformed server response never establishes a session', () async {
    for (final body in ['<html>Error</html>', '{"token":"","user":{}}', '[]']) {
      await expectLater(
        AuthService.login(
          'student@example.com',
          'secret',
          client: MockClient((_) async => http.Response(body, 200)),
        ),
        throwsA(isA<AuthException>()),
      );
      expect(AuthService.token, isNull);
    }
  });

  test('Network failure has a useful message', () async {
    await expectLater(
      AuthService.login(
        'student@example.com',
        'secret',
        client: MockClient(
          (_) async => throw http.ClientException('connection refused'),
        ),
      ),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('Could not connect'),
        ),
      ),
    );
  });
}
