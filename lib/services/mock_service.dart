import '../models/region_mood.dart';
import '../models/city_mood.dart';
import '../models/district_mood.dart';
import '../models/federal_district_mood.dart';
import '../data/russian_regions.dart';
import '../data/region_cities_data.dart';
import '../data/region_cities.dart';
import 'dart:math';

/// Мок-сервис для тестирования без бекенда
class MockService {
  static final Random _random = Random();

  /// Генерировать моковые данные рейтинга регионов
  static List<RegionMood> generateMockRegionsRanking({String period = 'day'}) {
    final regions = RussianRegions.getAll();
    
    return regions.map((regionData) {
      // Генерируем случайные данные для демонстрации
      final averageMood = 2.0 + _random.nextDouble() * 2.5; // От 2.0 до 4.5
      final population = RegionCitiesData.getPopulation(regionData['id']!);
      // Защита от деления на ноль и отрицательных значений
      final maxCheckIns = population > 0 ? (population ~/ 100).clamp(1, 10000) : 100;
      final totalCheckIns = _random.nextInt(maxCheckIns) + 10; // От 10 до 1% населения
      
      return RegionMood(
        id: regionData['id']!,
        name: regionData['name']!,
        averageMood: double.parse(averageMood.toStringAsFixed(2)),
        totalCheckIns: totalCheckIns,
        population: population,
        lastUpdate: DateTime.now().subtract(
          Duration(hours: _random.nextInt(24)),
        ),
      );
    }).toList()
      ..sort((a, b) => b.averageMood.compareTo(a.averageMood)); // Сортируем по убыванию
  }

  /// Генерировать моковые данные для конкретного региона
  static RegionMood generateMockRegionStats(String regionId, {String period = 'day'}) {
    final regionData = RussianRegions.findById(regionId);
    
    if (regionData == null) {
      throw Exception('Регион не найден');
    }

    final averageMood = 2.0 + _random.nextDouble() * 2.5;
    final population = RegionCitiesData.getPopulation(regionId);
    // Защита от деления на ноль и отрицательных значений
    final maxCheckIns = population > 0 ? (population ~/ 100).clamp(1, 10000) : 100;
    final totalCheckIns = _random.nextInt(maxCheckIns) + 10;

    return RegionMood(
      id: regionId,
      name: regionData['name']!,
      averageMood: double.parse(averageMood.toStringAsFixed(2)),
      totalCheckIns: totalCheckIns,
      population: population,
      lastUpdate: DateTime.now(),
    );
  }

  /// Генерировать моковые данные городов региона
  static Future<List<CityMood>> generateMockCities(String regionId, {String period = 'day'}) async {
    // Получаем реальные города из RegionCities
    final citiesData = await RegionCities.getCitiesForRegion(regionId);
    
    // Если нет данных, используем fallback
    if (citiesData.isEmpty) {
      final fallbackCities = _getCitiesForRegion(regionId);
      return fallbackCities.map((cityName) {
        final averageMood = 2.0 + _random.nextDouble() * 2.5;
        final population = 50000 + _random.nextInt(500000);
        final maxCheckIns = (population ~/ 200).clamp(1, 5000);
        final totalCheckIns = _random.nextInt(maxCheckIns) + 5;
        
        return CityMood(
          id: '${regionId}_${cityName.hashCode}',
          name: cityName,
          regionId: regionId,
          averageMood: double.parse(averageMood.toStringAsFixed(2)),
          totalCheckIns: totalCheckIns,
          population: population,
          lastUpdate: DateTime.now().subtract(
            Duration(hours: _random.nextInt(24)),
          ),
        );
      }).toList()
        ..sort((a, b) => b.averageMood.compareTo(a.averageMood));
    }
    
    // Используем реальные данные о городах
    return citiesData.map((cityData) {
      final cityName = cityData['name'] as String;
      final cityPopulation = (cityData['population'] as int?) ?? 0;
      
      // Генерируем случайное настроение для демонстрации
      final averageMood = 2.0 + _random.nextDouble() * 2.5;
      
      // Вычисляем количество чек-инов на основе населения
      final maxCheckIns = cityPopulation > 0 
          ? (cityPopulation ~/ 200).clamp(1, 5000)
          : 100;
      final totalCheckIns = _random.nextInt(maxCheckIns) + 5;
      
      return CityMood(
        id: '${regionId}_${cityName.hashCode}',
        name: cityName,
        regionId: regionId,
        averageMood: double.parse(averageMood.toStringAsFixed(2)),
        totalCheckIns: totalCheckIns,
        population: cityPopulation,
        lastUpdate: DateTime.now().subtract(
          Duration(hours: _random.nextInt(24)),
        ),
      );
    }).toList()
      ..sort((a, b) => b.averageMood.compareTo(a.averageMood));
  }

