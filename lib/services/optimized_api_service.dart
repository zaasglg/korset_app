import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

/// Optimized API Service with caching, connection pooling, and retry logic
class OptimizedApiService {
  static OptimizedApiService? _instance;
  static final Map<String, OptimizedApiService> _instances = {};
  
  final http.Client _client;
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, Future<dynamic>> _pendingRequests = {};
  final Duration _cacheTimeout;
  final int _maxRetries;
  final Duration _retryDelay;
  
  // Private constructor
  OptimizedApiService._({
    http.Client? client,
    Duration? cacheTimeout,
    int? maxRetries,
    Duration? retryDelay,
  }) : _client = client ?? _createOptimizedClient(),
       _cacheTimeout = cacheTimeout ?? const Duration(minutes: 5),
       _maxRetries = maxRetries ?? 3,
       _retryDelay = retryDelay ?? const Duration(seconds: 1);

  /// Factory constructor for singleton pattern
  factory OptimizedApiService({
    String? instanceKey,
    http.Client? client,
    Duration? cacheTimeout,
    int? maxRetries,
    Duration? retryDelay,
  }) {
    if (instanceKey != null) {
      return _instances.putIfAbsent(
        instanceKey,
        () => OptimizedApiService._(
          client: client,
          cacheTimeout: cacheTimeout,
          maxRetries: maxRetries,
          retryDelay: retryDelay,
        ),
      );
    }
    
    return _instance ??= OptimizedApiService._(
      client: client,
      cacheTimeout: cacheTimeout,
      maxRetries: maxRetries,
      retryDelay: retryDelay,
    );
  }

  /// Create an optimized HTTP client with connection pooling
  static http.Client _createOptimizedClient() {
    final httpClient = HttpClient();
    httpClient.maxConnectionsPerHost = 10;
    httpClient.connectionTimeout = const Duration(seconds: 10);
    httpClient.idleTimeout = const Duration(seconds: 30);
    return IOClient(httpClient);
  }

  /// Get headers with authentication and compression support
  Future<Map<String, String>> _getHeaders({
    bool requiresAuth = false,
    bool acceptCompression = true,
  }) async {
    Map<String, String> headers = {...ApiConfig.headers};

    if (acceptCompression) {
      headers['Accept-Encoding'] = 'gzip, deflate';
    }

    if (requiresAuth) {
      final token = await AuthService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Generate cache key for request
  String _getCacheKey(String method, String endpoint, Map<String, dynamic>? params) {
    final key = '$method:$endpoint';
    if (params != null && params.isNotEmpty) {
      final sortedParams = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
      );
      return '$key:${json.encode(sortedParams)}';
    }
    return key;
  }

  /// Check if cached data is still valid
  bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheTimeout;
  }

  /// Get data from cache
  T? _getFromCache<T>(String cacheKey) {
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as T?;
    }
    
