import 'package:angkor_burger_app/data/user_profile_manager.dart';
import 'package:angkor_burger_app/models/product_model.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesManager {
  static final ValueNotifier<Set<String>> favoriteProductNamesNotifier =
      ValueNotifier<Set<String>>({});

  static Set<String> get favoriteNames => favoriteProductNamesNotifier.value;

  static int get count => favoriteNames.length;

  /// Builds a key unique to the active user (e.g., 'favorites_user1@gmail.com')
  static String _getUserStorageKey() {
    final email =
        UserProfileManager.profileNotifier.value.email.trim().toLowerCase();
    if (email.isNotEmpty) {
      return 'user_favorites_$email';
    }
    return 'user_favorites_guest';
  }

  /// Load favorites specifically for the currently logged-in user
  static Future<void> loadUserFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getUserStorageKey();
    final savedList = prefs.getStringList(key) ?? [];
    favoriteProductNamesNotifier.value = savedList.toSet();
  }

  static bool isFavorite(ProductModel product) {
    return favoriteNames.contains(product.name) ||
        favoriteNames.contains(product.id.toString());
  }

  static Future<void> toggleFavorite(ProductModel product) async {
    final updated = Set<String>.from(favoriteNames);
    final key = product.name;

    if (updated.contains(key)) {
      updated.remove(key);
    } else {
      updated.add(key);
    }

    favoriteProductNamesNotifier.value = updated;
    await _saveUserFavorites(updated);
  }

  static Future<void> setFavorite(ProductModel product, bool isFav) async {
    final updated = Set<String>.from(favoriteNames);
    final key = product.name;

    if (isFav) {
      updated.add(key);
    } else {
      updated.remove(key);
    }

    favoriteProductNamesNotifier.value = updated;
    await _saveUserFavorites(updated);
  }

  static Future<void> clearFavorites() async {
    favoriteProductNamesNotifier.value = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getUserStorageKey());
  }

  static Future<void> _saveUserFavorites(Set<String> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_getUserStorageKey(), favorites.toList());
  }
}
