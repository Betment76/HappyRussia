import 'settlement.dart';

/// Модель городского округа/района из базы данных
class UrbanDistrict {
  final String name;
  final int population;
  final List<Settlement> settlements;

  UrbanDistrict({
    required this.name,
    required this.population,
    required this.settlements,
  });

  factory UrbanDistrict.fromJson(Map<String, dynamic> json) {
    return UrbanDistrict(
      name: json['name'] as String? ?? '',
      population: json['population'] as int? ?? 0,
      settlements: (json['settlements'] as List<dynamic>?)
              ?.map((s) => Settlement.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'population': population,
      'settlements': settlements.map((s) => s.toJson()).toList(),
    };
  }

  /// Получить только города из округа
  List<Settlement> get cities {
    return settlements.where((s) => s.type == 'город').toList();
  }

  /// Получить все населенные пункты кроме городов
  List<Settlement> get otherSettlements {
    return settlements.where((s) => s.type != 'город').toList();
  }
}

