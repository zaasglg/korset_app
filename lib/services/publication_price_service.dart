import 'package:flutter/foundation.dart';
import 'package:korset_app/models/publication_price.dart';
import 'package:korset_app/services/api_service.dart';

class PublicationPriceService {
  static final ApiService _apiService = ApiService();

  static Future<List<PublicationPrice>> getPublicationPrices() async {
    try {
      debugPrint('PublicationPriceService: Загружаем цены публикации...');

      final response = await _apiService.get(
        '/api/publication-prices/announcements',
        requiresAuth: true,
      );

      debugPrint('PublicationPriceService: Получен ответ: $response');

      if (response == null) {
        debugPrint('PublicationPriceService: Пустой ответ от сервера');
        throw Exception('Сервер не отвечает');
      }

      if (response['success'] != true) {
        debugPrint(
            'PublicationPriceService: Неуспешный ответ: ${response['message'] ?? 'Неизвестная ошибка'}');
        throw Exception(
            response['message'] ?? 'Ошибка при загрузке цен публикации');
      }

      final data = response['data'];
      if (data == null) {
        debugPrint(
            'PublicationPriceService: Данные цен публикации отсутствуют');
        return [];
      }

      if (data is! List) {
        debugPrint(
            'PublicationPriceService: Данные цен публикации имеют неверный формат');
        throw Exception('Неверный формат данных цен публикации');
      }

      debugPrint(
          'PublicationPriceService: Парсим ${data.length} цен публикации');
      final prices = data
          .map<PublicationPrice>((json) => PublicationPrice.fromJson(json))
          .toList();

      debugPrint(
          'PublicationPriceService: Успешно загружено ${prices.length} цен публикации');
      return prices;
    } catch (e) {
      debugPrint(
          'PublicationPriceService: Ошибка при загрузке цен публикации: $e');

      // Если это наша кастомная ошибка, прокидываем её дальше
      if (e is Exception) {
        rethrow;
      }

      // Иначе оборачиваем в более понятное сообщение
      throw Exception('Не удалось загрузить цены публикации: $e');
    }
  }

  // Метод для получения тарифов историй
  static Future<List<PublicationPrice>> getStoryPrices() async {
    try {
      debugPrint('PublicationPriceService: Загружаем тарифы историй...');

      final response = await _apiService.get(
        '/api/publication-prices/stories',
        requiresAuth: true,
      );

      debugPrint(
          'PublicationPriceService: Получен ответ для историй: $response');

      if (response == null) {
        debugPrint(
            'PublicationPriceService: Пустой ответ от сервера для историй');
        throw Exception('Сервер не отвечает');
      }

      if (response['success'] != true) {
        debugPrint(
            'PublicationPriceService: Неуспешный ответ для историй: ${response['message'] ?? 'Неизвестная ошибка'}');
        throw Exception(
            response['message'] ?? 'Ошибка при загрузке тарифов историй');
      }

      final data = response['data'];
      if (data == null) {
        debugPrint(
            'PublicationPriceService: Данные тарифов историй отсутствуют');
        return [];
      }

      if (data is! List) {
        debugPrint(
            'PublicationPriceService: Данные тарифов историй имеют неверный формат');
        throw Exception('Неверный формат данных тарифов историй');
      }

      debugPrint(
          'PublicationPriceService: Парсим ${data.length} тарифов историй');
      final prices = data
          .map<PublicationPrice>((json) => PublicationPrice.fromJson(json))
          .toList();

      debugPrint(
          'PublicationPriceService: Успешно загружено ${prices.length} тарифов историй');
      return prices;
    } catch (e) {
      debugPrint(
          'PublicationPriceService: Ошибка при загрузке тарифов историй: $e');

      // Если это наша кастомная ошибка, прокидываем её дальше
      if (e is Exception) {
        rethrow;
      }

      // Иначе оборачиваем в более понятное сообщение
      throw Exception('Не удалось загрузить тарифы историй: $e');
    }
  }
}