    // Clean up expired cache
    _cache.remove(cacheKey);
    _cacheTimestamps.remove(cacheKey);
    return null;
  }

  /// Store data in cache
  void _storeInCache(String cacheKey, dynamic data) {
    _cache[cacheKey] = data;
    _cacheTimestamps[cacheKey] = DateTime.now();
    
    // Limit cache size to prevent memory issues
    if (_cache.length > 100) {
      _cleanupOldCache();
    }
  }

  /// Clean up old cache entries
  void _cleanupOldCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > _cacheTimeout) {
        keysToRemove.add(key);
      }
    });
    
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Execute HTTP request with retry logic
  Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() request,
  ) async {
    int attempts = 0;
    
    while (attempts < _maxRetries) {
      try {
        final response = await request();
        
        // If successful or client error (4xx), don't retry
        if (response.statusCode < 500) {
          return response;
        }
        
        attempts++;
        if (attempts < _maxRetries) {
          await Future.delayed(_retryDelay * attempts);
        }
      } catch (e) {
        attempts++;
        if (attempts >= _maxRetries) {
          rethrow;
        }
        await Future.delayed(_retryDelay * attempts);
      }
    }
    
    throw ApiException(
      statusCode: 500,
      message: 'Max retry attempts exceeded',
    );
  }

  /// GET request with caching and deduplication
  Future<dynamic> get(
    String endpoint, {
    bool requiresAuth = false,
    bool useCache = true,
    Duration? customTimeout,
    Map<String, dynamic>? queryParams,
  }) async {
    final cacheKey = _getCacheKey('GET', endpoint, queryParams);
    
    // Check cache first
    if (useCache) {
      final cachedData = _getFromCache(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
    }
    
    // Check for pending request (deduplication)
    if (_pendingRequests.containsKey(cacheKey)) {
      return await _pendingRequests[cacheKey]!;
    }
    
    // Create new request
    final requestFuture = _performGet(
      endpoint,
      requiresAuth: requiresAuth,
      customTimeout: customTimeout,
      queryParams: queryParams,
    );
    
    _pendingRequests[cacheKey] = requestFuture;
    
    try {
      final result = await requestFuture;
      
      // Cache successful results
      if (useCache && result != null) {
        _storeInCache(cacheKey, result);
      }
      
      return result;
    } finally {
      _pendingRequests.remove(cacheKey);
    }
  }

  /// Perform actual GET request
  Future<dynamic> _performGet(
    String endpoint, {
    bool requiresAuth = false,
    Duration? customTimeout,
    Map<String, dynamic>? queryParams,
  }) async {
    String url = '${ApiConfig.baseUrl}$endpoint';
    
    // Add query parameters
    if (queryParams != null && queryParams.isNotEmpty) {
      final uri = Uri.parse(url);
      final newUri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          ...queryParams.map((key, value) => MapEntry(key, value.toString())),
        },
      );
      url = newUri.toString();
    }
    
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    
    return await _executeWithRetry(() async {
      final response = await _client
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(customTimeout ?? const Duration(seconds: ApiConfig.timeoutDuration));
      
      return _handleResponse(response);
    });
  }

  /// POST request
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    Duration? customTimeout,
  }) async {
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    
    return await _executeWithRetry(() async {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: headers,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(customTimeout ?? const Duration(seconds: ApiConfig.timeoutDuration));
      
      return _handleResponse(response);
    });
  }

  /// PUT request
  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    Duration? customTimeout,
  }) async {
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    
    return await _executeWithRetry(() async {
      final response = await _client
          .put(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: headers,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(customTimeout ?? const Duration(seconds: ApiConfig.timeoutDuration));
      
      return _handleResponse(response);
    });
  }

  /// DELETE request
  Future<dynamic> delete(
    String endpoint, {
    bool requiresAuth = false,
    Duration? customTimeout,
  }) async {
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    
    return await _executeWithRetry(() async {
      final response = await _client
          .delete(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: headers,
          )
          .timeout(customTimeout ?? const Duration(seconds: ApiConfig.timeoutDuration));
      
      return _handleResponse(response);
    });
  }

  /// Multipart POST request
  Future<dynamic> postMultipart(
    String endpoint, {
    Map<String, String>? fields,
    Map<String, File>? files,
    bool requiresAuth = false,
    Duration? customTimeout,
  }) async {
    return await _executeWithRetry(() async {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
      );

      // Add headers (excluding Content-Type for multipart)
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      // Add fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Add files
      if (files != null) {
        for (final entry in files.entries) {
          final file = entry.value;
          final fieldName = entry.key;
          
          final multipartFile = await http.MultipartFile.fromPath(
            fieldName,
            file.path,
          );
          request.files.add(multipartFile);
        }
      }

      final streamedResponse = await request.send()
          .timeout(customTimeout ?? const Duration(seconds: ApiConfig.timeoutDuration));
      
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    });
  }

  /// Batch multiple requests
  Future<List<dynamic>> batch(List<Future<dynamic> Function()> requests) async {
    final futures = requests.map((request) => request()).toList();
    return await Future.wait(futures);
  }

  /// Handle HTTP response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      
      try {
        return json.decode(response.body);
      } catch (e) {
        // If JSON parsing fails, return raw body
        return response.body;
      }
    } else {
      String errorMessage = response.body;
      
      // Try to extract error message from JSON response
      try {
        final errorJson = json.decode(response.body);
        if (errorJson is Map && errorJson.containsKey('message')) {
          errorMessage = errorJson['message'];
        }
      } catch (e) {
        // Use raw body as error message
      }
      
      throw ApiException(
        statusCode: response.statusCode,
        message: errorMessage,
      );
    }
  }

  /// Clear all cache
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Clear specific cache entry
  void clearCacheEntry(String method, String endpoint, [Map<String, dynamic>? params]) {
    final cacheKey = _getCacheKey(method, endpoint, params);
    _cache.remove(cacheKey);
    _cacheTimestamps.remove(cacheKey);
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'totalEntries': _cache.length,
      'validEntries': _cache.keys.where((key) => _isCacheValid(key)).length,
      'expiredEntries': _cache.keys.where((key) => !_isCacheValid(key)).length,
      'pendingRequests': _pendingRequests.length,
    };
  }

  /// Dispose resources
  void dispose() {
    _client.close();
    _cache.clear();
    _cacheTimestamps.clear();
    _pendingRequests.clear();
  }
}

/// Enhanced API Exception with more details
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? details;
  final DateTime timestamp;

  ApiException({
    required this.statusCode,
    required this.message,
    this.details,
  }) : timestamp = DateTime.now();

  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500;
  bool get isNetworkError => statusCode == 0;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'ApiException: [$statusCode] $message';

  Map<String, dynamic> toJson() => {
    'statusCode': statusCode,
    'message': message,
    'details': details,
    'timestamp': timestamp.toIso8601String(),
  };
}