import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/check_in.dart';
import '../models/region_mood.dart';
import '../models/city_mood.dart';
import '../models/district_mood.dart';
import '../models/federal_district_mood.dart';

/// Сервис для работы с API
class ApiService {
  final Dio _dio = Dio();
  
  // URL бекенда
  // Автоматически определяет правильный адрес в зависимости от платформы
  static String get baseUrl {
    // Продакшен URL на Yandex Cloud
    const String productionUrl = 'https://bbas207e8gbhlpbjb51u.containers.yandexcloud.net/api';
    
    // Для разработки можно использовать локальный сервер
    // Раскомментируйте нужный вариант и закомментируйте productionUrl
    
    if (kIsWeb) {
      return productionUrl;
      // return 'http://localhost:8000/api'; // Для локальной разработки
    } else if (Platform.isAndroid) {
      return productionUrl;
      // return 'http://10.0.2.2:8000/api'; // Для Android эмулятора (локально)
    } else if (Platform.isIOS) {
      return productionUrl;
      // return 'http://localhost:8000/api'; // Для iOS симулятора (локально)
    } else {
      return productionUrl;
      // return 'http://localhost:8000/api'; // Для других платформ (локально)
    }
  }

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    
    // Логирование для отладки
    if (kDebugMode) {
      print('ApiService: Используется baseUrl = $baseUrl');
    }
  }

  /// Отправить чек-ин на сервер
  Future<void> submitCheckIn(CheckIn checkIn) async {
    try {
      await _dio.post(
        '/checkins',
        data: checkIn.toJson(),
      );
    } catch (e) {
      // В случае ошибки данные сохранятся локально и синхронизируются позже
      throw Exception('Ошибка отправки чек-ина: $e');
    }
  }

  /// Получить список регионов с рейтингом
  /// period: 'day', 'week', 'month'
  Future<List<RegionMood>> getRegionsRanking({String period = 'day'}) async {
    try {
      final response = await _dio.get(
        '/regions/ranking',
        queryParameters: {'period': period},
      );

      final List<dynamic> data = response.data;
      return data.map((json) => RegionMood.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки рейтинга регионов: $e');
    }
  }

  /// Получить статистику конкретного региона
  Future<RegionMood> getRegionStats(String regionId, {String period = 'day'}) async {
    try {
      final response = await _dio.get(
        '/regions/$regionId/stats',
        queryParameters: {'period': period},
      );

      return RegionMood.fromJson(response.data);
    } catch (e) {
      throw Exception('Ошибка загрузки статистики региона: $e');
    }
  }

  /// Синхронизировать локальные чек-ины с сервером
  Future<void> syncCheckIns(List<CheckIn> checkIns) async {
    try {
      await _dio.post(
        '/checkins/sync',
        data: checkIns.map((c) => c.toJson()).toList(),
      );
    } catch (e) {
      throw Exception('Ошибка синхронизации: $e');
    }
  }

  /// Получить список городов региона с рейтингом
  Future<List<CityMood>> getCitiesRanking(String regionId, {String period = 'day'}) async {
    try {
      final response = await _dio.get(
        '/regions/$regionId/cities/ranking',
        queryParameters: {'period': period},
      );

      final List<dynamic> data = response.data;
      return data.map((json) => CityMood.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки рейтинга городов: $e');
    }
  }

  /// Получить список районов города с рейтингом
  Future<List<DistrictMood>> getDistrictsRanking(String cityId, {String period = 'day'}) async {
    try {
      final response = await _dio.get(
        '/cities/$cityId/districts/ranking',
        queryParameters: {'period': period},
      );

      final List<dynamic> data = response.data;
      return data.map((json) => DistrictMood.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки рейтинга районов: $e');
    }
  }

  /// Получить рейтинг всех городов России
  Future<List<CityMood>> getAllCitiesRanking({String period = 'day'}) async {
    try {
      final response = await _dio.get(
        '/cities/ranking',
        queryParameters: {'period': period},
      );

      final List<dynamic> data = response.data;
      return data.map((json) => CityMood.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки рейтинга всех городов: $e');
    }
  }

  /// Получить рейтинг федеральных округов
  Future<List<FederalDistrictMood>> getFederalDistrictsRanking({String period = 'day'}) async {
    try {
      final response = await _dio.get(
        '/regions/federal-districts/ranking',
        queryParameters: {'period': period},
      );

      final List<dynamic> data = response.data;
      return data.map((json) => FederalDistrictMood.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Ошибка загрузки рейтинга федеральных округов: $e');
    }
  }
}

