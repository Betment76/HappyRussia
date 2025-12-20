import 'package:dio/dio.dart';
import '../models/check_in.dart';
import '../models/region_mood.dart';
import '../models/city_mood.dart';
import '../models/district_mood.dart';

/// Сервис для работы с API
class ApiService {
  final Dio _dio = Dio();
  
  // TODO: Заменить на реальный URL YandexCloud
  static const String baseUrl = 'https://your-api.yandexcloud.net/api';

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
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
}

