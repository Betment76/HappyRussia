import 'package:flutter/foundation.dart';
import '../models/region_mood.dart';
import '../models/city_mood.dart';
import '../models/district_mood.dart';
import '../models/federal_district_mood.dart';
import '../models/check_in.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/mock_service.dart';

/// Провайдер для управления состоянием настроения
class MoodProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  
  // Флаг для использования моков (true = моки, false = реальный API)
  static const bool useMocks = true; // TODO: Переключить на false когда бекенд готов

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

  /// Загрузить рейтинг регионов
  Future<void> loadRegionsRanking({String? period}) async {
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
    try {
      // Сохраняем локально
      await _storageService.saveCheckIn(checkIn);
      
      if (useMocks) {
        // В режиме моков просто имитируем отправку
        await Future.delayed(const Duration(milliseconds: 300));
      } else {
        // Отправляем на сервер
        await _apiService.submitCheckIn(checkIn);
      }
      
      // Обновляем рейтинг
      await loadRegionsRanking();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Проверить, был ли сегодня чек-ин
  Future<bool> hasCheckInToday() async {
    return await _storageService.hasCheckInToday();
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
        // TODO: Добавить метод в ApiService
        districts = MockService.generateMockFederalDistrictsRanking(period: periodToUse);
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
        // TODO: Добавить метод в ApiService
        cities = await MockService.generateMockAllCitiesRanking(period: periodToUse);
      }
      
      _allCities = cities;
      _errorAllCities = null;
    } catch (e) {
      _errorAllCities = e.toString();
      _allCities = [];
    } finally {
      _isLoadingAllCities = false;
      notifyListeners();
    }
  }
}

