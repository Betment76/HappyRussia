import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';

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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();

  // Местоположение
  UserLocation? _userLocation;
  bool _isDetectingLocation = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
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

  /// Определить местоположение по GPS
  Future<void> _detectLocation() async {
    setState(() {
      _isDetectingLocation = true;
      _userLocation = null;
    });

    try {
      final location = await _locationService.getUserLocation();
      
      if (mounted) {
        setState(() {
          _userLocation = location;
          _isDetectingLocation = false;
        });

        if (!location.isValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Не удалось полностью определить местоположение. Попробуйте еще раз.'),
              action: SnackBarAction(
                label: 'Повторить',
                onPressed: _detectLocation,
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Местоположение успешно определено!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDetectingLocation = false;
        });
        
        // Извлекаем понятное сообщение об ошибке
        String errorMessage = e.toString();
        if (errorMessage.contains('Exception:')) {
          errorMessage = errorMessage.split('Exception:').last.trim();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            action: SnackBarAction(
              label: 'Повторить',
              onPressed: _detectLocation,
            ),
            duration: const Duration(seconds: 8),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  /// Валидация имени
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите имя';
    }
    if (value.trim().length < 2) {
      return 'Имя должно содержать минимум 2 символа';
    }
    return null;
  }

  /// Валидация номера телефона
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return 'Введите номер телефона';
    }
    // Простая валидация: только цифры, минимум 10 цифр (без учета +7)
    final cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length < 10) {
      return 'Введите корректный номер телефона';
    }
    return null;
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

  /// Обработка регистрации
  Future<void> _handleRegistration() async {
    if (_formKey.currentState!.validate()) {
      if (_userLocation == null || !_userLocation!.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Определите местоположение'),
          ),
        );
        return;
      }

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

      try {
        final name = _nameController.text.trim();
        final location = _userLocation!.formattedLocation;
        
        // Сохраняем фото в постоянное хранилище (если выбрано)
        String? savedImagePath;
        if (_profileImage != null) {
          savedImagePath = await _saveProfileImage(_profileImage!);
        }
        
        // Отладочный вывод
        debugPrint('Сохранение данных профиля:');
        debugPrint('  Имя: $name');
        debugPrint('  Путь к фото: $savedImagePath');
        debugPrint('  Местоположение: $location');
        
        // Сохраняем данные профиля
        String phone = _phoneController.text.trim();
        // Добавляем +7 к номеру (так как +7 показывается через prefixText)
        if (phone.isNotEmpty) {
          final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
          phone = '+7$cleanPhone';
        } else {
          phone = '+7';
        }
        await _storageService.saveProfile(
          name: name,
          imagePath: savedImagePath ?? '',
          location: location,
          phone: phone.isNotEmpty && phone != '+7' ? phone : null,
        );
        
        debugPrint('Данные профиля успешно сохранены');
        
        // Проверяем, что данные действительно сохранились
        final savedName = await _storageService.getProfileName();
        final savedImage = await _storageService.getProfileImagePath();
        final savedLocation = await _storageService.getProfileLocation();
        
        debugPrint('Проверка после сохранения:');
        debugPrint('  Сохраненное имя: $savedName');
        debugPrint('  Сохраненный путь: $savedImage');
        debugPrint('  Сохраненное местоположение: $savedLocation');
        
        // Проверяем только обязательные поля (имя и местоположение)
        // Фото необязательно, поэтому savedImage может быть null
        if (savedName == null || savedLocation == null) {
          throw Exception('Данные не были сохранены корректно');
        }

        if (mounted) {
          Navigator.pop(context); // Закрываем индикатор загрузки
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Регистрация успешна!'),
              duration: Duration(seconds: 2),
            ),
          );

          // Небольшая задержка перед переходом, чтобы убедиться, что все сохранено
          await Future.delayed(const Duration(milliseconds: 100));

          // Вызвать callback для завершения регистрации
          if (widget.onRegistrationComplete != null) {
            widget.onRegistrationComplete!();
          } else {
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Закрываем индикатор загрузки
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка сохранения данных: $e'),
            ),
          );
        }
      }
    }
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

            // Имя
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Имя',
                hintText: 'Введите ваше имя',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.words,
              validator: _validateName,
            ),
            const SizedBox(height: 16),

            // Номер телефона
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Номер телефона',
                hintText: '(999) 123-45-67',
                prefixText: '+7 ',
                prefixStyle: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9\s\(\)\-]')),
                LengthLimitingTextInputFormatter(20),
              ],
              validator: _validatePhone,
            ),
            const SizedBox(height: 16),

            // Кнопка определения местоположения
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isDetectingLocation ? null : _detectLocation,
                icon: _isDetectingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.location_on),
                label: Text(_isDetectingLocation ? 'Определение...' : 'Определить местоположение'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Отображение местоположения
            if (_userLocation != null) ...[
              Card(
                color: Colors.grey[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: _userLocation!.isValid
                                ? Colors.green
                                : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Местоположение',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_userLocation!.federalDistrict != null)
                        _buildLocationRow('Округ', _userLocation!.federalDistrict!),
                      if (_userLocation!.region != null)
                        _buildLocationRow('Регион', _userLocation!.region!),
                      if (_userLocation!.district != null)
                        _buildLocationRow('Район', _userLocation!.district!),
                      if (_userLocation!.city != null && _userLocation!.district == null)
                        _buildLocationRow('Город', _userLocation!.city!),
                      if (_userLocation!.settlement != null)
                        _buildLocationRow('Населенный пункт', _userLocation!.settlement!),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _userLocation!.formattedLocation,
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

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
                  'Подтвердить',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Виджет для отображения строки местоположения
  Widget _buildLocationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
