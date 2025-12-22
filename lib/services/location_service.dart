import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../data/russian_regions.dart';

/// Модель местоположения пользователя
class UserLocation {
  final String? federalDistrict; // Федеральный округ
  final String? region; // Регион
  final String? district; // Район (если есть)
  final String? city; // Город (если есть)
  final String? settlement; // Населенный пункт

  UserLocation({
    this.federalDistrict,
    this.region,
    this.district,
    this.city,
    this.settlement,
  });

  /// Форматированная строка местоположения
  String get formattedLocation {
    final parts = <String>[];
    if (federalDistrict != null) parts.add(federalDistrict!);
    if (region != null) parts.add(region!);
    
    // Если есть город, показываем только город (без района)
    if (city != null) {
      parts.add(city!);
    } 
    // Если есть село/деревня/поселок, показываем район и населенный пункт
    else if (settlement != null) {
      if (district != null) {
        parts.add(district!);
      }
      parts.add(settlement!);
    }
    // Если есть только район (без населенного пункта)
    else if (district != null) {
      parts.add(district!);
    }
    
    return parts.join(' - ');
  }

  bool get isValid => federalDistrict != null && region != null;
}

/// Сервис для работы с геолокацией
class LocationService {
  /// Проверить разрешения на геолокацию
  Future<String?> checkPermissions() async {
    // Проверяем, включен ли GPS
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return 'GPS не включен. Пожалуйста, включите GPS в настройках устройства.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return 'Разрешение на геолокацию не предоставлено. Пожалуйста, разрешите доступ к местоположению в настройках приложения.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return 'Разрешение на геолокацию заблокировано. Пожалуйста, разрешите доступ к местоположению в настройках приложения.';
    }

