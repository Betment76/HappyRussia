import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/storage_service.dart';
import '../providers/mood_provider.dart';
import '../models/federal_district_mood.dart';
import '../models/region_mood.dart';
import '../models/city_mood.dart';
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

  @override
  void initState() {
    super.initState();
    _loadAllData();
    // Загружаем данные из провайдера
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MoodProvider>();
      provider.loadFederalDistrictsRanking();
      provider.loadRegionsRanking();
      provider.loadAllCitiesRanking();
    });
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
                  // Карточка округа
                  if (_federalDistrictName != null)
                    SliverToBoxAdapter(
                      child: Consumer<MoodProvider>(
                        builder: (context, provider, _) {
                          final district = _findFederalDistrict(_federalDistrictName!, provider);
                          if (district != null) {
                            return FederalDistrictCard(
                              district: district,
                              isClickable: false,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  // Карточка региона
                  if (_regionName != null)
                    SliverToBoxAdapter(
                      child: Consumer<MoodProvider>(
                        builder: (context, provider, _) {
                          final region = _findRegion(_regionName!, provider);
                          if (region != null) {
                            return RegionCard(
                              region: region,
                              isClickable: false,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  // Карточка города
                  if (_cityName != null)
                    SliverToBoxAdapter(
                      child: Consumer<MoodProvider>(
                        builder: (context, provider, _) {
                          final city = _findCity(_cityName!, provider);
                          if (city != null) {
                            // Находим ранг города в общем списке
                            int rank = provider.allCities.indexWhere((c) => c.id == city.id) + 1;
                            if (rank == 0) {
                              // Если город не найден в списке, используем 0
                              rank = 1;
                            }
                            return CityCard(
                              city: city,
                              rank: rank,
                              isClickable: false,
                            );
                          }
                          return const SizedBox.shrink();
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

  // Старые методы удалены - используем общие виджеты из widgets/mood_cards.dart
}
