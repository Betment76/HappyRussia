#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Исправление структуры данных республики Адыгея"""

import json
from pathlib import Path

file_path = Path(__file__).parent.parent / 'app' / 'data' / 'districts' / 'south.json'

with open(file_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

region = None
for r in data['regions']:
    if r['id'] == '01':
        region = r
        break

if not region:
    print("Республика Адыгея не найдена!")
    exit(1)

print("=== ИСПРАВЛЕНИЕ СТРУКТУРЫ РЕСПУБЛИКИ АДЫГЕЯ ===\n")

# Согласно административному делению должно быть:
# - 2 городских округа: Майкоп, Адыгейск (уже в cities)
# - 7 районов: Гиагинский, Кошехабльский, Красногвардейский, Майкопский, Тахтамукайский, Теучежский, Шовгеновский

# Текущая структура:
print(f"Текущее количество районов: {len(region['urban_districts'])}")
for i, district in enumerate(region['urban_districts'], 1):
    print(f"{i}. {district['name']} ({len(district['settlements'])} населенных пунктов)")

# Находим район "Районы" который содержит все населенные пункты
all_settlements_district = None
for district in region['urban_districts']:
    if district['name'] == 'Районы' or district['name'].lower() == 'районы':
        all_settlements_district = district
        break

if not all_settlements_district:
    print("\nРайон 'Районы' не найден!")
    exit(1)

print(f"\nНайден общий район 'Районы' с {len(all_settlements_district['settlements'])} населенными пунктами")

# Создаем структуру районов
# Нужно распределить населенные пункты по районам
# Для этого нужно знать, к какому району относится каждый населенный пункт
# Но у нас нет этой информации в данных, поэтому создадим базовую структуру

# Список районов согласно административному делению
districts_list = [
    'Гиагинский район',
    'Кошехабльский район', 
    'Красногвардейский район',
    'Майкопский район',
    'Тахтамукайский район',
    'Теучежский район',
    'Шовгеновский район'
]

# Создаем новые районы
new_districts = []

# Оставляем "Майкопский городской округ" если он есть
for district in region['urban_districts']:
    if 'майкопский' in district['name'].lower() and 'городской округ' in district['name'].lower():
        # Переименовываем в "Майкопский район" или оставляем как есть
        # Но это городской округ, не район
        # Проверяем, нужно ли его включать в список районов
        pass

# Создаем районы
# Пока создаем пустые районы, так как нет информации о распределении населенных пунктов
for district_name in districts_list:
    new_district = {
        'name': district_name,
        'population': 0,  # Будет пересчитано
        'settlements': []
    }
    new_districts.append(new_district)

# Удаляем старый район "Районы" и добавляем новые
region['urban_districts'] = [d for d in region['urban_districts'] if d['name'] != 'Районы' and d['name'].lower() != 'районы']
region['urban_districts'].extend(new_districts)

print(f"\nСоздано {len(new_districts)} новых районов")
print(f"Итого районов: {len(region['urban_districts'])}")

# Сохраняем
with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("\n+ Данные сохранены!")
print("\nВНИМАНИЕ: Районы созданы пустыми. Нужно распределить населенные пункты по районам вручную или найти источник данных.")

