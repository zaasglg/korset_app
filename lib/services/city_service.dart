import '../models/city.dart';
import '../models/region.dart';
import 'api_service.dart';
import 'dart:developer' as developer;

class CityService {
  final ApiService _apiService;

  CityService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Получить список всех городов
  Future<List<City>> getCities() async {
    try {
      developer.log('Fetching cities from API');
      final response = await _apiService.get('/api/cities');
      developer.log('API response received for cities');

      if (response != null && response is Map) {
        // Check for success status
        if (response['status'] == 'success' && response['data'] != null && response['data'] is List) {
          developer.log('Found cities in data array');
          final cities = (response['data'] as List)
              .map((item) => City.fromJson(item))
              .toList();
          
          developer.log('Parsed ${cities.length} cities');
          return cities;
        }
      }

      // Fallback handling for other response formats
      if (response != null) {
        // Direct list of cities
        if (response is List) {
          developer.log('Response is a direct list of cities');
          return response.map((item) => City.fromJson(item)).toList();
        }
        
        if (response is Map) {
          // Check other possible formats
          if (response['data'] != null && response['data'] is List) {
            developer.log('Response has data wrapper');
            return (response['data'] as List)
                .map((item) => City.fromJson(item))
                .toList();
          }
          
          if (response['cities'] != null && response['cities'] is List) {
            developer.log('Response has cities wrapper');
            return (response['cities'] as List)
                .map((item) => City.fromJson(item))
                .toList();
          }
        }
      }

      developer.log('No cities found in response, returning empty list');
      return [];
    } catch (e) {
      developer.log('Error fetching cities: $e');
      // Return mock cities for development
      return _getMockCities();
    }
  }

