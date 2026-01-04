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
    
    // В режиме отладки используем локальный сервер
    // Для продакшена используем productionUrl
    if (kDebugMode) {
      // Локальный бекенд для разработки
      if (kIsWeb) {
        return 'http://localhost:8000/api'; // Для веб-разработки
      } else if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000/api'; // Для Android эмулятора
        // Для реального Android устройства используйте IP вашего компьютера:
        // return 'http://192.168.1.XXX:8000/api'; // Замените XXX на IP вашего компьютера
      } else if (Platform.isIOS) {
        return 'http://localhost:8000/api'; // Для iOS симулятора
        // Для реального iOS устройства используйте IP вашего компьютера:
        // return 'http://192.168.1.XXX:8000/api'; // Замените XXX на IP вашего компьютера
      } else {
        return 'http://localhost:8000/api'; // Для других платформ
      }
    } else {
      // Продакшен
      return productionUrl;
    }
  }

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    // Увеличиваем таймауты для локальной разработки
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    
    // Логирование для отладки
    if (kDebugMode) {
      print('ApiService: Используется baseUrl = $baseUrl');
      print('ApiService: Таймауты: connect=${_dio.options.connectTimeout}, receive=${_dio.options.receiveTimeout}');
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

  /// Удалить все чек-ины (для debug режима)
  Future<void> deleteAllCheckIns() async {
    try {
      await _dio.delete('/checkins/all');
    } catch (e) {
      throw Exception('Ошибка удаления чек-инов: $e');
    }
  }
}

