import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mood_provider.dart';
import '../models/federal_district_mood.dart';
import 'district_regions_screen.dart';

/// Экран с рейтингом федеральных округов
class FederalDistrictsScreen extends StatelessWidget {
  const FederalDistrictsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<MoodProvider>(
      builder: (context, provider, child) {
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
                  onPressed: () => provider.loadFederalDistrictsRanking(),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadFederalDistrictsRanking(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.federalDistricts.length,
            itemBuilder: (context, index) {
              return _buildDistrictCard(provider.federalDistricts[index], theme, context);
            },
          ),
        );
      },
    );
  }

  /// Карточка федерального округа
  Widget _buildDistrictCard(FederalDistrictMood district, ThemeData theme, BuildContext context) {
    final moodColor = _getColorByMood(district.averageMood);

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
              builder: (_) => DistrictRegionsScreen(district: district),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Смайлик настроения
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: moodColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  district.moodLevel.emoji,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
              const SizedBox(width: 16),

              // Информация об округе
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      district.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0039A6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Население: ${district.population.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} чел.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${district.totalCheckIns.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: moodColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${district.happyPercentage.toStringAsFixed(2)}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: moodColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: district.averageMood / 5.0,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(moodColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${district.averageMood.toStringAsFixed(2)} / 5.0',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

