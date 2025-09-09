import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:korset_app/services/auth_service.dart';
import 'package:korset_app/config/api_config.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  static const String baseUrl = ApiConfig.baseUrl;

  /// Поделиться объявлением (для авторизованных пользователей)
  static Future<Map<String, dynamic>> shareProduct(int productId) async {
    try {
      final token = await AuthService.getToken();
      final endpoint = token != null
          ? '$baseUrl/api/products/$productId/share'
          : '$baseUrl/api/public/products/$productId/share';

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      print('=== Share Product Request ===');
      print('URL: $endpoint');
      print('Headers: $headers');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['data'];
        } else {
          throw Exception(
              data['message'] ?? 'Ошибка при получении данных для поделиться');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Ошибка сервера при поделиться');
      }
    } catch (e) {
      print('Error sharing product: $e');
      throw Exception('Ошибка при поделиться: ${e.toString()}');
    }
  }

  /// Получить статистику поделившихся
  static Future<Map<String, dynamic>> getShareStats(int productId) async {
    try {
      final token = await AuthService.getToken();

      if (token == null) {
        throw Exception('Требуется авторизация');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/products/$productId/share-stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Share stats response: ${response.statusCode}');
      print('Share stats body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Ошибка при получении статистики');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Ошибка сервера');
      }
    } catch (e) {
      print('Error getting share stats: $e');
      throw Exception('Ошибка при получении статистики: ${e.toString()}');
    }
  }

  /// Поделиться объявлением через нативное меню устройства
  static Future<void> shareProductNative(Map<String, dynamic> shareData) async {
    try {
      final String shareText = '''
${shareData['title']}

${shareData['description']}

💰 Цена: ${shareData['price']} ₸
📍 Местоположение: ${shareData['location']}

Подробнее: ${shareData['url']}
''';

      await Share.share(
        shareText,
        subject: shareData['title'],
      );
    } catch (e) {
      print('Error sharing natively: $e');
      throw Exception('Ошибка при поделиться: ${e.toString()}');
    }
  }

  /// Полный процесс поделиться (получить данные + поделиться)
  static Future<void> shareProductComplete(int productId) async {
    try {
      // Получаем данные для поделиться
      final shareData = await shareProduct(productId);

      // Поделиться через нативное меню
      await shareProductNative(shareData);

      print(
          'Product shared successfully. New shares count: ${shareData['shares_count']}');
    } catch (e) {
      print('Error in complete share process: $e');
      rethrow;
    }
  }
}
