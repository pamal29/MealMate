import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_service.dart';
import '../home/models/shop.dart';
import 'tray.dart';

/// Student browsing and ordering endpoints (`/api/shops`, `/api/orders`).
class StudentApi {
  /// Replaced by a mock in tests.
  static http.Client? client;

  /// Open shops first, as the backend orders them. No login needed.
  static Future<List<Shop>> shops() async {
    final data = await _send('GET', '/api/shops');
    if (data is! List) throw const StudentApiException(_unexpected);
    return data.whereType<Map<String, dynamic>>().map(_shop).toList();
  }

  /// The items a shop currently has available. No login needed.
  static Future<List<FoodItem>> menu(String shopId) async {
    final data = await _send('GET', '/api/shops/$shopId');
    final items = data is Map<String, dynamic> ? data['items'] : null;
    if (items is! List) throw const StudentApiException(_unexpected);
    return items.whereType<Map<String, dynamic>>().map(_item).toList();
  }

  static Future<Map<String, dynamic>> placeOrder({
    required String shopId,
    required Map<String, int> quantities,
  }) async {
    final data = await _send(
      'POST',
      '/api/orders',
      body: {
        'shop_id': shopId,
        'items': [
          for (final e in quantities.entries)
            {'menu_item_id': e.key, 'quantity': e.value},
        ],
      },
    );
    final order = data is Map<String, dynamic> ? data['order'] : null;
    if (order is! Map<String, dynamic>) {
      throw const StudentApiException(_unexpected);
    }
    return order;
  }

  static Future<List<Map<String, dynamic>>> myOrders() async {
    final data = await _send('GET', '/api/orders/mine');
    final orders = data is Map<String, dynamic> ? data['orders'] : null;
    if (orders is! List) throw const StudentApiException(_unexpected);
    return orders.whereType<Map<String, dynamic>>().toList();
  }

  static Future<void> cancelOrder(String id) =>
      _send('PATCH', '/api/orders/$id/cancel');

  static Shop _shop(Map<String, dynamic> json) => Shop(
    id: '${json['id']}',
    name: json['name'] as String? ?? '',
    category: json['category'] as String? ?? '',
    location: json['location'] as String? ?? '',
    rating: double.tryParse('${json['rating']}') ?? 0,
    isOpen: json['is_open'] != false,
    imageAsset: '',
  );

  static FoodItem _item(Map<String, dynamic> json) => FoodItem(
    '${json['id']}',
    json['name'] as String? ?? '',
    json['description'] as String? ?? '',
    '',
    parsePrice(json['price']),
    null,
  );

  static const _unexpected =
      'The server returned an unexpected response. Please try again.';

  static Future<Object?> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final base = AuthService.apiBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    if (base.isEmpty) {
      throw const StudentApiException(
        'The server address has not been configured.',
      );
    }
    final bearer = AuthService.token;
    final transport = client ?? http.Client();
    try {
      final request = http.Request(method, Uri.parse('$base$path'));
      if (bearer != null) {
        request.headers['Authorization'] = 'Bearer $bearer';
      }
      if (body != null) {
        request
          ..headers['Content-Type'] = 'application/json'
          ..body = jsonEncode(body);
      }
      final response = await http.Response.fromStream(
        await transport.send(request).timeout(const Duration(seconds: 20)),
      );
      if (response.statusCode == 401) {
        AuthService.logout();
        throw const StudentApiException('Please sign in to continue.');
      }
      if (response.statusCode >= 500) {
        throw const StudentApiException(
          'The server is unavailable. Please try again later.',
        );
      }
      final data = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StudentApiException(
          data is Map && data['message'] is String
              ? data['message'] as String
              : 'Unable to complete the request. Please try again.',
        );
      }
      return data;
    } on TimeoutException {
      throw const StudentApiException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const StudentApiException(
        'Could not connect to the server. Check your connection and try again.',
      );
    } on FormatException {
      throw const StudentApiException(_unexpected);
    } finally {
      if (client == null) transport.close();
    }
  }
}

class StudentApiException implements Exception {
  const StudentApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