    return null; // Все в порядке
  }

  /// Получить текущую позицию
  Future<Position> getCurrentPosition() async {
    final permissionError = await checkPermissions();
    if (permissionError != null) {
      throw Exception(permissionError);
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15), // Таймаут 15 секунд
      );
    } catch (e) {
      if (e.toString().contains('timeout') || e.toString().contains('TIMEOUT')) {
        throw Exception('Превышено время ожидания GPS сигнала. Убедитесь, что вы находитесь на открытой местности и GPS включен.');
      }
      throw Exception('Ошибка получения координат: $e');
    }
  }

  /// Получить полное местоположение по координатам
  Future<UserLocation> getLocationFromCoordinates(double lat, double lon) async {
    try {
      // Убираем localeIdentifier, так как он вызывает ошибку UnknownFormatConversionException на некоторых устройствах
      List<Placemark> placemarks;
      try {
        placemarks = await placemarkFromCoordinates(
          lat, 
          lon,
          // Не используем localeIdentifier из-за ошибки на некоторых устройствах Samsung/Android
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('Превышено время ожидания определения адреса. Проверьте подключение к интернету.'),
        );
      } catch (e) {
        debugPrint('Ошибка геокодирования: $e');
        // Если ошибка форматирования (известная проблема на некоторых устройствах Samsung/Android)
        if (e.toString().contains('UnknownFormatConversionException') || 
            e.toString().contains('Conversion') ||
            e.toString().contains('Format')) {
          // Пробуем еще раз с задержкой
          await Future.delayed(const Duration(milliseconds: 1000));
          try {
            placemarks = await placemarkFromCoordinates(lat, lon).timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw Exception('Превышено время ожидания определения адреса. Проверьте подключение к интернету.'),
            );
          } catch (e2) {
            // Если все еще ошибка, возвращаем базовую информацию только по координатам
            debugPrint('Повторная ошибка геокодирования: $e2');
            throw Exception('Не удалось определить адрес. Координаты: $lat, $lon. Попробуйте еще раз или проверьте подключение к интернету.');
          }
        } else {
          rethrow;
        }
      }
      
      if (placemarks.isEmpty) {
        throw Exception('Не удалось определить адрес по координатам. Проверьте подключение к интернету.');
      }

      final placemark = placemarks.first;
      
      // Проверяем, что это Россия
      final country = placemark.country?.toLowerCase() ?? '';
      final isRussia = country.contains('russia') || 
                       country.contains('россия') || 
                       country.contains('ru') ||
                       country.contains('russian federation');
      
      if (!isRussia) {
        throw Exception('Местоположение определено вне территории России. Убедитесь, что GPS настроен правильно или используйте реальное устройство для тестирования.');
      }
      
      // Получаем регион из administrativeArea
      String? regionName = placemark.administrativeArea;
      if (regionName == null || regionName.isEmpty) {
        regionName = placemark.country; // Fallback
      }

      // Находим регион в нашей базе данных
      Map<String, String>? regionData;
      if (regionName != null) {
        // Пробуем найти точное совпадение
        regionData = RussianRegions.findByName(regionName);
        
        // Если не нашли, пробуем найти по частичному совпадению
        if (regionData == null) {
          // Убираем лишние слова (область, край, республика и т.д.)
          final cleanName = regionName
              .replaceAll(RegExp(r'\s*(область|край|республика|автономный округ|АО|г\.|город)\s*', caseSensitive: false), '')
              .trim();
          
          for (var region in RussianRegions.getAll()) {
            final regionFullName = region['name'] ?? '';
            if (regionFullName.toLowerCase().contains(cleanName.toLowerCase()) ||
                cleanName.toLowerCase().contains(regionFullName.toLowerCase().split(' ').first)) {
              regionData = region;
              break;
            }
          }
        }
      }

      // Определяем федеральный округ
      String? federalDistrict;
      if (regionData != null) {
        federalDistrict = regionData['federalDistrict'];
      }

      // Район области/края
      String? district = placemark.subAdministrativeArea;
      if (district != null && district.isEmpty) {
        district = null;
      }

      // Город
      String? city = placemark.locality;
      if (city != null && city.isEmpty) {
        city = null;
      }

      // Населенный пункт (поселок, деревня, село и т.д.)
      String? settlement = placemark.subLocality;
      if (settlement == null || settlement.isEmpty) {
        settlement = placemark.name;
      }
      if (settlement != null && settlement.isEmpty) {
        settlement = null;
      }

      // Определяем, является ли населенный пункт городом
      // Если есть city (locality), то это город, и район не показываем
      // Если city нет, но есть settlement, то это село/деревня/поселок, и район показываем
      String? finalDistrict;
      String? finalCity;
      String? finalSettlement;

      if (city != null) {
        // Это город - район не показываем
        finalCity = city;
        finalSettlement = null;
        finalDistrict = null;
      } else if (settlement != null) {
        // Это село/деревня/поселок - показываем район
        finalCity = null;
        finalSettlement = settlement;
        finalDistrict = district;
      } else {
        // Не удалось определить
        finalCity = city;
        finalSettlement = settlement;
        finalDistrict = district;
      }

      return UserLocation(
        federalDistrict: federalDistrict,
        region: regionData?['name'] ?? regionName,
        district: finalDistrict,
        city: finalCity,
        settlement: finalSettlement,
      );
    } catch (e) {
      debugPrint('Критическая ошибка определения местоположения: $e');
      // При любой ошибке геокодирования используем fallback метод
      debugPrint('Используем альтернативный метод определения региона по координатам');
      return _getLocationFromCoordinatesFallback(lat, lon);
    }
  }

  /// Альтернативный метод определения региона по координатам (без геокодирования)
  UserLocation _getLocationFromCoordinatesFallback(double lat, double lon) {
    // Известные координаты столиц регионов для определения региона по ближайшей столице
    // Иркутск: 52.2864, 104.2807
    // Определяем регион по известным координатам крупных городов
    final regionByCoordinates = _findRegionByCoordinates(lat, lon);
    
    if (regionByCoordinates != null) {
      // В fallback методе определяем только город (столицу региона)
      // Район не показываем, так как это город
      return UserLocation(
        federalDistrict: regionByCoordinates['federalDistrict'],
        region: regionByCoordinates['name'],
        city: regionByCoordinates['capital'],
        district: null, // Для городов район не показываем
        settlement: null,
      );
    }
    
    // Если не нашли, возвращаем базовую информацию
    throw Exception('Не удалось определить регион по координатам. Координаты: $lat, $lon');
  }

  /// Найти регион по координатам используя известные координаты столиц
  Map<String, String>? _findRegionByCoordinates(double lat, double lon) {
    // Координаты столиц некоторых регионов (можно расширить)
    final cityCoordinates = <String, Map<String, double>>{
      '38': {'lat': 52.2864, 'lon': 104.2807}, // Иркутская область
      '77': {'lat': 55.7558, 'lon': 37.6173}, // Москва
      '78': {'lat': 59.9343, 'lon': 30.3351}, // Санкт-Петербург
      '66': {'lat': 56.8431, 'lon': 60.6454}, // Свердловская область
      '54': {'lat': 55.0084, 'lon': 82.9357}, // Новосибирская область
      '23': {'lat': 45.0355, 'lon': 38.9753}, // Краснодарский край
      '16': {'lat': 55.8304, 'lon': 49.0661}, // Татарстан
    };

    // Находим ближайший город
    double minDistance = double.infinity;
    String? closestRegionId;

    for (var entry in cityCoordinates.entries) {
      final cityLat = entry.value['lat']!;
      final cityLon = entry.value['lon']!;
      
      // Вычисляем расстояние (упрощенная формула)
      final distance = (lat - cityLat).abs() + (lon - cityLon).abs();
      
      if (distance < minDistance) {
        minDistance = distance;
        closestRegionId = entry.key;
      }
    }

    // Если расстояние слишком большое, пробуем определить по широте/долготе
    if (minDistance > 5.0) {
      // Иркутск примерно 52.28, 104.28
      if (lat >= 51.0 && lat <= 54.0 && lon >= 102.0 && lon <= 107.0) {
        closestRegionId = '38'; // Иркутская область
      }
    }

    if (closestRegionId != null) {
      return RussianRegions.findById(closestRegionId);
    }

    return null;
  }

  /// Получить регион по координатам
  Future<String?> getRegionFromCoordinates(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        // В России административный район обычно в administrativeArea
        return placemarks.first.administrativeArea;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Получить регион пользователя
  Future<String?> getUserRegion() async {
    try {
      final position = await getCurrentPosition();
      return await getRegionFromCoordinates(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      return null;
    }
  }

  /// Получить полное местоположение пользователя
  Future<UserLocation> getUserLocation() async {
    try {
      final position = await getCurrentPosition();
      debugPrint('Получены координаты: ${position.latitude}, ${position.longitude}');
      
      // Пробуем геокодирование с таймаутом
      try {
        return await getLocationFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('Таймаут геокодирования, используем fallback');
            throw Exception('timeout');
          },
        );
      } catch (e) {
        debugPrint('Ошибка геокодирования координат: $e');
        // При любой ошибке геокодирования используем fallback метод
        debugPrint('Используем альтернативный метод определения региона по координатам');
        return _getLocationFromCoordinatesFallback(
          position.latitude,
          position.longitude,
        );
      }
    } catch (e) {
      debugPrint('Финальная ошибка getUserLocation: $e');
      rethrow;
    }
  }
}

