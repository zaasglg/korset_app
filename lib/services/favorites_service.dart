import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:korset_app/models/favorite_item.dart';

class FavoritesService {
  static const String _favoritesKey = 'user_favorites';

  // Получить все избранные объявления
  static Future<List<FavoriteItem>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? favoritesJson = prefs.getString(_favoritesKey);
      
      if (favoritesJson == null || favoritesJson.isEmpty) {
        return [];
      }

      final List<dynamic> favoritesList = json.decode(favoritesJson);
      return favoritesList
          .map((item) => FavoriteItem.fromJson(item))
          .toList();
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }

  // Добавить в избранное
  static Future<bool> addToFavorites(FavoriteItem item) async {
    try {
      final favorites = await getFavorites();
      
      // Проверяем, не добавлен ли уже этот элемент
      if (favorites.any((fav) => fav.id == item.id)) {
        return false; // Уже в избранном
      }

      favorites.add(item);
      await _saveFavorites(favorites);
      return true;
    } catch (e) {
      print('Error adding to favorites: $e');
      return false;
    }
  }

  // Удалить из избранного
  static Future<bool> removeFromFavorites(String itemId) async {
    try {
      final favorites = await getFavorites();
      final updatedFavorites = favorites.where((item) => item.id != itemId).toList();
      
      await _saveFavorites(updatedFavorites);
      return true;
    } catch (e) {
      print('Error removing from favorites: $e');
      return false;
    }
  }

  // Проверить, находится ли объявление в избранном
  static Future<bool> isFavorite(String itemId) async {
    try {
      final favorites = await getFavorites();
      return favorites.any((item) => item.id == itemId);
    } catch (e) {
      print('Error checking if favorite: $e');
      return false;
    }
  }

  // Очистить все избранное
  static Future<bool> clearFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoritesKey);
      return true;
    } catch (e) {
      print('Error clearing favorites: $e');
      return false;
    }
  }

  // Получить количество избранных объявлений
  static Future<int> getFavoritesCount() async {
    try {
      final favorites = await getFavorites();
      return favorites.length;
    } catch (e) {
      print('Error getting favorites count: $e');
      return 0;
    }
  }

  // Сохранить список избранного
  static Future<void> _saveFavorites(List<FavoriteItem> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final String favoritesJson = json.encode(
      favorites.map((item) => item.toJson()).toList(),
    );
    await prefs.setString(_favoritesKey, favoritesJson);
  }
}
