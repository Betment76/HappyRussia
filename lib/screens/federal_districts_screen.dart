import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mood_provider.dart';
import '../models/federal_district_mood.dart';
import '../widgets/mood_cards.dart';
import '../widgets/data_cards.dart';
import 'district_regions_screen.dart';

/// Экран с рейтингом федеральных округов
class FederalDistrictsScreen extends StatefulWidget {
  const FederalDistrictsScreen({super.key});

  @override
  State<FederalDistrictsScreen> createState() => _FederalDistrictsScreenState();
}

class _FederalDistrictsScreenState extends State<FederalDistrictsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ВАЖНО: Не вызываем setState() или notifyListeners() во время build
    // Используем addPostFrameCallback для выполнения после завершения сборки
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshData();
    });
  }

  void _refreshData() {
    final provider = context.read<MoodProvider>();
    // Загружаем данные только если они еще не загружены
    if (provider.federalDistrictsData.isEmpty) {
      provider.loadSettlementsData();
    }
    if (provider.federalDistricts.isEmpty) {
      provider.loadFederalDistrictsRanking();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<MoodProvider>(
      builder: (context, provider, child) {
        // Показываем актуальные данные из базы
        if (provider.isLoadingSettlementsData && provider.federalDistrictsData.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Если есть актуальные данные, показываем их
        if (provider.federalDistrictsData.isNotEmpty) {
          // Сортируем округа: сначала по счастью (если есть голоса), потом по населению
          final districtsWithMood = provider.federalDistrictsData.map((districtData) {
            FederalDistrictMood? districtMood;
            try {
              districtMood = provider.federalDistricts.firstWhere(
                (d) => d.name == districtData.name,
              );
            } catch (e) {
              districtMood = null;
            }
            return {
              'data': districtData,
              'mood': districtMood,
            };
          }).toList();
          
          districtsWithMood.sort((a, b) {
            final aMood = a['mood'] as FederalDistrictMood?;
            final bMood = b['mood'] as FederalDistrictMood?;
            
            final aHasVotes = aMood != null && aMood.totalCheckIns > 0;
            final bHasVotes = bMood != null && bMood.totalCheckIns > 0;
            
            // Если у обоих есть голоса - сортируем по счастью
            if (aHasVotes && bHasVotes) {
              return bMood!.averageMood.compareTo(aMood!.averageMood);
            }
            // Если только у одного есть голоса - он выше
            if (aHasVotes && !bHasVotes) return -1;
            if (!aHasVotes && bHasVotes) return 1;
            // Если у обоих нет голосов - сортируем по населению
            final aData = a['data'] as dynamic;
            final bData = b['data'] as dynamic;
            return bData.population.compareTo(aData.population);
          });
          
          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadSettlementsData();
              await provider.loadFederalDistrictsRanking();
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: districtsWithMood.length,
              itemBuilder: (context, index) {
                final item = districtsWithMood[index];
                final districtData = item['data'] as dynamic;
                final districtMood = item['mood'] as FederalDistrictMood?;

                // Всегда показываем карточку настроения (со смайликом и статус-баром)
                // Если нет реальных данных по настроению, подставляем нули
                final moodForCard = districtMood ??
                    FederalDistrictMood(
                      id: districtData.name, // идентификатор по названию
                      name: districtData.name,
                      averageMood: 0,
                      totalCheckIns: 0,
                      population: districtData.population,
                      lastUpdate: DateTime.fromMillisecondsSinceEpoch(0),
                    );

                return FederalDistrictCard(
                  district: moodForCard,
                  isClickable: false, // кликабельность отключена по требованию
                );
              },
            ),
          );
        }

        // Fallback: показываем данные о настроении, если они есть
        if (provider.isLoadingFederalDistricts && provider.federalDistricts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorFederalDistricts != null && provider.federalDistricts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Ошибка: ${provider.errorFederalDistricts}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    provider.loadSettlementsData();
                    provider.loadFederalDistrictsRanking();
                  },
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        // Фильтруем округа: показываем только те, где есть хотя бы один чек-ин
        final filteredDistricts = provider.federalDistricts
            .where((district) => district.totalCheckIns > 0)
            .toList();

        if (filteredDistricts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Загрузка данных об округах...',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await provider.loadSettlementsData();
            await provider.loadFederalDistrictsRanking();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filteredDistricts.length,
            itemBuilder: (context, index) {
              return FederalDistrictCard(
                district: filteredDistricts[index],
                isClickable: false,
              );
            },
          ),
        );
      },
    );
  }
}

