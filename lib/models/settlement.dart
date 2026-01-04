/// Модель населенного пункта из базы данных
class Settlement {
  final String id;
  final String name;
  final String type; // город, поселок, село, деревня и т.д.
  final int population;

  Settlement({
    required this.id,
    required this.name,
    required this.type,
    required this.population,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'город',
      population: json['population'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'population': population,
    };
  }
}

