import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/storage_service.dart';
import '../services/settlements_data_service.dart';
import '../providers/mood_provider.dart';
import '../models/federal_district_mood.dart';
import '../models/region_mood.dart';
import '../models/region_data.dart';
import '../models/city_mood.dart';
import '../models/settlement.dart';
import '../widgets/mood_cards.dart';

/// Экран профиля с историей чек-инов
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  
  // Данные профиля
  String? _profileName;
  String? _profileImagePath;
  String? _profileLocation;
  String? _profilePhone;
  
  // Распарсенные данные места регистрации
  String? _federalDistrictName;
  String? _regionName;
  String? _cityName;
  
  // Поиск города для выбора места проживания
  final TextEditingController _citySearchController = TextEditingController();
  String _citySearchQuery = '';
  List<Settlement> _searchResults = [];
  Map<String, String> _settlementToRegion = {}; // Маппинг: settlement.id -> region.name
  Map<String, String> _settlementToDistrict = {}; // Маппинг: settlement.id -> district.name (район)
  bool _isSearching = false;
  Settlement? _selectedSettlement;
  String? _selectedSettlementRegionName;

  @override
  void initState() {
    super.initState();
    _citySearchController.addListener(_onCitySearchChanged);
    _loadAllData();
    // Загружаем данные из провайдера
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MoodProvider>();
      provider.loadFederalDistrictsRanking();
      provider.loadRegionsRanking();
      provider.loadAllCitiesRanking();
      await provider.loadSettlementsData();
      // Загружаем выбранный населенный пункт, если есть местоположение
      if (_profileLocation != null && _profileLocation!.isNotEmpty) {
        await _loadSelectedSettlementFromLocation(_profileLocation!);
      }
    });
  }

  @override
  void dispose() {
    _citySearchController.dispose();
    super.dispose();
  }

  /// Обработчик изменения текста в поисковой строке
  void _onCitySearchChanged() {
    final query = _citySearchController.text.trim();
    setState(() {
      _citySearchQuery = query;
      _isSearching = query.isNotEmpty;
    });
    
    if (query.isNotEmpty) {
      _performCitySearch(query);
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  /// Выполнить поиск городов
  Future<void> _performCitySearch(String query) async {
    try {
      final service = SettlementsDataService();
      final results = await service.searchSettlements(query);
      
      // Сначала показываем результаты без регионов, чтобы UI не зависал
      setState(() {
        _searchResults = results;
        _settlementToRegion = {}; // Очищаем старые данные
      });
      
      // Находим регионы для найденных населенных пунктов асинхронно
      // Выполняем в отдельном Future, чтобы не блокировать UI
      Future.microtask(() async {
        final provider = context.read<MoodProvider>();
        await provider.loadSettlementsData();
        final allRegions = provider.getAllRegionsData();
        final settlementToRegion = <String, String>{};
        final settlementToDistrict = <String, String>{};
        
        // Ограничиваем количество обрабатываемых результатов для производительности
        final resultsToProcess = results.take(20).toList();
        
        for (final settlement in resultsToProcess) {
          String? regionName;
          String? districtName;
          
          // Извлекаем ID региона из ID населенного пункта (формат: "24-673" -> "24")
          final regionIdFromSettlement = settlement.id.split('-').first;
          
          // Ищем регион по ID из settlement.id
          bool found = false;
          try {
            final region = allRegions.firstWhere(
              (r) => r.id == regionIdFromSettlement,
            );
            
            // Проверяем города региона
            for (final city in region.cities) {
              if (city.id == settlement.id) {
                regionName = region.name;
                found = true;
                break;
              }
            }
            
            // Если не нашли в городах, проверяем населенные пункты в округах
            if (!found) {
              for (final district in region.urbanDistricts) {
                for (final s in district.settlements) {
                  if (s.id == settlement.id) {
                    regionName = region.name;
                    districtName = district.name;
                    found = true;
                    break;
                  }
                }
                if (found) break;
              }
            }
          } catch (e) {
            // Если не нашли регион по ID, используем старую логику поиска по всем регионам
            // (но это должно быть редко)
            for (final region in allRegions) {
              // Проверяем города региона
              for (final city in region.cities) {
                if (city.id == settlement.id) {
                  regionName = region.name;
                  found = true;
                  break;
                }
              }
              if (found) break;
              
              // Проверяем населенные пункты в округах
              for (final district in region.urbanDistricts) {
                for (final s in district.settlements) {
                  if (s.id == settlement.id) {
                    regionName = region.name;
                    districtName = district.name;
                    found = true;
                    break;
                  }
                }
                if (found) break;
              }
              if (found) break;
            }
          }
          
          if (regionName != null) {
            settlementToRegion[settlement.id] = regionName;
          }
          if (districtName != null) {
            settlementToDistrict[settlement.id] = districtName;
          }
        }
        
        // Обновляем UI только если виджет еще смонтирован и запрос не изменился
        if (mounted && _citySearchQuery == query) {
          setState(() {
            _settlementToRegion = settlementToRegion;
            _settlementToDistrict = settlementToDistrict;
          });
        }
      });
    } catch (e) {
      debugPrint('Ошибка поиска городов: $e');
    }
  }

  /// Выбрать город/населенный пункт
  Future<void> _selectSettlement(Settlement settlement) async {
    // Находим регион для этого населенного пункта
    final provider = context.read<MoodProvider>();
    await provider.loadSettlementsData();
    final allRegions = provider.getAllRegionsData();
    
    String? regionName;
    String? federalDistrictName;
    
    // Извлекаем ID региона из ID населенного пункта (формат: "24-673" -> "24")
    final regionIdFromSettlement = settlement.id.split('-').first;
    debugPrint('Выбран населенный пункт: ${settlement.name}, ID: ${settlement.id}, ID региона: $regionIdFromSettlement');
    
    // Ищем регион по ID из settlement.id
    try {
      final region = allRegions.firstWhere(
        (r) => r.id == regionIdFromSettlement,
      );
      debugPrint('Найден регион по ID: ${region.name} (ID: ${region.id})');
      
      // Проверяем города региона
      bool found = false;
      for (final city in region.cities) {
        if (city.id == settlement.id) {
          regionName = region.name;
          federalDistrictName = region.federalDistrict;
          found = true;
          debugPrint('Найден в городах региона: ${region.name}');
          break;
        }
      }
      
      // Если не нашли в городах, проверяем населенные пункты в округах
      if (!found) {
        for (final district in region.urbanDistricts) {
          for (final s in district.settlements) {
            if (s.id == settlement.id) {
              regionName = region.name;
              federalDistrictName = region.federalDistrict;
              found = true;
              debugPrint('Найден в округах региона: ${region.name}, район: ${district.name}');
              break;
            }
          }
          if (found) break;
        }
      }
      
      if (!found) {
        debugPrint('⚠️ Населенный пункт не найден в регионе ${region.name} по ID ${settlement.id}');
      }
    } catch (e) {
      debugPrint('⚠️ Регион с ID $regionIdFromSettlement не найден. Ошибка: $e');
      // Если не нашли регион по ID, используем старую логику поиска по всем регионам
      for (final region in allRegions) {
        // Проверяем города региона
        for (final city in region.cities) {
          if (city.id == settlement.id) {
            regionName = region.name;
            federalDistrictName = region.federalDistrict;
            debugPrint('Найден в городах (поиск по всем регионам): ${region.name}');
            break;
          }
        }
        if (regionName != null) break;
        
        // Проверяем населенные пункты в округах
        for (final district in region.urbanDistricts) {
          for (final s in district.settlements) {
            if (s.id == settlement.id) {
              regionName = region.name;
              federalDistrictName = region.federalDistrict;
              debugPrint('Найден в округах (поиск по всем регионам): ${region.name}, район: ${district.name}');
              break;
            }
          }
          if (regionName != null) break;
        }
        if (regionName != null) break;
      }
    }
    
    debugPrint('Итоговый регион для ${settlement.name}: $regionName');
    
    // Если регион не найден, пытаемся найти его еще раз через SettlementsDataService
    if (regionName == null) {
      debugPrint('⚠️ Регион не найден, пытаемся найти через SettlementsDataService');
      try {
        final service = SettlementsDataService();
        final region = await service.findRegionById(regionIdFromSettlement);
        if (region != null) {
          regionName = region.name;
          federalDistrictName = region.federalDistrict;
          debugPrint('✓ Регион найден через SettlementsDataService: $regionName');
        }
      } catch (e) {
        debugPrint('⚠️ Ошибка поиска региона через SettlementsDataService: $e');
      }
    }
    
    debugPrint('Финальный регион для сохранения: $regionName');
    
    setState(() {
      _selectedSettlement = settlement;
      _selectedSettlementRegionName = regionName;
      _citySearchQuery = '';
      _citySearchController.clear();
      _searchResults = [];
      _isSearching = false;
    });
    
    // Сохраняем выбранное место в профиль
    if (federalDistrictName != null && regionName != null) {
      String location;
      if (settlement.type.toLowerCase() == 'город') {
        location = '$federalDistrictName - $regionName - ${settlement.name}';
      } else {
        // Для сел/деревень/поселков нужно найти район
        // Пока используем упрощенный формат
        location = '$federalDistrictName - $regionName - ${settlement.name}';
      }
      
      await _storageService.saveProfile(
        name: _profileName ?? '',
        imagePath: _profileImagePath ?? '',
        location: location,
        phone: _profilePhone,
      );
      
      // Перезагружаем данные профиля
      await _loadProfileData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Обновляем при возврате на экран
    _loadAllData();
  }

  /// Загрузить все данные профиля
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      await _loadProfileData();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Загрузить данные профиля
  Future<void> _loadProfileData() async {
    try {
      final name = await _storageService.getProfileName();
      final imagePath = await _storageService.getProfileImagePath();
      final location = await _storageService.getProfileLocation();
      final phone = await _storageService.getProfilePhone();
      
      // Отладочный вывод (можно убрать позже)
      debugPrint('Загружены данные профиля:');
      debugPrint('  Имя: $name');
      debugPrint('  Путь к фото: $imagePath');
      debugPrint('  Местоположение: $location');
      debugPrint('  Телефон: $phone');
      
      if (mounted) {
        setState(() {
          _profileName = name;
          _profileImagePath = imagePath;
          _profileLocation = location;
          _profilePhone = phone;
          // Парсим место регистрации
          if (location != null && location.isNotEmpty) {
            _parseLocation(location);
            // Загружаем выбранный населенный пункт, если есть
            _loadSelectedSettlementFromLocation(location);
          } else {
            _selectedSettlement = null;
            _selectedSettlementRegionName = null;
          }
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки данных профиля: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Мой профиль',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0039A6),
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadProfileData();
            },
            tooltip: 'Обновить',
          ),
          // Кнопка сброса только в дебаг версии
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _showResetDialog,
              tooltip: 'Сбросить данные (Debug)',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadProfileData();
              },
              child: CustomScrollView(
                slivers: [
                  // Заголовок профиля
                  SliverToBoxAdapter(
                    child: _buildProfileHeader(theme),
                  ),
                  // Поисковая строка для выбора города проживания
                  SliverToBoxAdapter(
                    child: _buildCitySearchSection(theme),
                  ),
                  // Карточка города (только одна, самая нижняя)
                  if (_selectedSettlement != null)
                    SliverToBoxAdapter(
                      child: Consumer<MoodProvider>(
                        builder: (context, provider, _) {
                          final settlement = _selectedSettlement!;
                          final regionId = settlement.id.split('-').first;
                          
                          // Пытаемся найти данные о настроении для этого населенного пункта
                          CityMood? cityMood;
                          
                          try {
                            // Сначала ищем по точному совпадению ID
                            cityMood = provider.allCities.firstWhere(
                              (c) => c.id == settlement.id,
                            );
                          } catch (e) {
                            try {
                              // Затем ищем по комбинации regionId + имя
                              cityMood = provider.allCities.firstWhere(
                                (c) => c.regionId == regionId &&
                                      c.name.toLowerCase().trim() == settlement.name.toLowerCase().trim(),
                              );
                            } catch (e) {
                              try {
                                // Затем ищем по точному совпадению имени
                                cityMood = provider.allCities.firstWhere(
                                  (c) => c.name.toLowerCase().trim() == settlement.name.toLowerCase().trim(),
                                );
                              } catch (e) {
                                try {
                                  // Затем ищем по частичному совпадению имени с учетом regionId
                                  cityMood = provider.allCities.firstWhere(
                                    (c) => c.regionId == regionId &&
                                          (c.name.toLowerCase().trim().contains(settlement.name.toLowerCase().trim()) ||
                                           settlement.name.toLowerCase().trim().contains(c.name.toLowerCase().trim())),
                                  );
                                } catch (e) {
                                  try {
                                    // Последняя попытка: частичное совпадение имени без regionId
                                    cityMood = provider.allCities.firstWhere(
                                      (c) => c.name.toLowerCase().trim().contains(settlement.name.toLowerCase().trim()) ||
                                            settlement.name.toLowerCase().trim().contains(c.name.toLowerCase().trim()),
                                    );
                                  } catch (e) {
                                    cityMood = null;
                                  }
                                }
                              }
                            }
                          }
                          
                          // Если данных нет, создаем заглушку с нулевым настроением
                          final moodForCard = cityMood ?? CityMood(
                            id: settlement.id,
                            name: settlement.name,
                            regionId: regionId,
                            averageMood: 0,
                            totalCheckIns: 0,
                            population: settlement.population,
                            lastUpdate: DateTime.fromMillisecondsSinceEpoch(0),
                          );
                          
                          // Находим ранг города в общем списке (с учетом сортировки как в AllCitiesScreen)
                          final sortedCities = List<CityMood>.from(provider.allCities);
                          sortedCities.sort((a, b) {
                            final aHasVotes = a.totalCheckIns > 0;
                            final bHasVotes = b.totalCheckIns > 0;
                            
                            if (aHasVotes && bHasVotes) {
                              return b.averageMood.compareTo(a.averageMood);
                            }
                            if (aHasVotes && !bHasVotes) return -1;
                            if (!aHasVotes && bHasVotes) return 1;
                            return b.population.compareTo(a.population);
                          });
                          
                          int rank = sortedCities.indexWhere((c) => c.id == moodForCard.id) + 1;
                          if (rank == 0) {
                            rank = sortedCities.length + 1;
                          }
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: CityCard(
                              city: moodForCard,
                              rank: rank,
                              isClickable: false,
                              settlementType: settlement.type,
                              regionName: _selectedSettlementRegionName,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  /// Заголовок профиля с фото, именем и местом регистрации
  Widget _buildProfileHeader(ThemeData theme) {
    // Проверяем существование файла изображения
    bool hasImage = false;
    if (_profileImagePath != null) {
      try {
        hasImage = File(_profileImagePath!).existsSync();
      } catch (e) {
        // Игнорируем ошибки проверки файла
        hasImage = false;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Фото профиля (квадратное с закругленными углами) - кликабельное
          GestureDetector(
            onTap: _showImageSourceDialog,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 100,
                height: 100,
                color: Colors.grey[300],
                child: hasImage
                    ? Image.file(
                        File(_profileImagePath!),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.person, size: 50, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Имя и место регистрации справа от фото
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Имя
                if (_profileName != null && _profileName!.isNotEmpty)
                  Text(
                    _profileName!,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  )
                else
                  Text(
                    'Пользователь',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                // ID профиля (номер телефона)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    _profilePhone != null && _profilePhone!.isNotEmpty
                        ? 'ID профиля: $_profilePhone'
                        : 'ID профиля: не указан',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                
                // Округ, регион и город
                if (_federalDistrictName != null)
                  Text(
                    '$_federalDistrictName Федеральный округ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                if (_regionName != null)
                  Text(
                    _regionName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                if (_cityName != null)
                  Text(
                    _cityName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                if (_federalDistrictName == null && _regionName == null && _cityName == null)
                  Text(
                    'Место не указано',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Выбрать фото профиля
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        await _updateProfileImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при выборе фото: $e')),
        );
      }
    }
  }

  /// Показать диалог выбора источника фото
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Выбрать из галереи'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Сделать фото'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Сохранить фото профиля в постоянное хранилище
  Future<String> _saveProfileImage(File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final profileDir = Directory('${appDir.path}/profile');
    if (!await profileDir.exists()) {
      await profileDir.create(recursive: true);
    }
    
    final fileName = 'profile_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = File('${profileDir.path}/$fileName');
    await imageFile.copy(savedImage.path);
    
    return savedImage.path;
  }

  /// Обновить фото профиля
  Future<void> _updateProfileImage(File imageFile) async {
    try {
      // Показываем индикатор загрузки
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Загружаем актуальные данные профиля из хранилища перед сохранением
      final currentName = await _storageService.getProfileName();
      final currentLocation = await _storageService.getProfileLocation();
      final currentPhone = await _storageService.getProfilePhone();
      
      // Сохраняем фото
      final savedImagePath = await _saveProfileImage(imageFile);
      
      // Сохраняем все данные профиля (включая новое фото)
      // Используем данные из хранилища или из состояния как fallback
      await _storageService.saveProfile(
        name: currentName ?? _profileName ?? '',
        imagePath: savedImagePath,
        location: currentLocation ?? _profileLocation ?? '',
        phone: currentPhone ?? _profilePhone,
      );

      // Обновляем состояние, загружая все данные заново
      if (mounted) {
        Navigator.pop(context); // Закрываем индикатор загрузки
        // Перезагружаем все данные профиля для синхронизации
        await _loadProfileData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Фото профиля обновлено'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Закрываем индикатор загрузки
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления фото: $e')),
        );
      }
    }
  }

  /// Парсить место регистрации для извлечения округа, региона и населенного пункта
  void _parseLocation(String location) {
    // Формат: 
    // Для города: "Округ - Регион - Город"
    // Для села/деревни/поселка: "Округ - Регион - Район - Населенный пункт"
    final parts = location.split(' - ');
    if (parts.length >= 1) {
      _federalDistrictName = parts[0].trim();
    }
    if (parts.length >= 2) {
      _regionName = parts[1].trim();
    }
    if (parts.length >= 4) {
      // Если есть 4 части: Округ - Регион - Район - Населенный пункт (село/деревня/поселок)
      _cityName = parts[3].trim();
    } else if (parts.length >= 3) {
      // Если есть 3 части: Округ - Регион - Город (или населенный пункт без района)
      _cityName = parts[2].trim();
    } else {
      _cityName = null;
    }
  }

  /// Найти федеральный округ по имени
  FederalDistrictMood? _findFederalDistrict(String name, MoodProvider provider) {
    if (provider.federalDistricts.isEmpty) return null;
    try {
      return provider.federalDistricts.firstWhere(
        (district) => district.name.toLowerCase().contains(name.toLowerCase()) ||
            name.toLowerCase().contains(district.name.toLowerCase()),
      );
    } catch (e) {
      return null;
    }
  }

  /// Найти регион по имени
  RegionMood? _findRegion(String name, MoodProvider provider) {
    if (provider.regions.isEmpty) return null;
    try {
      return provider.regions.firstWhere(
        (region) => region.name.toLowerCase().contains(name.toLowerCase()) ||
            name.toLowerCase().contains(region.name.toLowerCase()),
      );
    } catch (e) {
      return null;
    }
  }

  /// Найти город по имени
  CityMood? _findCity(String name, MoodProvider provider) {
    if (provider.allCities.isEmpty) return null;
    try {
      return provider.allCities.firstWhere(
        (city) => city.name.toLowerCase() == name.toLowerCase() ||
            city.name.toLowerCase().contains(name.toLowerCase()) ||
            name.toLowerCase().contains(city.name.toLowerCase()),
      );
    } catch (e) {
      return null;
    }
  }

  /// Загрузить выбранный населенный пункт из местоположения
  Future<void> _loadSelectedSettlementFromLocation(String location) async {
    if (_cityName == null || _cityName!.isEmpty) {
      _selectedSettlement = null;
      _selectedSettlementRegionName = null;
      return;
    }

    try {
      final provider = context.read<MoodProvider>();
      await provider.loadSettlementsData();
      final service = SettlementsDataService();
      
      // Ищем населенный пункт по имени
      final results = await service.searchSettlements(_cityName!);
      if (results.isNotEmpty) {
        // Пытаемся найти населенный пункт, который соответствует сохраненному региону
        Settlement? settlement;
        String? regionName;
        
        // Если есть информация о регионе в location, используем её для точного поиска
        if (_regionName != null && _regionName!.isNotEmpty) {
          final allRegions = provider.getAllRegionsData();
          // Ищем регион по имени из сохраненного местоположения
          RegionData? targetRegion;
          try {
            targetRegion = allRegions.firstWhere(
              (r) => r.name.toLowerCase() == _regionName!.toLowerCase(),
            );
          } catch (e) {
            // Регион не найден по точному совпадению, ищем по частичному
            try {
              targetRegion = allRegions.firstWhere(
                (r) => r.name.toLowerCase().contains(_regionName!.toLowerCase()) ||
                    _regionName!.toLowerCase().contains(r.name.toLowerCase()),
              );
            } catch (e) {
              targetRegion = null;
            }
          }
          
          if (targetRegion != null) {
            // Ищем населенный пункт в этом регионе
            for (final result in results) {
              final regionIdFromSettlement = result.id.split('-').first;
              if (regionIdFromSettlement == targetRegion.id) {
                settlement = result;
                regionName = targetRegion.name;
                break;
              }
            }
          }
        }
        
        // Если не нашли по региону, берем первый результат и определяем регион по ID
        if (settlement == null) {
          settlement = results.first;
          
          // Извлекаем ID региона из ID населенного пункта (формат: "24-673" -> "24")
          final regionIdFromSettlement = settlement.id.split('-').first;
          final allRegions = provider.getAllRegionsData();
          
          try {
            final region = allRegions.firstWhere(
              (r) => r.id == regionIdFromSettlement,
            );
            
            // Проверяем, что населенный пункт действительно в этом регионе
            bool found = false;
            for (final city in region.cities) {
              if (city.id == settlement.id) {
                regionName = region.name;
                found = true;
                break;
              }
            }
            
            if (!found) {
              for (final district in region.urbanDistricts) {
                for (final s in district.settlements) {
                  if (s.id == settlement.id) {
                    regionName = region.name;
                    found = true;
                    break;
                  }
                }
                if (found) break;
              }
            }
          } catch (e) {
            debugPrint('⚠️ Регион с ID $regionIdFromSettlement не найден при загрузке из местоположения: $e');
          }
        }
        
        if (mounted && settlement != null) {
          debugPrint('Загружен населенный пункт из местоположения: ${settlement.name}, регион: $regionName');
          setState(() {
            _selectedSettlement = settlement;
            _selectedSettlementRegionName = regionName;
          });
        }
      }
    } catch (e) {
      debugPrint('Ошибка загрузки выбранного населенного пункта: $e');
    }
  }

  /// Построить секцию поиска города
  Widget _buildCitySearchSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Город проживания',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0039A6),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _citySearchController,
            decoration: InputDecoration(
              hintText: 'Поиск города, села, деревни...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
              suffixIcon: _citySearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        _citySearchController.clear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              isDense: true,
            ),
          ),
          // Результаты поиска
          if (_isSearching && _searchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length > 20 ? 20 : _searchResults.length,
                itemBuilder: (context, index) {
                  final settlement = _searchResults[index];
                  final regionName = _settlementToRegion[settlement.id];
                  final districtName = _settlementToDistrict[settlement.id];
                  
                  // Формируем строку с информацией
                  final populationStr = settlement.population.toString().replaceAllMapped(
                    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                    (Match m) => '${m[1]} ',
                  );
                  
                  String subtitleText = '${settlement.type} • $populationStr чел.';
                  if (districtName != null) {
                    subtitleText += ' • $districtName';
                  }
                  if (regionName != null) {
                    subtitleText += ' • $regionName';
                  }
                  
                  return ListTile(
                    dense: true,
                    title: Text(
                      settlement.name,
                      style: theme.textTheme.bodyMedium,
                    ),
                    subtitle: Text(
                      subtitleText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    onTap: () => _selectSettlement(settlement),
                  );
                },
              ),
            ),
          ],
          if (_isSearching && _searchResults.isEmpty && _citySearchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Ничего не найдено',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Построить карточку выбранного населенного пункта
  Widget _buildSelectedSettlementCard(ThemeData theme) {
    if (_selectedSettlement == null) return const SizedBox.shrink();
    
    return Consumer<MoodProvider>(
      builder: (context, provider, child) {
        // Пытаемся найти данные о настроении для этого населенного пункта
        // Важно: ищем только по ID, чтобы не найти неправильный город с таким же названием
        CityMood? cityMood;
        try {
          cityMood = provider.allCities.firstWhere(
            (c) => c.id == _selectedSettlement!.id,
          );
        } catch (e) {
          // Если не нашли по ID, не ищем по имени, чтобы избежать неправильного совпадения
          cityMood = null;
        }

        // Если данных нет, создаем заглушку
        final moodForCard = cityMood ?? CityMood(
          id: _selectedSettlement!.id,
          name: _selectedSettlement!.name,
          regionId: '',
          averageMood: 0,
          totalCheckIns: 0,
          population: _selectedSettlement!.population,
          lastUpdate: DateTime.fromMillisecondsSinceEpoch(0),
        );

        // Находим ранг города в общем списке
        int rank = provider.allCities.indexWhere((c) => c.id == moodForCard.id) + 1;
        if (rank == 0) {
          rank = 1;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: CityCard(
            city: moodForCard,
            rank: rank,
            isClickable: false,
            settlementType: _selectedSettlement!.type,
            regionName: _selectedSettlementRegionName,
          ),
        );
      },
    );
  }

  /// Показать диалог подтверждения сброса
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Сброс данных (Debug)'),
          content: const Text(
            'Вы уверены, что хотите сбросить:\n'
            '• Все чек-ины\n'
            '• Местоположение (город проживания)\n'
            '• Кэш рейтингов\n\n'
            'Это действие нельзя отменить.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetData();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Сбросить'),
            ),
          ],
        );
      },
    );
  }

  /// Сбросить данные (город и голосования)
  Future<void> _resetData() async {
    try {
      // Показываем индикатор загрузки
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Очищаем данные голосования локально
      await _storageService.clearCheckIns();
      
      // Очищаем чек-ины на сервере
      try {
        final provider = context.read<MoodProvider>();
        await provider.deleteAllCheckIns();
      } catch (e) {
        debugPrint('⚠️ Ошибка удаления чек-инов на сервере: $e');
        // Продолжаем выполнение, даже если не удалось удалить на сервере
      }
      
      // Очищаем кэш рейтингов
      await _storageService.clearRankingsCache();
      
      // Очищаем выбор города из профиля
      await _storageService.clearProfileLocation();
      
      // Очищаем состояние выбранного города
      setState(() {
        _selectedSettlement = null;
        _selectedSettlementRegionName = null;
        _profileLocation = null;
        _federalDistrictName = null;
        _regionName = null;
        _cityName = null;
      });

      // Перезагружаем данные профиля
      await _loadProfileData();

      // Обновляем провайдер для пересчета рейтингов (загружаем свежие данные с сервера)
      final provider = context.read<MoodProvider>();
      await provider.loadSettlementsData();
      await provider.loadFederalDistrictsRanking();
      await provider.loadRegionsRanking();
      await provider.loadAllCitiesRanking();

      if (mounted) {
        Navigator.pop(context); // Закрываем индикатор загрузки
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Данные успешно сброшены'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Закрываем индикатор загрузки
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при сбросе данных: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Старые методы удалены - используем общие виджеты из widgets/mood_cards.dart
}
