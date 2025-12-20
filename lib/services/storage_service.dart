import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/check_in.dart';
import '../models/region_mood.dart';

/// Сервис для локального хранения данных
class StorageService {
  static const String _checkInsKey = 'check_ins';
  static const String _regionsKey = 'regions_cache';
  static const String _lastSyncKey = 'last_sync';

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
}

