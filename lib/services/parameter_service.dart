import '../models/parameter.dart';
import 'api_service.dart';
import 'dart:developer' as developer;

class ParameterService {
  final ApiService _apiService;

  ParameterService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<List<Parameter>> getCategoryParameters(String categoryId) async {
    try {
      developer.log('Fetching parameters for category: $categoryId');
      final response = await _apiService.get('/api/categories/$categoryId/parameters');
      developer.log('API response received for parameters');

      if (response != null && response is Map) {
        // Check for success status
        if (response['status'] == 'success' && response['data'] != null && response['data'] is List) {
          developer.log('Found parameters in data array');
          final parameters = (response['data'] as List)
              .map((item) => Parameter.fromJson(item))
              .toList();
          
          developer.log('Parsed ${parameters.length} parameters');
          return parameters;
        }
      }

      // Fallback handling for other response formats
      if (response != null) {
        // Direct list of parameters
        if (response is List) {
          developer.log('Response is a direct list');
          return response.map((item) => Parameter.fromJson(item)).toList();
        }
        
        if (response is Map) {
          // Check other possible formats
          if (response['data'] != null && response['data'] is List) {
            developer.log('Response has data wrapper');
            return (response['data'] as List)
                .map((item) => Parameter.fromJson(item))
                .toList();
          }
          
          if (response['parameters'] != null && response['parameters'] is List) {
            developer.log('Response has parameters wrapper');
            return (response['parameters'] as List)
                .map((item) => Parameter.fromJson(item))
                .toList();
          }
        }
      }

      developer.log('Could not parse parameters from response format');
      return [];
    } catch (e) {
      developer.log('Error fetching parameters: $e', error: e);
      return [];
    }
  }
}
