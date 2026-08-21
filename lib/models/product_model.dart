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
}
