import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Sessions stay in memory and are cleared on logout or an expired token.
class AuthService {
  static const _configuredUrl = String.fromEnvironment('API_BASE_URL');
  static String get apiBaseUrl => _configuredUrl.isNotEmpty
      ? _configuredUrl
      : kReleaseMode
      ? ''
      : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:3000'
      : 'http://localhost:3000';
  static String? token;
  static Map<String, dynamic>? user;

  static void logout() {
    token = null;
    user = null;
  }

  static Future<Map<String, dynamic>> _request(
    String path, {
    Map<String, dynamic>? body,
    String? bearer,
    http.Client? client,
  }) async {
    final base = apiBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    if (base.isEmpty) {
      throw const AuthException('The server address has not been configured.');
    }
    final transport = client ?? http.Client();
    try {
      final uri = Uri.parse('$base/api/auth/$path');
      final headers = {
        'Content-Type': 'application/json',
        if (bearer != null) 'Authorization': 'Bearer $bearer',
      };
      final response =
          await (body == null
                  ? transport.get(uri, headers: headers)
                  : transport.post(
                      uri,
                      headers: headers,
                      body: jsonEncode(body),
                    ))
              .timeout(const Duration(seconds: 20));
      if (response.statusCode == 401) {
        if (bearer != null) {
          logout();
          throw const AuthException(
            'Your session has expired. Please sign in again.',
          );
        }
        throw const AuthException(
          'Incorrect email or password. Please try again.',
        );
      }
      if (response.statusCode >= 500) {
        throw const AuthException(
          'The server is unavailable. Please try again later.',
        );
      }
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) throw const FormatException();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthException(
          data['message'] is String
              ? data['message'] as String
              : 'Unable to complete the request. Please try again.',
        );
      }
      return data;
    } on TimeoutException {
      throw const AuthException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const AuthException(
        'Could not connect to the server. Check your connection and try again.',
      );
    } on FormatException {
      throw const AuthException(
        'The server returned an unexpected response. Please try again.',
      );
    } finally {
      if (client == null) transport.close();
    }
  }

  static void _saveSession(Map<String, dynamic> data) {
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

  static Future<void> login(
    String email,
    String password, {
    http.Client? client,
  }) async {
    logout();
    _saveSession(
      await _request(
        'login',
        body: {'email': email.trim().toLowerCase(), 'password': password},
        client: client,
      ),
    );
  }

  static Future<void> register(
    String name,
    String email,
    String password, {
    String role = 'student',
    String? phone,
    http.Client? client,
  }) async {
    logout();
    _saveSession(
      await _request(
        'register',
        body: {
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'role': role,
          'phone': phone?.trim().isEmpty == true
            ? null
            : phone?.trim(),
        },
        client: client,
      ),
    );
  }

  static Future<Map<String, dynamic>> profile({http.Client? client}) async {
    final bearer = token;
    if (bearer == null) {
      throw const AuthException('Please sign in to view your profile.');
    }
    final data = await _request('me', bearer: bearer, client: client);
    if (data['user'] is! Map<String, dynamic>) {
      throw const AuthException(
        'Unable to load your profile. Please try again.',
      );
    }
    if (token != bearer) throw const AuthException('Please sign in again.');
    final profile = data['user'] as Map<String, dynamic>;
    if (!profile.containsKey('phone') && user?['phone'] != null) {
      profile['phone'] = user!['phone'];
    }
    return user = profile;
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}
