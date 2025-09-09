import 'package:flutter/foundation.dart';
import 'package:korset_app/models/wallet.dart';
import 'package:korset_app/services/auth_service.dart';
import 'package:korset_app/services/api_service.dart';

class WalletService {
  static final ApiService _apiService = ApiService();

  static Future<Wallet?> getWallet() async {
    try {
      debugPrint('WalletService: Начинаем загрузку данных кошелька...');

      final token = await AuthService.getToken();
      if (token == null) {
        debugPrint('WalletService: Токен доступа не найден');
        throw Exception('Пользователь не авторизован');
      }

      debugPrint('WalletService: Токен найден, делаем запрос к API...');
      final response = await _apiService.get('/api/wallet', requiresAuth: true);

      debugPrint('WalletService: Получен ответ: $response');

      if (response == null) {
        debugPrint('WalletService: Пустой ответ от сервера');
        throw Exception('Сервер не отвечает');
      }

      if (response['success'] != true) {
        debugPrint(
            'WalletService: Неуспешный ответ: ${response['message'] ?? 'Неизвестная ошибка'}');
        final errorMessage =
            response['message'] ?? response['error'] ?? 'Ошибка сервера';
        throw Exception(errorMessage);
      }

      if (response['data'] == null) {
        debugPrint('WalletService: Данные кошелька отсутствуют в ответе');
        throw Exception('Данные кошелька не найдены');
      }

      debugPrint('WalletService: Парсим данные кошелька...');
      final wallet = Wallet.fromJson(response['data']);
      debugPrint(
          'WalletService: Данные кошелька успешно загружены. Баланс: ${wallet.currentBalance}');

      return wallet;
    } catch (e) {
      debugPrint('WalletService: Ошибка при загрузке кошелька: $e');

      // Если это наша кастомная ошибка, прокидываем её дальше
      if (e is Exception) {
        rethrow;
      }

      // Иначе оборачиваем в более понятное сообщение
      throw Exception('Не удалось загрузить данные кошелька: $e');
    }
  }

  static Future<Map<String, dynamic>?> topUpBalance({
    required double amount,
    String? description,
  }) async {
    try {
      debugPrint(
          'WalletService: Начинаем пополнение баланса на сумму $amount...');

      final token = await AuthService.getToken();
      if (token == null) {
        debugPrint('WalletService: Токен доступа не найден');
        throw Exception('Пользователь не авторизован');
      }

      final requestBody = {
        'amount': amount,
        'description': description ?? 'Пополнение баланса',
      };

      debugPrint(
          'WalletService: Отправляем запрос на пополнение: $requestBody');
      final response = await _apiService.post(
        '/api/payments/topup',
        body: requestBody,
        requiresAuth: true,
      );

      debugPrint('WalletService: Получен ответ пополнения: $response');

      if (response == null) {
        debugPrint('WalletService: Пустой ответ от сервера');
        throw Exception('Сервер не отвечает');
      }

      if (response['success'] != true) {
        final message = response['message'] ?? 'Ошибка при создании платежа';
        debugPrint('WalletService: Ошибка пополнения: $message');
        throw Exception(message);
      }

      debugPrint('WalletService: Пополнение успешно инициировано');
      return response['data'];
    } catch (e) {
      debugPrint('WalletService: Ошибка при пополнении баланса: $e');

      // Если это наша кастомная ошибка, прокидываем её дальше
      if (e is Exception) {
        rethrow;
      }

      // Иначе оборачиваем в более понятное сообщение
      throw Exception('Не удалось создать платеж: $e');
    }
  }
}
