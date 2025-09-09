import '../models/product.dart';
import '../models/product_filters.dart';
import 'api_service.dart';
import 'dart:io';

/// ProductService for handling product-related API operations
class ProductService {
  final ApiService _apiService = ApiService();

  /// Build query parameters for API requests
  Map<String, String> _buildQueryParams({
    int? categoryId,
    int? cityId,
    double? minPrice,
    double? maxPrice,
    String? search,
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? priceRange,
    bool? hasPhoto,
    String? subcategory,
    String? subSubcategory,
    List<int>? categoryIds,
    Map<String, String>? customFilters,
  }) {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (categoryId != null) {
      queryParams['category_id'] = categoryId.toString();
    } else if (categoryIds != null && categoryIds.isNotEmpty) {
      queryParams['category_id'] = categoryIds.first.toString();
    }

    if (cityId != null) queryParams['city_id'] = cityId.toString();
    if (minPrice != null) queryParams['min_price'] = minPrice.toString();
    if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      queryParams['sort_by'] = sortBy;
    }
    if (priceRange != null && priceRange.isNotEmpty) {
      queryParams['price_range'] = priceRange;
    }
    if (hasPhoto != null) {
      queryParams['has_photo'] = hasPhoto.toString();
    }
    if (subcategory != null && subcategory.isNotEmpty) {
      queryParams['subcategory'] = subcategory;
    }
    if (subSubcategory != null && subSubcategory.isNotEmpty) {
      queryParams['sub_subcategory'] = subSubcategory;
    }

    // Add custom filters
    if (customFilters != null) {
      queryParams.addAll(customFilters);
    }

