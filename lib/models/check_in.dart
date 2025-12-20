import 'mood_level.dart';

/// Модель ежедневного чек-ина настроения
class CheckIn {
  final String id;
  final String regionId;
  final String regionName;
  final MoodLevel mood;
  final DateTime date;
  final String? userId; // Опционально для истории

  CheckIn({
    required this.id,
    required this.regionId,
    required this.regionName,
    required this.mood,
    required this.date,
    this.userId,
  });

  /// Создать из JSON
  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      id: json['id'] as String,
      regionId: json['regionId'] as String,
      regionName: json['regionName'] as String,
      mood: MoodLevel.values.firstWhere(
        (e) => e.value == json['mood'] as int,
      ),
      date: DateTime.parse(json['date'] as String),
      userId: json['userId'] as String?,
    );
  }

  /// Преобразовать в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'regionId': regionId,
      'regionName': regionName,
      'mood': mood.value,
      'date': date.toIso8601String(),
      'userId': userId,
    };
  }
}

