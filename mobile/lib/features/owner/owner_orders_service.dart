import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_service.dart';

/// An order as returned by `GET /api/orders/shop`.
class OwnerOrder {
  OwnerOrder({
    required this.id,
    required this.studentName,
    required this.items,
    required this.total,
    required this.createdAt,
    required this.status,
    this.pickupTime,
    this.note,
  });

  factory OwnerOrder.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((item) => '${item['quantity']}× ${item['name']}')
        .join('\n');
    return OwnerOrder(
      id: json['id'] as String,
      studentName: json['student_name'] as String? ?? 'Student',
      items: items,
      total: num.tryParse('${json['total']}') ?? 0,
      createdAt:
          DateTime.tryParse('${json['created_at']}')?.toLocal() ??
          DateTime.now(),
      status: json['status'] as String? ?? 'pending',
      pickupTime: DateTime.tryParse('${json['pickup_time']}')?.toLocal(),
      note: json['note'] as String?,
    );
  }

  final String id, studentName, items, status;
  final num total;
  final DateTime createdAt;
  final DateTime? pickupTime;
  final String? note;

  bool get isPending => status == 'pending';

  /// Short, readable reference built from the order's UUID.
  String get shortId => id.split('-').first.toUpperCase();
}

class OwnerOrdersService {
  /// Orders for the signed-in owner's shop, newest first.
  static Future<List<OwnerOrder>> fetch({http.Client? client}) async {
    final data = await _send('GET', '/api/orders/shop', client: client);
    final orders = data['orders'];
    if (orders is! List) throw const OrdersException(_unexpected);
    return orders
        .whereType<Map<String, dynamic>>()
        .map(OwnerOrder.fromJson)
        .toList();
  }

  /// Accepts a pending order. The backend requires a pickup time between
  /// 5 minutes and 24 hours from now, and notifies the student.
  static Future<void> accept(
    String orderId,
    DateTime pickupTime, {
    http.Client? client,
  }) => _send(
    'PATCH',
    '/api/orders/$orderId/status',
    body: {
      'status': 'accepted',
      'pickup_time': pickupTime.toUtc().toIso8601String(),
    },
    client: client,
  );

  /// Rejects a pending order. The backend stores this as `cancelled` and
  /// notifies the student.
  static Future<void> reject(String orderId, {http.Client? client}) => _send(
    'PATCH',
    '/api/orders/$orderId/status',
    body: {'status': 'cancelled'},
    client: client,
  );

  static const _unexpected =
      'The server returned an unexpected response. Please try again.';

  static Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    http.Client? client,
  }) async {
    final bearer = AuthService.token;
    if (bearer == null) {
      throw const OrdersException(
        'Please sign in to manage orders.',
        signedOut: true,
      );
    }
    final base = AuthService.apiBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    if (base.isEmpty) {
      throw const OrdersException(
        'The server address has not been configured.',
      );
    }
    final transport = client ?? http.Client();
    try {
      final uri = Uri.parse('$base$path');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $bearer',
      };
      final response =
          await (method == 'PATCH'
                  ? transport.patch(
                      uri,
                      headers: headers,
                      body: jsonEncode(body),
                    )
                  : transport.get(uri, headers: headers))
              .timeout(const Duration(seconds: 20));
      if (response.statusCode == 401) {
        AuthService.logout();
        throw const OrdersException(
          'Your session has expired. Please sign in again.',
          signedOut: true,
        );
      }
      if (response.statusCode == 404 && method == 'PATCH') {
        throw const OrdersException(
          'This order was already handled or cancelled by the student.',
          stale: true,
        );
      }
      if (response.statusCode >= 500) {
        throw const OrdersException(
          'The server is unavailable. Please try again later.',
        );
      }
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) throw const FormatException();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OrdersException(
          data['message'] is String
              ? data['message'] as String
              : 'Unable to complete the request. Please try again.',
        );
      }
      return data;
    } on TimeoutException {
      throw const OrdersException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const OrdersException(
        'Could not connect to the server. Check your connection and try again.',
      );
    } on FormatException {
      throw const OrdersException(_unexpected);
    } finally {
      if (client == null) transport.close();
    }
  }
}

class OrdersException implements Exception {
  const OrdersException(
    this.message, {
    this.stale = false,
    this.signedOut = false,
  });
  final String message;

  /// True when there is no valid session, so polling should stop.
  final bool signedOut;

  /// True when the order changed on the server, so the list should reload.
  final bool stale;
}
