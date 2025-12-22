import 'package:flutter/material.dart';
import 'registration_screen.dart';
import 'home_screen.dart';
import '../services/storage_service.dart';

/// Экран-обертка для проверки первого запуска
class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  final StorageService _storageService = StorageService();
  bool _isLoading = true;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _checkRegistrationStatus();
  }

  /// Проверить, зарегистрирован ли пользователь (по наличию данных профиля)
  Future<void> _checkRegistrationStatus() async {
    try {
      // Проверяем наличие данных профиля (имя и местоположение обязательны)
      final name = await _storageService.getProfileName();
      final location = await _storageService.getProfileLocation();
      
      // Пользователь зарегистрирован, если есть имя и местоположение
      _isRegistered = name != null && name.isNotEmpty && 
                      location != null && location.isNotEmpty;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // В случае ошибки считаем, что пользователь не зарегистрирован
      if (mounted) {
        setState(() {
          _isRegistered = false;
          _isLoading = false;
        });
      }
    }
  }

  /// Обработка завершения регистрации
  Future<void> _onRegistrationComplete() async {
    // Данные уже сохранены в StorageService, просто переходим на главный экран
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Если пользователь не зарегистрирован - показываем экран регистрации
    if (!_isRegistered) {
      return RegistrationScreen(
        onRegistrationComplete: _onRegistrationComplete,
      );
    }

    // Иначе показываем главный экран
    return const HomeScreen();
  }
}

