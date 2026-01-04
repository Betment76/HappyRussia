import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../providers/mood_provider.dart';
import '../models/city_mood.dart';
import '../models/settlement.dart';
import '../widgets/mood_cards.dart';

/// Экран со всеми населенными пунктами России (города, сёла, деревни и т.д.)
class AllCitiesScreen extends StatefulWidget {
  const AllCitiesScreen({super.key});

  @override
  State<AllCitiesScreen> createState() => _AllCitiesScreenState();
}

class _AllCitiesScreenState extends State<AllCitiesScreen> {
  List<Settlement> _allSettlements = [];
  Map<String, String> _settlementToRegion = {}; // Маппинг: settlement.id -> region.name
  bool _isLoadingData = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<MoodProvider>();
    
    // ВАЖНО: Не вызываем setState() или notifyListeners() во время build
    // Используем addPostFrameCallback для выполнения после завершения сборки
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // Всегда обновляем рейтинг городов при возврате на экран
      // Это нужно для обновления данных после чек-ина
      provider.loadAllCitiesRanking();
      
      // Перезагружаем settlements, чтобы включить новые города с чек-инами
      if (provider.federalDistrictsData.isNotEmpty && !_isLoadingData) {
        setState(() {
          _isLoadingData = true;
        });
        _loadAllSettlements(provider);
      } else if (_allSettlements.isEmpty && !_isLoadingData) {
        setState(() {
          _isLoadingData = true;
        });
        // Загружаем settlements асинхронно
        if (provider.federalDistrictsData.isEmpty) {
          provider.loadSettlementsData().then((_) {
            if (mounted) {
              _loadAllSettlements(provider);
            }
          });
        } else {
          _loadAllSettlements(provider);
        }
      }
    });
  }

  Future<void> _refreshData() async {
    final provider = context.read<MoodProvider>();
    // Загружаем статические данные о населенных пунктах
    await provider.loadSettlementsData();
    // Загружаем settlements асинхронно
    await _loadAllSettlements(provider);
    // Загружаем рейтинг городов (для смайликов и прогресс-бара) параллельно
    provider.loadAllCitiesRanking();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Фильтрация населённых пунктов по поисковому запросу
  List<Settlement> get _filteredSettlements {
    if (_searchQuery.isEmpty) {
      return _allSettlements;
    }
    // Ищем только по имени населенного пункта, НЕ по региону и типу
    // Поиск по региону слишком широкий и находит лишние города
    final queryLower = _searchQuery.toLowerCase().trim();
    debugPrint('🔍 Фильтрация по запросу "$queryLower":');
    debugPrint('   Всего settlements в _allSettlements: ${_allSettlements.length}');
    
    final results = _allSettlements.where((settlement) {
      final nameLower = settlement.name.toLowerCase();
      final matches = nameLower.contains(queryLower);
      
      if (nameLower == 'иркутск' || (queryLower == 'иркутск' && nameLower.contains('иркутск'))) {
        debugPrint('   🔍 Проверка "${settlement.name}": matches=$matches');
      }
      
      return matches;
    }).toList();
    
    debugPrint('   Найдено settlements: ${results.length}');
    if (queryLower == 'иркутск') {
      debugPrint('   Результаты поиска "иркутск": ${results.map((s) => '${s.name} (ID: ${s.id})').join(', ')}');
    }
    
    // Сортируем: сначала точные совпадения (начинаются с запроса), потом остальные
    // Это нужно, чтобы при поиске "иркутск" сначала показывался "Иркутск", а не "Иркутский" или "Иркутское"
    results.sort((a, b) {
      final aName = a.name.toLowerCase();
      final bName = b.name.toLowerCase();
      final aStartsWith = aName.startsWith(queryLower);
      final bStartsWith = bName.startsWith(queryLower);
      
      if (aStartsWith && !bStartsWith) return -1;
      if (!aStartsWith && bStartsWith) return 1;
      
      // Если оба начинаются или оба не начинаются - сортируем по длине имени (короткие первыми)
      // Это нужно, чтобы "Иркутск" был выше "Иркутский" или "Иркутское"
      return aName.length.compareTo(bName.length);
    });
    
    return results;
  }

  Future<void> _loadAllSettlements(MoodProvider provider) async {
    // Выполняем тяжелую обработку данных асинхронно
    await Future(() {
      final allRegions = provider.getAllRegionsData();
      
      // Используем Map для удаления дубликатов по имени+типу
      // Ключ: имя_тип, значение: Settlement (выбираем с наибольшим населением)
      final settlementsMap = <String, Settlement>{};  
      final regionMap = <String, String>{}; // Маппинг: settlement.id -> region.name
      
      for (final region in allRegions) {
        // Добавляем города региона
        for (final city in region.cities) {
          if (city.population <= 0) continue; // Пропускаем без населения
          final key = '${city.name.toLowerCase().trim()}_${city.type.toLowerCase().trim()}';
          final existing = settlementsMap[key];
          if (existing == null || city.population > existing.population) {
            // Если заменяем существующую запись, удаляем старое название региона
            if (existing != null) {
              regionMap.remove(existing.id);
            }
            settlementsMap[key] = city;
            regionMap[city.id] = region.name;
          }
        }
        
        // Добавляем населенные пункты из районов
        for (final district in region.urbanDistricts) {
          for (final settlement in district.settlements) {
            if (settlement.population <= 0) continue; // Пропускаем без населения
            final key = '${settlement.name.toLowerCase().trim()}_${settlement.type.toLowerCase().trim()}';
            final existing = settlementsMap[key];
            if (existing == null || settlement.population > existing.population) {
              // Если заменяем существующую запись, удаляем старое название региона
              if (existing != null) {
                regionMap.remove(existing.id);
              }
              settlementsMap[key] = settlement;
              regionMap[settlement.id] = region.name;
            }
          }
        }
      }
      
      // Преобразуем в список
      final allSettlements = settlementsMap.values.toList();
      
      if (mounted) {
        setState(() {
          _allSettlements = allSettlements;
          _settlementToRegion = regionMap;
          _isLoadingData = false;
        });
      }
    });
  }

  /// Построить отсортированный список городов
  /// Этот метод вызывается внутри Consumer, поэтому автоматически обновляется при изменении provider.allCities
  Widget _buildSortedCitiesList(MoodProvider provider) {
    // Используем кэшированный список для сортировки
    var sortedSettlements = _filteredSettlements;
    
    // Если есть поисковый запрос, также ищем в provider.allCities
    if (_searchQuery.isNotEmpty) {
      debugPrint('🔍 Поиск по запросу: "$_searchQuery"');
      debugPrint('   Всего городов в provider.allCities: ${provider.allCities.length}');
      debugPrint('   Города с чек-инами: ${provider.allCities.where((c) => c.totalCheckIns > 0).map((c) => '${c.name} (${c.totalCheckIns})').join(', ')}');
      
      // Ищем только по имени города, НЕ по региону (чтобы не находить лишние города)
      // ВАЖНО: Используем toLowerCase() для обоих значений, чтобы поиск был регистронезависимым
      final searchQueryLower = _searchQuery.toLowerCase().trim();
      final citiesFromProvider = provider.allCities.where((city) {
        final cityNameLower = city.name.toLowerCase().trim();
        // Проверяем точное совпадение или начало имени
        final nameMatch = cityNameLower.contains(searchQueryLower);
        
        if (nameMatch) {
          debugPrint('   ✅ Найден в provider.allCities по имени: ${city.name} (ID: ${city.id}, totalCheckIns: ${city.totalCheckIns})');
        }
        
        return nameMatch; // Только по имени, не по региону
      }).toList();
      
      debugPrint('   Найдено городов в provider.allCities: ${citiesFromProvider.length}');
      
      // Добавляем города из provider.allCities, которых нет в sortedSettlements
      for (final cityMood in citiesFromProvider) {
        final exists = sortedSettlements.any((s) => 
          s.id == cityMood.id || 
          (s.name.toLowerCase() == cityMood.name.toLowerCase() && 
           s.id.split('-').first == cityMood.regionId)
        );
        
        if (!exists) {
          // Создаем Settlement из CityMood
          try {
            final regionData = provider.getAllRegionsData().firstWhere(
              (r) => r.id == cityMood.regionId,
            );
            
            String settlementType = 'город';
            // Пытаемся найти тип в статических данных
            try {
              final city = regionData.cities.firstWhere(
                (c) => c.id == cityMood.id || c.name.toLowerCase() == cityMood.name.toLowerCase(),
              );
              settlementType = city.type;
            } catch (e) {
              // Ищем в округах
              for (final district in regionData.urbanDistricts) {
                try {
                  final settlement = district.settlements.firstWhere(
                    (s) => s.id == cityMood.id || s.name.toLowerCase() == cityMood.name.toLowerCase(),
                  );
                  settlementType = settlement.type;
                  break;
                } catch (e) {
                  // Продолжаем поиск
                }
              }
            }
            
            sortedSettlements.add(Settlement(
              id: cityMood.id,
              name: cityMood.name,
              type: settlementType,
              population: cityMood.population > 0 ? cityMood.population : 0,
            ));
            
            // Добавляем в маппинг региона
            _settlementToRegion[cityMood.id] = regionData.name;
          } catch (e) {
            debugPrint('⚠️ Не удалось добавить город ${cityMood.name} из provider.allCities: $e');
          }
        }
      }
    }
    
    // Создаем Set для быстрой проверки наличия settlement по ID
    final existingSettlementIds = sortedSettlements.map((s) => s.id).toSet();
    
    // Добавляем города из provider.allCities, которых нет в settlements, но у которых есть чек-ины
    // ВАЖНО: При поиске НЕ добавляем города, которые не соответствуют запросу
    // Это нужно только для обычного отображения (без поиска), чтобы города с чек-инами появлялись в топе
    final additionalSettlements = <Settlement>[];
    final additionalRegionNames = <String, String>{}; // Маппинг для дополнительных городов
    
    // Добавляем города с чек-инами только если НЕТ поискового запроса
    // При поиске города уже добавлены выше (строки 194-262), если они соответствуют запросу
    if (_searchQuery.isEmpty) {
      // Логирование только если есть города с чек-инами
      final citiesWithCheckIns = provider.allCities.where((c) => c.totalCheckIns > 0).toList();
      if (citiesWithCheckIns.isNotEmpty) {
        debugPrint('🔍 Проверка городов с чек-инами для добавления в список (без поиска):');
        debugPrint('   Всего городов в provider.allCities: ${provider.allCities.length}');
        debugPrint('   Города с чек-инами: ${citiesWithCheckIns.map((c) => '${c.name} (ID: ${c.id}, totalCheckIns: ${c.totalCheckIns})').join(', ')}');
      }
      
      for (final cityMood in provider.allCities) {
        // Добавляем только города с чек-инами, которых нет в списке
        final hasCheckIns = cityMood.totalCheckIns > 0;
        final existsInListById = existingSettlementIds.contains(cityMood.id);
        // Также проверяем по имени и regionId (на случай, если ID отличается)
        final existsInListByName = sortedSettlements.any((s) => 
          s.name.toLowerCase().trim() == cityMood.name.toLowerCase().trim() &&
          s.id.split('-').first == cityMood.regionId
        );
        final existsInList = existsInListById || existsInListByName;
        
        if (hasCheckIns && !existsInList) {
          // Логирование только при добавлении нового города
          debugPrint('   ➕ Добавляем город с чек-ином: ${cityMood.name} (ID: ${cityMood.id}, totalCheckIns: ${cityMood.totalCheckIns})');
          // Пытаемся найти тип населенного пункта и название региона в статических данных
          String settlementType = 'город'; // По умолчанию
          String? regionName;
          try {
            final regionData = provider.getAllRegionsData().firstWhere(
              (r) => r.id == cityMood.regionId,
            );
            regionName = regionData.name;
            // Ищем в городах региона
            try {
              final settlement = regionData.cities.firstWhere(
                (s) => s.id == cityMood.id || 
                       (s.name.toLowerCase().trim() == cityMood.name.toLowerCase().trim()),
              );
              settlementType = settlement.type;
            } catch (e) {
              // Ищем в округах региона
              for (final district in regionData.urbanDistricts) {
                try {
                  final settlement = district.settlements.firstWhere(
                    (s) => s.id == cityMood.id || 
                           (s.name.toLowerCase().trim() == cityMood.name.toLowerCase().trim()),
                  );
                  settlementType = settlement.type;
                  break;
                } catch (e) {
                  // Продолжаем поиск
                }
              }
            }
          } catch (e) {
            // Если не нашли регион, используем тип по умолчанию
          }
          
          additionalSettlements.add(Settlement(
            id: cityMood.id,
            name: cityMood.name,
            type: settlementType,
            population: cityMood.population > 0 ? cityMood.population : 0,
          ));
          
          if (regionName != null) {
            additionalRegionNames[cityMood.id] = regionName;
          }
        }
      }
    }
    
    // Объединяем существующие settlements с дополнительными, убирая дубликаты
    // Создаем Map для быстрой проверки и объединения
    final settlementsMap = <String, Settlement>{};
    // Сначала добавляем все существующие settlements
    for (final settlement in sortedSettlements) {
      settlementsMap[settlement.id] = settlement;
    }
    // Затем добавляем дополнительные, только если их еще нет
    for (final settlement in additionalSettlements) {
      if (!settlementsMap.containsKey(settlement.id)) {
        settlementsMap[settlement.id] = settlement;
      }
    }
    final allSettlementsForSorting = settlementsMap.values.toList();
    
    // Получаем данные о настроении для сортировки
    // Важно: используем актуальные данные из provider.allCities
    final settlementsWithMood = allSettlementsForSorting.map((settlement) {
      CityMood? cityMood;
      // Получаем regionId из settlement.id (формат: regionId-settlementId)
      final regionId = settlement.id.split('-').first;
      
      try {
        // Сначала ищем по точному совпадению ID
        cityMood = provider.allCities.firstWhere(
          (c) => c.id == settlement.id,
        );
      } catch (e) {
        try {
          // Затем ищем по комбинации regionId + имя (без учета регистра)
          cityMood = provider.allCities.firstWhere(
            (c) => c.regionId == regionId &&
                  c.name.toLowerCase().trim() == settlement.name.toLowerCase().trim(),
          );
        } catch (e) {
          // Не используем поиск по точному имени без regionId - может находить неправильные города
          // Например, при поиске "Новосибирск" может найтиться "Иркутск" если они есть в разных регионах
          // Также не используем частичное совпадение - слишком неточно
          cityMood = null;
        }
      }
      return {
        'settlement': settlement,
        'mood': cityMood,
      };
    }).toList();
    
    // Сортируем: сначала по счастью (если есть голоса), потом по населению
    settlementsWithMood.sort((a, b) {
      final aMood = a['mood'] as CityMood?;
      final bMood = b['mood'] as CityMood?;
      
      final aHasVotes = aMood != null && aMood.totalCheckIns > 0;
      final bHasVotes = bMood != null && bMood.totalCheckIns > 0;
      
      final aSettlement = a['settlement'] as Settlement;
      final bSettlement = b['settlement'] as Settlement;
      
      // Если у обоих есть голоса - сортируем по счастью
      if (aHasVotes && bHasVotes) {
        return bMood!.averageMood.compareTo(aMood!.averageMood);
      }
      // Если только у одного есть голоса - он выше
      if (aHasVotes && !bHasVotes) return -1;
      if (!aHasVotes && bHasVotes) return 1;
      // Если у обоих нет голосов - сортируем по населению
      return bSettlement.population.compareTo(aSettlement.population);
    });
    
    final sortedList = settlementsWithMood
        .map((item) => item['settlement'] as Settlement)
        .toList();
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sortedList.length,
      itemBuilder: (context, index) {
        final settlement = sortedList[index];
        
        // Пытаемся найти реальные данные о настроении
        CityMood? cityMood;
        // Получаем regionId из settlement.id (формат: regionId-settlementId)
        final regionId = settlement.id.split('-').first;
        
        try {
          // Сначала ищем по точному совпадению ID
          cityMood = provider.allCities.firstWhere(
            (c) => c.id == settlement.id,
          );
        } catch (e) {
          try {
            // Затем ищем по комбинации regionId + имя (без учета регистра)
            cityMood = provider.allCities.firstWhere(
              (c) => c.regionId == regionId &&
                    c.name.toLowerCase().trim() == settlement.name.toLowerCase().trim(),
            );
          } catch (e) {
            try {
              // Затем ищем по точному совпадению имени (без учета регистра)
              cityMood = provider.allCities.firstWhere(
                (c) => c.name.toLowerCase().trim() == settlement.name.toLowerCase().trim(),
              );
            } catch (e) {
              try {
                // Затем ищем по частичному совпадению имени с учетом regionId
                cityMood = provider.allCities.firstWhere(
                  (c) => c.regionId == regionId &&
                        (c.name.toLowerCase().trim().contains(settlement.name.toLowerCase().trim()) ||
                         settlement.name.toLowerCase().trim().contains(c.name.toLowerCase().trim())),
                );
              } catch (e) {
                // Не используем частичное совпадение без regionId - слишком неточно
                // Может находить неправильные города (например, Иркутск для всех)
                cityMood = null;
              }
            }
          }
        }

        // Важно: всегда используем имя из settlement, чтобы отображать правильное название
        // Для дополнительных городов cityMood должен находиться по точному ID
        // Используем данные о настроении из cityMood, если он найден
        final moodForCard = CityMood(
          id: settlement.id,
          name: settlement.name, // Всегда используем имя из settlement
          regionId: regionId,
          averageMood: cityMood?.averageMood ?? 0,
          totalCheckIns: cityMood?.totalCheckIns ?? 0,
          population: settlement.population, // Всегда используем население из settlement
          lastUpdate: cityMood?.lastUpdate ?? DateTime.fromMillisecondsSinceEpoch(0),
        );

        // Получаем название региона: сначала из основного маппинга, потом из дополнительного
        final regionName = _settlementToRegion[settlement.id] ?? 
                          (additionalRegionNames[settlement.id]);
        
        return CityCard(
          city: moodForCard,
          rank: index + 1,
          isClickable: false,
          settlementType: settlement.type,
          regionName: regionName,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<MoodProvider>(
      builder: (context, provider, child) {
        // Если settlements не загружены, загружаем их
        if (_allSettlements.isEmpty && !_isLoadingData && provider.federalDistrictsData.isNotEmpty) {
          setState(() {
            _isLoadingData = true;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _loadAllSettlements(provider);
            }
          });
        }
        
        if (_isLoadingData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_allSettlements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_city_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Загрузка данных о населенных пунктах...',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Поисковая строка
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Поиск города, села, деревни...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  isDense: true,
                ),
              ),
            ),
            // Список населённых пунктов
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await provider.loadSettlementsData();
                  await _loadAllSettlements(provider);
                },
                child: _filteredSettlements.isEmpty && _searchQuery.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Ничего не найдено по запросу "$_searchQuery"',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : _buildSortedCitiesList(provider),
              ),
            ),
          ],
        );
      },
    );
  }
}

