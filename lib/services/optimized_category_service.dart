import '../models/category.dart';
import 'optimized_api_service.dart';
import 'dart:developer' as developer;

/// Optimized Category Service with caching and better error handling
class OptimizedCategoryService {
  static OptimizedCategoryService? _instance;
  final OptimizedApiService _apiService;

  OptimizedCategoryService._() 
      : _apiService = OptimizedApiService(instanceKey: 'categories');

  factory OptimizedCategoryService() {
    return _instance ??= OptimizedCategoryService._();
  }

  /// Get categories with caching and optimized parsing
  Future<List<Category>> getCategories({bool useCache = true}) async {
    try {
      developer.log('Fetching categories from API with cache: $useCache');
      
      final response = await _apiService.get(
        '/api/categories',
        useCache: useCache,
      );
      
      developer.log('API response received');

      // Handle the exact API response structure
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

  /// Get category by ID with caching
  Future<Category?> getCategoryById(int id, {bool useCache = true}) async {
    try {
      final response = await _apiService.get(
        '/api/categories/$id',
        useCache: useCache,
      );

      if (response != null && response is Map) {
        if (response['status'] == 'success' && response['data'] != null) {
          return Category.fromJson(response['data']);
        }
      }

      return null;
    } catch (e) {
      developer.log('Error fetching category by ID: $e', error: e);
      return null;
    }
  }

  /// Get categories with product counts
  Future<List<Map<String, dynamic>>> getCategoriesWithCounts({bool useCache = true}) async {
    try {
      final response = await _apiService.get(
        '/api/categories/with-counts',
        useCache: useCache,
      );

      if (response != null && response is Map) {
        if (response['status'] == 'success' && response['data'] != null && response['data'] is List) {
          return List<Map<String, dynamic>>.from(response['data']);
        }
      }

      return [];
    } catch (e) {
      developer.log('Error fetching categories with counts: $e', error: e);
      return [];
    }
  }

  /// Get popular categories with caching
  Future<List<Category>> getPopularCategories({int limit = 10, bool useCache = true}) async {
    try {
      final response = await _apiService.get(
        '/api/categories/popular',
        queryParams: {'limit': limit},
        useCache: useCache,
      );

      if (response != null && response is Map) {
        if (response['status'] == 'success' && response['data'] != null && response['data'] is List) {
          return (response['data'] as List)
              .map((item) => Category.fromJson(item))
              .toList();
        }
      }

      return [];
    } catch (e) {
      developer.log('Error fetching popular categories: $e', error: e);
      return [];
    }
  }

  /// Get category tree with optimized structure
  Future<List<Category>> getCategoryTree({bool useCache = true}) async {
    final categories = await getCategories(useCache: useCache);
    return _buildCategoryTree(categories);
  }

  /// Build category tree from flat list
  List<Category> _buildCategoryTree(List<Category> categories) {
    final Map<int, Category> categoryMap = {};
    final List<Category> rootCategories = [];

    // Create a map for quick lookup
    for (final category in categories) {
      categoryMap[category.id] = category;
    }

    // Build the tree structure
    for (final category in categories) {
      if (category.parentId == null || category.parentId == 0) {
        rootCategories.add(category);
      } else {
        final parent = categoryMap[category.parentId];
        if (parent != null) {
          parent.children.add(category);
        }
      }
    }

    return rootCategories;
  }

  /// Get flattened list of all categories including children
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

  /// Search categories by name
  Future<List<Category>> searchCategories(String query, {bool useCache = true}) async {
    if (query.isEmpty) return [];

    try {
      final response = await _apiService.get(
        '/api/categories/search',
        queryParams: {'q': query},
        useCache: useCache,
      );

      if (response != null && response is Map) {
        if (response['status'] == 'success' && response['data'] != null && response['data'] is List) {
          return (response['data'] as List)
              .map((item) => Category.fromJson(item))
              .toList();
        }
      }

      return [];
    } catch (e) {
      developer.log('Error searching categories: $e', error: e);
      return [];
    }
  }

  /// Get categories by parent ID
  Future<List<Category>> getCategoriesByParent(int parentId, {bool useCache = true}) async {
    try {
      final response = await _apiService.get(
        '/api/categories/by-parent/$parentId',
        useCache: useCache,
      );

      if (response != null && response is Map) {
        if (response['status'] == 'success' && response['data'] != null && response['data'] is List) {
          return (response['data'] as List)
              .map((item) => Category.fromJson(item))
              .toList();
        }
      }

      return [];
    } catch (e) {
      developer.log('Error fetching categories by parent: $e', error: e);
      return [];
    }
  }

  /// Get category path (breadcrumb)
  Future<List<Category>> getCategoryPath(int categoryId, {bool useCache = true}) async {
    try {
      final response = await _apiService.get(
        '/api/categories/$categoryId/path',
        useCache: useCache,
      );

      if (response != null && response is Map) {
        if (response['status'] == 'success' && response['data'] != null && response['data'] is List) {
          return (response['data'] as List)
              .map((item) => Category.fromJson(item))
              .toList();
        }
      }

      return [];
    } catch (e) {
      developer.log('Error fetching category path: $e', error: e);
      return [];
    }
  }

  /// Get category statistics
  Future<Map<String, dynamic>> getCategoryStatistics({bool useCache = true}) async {
    try {
      final response = await _apiService.get(
        '/api/categories/statistics',
        useCache: useCache,
      );

      if (response != null && response is Map) {
        if (response['status'] == 'success' && response['data'] != null) {
          return Map<String, dynamic>.from(response['data']);
        }
      }

      return {};
    } catch (e) {
      developer.log('Error fetching category statistics: $e', error: e);
      return {};
    }
  }

  /// Batch get multiple categories by IDs
  Future<List<Category>> getCategoriesByIds(List<int> ids) async {
    if (ids.isEmpty) return [];

    try {
      // Create batch requests
      final requests = ids.map((id) => () => _apiService.get('/api/categories/$id')).toList();
      
      final responses = await _apiService.batch(requests);
      
      final categories = <Category>[];
      for (final response in responses) {
        try {
          if (response != null && response is Map && response['status'] == 'success') {
            categories.add(Category.fromJson(response['data']));
          }
        } catch (e) {
          // Skip invalid categories
          continue;
        }
      }
      
      return categories;
    } catch (e) {
      developer.log('Error batch fetching categories: $e', error: e);
      return [];
    }
  }

  /// Find category by name (case-insensitive)
  Future<Category?> findCategoryByName(String name, {bool useCache = true}) async {
    final categories = await getCategories(useCache: useCache);
    final allCategories = getAllCategoriesFlattened(categories);
    
    try {
      return allCategories.firstWhere(
        (category) => category.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get root categories only
  Future<List<Category>> getRootCategories({bool useCache = true}) async {
    final categories = await getCategories(useCache: useCache);
    return categories.where((category) => category.parentId == null || category.parentId == 0).toList();
  }

  /// Get subcategories for a category
  Future<List<Category>> getSubcategories(int parentId, {bool useCache = true}) async {
    final categories = await getCategories(useCache: useCache);
    final allCategories = getAllCategoriesFlattened(categories);
    
    return allCategories.where((category) => category.parentId == parentId).toList();
  }

  /// Check if category has children
  Future<bool> hasSubcategories(int categoryId, {bool useCache = true}) async {
    final subcategories = await getSubcategories(categoryId, useCache: useCache);
    return subcategories.isNotEmpty;
  }

  /// Get category depth level
  Future<int> getCategoryDepth(int categoryId, {bool useCache = true}) async {
    final path = await getCategoryPath(categoryId, useCache: useCache);
    return path.length;
  }

  /// Refresh categories cache
  Future<List<Category>> refreshCategories() async {
    _apiService.clearCacheEntry('GET', '/api/categories');
    return await getCategories(useCache: false);
  }

  /// Clear all category caches
  void clearCache() {
    _apiService.clearCache();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return _apiService.getCacheStats();
  }

  /// Preload category data for better performance
  Future<void> preloadCategoryData() async {
    try {
      // Preload categories, popular categories, and statistics
      await Future.wait([
        getCategories(),
        getPopularCategories(),
        getCategoryStatistics(),
      ]);
    } catch (e) {
      // Ignore preload errors
      developer.log('Error preloading category data: $e', error: e);
    }
  }

  /// Dispose resources
  void dispose() {
    _apiService.dispose();
  }
}