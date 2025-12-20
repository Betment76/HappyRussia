import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/check_in.dart';
import '../models/mood_level.dart';

/// Экран профиля с историей чек-инов
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storageService = StorageService();
  List<CheckIn> _checkIns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCheckIns();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Обновляем при возврате на экран
    _loadCheckIns();
  }

  /// Загрузить историю чек-инов
  Future<void> _loadCheckIns() async {
    setState(() => _isLoading = true);

    final checkIns = await _storageService.getCheckIns();
    // Сортируем по дате (новые первые)
    checkIns.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      _checkIns = checkIns;
      _isLoading = false;
    });
  }

  /// Вычислить среднее настроение
  double _calculateAverageMood() {
    if (_checkIns.isEmpty) return 0;

    final sum = _checkIns.fold<double>(
      0,
      (sum, checkIn) => sum + checkIn.mood.value,
    );

    return sum / _checkIns.length;
  }

  /// Получить количество чек-инов за период
  int _getCheckInsCountForPeriod(int days) {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));
    return _checkIns.where((c) => c.date.isAfter(cutoff)).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCheckIns,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _checkIns.isEmpty
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
                        'У вас пока нет чек-инов',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Сделайте первый чек-ин на главном экране',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCheckIns,
                  child: Column(
                    children: [
                      // Статистика
                      _buildStatistics(theme),

                      // Список чек-инов
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _checkIns.length,
                          itemBuilder: (context, index) {
                            return _buildCheckInCard(_checkIns[index], theme);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  /// Виджет статистики
  Widget _buildStatistics(ThemeData theme) {
    final averageMood = _calculateAverageMood();
    final moodLevel = averageMood >= 4.5
        ? MoodLevel.veryHappy
        : averageMood >= 3.5
            ? MoodLevel.happy
            : averageMood >= 2.5
                ? MoodLevel.neutral
                : averageMood >= 1.5
                    ? MoodLevel.sad
                    : MoodLevel.verySad;

    final moodColor = _getMoodColor(averageMood);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            moodColor.withOpacity(0.2),
            moodColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: moodColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Главный смайлик
          Text(
            moodLevel.emoji,
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),

          // Среднее настроение
          Text(
            'Среднее настроение',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            averageMood.toStringAsFixed(2),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: moodColor,
            ),
          ),
          const SizedBox(height: 20),

          // Статистика по периодам
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Всего',
                '${_checkIns.length}',
                Icons.calendar_today,
                theme,
              ),
              _buildStatItem(
                'За неделю',
                '${_getCheckInsCountForPeriod(7)}',
                Icons.date_range,
                theme,
              ),
              _buildStatItem(
                'За месяц',
                '${_getCheckInsCountForPeriod(30)}',
                Icons.event,
                theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getMoodColor(double mood) {
    if (mood >= 4.0) return Colors.green[600]!;
    if (mood >= 3.0) return Colors.yellow[600]!;
    if (mood >= 2.0) return Colors.orange[600]!;
    return Colors.red[600]!;
  }

  /// Карточка чек-ина
  Widget _buildCheckInCard(CheckIn checkIn, ThemeData theme) {
    final dateFormat = DateFormat('d MMMM yyyy', 'ru_RU');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getMoodColor(checkIn.mood.value.toDouble())
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            checkIn.mood.emoji,
            style: const TextStyle(fontSize: 32),
          ),
        ),
        title: Text(
          checkIn.regionName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(checkIn.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  timeFormat.format(checkIn.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getMoodColor(checkIn.mood.value.toDouble())
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            checkIn.mood.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getMoodColor(checkIn.mood.value.toDouble()),
            ),
          ),
        ),
      ),
    );
  }
}
