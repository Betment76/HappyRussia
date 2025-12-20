import 'mood_level.dart';

/// Модель города с данными о настроении
class CityMood {
  final String id;
  final String name;
  final String regionId;
  final double averageMood; // Средний балл настроения (1-5)
  final int totalCheckIns; // Количество чек-инов
  final int population; // Население города
  final DateTime lastUpdate;

  CityMood({
    required this.id,
    required this.name,
    required this.regionId,
    required this.averageMood,
    required this.totalCheckIns,
    required this.population,
    required this.lastUpdate,
  });

  /// Получить смайлик на основе среднего настроения
  MoodLevel get moodLevel {
    if (averageMood >= 4.5) return MoodLevel.veryHappy;
    if (averageMood >= 3.5) return MoodLevel.happy;
    if (averageMood >= 2.5) return MoodLevel.neutral;
    if (averageMood >= 1.5) return MoodLevel.sad;
    return MoodLevel.verySad;
  }

  /// Вычислить процент счастливых людей
  double get happyPercentage {
    if (population == 0) return 0;
    return (totalCheckIns / population) * 100;
  }

  /// Создать из JSON
  factory CityMood.fromJson(Map<String, dynamic> json) {
    return CityMood(
      id: json['id'] as String,
      name: json['name'] as String,
      regionId: json['regionId'] as String,
      averageMood: (json['averageMood'] as num).toDouble(),
      totalCheckIns: json['totalCheckIns'] as int,
      population: json['population'] as int? ?? 0,
      lastUpdate: DateTime.parse(json['lastUpdate'] as String),
    );
  }

  /// Преобразовать в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'regionId': regionId,
      'averageMood': averageMood,
      'totalCheckIns': totalCheckIns,
      'population': population,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }
}

