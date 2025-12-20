import 'region_cities_data.dart';

/// Данные о городах регионов
class RegionCities {
  static Map<String, List<Map<String, dynamic>>>? _citiesCache;

  /// Получить список городов для региона
  static Future<List<Map<String, dynamic>>> getCitiesForRegion(String regionId) async {
    if (_citiesCache == null) {
      _loadCitiesData();
    }
    
    return _citiesCache![regionId] ?? [];
  }

  /// Загрузить данные о городах
  static void _loadCitiesData() {
    _citiesCache = RegionCitiesData.cities;
  }
}

