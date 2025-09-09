import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'optimized_api_service.dart';

/// Optimized Auth Service with better token management and caching
class OptimizedAuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _refreshTokenKey = 'refresh_token';

  static OptimizedAuthService? _instance;
  final OptimizedApiService _apiService;

  OptimizedAuthService._() 
      : _apiService = OptimizedApiService(instanceKey: 'auth');

  factory OptimizedAuthService() {
    return _instance ??= OptimizedAuthService._();
  }

  /// Save token with expiry information
  static Future<void> saveToken(String token, {DateTime? expiresAt}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    
    if (expiresAt != null) {
      await prefs.setString(_tokenExpiryKey, expiresAt.toIso8601String());
    }
  }

  /// Get token if it's still valid
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    
    if (token == null) return null;
    
    // Check if token is expired
    final expiryString = prefs.getString(_tokenExpiryKey);
    if (expiryString != null) {
      final expiry = DateTime.parse(expiryString);
      if (DateTime.now().isAfter(expiry)) {
        // Token is expired, try to refresh
        final refreshed = await _refreshTokenIfNeeded();
        if (refreshed) {
          return prefs.getString(_tokenKey);
        } else {
          await logout();
          return null;
        }
      }
    }
    
    return token;
  }

  /// Save refresh token
  static Future<void> saveRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// Save user data with JSON encoding
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user));
  }

  /// Get user data with JSON decoding
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    
    if (userStr != null) {
      try {
        return Map<String, dynamic>.from(json.decode(userStr));
      } catch (e) {
        // If JSON parsing fails, remove corrupted data
        await prefs.remove(_userKey);
        return null;
      }
    }
    
    return null;
  }

  /// Check if user is authenticated with token validation
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Logout and clear all stored data
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_tokenKey),
      prefs.remove(_userKey),
      prefs.remove(_tokenExpiryKey),
      prefs.remove(_refreshTokenKey),
    ]);
    
    // Clear API cache
    _instance?._apiService.clearCache();
  }

  /// Register a new user with enhanced error handling
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final instance = OptimizedAuthService();
      final response = await instance._apiService.post(
        ApiConfig.register,
        body: {
          'name': name,
          'email': email,
          'phone_number': phoneNumber,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      if (response != null) {
        final token = response['token'] ?? response['access_token'];
        final refreshToken = response['refresh_token'];
        final userData = response['user'] ?? {};
        final expiresIn = response['expires_in']; // seconds

        if (token != null) {
          // Calculate expiry time
          DateTime? expiresAt;
          if (expiresIn != null) {
            expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
          }

          // Save tokens and user data
          await Future.wait([
            saveToken(token, expiresAt: expiresAt),
            saveUser(userData),
            if (refreshToken != null) saveRefreshToken(refreshToken),
          ]);

          return {
            'token': token,
            'user': userData,
            'refresh_token': refreshToken,
            'expires_at': expiresAt?.toIso8601String(),
          };
        }
      }

      throw ApiException(
        statusCode: 400,
        message: 'Invalid response from server',
      );
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 500,
        message: 'Registration failed: $e',
      );
    }
  }

  /// Login with enhanced token management
  static Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final instance = OptimizedAuthService();
      final response = await instance._apiService.post(
        '/api/login',
        body: {
          'phone_number': phoneNumber,
          'password': password,
        },
      );

      if (response != null) {
        final token = response['token'] ?? response['access_token'];
        final refreshToken = response['refresh_token'];
        final userData = response['user'] ?? {};
        final expiresIn = response['expires_in']; // seconds

        if (token != null) {
          // Calculate expiry time
          DateTime? expiresAt;
          if (expiresIn != null) {
            expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
          }

          // Save tokens and user data
          await Future.wait([
            saveToken(token, expiresAt: expiresAt),
            saveUser(userData),
            if (refreshToken != null) saveRefreshToken(refreshToken),
          ]);

          return {
            'token': token,
            'user': userData,
            'refresh_token': refreshToken,
            'expires_at': expiresAt?.toIso8601String(),
          };
        }
      }

      throw ApiException(
        statusCode: 401,
        message: 'Invalid credentials',
      );
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 500,
        message: 'Login failed: $e',
      );
    }
  }

  /// Refresh token if needed
  static Future<bool> _refreshTokenIfNeeded() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final instance = OptimizedAuthService();
      final response = await instance._apiService.post(
        '/api/refresh',
        body: {
          'refresh_token': refreshToken,
        },
      );

      if (response != null) {
        final newToken = response['token'] ?? response['access_token'];
        final newRefreshToken = response['refresh_token'];
        final expiresIn = response['expires_in'];

        if (newToken != null) {
          DateTime? expiresAt;
          if (expiresIn != null) {
            expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
          }

          await Future.wait([
            saveToken(newToken, expiresAt: expiresAt),
            if (newRefreshToken != null) saveRefreshToken(newRefreshToken),
          ]);

          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Manually refresh token
  static Future<bool> refreshToken() async {
    return await _refreshTokenIfNeeded();
  }

  /// Change password with enhanced validation
  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String passwordConfirmation,
  }) async {
    try {
      final instance = OptimizedAuthService();
      final response = await instance._apiService.post(
        '/api/change-password',
        body: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': passwordConfirmation,
        },
        requiresAuth: true,
      );

      return response != null && 
             (response['success'] == true || response['status'] == 'success');
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 500,
        message: 'Password change failed: $e',
      );
    }
  }

  /// Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phoneNumber,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final body = <String, dynamic>{};
      
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (phoneNumber != null) body['phone_number'] = phoneNumber;
      if (additionalData != null) body.addAll(additionalData);

      final instance = OptimizedAuthService();
      final response = await instance._apiService.put(
        '/api/profile',
        body: body,
        requiresAuth: true,
      );

      if (response != null && response['user'] != null) {
        // Update stored user data
        await saveUser(response['user']);
        return response['user'];
      }

      throw ApiException(
        statusCode: 400,
        message: 'Profile update failed',
      );
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        statusCode: 500,
        message: 'Profile update failed: $e',
      );
    }
  }

  /// Get current user profile from server
  static Future<Map<String, dynamic>?> getCurrentUser({bool useCache = true}) async {
    try {
      final instance = OptimizedAuthService();
      final response = await instance._apiService.get(
        '/api/user',
        requiresAuth: true,
        useCache: useCache,
      );

      if (response != null && response['user'] != null) {
        // Update stored user data
        await saveUser(response['user']);
        return response['user'];
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Verify email
  static Future<bool> verifyEmail(String verificationCode) async {
    try {
      final instance = OptimizedAuthService();
      final response = await instance._apiService.post(
        '/api/verify-email',
        body: {
          'verification_code': verificationCode,
        },
        requiresAuth: true,
      );

      return response != null && 
             (response['success'] == true || response['status'] == 'success');
    } catch (e) {
      return false;
    }
  }

  /// Request password reset
  static Future<bool> requestPasswordReset(String email) async {
    try {
      final instance = OptimizedAuthService();
      final response = await instance._apiService.post(
        '/api/password/reset',
        body: {
          'email': email,
        },
      );

      return response != null && 
             (response['success'] == true || response['status'] == 'success');
    } catch (e) {
      return false;
    }
  }

  /// Reset password with token
  static Future<bool> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final instance = OptimizedAuthService();
      final response = await instance._apiService.post(
        '/api/password/reset/confirm',
        body: {
          'token': token,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      return response != null && 
             (response['success'] == true || response['status'] == 'success');
    } catch (e) {
      return false;
    }
  }

  /// Check token validity
  static Future<bool> isTokenValid() async {
    try {
      final instance = OptimizedAuthService();
      final response = await instance._apiService.get(
        '/api/user',
        requiresAuth: true,
        useCache: false,
      );

      return response != null;
    } catch (e) {
      if (e is ApiException && e.isUnauthorized) {
        await logout();
      }
      return false;
    }
  }

  /// Get authentication status with detailed information
  static Future<Map<String, dynamic>> getAuthStatus() async {
    final token = await getToken();
    final user = await getUser();
    final isValid = token != null ? await isTokenValid() : false;

    return {
      'isAuthenticated': isValid,
      'hasToken': token != null,
      'hasUser': user != null,
      'user': user,
      'tokenValid': isValid,
    };
  }

  /// Clear cache
  void clearCache() {
    _apiService.clearCache();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return _apiService.getCacheStats();
  }

  /// Dispose resources
  void dispose() {
    _apiService.dispose();
  }
}