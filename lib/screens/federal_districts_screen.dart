import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mood_provider.dart';
import '../models/federal_district_mood.dart';
import '../widgets/mood_cards.dart';

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
                  Icons.sentiment_neutral,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Нет округов с зарегистрированными пользователями',
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
          onRefresh: () => provider.loadFederalDistrictsRanking(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filteredDistricts.length,
            itemBuilder: (context, index) {
              return FederalDistrictCard(
                district: filteredDistricts[index],
                isClickable: true,
              );
            },
          ),
        );
      },
    );
  }

  // Старые методы удалены - используем общий виджет FederalDistrictCard из widgets/mood_cards.dart
}

