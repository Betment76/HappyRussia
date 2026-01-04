import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/region_mood.dart';
import '../models/city_mood.dart';
import '../models/district_mood.dart';
import '../models/federal_district_mood.dart';
import '../models/check_in.dart';
import '../models/region_data.dart';
import '../models/federal_district_data.dart';
import '../models/settlement.dart';
import '../models/urban_district.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/mock_service.dart';
import '../services/settlements_data_service.dart';

/// Провайдер для управления состоянием настроения
class MoodProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final SettlementsDataService _settlementsService = SettlementsDataService();
  
  // Флаг для использования моков (true = моки, false = реальный API)
  static const bool useMocks = false; // Бекенд готов, используем реальный API

  // Актуальные данные о населенных пунктах из базы
  List<FederalDistrictData> _federalDistrictsData = [];
  bool _isLoadingSettlementsData = false;

  List<RegionMood> _regions = [];
  bool _isLoading = false;
  String _selectedPeriod = 'day'; // day, week, month
  String? _error;

  // Данные о городах
  List<CityMood> _cities = [];
  bool _isLoadingCities = false;
  String? _errorCities;

  // Данные о районах
  List<DistrictMood> _districts = [];
  bool _isLoadingDistricts = false;
  String? _errorDistricts;

  // Данные о федеральных округах
  List<FederalDistrictMood> _federalDistricts = [];
  bool _isLoadingFederalDistricts = false;
  String? _errorFederalDistricts;

  // Данные о всех городах
  List<CityMood> _allCities = [];
  bool _isLoadingAllCities = false;
  String? _errorAllCities;

  List<RegionMood> get regions => _regions;
  bool get isLoading => _isLoading;
  String get selectedPeriod => _selectedPeriod;
  String? get error => _error;

  List<CityMood> get cities => _cities;
  bool get isLoadingCities => _isLoadingCities;
  String? get errorCities => _errorCities;

  List<DistrictMood> get districts => _districts;
  bool get isLoadingDistricts => _isLoadingDistricts;
  String? get errorDistricts => _errorDistricts;

  List<FederalDistrictMood> get federalDistricts => _federalDistricts;
  bool get isLoadingFederalDistricts => _isLoadingFederalDistricts;
  String? get errorFederalDistricts => _errorFederalDistricts;

  List<CityMood> get allCities => _allCities;
  bool get isLoadingAllCities => _isLoadingAllCities;
  String? get errorAllCities => _errorAllCities;

  List<FederalDistrictData> get federalDistrictsData => _federalDistrictsData;
  bool get isLoadingSettlementsData => _isLoadingSettlementsData;

  /// Найти город по ID
  CityMood? getCityById(String cityId) {
    // Ищем в списке всех городов
    try {
      return _allCities.firstWhere((city) => city.id == cityId);
    } catch (e) {
      // Ищем в списке городов региона
      try {
        return _cities.firstWhere((city) => city.id == cityId);
      } catch (e) {
        return null;
      }
    }
  }

  /// Загрузить рейтинг регионов
  Future<void> loadRegionsRanking({String? period}) async {
    // Предотвращаем повторные вызовы, если уже загружается
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Сначала пытаемся загрузить из кэша
      final cachedRegions = await _storageService.getRegionsCache();
      if (cachedRegions.isNotEmpty && !useMocks) {
        _regions = cachedRegions;
        notifyListeners();
      }

      // Загружаем данные (моки или реальный API)
      final periodToUse = period ?? _selectedPeriod;
      List<RegionMood> regions;
      
      if (useMocks) {
        // Используем моки для фронтенда
        await Future.delayed(const Duration(milliseconds: 500)); // Имитация загрузки
        regions = MockService.generateMockRegionsRanking(period: periodToUse);
      } else {
        // Реальный API
        regions = await _apiService.getRegionsRanking(period: periodToUse);
      }
      
      _regions = regions;
      _selectedPeriod = periodToUse;
      
      // Сохраняем в кэш
      await _storageService.saveRegionsCache(regions);
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      // Если ошибка, используем кэш или моки
      if (_regions.isEmpty) {
        if (useMocks) {
          _regions = MockService.generateMockRegionsRanking();
        } else {
          _regions = await _storageService.getRegionsCache();
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Отправить чек-ин
  Future<void> submitCheckIn(CheckIn checkIn) async {
    if (kDebugMode) {
      print('📤 Отправка чек-ина:');
      print('   cityId: ${checkIn.cityId}');
      print('   cityName: ${checkIn.cityName}');
      print('   regionId: ${checkIn.regionId}');
      print('   userId: ${checkIn.userId}');
      print('   mood: ${checkIn.mood.value}');
    }
    
    try {
      // Сохраняем локально
      await _storageService.saveCheckIn(checkIn);
      
      // Оптимистичное обновление: сразу обновляем локальные данные
      // чтобы город появился в топе немедленно, не дожидаясь ответа сервера
      _updateLocalDataOptimistically(checkIn);
      
      if (useMocks) {
        // В режиме моков просто имитируем отправку
        await Future.delayed(const Duration(milliseconds: 300));
      } else {
        // Отправляем на сервер
        await _apiService.submitCheckIn(checkIn);
      }
      
    } catch (e) {
      // При ошибке откатываем оптимистичное обновление
      _revertOptimisticUpdate(checkIn);
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      // Обновляем все рейтинги с сервера для синхронизации
      // Это делается в finally, чтобы обновить данные даже если была ошибка
      Future.wait([
        loadFederalDistrictsRanking(),
        loadRegionsRanking(),
        loadAllCitiesRanking(),
        if (checkIn.regionId != null) loadCitiesRanking(checkIn.regionId!),
      ]).catchError((e) {
        // Игнорируем ошибки при обновлении рейтингов
        if (kDebugMode) {
          print('Ошибка обновления рейтингов: $e');
        }
      });
    }
  }

  /// Оптимистичное обновление локальных данных после чек-ина
  void _updateLocalDataOptimistically(CheckIn checkIn) {
    // Обновляем данные о городе
    if (checkIn.cityId != null && checkIn.cityName != null) {
      // Ищем город по ID или по имени + regionId
      final cityIndex = _allCities.indexWhere((c) => 
        c.id == checkIn.cityId || 
        (c.name.toLowerCase().trim() == checkIn.cityName!.toLowerCase().trim() && 
         c.regionId == checkIn.regionId)
      );
      
      if (cityIndex >= 0) {
        // Город уже есть в списке - обновляем его данные
        final existingCity = _allCities[cityIndex];
        
        // ВАЖНО: По новой логике totalCheckIns = количество уникальных пользователей
        // В оптимистичном обновлении мы не можем точно знать, был ли уже чек-ин от этого пользователя
        // Поэтому просто обновляем настроение, а totalCheckIns обновится с сервера
        // Но если totalCheckIns = 0, то это первый чек-ин - устанавливаем в 1
        final newTotalCheckIns = existingCity.totalCheckIns == 0 ? 1 : existingCity.totalCheckIns;
        
        // Обновляем настроение: берем последний чек-ин (по новой логике)
        // В оптимистичном обновлении просто устанавливаем настроение из чек-ина
        final newAverageMood = checkIn.mood.value.toDouble();
        
        _allCities[cityIndex] = CityMood(
          id: existingCity.id,
          name: existingCity.name,
          regionId: existingCity.regionId,
          averageMood: newAverageMood,
          totalCheckIns: newTotalCheckIns,
          population: existingCity.population,
          lastUpdate: DateTime.now(),
        );
      } else {
        // Города нет в списке - добавляем его
        // Нужно получить население из статических данных
        _addCityOptimistically(checkIn);
      }
    }
    
    // Обновляем данные о регионе
    if (checkIn.regionId != null) {
      final regionIndex = _regions.indexWhere((r) => r.id == checkIn.regionId);
      if (regionIndex >= 0) {
        final existingRegion = _regions[regionIndex];
        
        // ВАЖНО: По новой логике totalCheckIns = количество уникальных пользователей
        // В оптимистичном обновлении мы не можем точно знать, был ли уже чек-ин от этого пользователя
        // Поэтому просто обновляем настроение, а totalCheckIns обновится с сервера
        final newTotalCheckIns = existingRegion.totalCheckIns == 0 ? 1 : existingRegion.totalCheckIns;
        
        // Обновляем настроение: берем последний чек-ин
        final newAverageMood = checkIn.mood.value.toDouble();
        
        _regions[regionIndex] = RegionMood(
          id: existingRegion.id,
          name: existingRegion.name,
          averageMood: newAverageMood,
          totalCheckIns: newTotalCheckIns,
          population: existingRegion.population,
          lastUpdate: DateTime.now(),
        );
      }
    }
    
    notifyListeners();
  }

  /// Добавить город оптимистично (если его нет в списке)
  Future<void> _addCityOptimistically(CheckIn checkIn) async {
    if (checkIn.cityId == null || checkIn.cityName == null || checkIn.regionId == null) {
      return;
    }
    
    try {
      // Пытаемся найти население в статических данных
      int population = 0;
      try {
        final settlement = await _settlementsService.findSettlementById(checkIn.cityId!);
        if (settlement != null) {
          population = settlement.population;
        }
      } catch (e) {
        // Если не нашли, пытаемся найти по имени
        try {
          final regionCities = await _settlementsService.getRegionCities(checkIn.regionId!);
          final foundSettlement = regionCities.firstWhere(
            (s) => s.name.toLowerCase() == checkIn.cityName!.toLowerCase(),
            orElse: () => Settlement(id: '', name: '', type: '', population: 0),
          );
          population = foundSettlement.population;
        } catch (e) {
          // Игнорируем ошибки
        }
      }
      
      // Добавляем город в список
      _allCities.add(CityMood(
        id: checkIn.cityId!,
        name: checkIn.cityName!,
        regionId: checkIn.regionId!,
        averageMood: checkIn.mood.value.toDouble(),
        totalCheckIns: 1,
        population: population,
        lastUpdate: DateTime.now(),
      ));
    } catch (e) {
      // Игнорируем ошибки при добавлении города
      if (kDebugMode) {
        print('Ошибка добавления города оптимистично: $e');
      }
    }
  }

  /// Откатить оптимистичное обновление при ошибке
  void _revertOptimisticUpdate(CheckIn checkIn) {
    // Просто перезагружаем данные с сервера
    // Это проще, чем отслеживать все изменения
  }

  /// Проверить, был ли сегодня чек-ин
  Future<bool> hasCheckInToday() async {
    return await _storageService.hasCheckInToday();
  }

  /// Удалить все чек-ины (локально и на сервере)
  Future<void> deleteAllCheckIns() async {
    try {
      // Удаляем на сервере
      if (!useMocks) {
        await _apiService.deleteAllCheckIns();
      }
      // Локальные данные уже удаляются в StorageService.clearCheckIns()
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка удаления чек-инов на сервере: $e');
      }
      rethrow;
    }
  }

  /// Загрузить рейтинг городов региона
  Future<void> loadCitiesRanking(String regionId, {String? period}) async {
    _isLoadingCities = true;
    _errorCities = null;
    notifyListeners();

    try {
      final periodToUse = period ?? _selectedPeriod;
      List<CityMood> cities;
      
      if (useMocks) {
        await Future.delayed(const Duration(milliseconds: 300));
        cities = await MockService.generateMockCities(regionId, period: periodToUse);
      } else {
        cities = await _apiService.getCitiesRanking(regionId, period: periodToUse);
      }
      
      // Если население = 0, пытаемся получить его из локальной базы данных
      for (int i = 0; i < cities.length; i++) {
        if (cities[i].population == 0) {
          try {
            final settlement = await _settlementsService.findSettlementById(cities[i].id);
            if (settlement != null && settlement.population > 0) {
              cities[i] = CityMood(
                id: cities[i].id,
                name: cities[i].name,
                regionId: cities[i].regionId,
                averageMood: cities[i].averageMood,
                totalCheckIns: cities[i].totalCheckIns,
                population: settlement.population,
                lastUpdate: cities[i].lastUpdate,
              );
            } else {
              // Если не нашли по ID, пытаемся найти по имени и regionId
              final regionCities = await _settlementsService.getRegionCities(regionId);
              final foundSettlement = regionCities.firstWhere(
                (s) => s.name.toLowerCase() == cities[i].name.toLowerCase(),
                orElse: () => Settlement(id: '', name: '', type: '', population: 0),
              );
              if (foundSettlement.population > 0) {
                cities[i] = CityMood(
                  id: cities[i].id,
                  name: cities[i].name,
                  regionId: cities[i].regionId,
                  averageMood: cities[i].averageMood,
                  totalCheckIns: cities[i].totalCheckIns,
                  population: foundSettlement.population,
                  lastUpdate: cities[i].lastUpdate,
                );
              }
            }
          } catch (e) {
            // Игнорируем ошибки при поиске населения
            if (kDebugMode) {
              print('Не удалось получить население для ${cities[i].name}: $e');
            }
          }
        }
      }
      
      _cities = cities;
      _errorCities = null;
    } catch (e) {
      _errorCities = e.toString();
      _cities = [];
    } finally {
      _isLoadingCities = false;
      notifyListeners();
    }
  }

  /// Загрузить рейтинг районов города
  Future<void> loadDistrictsRanking(String cityId, {String? period}) async {
    _isLoadingDistricts = true;
    _errorDistricts = null;
    notifyListeners();

    try {
      final periodToUse = period ?? _selectedPeriod;
      List<DistrictMood> districts;
      
      if (useMocks) {
        await Future.delayed(const Duration(milliseconds: 300));
        districts = MockService.generateMockDistricts(cityId, period: periodToUse);
      } else {
        districts = await _apiService.getDistrictsRanking(cityId, period: periodToUse);
      }
      
      _districts = districts;
      _errorDistricts = null;
    } catch (e) {
      _errorDistricts = e.toString();
      _districts = [];
    } finally {
      _isLoadingDistricts = false;
      notifyListeners();
    }
  }

  /// Загрузить рейтинг федеральных округов
  Future<void> loadFederalDistrictsRanking({String? period}) async {
    // Предотвращаем повторные вызовы, если уже загружается
    if (_isLoadingFederalDistricts) return;
    
    _isLoadingFederalDistricts = true;
    _errorFederalDistricts = null;
    notifyListeners();

    try {
      final periodToUse = period ?? _selectedPeriod;
      List<FederalDistrictMood> districts;
      
      if (useMocks) {
        await Future.delayed(const Duration(milliseconds: 500));
        districts = MockService.generateMockFederalDistrictsRanking(period: periodToUse);
      } else {
        districts = await _apiService.getFederalDistrictsRanking(period: periodToUse);
      }
      
      // Если население = 0, пытаемся получить его из локальной базы данных
      for (int i = 0; i < districts.length; i++) {
        if (districts[i].population == 0) {
          try {
            final districtData = await _settlementsService.loadDistrict(districts[i].name);
            if (districtData != null && districtData.population > 0) {
              districts[i] = FederalDistrictMood(
                id: districts[i].id,
                name: districts[i].name,
                averageMood: districts[i].averageMood,
                totalCheckIns: districts[i].totalCheckIns,
                population: districtData.population,
                lastUpdate: districts[i].lastUpdate,
              );
            }
          } catch (e) {
            // Игнорируем ошибки при поиске населения
            if (kDebugMode) {
              print('Не удалось получить население для ${districts[i].name}: $e');
            }
          }
        }
      }
      
      _federalDistricts = districts;
      _errorFederalDistricts = null;
    } catch (e) {
      _errorFederalDistricts = e.toString();
      _federalDistricts = [];
    } finally {
      _isLoadingFederalDistricts = false;
      notifyListeners();
    }
  }

  /// Загрузить рейтинг всех городов России
  Future<void> loadAllCitiesRanking({String? period}) async {
    // Предотвращаем повторные вызовы, если уже загружается
    if (_isLoadingAllCities) return;
    
    _isLoadingAllCities = true;
    _errorAllCities = null;
    notifyListeners();

    try {
      final periodToUse = period ?? _selectedPeriod;
      List<CityMood> cities;
      
      if (useMocks) {
        await Future.delayed(const Duration(milliseconds: 800));
        cities = await MockService.generateMockAllCitiesRanking(period: periodToUse);
      } else {
        cities = await _apiService.getAllCitiesRanking(period: periodToUse);
      }
      
      // Если население = 0, пытаемся получить его из локальной базы данных
      for (int i = 0; i < cities.length; i++) {
        if (cities[i].population == 0) {
          try {
            final settlement = await _settlementsService.findSettlementById(cities[i].id);
            if (settlement != null && settlement.population > 0) {
              cities[i] = CityMood(
                id: cities[i].id,
                name: cities[i].name,
                regionId: cities[i].regionId,
                averageMood: cities[i].averageMood,
                totalCheckIns: cities[i].totalCheckIns,
                population: settlement.population,
                lastUpdate: cities[i].lastUpdate,
              );
            } else {
              // Если не нашли по ID, пытаемся найти по имени и regionId
              final regionCities = await _settlementsService.getRegionCities(cities[i].regionId);
              final foundSettlement = regionCities.firstWhere(
                (s) => s.name.toLowerCase() == cities[i].name.toLowerCase(),
                orElse: () => Settlement(id: '', name: '', type: '', population: 0),
              );
              if (foundSettlement.population > 0) {
                cities[i] = CityMood(
                  id: cities[i].id,
                  name: cities[i].name,
                  regionId: cities[i].regionId,
                  averageMood: cities[i].averageMood,
                  totalCheckIns: cities[i].totalCheckIns,
                  population: foundSettlement.population,
                  lastUpdate: cities[i].lastUpdate,
                );
              }
            }
          } catch (e) {
            // Игнорируем ошибки при поиске населения
            if (kDebugMode) {
              print('Не удалось получить население для ${cities[i].name}: $e');
            }
          }
        }
      }
      
      _allCities = cities;
      _errorAllCities = null;
      
      if (kDebugMode) {
        final citiesWithCheckIns = cities.where((c) => c.totalCheckIns > 0).length;
        print('📊 Загружен рейтинг городов: ${cities.length} городов, с чек-инами: $citiesWithCheckIns');
      }
    } catch (e, stackTrace) {
      _errorAllCities = e.toString();
      _allCities = [];
      if (kDebugMode) {
        print('❌ Ошибка загрузки рейтинга городов: $e');
        print('   Stack trace: $stackTrace');
      }
    } finally {
      _isLoadingAllCities = false;
      notifyListeners();
    }
  }

  /// Загрузить актуальные данные о населенных пунктах из базы
  Future<void> loadSettlementsData() async {
    _isLoadingSettlementsData = true;
    notifyListeners();

    try {
      _federalDistrictsData = await _settlementsService.loadAllDistricts();
    } catch (e) {
      print('Ошибка загрузки данных о населенных пунктах: $e');
      _federalDistrictsData = [];
    } finally {
      _isLoadingSettlementsData = false;
      notifyListeners();
    }
  }

  /// Получить регион с актуальными данными
  Future<RegionData?> getRegionData(String regionId) async {
    if (_federalDistrictsData.isEmpty) {
      await loadSettlementsData();
    }
    return await _settlementsService.findRegionById(regionId);
  }

  /// Получить федеральный округ с актуальными данными
  FederalDistrictData? getFederalDistrictData(String districtName) {
    try {
      return _federalDistrictsData.firstWhere(
        (d) => d.name == districtName,
      );
    } catch (e) {
      return null;
    }
  }

  /// Получить все регионы с актуальными данными
  List<RegionData> getAllRegionsData() {
    final regions = <RegionData>[];
    for (final district in _federalDistrictsData) {
      regions.addAll(district.regions);
    }
    // Сортируем регионы по ID (номеру)
    regions.sort((a, b) => a.id.compareTo(b.id));
    return regions;
  }

  /// Получить все города региона с актуальными данными
  Future<List<Settlement>> getRegionCitiesData(String regionId) async {
    return await _settlementsService.getRegionCities(regionId);
  }

  /// Получить все округа региона с актуальными данными
  Future<List<UrbanDistrict>> getRegionDistrictsData(String regionId) async {
    return await _settlementsService.getRegionDistricts(regionId);
  }
}

