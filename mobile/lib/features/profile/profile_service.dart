import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/auth_service.dart'; // adjust path

class ProfileException implements Exception {
  ProfileException(this.message);
  final String message;
}

class ProfileService {
  static Future<Map<String, dynamic>> update({
    String? name,
    String? email,
    String? phone,
    String? currentPassword,
    String? newPassword,
    XFile? image,
  }) async {
    final token = AuthService.token;
    final base = AuthService.apiBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    if (token == null) throw ProfileException('Please sign in again.');
    if (base.isEmpty) {
      throw ProfileException('The server address has not been configured.');
    }

    final req = http.MultipartRequest('PATCH', Uri.parse('$base/api/profile'))
      ..headers['Authorization'] = 'Bearer $token';

    void field(String k, String? v) {
      if (v != null) req.fields[k] = v;
    }

    field('name', name);
    field('email', email);
    field('phone', phone);
    field('current_password', currentPassword);
    field('new_password', newPassword);

    if (image != null) {
      final ext = image.path.split('.').last.toLowerCase();
      final subtype = ext == 'jpg' ? 'jpeg' : ext; // jpeg | png | webp
      req.files.add(await http.MultipartFile.fromPath(
        'profile_picture',
        image.path,
        contentType: MediaType('image', subtype),
      ));
    }

    try {
      final res = await http.Response.fromStream(
        await req.send().timeout(const Duration(seconds: 30)),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        final updated = body['user'] as Map<String, dynamic>;
        AuthService.user = {...?AuthService.user, ...updated}; 
        return updated;
      }
      final msg = body['message'] as String? ?? 'Update failed';
      if (res.statusCode == 401 && msg != 'Current password is incorrect') {
        AuthService.logout();
        throw ProfileException('Your session has expired. Please sign in again.');
      }
      throw ProfileException(msg);
    } on TimeoutException {
      throw ProfileException('The server took too long to respond.');
    } on http.ClientException {
      throw ProfileException('Could not connect to the server.');
    } on FormatException {
      throw ProfileException('The server returned an unexpected response.');
    }
  }
}