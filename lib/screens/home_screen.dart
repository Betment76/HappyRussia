import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mood_provider.dart';
import '../models/region_mood.dart';
import '../widgets/mood_cards.dart';
import '../widgets/data_cards.dart';
import 'check_in_screen.dart';
import 'profile_screen.dart';
import 'federal_districts_screen.dart';
import 'all_cities_screen.dart';
import 'cities_screen.dart';

/// Главный экран с рейтингом регионов
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 1; // По умолчанию выбрана вкладка "Регионы"

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        // Обновляем данные при переключении вкладок (после завершения анимации)
        _refreshDataForTab(_tabController.index);
      }
    });
    // Загружаем данные при открытии экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDataForTab(_currentTabIndex);
    });
  }

  /// Обновить данные для выбранной вкладки
  void _refreshDataForTab(int tabIndex) {
    final provider = context.read<MoodProvider>();
    // Загружаем данные только если они еще не загружены
    if (provider.federalDistrictsData.isEmpty) {
      provider.loadSettlementsData();
    }
    
    // Для вкладки "Города" всегда обновляем данные при переключении
    if (tabIndex == 2) {
      // Загружаем settlements и рейтинг городов
      // Важно: загружаем settlements, чтобы включить новые города с чек-инами
      if (provider.federalDistrictsData.isEmpty) {
        provider.loadSettlementsData();
      }
      // Всегда обновляем рейтинг городов при переключении на вкладку
      provider.loadAllCitiesRanking();
    } else {
      // Для других вкладок обновляем рейтинги только если они пустые
      if (provider.federalDistricts.isEmpty) {
        provider.loadFederalDistrictsRanking();
      }
      if (provider.regions.isEmpty) {
        provider.loadRegionsRanking();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Получить заголовок в зависимости от выбранной вкладки
  String _getHeaderTitle() {
    switch (_currentTabIndex) {
      case 0:
        return 'Рейтинг округов';
      case 1:
        return 'Рейтинг регионов';
      case 2:
        return 'Рейтинг городов';
      default:
        return 'Рейтинг регионов';
    }
  }

  /// Получить подзаголовок в зависимости от выбранной вкладки
  String _getHeaderSubtitle() {
    switch (_currentTabIndex) {
      case 0:
        return 'Средний уровень счастья по округам';
      case 1:
        return 'Средний уровень счастья по России';
      case 2:
        return 'Средний уровень счастья по городам России';
      default:
        return 'Средний уровень счастья по России';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Моё Настроение',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0039A6),
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            tooltip: 'Профиль',
          ),
        ],
      ),
      body: Consumer<MoodProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.regions.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null && provider.regions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ошибка загрузки',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.error ?? 'Неизвестная ошибка',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => provider.loadRegionsRanking(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Заголовок с информацией (цвета российского флага)
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
                      _getHeaderTitle(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getHeaderSubtitle(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Вкладки
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF0039A6),
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: const Color(0xFF0039A6),
                  tabs: const [
                    Tab(text: 'Округа'),
                    Tab(text: 'Регионы'),
                    Tab(text: 'Города/Сёла'),
                  ],
                ),
              ),
              
              // Контент вкладок
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Вкладка "Округа"
                    const FederalDistrictsScreen(),
                    // Вкладка "Регионы"
                    RefreshIndicator(
                      onRefresh: () async {
                        await provider.loadSettlementsData();
                        await provider.loadRegionsRanking();
                      },
                      child: _buildRegionsList(provider, theme),
                    ),
                    // Вкладка "Города"
                    const AllCitiesScreen(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(
          left: 8,
          right: 8,
          top: 4,
          bottom: 4,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckInScreen()),
                );
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Добавить настроение'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Построить список регионов (с актуальными данными из базы)
  Widget _buildRegionsList(MoodProvider provider, ThemeData theme) {
    // Если есть актуальные данные, показываем их
    if (provider.federalDistrictsData.isNotEmpty) {
      final allRegions = provider.getAllRegionsData();
      
      if (allRegions.isEmpty) {
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
                'Загрузка данных о регионах...',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      // Сортируем регионы: сначала по счастью (если есть голоса), потом по населению
      final regionsWithMood = allRegions.map((regionData) {
        RegionMood? regionMood;
        try {
          regionMood = provider.regions.firstWhere(
            (r) => r.id == regionData.id,
          );
        } catch (e) {
          regionMood = null;
        }
        return {
          'data': regionData,
          'mood': regionMood,
        };
      }).toList();
      
      regionsWithMood.sort((a, b) {
        final aMood = a['mood'] as RegionMood?;
        final bMood = b['mood'] as RegionMood?;
        
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

      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: regionsWithMood.length,
        itemBuilder: (context, index) {
          final item = regionsWithMood[index];
          final regionData = item['data'] as dynamic;
          final regionMood = item['mood'] as RegionMood?;

          // Всегда показываем карточку настроения (со смайликом и статус-баром)
          // Если нет реальных данных по настроению, подставляем нули
          final moodForCard = regionMood ??
              RegionMood(
                id: regionData.id,
                name: regionData.name,
                averageMood: 0,
                totalCheckIns: 0,
                population: regionData.population,
                lastUpdate: DateTime.fromMillisecondsSinceEpoch(0),
              );

          return RegionCard(
            region: moodForCard,
            isClickable: false, // кликабельность отключена по требованию
          );
        },
      );
    }

    // Fallback: показываем данные о настроении, если они есть
    final filteredRegions = provider.regions
        .where((region) => region.totalCheckIns > 0)
        .toList();

    if (filteredRegions.isEmpty) {
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
              'Загрузка данных о регионах...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredRegions.length,
      itemBuilder: (context, index) {
        return RegionCard(
          region: filteredRegions[index],
          isClickable: false,
        );
      },
    );
  }
}
