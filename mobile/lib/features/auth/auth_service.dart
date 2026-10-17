import 'dart:convert';

import 'package:http/http.dart' as http;

/// Keeps the authenticated session in memory; never writes credentials to disk.
class AuthService {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static String? token;
  static Map<String, dynamic>? user;

  static Future<void> login(String email, String password) async {
    if (apiBaseUrl.isEmpty) {
      throw const AuthException(
        'Login is not configured yet. Please try again later.',
      );
    }
    final base = apiBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    final response = await http
        .post(
          Uri.parse('$base/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim(), 'password': password}),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 401) {
      throw const AuthException(
        'Incorrect email or password. Please try again.',
      );
    }
    if (response.statusCode != 200) {
      throw const AuthException(
        'Unable to sign in right now. Please try again later.',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['token'] is! String ||
        (data['token'] as String).isEmpty ||
        data['user'] is! Map<String, dynamic>) {
      throw const AuthException(
        'Unable to complete sign-in. Please try again.',
      );
    }
    token = data['token'] as String;
    user = data['user'] as Map<String, dynamic>;
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}
