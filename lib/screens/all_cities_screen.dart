import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mood_provider.dart';
import '../models/city_mood.dart';
import '../widgets/mood_cards.dart';

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

        // Фильтруем города: показываем только те, где есть хотя бы один чек-ин
        final filteredCities = provider.allCities
            .where((city) => city.totalCheckIns > 0)
            .toList();

        if (filteredCities.isEmpty) {
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
                  'Нет городов с зарегистрированными пользователями',
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
          onRefresh: () => provider.loadAllCitiesRanking(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filteredCities.length,
            itemBuilder: (context, index) {
              return CityCard(
                city: filteredCities[index],
                rank: index + 1,
                isClickable: true,
              );
            },
          ),
        );
      },
    );
  }

  // Старые методы удалены - используем общие виджеты из widgets/mood_cards.dart
}

