import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mood_provider.dart';
import '../models/region_mood.dart';
import '../models/federal_district_mood.dart';
import '../models/federal_district_data.dart';
import '../models/region_data.dart';
import '../data/russian_regions.dart';
import '../widgets/mood_cards.dart';
import '../widgets/data_cards.dart';
import 'region_detail_screen.dart';

/// Экран с рейтингом регионов федерального округа
class DistrictRegionsScreen extends StatefulWidget {
  final FederalDistrictMood? district;
  final FederalDistrictData? districtData;

  const DistrictRegionsScreen({
    super.key,
    this.district,
    this.districtData,
  }) : assert(district != null || districtData != null, 'Необходимо указать district или districtData');

  @override
  State<DistrictRegionsScreen> createState() => _DistrictRegionsScreenState();
}

class _DistrictRegionsScreenState extends State<DistrictRegionsScreen> {
  List<RegionMood> _filteredRegions = [];
  List<RegionData> _regionsData = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MoodProvider>();
      await provider.loadSettlementsData();
      _loadRegions(provider);
    });
  }

  void _loadRegions(MoodProvider provider) {
    final districtName = widget.district?.name ?? widget.districtData?.name ?? '';
    
    // Получаем актуальные данные о регионах округа
    FederalDistrictData? districtDataObj;
    if (widget.districtData != null) {
      districtDataObj = widget.districtData;
    } else {
      districtDataObj = provider.getFederalDistrictData(districtName);
    }
    
    if (districtDataObj != null) {
      _regionsData = List<RegionData>.from(districtDataObj.regions);
      // Сортируем регионы по ID (номеру)
      _regionsData.sort((a, b) => a.id.compareTo(b.id));
    }
    
    // Если есть данные о настроении, фильтруем регионы
    if (widget.district != null) {
      // Получаем ID регионов этого округа
      final regionIds = RussianRegions.getByFederalDistrict(districtName)
          .map((r) => r['id']!)
          .toSet();
      
      // Фильтруем регионы по ID и показываем только те, где есть хотя бы один чек-ин
      _filteredRegions = provider.regions
          .where((region) => regionIds.contains(region.id) && region.totalCheckIns > 0)
          .toList()
        ..sort((a, b) => b.averageMood.compareTo(a.averageMood));
    }
    
    setState(() {
      _isLoadingData = false;
    });
  }

  /// Преобразовать название округа в формат "Название ФО"
  String _getShortDistrictName(String fullName) {
    // Если название уже содержит "Федеральный округ", заменяем на "ФО"
    if (fullName.contains('Федеральный округ')) {
      return fullName.replaceAll('Федеральный округ', 'ФО').trim();
    }
    // Иначе просто добавляем " ФО"
    return '$fullName ФО';
  }

  String get _districtName {
    return widget.district?.name ?? widget.districtData?.name ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getShortDistrictName(_districtName)),
        elevation: 0,
      ),
      body: Consumer<MoodProvider>(
        builder: (context, provider, child) {
          if (_isLoadingData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Если есть актуальные данные, показываем их
          if (_regionsData.isNotEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                await provider.loadSettlementsData();
                _loadRegions(provider);
              },
              child: Column(
                children: [
                  // Заголовок с информацией об округе
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
                          'Рейтинг регионов',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.district != null && widget.district!.totalCheckIns > 0
                              ? 'Средний балл округа: ${widget.district!.averageMood.toStringAsFixed(1)}/5.0'
                              : '${_regionsData.length} регионов',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _regionsData.length,
                      itemBuilder: (context, index) {
                        final regionData = _regionsData[index];
                        // Пытаемся найти данные о настроении для этого региона
                        RegionMood? regionMood;
                        try {
                          regionMood = provider.regions.firstWhere(
                            (r) => r.id == regionData.id && r.totalCheckIns > 0,
                          );
                        } catch (e) {
                          regionMood = null;
                        }
                        
                        // Если есть данные о настроении, показываем карточку с настроением
                        if (regionMood != null) {
                          return RegionCard(
                            region: regionMood!,
                            isClickable: false,
                          );
                        }
                        
                        // Иначе показываем карточку с актуальными данными
                        return RegionDataCard(
                          region: regionData,
                          isClickable: false,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          // Fallback: показываем только регионы с настроением
          if (_filteredRegions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sentiment_neutral,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Нет данных',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadSettlementsData();
              await provider.loadRegionsRanking();
              _loadRegions(provider);
            },
            child: Column(
              children: [
                // Заголовок с информацией об округе
                Container(
                  width: double.infinity, // На всю ширину
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white, // Белый
                        const Color(0xFF0039A6), // Синий
                        const Color(0xFFD52B1E), // Красный
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Рейтинг регионов',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.district != null
                            ? 'Средний балл округа: ${widget.district!.averageMood.toStringAsFixed(1)}/5.0'
                            : '${_regionsData.length} регионов',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredRegions.length,
                    itemBuilder: (context, index) {
                      return _buildRegionCard(_filteredRegions[index], theme);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Карточка региона
  Widget _buildRegionCard(RegionMood region, ThemeData theme) {
    final moodColor = _getColorByMood(region.averageMood);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 4,
      shadowColor: const Color(0xFF0039A6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                      region.moodLevel.emoji,
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${region.averageMood.toStringAsFixed(1)}/5',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Номер региона, название и население в левом верхнем углу
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Номер региона
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: moodColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        region.id,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0039A6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Название региона и население
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            region.name,
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
                              '${region.population.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} чел.',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 12),
                      // Иконка человечка и количество проголосовавших
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${region.totalCheckIns.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      // Процент над правым краем прогресс-бара
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
                            '${region.happyPercentage.toStringAsFixed(2)}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: moodColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Прогресс-бар
                  Padding(
                    padding: const EdgeInsets.only(right: 60),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: region.averageMood / 5.0,
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
    );
  }

  /// Получить цвет по уровню настроения
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

