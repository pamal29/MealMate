import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_service.dart';

/// A notification as returned by `GET /api/notifications`.
class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.orderId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        orderId: json['order_id'] as String?,
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? 'Notification',
        body: json['body'] as String? ?? '',
        isRead: json['is_read'] == true,
        createdAt:
            DateTime.tryParse('${json['created_at']}')?.toLocal() ??
            DateTime.now(),
      );

  final String id, type, title, body;
  final String? orderId;
  final DateTime createdAt;
  bool isRead;
}

class NotificationsService {
  /// The signed-in user's notifications, newest first (the backend returns
  /// at most 50).
  static Future<List<AppNotification>> fetch({http.Client? client}) async {
    final data = await _send('GET', '/api/notifications', client: client);
    final list = data['notifications'];
    if (list is! List) throw const NotificationsException(_unexpected);
    return list
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
  }

  /// Number of unread notifications, for badges.
  static Future<int> unreadCount({http.Client? client}) async =>
      (await fetch(client: client)).where((n) => !n.isRead).length;

  static Future<void> markRead(String id, {http.Client? client}) =>
      _send('PATCH', '/api/notifications/$id/read', client: client);

  static const _unexpected =
      'The server returned an unexpected response. Please try again.';

  static Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    http.Client? client,
  }) async {
    final bearer = AuthService.token;
    if (bearer == null) {
      throw const NotificationsException(
        'Please sign in to see your notifications.',
      );
    }
    final base = AuthService.apiBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    if (base.isEmpty) {
      throw const NotificationsException(
        'The server address has not been configured.',
      );
    }
    final transport = client ?? http.Client();
    try {
      final uri = Uri.parse('$base$path');
      final headers = {'Authorization': 'Bearer $bearer'};
      final response =
          await (method == 'PATCH'
                  ? transport.patch(uri, headers: headers)
                  : transport.get(uri, headers: headers))
              .timeout(const Duration(seconds: 20));
      if (response.statusCode == 401) {
        AuthService.logout();
        throw const NotificationsException(
          'Your session has expired. Please sign in again.',
        );
      }
      if (response.statusCode >= 500) {
        throw const NotificationsException(
          'The server is unavailable. Please try again later.',
        );
      }
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) throw const FormatException();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw NotificationsException(
          data['message'] is String
              ? data['message'] as String
              : 'Unable to complete the request. Please try again.',
        );
      }
      return data;
    } on TimeoutException {
      throw const NotificationsException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const NotificationsException(
        'Could not connect to the server. Check your connection and try again.',
      );
    } on FormatException {
      throw const NotificationsException(_unexpected);
    } finally {
      if (client == null) transport.close();
    }
  }
}

class NotificationsException implements Exception {
  const NotificationsException(this.message);
  final String message;
}
