import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class ApiService {
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

  Future<dynamic> delete(String endpoint, {bool requiresAuth = false}) async {
    try {
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      final response = await _client
          .delete(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: headers,
          )
          .timeout(const Duration(seconds: ApiConfig.timeoutDuration));

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  dynamic _handleResponse(http.Response response) {
    print('ApiService: Response status: ${response.statusCode}');
    print('ApiService: Response body: ${response.body}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
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
