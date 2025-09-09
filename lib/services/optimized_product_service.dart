import '../models/product.dart';
import '../models/product_filters.dart';
import 'optimized_api_service.dart';
import 'dart:io';

/// Optimized Product Service with caching, batch operations, and better error handling
class OptimizedProductService {
  static OptimizedProductService? _instance;
  final OptimizedApiService _apiService;

  OptimizedProductService._() 
      : _apiService = OptimizedApiService(instanceKey: 'products');

  factory OptimizedProductService() {
    return _instance ??= OptimizedProductService._();
  }

  /// Get products with optimized caching and query building
  Future<List<Product>> getProducts({
    int? categoryId,
    int? cityId,
    double? minPrice,
    double? maxPrice,
    String? search,
    int page = 1,
    int limit = 20,
    String? sortBy,
    List<int>? categoryIds,
    bool useCache = true,
  }) async {
    try {
      // Build query parameters efficiently
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (categoryId != null) {
        queryParams['category_id'] = categoryId;
      } else if (categoryIds != null && categoryIds.isNotEmpty) {
        queryParams['category_id'] = categoryIds.first;
      }

      if (cityId != null) queryParams['city_id'] = cityId;
      if (minPrice != null) queryParams['min_price'] = minPrice;
      if (maxPrice != null) queryParams['max_price'] = maxPrice;
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sort_by'] = sortBy;
      }

      final response = await _apiService.get(
        '/api/public/products',
        queryParams: queryParams,
        useCache: useCache,
      );

      if (response['status'] == 'success') {
        final List<dynamic> productsData = response['data'];
        return productsData.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Ошибка загрузки продуктов: ${response['message'] ?? 'Неизвестная ошибка'}');
      }
    } catch (e) {
      throw Exception('Не удалось загрузить продукты: $e');
    }
  }

  /// Get popular products with caching
  Future<List<Product>> getPopularProducts({int limit = 10}) async {
    return await getProducts(limit: limit, sortBy: 'popularity_desc');
  }

  /// Get latest products with caching
  Future<List<Product>> getLatestProducts({int limit = 10}) async {
    return await getProducts(limit: limit, sortBy: 'date_desc');
  }

  /// Get recommended products with caching
  Future<List<Product>> getRecommendedProducts({int limit = 10}) async {
    return await getProducts(limit: limit, sortBy: 'popularity_desc');
  }

  /// Get products by category with optimized query building
  Future<List<Product>> getProductsByCategory({
    required int categoryId,
    int? cityId,
    double? minPrice,
    double? maxPrice,
    String? search,
    int page = 1,
    int limit = 20,
    String? sortBy,
    Map<String, String>? customFilters,
    bool useCache = true,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'category_id': categoryId,
      };

      if (cityId != null) queryParams['city_id'] = cityId;
      if (minPrice != null) queryParams['min_price'] = minPrice;
      if (maxPrice != null) queryParams['max_price'] = maxPrice;
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sort_by'] = sortBy;
      }

      // Add custom filters
      if (customFilters != null) {
        queryParams.addAll(customFilters);
      }

      final response = await _apiService.get(
        '/api/public/products',
        queryParams: queryParams,
        useCache: useCache,
      );

      if (response['status'] == 'success') {
        final List<dynamic> productsData = response['data'];
        return productsData.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Ошибка загрузки продуктов: ${response['message'] ?? 'Неизвестная ошибка'}');
      }
    } catch (e) {
      throw Exception('Не удалось загрузить продукты: $e');
    }
  }

  /// Get products by multiple categories (batch operation)
  Future<List<Product>> getProductsByCategories({
    required List<int> categoryIds,
    int? cityId,
    double? minPrice,
    double? maxPrice,
    String? search,
    int page = 1,
    int limit = 20,
    String? sortBy,
  }) async {
    if (categoryIds.isEmpty) return [];

    // For now, use the first category as API supports only one category at a time
    // In the future, this could be optimized with batch requests
    return await getProductsByCategory(
      categoryId: categoryIds.first,
      cityId: cityId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      search: search,
      page: page,
      limit: limit,
      sortBy: sortBy,
    );
  }

  /// Get product count by category with caching
  Future<int> getProductsCountByCategory(int categoryId) async {
    try {
      final response = await _apiService.get(
        '/api/public/products/count',
        queryParams: {'category_id': categoryId},
        useCache: true,
      );
      
      if (response['status'] == 'success') {
        return response['data']['count'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  /// Get product by ID with caching
  Future<Product> getProductById(int id, {bool useCache = true}) async {
    try {
      final response = await _apiService.get(
        '/api/public/products/$id',
        useCache: useCache,
      );

      if (response['status'] == 'success') {
        return Product.fromJson(response['data']);
      } else {
        throw Exception('Ошибка загрузки продукта: ${response['message'] ?? 'Неизвестная ошибка'}');
      }
    } catch (e) {
      throw Exception('Не удалось загрузить продукт: $e');
    }
  }

  /// Get raw product data by ID with caching
  Future<Map<String, dynamic>> getProductByIdRaw(int id, {bool useCache = true}) async {
    try {
      final response = await _apiService.get(
        '/api/public/products/$id',
        useCache: useCache,
      );

      if (response['status'] == 'success') {
        return response['data'];
      } else {
        throw Exception('Ошибка загрузки продукта: ${response['message'] ?? 'Неизвестная ошибка'}');
      }
    } catch (e) {
      throw Exception('Не удалось загрузить продукт: $e');
    }
  }

  /// Batch get multiple products by IDs
  Future<List<Product>> getProductsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];

    try {
      // Create batch requests
      final requests = ids.map((id) => () => _apiService.get('/api/public/products/$id')).toList();
      
      final responses = await _apiService.batch(requests);
      
      final products = <Product>[];
      for (final response in responses) {
        try {
          if (response['status'] == 'success') {
            products.add(Product.fromJson(response['data']));
          }
        } catch (e) {
          // Skip invalid products
          continue;
        }
      }
      
      return products;
    } catch (e) {
      throw Exception('Не удалось загрузить продукты: $e');
    }
  }

  /// Create product with optimized multipart upload
  Future<Map<String, dynamic>> createProduct({
    required String categoryId,
    required String cityId,
    required String name,
    required String description,
    required String price,
    required String address,
    File? videoFile,
    bool isVideoCallAvailable = false,
    String? phoneNumber,
    String? whatsappNumber,
    bool readyForVideoDemo = false,
    List<Map<String, dynamic>>? parameters,
  }) async {
    try {
      final fields = <String, String>{
        'category_id': categoryId,
        'city_id': cityId,
        'name': name,
        'description': description,
        'price': price,
        'address': address,
        'is_video_call_available': isVideoCallAvailable.toString(),
        'ready_for_video_demo': readyForVideoDemo.toString(),
      };

      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
        fields['phone_number'] = phoneNumber.trim();
      }
      if (whatsappNumber != null && whatsappNumber.trim().isNotEmpty) {
        fields['whatsapp_number'] = whatsappNumber.trim();
      }

      // Add parameters
      if (parameters != null && parameters.isNotEmpty) {
        for (int i = 0; i < parameters.length; i++) {
          final param = parameters[i];
          fields['parameters[$i][parameter_id]'] = param['parameter_id'].toString();
          fields['parameters[$i][value]'] = param['value'].toString();
        }
      }

      Map<String, File>? files;
      if (videoFile != null) {
        files = {'video': videoFile};
      }

      final response = await _apiService.postMultipart(
        '/api/products',
        fields: fields,
        files: files,
        requiresAuth: true,
      );

      if (response['status'] == 'success') {
        // Clear relevant cache entries after creating a product
        _clearProductCaches();
        return response['data'];
      } else {
        throw Exception('Ошибка создания продукта: ${response['message'] ?? 'Неизвестная ошибка'}');
      }
    } catch (e) {
      throw Exception('Не удалось создать продукт: $e');
    }
  }

  /// Get filters for category with caching
  Future<Map<String, dynamic>> getFiltersForCategory(int categoryId) async {
    try {
      final response = await _apiService.get(
        '/api/public/categories/$categoryId/filters',
        useCache: true,
      );
      
      if (response['status'] == 'success') {
        return response['data'];
      } else {
        throw Exception('Ошибка загрузки фильтров: ${response['message'] ?? 'Неизвестная ошибка'}');
      }
    } catch (e) {
      throw Exception('Не удалось загрузить фильтры: $e');
    }
  }

  /// Get category statistics with caching
  Future<Map<String, dynamic>> getCategoryStatistics() async {
    try {
      final response = await _apiService.get(
        '/api/public/categories/statistics',
        useCache: true,
      );
      
      if (response['status'] == 'success') {
        return response['data'];
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  /// Advanced search with optimized query building
  Future<List<Product>> searchProductsAdvanced({
    String? query,
    List<int>? categoryIds,
    int? cityId,
    double? minPrice,
    double? maxPrice,
    Map<String, dynamic>? filters,
    int page = 1,
    int limit = 20,
    String? sortBy,
    bool useCache = true,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }
      
      if (categoryIds != null && categoryIds.isNotEmpty) {
        queryParams['category_ids'] = categoryIds.join(',');
      }
      
      if (cityId != null) queryParams['city_id'] = cityId;
      if (minPrice != null) queryParams['min_price'] = minPrice;
      if (maxPrice != null) queryParams['max_price'] = maxPrice;
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sort_by'] = sortBy;
      }
      
      // Add additional filters
      if (filters != null) {
        filters.forEach((key, value) {
          if (value != null) {
            queryParams[key] = value.toString();
          }
        });
      }

      final response = await _apiService.get(
        '/api/public/products/search',
        queryParams: queryParams,
        useCache: useCache,
      );

      if (response['status'] == 'success') {
        final List<dynamic> productsData = response['data'];
        return productsData.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Ошибка поиска продуктов: ${response['message'] ?? 'Неизвестная ошибка'}');
      }
    } catch (e) {
      throw Exception('Не удалось найти продукты: $e');
    }
  }

  /// Get products with filters using optimized approach
  Future<List<Product>> getProductsWithFilters({
    required ProductFilters filters,
    int page = 1,
    int limit = 20,
    bool useCache = true,
  }) async {
    int? categoryId;
    if (filters.categoryIds != null && filters.categoryIds!.isNotEmpty) {
      categoryId = filters.categoryIds!.first;
    }
    
    if (categoryId != null) {
      Map<String, String>? stringCustomFilters;
      if (filters.customFilters != null) {
        stringCustomFilters = filters.customFilters!.map(
          (key, value) => MapEntry(key, value.toString()),
        );
      }
      
      return await getProductsByCategory(
        categoryId: categoryId,
        cityId: filters.cityId,
        minPrice: filters.minPrice,
        maxPrice: filters.maxPrice,
        search: filters.search,
        page: page,
        limit: limit,
        sortBy: filters.sortBy,
        customFilters: stringCustomFilters,
        useCache: useCache,
      );
    } else {
      return await getProducts(
        cityId: filters.cityId,
        minPrice: filters.minPrice,
        maxPrice: filters.maxPrice,
        search: filters.search,
        page: page,
        limit: limit,
        sortBy: filters.sortBy,
        useCache: useCache,
      );
    }
  }

  /// Clear product-related caches
  void _clearProductCaches() {
    _apiService.clearCacheEntry('GET', '/api/public/products');
    _apiService.clearCacheEntry('GET', '/api/public/products/search');
    _apiService.clearCacheEntry('GET', '/api/public/categories/statistics');
  }

  /// Clear all product caches
  void clearCache() {
    _apiService.clearCache();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return _apiService.getCacheStats();
  }

  /// Preload popular data for better performance
  Future<void> preloadPopularData() async {
    try {
      // Preload popular products, latest products, and category statistics
      await Future.wait([
        getPopularProducts(limit: 20),
        getLatestProducts(limit: 20),
        getCategoryStatistics(),
      ]);
    } catch (e) {
      // Ignore preload errors
    }
  }

  /// Dispose resources
  void dispose() {
    _apiService.dispose();
  }
}