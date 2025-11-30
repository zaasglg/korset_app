import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class AuthService {
  /// Сброс пароля по номеру телефона
  static Future<Map<String, dynamic>> resetPassword(String phoneNumber) async {
    try {
      print('AuthService: Отправляем запрос на сброс пароля для номера: $phoneNumber');
      
      final response = await _apiService.post(
        '/api/reset-password',
        body: {'phone_number': phoneNumber},
      );
      
      print('AuthService: Ответ сервера на сброс пароля: $response');
      
      // Если ответ null или пустой, считаем что запрос прошел успешно
      if (response == null) {
        return {
          'success': true,
          'message': 'Новый пароль отправлен на ваш номер телефона'
        };
      }
      
      // Возвращаем ответ как есть
      return response;
    } catch (e) {
      print('AuthService: Ошибка сброса пароля: $e');
      
      // Если это ApiException, проверяем статус код
      if (e is ApiException) {
        print('AuthService: ApiException - statusCode: ${e.statusCode}, message: ${e.message}');
        
        // Для некоторых статус кодов возвращаем успешный результат
        if (e.statusCode == 200 || e.statusCode == 201) {
          return {
            'success': true,
            'message': 'Новый пароль отправлен на ваш номер телефона'
          };
        }
      }
      
      rethrow;
    }
  }
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  static final ApiService _apiService = ApiService();

  /// Исправляет URL аватара, добавляя базовый URL с /storage/ если нужно
  static void _fixAvatarUrl(Map<String, dynamic> userData) {
    if (userData['avatar'] != null &&
        userData['avatar'].toString().isNotEmpty &&
        userData['avatar'] != 'null') {
      String avatarUrl = userData['avatar'].toString();
      print('AuthService: Исходный avatar URL: $avatarUrl');

      if (!avatarUrl.startsWith('http')) {
        // Добавляем базовый URL с /storage/
        avatarUrl = avatarUrl.startsWith('/')
            ? 'https://videopokaz.kz/storage$avatarUrl'
            : 'https://videopokaz.kz/storage/$avatarUrl';
        userData['avatar'] = avatarUrl;
        print('AuthService: avatar URL исправлен на: $avatarUrl');
      } else {
        print('AuthService: avatar URL уже полный: $avatarUrl');
      }
    } else {
      print('AuthService: avatar пустой или null');
    }
  }

  /// Принудительно обновить user из API и сохранить в SharedPreferences
  static Future<void> refreshUserFromApi() async {
    try {
      print('AuthService: Начинаем refreshUserFromApi...');
      final token = await getToken();
      if (token == null) {
        print('AuthService: no token found for refresh');
        return;
      }

      final response = await _apiService.get('/api/user', requiresAuth: true);
      print('AuthService: Получен ответ от /api/user: $response');

      if (response != null) {
        Map<String, dynamic>? userData;

        // Проверяем формат ответа - сначала прямой формат
        if (response is Map<String, dynamic> &&
            response.containsKey('id') &&
            response.containsKey('name')) {
          print('AuthService: Используем прямой формат ответа');
          userData = Map<String, dynamic>.from(response);
        }
        // Затем обёрнутый формат
        else if (response is Map<String, dynamic> &&
            response.containsKey('user')) {
          print('AuthService: Используем обёрнутый формат ответа');
          userData = Map<String, dynamic>.from(response['user']);
        }

        if (userData != null) {
          print(
              'AuthService: Данные пользователя получены: ID=${userData['id']}, name=${userData['name']}');
          print('AuthService: Исходный avatar: ${userData['avatar']}');

          // Исправляем URL аватара
          _fixAvatarUrl(userData);

          // Сохраняем обновленные данные
          await saveUser(userData);
          print(
              'AuthService: Данные пользователя успешно обновлены и сохранены');
        } else {
          print(
              'AuthService: user refresh failed, no valid user data in response');
        }
      } else {
        print('AuthService: user refresh failed, response is null');
      }
    } catch (e) {
      print('AuthService: Error in refreshUserFromApi: $e');
    }
  }

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
    // Store as JSON to preserve correct types and special characters (e.g., URLs)
    await prefs.setString(_userKey, jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr != null) {
      // 1) Try JSON first (new format)
      try {
        final decoded = jsonDecode(userStr);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {
        // Not JSON, fall back to legacy parsing
      }

      // 2) Legacy format: Map.toString() like {key: value, key2: value2}
      // We'll parse by splitting pairs on ", " and keys/values on first ":" only
      try {
        final trimmed = userStr.trim();
        final noBraces = trimmed.startsWith('{') && trimmed.endsWith('}')
            ? trimmed.substring(1, trimmed.length - 1)
            : trimmed;
        if (noBraces.isEmpty) return {};

        final Map<String, dynamic> result = {};
        // Split on comma+space to separate pairs; this avoids splitting inside URLs
        final pairs = noBraces.split(', ');
        for (final p in pairs) {
          final idx = p.indexOf(':');
          if (idx <= 0) continue;
          final key = p.substring(0, idx).trim().replaceAll('"', '');
          final value = p.substring(idx + 1).trim();
          // Remove wrapping quotes if any
          final normalized = value.replaceAll(RegExp(r'^"|"$'), '');
          result[key] = normalized;
        }
        return result;
      } catch (e) {
        // If parsing fails, return null
        return null;
      }
    }
    return null;
  }

  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Форсированная проверка аутентификации (для обновления UI)
  static Future<bool> checkAuthenticationStatus() async {
    await Future.delayed(Duration(
        milliseconds: 50)); // Небольшая задержка для завершения сохранения
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// First step of registration - send user data and get verification code
  ///
  /// Проверяет, зарегистрирован ли номер телефона
  /// Возвращает true если номер доступен для регистрации
  /// Возвращает false если номер уже зарегистрирован
  /// Выбрасывает ApiException в случае ошибки
  static Future<bool> checkPhoneNumber(String phoneNumber) async {
    try {
      print('AuthService: Проверяем номер телефона: $phoneNumber');

      final response = await _apiService.post(
        '/api/check-phone-number',
        body: {
          'phone_number': phoneNumber,
        },
      );

      print('AuthService: Ответ проверки номера: $response');

      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data != null) {
          final isRegistered = data['is_registered'];
          final message = data['message'] ?? '';

          print('AuthService: is_registered = $isRegistered');
          print('AuthService: message = $message');

          // Если номер уже зарегистрирован, выбрасываем исключение с сообщением
          if (isRegistered == true ||
              isRegistered == 'true' ||
              isRegistered == '1' ||
              isRegistered == 1) {
            throw ApiException(
              statusCode: 422,
              message: message.isNotEmpty
                  ? message
                  : 'Номер телефона уже зарегистрирован',
            );
          }

          // Номер доступен для регистрации
          return true;
        }
      }

      // Если нет данных или success не true, считаем что номер доступен
      return true;
    } catch (e) {
      print('AuthService: Ошибка проверки номера: $e');
      rethrow;
    }
  }

  /// Returns true if the code was sent successfully
  /// Throws an ApiException if registration fails
  static Future<bool> registerStep1({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
    required String passwordConfirmation,
    String? referralCode,
  }) async {
    try {
      final body = {
        'name': name,
        'email': email,
        'phone_number': phoneNumber,
        'password': password,
        'password_confirmation': passwordConfirmation,
      };

      if (referralCode != null && referralCode.isNotEmpty) {
        body['referral_code'] = referralCode;
      }

      final response = await _apiService.post(
        ApiConfig.register,
        body: body,
      );

      return response != null;
    } catch (e) {
      print('Registration step 1 error: $e');

      // Улучшенная обработка ошибок
      if (e is ApiException) {
        if (e.statusCode == 422) {
          // Парсим сообщение об ошибке для более понятного отображения
          String errorMessage = e.message;

          if (errorMessage.contains('sms_error') ||
              errorMessage.contains("can't to deliver")) {
            throw ApiException(
              statusCode: 422,
              message:
                  'Не удалось отправить SMS на указанный номер. Проверьте правильность номера телефона.',
            );
          } else if (errorMessage.contains('phone_number')) {
            throw ApiException(
              statusCode: 422,
              message: 'Этот номер телефона уже зарегистрирован в системе.',
            );
          } else if (errorMessage.contains('email')) {
            throw ApiException(
              statusCode: 422,
              message: 'Этот email уже используется другим пользователем.',
            );
          } else {
            throw ApiException(
              statusCode: 422,
              message:
                  'Ошибка валидации данных. Проверьте правильность введенной информации.',
            );
          }
        }
      }

      rethrow;
    }
  }

  /// Second step of registration - verify code and complete registration
  ///
  /// Returns a map containing the user data and token if successful
  /// Throws an ApiException if verification fails
  static Future<Map<String, dynamic>> verifyAndRegister({
    required String phoneNumber,
    required String code,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/verify-and-register',
        body: {
          'phone_number': phoneNumber,
          'code': code,
        },
      );

      if (response != null && response['token'] != null) {
        // Save the token and user data
        final token = response['token'];
        final userData = response['user'] ?? {};

        _fixAvatarUrl(userData);
        await saveToken(token);
        await saveUser(userData);

        return {
          'token': token,
          'user': userData,
        };
      } else {
        throw ApiException(
          statusCode: 400,
          message: 'Invalid verification code',
        );
      }
    } catch (e) {
      print('Verification error: $e');
      rethrow;
    }
  }

  /// Legacy register method for backward compatibility
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

        _fixAvatarUrl(userData);
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
      print('AuthService: Попытка входа для номера: $phoneNumber');
      
      final response = await _apiService.post(
        '/api/login',
        body: {
          'phone_number': phoneNumber,
          'password': password,
        },
      );
      
      print('AuthService: Ответ сервера на вход: $response');

      if (response != null && response['token'] != null) {
        // Save the token and user data
        final token = response['token'];
        final userData = response['user'] ?? {};

        _fixAvatarUrl(userData);
        await saveToken(token);
        await saveUser(userData);

        print('AuthService: Успешный вход, токен сохранен');

        return {
          'token': token,
          'user': userData,
        };
      } else {
        print('AuthService: Неверные данные для входа');
        throw ApiException(
          statusCode: 401,
          message: 'Неверный номер телефона или пароль',
        );
      }
    } catch (e) {
      print('AuthService: Ошибка входа: $e');
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

  /// Delete user account
  ///
  /// Returns true if account was deleted successfully
  /// Throws an ApiException if deletion fails
  static Future<bool> deleteAccount(String password) async {
    try {
      final response = await _apiService.delete(
        '/api/delete-account',
        body: {
          'password': password,
        },
        requiresAuth: true,
      );

      if (response != null && response['success'] == true) {
        // Clear local data after successful deletion
        await logout();
        return true;
      }

      return false;
    } catch (e) {
      print('Delete account error: $e');
      rethrow;
    }
  }
}
