import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/mood_provider.dart';
import 'screens/initial_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MoodProvider(),
      child: MaterialApp(
        title: 'Битва Регионов',
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
      ),
    );
  }
}

