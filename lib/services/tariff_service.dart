import 'package:flutter/foundation.dart';
import 'package:korset_app/models/tariff.dart';
import 'package:korset_app/models/user_tariff.dart';
import 'package:korset_app/services/api_service.dart';

class TariffService {
  static final ApiService _apiService = ApiService();

  static Future<List<Tariff>> getTariffs() async {
    try {
      debugPrint('TariffService: Загружаем тарифы...');

      final response =
          await _apiService.get('/api/tariffs', requiresAuth: true);

      debugPrint('TariffService: Получен ответ: $response');

      if (response == null) {
        debugPrint('TariffService: Пустой ответ от сервера');
        throw Exception('Сервер не отвечает');
      }

      if (response['success'] != true) {
        debugPrint(
            'TariffService: Неуспешный ответ: ${response['message'] ?? 'Неизвестная ошибка'}');
        throw Exception(response['message'] ?? 'Ошибка при загрузке тарифов');
      }

      final data = response['data'];
      if (data == null) {
        debugPrint('TariffService: Данные тарифов отсутствуют');
        return [];
      }

      if (data is! List) {
        debugPrint('TariffService: Данные тарифов имеют неверный формат');
        throw Exception('Неверный формат данных тарифов');
      }

      debugPrint('TariffService: Парсим ${data.length} тарифов');
      final tariffs = data
          .map<Tariff>((json) => Tariff.fromJson(json))
          .where(
              (tariff) => tariff.isActive) // Показываем только активные тарифы
          .toList();

      debugPrint(
          'TariffService: Успешно загружено ${tariffs.length} активных тарифов');
      return tariffs;
    } catch (e) {
      debugPrint('TariffService: Ошибка при загрузке тарифов: $e');

      // Если это наша кастомная ошибка, прокидываем её дальше
      if (e is Exception) {
        rethrow;
      }

      // Иначе оборачиваем в более понятное сообщение
      throw Exception('Не удалось загрузить тарифы: $e');
    }
  }

  static Future<Map<String, dynamic>> purchaseTariff(int tariffId) async {
    try {
      debugPrint('TariffService: Покупка тарифа $tariffId...');

      final response = await _apiService.post(
        '/api/tariffs/$tariffId/purchase',
        requiresAuth: true,
      );

      debugPrint('TariffService: Получен ответ покупки: $response');

      if (response == null) {
        debugPrint('TariffService: Пустой ответ от сервера');
        return {
          'success': false,
          'message': 'Сервер не отвечает',
        };
      }

      // Возвращаем весь ответ без проверки success
      // Пусть UI сам решает, как обрабатывать success: true/false
      return response;
    } catch (e) {
      debugPrint('TariffService: Ошибка при покупке тарифа: $e');

      // Возвращаем ошибку в том же формате, что и API
      return {
        'success': false,
        'message': 'Не удалось купить тариф: ${e.toString()}',
      };
    }
  }

  static Future<MyTariffsResponse?> getMyTariffs() async {
    try {
      debugPrint('TariffService: Загружаем активные тарифы пользователя...');

      final response =
          await _apiService.get('/api/my-tariffs', requiresAuth: true);

      debugPrint('TariffService: Получен ответ активных тарифов: $response');

      if (response == null) {
        debugPrint('TariffService: Пустой ответ от сервера');
        return null;
      }

      // Возвращаем весь ответ, даже если success: false
      return MyTariffsResponse.fromJson(response);
    } catch (e) {
      debugPrint('TariffService: Ошибка при загрузке активных тарифов: $e');

      // Если это наша кастомная ошибка, прокидываем её дальше
      if (e is Exception) {
        rethrow;
      }

      // Иначе оборачиваем в более понятное сообщение
      throw Exception('Не удалось загрузить активные тарифы: $e');
    }
  }
}
