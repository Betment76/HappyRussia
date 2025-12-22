import 'mood_level.dart';

/// Модель ежедневного чек-ина настроения
class CheckIn {
  final String id;
  final String regionId;
  final String regionName;
  final MoodLevel mood;
  final DateTime date;
  final String? userId; // Опционально для истории
  
  // Информация о городе или населенном пункте
  final String? cityId; // ID города (если есть в RegionCitiesData)
  final String? cityName; // Название города или населенного пункта
  final String? federalDistrict; // Федеральный округ
  final String? district; // Район (если это населенный пункт, а не город)

  CheckIn({
    required this.id,
    required this.regionId,
    required this.regionName,
    required this.mood,
    required this.date,
    this.userId,
    this.cityId,
    this.cityName,
    this.federalDistrict,
    this.district,
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
      cityId: json['cityId'] as String?,
      cityName: json['cityName'] as String?,
      federalDistrict: json['federalDistrict'] as String?,
      district: json['district'] as String?,
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
      'cityId': cityId,
      'cityName': cityName,
      'federalDistrict': federalDistrict,
      'district': district,
    };
  }
}

