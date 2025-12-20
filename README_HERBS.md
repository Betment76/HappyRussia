# Гербы регионов России

## Структура

Гербы хранятся в папке `assets/herbs/` с именами файлов по коду региона:
- `01.png` - Республика Адыгея
- `02.png` - Республика Башкортостан
- `77.png` - г. Москва
- и т.д.

## Источники для скачивания

### 1. Геральдика.ру
- Сайт: https://geraldika.ru/symbols/region
- На сайте есть каталог гербов всех регионов
- Нужно перейти на страницу каждого региона и скачать изображение

### 2. Википедия
- Страница: https://ru.wikipedia.org/wiki/Гербы_субъектов_Российской_Федерации
- Все гербы в одном месте с хорошим качеством

### 3. Wikimedia Commons
- Категория: https://commons.wikimedia.org/wiki/Category:Coats_of_arms_of_subjects_of_the_Russian_Federation
- Высокое качество, разные форматы

## Рекомендации

- Формат: PNG с прозрачным фоном
- Размер: 200x200 или 300x300 пикселей
- Имя файла: код региона (01.png, 02.png, и т.д.)

## Использование в коде

```dart
import 'package:flutter/material.dart';
import '../utils/herb_helper.dart';

// Получить путь к гербу
final herbPath = HerbHelper.getHerbPath('77'); // для Москвы

// Отобразить герб
Image.asset(herbPath)
```

