import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mood_provider.dart';
import '../models/region_mood.dart';
import 'check_in_screen.dart';
import 'profile_screen.dart';
import 'cities_screen.dart';
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
        return 'Средний уровень счастья по федеральным округам';
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
        title: Row(
          children: [
            const Text('⚔️ '),
            const Text('Битва Регионов'),
          ],
        ),
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
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: provider.regions.length,
                              itemBuilder: (context, index) {
                                return _buildRegionCard(
                                  provider.regions[index],
                                  theme,
                                );
                              },
                            ),
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

  /// Карточка региона
  Widget _buildRegionCard(RegionMood region, ThemeData theme) {
    final moodColor = _getColorByMood(region.averageMood);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 4,
      shadowColor: const Color(0xFF0039A6), // Синий цвет российского флага
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CitiesScreen(region: region),
            ),
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
                    height: 45 ,
                    decoration: BoxDecoration(
                      color: moodColor.withOpacity(0.2), // Цвет настроения
                      borderRadius: BorderRadius.circular(8), // Закругленные углы
                    ),
                    child: Center(
                      child: Text(
                        region.id,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0039A6), // Синий цвет российского флага
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
                              color: const Color(0xFF0039A6), // Синий цвет российского флага
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
              child: Row(
                children: [
                  // Информация о регионе
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const SizedBox(width: 8),
                        // Иконка человечка и количество проголосовавших
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${region.totalCheckIns.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(), // Растягиваем пространство
                        // Процент над правым краем прогресс-бара
                        Padding(
                          padding: const EdgeInsets.only(right: 60), // Отступ для смайлика
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
                    const SizedBox(height: 6),
                    // Прогресс-бар (растягивается до смайлика)
                    Padding(
                      padding: const EdgeInsets.only(right: 60), // Отступ для смайлика
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
            ),
          ],
        ),
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
