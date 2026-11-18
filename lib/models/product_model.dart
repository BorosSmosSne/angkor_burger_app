import 'package:flutter/foundation.dart';
import '../services/rest_api.dart';   // <-- add this
// import 'package:angkor_burger_app/helpers/image_url.dart';

class ProductModel {
  final int id;
  final String name;
  final double price;
  final double rating;
  final String imagePath;
  final String description;
  final String category;
  final bool isActive;
  final bool isPopular;
  final bool isInStock;
  final int stockQuantity;
  final Map<String, double> sizePrices;
  final Map<String, double> addOns;
  final List<String> ingredients;
  final String nutritionFacts;
  final String? specialInstruction;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.rating,
    required this.imagePath,
    required this.description,
    required this.category,
    this.isActive = true,
    this.isPopular = false,
    this.isInStock = true,
    this.stockQuantity = 0,
    required this.sizePrices,
    required this.addOns,
    this.ingredients = const [],
    required this.nutritionFacts,
    this.specialInstruction,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // 1. Parse Sizes / Portions
    final Map<String, double> parsedSizes = {};
    final rawSizes = json['sizes'];
    if (rawSizes != null && rawSizes is List && rawSizes.isNotEmpty) {
      for (final s in rawSizes) {
        if (s is Map) {
          final sName =
              s['size_name']?.toString() ?? s['name']?.toString() ?? 'M';
          final sPrice = double.tryParse((s['price'] ?? 0).toString()) ?? 0.0;
          parsedSizes[sName] = sPrice;
        }
      }
    }

    // Default tiered pricing fallback if API has no explicit size objects
    if (parsedSizes.isEmpty) {
      final double base = double.tryParse(
              (json['base_price'] ?? json['price'] ?? 0).toString()) ??
          0.0;
      parsedSizes['S'] = double.parse(base.toStringAsFixed(2));
      parsedSizes['M'] = double.parse((base + 1.50).toStringAsFixed(2));
      parsedSizes['L'] = double.parse((base + 3.00).toStringAsFixed(2));
    }

    // 2. Parse Add-ons
    final Map<String, double> parsedAddons = {};
    final rawAddons = json['addons'] ?? json['add_ons'] ?? json['addOns'];
    if (rawAddons != null && rawAddons is List) {
      for (final a in rawAddons) {
        if (a is Map) {
          final aName = a['name']?.toString() ?? '';
          final aPrice = double.tryParse((a['price'] ?? 0).toString()) ?? 0.0;
          if (aName.isNotEmpty) {
            parsedAddons[aName] = aPrice;
          }
        }
      }
    }

    // 3. Nutrition Facts
    final cal = json['calories']?.toString() ?? '800';
    final pro = json['protein']?.toString() ?? '30g';
    final nutrition = '$cal kcal • $pro Protein';

    final rawImage = (json['image_url'] ??
            json['imagePath'] ??
            json['image'] ??
            json['image_path'] ??
            '')
        .toString();
    final resolved = RestApi.resolveImage(rawImage);
    final finalImage = resolved.isEmpty
        ? 'assets/images/imagelist1.jpg'
        : (resolved.startsWith('http') || resolved.startsWith('assets/'))
            ? resolved
            : 'assets/$resolved';
    // 4. Safe Cross-Platform Image URL Resolver (see helpers/image_url.dart)
    // final String finalImage = resolveImageUrl(
    //   json['image_url'] ??
    //       json['imagePath'] ??
    //       json['image'] ??
    //       json['image_path'],
    // );

    // 5. Parse Category
    String parsedCategory = 'All';
    if (json['category'] != null) {
      if (json['category'] is Map) {
        parsedCategory = json['category']['name']?.toString() ?? 'All';
      } else {
        parsedCategory = json['category'].toString();
      }
    } else if (json['category_name'] != null) {
      parsedCategory = json['category_name'].toString();
    }

    parsedCategory = parsedCategory.trim();
    if (parsedCategory.isEmpty || parsedCategory.toLowerCase() == 'null') {
      final nameLower = (json['name'] ?? '').toString().toLowerCase();
      if (nameLower.contains('wing') || nameLower.contains('chicken')) {
        parsedCategory = 'Chicken & Wings';
      } else if (nameLower.contains('potato') ||
          nameLower.contains('fries') ||
          nameLower.contains('drink')) {
        parsedCategory = 'Sides & Wings';
      } else {
        parsedCategory = 'Burgers';
      }
    }

    // 6. Resilient Boolean Helper
    bool parseBool(dynamic val, {bool defaultValue = false}) {
      if (val == null) return defaultValue;
      if (val is bool) return val;
      if (val is num) return val != 0;
      final str = val.toString().trim().toLowerCase();
      if (str == '1' || str == 'true' || str == 'yes') return true;
      if (str == '0' || str == 'false' || str == 'no') return false;
      return defaultValue;
    }

    final bool active = parseBool(
      json['is_active'] ?? json['isActive'] ?? json['active'],
      defaultValue: true,
    );

    final bool popular = parseBool(
      json['is_popular'] ?? json['isPopular'] ?? json['popular'],
      defaultValue: false,
    );

    final bool inStock = parseBool(
      json['is_in_stock'] ?? json['isInStock'] ?? json['in_stock'],
      defaultValue: true,
    );

    return ProductModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'Burger',
      price: double.tryParse(
              (json['base_price'] ?? json['price'] ?? 0).toString()) ??
          0.0,
      rating: double.tryParse((json['rating'] ?? 4.8).toString()) ?? 4.8,
      imagePath: finalImage,
      description: json['description']?.toString() ?? '',
      category: parsedCategory,
      sizePrices: parsedSizes,
      addOns: parsedAddons,
      ingredients: json['ingredients'] != null && json['ingredients'] is List
          ? List<String>.from(json['ingredients'].map((x) => x.toString()))
          : [],
      nutritionFacts: nutrition,
      specialInstruction: json['special_instruction']?.toString(),
      isActive: active,
      isInStock: inStock,
      isPopular: popular,
      stockQuantity: int.tryParse(
              (json['stock_quantity'] ?? json['stock'] ?? 10).toString()) ??
          10,
    );
  }

  Map<String, dynamic> toJson({int? categoryId}) {
    int? cal;
    String? pro;
    if (nutritionFacts.contains('kcal')) {
      final parts = nutritionFacts.split('•');
      cal = int.tryParse(parts[0].replaceAll(RegExp(r'[^0-9]'), '').trim());
      if (parts.length > 1) {
        pro = parts[1].replaceAll('Protein', '').trim();
      }
    }

    return {
      if (categoryId != null) 'category_id': categoryId,
      'category_name': category,
      'name': name,
      'base_price': price,
      'image_url': imagePath,
      'rating': rating,
      'calories': cal,
      'protein': pro,
      'ingredients': ingredients,
      'is_active': isActive ? 1 : 0,
      'is_popular': isPopular ? 1 : 0,
      'is_in_stock': isInStock ? 1 : 0,
      'stock_quantity': stockQuantity,
      'sizes': sizePrices.entries
          .map((e) => {'size_name': e.key, 'price': e.value})
          .toList(),
      'addons':
          addOns.entries.map((e) => {'name': e.key, 'price': e.value}).toList(),
    };
  }
}
