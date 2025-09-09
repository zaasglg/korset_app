import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:korset_app/models/booking_commission.dart';
import 'package:korset_app/models/booking.dart';
import 'package:korset_app/models/booking_status.dart';
import 'package:korset_app/config/api_config.dart';
import 'package:korset_app/services/auth_service.dart';

class BookingCommissionService {
  static const String baseUrl = ApiConfig.baseUrl;

  /// Получить тарифы бронирования
  Future<List<BookingCommission>> getBookingCommissions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/publication-prices/booking-commissions'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((item) => BookingCommission.fromJson(item)).toList();
        } else {
          throw Exception('Некорректный ответ сервера');
        }
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Не удалось загрузить тарифы бронирования: $e');
    }
  }

  /// Получить первый тариф бронирования
  Future<BookingCommission?> getFirstBookingCommission() async {
    try {
      final commissions = await getBookingCommissions();
      return commissions.isNotEmpty ? commissions.first : null;
    } catch (e) {
      throw Exception('Не удалось загрузить тариф бронирования: $e');
    }
  }

  /// Создать бронирование
  Future<Map<String, dynamic>> createBooking({
    required int productId,
    String notes = '',
  }) async {
    try {
      print('=== Booking Service Debug ===');
      print('Product ID: $productId');
      print('Notes: $notes');

      // Получаем токен авторизации
      final token = await AuthService.getToken();
      print('Token: ${token != null ? "exists" : "null"}');

      if (token == null) {
        throw Exception('Требуется авторизация');
      }

      final booking = Booking(
        productId: productId,
        notes: notes,
      );

      print('Booking data: ${booking.toJson()}');
      print('URL: $baseUrl/api/bookings');

      final response = await http.post(
        Uri.parse('$baseUrl/api/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(booking.toJson()),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse;
      } else {
        try {
          final errorData = json.decode(response.body);
          final String errorMessage =
              errorData['message'] ?? 'Ошибка создания бронирования';
          throw Exception(errorMessage);
        } catch (jsonError) {
          print('JSON parsing error: $jsonError');
          // Если не удалось распарсить JSON, возвращаем статус код
          throw Exception('Ошибка сервера: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Booking creation exception: $e');
      throw Exception('Не удалось создать бронирование: $e');
    }
  }

  /// Получить статус бронирования продукта
  Future<BookingStatus> getBookingStatus(int productId) async {
    try {
      print('=== Get Booking Status Debug ===');
      print('Product ID: $productId');
      print('URL: $baseUrl/api/products/$productId/booking-status');

      final response = await http.get(
        Uri.parse('$baseUrl/api/products/$productId/booking-status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return BookingStatus.fromJson(jsonResponse['data']);
        } else {
          throw Exception('Некорректный ответ сервера');
        }
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('Get booking status exception: $e');
      throw Exception('Не удалось получить статус бронирования: $e');
    }
  }
}
