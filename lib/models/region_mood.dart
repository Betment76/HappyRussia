import 'mood_level.dart';

/// Модель региона с данными о настроении
class RegionMood {
  final String id;
  final String name;
  final double averageMood; // Средний балл настроения (1-5)
  final int totalCheckIns; // Количество чек-инов
  final int population; // Население региона
  final DateTime lastUpdate;

  RegionMood({
    required this.id,
    required this.name,
    required this.averageMood,
    required this.totalCheckIns,
    required this.population,
    required this.lastUpdate,
  });

  /// Вычислить процент счастливых людей
  double get happyPercentage {
    if (population == 0) return 0;
    // Предполагаем, что каждый чек-ин = один человек
    // Процент = (количество чек-инов / население) * 100
    return (totalCheckIns / population) * 100;
  }

  /// Получить смайлик на основе среднего настроения
  MoodLevel get moodLevel {
    if (averageMood >= 4.5) return MoodLevel.veryHappy;
    if (averageMood >= 3.5) return MoodLevel.happy;
    if (averageMood >= 2.5) return MoodLevel.neutral;
    if (averageMood >= 1.5) return MoodLevel.sad;
    return MoodLevel.verySad;
  }

  /// Создать из JSON
  factory RegionMood.fromJson(Map<String, dynamic> json) {
    return RegionMood(
      id: json['id'] as String,
      name: json['name'] as String,
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
      'averageMood': averageMood,
      'totalCheckIns': totalCheckIns,
      'population': population,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }
}

