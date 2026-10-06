import 'dart:convert';
import 'package:flutter/foundation.dart'; // Needed for kIsWeb
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:angkor_burger_app/models/product_model.dart';

class RestApi {
  // Automatically switches between Chrome/Web (127.0.0.1) and Android Emulator (10.0.2.2)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    return 'http://10.0.2.2:8000/api';
  }

// Fetch all staff members
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

// Create a staff user
  static Future<Map<String, dynamic>> createStaffUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/create-staff'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      );

      debugPrint('Create Staff Status: ${response.statusCode}');
      debugPrint('Create Staff Body: ${response.body}');

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': 'Staff added successfully!'};
      } else {
        // Return the specific Laravel validation message
        final errorMsg = data['message'] ?? 'Failed to add staff.';
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      debugPrint('Error creating staff: $e');
      return {'success': false, 'message': 'Network/Connection error: $e'};
    }
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// PUT /api/user/profile - Save updated profile details to Laravel MySQL
  static Future<bool> updateUserProfile({
    required String email,
    required String name,
    required String phone,
    required String address,
    String? gender,
    String? dateOfBirth,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'name': name,
          'phone': phone,
          'address': address,
          'gender': gender,
          'date_of_birth': dateOfBirth,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating profile in Laravel: $e');
      return false;
    }
  }

  /// POST /api/categories - Save a new category to MySQL database
  static Future<bool> createCategory(String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories'),
        headers: _headers,
        body: jsonEncode({'name': name}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error in createCategory: $e');
      return false;
    }
  }

  /// GET /api/user/profile?email=...
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

  /// GET /api/categories - Fetch all categories from backend
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

  /// 1. READ (GET all products)
  static Future<List<ProductModel>> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: _headers,
      );
      debugPrint('--> [RestApi] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List data = decoded is List ? decoded : (decoded['data'] ?? []);

        debugPrint('--> [RestApi] Parsing ${data.length} raw JSON items...');
        final products =
            data.map((item) => ProductModel.fromJson(item)).toList();
        debugPrint(
            '--> [RestApi] Successfully parsed ${products.length} products!');
        return products;
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e, stack) {
      debugPrint('Error in fetchProducts: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  /// 2. MULTIPART POST: Send file bytes + text fields
  static Future<bool> uploadProductWithImage({
    required Map<String, dynamic> fields,
    XFile? imageFile,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/products');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Accept'] = 'application/json';

      // Add text fields
      fields.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Add the image file bytes
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
      debugPrint('Error in uploadProductWithImage: $e');
      return false;
    }
  }

  /// 3. CREATE via JSON (fallback if no image file)
  static Future<bool> createProduct(Map<String, dynamic> productData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: _headers,
        body: jsonEncode(productData),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error in createProduct: $e');
      return false;
    }
  }

  /// 4. UPDATE with optional image file upload
  static Future<bool> updateProductWithImage({
    required int id,
    required Map<String, dynamic> fields,
    XFile? imageFile,
  }) async {
    try {
      // Laravel handles PUT requests with files best using POST with _method = PUT
      final uri = Uri.parse('$baseUrl/products/$id');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Accept'] = 'application/json';
      request.fields['_method'] = 'PUT'; // Method spoofing for Laravel

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
      debugPrint('Error in updateProductWithImage: $e');
      return false;
    }
  }

  /// 5. DELETE product by ID
  static Future<bool> deleteProduct(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$id'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error in deleteProduct: $e');
      return false;
    }
  }
}
