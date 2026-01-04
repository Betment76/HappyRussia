import 'settlement.dart';
import 'urban_district.dart';

/// Модель региона из базы данных
class RegionData {
  final String id;
  final String name;
  final int population;
  final String federalDistrict;
  final List<Settlement> cities;
  final List<UrbanDistrict> urbanDistricts;

  RegionData({
    required this.id,
    required this.name,
    required this.population,
    required this.federalDistrict,
    required this.cities,
    required this.urbanDistricts,
  });

  factory RegionData.fromJson(Map<String, dynamic> json) {
    return RegionData(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      population: json['population'] as int? ?? 0,
      federalDistrict: json['federal_district'] as String? ?? '',
      cities: (json['cities'] as List<dynamic>?)
              ?.map((c) => Settlement.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      urbanDistricts: (json['urban_districts'] as List<dynamic>?)
              ?.map((ud) => UrbanDistrict.fromJson(ud as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'population': population,
      'federal_district': federalDistrict,
      'cities': cities.map((c) => c.toJson()).toList(),
      'urban_districts': urbanDistricts.map((ud) => ud.toJson()).toList(),
    };
  }

  /// Получить все населенные пункты региона (города + из округов)
  List<Settlement> getAllSettlements() {
    final allSettlements = <Settlement>[...cities];
    for (final district in urbanDistricts) {
      allSettlements.addAll(district.settlements);
    }
    return allSettlements;
  }

  /// Получить общее количество населенных пунктов
  int get totalSettlementsCount {
    return cities.length +
        urbanDistricts.fold(0, (sum, district) => sum + district.settlements.length);
  }

  /// Получить список районов без "Города области" и городов
  List<UrbanDistrict> get filteredDistricts {
    // Исключаем из списка районов:
    // - "Города области"
    // - Названия, которые начинаются с "город " (например, "город Белгород")
    // - Названия, которые равны "город"
    return urbanDistricts.where((district) {
      final nameLower = district.name.toLowerCase().trim();
      return district.name != 'Города области' && 
             nameLower != 'город' &&
             !nameLower.startsWith('город ');
    }).toList();
  }
}

