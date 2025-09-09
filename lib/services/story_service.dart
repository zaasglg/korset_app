import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/story.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class StoryService {
  static const String _baseUrl = ApiConfig.baseUrl;

  // Получить все истории (гостевой доступ)
  static Future<List<Story>> getStories() async {
    try {
      final token = await AuthService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$_baseUrl/api/stories-guest'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> storiesJson = data['data'] ?? [];

        print('=== API RESPONSE DEBUG ===');
        print('Stories count: ${storiesJson.length}');
        for (var storyJson in storiesJson) {
          print('Story ID: ${storyJson['id']}');
          print('Media URL: ${storyJson['media_url']}');
          print('Media type: ${storyJson['media_type']}');
          print('User: ${storyJson['user']?['name']}');
          print('---');
        }
        print('========================');

        return storiesJson
            .map((json) => Story.fromJson(json))
            .where((story) => !story.isExpired) // Фильтруем истекшие истории
            .toList();
      } else {
        throw Exception('Ошибка загрузки историй: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching stories: $e');
      throw Exception('Не удалось загрузить истории: $e');
    }
  }

  // Создать новую историю
  static Future<Story> createStory({
    String? content,
    File? mediaFile,
    int? expiresInHours,
    int? publicationPriceId,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Необходима авторизация для создания истории');
      }

      // Если есть медиафайл, используем multipart
      if (mediaFile != null) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl/api/stories'),
        );

        // Добавляем заголовки
        request.headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        });

        // Добавляем текстовый контент
        if (content != null && content.isNotEmpty) {
          request.fields['content'] = content;
        }

        // Добавляем время истечения - отправляем дату вместо часов
        if (expiresInHours != null) {
          final expiresAt = DateTime.now().add(Duration(hours: expiresInHours));
          request.fields['expires_at'] = expiresAt.toIso8601String();
        }

        // Добавляем publication_price_id
        if (publicationPriceId != null) {
          request.fields['publication_price_id'] =
              publicationPriceId.toString();
        }

        // Добавляем медиафайл
        String fieldName = 'media';
        String fileName = mediaFile.path.split('/').last;

        request.files.add(
          await http.MultipartFile.fromPath(
            fieldName,
            mediaFile.path,
            filename: fileName,
          ),
        );

        // Отправляем запрос
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = json.decode(response.body);
          return Story.fromJson(data['data'] ?? data);
        } else {
          final errorData = json.decode(response.body);
          String errorMessage = 'Ошибка создания истории';

          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['errors'] != null) {
            final errors = errorData['errors'] as Map<String, dynamic>;
            errorMessage = errors.values.first.toString();
          }

          throw Exception(errorMessage);
        }
      } else {
        // Если нет медиафайла, используем обычный JSON запрос
        final headers = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        };

        final body = <String, dynamic>{};

        if (content != null && content.isNotEmpty) {
          body['content'] = content;
        }

        if (expiresInHours != null) {
          final expiresAt = DateTime.now().add(Duration(hours: expiresInHours));
          body['expires_at'] = expiresAt.toIso8601String();
        }

        if (publicationPriceId != null) {
          body['publication_price_id'] = publicationPriceId;
        }

        final response = await http.post(
          Uri.parse('$_baseUrl/api/stories'),
          headers: headers,
          body: json.encode(body),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = json.decode(response.body);
          return Story.fromJson(data['data'] ?? data);
        } else {
          final errorData = json.decode(response.body);
          String errorMessage = 'Ошибка создания истории';

          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['errors'] != null) {
            final errors = errorData['errors'] as Map<String, dynamic>;
            errorMessage = errors.values.first.toString();
          }

          throw Exception(errorMessage);
        }
      }
    } catch (e) {
      print('Error creating story: $e');
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Не удалось создать историю: $e');
    }
  }

  // Удалить историю
  static Future<bool> deleteStory(int storyId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Необходима авторизация для удаления истории');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.delete(
        Uri.parse('$_baseUrl/api/stories/$storyId'),
        headers: headers,
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting story: $e');
      return false;
    }
  }

  // Получить истории конкретного пользователя
  static Future<List<Story>> getUserStories(int userId) async {
    try {
      final token = await AuthService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$_baseUrl/api/users/$userId/stories'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> storiesJson = data['data'] ?? data;

        return storiesJson
            .map((json) => Story.fromJson(json))
            .where((story) => !story.isExpired)
            .toList();
      } else {
        throw Exception(
            'Ошибка загрузки историй пользователя: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user stories: $e');
      throw Exception('Не удалось загрузить истории пользователя: $e');
    }
  }
}