  /// Поиск городов по названию
  Future<List<City>> searchCities(String query) async {
    try {
      developer.log('Searching cities with query: $query');
      final response = await _apiService.get('/api/cities/search?q=$query');
      
      if (response != null && response is Map) {
        if (response['status'] == 'success' && response['data'] != null && response['data'] is List) {
          final cities = (response['data'] as List)
              .map((item) => City.fromJson(item))
              .toList();
          
          developer.log('Found ${cities.length} cities matching "$query"');
          return cities;
        }
      }

      if (response != null && response is List) {
        return response.map((item) => City.fromJson(item)).toList();
      }

      return [];
    } catch (e) {
      developer.log('Error searching cities: $e');
      // Return filtered mock cities for development
      final mockCities = _getMockCities();
      return mockCities.where((city) => 
        city.name.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
  }

  /// Получить города по региону
  Future<List<City>> getCitiesByRegion(int regionId) async {
    try {
      developer.log('Fetching cities for region: $regionId');
      final response = await _apiService.get('/api/regions/$regionId/cities');
      
      if (response != null && response is Map) {
        if (response['status'] == 'success' && response['data'] != null && response['data'] is List) {
          final cities = (response['data'] as List)
              .map((item) => City.fromJson(item))
              .toList();
          
          developer.log('Found ${cities.length} cities in region $regionId');
          return cities;
        }
      }

      if (response != null && response is List) {
        return response.map((item) => City.fromJson(item)).toList();
      }

      return [];
    } catch (e) {
      developer.log('Error fetching cities by region: $e');
      return [];
    }
  }

  /// Временные моковые данные для разработки
  List<City> _getMockCities() {
    return [
      City(
        id: 1,
        name: 'Алматы',
        nameEn: 'Almaty',
        nameKz: 'Алматы',
        regionId: 1,
        region: Region(id: 1, name: 'Алматинская область'),
      ),
      City(
        id: 2,
        name: 'Астана',
        nameEn: 'Astana',
        nameKz: 'Астана',
        regionId: 2,
        region: Region(id: 2, name: 'Акмолинская область'),
      ),
      City(
        id: 3,
        name: 'Шымкент',
        nameEn: 'Shymkent',
        nameKz: 'Шымкент',
        regionId: 3,
        region: Region(id: 3, name: 'Туркестанская область'),
      ),
      City(
        id: 4,
        name: 'Караганда',
        nameEn: 'Karaganda',
        nameKz: 'Қарағанды',
        regionId: 4,
        region: Region(id: 4, name: 'Карагандинская область'),
      ),
      City(
        id: 5,
        name: 'Актобе',
        nameEn: 'Aktobe',
        nameKz: 'Ақтөбе',
        regionId: 5,
        region: Region(id: 5, name: 'Актюбинская область'),
      ),
      City(
        id: 6,
        name: 'Тараз',
        nameEn: 'Taraz',
        nameKz: 'Тараз',
        regionId: 6,
        region: Region(id: 6, name: 'Жамбылская область'),
      ),
      City(
        id: 7,
        name: 'Павлодар',
        nameEn: 'Pavlodar',
        nameKz: 'Павлодар',
        regionId: 7,
        region: Region(id: 7, name: 'Павлодарская область'),
      ),
      City(
        id: 8,
        name: 'Усть-Каменогорск',
        nameEn: 'Ust-Kamenogorsk',
        nameKz: 'Өскемен',
        regionId: 8,
        region: Region(id: 8, name: 'Восточно-Казахстанская область'),
      ),
      City(
        id: 9,
        name: 'Семей',
        nameEn: 'Semey',
        nameKz: 'Семей',
        regionId: 9,
        region: Region(id: 9, name: 'Восточно-Казахстанская область'),
      ),
      City(
        id: 10,
        name: 'Актау',
        nameEn: 'Aktau',
        nameKz: 'Ақтау',
        regionId: 10,
        region: Region(id: 10, name: 'Мангистауская область'),
      ),
      City(
        id: 11,
        name: 'Уральск',
        nameEn: 'Uralsk',
        nameKz: 'Орал',
        regionId: 11,
        region: Region(id: 11, name: 'Западно-Казахстанская область'),
      ),
      City(
        id: 12,
        name: 'Костанай',
        nameEn: 'Kostanay',
        nameKz: 'Қостанай',
        regionId: 12,
        region: Region(id: 12, name: 'Костанайская область'),
      ),
      City(
        id: 13,
        name: 'Петропавловск',
        nameEn: 'Petropavlovsk',
        nameKz: 'Петропавл',
        regionId: 13,
        region: Region(id: 13, name: 'Северо-Казахстанская область'),
      ),
      City(
        id: 14,
        name: 'Атырау',
        nameEn: 'Atyrau',
        nameKz: 'Атырау',
        regionId: 14,
        region: Region(id: 14, name: 'Атырауская область'),
      ),
      City(
        id: 15,
        name: 'Кызылорда',
        nameEn: 'Kyzylorda',
        nameKz: 'Қызылорда',
        regionId: 15,
        region: Region(id: 15, name: 'Кызылординская область'),
      ),
      City(
        id: 16,
        name: 'Талдыкорган',
        nameEn: 'Taldykorgan',
        nameKz: 'Талдықорған',
        regionId: 1,
        region: Region(id: 1, name: 'Алматинская область'),
      ),
      City(
        id: 17,
        name: 'Экибастуз',
        nameEn: 'Ekibastuz',
        nameKz: 'Екібастұз',
        regionId: 4,
        region: Region(id: 4, name: 'Карагандинская область'),
      ),
      City(
        id: 18,
        name: 'Темиртау',
        nameEn: 'Temirtau',
        nameKz: 'Теміртау',
        regionId: 4,
        region: Region(id: 4, name: 'Карагандинская область'),
      ),
      City(
        id: 19,
        name: 'Туркестан',
        nameEn: 'Turkestan',
        nameKz: 'Түркістан',
        regionId: 3,
        region: Region(id: 3, name: 'Туркестанская область'),
      ),
      City(
        id: 20,
        name: 'Балхаш',
        nameEn: 'Balkhash',
        nameKz: 'Балхаш',
        regionId: 4,
        region: Region(id: 4, name: 'Карагандинская область'),
      ),
    ];
  }
}
