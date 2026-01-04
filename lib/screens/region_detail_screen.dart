import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/region_mood.dart';
import '../models/region_data.dart';
import '../models/settlement.dart';
import '../models/urban_district.dart';
import '../providers/mood_provider.dart';
import '../widgets/data_cards.dart';
import '../widgets/mood_cards.dart';
import '../widgets/yandex_banner_ad.dart';
import 'cities_screen.dart';

/// Экран с детальной информацией о регионе: города и районы
class RegionDetailScreen extends StatefulWidget {
  final RegionMood? region;
  final String? regionId;

  const RegionDetailScreen({
    super.key,
    this.region,
    this.regionId,
  }) : assert(region != null || regionId != null, 'Необходимо указать region или regionId');

  @override
  State<RegionDetailScreen> createState() => _RegionDetailScreenState();
}

class _RegionDetailScreenState extends State<RegionDetailScreen> {
  RegionData? _regionData;
  List<Settlement> _cities = [];
  List<UrbanDistrict> _districts = [];
  bool _isLoadingData = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  /// Определить тип субъекта по названию и вернуть текст в родительном падеже
  String _getRegionTypeGenitive(String regionName) {
    final nameLower = regionName.toLowerCase();
    
    // Республика
    if (nameLower.contains('республика')) {
      return 'республики';
    }
    
    // Край
    if (nameLower.contains('край')) {
      return 'края';
    }
    
    // Автономный округ
    if (nameLower.contains('автономный округ')) {
      return 'округа';
    }
    
    // Автономная область
    if (nameLower.contains('автономная область')) {
      return 'области';
    }
    
    // Город федерального значения
    if (nameLower.contains('город федерального значения') || 
        nameLower == 'москва' || 
        nameLower == 'санкт-петербург' || 
        nameLower == 'севастополь') {
      return 'города';
    }
    
    // По умолчанию - область
    return 'области';
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MoodProvider>();
      final regionId = widget.region?.id ?? widget.regionId;
      
      if (regionId != null) {
        // Загружаем актуальные данные о регионе
        await provider.loadSettlementsData();
        _regionData = await provider.getRegionData(regionId);
        if (_regionData != null) {
          _cities = await provider.getRegionCitiesData(regionId);
          _districts = await provider.getRegionDistrictsData(regionId);
        }
        
        setState(() {
          _isLoadingData = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Фильтрация городов по поисковому запросу
  List<Settlement> get _filteredCities {
    if (_searchQuery.isEmpty) {
      return _cities;
    }
    return _cities.where((city) {
      return city.name.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  // Фильтрация районов по поисковому запросу
  List<UrbanDistrict> get _filteredDistricts {
    if (_searchQuery.isEmpty) {
      return _districts;
    }
    return _districts.where((district) {
      return district.name.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final regionId = widget.region?.id ?? widget.regionId;
    final regionName = widget.region?.name ?? _regionData?.name ?? '';
    final regionTypeGenitive = _getRegionTypeGenitive(regionName);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(-8),
        child: AppBar(
          title: const Text(''),
          elevation: 0,
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false,
          toolbarHeight: 0,
        ),
      ),
      body: Column(
        children: [
          // Рекламный баннер Яндекс.Директ под AppBar
          YandexBannerAd(
            // TODO: Замените на ваш реальный Ad Unit ID из кабинета Яндекс.Директ
            // Для тестирования можно использовать тестовый ID: 'demo-banner-yandex'
            adUnitId: 'demo-banner-yandex', // Замените на реальный ID
            height: 100,
          ),
          // Контент экрана под рекламным баннером
          Expanded(
            child: Consumer<MoodProvider>(
              builder: (context, provider, child) {
                if (_isLoadingData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_regionData == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Нет данных о регионе',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Заголовок с информацией о регионе (фиксированный, не скроллится)
                    Container(
                      width: double.infinity,
                      height: 100,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            const Color(0xFF0039A6),
                            const Color(0xFFD52B1E),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.10, 0.40, 0.85],
                        ),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Кнопка назад слева
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                              // Название региона по центру
                              Text(
                                regionName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          const SizedBox(height: 0),
                          Text(
                            '${_cities.length} городов • ${_districts.length} районов • ${_regionData!.totalSettlementsCount} населенных пунктов',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 0),
                          Text(
                            'Население: ${_regionData!.population.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} чел.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Поисковая строка
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Поиск города или района...',
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
                    // Прокручиваемый контент
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          if (regionId != null) {
                            await provider.loadSettlementsData();
                            _regionData = await provider.getRegionData(regionId);
                            if (_regionData != null) {
                              _cities = await provider.getRegionCitiesData(regionId);
                              _districts = await provider.getRegionDistrictsData(regionId);
                            }
                            setState(() {});
                          }
                        },
                        child: CustomScrollView(
                          slivers: [
                
                // Секция "Города"
                if (_filteredCities.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 12, 16, 4),
                      child: Text(
                        'Города $regionTypeGenitive',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0039A6),
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return SettlementCard(
                          settlement: _filteredCities[index],
                          regionName: regionName,
                          isClickable: true,
                        );
                      },
                      childCount: _filteredCities.length,
                    ),
                  ),
                ],
                
                // Секция "Районы"
                if (_filteredDistricts.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 12, 16, 4),
                      child: Text(
                        'Районы $regionTypeGenitive',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0039A6),
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return UrbanDistrictCard(
                          district: _filteredDistricts[index],
                          regionName: regionName,
                          isClickable: true,
                        );
                      },
                      childCount: _filteredDistricts.length,
                    ),
                  ),
                ],
                
                // Если нет данных после фильтрации
                if (_filteredCities.isEmpty && _filteredDistricts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty ? Icons.search_off : Icons.location_city_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Ничего не найдено по запросу "$_searchQuery"'
                                : 'Нет данных о городах и районах',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

