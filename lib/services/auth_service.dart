import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  static final ApiService _apiService = ApiService();

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, user.toString());
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr != null) {
      // Convert string representation of map back to Map
      return Map<String, dynamic>.from(
        Map.fromEntries(
          userStr.replaceAll('{', '').replaceAll('}', '').split(',').map((e) {
            final parts = e.split(':');
            return MapEntry(
              parts[0].trim().replaceAll('"', ''),
              parts[1].trim().replaceAll('"', ''),
            );
          }),
        ),
      );
    }
    return null;
  }

  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Register a new user with the API
  ///
  /// Returns a map containing the user data and token if successful
  /// Throws an ApiException if registration fails
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.register,
        body: {
          'name': name,
          'email': email,
          'phone_number': phoneNumber,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      if (response != null && response['token'] != null) {
        // Save the token and user data
        final token = response['token'];
        final userData = response['user'] ?? {};

        await saveToken(token);
        await saveUser(userData);

        return {
          'token': token,
          'user': userData,
        };
      } else {
        throw ApiException(
          statusCode: 400,
          message: 'Invalid response from server',
        );
      }
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  /// Login a user with phone number and password
  ///
  /// Returns a map containing the user data and token if successful
  /// Throws an ApiException if login fails
  static Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/login',
        body: {
          'phone_number': phoneNumber,
          'password': password,
        },
      );

      if (response != null && response['token'] != null) {
        // Save the token and user data
        final token = response['token'];
        final userData = response['user'] ?? {};

        await saveToken(token);
        await saveUser(userData);

        return {
          'token': token,
          'user': userData,
        };
      } else {
        throw ApiException(
          statusCode: 400,
          message: 'Invalid credentials',
        );
      }
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  /// Change user password
  ///
  /// Returns true if password was changed successfully
  /// Throws an ApiException if change fails
  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/change-password',
        body: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': passwordConfirmation,
        },
      );

      return response != null && response['success'] == true;
    } catch (e) {
      print('Change password error: $e');
      rethrow;
    }
  }
}
