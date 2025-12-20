import 'package:flutter/material.dart';
import '../models/district_mood.dart';
import '../models/city_mood.dart';
import '../services/mock_service.dart';

/// Экран с рейтингом районов города
class DistrictsScreen extends StatefulWidget {
  final CityMood city;

  const DistrictsScreen({
    super.key,
    required this.city,
  });

  @override
  State<DistrictsScreen> createState() => _DistrictsScreenState();
}

class _DistrictsScreenState extends State<DistrictsScreen> {
  List<DistrictMood> _districts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDistricts();
  }

  Future<void> _loadDistricts() async {
    setState(() => _isLoading = true);
    
    // Имитация загрузки
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Генерируем моки районов
    final districts = MockService.generateMockDistricts(widget.city.id);
    
    setState(() {
      _districts = districts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.city.name),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _districts.isEmpty
              ? Center(
                  child: Text(
                    'Нет данных о районах',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Заголовок с информацией о городе
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
                            'Рейтинг районов',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Средний балл города: ${widget.city.averageMood.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Список районов
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadDistricts,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _districts.length,
                          itemBuilder: (context, index) {
                            return _buildDistrictCard(_districts[index], index + 1, theme);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildDistrictCard(DistrictMood district, int rank, ThemeData theme) {
    final moodColor = _getColorByMood(district.averageMood);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Место в рейтинге
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: rank <= 3
                    ? moodColor.withOpacity(0.2)
                    : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: rank <= 3 ? moodColor : Colors.grey[700],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Информация о районе
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    district.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
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
                        '${district.population.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} чел.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${district.happyPercentage.toStringAsFixed(2)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: moodColor,
                          fontWeight: FontWeight.bold,
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

            const SizedBox(width: 12),

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
          ],
        ),
      ),
    );
  }

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

