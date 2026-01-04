import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/city_mood.dart';
import '../models/region_mood.dart';
import '../models/region_data.dart';
import '../models/settlement.dart';
import '../providers/mood_provider.dart';
import '../widgets/data_cards.dart';
import '../widgets/mood_cards.dart';
import 'city_detail_screen.dart';

/// Экран с рейтингом городов региона
class CitiesScreen extends StatefulWidget {
  final RegionMood? region;
  final String? regionId;

  const CitiesScreen({
    super.key,
    this.region,
    this.regionId,
  }) : assert(region != null || regionId != null, 'Необходимо указать region или regionId');

  @override
  State<CitiesScreen> createState() => _CitiesScreenState();
}

class _CitiesScreenState extends State<CitiesScreen> {
  RegionData? _regionData;
  List<Settlement> _cities = [];
  List<Settlement> _ruralSettlements = []; // сёла, деревни и т.д.
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MoodProvider>();
      final regionId = widget.region?.id ?? widget.regionId;
      
      if (regionId != null) {
        // Загружаем актуальные данные о регионе
        await provider.loadSettlementsData();
        _regionData = await provider.getRegionData(regionId);
        if (_regionData != null) {
          // Города региона
          _cities = await provider.getRegionCitiesData(regionId);
          // Все НП региона и отдельно сельские (не «город»)
          final allSettlements = _regionData!.getAllSettlements();
          _ruralSettlements = allSettlements
              .where((s) => s.type.toLowerCase() != 'город')
              .toList();
        }
        
        // Загружаем данные о настроении, если есть region
        if (widget.region != null) {
          await provider.loadCitiesRanking(regionId);
        }
        
        setState(() {
          _isLoadingData = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final regionId = widget.region?.id ?? widget.regionId;
    final regionName = widget.region?.name ?? _regionData?.name ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Города $regionName'),
        elevation: 0,
      ),
      body: Consumer<MoodProvider>(
        builder: (context, provider, child) {
          // Показываем актуальные данные из базы
          if (_isLoadingData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_regionData == null || _cities.isEmpty) {
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
                    'Нет данных о городах',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          // Если есть данные о настроении, фильтруем их по региону
          final citiesWithMood = <CityMood>[];
          if (widget.region != null && provider.cities.isNotEmpty && regionId != null) {
            // Фильтруем города по regionId - показываем только города этого региона
            citiesWithMood.addAll(
              provider.cities.where((city) => city.regionId == regionId),
            );
          }

          // Фильтруем города с настроением: показываем только те, где есть хотя бы один чек-ин
          final filteredCitiesWithMood = citiesWithMood
              .where((city) => city.totalCheckIns > 0)
              .toList();

          return Column(
            children: [
              // Заголовок с информацией о регионе
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      const Color(0xFF0039A6),
                      const Color(0xFFD52B1E),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      filteredCitiesWithMood.isNotEmpty ? 'Рейтинг городов' : 'Города региона',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.region != null)
                      Text(
                        'Средний балл региона: ${widget.region!.averageMood.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      )
                    else
                      Text(
                        '${_cities.length} городов • Население: ${_regionData!.population.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} чел.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                  ],
                ),
              ),

              // Список городов
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    if (regionId != null) {
                      await provider.loadSettlementsData();
                      _regionData = await provider.getRegionData(regionId);
                      if (_regionData != null) {
                        // Перезагружаем города
                        _cities = await provider.getRegionCitiesData(regionId);
                        // Пересчитываем сельские НП
                        final allSettlements = _regionData!.getAllSettlements();
                        _ruralSettlements = allSettlements
                            .where((s) => s.type.toLowerCase() != 'город')
                            .toList();
                      }
                      if (widget.region != null) {
                        await provider.loadCitiesRanking(regionId);
                      }
                      setState(() {});
                    }
                  },
                  child: filteredCitiesWithMood.isNotEmpty
                      ? ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          // города с настроением + (опциональный заголовок) + сельские НП
                          itemCount: filteredCitiesWithMood.length +
                              (_ruralSettlements.isNotEmpty ? 1 : 0) +
                              _ruralSettlements.length,
                          itemBuilder: (context, index) {
                            // Сначала карточки городов со смайликами
                            if (index < filteredCitiesWithMood.length) {
                              return _buildCityCardWithMood(
                                filteredCitiesWithMood[index],
                                index + 1,
                                theme,
                              );
                            }

                            // Дальше – заголовок «Населённые пункты»
                            final afterCitiesIndex =
                                index - filteredCitiesWithMood.length;
                            if (_ruralSettlements.isNotEmpty &&
                                afterCitiesIndex == 0) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    24, 16, 16, 4),
                                child: Text(
                                  'Населённые пункты (сёла, деревни и др.)',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0039A6),
                                  ),
                                ),
                              );
                            }

                            // Карточки сёл / деревень и т.д. (SettlementCard)
                            final ruralIndex =
                                afterCitiesIndex - (_ruralSettlements.isNotEmpty ? 1 : 0);
                            final settlement = _ruralSettlements[ruralIndex];
                            return SettlementCard(
                              settlement: settlement,
                              regionName: regionName,
                              isClickable: false,
                            );
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _cities.length,
                          itemBuilder: (context, index) {
                            return SettlementCard(
                              settlement: _cities[index],
                              regionName: regionName,
                              isClickable: false,
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCityCardWithMood(CityMood city, int rank, ThemeData theme) {
    final moodColor = _getColorByMood(city.averageMood);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 4,
      shadowColor: const Color(0xFF0039A6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/city/${city.id}',
            arguments: city,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Смайлик настроения с оценкой в правом верхнем углу
            Positioned(
              top: 8,
              right: 8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: moodColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      city.moodLevel.emoji,
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${city.averageMood.toStringAsFixed(1)}/5',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Номер города, название и население в левом верхнем углу
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Номер города
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: moodColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0039A6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Название города и население
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            city.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0039A6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${city.population.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} чел.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 45, left: 16, right: 16, bottom: 16),
              child: Row(
                children: [
                  // Информация о городе
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${city.totalCheckIns.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(right: 60),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: moodColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${city.happyPercentage.toStringAsFixed(2)}%',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: moodColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(right: 60),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: city.averageMood / 5.0,
                              minHeight: 8,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(moodColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorByMood(double mood) {
    if (mood >= 4.5) return Colors.green[600]!;
    if (mood >= 4.0) return Colors.green[400]!;
    if (mood >= 3.5) return Colors.lightGreen[400]!;
    if (mood >= 3.0) return Colors.yellow[600]!;
    if (mood >= 2.5) return Colors.orange[400]!;
    if (mood >= 2.0) return Colors.deepOrange[400]!;
    return Colors.red[600]!;
  }
}
