import 'package:korset_app/models/referral.dart';
import 'package:korset_app/services/api_service.dart';

class ReferralService {
  static final ApiService _apiService = ApiService();

  // Получить информацию о рефералах
  static Future<ReferralData?> getReferralData() async {
    try {
      print('ReferralService: Making GET request to /api/referrals');
      final response = await _apiService.get(
        '/api/referrals',
        requiresAuth: true,
      );

      print('ReferralService: Response received: $response');
      if (response != null && response['success'] == true) {
        return ReferralData.fromJson(response['data']);
      } else {
        throw Exception('API returned success: false');
      }
    } catch (e) {
      print('Error getting referral data: $e');
      return null;
    }
  }

  // Сгенерировать новый реферальный код
  static Future<ReferralCodeResponse?> generateReferralCode() async {
    try {
      print('ReferralService: Making POST request to /api/referrals/generate');
      final response = await _apiService.post(
        '/api/referrals/generate',
        requiresAuth: true,
      );

      print('ReferralService: Response received: $response');
      if (response != null && response['success'] == true) {
        return ReferralCodeResponse.fromJson(response['data']);
      } else {
        throw Exception('API returned success: false');
      }
    } catch (e) {
      print('Error generating referral code: $e');
      return null;
    }
  }

  // Построить реферальную ссылку
  static String buildReferralLink(String referralCode) {
    return 'https://korset.kz/register?ref=$referralCode';
  }

  // Форматировать валюту
  static String formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2)} ₸';
  }
}
