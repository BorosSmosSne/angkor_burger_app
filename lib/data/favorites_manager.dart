import 'package:angkor_burger_app/data/dummy_data.dart';
import 'package:angkor_burger_app/models/product_model.dart';
import 'package:flutter/foundation.dart';

/// Global manager for user favorite products across the application.
class FavoritesManager {
  /// Reactive notifier for favorite product names
  static final ValueNotifier<Set<String>> favoriteProductNamesNotifier =
      ValueNotifier<Set<String>>({
    // Initial sample favorites
    'Truffle Burger',
    'Pepperoni Feast Pizza',
  });

  static Set<String> get favoriteNames =>
      favoriteProductNamesNotifier.value;

  static int get count => favoriteNames.length;

  static bool isFavorite(ProductModel product) {
    return favoriteNames.contains(product.name);
  }

  static bool isFavoriteName(String productName) {
    return favoriteNames.contains(productName);
  }

  static void toggleFavorite(ProductModel product) {
    final updated = Set<String>.from(favoriteNames);
    if (updated.contains(product.name)) {
      updated.remove(product.name);
    } else {
      updated.add(product.name);
    }
    favoriteProductNamesNotifier.value = updated;
  }

  static void setFavorite(ProductModel product, bool isFav) {
    final updated = Set<String>.from(favoriteNames);
    if (isFav) {
      updated.add(product.name);
    } else {
      updated.remove(product.name);
    }
    favoriteProductNamesNotifier.value = updated;
  }

  static void clearFavorites() {
    favoriteProductNamesNotifier.value = {};
  }

  /// Get list of favorite [ProductModel] objects from sampleProducts
  static List<ProductModel> getFavoriteProducts() {
    final favSet = favoriteNames;
    return sampleProducts.where((p) => favSet.contains(p.name)).toList();
  }
}
