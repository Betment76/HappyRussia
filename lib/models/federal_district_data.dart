import 'region_data.dart';

/// Модель федерального округа из базы данных
class FederalDistrictData {
  final String name;
  final int population;
  final List<RegionData> regions;

  FederalDistrictData({
    required this.name,
    required this.population,
    required this.regions,
  });

  factory FederalDistrictData.fromJson(Map<String, dynamic> json) {
    final regions = (json['regions'] as List<dynamic>?)
            ?.map((r) => RegionData.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];
    // Сортируем регионы по ID (номеру)
    regions.sort((a, b) => a.id.compareTo(b.id));
    
    return FederalDistrictData(
      name: json['name'] as String? ?? '',
      population: json['population'] as int? ?? 0,
      regions: regions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'population': population,
      'regions': regions.map((r) => r.toJson()).toList(),
    };
  }

  /// Получить все регионы отсортированные по названию
  List<RegionData> get sortedRegions {
    final sorted = List<RegionData>.from(regions);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }
}

