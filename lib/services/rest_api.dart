import 'dart:convert';
import 'package:angkor_burger_app/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; //[cite: 8, 10]
// import '../models/burger_models.dart';

class RestApi {
  // IP Configurations:
  // - Android Emulator: 'http://10.0.2.2:8000/api'
  // - Physical Device: 'http://192.168.1.X:8000/api' (your computer's IP)
  // - Chrome / Windows: 'http://127.0.0.1:8000/api'
  // static const String baseUrl = 'http://10.0.2.2:8000/api';
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// POST /api/categories - Save a new category to MySQL database
  static Future<bool> createCategory(String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories'),
        headers: _headers,
        body: jsonEncode({'name': name}),
      );
      // Status 200 or 201 indicates success
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error in createCategory: $e');
      return false;
    }
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

  //// old
  // static Future<List<dynamic>> fetchCategories() async {
  //   try {
  //     final response = await http.get(
  //       Uri.parse('$baseUrl/categories'),
  //       headers: {'Accept': 'application/json'},
  //     );
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       final List list = data is List ? data : (data['data'] ?? []);
  //       return list.map((e) => Map<String, dynamic>.from(e)).toList();
  //     }
  //   } catch (e) {
  //     debugPrint('Error fetching categories: $e');
  //   }
  //   return [];
  // }

  // 1. READ (GET all products)[cite: 10]
  static Future<List<ProductModel>> fetchProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      //[cite: 10]
      final List data = jsonDecode(response.body); //[cite: 8, 10]
      return data
          .map((json) => ProductModel.fromJson(json))
          .toList(); //[cite: 8, 10]
    } else {
      throw Exception(
          'Failed to load products: ${response.statusCode}'); //[cite: 8]
    }
  }

// MULTIPART POST: Send file bytes + text fields
  static Future<bool> uploadProductWithImage({
    required Map<String, dynamic> fields,
    XFile? imageFile,
  }) async {
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
    return response.statusCode == 201;
  }

  // 2. CREATE (POST new product)[cite: 10]
  static Future<bool> createProduct(Map<String, dynamic> productData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: _headers,
      body: jsonEncode(productData),
    );
    return response.statusCode == 201; //[cite: 10]
  }

  // 3.Update with optional image file upload
  static Future<bool> updateProductWithImage({
    required int id,
    required Map<String, dynamic> fields,
    XFile? imageFile,
  }) async {
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
  }

  // 4. DELETE (DELETE product by ID)[cite: 10]
  static Future<bool> deleteProduct(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/products/$id'),
      headers: _headers,
    );
    return response.statusCode == 200; //[cite: 10]
  }
}
