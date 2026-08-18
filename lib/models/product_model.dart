class ProductModel {
  final String name;
  final double price;
  final double rating;
  final String imagePath;
  final String description;
  final String category;

  ProductModel(
      {required this.name,
      required this.price,
      required this.rating,
      required this.imagePath,
      required this.description,
      required this.category});
}
