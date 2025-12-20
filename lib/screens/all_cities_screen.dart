import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mood_provider.dart';
import '../models/city_mood.dart';
import 'districts_screen.dart';

/// Экран с рейтингом всех городов России
class AllCitiesScreen extends StatefulWidget {
  const AllCitiesScreen({super.key});

  @override
  State<AllCitiesScreen> createState() => _AllCitiesScreenState();
}

class _AllCitiesScreenState extends State<AllCitiesScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<MoodProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingAllCities && provider.allCities.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorAllCities != null && provider.allCities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Ошибка: ${provider.errorAllCities}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadAllCitiesRanking(),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadAllCitiesRanking(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.allCities.length,
            itemBuilder: (context, index) {
              return _buildCityCard(context, provider.allCities[index], index + 1, theme);
            },
          ),
        );
      },
    );
  }

  /// Карточка города
  Widget _buildCityCard(BuildContext context, CityMood city, int rank, ThemeData theme) {
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DistrictsScreen(city: city),
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
                      color: moodColor.withOpacity(0.2), // Цвет настроения
                      borderRadius: BorderRadius.circular(8), // Закругленные углы
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0039A6), // Синий цвет российского флага
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
                        '${city.totalCheckIns.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')}',
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
                  const SizedBox(height: 8),
                  // Прогресс-бар (растягивается до смайлика)
                  Padding(
                    padding: const EdgeInsets.only(right: 60), // Отступ для смайлика
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

