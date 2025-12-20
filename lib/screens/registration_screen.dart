import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../data/russian_regions.dart';
import '../data/region_cities_data.dart';
import '../data/region_districts_data.dart';

/// Экран регистрации пользователя
class RegistrationScreen extends StatefulWidget {
  final VoidCallback? onRegistrationComplete;

  const RegistrationScreen({
    super.key,
    this.onRegistrationComplete,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // Выбранные значения для места проживания
  String? _selectedFederalDistrict;
  String? _selectedRegion;
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedSettlement;

  // Списки для выпадающих списков
  List<String> _federalDistricts = [];
  List<Map<String, String>> _regions = [];
  List<Map<String, dynamic>> _cities = [];
  List<String> _districts = [];
  List<String> _settlements = [];

  @override
  void initState() {
    super.initState();
    _loadFederalDistricts();
  }

  /// Загрузить список федеральных округов
  void _loadFederalDistricts() {
    setState(() {
      _federalDistricts = RussianRegions.getFederalDistricts();
    });
  }

  /// Загрузить регионы выбранного округа
  void _loadRegions(String? district) {
    setState(() {
      _selectedRegion = null;
      _selectedCity = null;
      _selectedDistrict = null;
      _selectedSettlement = null;
      _regions = [];
      _cities = [];
      _districts = [];
      _settlements = [];

      if (district != null) {
        _regions = RussianRegions.getByFederalDistrict(district);
      }
    });
  }

  /// Загрузить районы выбранного региона (районы области/края)
  void _loadDistricts(String? regionId) {
    setState(() {
      _selectedCity = null;
      _selectedDistrict = null;
      _selectedSettlement = null;
      _cities = [];
      _districts = [];
      _settlements = [];

      if (regionId != null) {
        // Загружаем реальные данные о районах региона
        _districts = RegionDistrictsData.getDistrictsForRegion(regionId);
        
        // Если данных нет, используем моковые данные
        if (_districts.isEmpty) {
          _districts = [
            'Центральный район',
            'Северный район',
            'Южный район',
            'Восточный район',
            'Западный район',
            'Городской район',
            'Сельский район',
          ];
        }
        
        // Загружаем города для выбора (если район не выбран)
        _loadCities(regionId);
      }
    });
  }

  /// Загрузить города выбранного региона (для справки, неактивен)
  void _loadCities(String? regionId) {
    setState(() {
      _selectedCity = null;
      _cities = [];

      if (regionId != null) {
        _cities = RegionCitiesData.cities[regionId] ?? [];
      }
    });
  }

  /// Загрузить поселки/деревни выбранного района (моковые данные)
  void _loadSettlements(String? districtName) {
    setState(() {
      _selectedSettlement = null;
      _settlements = [];

      if (districtName != null) {
        // Моковые данные для поселков/деревень в районе
        _settlements = [
          'Поселок 1',
          'Поселок 2',
          'Деревня 1',
          'Деревня 2',
          'Село 1',
          'Село 2',
          'Хутор 1',
        ];
      }
    });
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
        setState(() {
          _profileImage = File(image.path);
        });
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
                leading: const Icon(Icons.photo_camera),
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

  /// Валидация номера телефона
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите номер телефона';
    }
    // Простая валидация: только цифры, минимум 10 символов
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    final cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Введите корректный номер телефона';
    }
    return null;
  }

