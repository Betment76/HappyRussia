import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mood_provider.dart';
import '../widgets/mood_cards.dart';
import 'check_in_screen.dart';
import 'profile_screen.dart';
import 'federal_districts_screen.dart';
import 'all_cities_screen.dart';

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
      if (_tabController.indexIsChanging || _tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    // Загружаем данные при открытии экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MoodProvider>();
      provider.loadFederalDistrictsRanking();
      provider.loadRegionsRanking();
      provider.loadAllCitiesRanking();
    });
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
                    Tab(text: 'Города'),
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
                    provider.regions.isEmpty
                        ? Center(
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
                          )
                        : RefreshIndicator(
                            onRefresh: () => provider.loadRegionsRanking(),
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

  /// Построить список регионов (только с зарегистрированными пользователями)
  Widget _buildRegionsList(MoodProvider provider, ThemeData theme) {
    // Фильтруем регионы: показываем только те, где есть хотя бы один чек-ин
    final filteredRegions = provider.regions
        .where((region) => region.totalCheckIns > 0)
        .toList();

    if (filteredRegions.isEmpty) {
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
              'Нет регионов с зарегистрированными пользователями',
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
          isClickable: true,
        );
      },
    );
  }
}
