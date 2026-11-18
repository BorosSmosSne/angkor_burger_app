import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:angkor_burger_app/models/product_model.dart';

class RestApi {
  static String get serverOrigin {
  if (kIsWeb) return 'http://127.0.0.1:8000';
  if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000';
  return 'http://127.0.0.1:8000'; // iOS simulator / macOS
}
static String get baseUrl => '$serverOrigin/api';

/// Turns "uploads/x.jpg" or "http://anything:8000/uploads/x.jpg" into a reachable URL.
static String resolveImage(String raw) {
  final r = raw.trim();
  if (r.isEmpty) return '';
  final i = r.indexOf('/uploads/');
  if (r.startsWith('http') && i != -1) return Uri.encodeFull('$serverOrigin${r.substring(i)}');
  if (r.startsWith('http')) return Uri.encodeFull(r);
  if (r.startsWith('uploads/') || r.startsWith('/uploads/')) {
    return Uri.encodeFull('$serverOrigin/${r.replaceFirst(RegExp(r'^/'), '')}');
  }
  return r; // local asset
}
  static Map<String, String> get _headers => {
        'Accept': 'application/json',
      };
  static Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static String currentUserRole = 'customer';
  static int? currentUserId;

  static void resetSession() {
    currentUserRole = 'customer';
    currentUserId = null;
  }

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _jsonHeaders,
        body: jsonEncode({
          'email': email.trim(),
          'password': password.trim(),
        }),
      );

      final dynamic data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final role =
            data['user']?['role']?.toString().toLowerCase() ?? 'customer';
        currentUserRole = role;
        currentUserId = data['user']?['id'];

        return {
          'success': true,
          'user': data['user'],
          'role': role,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Invalid credentials.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  //   static String get baseUrl {
  //   // Android emulator reaches the Mac through 10.0.2.2.
  //   // Web, iOS simulator, and macOS use 127.0.0.1.
  //   if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
  //     return 'http://10.0.2.2:8000/api';
  //   }
  //   return 'http://127.0.0.1:8000/api';
  // }

  static Future<List<dynamic>> fetchStaffMembers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/staff'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching staff: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> createStaffUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/create-staff'),
        headers: _jsonHeaders,
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': 'Staff added successfully!'};
      } else {
        final errorMsg = data['message'] ?? 'Failed to add staff.';
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network/Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateStaffUser({
    required int id,
    required String name,
    required String email,
    required String phone,
    String? newPassword,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'name': name,
        'email': email,
        'phone': phone,
      };
      if (newPassword != null && newPassword.trim().isNotEmpty) {
        body['password'] = newPassword.trim();
      }

      final response = await http.put(
        Uri.parse('$baseUrl/admin/staff/$id'),
        headers: _jsonHeaders,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Staff updated successfully!'};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update staff'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<bool> deleteStaffUser(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/staff/$id'),
        headers: {'Accept': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateUserProfile({
    required String email,
    required String name,
    required String phone,
    required String address,
    String? password,
    String? gender,
    String? dateOfBirth,
    String? role,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: _jsonHeaders,
        body: jsonEncode({
          'email': email.trim(),
          'name': name.trim(),
          'phone': phone.trim().isNotEmpty ? phone.trim() : null,
          'address': address.trim().isNotEmpty ? address.trim() : null,
          'password': password,
          'plain_password': password,
          'gender': gender,
          'date_of_birth': dateOfBirth,
          'role': role ?? 'customer',
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error updating profile in Laravel: $e');
      return false;
    }
  }

  static Future<bool> createCategory(String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories'),
        headers: _headers,
        body: jsonEncode({'name': name}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> fetchUserProfile(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/profile?email=${Uri.encodeComponent(email)}'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is Map<String, dynamic> ? (data['user'] ?? data) : null;
      }
    } catch (e) {
      debugPrint('Error fetching profile from Laravel: $e');
    }
    return null;
  }

  static Future<List<dynamic>> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : (data['data'] ?? []);
      }
    } catch (e) {
      debugPrint('Error in fetchCategories: $e');
    }
    return [];
  }

  static Future<List<ProductModel>> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List data = decoded is List ? decoded : (decoded['data'] ?? []);
        return data.map((item) => ProductModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<bool> uploadProductWithImage({
    required Map<String, dynamic> fields,
    XFile? imageFile,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/products');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Accept'] = 'application/json';

      fields.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: imageFile.name,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> createProduct(Map<String, dynamic> productData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: _headers,
        body: jsonEncode(productData),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateProductWithImage({
    required int id,
    required Map<String, dynamic> fields,
    XFile? imageFile,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/products/$id');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Accept'] = 'application/json';
      request.fields['_method'] = 'PUT';

      fields.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: imageFile.name,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteProduct(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$id'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