  /// Обработка регистрации
  void _handleRegistration() {
    if (_formKey.currentState!.validate()) {
      if (_profileImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Выберите фото профиля')),
        );
        return;
      }

      if (_selectedFederalDistrict == null || _selectedRegion == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Выберите место проживания (округ, регион)'),
          ),
        );
        return;
      }

      // Проверяем: либо выбран район, либо выбран город
      if (_selectedDistrict == null && _selectedCity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Выберите район или город'),
          ),
        );
        return;
      }

      // TODO: Реализовать сохранение данных регистрации
      final phone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Регистрация успешна! ID: $phone'),
        ),
      );

      // Вызвать callback для завершения регистрации
      if (widget.onRegistrationComplete != null) {
        widget.onRegistrationComplete!();
      } else {
        // Если callback не передан, просто закрываем экран
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Фото профиля
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primary,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        onPressed: _showImageSourceDialog,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Номер телефона
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Номер телефона',
                hintText: '+7 (999) 123-45-67',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.phone,
              validator: _validatePhone,
            ),
            const SizedBox(height: 24),

            // Заголовок "Место проживания"
            Text(
              'Место проживания',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0039A6),
              ),
            ),
            const SizedBox(height: 16),

            // Федеральный округ
            DropdownButtonFormField<String>(
              value: _selectedFederalDistrict,
              decoration: InputDecoration(
                labelText: 'Федеральный округ',
                prefixIcon: const Icon(Icons.map),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _federalDistricts.map((district) {
                return DropdownMenuItem(
                  value: district,
                  child: Text(district),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFederalDistrict = value;
                });
                _loadRegions(value);
              },
              validator: (value) {
                if (value == null) return 'Выберите федеральный округ';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Регион
            DropdownButtonFormField<String>(
              value: _selectedRegion,
              decoration: InputDecoration(
                labelText: 'Регион',
                prefixIcon: const Icon(Icons.location_city),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _regions.map((region) {
                return DropdownMenuItem(
                  value: region['id'],
                  child: Text(region['name'] ?? ''),
                );
              }).toList(),
              onChanged: _selectedFederalDistrict == null
                  ? null
                  : (value) {
                      setState(() {
                        _selectedRegion = value;
                      });
                      _loadDistricts(value); // Загружаем районы региона
                      _loadCities(value); // Загружаем города для справки (неактивны)
                    },
              validator: (value) {
                if (value == null) return 'Выберите регион';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Район (районы области/края)
            DropdownButtonFormField<String>(
              value: _selectedDistrict,
              decoration: InputDecoration(
                labelText: 'Район',
                prefixIcon: const Icon(Icons.place),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _districts.map((district) {
                return DropdownMenuItem(
                  value: district,
                  child: Text(district),
                );
              }).toList(),
              onChanged: _selectedRegion == null
                  ? null
                  : (value) {
                      setState(() {
                        _selectedDistrict = value;
                        // Если выбран район, сбрасываем выбор города
                        if (value != null) {
                          _selectedCity = null;
                        }
                      });
                      _loadSettlements(value);
                    },
              validator: (value) {
                if (value == null) return 'Выберите район';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Поселок/Деревня
            DropdownButtonFormField<String>(
              value: _selectedSettlement,
              decoration: InputDecoration(
                labelText: 'Поселок/Деревня',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _settlements.map((settlement) {
                return DropdownMenuItem(
                  value: settlement,
                  child: Text(settlement),
                );
              }).toList(),
              onChanged: _selectedDistrict == null
                  ? null
                  : (value) {
                      setState(() {
                        _selectedSettlement = value;
                      });
                    },
            ),
            const SizedBox(height: 16),

            // Поселок/Деревня
            DropdownButtonFormField<String>(
              value: _selectedSettlement,
              decoration: InputDecoration(
                labelText: 'Поселок/Деревня',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _settlements.map((settlement) {
                return DropdownMenuItem(
                  value: settlement,
                  child: Text(settlement),
                );
              }).toList(),
              onChanged: _selectedDistrict == null
                  ? null
                  : (value) {
                      setState(() {
                        _selectedSettlement = value;
                      });
                    },
            ),
            const SizedBox(height: 16),

            // Город (активен только если район не выбран)
            DropdownButtonFormField<String>(
              value: _selectedCity,
              decoration: InputDecoration(
                labelText: _selectedDistrict == null ? 'Город' : 'Город (неактивен)',
                prefixIcon: const Icon(Icons.home),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: _selectedDistrict != null,
                fillColor: _selectedDistrict != null ? Colors.grey[200] : null,
              ),
              items: _cities.map((city) {
                return DropdownMenuItem(
                  value: city['name'] as String,
                  child: Text(city['name'] as String),
                );
              }).toList(),
              onChanged: _selectedDistrict == null && _selectedRegion != null
                  ? (value) {
                      setState(() {
                        _selectedCity = value;
                      });
                    }
                  : null, // Неактивен если выбран район
            ),
            const SizedBox(height: 32),

            // Кнопка регистрации
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Зарегистрироваться',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

