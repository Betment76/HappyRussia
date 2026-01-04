import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/federal_district_data.dart';
import '../models/region_data.dart';
import '../models/settlement.dart';
import '../models/urban_district.dart';

/// Сервис для загрузки данных о населенных пунктах из JSON файлов
class SettlementsDataService {
  static const Map<String, String> _districtFiles = {
    'Центральный': 'central.json',
    'Северо-Западный': 'northwest.json',
    'Южный': 'south.json',
    'Северо-Кавказский': 'north_caucasus.json',
    'Приволжский': 'volga.json',
    'Уральский': 'ural.json',
    'Сибирский': 'siberian.json',
    'Дальневосточный': 'far_east.json',
  };

  /// Кэш загруженных данных
  final Map<String, FederalDistrictData> _cache = {};

  /// Загрузить все федеральные округа
  Future<List<FederalDistrictData>> loadAllDistricts() async {
    final districts = <FederalDistrictData>[];

    for (final entry in _districtFiles.entries) {
      try {
        final district = await loadDistrict(entry.key);
        if (district != null) {
          districts.add(district);
        }
      } catch (e) {
        print('Ошибка загрузки округа ${entry.key}: $e');
      }
    }

    return districts;
  }

  /// Загрузить конкретный федеральный округ
  Future<FederalDistrictData?> loadDistrict(String districtName) async {
    // Проверяем кэш
    if (_cache.containsKey(districtName)) {
      return _cache[districtName];
    }

    final fileName = _districtFiles[districtName];
    if (fileName == null) {
      print('Файл для округа $districtName не найден');
      return null;
    }

    try {
      // Загружаем из assets
      final jsonString = await rootBundle.loadString(
        'assets/districts/$fileName',
      );
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final district = FederalDistrictData.fromJson(jsonData);
      _cache[districtName] = district;
      return district;
    } catch (e) {
      print('Ошибка загрузки округа $districtName из $fileName: $e');
      return null;
    }
  }

