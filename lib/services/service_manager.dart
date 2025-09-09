import 'optimized_auth_service.dart';
import 'optimized_product_service.dart';
import 'optimized_category_service.dart';

/// Service Manager to coordinate all optimized services
class ServiceManager {
  static ServiceManager? _instance;
  
  late final OptimizedAuthService _authService;
  late final OptimizedProductService _productService;
  late final OptimizedCategoryService _categoryService;
  
  bool _initialized = false;

  ServiceManager._() {
    _authService = OptimizedAuthService();
    _productService = OptimizedProductService();
    _categoryService = OptimizedCategoryService();
  }

  factory ServiceManager() {
    return _instance ??= ServiceManager._();
  }

  /// Initialize all services
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Preload essential data in parallel
      await Future.wait([
        _categoryService.preloadCategoryData(),
        _productService.preloadPopularData(),
      ], eagerError: false); // Don't fail if one preload fails

      _initialized = true;
    } catch (e) {
      // Log error but don't fail initialization
      print('ServiceManager: Preload warning: $e');
      _initialized = true;
    }
  }

  /// Get auth service
  OptimizedAuthService get auth => _authService;

  /// Get product service
  OptimizedProductService get products => _productService;

  /// Get category service
  OptimizedCategoryService get categories => _categoryService;

  /// Check if services are initialized
  bool get isInitialized => _initialized;

  /// Get overall cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'auth': _authService.getCacheStats(),
      'products': _productService.getCacheStats(),
      'categories': _categoryService.getCacheStats(),
      'initialized': _initialized,
    };
  }

  /// Clear all caches
  void clearAllCaches() {
    _authService.clearCache();
    _productService.clearCache();
    _categoryService.clearCache();
  }

  /// Refresh all cached data
  Future<void> refreshAllData() async {
    await Future.wait([
      _categoryService.refreshCategories(),
      _productService.preloadPopularData(),
    ], eagerError: false);
  }

  /// Dispose all services
  void dispose() {
    _authService.dispose();
    _productService.dispose();
    _categoryService.dispose();
    _initialized = false;
  }

  /// Reset service manager (for testing or logout)
  void reset() {
    dispose();
    _instance = null;
  }
}

/// Global service manager instance
final serviceManager = ServiceManager();