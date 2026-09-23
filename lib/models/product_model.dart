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
    required this.sizePrices,
    required this.addOns,
    this.ingredients = const [],
    required this.nutritionFacts,
    this.specialInstruction,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // 1. Parse sizes list [{size_name: 'Regular', price: 12.0}] -> Map {'Regular': 12.0}
    final Map<String, double> parsedSizes = {};
    if (json['sizes'] != null && json['sizes'] is List) {
      for (var s in json['sizes']) {
        final sName = s['size_name']?.toString() ?? '';
        if (sName.isNotEmpty) {
          parsedSizes[sName] =
              double.tryParse(s['price']?.toString() ?? '0') ?? 0.0;
        }
      }
    }

    // 2. Parse addons list [{name: 'Bacon', price: 2.0}] -> Map {'Bacon': 2.0}
    final Map<String, double> parsedAddons = {};
    if (json['addons'] != null && json['addons'] is List) {
      for (var a in json['addons']) {
        final aName = a['name']?.toString() ?? '';
        if (aName.isNotEmpty) {
          parsedAddons[aName] =
              double.tryParse(a['price']?.toString() ?? '0') ?? 0.0;
        }
      }
    }

    // 3. Format nutrition string from calories and protein
    final cal = json['calories']?.toString() ?? '0';
    final pro = json['protein']?.toString() ?? '0g';
    final nutrition = '$cal kcal • $pro Protein';

    // 4. Handle image path (keep http/https intact, prevent duplicate assets/)
    String rawImage =
        (json['image_url'] ?? json['imagePath'] ?? '').toString().trim();
    String finalImagePath;

    if (rawImage.startsWith('http://') || rawImage.startsWith('https://')) {
      finalImagePath = rawImage;
    } else if (rawImage.isNotEmpty) {
      if (rawImage.startsWith('assets/assets/')) {
        finalImagePath = rawImage.replaceFirst('assets/assets/', 'assets/');
      } else if (!rawImage.startsWith('assets/')) {
        finalImagePath = 'assets/$rawImage';
      } else {
        finalImagePath = rawImage;
      }
    } else {
      finalImagePath = 'assets/images/imagelist1.jpg';
    }

    // 5. Robust Dynamic Category Extraction
    String parsedCategory = '';
    if (json['category'] != null) {
      if (json['category'] is Map) {
        parsedCategory = (json['category']['name'] ?? '').toString().trim();
      } else {
        parsedCategory = json['category'].toString().trim();
      }
    }

    if (parsedCategory.isEmpty && json['category_name'] != null) {
      parsedCategory = json['category_name'].toString().trim();
    }

    // Intelligent fallback only if backend sends nothing
    if (parsedCategory.isEmpty) {
      final nameLower = (json['name'] ?? '').toString().toLowerCase();
      if (nameLower.contains('wing') || nameLower.contains('chicken')) {
        parsedCategory = 'Chicken & Wings';
      } else if (nameLower.contains('potato') ||
          nameLower.contains('fries') ||
          nameLower.contains('drink')) {
        parsedCategory = 'Sides & Wings';
      } else {
        parsedCategory = 'Burgers (Gourmet Series)';
      }
    }

    // 6. Robust Boolean Parsing for active, popular, and in_stock
    // Handles 1, true, '1', 'true', 0, false, '0', 'false'
    bool parseBool(dynamic val, {bool defaultValue = false}) {
      if (val == null) return defaultValue;
      if (val is bool) return val;
      if (val is num) return val != 0;
      final s = val.toString().trim().toLowerCase();
      if (s == '1' || s == 'true') return true;
      if (s == '0' || s == 'false') return false;
      return defaultValue;
    }

    final bool parsedActive = parseBool(
      json['is_active'] ?? json['isActive'],
      defaultValue: true,
    );

    final bool parsedPopular = parseBool(
      json['is_popular'] ?? json['isPopular'],
      defaultValue: false,
    );

    final rawInStock = json['is_in_stock'];
    final bool parsedInStock = rawInStock == null ||
        rawInStock == 1 ||
        rawInStock == true ||
        rawInStock == '1';
    // final bool parsedInStock = parseBool(
    //   json['is_in_stock'] ?? json['isInStock'] ?? json['in_stock'],
    //   defaultValue: true,
    // );

    return ProductModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      price: double.tryParse(
              (json['base_price'] ?? json['price'] ?? 0).toString()) ??
          0.0,
      rating: double.tryParse((json['rating'] ?? 5.0).toString()) ?? 5.0,
      imagePath: finalImagePath,
      description: json['description']?.toString() ??
          'Delicious handcrafted burger with fresh ingredients.',
      category: parsedCategory,
      isActive: parsedActive,
      isPopular: parsedPopular,
      isInStock: parsedInStock,
      sizePrices: parsedSizes.isNotEmpty
          ? parsedSizes
          : {
              'Regular':
                  double.tryParse((json['base_price'] ?? 0).toString()) ?? 0.0
            },
      addOns: parsedAddons,
      ingredients: json['ingredients'] != null && json['ingredients'] is List
          ? List<String>.from(json['ingredients'].map((e) => e.toString()))
          : [],
      nutritionFacts: nutrition,
      specialInstruction: json['special_instruction']?.toString(),
    );
  }

  // Prepares the model to be sent to Laravel via POST or PUT
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
      'sizes': sizePrices.entries
          .map((e) => {'size_name': e.key, 'price': e.value})
          .toList(),
      'addons':
          addOns.entries.map((e) => {'name': e.key, 'price': e.value}).toList(),
    };
  }
}
