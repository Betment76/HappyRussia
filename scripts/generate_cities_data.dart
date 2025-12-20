import 'dart:io';

/// Скрипт для генерации Dart файла с данными о городах из регионы.md
void main() async {
  final inputFile = File('регионы.md');
  final outputFile = File('lib/data/region_cities_data.dart');
  
  if (!await inputFile.exists()) {
    print('Ошибка: файл регионы.md не найден');
    exit(1);
  }
  
  final content = await inputFile.readAsString();
  final lines = content.split('\n');
  
  final buffer = StringBuffer();
  buffer.writeln('/// Автоматически сгенерированный файл с данными о городах регионов');
  buffer.writeln('/// Не редактировать вручную! Используйте scripts/generate_cities_data.dart');
  buffer.writeln('');
  buffer.writeln('/// Данные о городах регионов');
  buffer.writeln('class RegionCitiesData {');
  buffer.writeln('  static final Map<String, List<Map<String, dynamic>>> cities = {');
  
  for (final line in lines) {
    if (!line.startsWith('|') || line.startsWith('| Код') || line.startsWith('|:---')) {
      continue;
    }
    
    final parts = line.split('|').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    
    if (parts.length < 4) continue;
    
    final code = parts[0];
    final citiesString = parts[3];
    
    // Парсим города
    final cityParts = citiesString.split(RegExp(r'<br\s*/?>', caseSensitive: false));
    final citiesList = <String>[];
    
    for (final cityPart in cityParts) {
      final trimmed = cityPart.trim();
      if (trimmed.isEmpty) continue;
      
      final match = RegExp(r'^(.+?)\s*\((\d[\d\s]*)\)$').firstMatch(trimmed);
      
      if (match != null) {
        final name = match.group(1)!.trim();
        final populationStr = match.group(2)!.replaceAll(' ', '');
        final population = int.tryParse(populationStr) ?? 0;
        citiesList.add("    {'name': '${name.replaceAll("'", "\\'")}', 'population': $population},");
      } else {
        citiesList.add("    {'name': '${trimmed.replaceAll("'", "\\'")}', 'population': 0},");
      }
    }
    
    if (citiesList.isNotEmpty) {
      buffer.writeln("    '$code': [");
      buffer.writeln(citiesList.join('\n'));
      buffer.writeln('    ],');
    }
  }
  
  buffer.writeln('  };');
  buffer.writeln('}');
  
  await outputFile.writeAsString(buffer.toString());
  print('✓ Файл lib/data/region_cities_data.dart успешно создан');
}

