import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/check_in.dart';
import '../models/region_mood.dart';

/// Сервис для локального хранения данных
class StorageService {
  static const String _checkInsKey = 'check_ins';
  static const String _regionsKey = 'regions_cache';
  static const String _lastSyncKey = 'last_sync';
  static const String _profileNameKey = 'profile_name';
  static const String _profileImagePathKey = 'profile_image_path';
  static const String _profileLocationKey = 'profile_location';
  static const String _profilePhoneKey = 'profile_phone';

  /// Сохранить чек-ин локально
  Future<void> saveCheckIn(CheckIn checkIn) async {
    final prefs = await SharedPreferences.getInstance();
    final checkInsJson = prefs.getStringList(_checkInsKey) ?? [];
    
    // Добавляем новый чек-ин
    checkInsJson.add(jsonEncode(checkIn.toJson()));
    
    await prefs.setStringList(_checkInsKey, checkInsJson);
  }

  /// Получить все локальные чек-ины
  Future<List<CheckIn>> getCheckIns() async {
    final prefs = await SharedPreferences.getInstance();
    final checkInsJson = prefs.getStringList(_checkInsKey) ?? [];
    
    return checkInsJson.map((json) {
      return CheckIn.fromJson(jsonDecode(json));
    }).toList();
  }

  /// Проверить, был ли сегодня чек-ин
  Future<bool> hasCheckInToday() async {
    final checkIns = await getCheckIns();
    final today = DateTime.now();
    
    return checkIns.any((checkIn) {
      return checkIn.date.year == today.year &&
          checkIn.date.month == today.month &&
          checkIn.date.day == today.day;
    });
  }

  /// Сохранить кэш регионов
  Future<void> saveRegionsCache(List<RegionMood> regions) async {
    final prefs = await SharedPreferences.getInstance();
    final regionsJson = regions.map((r) => jsonEncode(r.toJson())).toList();
    
    await prefs.setStringList(_regionsKey, regionsJson);
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Получить кэш регионов
  Future<List<RegionMood>> getRegionsCache() async {
    final prefs = await SharedPreferences.getInstance();
    final regionsJson = prefs.getStringList(_regionsKey) ?? [];
    
    return regionsJson.map((json) {
      return RegionMood.fromJson(jsonDecode(json));
    }).toList();
  }

  /// Получить время последней синхронизации
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString(_lastSyncKey);
    
    return lastSync != null ? DateTime.parse(lastSync) : null;
  }

  /// Очистить все данные
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Сохранить данные профиля
  Future<void> saveProfile({
    required String name,
    required String imagePath,
    required String location,
    String? phone,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Отладочный вывод
      debugPrint('StorageService.saveProfile вызван:');
      debugPrint('  Имя: $name');
      debugPrint('  Путь к фото: $imagePath');
      debugPrint('  Местоположение: $location');
      debugPrint('  Ключи: $_profileNameKey, $_profileImagePathKey, $_profileLocationKey');
      
      final nameResult = await prefs.setString(_profileNameKey, name);
      // Сохраняем путь к фото только если он не пустой
      final imageResult = imagePath.isNotEmpty 
          ? await prefs.setString(_profileImagePathKey, imagePath)
          : await prefs.remove(_profileImagePathKey);
      final locationResult = await prefs.setString(_profileLocationKey, location);
      // Сохраняем или удаляем телефон
      if (phone != null && phone.isNotEmpty) {
        await prefs.setString(_profilePhoneKey, phone);
      } else {
        await prefs.remove(_profilePhoneKey);
      }
      
      debugPrint('Результаты сохранения: name=$nameResult, image=$imageResult, location=$locationResult');
      
      // Проверяем, что данные действительно сохранились
      final savedName = prefs.getString(_profileNameKey);
      final savedImage = prefs.getString(_profileImagePathKey);
      final savedLocation = prefs.getString(_profileLocationKey);
      
      debugPrint('Проверка сохраненных данных:');
      debugPrint('  Сохраненное имя: $savedName');
      debugPrint('  Сохраненный путь: $savedImage');
      debugPrint('  Сохраненное местоположение: $savedLocation');
    } catch (e) {
      print('Ошибка при сохранении профиля: $e');
      rethrow;
    }
  }

  /// Получить имя профиля
  Future<String?> getProfileName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileNameKey);
  }

  /// Получить путь к фото профиля
  Future<String?> getProfileImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileImagePathKey);
  }

  /// Получить место регистрации
  Future<String?> getProfileLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileLocationKey);
  }

  /// Получить номер телефона профиля
  Future<String?> getProfilePhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profilePhoneKey);
  }
}

