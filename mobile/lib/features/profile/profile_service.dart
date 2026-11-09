import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class ProfileException implements Exception {
  ProfileException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ProfileService {
  // TODO: use your existing API base URL and token storage
  static const _baseUrl = 'http://10.0.2.2:3000/api';

  static Future<Map<String, dynamic>> update({
    required String token,
    String? name,
    String? email,
    String? phone,
    String? currentPassword,
    String? newPassword,
    XFile? image,
  }) async {
    final req = http.MultipartRequest('PATCH', Uri.parse('$_baseUrl/profile'))
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

    final res = await http.Response.fromStream(await req.send());
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw ProfileException(body['message'] as String? ?? 'Update failed');
    }
    return body['user'] as Map<String, dynamic>;
  }
}