  /// Генерировать моковые данные районов города
  static List<DistrictMood> generateMockDistricts(String cityId, {String period = 'day'}) {
    // Примерные районы
    final districts = [
      'Центральный',
      'Северный',
      'Южный',
      'Восточный',
      'Западный',
      'Северо-Западный',
      'Юго-Восточный',
    ];
    
    return districts.map((districtName) {
      final averageMood = 2.0 + _random.nextDouble() * 2.5;
      final population = 10000 + _random.nextInt(100000); // От 10к до 110к
      final maxCheckIns = (population ~/ 300).clamp(1, 2000);
      final totalCheckIns = _random.nextInt(maxCheckIns) + 3;
      
      return DistrictMood(
        id: '${cityId}_${districtName.hashCode}',
        name: districtName,
        cityId: cityId,
        averageMood: double.parse(averageMood.toStringAsFixed(2)),
        totalCheckIns: totalCheckIns,
        population: population,
        lastUpdate: DateTime.now().subtract(
          Duration(hours: _random.nextInt(24)),
        ),
      );
    }).toList()
      ..sort((a, b) => b.averageMood.compareTo(a.averageMood));
  }

  /// Получить список городов для региона
  static List<String> _getCitiesForRegion(String regionId) {
    // Примерные города для разных регионов
    final cityMap = {
      '77': ['Москва', 'Зеленоград', 'Троицк'],
      '78': ['Санкт-Петербург', 'Колпино', 'Кронштадт'],
      '50': ['Москва', 'Химки', 'Балашиха', 'Подольск', 'Королёв'],
      '23': ['Краснодар', 'Сочи', 'Новороссийск', 'Армавир'],
      '66': ['Екатеринбург', 'Нижний Тагил', 'Каменск-Уральский'],
      '16': ['Казань', 'Набережные Челны', 'Альметьевск'],
      '02': ['Уфа', 'Стерлитамак', 'Салават'],
      '61': ['Ростов-на-Дону', 'Таганрог', 'Новочеркасск'],
    };
    
    return cityMap[regionId] ?? [
      'Город 1',
      'Город 2',
      'Город 3',
      'Город 4',
    ];
  }

  /// Генерировать моковые данные рейтинга федеральных округов
  static List<FederalDistrictMood> generateMockFederalDistrictsRanking({String period = 'day'}) {
    final districts = RussianRegions.getFederalDistricts();
    
    return districts.map((districtName) {
      // Получаем все регионы округа
      final regionsInDistrict = RussianRegions.getByFederalDistrict(districtName);
      
      // Вычисляем общее население округа
      int totalPopulation = 0;
      for (var region in regionsInDistrict) {
        totalPopulation += RegionCitiesData.getPopulation(region['id']!);
      }
      
      // Генерируем случайные данные
      final averageMood = 2.0 + _random.nextDouble() * 2.5;
      final maxCheckIns = totalPopulation > 0 ? (totalPopulation ~/ 100).clamp(1, 100000) : 1000;
      final totalCheckIns = _random.nextInt(maxCheckIns) + 100;
      
      return FederalDistrictMood(
        id: districtName.hashCode.toString(),
        name: districtName,
        averageMood: double.parse(averageMood.toStringAsFixed(2)),
        totalCheckIns: totalCheckIns,
        population: totalPopulation,
        lastUpdate: DateTime.now().subtract(
          Duration(hours: _random.nextInt(24)),
        ),
      );
    }).toList()
      ..sort((a, b) => b.averageMood.compareTo(a.averageMood));
  }

  /// Генерировать моковые данные всех городов России
  static Future<List<CityMood>> generateMockAllCitiesRanking({String period = 'day'}) async {
    final regions = RussianRegions.getAll();
    final List<CityMood> allCities = [];
    
    for (var region in regions) {
      final regionId = region['id']!;
      final cities = await generateMockCities(regionId, period: period);
      allCities.addAll(cities);
    }
    
    // Сортируем все города по среднему настроению
    allCities.sort((a, b) => b.averageMood.compareTo(a.averageMood));
    
    return allCities;
  }
}