    return queryParams;
  }

  /// Build URL with query parameters
  String _buildUrlWithParams(String endpoint, Map<String, String> params) {
    if (params.isEmpty) return endpoint;

    final uri = Uri.parse(endpoint);
    final newUri = uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...params,
    });
    return newUri.toString();
  }

  Future<List<Product>> getProducts({
    int? categoryId,
    int? cityId,
    double? minPrice,
    double? maxPrice,
    String? search,
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? priceRange,
    bool? hasPhoto,
    String? subcategory,
    String? subSubcategory,
    List<int>? categoryIds,
  }) async {
    try {
      final queryParams = _buildQueryParams(
        categoryId: categoryId,
        cityId: cityId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        search: search,
        page: page,
        limit: limit,
        sortBy: sortBy,
        priceRange: priceRange,
        hasPhoto: hasPhoto,
        subcategory: subcategory,
        subSubcategory: subSubcategory,
        categoryIds: categoryIds,
      );

      final url = _buildUrlWithParams('/api/public/products', queryParams);
      final response = await _apiService.get(url);

      if (response['status'] == 'success') {
        final List<dynamic> productsData = response['data'];
        return productsData.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception(
            'Ошибка загрузки продуктов: ${response['message'] ?? 'Неизвестная ошибка'}');
      }
    } catch (e) {
      throw Exception('Не удалось загрузить продукты: $e');
    }
  }

  Future<List<Product>> getPopularProducts({int limit = 10}) async {
    return await getProducts(limit: limit, sortBy: 'popularity_desc');
  }

  Future<List<Product>> getLatestProducts({int limit = 10}) async {
    return await getProducts(limit: limit, sortBy: 'date_desc');
  }

  Future<List<Product>> getRecommendedProducts({int limit = 10}) async {
    return await getProducts(limit: limit, sortBy: 'popularity_desc');
  }

  /// Получить продукты по конкретной категории (упрощенный метод)
  Future<List<Product>> getProductsByCategorySimple({
    required int categoryId,
    int? cityId,
    double? minPrice,
    double? maxPrice,
    String? search,
    int page = 1,
    int limit = 20,
    String? sortBy,
    Map<String, String>? customFilters,
    String? priceRange,
    bool? hasPhoto,
    String? subcategory,
    String? subSubcategory,
  }) async {
    return await getProductsByCategory(
      categoryId: categoryId,
      cityId: cityId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      search: search,
      page: page,
      limit: limit,
      sortBy: sortBy,
      priceRange: priceRange,
      hasPhoto: hasPhoto,
      subcategory: subcategory,
      subSubcategory: subSubcategory,
    );
  }

  /// Получить продукты по конкретной категории
  Future<List<Product>> getProductsByCategory({
    required int categoryId,
    int? cityId,
    double? minPrice,
    double? maxPrice,
    String? search,
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? priceRange,
    bool? hasPhoto,
    String? subcategory,
    String? subSubcategory,
  }) async {
    try {
      final queryParams = _buildQueryParams(
        categoryId: categoryId,
        cityId: cityId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        search: search,
        page: page,
        limit: limit,
        sortBy: sortBy,
        priceRange: priceRange,
        hasPhoto: hasPhoto,
        subcategory: subcategory,
        subSubcategory: subSubcategory,
      );

      final url = _buildUrlWithParams('/api/public/products', queryParams);
      final response = await _apiService.get(url);

      if (response['status'] == 'success') {
        final List<dynamic> productsData = response['data'];
        return productsData.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception(
            'Ошибка загрузки продуктов: ${response['message'] ?? 'Неизвестная ошибка'}');
      }
    } catch (e) {
      throw Exception('Не удалось загрузить продукты: $e');
    }
  }

  /// Получить продукты по нескольким категориям
  Future<List<Product>> getProductsByCategories({
    required List<int> categoryIds,
    int? cityId,
    double? minPrice,
    double? maxPrice,
    String? search,
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? priceRange,
    bool? hasPhoto,
    String? subcategory,
    String? subSubcategory,
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
      priceRange: priceRange,
      hasPhoto: hasPhoto,
      subcategory: subcategory,
      subSubcategory: subSubcategory,
    );
  }

  /// Получить количество продуктов в категории
  Future<int> getProductsCountByCategory(int categoryId) async {
    try {
      final queryParams = {'category_id': categoryId.toString()};
      final url =
          _buildUrlWithParams('/api/public/products/count', queryParams);
      final response = await _apiService.get(url);

      if (response['status'] == 'success') {
        return response['data']['count'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  Future<Product> getProductById(int id) async {
    try {
      final response = await _apiService.get('/api/public/products/$id');

      if (response['status'] == 'success') {
        return Product.fromJson(response['data']);
      } else {
        throw Exception(
            'Ошибка загрузки продукта: ${response['message'] ?? 'Неизвестная ошибка'}');
      }
    } catch (e) {
      throw Exception('Не удалось загрузить продукт: $e');
    }
  }

  /// Get raw product data for DetailPage (returns Map<String, dynamic>)
  Future<Map<String, dynamic>> getProductByIdRaw(int id) async {
    try {
      final response = await _apiService.get('/api/public/products/$id');

      if (response['status'] == 'success') {
        return response['data'];
      } else {
        throw Exception(
            'Ошибка загрузки продукта: ${response['message'] ?? 'Неизвестная ошибка'}');
      }
    } catch (e) {
      throw Exception('Не удалось загрузить продукт: $e');
    }
  }

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
    int? publicationPriceId,
  }) async {
    try {
      // Если есть видео, отправляем multipart
      if (videoFile != null) {
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
        if (publicationPriceId != null) {
          fields['publication_price_id'] = publicationPriceId.toString();
        }
        if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
          fields['phone_number'] = phoneNumber.trim();
        }
        if (whatsappNumber != null && whatsappNumber.trim().isNotEmpty) {
          fields['whatsapp_number'] = whatsappNumber.trim();
        }
        if (parameters != null && parameters.isNotEmpty) {
          for (int i = 0; i < parameters.length; i++) {
            final param = parameters[i];
            if (param.containsKey('parameter_id')) {
              fields['parameters[$i][parameter_id]'] =
                  param['parameter_id'].toString();
            }
            if (param.containsKey('value')) {
              fields['parameters[$i][value]'] = param['value'].toString();
            }
          }
        }
        final response = await _apiService.postMultipart(
          '/api/products',
          fields: fields,
          fileField: 'video',
          file: videoFile,
          requiresAuth: true,
        );
        if (response['status'] == 'success') {
          return response['data'];
        } else {
          throw Exception(
              'Ошибка создания продукта: ${response['message'] ?? 'Неизвестная ошибка'}');
        }
      } else {
        // Без видео — обычный JSON
        final body = <String, dynamic>{
          'category_id': categoryId,
          'city_id': cityId,
          'name': name,
          'description': description,
          'price': price,
          'address': address,
          'is_video_call_available': isVideoCallAvailable,
          'ready_for_video_demo': readyForVideoDemo,
        };
        if (publicationPriceId != null) {
          body['publication_price_id'] = publicationPriceId;
        }
        if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
          body['phone_number'] = phoneNumber.trim();
        }
        if (whatsappNumber != null && whatsappNumber.trim().isNotEmpty) {
          body['whatsapp_number'] = whatsappNumber.trim();
        }
        if (parameters != null && parameters.isNotEmpty) {
          body['parameters'] = parameters;
        }
        final response = await _apiService.post(
          '/api/products',
          body: body,
          requiresAuth: true,
        );
        if (response['status'] == 'success') {
          return response['data'];
        } else {
          throw Exception(
              'Ошибка создания продукта: ${response['message'] ?? 'Неизвестная ошибка'}');
        }
      }
    } catch (e) {
      throw Exception('Не удалось создать продукт: $e');
    }
  }

  /// Получить доступные фильтры для категории
  Future<Map<String, dynamic>> getFiltersForCategory(int categoryId) async {
    try {
      final response =
          await _apiService.get('/api/public/categories/$categoryId/filters');

      if (response['status'] == 'success') {
        return response['data'];
      } else {
        throw Exception(
            'Ошибка загрузки фильтров: ${response['message'] ?? 'Неизвестная ошибка'}');
      }
    } catch (e) {
      throw Exception('Не удалось загрузить фильтры: $e');
    }
  }

  /// Получить статистику по категориям
  Future<Map<String, dynamic>> getCategoryStatistics() async {
    try {
      final response =
          await _apiService.get('/api/public/categories/statistics');

      if (response['status'] == 'success') {
        return response['data'];
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  /// Поиск продуктов с продвинутыми фильтрами
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
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }

      if (categoryIds != null && categoryIds.isNotEmpty) {
        queryParams['category_ids'] = categoryIds.join(',');
      }

      if (cityId != null) queryParams['city_id'] = cityId.toString();
      if (minPrice != null) queryParams['min_price'] = minPrice.toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
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

      final url =
          _buildUrlWithParams('/api/public/products/search', queryParams);
      final response = await _apiService.get(url);

      if (response['status'] == 'success') {
        final List<dynamic> productsData = response['data'];
        return productsData.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception(
            'Ошибка поиска продуктов: ${response['message'] ?? 'Неизвестная ошибка'}');
      }
    } catch (e) {
      throw Exception('Не удалось найти продукты: $e');
    }
  }

  /// Получить продукты с использованием объекта фильтров
  Future<List<Product>> getProductsWithFilters({
    required ProductFilters filters,
    int page = 1,
    int limit = 20,
  }) async {
    int? categoryId;
    if (filters.categoryIds != null && filters.categoryIds!.isNotEmpty) {
      categoryId = filters.categoryIds!.first;
    }

    if (categoryId != null) {
      return await getProductsByCategory(
        categoryId: categoryId,
        cityId: filters.cityId,
        minPrice: filters.minPrice,
        maxPrice: filters.maxPrice,
        search: filters.search,
        page: page,
        limit: limit,
        sortBy: filters.sortBy,
        priceRange: filters.priceRange,
        hasPhoto: filters.hasPhoto,
        subcategory: filters.subcategory,
        subSubcategory: filters.subSubcategory,
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
      );
    }
  }

  /// Get user's products
  Future<List<Product>> getUserProducts({int page = 1, int limit = 20}) async {
    try {
      final endpoint = '/api/products?page=$page&limit=$limit';
      final response = await _apiService.get(endpoint, requiresAuth: true);

      if (response['status'] == 'success' && response['data'] != null) {
        final productsData = response['data']['data'] as List;
        return productsData
            .map((product) => Product.fromJson(product))
            .toList();
      } else {
        throw Exception('Failed to load user products: ${response['message']}');
      }
    } catch (e) {
      print('Error loading user products: $e');
      throw Exception('Failed to load user products: $e');
    }
  }

  /// Delete user's product
  Future<bool> deleteProduct(int productId) async {
    try {
      final response = await _apiService.delete('/api/products/$productId',
          requiresAuth: true);

      if (response['status'] == 'success') {
        return true;
      } else {
        throw Exception('Failed to delete product: ${response['message']}');
      }
    } catch (e) {
      print('Error deleting product: $e');
      throw Exception('Failed to delete product: $e');
    }
  }

  /// Update user's product
  Future<bool> updateProduct({
    required int productId,
    int? categoryId,
    int? cityId,
    String? name,
    String? description,
    double? price,
    String? address,
    String? whatsappNumber,
    String? phoneNumber,
    bool? isVideoCallAvailable,
    bool? readyForVideoDemo,
    String? status,
    File? mainPhoto,
    List<File>? photos,
    File? video,
    int? publicationPriceId,
    List<Map<String, dynamic>>? parameters,
    DateTime? expiresAt,
    String? videoUrl,
  }) async {
    try {
      // Используем multipart для поддержки файлов
      final Map<String, String> fields = {};

      // Добавляем только непустые поля
      if (categoryId != null) fields['category_id'] = categoryId.toString();
      if (cityId != null) fields['city_id'] = cityId.toString();
      if (name != null && name.isNotEmpty) fields['name'] = name;
      if (description != null && description.isNotEmpty)
        fields['description'] = description;
      if (price != null) fields['price'] = price.toString();
      if (address != null && address.isNotEmpty) fields['address'] = address;
      if (whatsappNumber != null && whatsappNumber.isNotEmpty)
        fields['whatsapp_number'] = whatsappNumber;
      if (phoneNumber != null && phoneNumber.isNotEmpty)
        fields['phone_number'] = phoneNumber;
      if (isVideoCallAvailable != null)
        fields['is_video_call_available'] = isVideoCallAvailable.toString();
      if (readyForVideoDemo != null)
        fields['ready_for_video_demo'] = readyForVideoDemo.toString();
      if (status != null && status.isNotEmpty) fields['status'] = status;
      if (publicationPriceId != null)
        fields['publication_price_id'] = publicationPriceId.toString();
      if (videoUrl != null && videoUrl.isNotEmpty)
        fields['video_url'] = videoUrl;

      // Дата истечения
      if (expiresAt != null) {
        fields['expires_at'] = expiresAt.toIso8601String();
      }

      // Главное фото - если не предоставлено, генерируем дефолтный текст
      if (mainPhoto == null) {
        fields['main_photo'] =
            'default_photo_${DateTime.now().millisecondsSinceEpoch}';
      }

      // Параметры продукта
      if (parameters != null && parameters.isNotEmpty) {
        for (int i = 0; i < parameters.length; i++) {
          final param = parameters[i];
          if (param.containsKey('parameter_id')) {
            fields['parameters[$i][parameter_id]'] =
                param['parameter_id'].toString();
          }
          if (param.containsKey('value')) {
            fields['parameters[$i][value]'] = param['value'].toString();
          }
        }
      }

      // Подготавливаем файлы
      final Map<String, File> files = {};
      if (mainPhoto != null) {
        files['main_photo'] = mainPhoto;
      }
      if (video != null) {
        files['video'] = video;
      }
      if (photos != null && photos.isNotEmpty) {
        for (int i = 0; i < photos.length; i++) {
          files['photos[$i]'] = photos[i];
        }
      }

      final response = await _apiService.putMultipart(
        '/api/products/$productId',
        data: fields.map((key, value) => MapEntry(key, value)),
        files: files,
        requiresAuth: true,
      );

      if (response['status'] == 'success') {
        return true;
      } else {
        throw Exception('Failed to update product: ${response['message']}');
      }
    } catch (e) {
      print('Error updating product: $e');
      throw Exception('Failed to update product: $e');
    }
  }
}
