import 'dart:convert';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class ApiService {
  /// Multipart POST (file upload)
  Future<dynamic> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
    required String fileField,
    required File file,
    bool requiresAuth = false,
    String? filename,
    String? contentType,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', uri);
    final headers = await _getHeaders(requiresAuth: requiresAuth);
    request.headers.addAll(headers);
    request.fields.addAll(fields);
    final multipartFile = await http.MultipartFile.fromPath(
      fileField,
      file.path,
      filename: filename,
      contentType: contentType != null ? MediaType.parse(contentType) : null,
    );
    request.files.add(multipartFile);
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders({bool requiresAuth = false}) async {
    Map<String, String> headers = {...ApiConfig.headers};

    if (requiresAuth) {
      final token = await AuthService.getToken();
      print('ApiService: Token from AuthService: $token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        print('ApiService: Added Authorization header');
      } else {
        print('ApiService: No token available');
      }
    }

    print('ApiService: Final headers: $headers');
    return headers;
  }

  Future<dynamic> get(String endpoint, {bool requiresAuth = false}) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: headers,
          )
          .timeout(const Duration(seconds: ApiConfig.timeoutDuration));

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> post(String endpoint,
      {Map<String, dynamic>? body, bool requiresAuth = false}) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: headers,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(const Duration(seconds: ApiConfig.timeoutDuration));

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> put(String endpoint,
      {Map<String, dynamic>? body, bool requiresAuth = false}) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client
          .put(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: headers,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(const Duration(seconds: ApiConfig.timeoutDuration));

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> delete(String endpoint,
      {Map<String, dynamic>? body, bool requiresAuth = false}) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client
          .delete(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: ApiConfig.timeoutDuration));

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Multipart PUT (file upload with update)
  Future<dynamic> putMultipart(
    String endpoint, {
    required Map<String, dynamic> data,
    required Map<String, File> files,
    bool requiresAuth = false,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final request = http.MultipartRequest('PUT', uri);
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      request.headers.addAll(headers);

      // Добавляем текстовые поля
      data.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Добавляем файлы
      for (final entry in files.entries) {
        final multipartFile = await http.MultipartFile.fromPath(
          entry.key,
          entry.value.path,
          contentType: _getContentType(entry.value.path),
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  MediaType? _getContentType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'mp4':
        return MediaType('video', 'mp4');
      case 'mov':
        return MediaType('video', 'quicktime');
      default:
        return null;
    }
  }

  dynamic _handleResponse(http.Response response) {
    print('ApiService: Response status: ${response.statusCode}');
    print('ApiService: Response body: ${response.body}');

    // Если ответ пустой, возвращаем null
    if (response.body.isEmpty) return null;

    // Пытаемся распарсить JSON для всех ответов
    try {
      final jsonResponse = json.decode(response.body);

      // Если статус 200-299, возвращаем как есть
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonResponse;
      }

      // Для кодов 400-499 (клиентские ошибки) с валидным JSON,
      // возвращаем JSON ответ, не выбрасывая исключение
      if (response.statusCode >= 400 && response.statusCode < 500) {
        // Если это JSON с информацией об ошибке, возвращаем его
        if (jsonResponse is Map<String, dynamic>) {
          return jsonResponse;
        }
      }

      // Для остальных ошибок выбрасываем исключение
      throw ApiException(
        statusCode: response.statusCode,
        message: response.body,
      );
    } catch (e) {
      // Если не удалось распарсить JSON
      if (e is ApiException) rethrow;

      // Для ошибок аутентификации
      if (response.statusCode == 401) {
        print('ApiService: Authentication failed - 401 Unauthorized');
      }

      throw ApiException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }
  }

  Exception _handleError(dynamic error) {
    if (error is ApiException) return error;
    return ApiException(
      statusCode: 500,
      message: error.toString(),
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException: [$statusCode] $message';
}
