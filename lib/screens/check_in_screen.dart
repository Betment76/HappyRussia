import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/mood_provider.dart';
import '../models/mood_level.dart';
import '../models/check_in.dart';
import '../models/city_mood.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../data/russian_regions.dart';
import '../data/region_cities_data.dart';
import '../services/settlements_data_service.dart';
import 'dart:async';

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
  
  // Выбранная карточка населенного пункта
  String? _selectedLocationType; // 'registration' или 'geolocation'
  UserLocation? _currentGeolocation; // Текущая геолокация
  bool _isLoadingGeolocation = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initializeRegion();
    // Загружаем данные о городах для отображения реального прогресса
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MoodProvider>();
      provider.loadSettlementsData();
      provider.loadAllCitiesRanking();
      // Загружаем геолокацию
      _loadGeolocation();
    });
  }

  /// Загрузить текущую геолокацию
  Future<void> _loadGeolocation() async {
    setState(() {
      _isLoadingGeolocation = true;
    });
    
    try {
      final location = await _locationService.getUserLocation();
      if (location.isValid) {
        setState(() {
          _currentGeolocation = location;
          // Если регион еще не определен, определяем его из геолокации
          if (_selectedRegionId == null && location.region != null) {
            final region = RussianRegions.findByName(location.region!);
            if (region != null) {
              _selectedRegionId = region['id'];
              _selectedRegionName = region['name'];
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки геолокации: $e');
      // Не показываем ошибку пользователю, просто не загружаем геолокацию
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGeolocation = false;
        });
      }
    }
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

    if (_selectedLocationType == null) {
      _showError('Выберите населенный пункт для чек-ина');
      return;
    }

    if (_selectedRegionId == null) {
      _showError('Выберите регион');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Определяем город для чек-ина на основе выбранной карточки
      String? cityName;
      String? cityId;
      String? federalDistrict;
      String? district;
      
      if (_selectedLocationType == 'geolocation' && _currentGeolocation != null) {
        // Используем данные из геолокации
        cityName = _currentGeolocation!.city ?? _currentGeolocation!.settlement;
        federalDistrict = _currentGeolocation!.federalDistrict;
        district = _currentGeolocation!.district;
        
        if (cityName != null && _selectedRegionId != null) {
          cityId = await _findCityId(cityName, _selectedRegionId!);
        }
      } else if (_selectedLocationType == 'registration' && _registrationLocation != null) {
        // Используем данные из места регистрации - именно то, что указано
        debugPrint('Чек-ин: выбрана карточка "Место регистрации"');
        debugPrint('Чек-ин: _registrationLocation = $_registrationLocation');
        
        final locationInfo = _extractLocationInfo(_registrationLocation);
        cityName = locationInfo['cityName'];
        federalDistrict = locationInfo['federalDistrict'];
        district = locationInfo['district'];
        
        debugPrint('Чек-ин: извлечено из места регистрации:');
        debugPrint('  - cityName = $cityName');
        debugPrint('  - federalDistrict = $federalDistrict');
        debugPrint('  - district = $district');
        debugPrint('Чек-ин: regionId = $_selectedRegionId, regionName = $_selectedRegionName');
        
        if (cityName != null && _selectedRegionId != null) {
          debugPrint('Чек-ин: ищем cityId для "$cityName" в регионе $_selectedRegionId');
          cityId = await _findCityId(cityName, _selectedRegionId!);
          debugPrint('Чек-ин: найден cityId = $cityId для города $cityName в регионе $_selectedRegionId');
          
          if (cityId == null) {
            debugPrint('⚠️ Чек-ин: cityId не найден! Возможно, город "$cityName" не существует в регионе $_selectedRegionId');
          }
        } else {
          debugPrint('⚠️ Чек-ин: cityName или regionId пустые - cityName: $cityName, regionId: $_selectedRegionId');
        }
      }
      
      // Получаем userId из профиля (номер телефона) - обязательное поле
      String? userId;
      try {
        userId = await _storageService.getProfilePhone();
        debugPrint('Чек-ин: userId из профиля = $userId');
      } catch (e) {
        debugPrint('⚠️ Чек-ин: не удалось получить userId из профиля: $e');
      }
      
      // Проверяем, что userId обязателен
      if (userId == null || userId.isEmpty || userId.trim().isEmpty) {
        _showError('Номер телефона не указан в профиле. Пожалуйста, укажите номер телефона в настройках профиля.');
        setState(() => _isSubmitting = false);
        return;
      }
      
      // Логируем финальные данные перед отправкой
      debugPrint('Чек-ин: Финальные данные - cityName: $cityName, cityId: $cityId, regionId: $_selectedRegionId, locationType: $_selectedLocationType, userId: $userId');

      final checkIn = CheckIn(
        id: const Uuid().v4(),
        regionId: _selectedRegionId!,
        regionName: _selectedRegionName!,
        mood: _selectedMood!,
        date: DateTime.now(),
        userId: userId, // Передаем userId из профиля
        cityId: cityId,
        cityName: cityName,
        federalDistrict: federalDistrict,
        district: district,
      );

      await context.read<MoodProvider>().submitCheckIn(checkIn);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
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
        padding: const EdgeInsets.all(8),
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
            const SizedBox(height: 8),

            // Смайлики
            _buildMoodSelector(theme),

            const SizedBox(height: 16),

            // Заголовок выбора населенного пункта
            Text(
              'Выберите населенный пункт для чек-ина:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Карточка места регистрации
            if (_registrationLocation != null && _registrationLocation!.isNotEmpty)
              Consumer<MoodProvider>(
                builder: (context, provider, child) {
                  return _buildLocationCard(
                    theme,
                    'registration',
                    'Место регистрации',
                    _registrationLocation!,
                    provider,
                  );
                },
              ),

            // Карточка текущей геолокации
            if (_isLoadingGeolocation)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_currentGeolocation != null && _currentGeolocation!.isValid)
              Consumer<MoodProvider>(
                builder: (context, provider, child) {
                  return _buildLocationCard(
                    theme,
                    'geolocation',
                    'Текущее местоположение',
                    _currentGeolocation!.formattedLocation,
                    provider,
                  );
                },
              ),

            const SizedBox(height: 10),

            // Кнопка отправки
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0039A6),
                  foregroundColor: Colors.white,
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
    // Первые 4 карточки в два столбца
    final firstFourMoods = MoodLevel.values.take(4).toList();
    // Последняя карточка "Прекрасно" отдельно
    final lastMood = MoodLevel.values.last;
    
    return Column(
      children: [
        // Первый ряд: Очень грустно, Грустно
        Row(
          children: [
            Expanded(
              child: _buildMoodButton(firstFourMoods[0], theme),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMoodButton(firstFourMoods[1], theme),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Второй ряд: Нейтрально, Хорошо (без отступа снизу)
        Row(
          children: [
            Expanded(
              child: _buildMoodButton(firstFourMoods[2], theme),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMoodButton(firstFourMoods[3], theme),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Карточка "Прекрасно" на всю ширину
        _buildMoodButton(lastMood, theme, isFullWidth: true),
      ],
    );
  }

  Widget _buildMoodButton(MoodLevel mood, ThemeData theme, {bool isFullWidth = false}) {
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
        width: isFullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          vertical: isFullWidth ? 16 : 12,
          horizontal: isFullWidth ? 16 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: isFullWidth
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      mood.emoji,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    mood.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? color : theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      mood.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      mood.label,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? color : theme.textTheme.bodyMedium?.color,
                      ),
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
      debugPrint('⚠️ _extractLocationInfo: location пустое');
      return {
        'federalDistrict': null,
        'district': null,
        'cityName': null,
      };
    }

    debugPrint('_extractLocationInfo: парсим location = "$location"');
    
    // Формат: "Округ - Регион - Район/Город - Населенный пункт"
    // или: "Округ - Регион - Город" (для городов)
    final parts = location.split(' - ');
    debugPrint('_extractLocationInfo: разбито на ${parts.length} частей: $parts');
    
    String? federalDistrict;
    String? district;
    String? cityName;

    if (parts.isNotEmpty) {
      federalDistrict = parts[0].trim();
    }
    
    if (parts.length >= 4) {
      // Если есть населенный пункт, берем его и район
      // Формат: "Округ - Регион - Район - Населенный пункт"
      district = parts[2].trim();
      cityName = parts[3].trim();
      debugPrint('_extractLocationInfo: формат с районом - district: $district, cityName: $cityName');
    } else if (parts.length >= 3) {
      // Если есть город/район, берем его
      // Формат: "Округ - Регион - Город"
      cityName = parts[2].trim();
      debugPrint('_extractLocationInfo: формат без района - cityName: $cityName');
    } else {
      debugPrint('⚠️ _extractLocationInfo: неожиданный формат - меньше 3 частей');
    }

    final result = {
      'federalDistrict': federalDistrict,
      'district': district,
      'cityName': cityName,
    };
    debugPrint('_extractLocationInfo: результат = $result');
    return result;
  }

  /// Найти ID города/населенного пункта по названию и региону
  Future<String?> _findCityId(String cityName, String regionId) async {
    try {
      final service = SettlementsDataService();
      final region = await service.findRegionById(regionId);
      if (region == null) {
        debugPrint('⚠️ Регион с ID $regionId не найден');
        return null;
      }

      final cityNameLower = cityName.toLowerCase().trim();

      // Сначала ищем точное совпадение в городах региона
      for (final city in region.cities) {
        if (city.name.toLowerCase().trim() == cityNameLower) {
          debugPrint('✓ Найден город по точному совпадению: ${city.name}, ID: ${city.id}');
          return city.id;
        }
      }

      // Если не нашли в городах, ищем в населенных пунктах округов
      for (final district in region.urbanDistricts) {
        for (final settlement in district.settlements) {
          if (settlement.name.toLowerCase().trim() == cityNameLower) {
            debugPrint('✓ Найден населенный пункт по точному совпадению: ${settlement.name}, ID: ${settlement.id}');
            return settlement.id;
          }
        }
      }

      // Если точного совпадения нет, ищем частичное совпадение
      for (final city in region.cities) {
        final name = city.name.toLowerCase().trim();
        if (name.contains(cityNameLower) || cityNameLower.contains(name)) {
          debugPrint('✓ Найден город по частичному совпадению: ${city.name}, ID: ${city.id}');
          return city.id;
        }
      }

      for (final district in region.urbanDistricts) {
        for (final settlement in district.settlements) {
          final name = settlement.name.toLowerCase().trim();
          if (name.contains(cityNameLower) || cityNameLower.contains(name)) {
            debugPrint('✓ Найден населенный пункт по частичному совпадению: ${settlement.name}, ID: ${settlement.id}');
            return settlement.id;
          }
        }
      }

      debugPrint('⚠️ Населенный пункт "$cityName" не найден в регионе $regionId');
      return null;
    } catch (e) {
      debugPrint('⚠️ Ошибка поиска ID города "$cityName" в регионе $regionId: $e');
      return null;
    }
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

  /// Карточка населенного пункта для выбора (место регистрации или геолокация)
  Widget _buildLocationCard(
    ThemeData theme,
    String locationType,
    String title,
    String locationString,
    MoodProvider provider,
  ) {
    final isSelected = _selectedLocationType == locationType;
    // Определяем название города для отображения - используем именно то, что указано
    final cityName = locationType == 'geolocation' 
        ? (_currentGeolocation?.city ?? _currentGeolocation?.settlement ?? '')
        : _extractCityFromLocation(locationString);
    
    // Ищем реальные данные о городе в рейтинге
    CityMood? cityMood;
    if (provider.allCities.isNotEmpty) {
      try {
        cityMood = provider.allCities.firstWhere(
          (city) => city.name.toLowerCase() == cityName.toLowerCase() ||
                    (city.regionId == _selectedRegionId && 
                     city.name.toLowerCase().contains(cityName.toLowerCase())),
        );
      } catch (e) {
        // Если не нашли в allCities, ищем в cities региона
        if (_selectedRegionId != null && provider.cities.isNotEmpty) {
          try {
            cityMood = provider.cities.firstWhere(
              (city) => city.name.toLowerCase() == cityName.toLowerCase() ||
                        city.name.toLowerCase().contains(cityName.toLowerCase()),
            );
          } catch (e) {
            cityMood = null;
          }
        }
      }
    }
    
    // Используем реальные данные или значения по умолчанию
    final averageMood = cityMood?.averageMood ?? 0.0;
    final totalCheckIns = cityMood?.totalCheckIns ?? 0;
    final cityPopulation = cityMood?.population ?? _getCityPopulation(cityName, _selectedRegionId);
    final happyPercentage = cityMood?.happyPercentage ?? 0.0;
    final moodColor = _getColorByMood(averageMood);
    final moodLevel = cityMood?.moodLevel ?? MoodLevel.neutral;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLocationType = locationType;
        });
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: isSelected ? 4 : 2,
        shadowColor: isSelected ? const Color(0xFF0039A6) : Colors.grey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? const Color(0xFF0039A6) : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
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
                      color: moodColor.withValues(alpha: 0.1),
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
                  // Иконка места или галочка выбора
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF0039A6).withValues(alpha: 0.2)
                          : moodColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF0039A6),
                            size: 24,
                          )
                        : const Icon(
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
                        // Заголовок карточки
                        Text(
                          title,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            cityName.isNotEmpty ? cityName : locationString,
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
            // Прогресс-бар и статистика внизу
            Padding(
              padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '$totalCheckIns',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(right: 60),
                        child: Text(
                          '${happyPercentage.toStringAsFixed(2)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 60),
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
      ),
    );
  }

  /// Карточка места регистрации в стиле карточек городов (старый метод, оставлен для совместимости)
  Widget _buildRegistrationLocationCityCard(ThemeData theme) {
    final cityName = _extractCityFromLocation(_registrationLocation!);
    final provider = context.read<MoodProvider>();
    
    // Ищем реальные данные о городе в рейтинге
    CityMood? cityMood;
    if (provider.allCities.isNotEmpty) {
      try {
        cityMood = provider.allCities.firstWhere(
          (city) => city.name.toLowerCase() == cityName.toLowerCase() ||
                    (city.regionId == _selectedRegionId && 
                     city.name.toLowerCase().contains(cityName.toLowerCase())),
        );
      } catch (e) {
        // Если не нашли в allCities, ищем в cities региона
        if (_selectedRegionId != null && provider.cities.isNotEmpty) {
          try {
            cityMood = provider.cities.firstWhere(
              (city) => city.name.toLowerCase() == cityName.toLowerCase() ||
                        city.name.toLowerCase().contains(cityName.toLowerCase()),
            );
          } catch (e) {
            cityMood = null;
          }
        }
      }
    }
    
    // Используем реальные данные или значения по умолчанию
    // Карточка всегда показывается, даже если данные еще не загружены
    final averageMood = cityMood?.averageMood ?? 0.0;
    final totalCheckIns = cityMood?.totalCheckIns ?? 0;
    final cityPopulation = cityMood?.population ?? _getCityPopulation(cityName, _selectedRegionId);
    final happyPercentage = cityMood?.happyPercentage ?? 0.0;
    final moodColor = _getColorByMood(averageMood);
    final moodLevel = cityMood?.moodLevel ?? MoodLevel.neutral;

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
                    color: moodColor.withValues(alpha: 0.1),
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
                    color: moodColor.withValues(alpha: 0.2),
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
                      '$totalCheckIns',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 60),
                      child: Text(
                        '${happyPercentage.toStringAsFixed(1)}%',
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
