import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_service.dart';

/// The signed-in owner's shop, as returned by `/api/shops/mine`.
class OwnerShop {
  OwnerShop({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.isOpen,
  });

  factory OwnerShop.fromJson(Map<String, dynamic> json) => OwnerShop(
    id: '${json['id']}',
    name: json['name'] as String? ?? '',
    category: json['category'] as String? ?? '',
    location: json['location'] as String? ?? '',
    isOpen: json['is_open'] != false,
  );

  final String id, name, category, location;
  final bool isOpen;
}

/// Shop and menu endpoints for shop owners (`/api/shops/mine`, `/api/menu`).
class OwnerShopService {
  /// The owner's shop, or null if they have not created one yet.
  static Future<OwnerShop?> myShop({http.Client? client}) async {
    try {
      return OwnerShop.fromJson(
        _map(await _send('GET', '/api/shops/mine', client: client)),
      );
    } on ShopException catch (e) {
      if (e.notFound) return null;
      rethrow;
    }
  }

  static Future<OwnerShop> createShop({
    required String name,
    required String category,
    required String location,
    http.Client? client,
  }) async => OwnerShop.fromJson(
    _map(
      await _send(
        'POST',
        '/api/shops',
        body: {'name': name, 'category': category, 'location': location},
        client: client,
      ),
    ),
  );

  /// Updates only the fields that are passed.
  static Future<OwnerShop> updateShop({
    String? name,
    String? category,
    String? location,
    bool? isOpen,
    http.Client? client,
  }) async => OwnerShop.fromJson(
    _map(
      await _send(
        'PUT',
        '/api/shops/mine',
        body: {
          'name': ?name,
          'category': ?category,
          'location': ?location,
          'is_open': ?isOpen,
        },
        client: client,
      ),
    ),
  );

  /// The owner's menu items, newest first. Throws a [ShopException] with
  /// `notFound` set when the owner has no shop yet.
  static Future<List<Map<String, dynamic>>> myMenu({
    http.Client? client,
  }) async {
    final data = await _send('GET', '/api/menu/mine', client: client);
    if (data is! List) throw const ShopException(_unexpected);
    return data.whereType<Map<String, dynamic>>().toList();
  }

  static Future<Map<String, dynamic>> addItem({
    required String name,
    required String description,
    required num price,
    http.Client? client,
  }) async => _map(
    await _send(
      'POST',
      '/api/menu',
      body: {'name': name, 'description': description, 'price': price},
      client: client,
    ),
  );

  /// Updates only the fields that are passed.
  static Future<Map<String, dynamic>> updateItem(
    String id, {
    String? name,
    String? description,
    num? price,
    bool? isAvailable,
    http.Client? client,
  }) async => _map(
    await _send(
      'PUT',
      '/api/menu/$id',
      body: {
        'name': ?name,
        'description': ?description,
        'price': ?price,
        'is_available': ?isAvailable,
      },
      client: client,
    ),
  );

  static Future<void> deleteItem(String id, {http.Client? client}) =>
      _send('DELETE', '/api/menu/$id', client: client);

  static const _unexpected =
      'The server returned an unexpected response. Please try again.';

  static Map<String, dynamic> _map(Object? data) {
    if (data is! Map<String, dynamic>) throw const ShopException(_unexpected);
    return data;
  }

  static Future<Object?> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    http.Client? client,
  }) async {
    final bearer = AuthService.token;
    if (bearer == null) {
      throw const ShopException('Please sign in to manage your shop.');
    }
    final base = AuthService.apiBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    if (base.isEmpty) {
      throw const ShopException('The server address has not been configured.');
    }
    final transport = client ?? http.Client();
    try {
      final request = http.Request(method, Uri.parse('$base$path'))
        ..headers['Authorization'] = 'Bearer $bearer';
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
        throw const ShopException(
          'Your session has expired. Please sign in again.',
        );
      }
      if (response.statusCode >= 500) {
        throw const ShopException(
          'The server is unavailable. Please try again later.',
        );
      }
      final data = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ShopException(
          data is Map && data['message'] is String
              ? data['message'] as String
              : 'Unable to complete the request. Please try again.',
          notFound: response.statusCode == 404,
        );
      }
      return data;
    } on TimeoutException {
      throw const ShopException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const ShopException(
        'Could not connect to the server. Check your connection and try again.',
      );
    } on FormatException {
      throw const ShopException(_unexpected);
    } finally {
      if (client == null) transport.close();
    }
  }
}

class ShopException implements Exception {
  const ShopException(this.message, {this.notFound = false});
  final String message;

  /// True for a 404, e.g. the owner has not created a shop yet.
  final bool notFound;

  @override
  String toString() => message;
}
