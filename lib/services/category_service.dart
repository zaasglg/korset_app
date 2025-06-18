import '../models/category.dart';
import 'api_service.dart';
import 'dart:developer' as developer;

class CategoryService {
  final ApiService _apiService;

  CategoryService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<List<Category>> getCategories() async {
    try {
      developer.log('Fetching categories from API');
      final response = await _apiService.get('/api/categories');
      developer.log('API response received');

      // Handle the exact API response structure shown in the example
      if (response != null && response is Map) {
        // Check for success status
        if (response['status'] == 'success' && response['data'] != null && response['data'] is List) {
          developer.log('Found categories in data array');
          final categories = (response['data'] as List)
              .map((item) => Category.fromJson(item))
              .toList();
          
          developer.log('Parsed ${categories.length} categories');
          // Log the first category and its children for debugging
          if (categories.isNotEmpty) {
            developer.log('First category: ${categories[0].name} with ${categories[0].children.length} children');
          }
          
          return categories;
        }
      }

      // Fallback handling for other response formats
      if (response != null) {
        // Direct list of categories
        if (response is List) {
          developer.log('Response is a direct list');
          return response.map((item) => Category.fromJson(item)).toList();
        }
        
        if (response is Map) {
          // Check other possible formats
          if (response['data'] != null && response['data'] is List) {
            developer.log('Response has data wrapper');
            return (response['data'] as List)
                .map((item) => Category.fromJson(item))
                .toList();
          }
          
          if (response['categories'] != null && response['categories'] is List) {
            developer.log('Response has categories wrapper');
            return (response['categories'] as List)
                .map((item) => Category.fromJson(item))
                .toList();
          }
        }
      }

      developer.log('Could not parse categories from response format');
      return [];
    } catch (e) {
      developer.log('Error fetching categories: $e', error: e);
      return [];
    }
  }
  
  // Get a flattened list of all categories including children
  List<Category> getAllCategoriesFlattened(List<Category> categories) {
    List<Category> allCategories = [];
    
    for (var category in categories) {
      allCategories.add(category);
      if (category.children.isNotEmpty) {
        allCategories.addAll(getAllCategoriesFlattened(category.children));
      }
    }
    
    return allCategories;
  }
}