  /// Найти регион по ID
  Future<RegionData?> findRegionById(String regionId) async {
    for (final district in await loadAllDistricts()) {
      try {
        return district.regions.firstWhere((r) => r.id == regionId);
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  /// Найти населенный пункт по ID
  Future<Settlement?> findSettlementById(String settlementId) async {
    for (final district in await loadAllDistricts()) {
      for (final region in district.regions) {
        // Проверяем города региона
        try {
          return region.cities.firstWhere((c) => c.id == settlementId);
        } catch (e) {
          // Проверяем населенные пункты в округах
          for (final urbanDistrict in region.urbanDistricts) {
            try {
              return urbanDistrict.settlements
                  .firstWhere((s) => s.id == settlementId);
            } catch (e) {
              continue;
            }
          }
        }
      }
    }
    return null;
  }

  /// Поиск населенных пунктов по названию
  Future<List<Settlement>> searchSettlements(String query) async {
    final results = <Settlement>[];
    final queryLower = query.toLowerCase().trim();

    if (queryLower.isEmpty) {
      return results;
    }

    for (final district in await loadAllDistricts()) {
      for (final region in district.regions) {
        // Ищем в городах
        for (final city in region.cities) {
          if (city.name.toLowerCase().contains(queryLower)) {
            results.add(city);
          }
        }

        // Ищем в округах
        for (final urbanDistrict in region.urbanDistricts) {
          for (final settlement in urbanDistrict.settlements) {
            if (settlement.name.toLowerCase().contains(queryLower)) {
              results.add(settlement);
            }
          }
        }
      }
    }

    // Сортируем: сначала точные совпадения, потом по населению (от большего к меньшему), потом по алфавиту
    results.sort((a, b) {
      final aStartsWith = a.name.toLowerCase().startsWith(queryLower);
      final bStartsWith = b.name.toLowerCase().startsWith(queryLower);
      if (aStartsWith && !bStartsWith) return -1;
      if (!aStartsWith && bStartsWith) return 1;
      // Если оба начинаются с запроса или оба не начинаются, сортируем по населению
      final populationCompare = b.population.compareTo(a.population);
      if (populationCompare != 0) return populationCompare;
      // Если население одинаковое, сортируем по алфавиту
      return a.name.compareTo(b.name);
    });

    return results;
  }

  /// Получить все города региона
  Future<List<Settlement>> getRegionCities(String regionId) async {
    final region = await findRegionById(regionId);
    if (region == null) return [];

    // Список названий регионов России для фильтрации (чтобы исключить населенные пункты с названиями регионов)
    final regionNames = {
      'адыгея', 'алтай', 'башкортостан', 'бурятия', 'дагестан', 'ингушетия',
      'кабардино-балкария', 'калмыкия', 'карачаево-черкесия', 'карелия', 'коми',
      'марий эл', 'мордовия', 'саха', 'якутия', 'северная осетия', 'татарстан',
      'тыва', 'удмуртия', 'хакасия', 'чечня', 'чувашия',
      'алтайский', 'краснодарский', 'красноярский', 'приморский', 'ставропольский', 'хабаровский',
      'амурская', 'архангельская', 'астраханская', 'белгородская', 'брянская', 'владимирская',
      'волгоградская', 'вологодская', 'воронежская', 'ивановская', 'иркутская', 'калининградская',
      'калужская', 'камчатский', 'кемеровская', 'кировская', 'костромская', 'курганская',
      'курская', 'ленинградская', 'липецкая', 'магаданская', 'московская', 'мурманская',
      'нижегородская', 'новгородская', 'новосибирская', 'омская', 'оренбургская', 'орловская',
      'пензенская', 'пермский', 'псковская', 'ростовская', 'рязанская', 'самарская',
      'саратовская', 'сахалинская', 'свердловская', 'смоленская', 'тамбовская', 'тверская',
      'томская', 'тульская', 'тюменская', 'ульяновская', 'челябинская', 'ярославская',
      'москва', 'санкт-петербург', 'севастополь',
      'еврейская', 'ненецкий', 'ханты-мансийский', 'чукотский', 'ямало-ненецкий'
    };

    // Используем Map для удаления дубликатов по имени+типу (так как один город может иметь разные ID)
    final citiesMap = <String, Settlement>{};
    
    // Добавляем города из списка cities региона (только тип "город" и с населением > 0)
    for (final city in region.cities) {
      // Фильтруем только города (type == 'город') с населением > 0
      if (city.type.toLowerCase() != 'город' || city.population <= 0) continue;
      
      // Исключаем населенные пункты с названиями регионов
      // НО не исключаем города федерального значения (Москва, Санкт-Петербург, Севастополь)
      final cityNameLower = city.name.toLowerCase().trim();
      final isFederalCity = region.id == '77' || region.id == '78' || region.id == '92';
      if (!isFederalCity && regionNames.contains(cityNameLower)) continue;
      
      // Используем имя+тип как ключ для удаления дубликатов
      final key = '${cityNameLower}_${city.type}';
      if (!citiesMap.containsKey(key)) {
        citiesMap[key] = city;
      } else {
        // Если город уже есть, выбираем тот, у которого больше население (более актуальные данные)
        final existing = citiesMap[key]!;
        if (city.population > existing.population) {
          citiesMap[key] = city;
        }
      }
    }
    
    // Добавляем города из округов только если в списке cities нет городов
    // Это позволяет контролировать точный список городов региона (например, для Иркутской области - 9 городов)
    final hasCitiesInList = citiesMap.isNotEmpty;
    
    if (!hasCitiesInList) {
      // Добавляем города из округов (только тип "город" и с населением > 0)
      for (final district in region.urbanDistricts) {
        for (final settlement in district.settlements) {
          // Фильтруем только города (type == 'город') с населением > 0
          if (settlement.type.toLowerCase() != 'город' || settlement.population <= 0) continue;
          
          // Исключаем населенные пункты с названиями регионов
          // НО не исключаем города федерального значения (Москва, Санкт-Петербург, Севастополь)
          final settlementNameLower = settlement.name.toLowerCase().trim();
          final isFederalCity = region.id == '77' || region.id == '78' || region.id == '92';
          if (!isFederalCity && regionNames.contains(settlementNameLower)) continue;
          
          final key = '${settlementNameLower}_${settlement.type}';
          if (!citiesMap.containsKey(key)) {
            citiesMap[key] = settlement;
          } else {
            // Если город уже есть, выбираем тот, у которого больше население
            final existing = citiesMap[key]!;
            if (settlement.population > existing.population) {
              citiesMap[key] = settlement;
            }
          }
        }
      }
    }

    // Преобразуем в список и сортируем по населению (от большего к меньшему)
    final cities = citiesMap.values.toList();
    cities.sort((a, b) => b.population.compareTo(a.population));
    return cities;
  }

  /// Получить все округа региона
  Future<List<UrbanDistrict>> getRegionDistricts(String regionId) async {
    final region = await findRegionById(regionId);
    if (region == null) return [];
    // Исключаем из списка районов:
    // - "Города области"
    // - Названия, которые начинаются с "город " (например, "город Белгород")
    // - Названия, которые равны "город"
    return region.urbanDistricts.where((district) {
      final nameLower = district.name.toLowerCase().trim();
      return district.name != 'Города области' && 
             nameLower != 'город' &&
             !nameLower.startsWith('город ');
    }).toList();
  }

  /// Очистить кэш
  void clearCache() {
    _cache.clear();
  }
}

