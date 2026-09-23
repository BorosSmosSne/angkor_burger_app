class ProductModel {
  final int id;
  final String name;
  final double price;
  final double rating;
  final String imagePath;
  final String description;
  final String category;
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
    required this.sizePrices,
    required this.addOns,
    this.ingredients = const [],
    required this.nutritionFacts,
    this.specialInstruction,
  });

  // Maps backend Laravel JSON directly to your existing Flutter model fields
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // 1. Parse sizes list [{size_name: 'Regular', price: 12.0}] -> Map {'Regular': 12.0}
    final Map<String, double> parsedSizes = {};
    if (json['sizes'] != null && json['sizes'] is List) {
      for (var s in json['sizes']) {
        parsedSizes[s['size_name']?.toString() ?? ''] =
            double.tryParse(s['price']?.toString() ?? '0') ?? 0.0;
      }
    }

    // 2. Parse addons list [{name: 'Bacon', price: 2.0}] -> Map {'Bacon': 2.0}
    final Map<String, double> parsedAddons = {};
    if (json['addons'] != null && json['addons'] is List) {
      for (var a in json['addons']) {
        parsedAddons[a['name']?.toString() ?? ''] =
            double.tryParse(a['price']?.toString() ?? '0') ?? 0.0;
      }
    }

    // 3. Format nutrition string from calories and protein
    final cal = json['calories']?.toString() ?? '0';
    final pro = json['protein']?.toString() ?? '0g';
    final nutrition = '$cal kcal • $pro Protein';

    // 4. Handle image path (keep http/https intact, prefix assets only if needed)
    String rawImage = json['image_url'] ?? json['imagePath'] ?? '';
    String finalImagePath;

    if (rawImage.startsWith('http://') || rawImage.startsWith('https://')) {
      finalImagePath = rawImage;
    } else if (rawImage.isNotEmpty) {
      finalImagePath =
          rawImage.startsWith('assets/') ? rawImage : 'assets/$rawImage';
    } else {
      finalImagePath = 'assets/images/imagelist1.jpg';
    }

    return ProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: double.tryParse(
              (json['base_price'] ?? json['price'] ?? 0).toString()) ??
          0.0,
      rating: double.tryParse((json['rating'] ?? 5.0).toString()) ?? 5.0,
      imagePath: finalImagePath,
      description: json['description'] ??
          'Delicious handcrafted burger with fresh ingredients.',
      category: json['category'] != null && json['category'] is Map
          ? (json['category']['name'] ?? 'Burgers')
          : 'Burgers',
      sizePrices: parsedSizes.isNotEmpty
          ? parsedSizes
          : {
              'Regular':
                  double.tryParse((json['base_price'] ?? 0).toString()) ?? 0.0
            },
      addOns: parsedAddons,
      ingredients: json['ingredients'] != null
          ? List<String>.from(json['ingredients'])
          : [],
      nutritionFacts: nutrition,
      specialInstruction: json['special_instruction'],
    );
  }

  // Prepares the model to be sent to Laravel via POST or PUT
  Map<String, dynamic> toJson({int categoryId = 1}) {
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
      'category_id': categoryId,
      'name': name,
      'base_price': price,
      'image_url': imagePath,
      'rating': rating,
      'calories': cal,
      'protein': pro,
      'ingredients': ingredients,
      'is_popular': true,
      'sizes': sizePrices.entries
          .map((e) => {'size_name': e.key, 'price': e.value})
          .toList(),
      'addons':
          addOns.entries.map((e) => {'name': e.key, 'price': e.value}).toList(),
    };
  }
}
