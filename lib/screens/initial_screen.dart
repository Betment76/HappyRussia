import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'registration_screen.dart';
import 'home_screen.dart';

/// Экран-обертка для проверки первого запуска
class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  bool _isLoading = true;
  bool _isFirstLaunch = false;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  /// Проверить, первый ли это запуск приложения
  Future<void> _checkFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isFirstLaunch = prefs.getBool('is_first_launch') ?? true;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // В случае ошибки считаем, что это первый запуск
      if (mounted) {
        setState(() {
          _isFirstLaunch = true;
          _isLoading = false;
        });
      }
    }
  }

  /// Обработка завершения регистрации
  Future<void> _onRegistrationComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_first_launch', false);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      // В случае ошибки все равно переходим на главный экран
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
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

    // Если первый запуск - показываем экран регистрации
    if (_isFirstLaunch) {
      return RegistrationScreen(
        onRegistrationComplete: _onRegistrationComplete,
      );
    }

    // Иначе показываем главный экран
    return const HomeScreen();
  }
}

