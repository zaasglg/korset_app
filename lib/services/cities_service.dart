import '../models/city.dart';
import 'api_service.dart';

class CitiesService {
  final ApiService _apiService;

  CitiesService({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();

  Future<List<City>> getCities() async {
    try {
      print('CitiesService: Fetching cities...');
      
      final response = await _apiService.get('/api/cities');
      print('CitiesService: Received response: $response');

      if (response == null) {
        print('CitiesService: Null response received');
        return [];
      }

      List<dynamic> citiesData;
      
      // Handle different response structures
      if (response is Map<String, dynamic>) {
        if (response.containsKey('data')) {
          citiesData = response['data'] as List<dynamic>;
        } else if (response.containsKey('cities')) {
          citiesData = response['cities'] as List<dynamic>;
        } else {
          // If the response is a map but doesn't contain data/cities keys,
          // it might be an error response
          print('CitiesService: Unexpected response structure: $response');
          return [];
        }
      } else if (response is List<dynamic>) {
        citiesData = response;
      } else {
        print('CitiesService: Unexpected response type: ${response.runtimeType}');
        return [];
      }

      final cities = citiesData.map((json) {
        try {
          return City.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          print('CitiesService: Error parsing city: $e, data: $json');
          return null;
        }
      }).where((city) => city != null).cast<City>().toList();

      print('CitiesService: Parsed ${cities.length} cities');
      return cities;
      
    } catch (e) {
      print('CitiesService: Error fetching cities: $e');
      // Return empty list on error rather than throwing
      // This allows the app to continue working with local fallback
      return [];
    }
  }

  Future<City?> getCityById(int id) async {
    try {
      print('CitiesService: Fetching city with id: $id');
      
      final response = await _apiService.get('/cities/$id');
      print('CitiesService: Received city response: $response');

      if (response == null) {
        return null;
      }

      // Handle different response structures
      Map<String, dynamic> cityData;
      if (response is Map<String, dynamic>) {
        if (response.containsKey('data')) {
          cityData = response['data'] as Map<String, dynamic>;
        } else {
          cityData = response;
        }
      } else {
        print('CitiesService: Unexpected response type for city: ${response.runtimeType}');
        return null;
      }

      return City.fromJson(cityData);
      
    } catch (e) {
      print('CitiesService: Error fetching city: $e');
      return null;
    }
  }
}
