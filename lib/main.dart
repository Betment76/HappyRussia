import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/yandex_ads_service.dart';
import 'providers/mood_provider.dart';
import 'screens/initial_screen.dart';
import 'screens/home_screen.dart';
import 'screens/city_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/check_in_screen.dart';
import 'models/city_mood.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Инициализируем локализацию для русского языка
  await initializeDateFormatting('ru_RU', null);
  // Инициализируем Яндекс Mobile Ads SDK
  await YandexAdsService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MoodProvider(),
      child: MaterialApp(
        title: 'Моё Настроение',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme(
            brightness: Brightness.light,
            // Цвета российского флага
            primary: const Color(0xFF0039A6), // Синий российского флага
            onPrimary: Colors.white,
            secondary: const Color(0xFFD52B1E), // Красный российского флага
            onSecondary: Colors.white,
            tertiary: Colors.white,
            onTertiary: const Color(0xFF0039A6),
            error: Colors.red,
            onError: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black87,
            surfaceContainerHighest: Colors.grey[100]!,
            outline: Colors.grey[400]!,
            shadow: Colors.black26,
          ),
          useMaterial3: true,
        ),
        home: const InitialScreen(),
        // Именованные маршруты для deep linking
        routes: {
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/checkin': (context) => const CheckInScreen(),
          // Маршрут для города будет обрабатываться через onGenerateRoute
        },
        onGenerateRoute: (settings) {
          // Обработка маршрута для города: /city/:cityId
          if (settings.name?.startsWith('/city/') ?? false) {
            final cityId = settings.name?.substring(6); // Убираем '/city/'
            
            // Если город передан в arguments, используем его
            if (settings.arguments is CityMood) {
              final city = settings.arguments as CityMood;
              return MaterialPageRoute(
                builder: (_) => CityDetailScreen(city: city),
                settings: settings,
              );
            }
            
            // Иначе пытаемся найти город по ID через провайдер
            if (cityId != null) {
              return MaterialPageRoute(
                builder: (context) {
                  final provider = Provider.of<MoodProvider>(context, listen: false);
                  final city = provider.getCityById(cityId);
                  
                  if (city != null) {
                    return CityDetailScreen(city: city);
                  } else {
                    // Если город не найден, возвращаемся на главный экран
                    return const HomeScreen();
                  }
                },
                settings: settings,
              );
            }
          }
          return null;
        },
      ),
    );
  }
}

