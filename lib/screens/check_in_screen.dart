import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/mood_provider.dart';
import '../models/mood_level.dart';
import '../models/check_in.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../data/russian_regions.dart';
import '../data/region_cities_data.dart';

/// Экран для ежедневного чек-ина настроения
class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen>
    with SingleTickerProviderStateMixin {
  MoodLevel? _selectedMood;
  String? _selectedRegionId;
  String? _selectedRegionName;
  String? _registrationLocation; // Место регистрации пользователя
  bool _isSubmitting = false;
  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initializeRegion();
  }

  /// Инициализировать регион: сначала из места регистрации, потом по геолокации
  Future<void> _initializeRegion() async {
    // Сначала загружаем место регистрации
    await _loadRegistrationLocation();
    // Затем определяем по геолокации (если регион еще не определен)
    await _detectRegion();
  }

  /// Загрузить место регистрации пользователя
  Future<void> _loadRegistrationLocation() async {
    try {
      final location = await _storageService.getProfileLocation();
      if (location != null && location.isNotEmpty) {
        setState(() {
          _registrationLocation = location;
        });
        // Пробуем определить регион из места регистрации
        _setRegionFromRegistrationLocation(location);
      }
    } catch (e) {
      debugPrint('Ошибка загрузки места регистрации: $e');
    }
  }

  /// Установить регион из места регистрации
  void _setRegionFromRegistrationLocation(String location) {
    // Место регистрации в формате: "Округ - Регион - Район/Город - Населенный пункт"
    final parts = location.split(' - ');
    if (parts.length >= 2) {
      final regionName = parts[1].trim(); // Второй элемент - регион
      
      // Пробуем найти регион по имени
      var region = RussianRegions.findByName(regionName);
      
      // Если не нашли, пробуем найти по частичному совпадению
      if (region == null) {
        for (var r in RussianRegions.getAll()) {
          final fullName = r['name'] ?? '';
          if (fullName.toLowerCase().contains(regionName.toLowerCase()) ||
              regionName.toLowerCase().contains(fullName.toLowerCase().split(' ').first)) {
            region = r;
            break;
          }
        }
      }
      
      if (region != null) {
        final regionId = region['id'];
        final regionName = region['name'];
        if (regionId != null && regionName != null) {
          setState(() {
            _selectedRegionId = regionId;
            _selectedRegionName = regionName;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Определить регион автоматически по геолокации (если регион еще не определен)
  Future<void> _detectRegion() async {
    // Если регион уже определен из места регистрации, не перезаписываем
    if (_selectedRegionId != null) {
      return;
    }

    try {
      final location = await _locationService.getUserLocation();
      if (location.isValid && location.region != null) {
        // Находим регион по имени
        final region = RussianRegions.findByName(location.region!);
        if (region != null) {
          setState(() {
            _selectedRegionId = region['id'];
            _selectedRegionName = region['name'];
          });
        }
      }
    } catch (e) {
      // Игнорируем ошибки геолокации, пользователь может выбрать регион вручную
      debugPrint('Ошибка определения региона: $e');
    }
  }

  /// Отправить чек-ин
  Future<void> _submitCheckIn() async {
    if (_selectedMood == null) {
      _showError('Выберите ваше настроение');
      return;
    }

    if (_selectedRegionId == null) {
      _showError('Выберите регион');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Извлекаем информацию о городе/населенном пункте из места регистрации
      final locationInfo = _extractLocationInfo(_registrationLocation);
      
      // Пытаемся найти cityId в RegionCitiesData
      String? cityId;
      if (locationInfo['cityName'] != null && _selectedRegionId != null) {
        cityId = _findCityId(locationInfo['cityName']!, _selectedRegionId!);
      }

      final checkIn = CheckIn(
        id: const Uuid().v4(),
        regionId: _selectedRegionId!,
        regionName: _selectedRegionName!,
        mood: _selectedMood!,
        date: DateTime.now(),
        cityId: cityId,
        cityName: locationInfo['cityName'],
        federalDistrict: locationInfo['federalDistrict'],
        district: locationInfo['district'],
      );

      await context.read<MoodProvider>().submitCheckIn(checkIn);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Чек-ин успешно отправлен!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Ошибка отправки: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Как ваше настроение?'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Заголовок
            Text(
              'Выберите ваше настроение:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Смайлики
            _buildMoodSelector(theme),

            const SizedBox(height: 20),

            // Карточка места регистрации в стиле карточек городов
            if (_registrationLocation != null && _registrationLocation!.isNotEmpty)
              _buildRegistrationLocationCityCard(theme),

            const SizedBox(height: 20),

            // Кнопка отправки
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitCheckIn,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Отправить',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Виджет выбора настроения
  Widget _buildMoodSelector(ThemeData theme) {
    return Column(
      children: MoodLevel.values.map((mood) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: _buildMoodButton(mood, theme),
        );
      }).toList(),
    );
  }

  Widget _buildMoodButton(MoodLevel mood, ThemeData theme) {
    final isSelected = _selectedMood == mood;
    final color = _getMoodColor(mood);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMood = mood;
        });
        _animationController.forward(from: 0.0);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                mood.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              mood.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMoodColor(MoodLevel mood) {
    switch (mood) {
      case MoodLevel.veryHappy:
        return Colors.green;
      case MoodLevel.happy:
        return Colors.lightGreen;
      case MoodLevel.neutral:
        return Colors.lightBlue;
      case MoodLevel.sad:
        return Colors.orange;
      case MoodLevel.verySad:
        return Colors.red;
    }
  }

  /// Извлечь информацию о местоположении из места регистрации
  Map<String, String?> _extractLocationInfo(String? location) {
    if (location == null || location.isEmpty) {
      return {
        'federalDistrict': null,
        'district': null,
        'cityName': null,
      };
    }

    // Формат: "Округ - Регион - Район/Город - Населенный пункт"
    final parts = location.split(' - ');
    
    String? federalDistrict;
    String? district;
    String? cityName;

    if (parts.length >= 1) {
      federalDistrict = parts[0].trim();
    }
    
    if (parts.length >= 4) {
      // Если есть населенный пункт, берем его и район
      district = parts[2].trim();
      cityName = parts[3].trim();
    } else if (parts.length >= 3) {
      // Если есть город/район, берем его
      cityName = parts[2].trim();
    }

    return {
      'federalDistrict': federalDistrict,
      'district': district,
      'cityName': cityName,
    };
  }

  /// Найти ID города в RegionCitiesData по названию
  String? _findCityId(String cityName, String regionId) {
    final cities = RegionCitiesData.cities[regionId];
    if (cities == null) return null;

    // Ищем точное совпадение
    for (var city in cities) {
      final name = city['name'] as String?;
      if (name != null && name.toLowerCase() == cityName.toLowerCase()) {
        // Используем комбинацию regionId + cityName как ID
        return '$regionId-${name.toLowerCase().replaceAll(' ', '-')}';
      }
    }

    // Ищем частичное совпадение
    for (var city in cities) {
      final name = city['name'] as String?;
      if (name != null) {
        if (name.toLowerCase().contains(cityName.toLowerCase()) ||
            cityName.toLowerCase().contains(name.toLowerCase())) {
          return '$regionId-${name.toLowerCase().replaceAll(' ', '-')}';
        }
      }
    }

    return null;
  }

  /// Извлечь название города/населенного пункта из места регистрации (для обратной совместимости)
  String _extractCityFromLocation(String location) {
    final info = _extractLocationInfo(location);
    return info['cityName'] ?? location;
  }

  /// Получить численность населения города
  int _getCityPopulation(String cityName, String? regionId) {
    if (regionId == null) return 0;
    
    final cities = RegionCitiesData.cities[regionId];
    if (cities == null) return 0;
    
    // Ищем город по точному совпадению или частичному
    for (var city in cities) {
      final name = city['name'] as String?;
      if (name != null) {
        // Точное совпадение
        if (name.toLowerCase() == cityName.toLowerCase()) {
          return city['population'] as int? ?? 0;
        }
        // Частичное совпадение (если название содержит город или наоборот)
        if (name.toLowerCase().contains(cityName.toLowerCase()) ||
            cityName.toLowerCase().contains(name.toLowerCase())) {
          return city['population'] as int? ?? 0;
        }
      }
    }
    
    return 0;
  }

  /// Получить цвет по уровню настроения (для карточки)
  Color _getColorByMood(double mood) {
    if (mood >= 4.5) return Colors.green[600]!;
    if (mood >= 4.0) return Colors.green[400]!;
    if (mood >= 3.5) return Colors.lightGreen[400]!;
    if (mood >= 3.0) return Colors.yellow[600]!;
    if (mood >= 2.5) return Colors.orange[400]!;
    if (mood >= 2.0) return Colors.deepOrange[400]!;
    return Colors.red[600]!;
  }

  /// Карточка места регистрации в стиле карточек городов
  Widget _buildRegistrationLocationCityCard(ThemeData theme) {
    final cityName = _extractCityFromLocation(_registrationLocation!);
    final cityPopulation = _getCityPopulation(cityName, _selectedRegionId);
    // Используем нейтральное настроение для карточки (можно будет заменить на реальное)
    final averageMood = 3.0;
    final moodColor = _getColorByMood(averageMood);
    final moodLevel = MoodLevel.neutral; // Можно заменить на реальное значение

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: const Color(0xFF0039A6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                    moodLevel.emoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${averageMood.toStringAsFixed(1)}/5',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Название населенного пункта в левом верхнем углу
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Иконка места вместо номера
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: moodColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFF0039A6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Название города/населенного пункта
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          cityName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0039A6),
                          ),
                          maxLines: 2,
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
                            cityPopulation > 0
                                ? '${cityPopulation.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} чел.'
                                : '—',
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
          // Информация внизу карточки
          Padding(
            padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      '0',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 60),
                      child: Text(
                        '0%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
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
                      value: averageMood / 5.0,
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
    );
  }

}
