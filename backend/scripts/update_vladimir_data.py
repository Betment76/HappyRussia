#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Обновление структуры данных Владимирской области согласно административному делению"""

import json
from pathlib import Path
from copy import deepcopy

# Путь к файлу
file_path = Path(__file__).parent.parent / 'app' / 'data' / 'districts' / 'central.json'

with open(file_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Найти Владимирскую область
region = None
region_index = -1
for i, r in enumerate(data['regions']):
    if r['id'] == '33':
        region = r
        region_index = i
        break

if not region:
    print("Владимирская область не найдена!")
    exit(1)

print("=== ИСПРАВЛЕНИЕ СТРУКТУРЫ ВЛАДИМИРСКОЙ ОБЛАСТИ ===\n")

# Города областного значения согласно RuWiki
cities_of_oblast_value = {
    'Владимир',
    'Ковров', 
    'Муром',
    'Гусь-Хрустальный',
    'Радужный'  # ЗАТО
}

# 1. Исправляем список cities - оставляем только города областного значения
print("1. Исправление списка cities...")
original_cities_count = len(region['cities'])
new_cities = []

# Находим города областного значения в текущем списке
for city in region['cities']:
    if city['name'] in cities_of_oblast_value:
        new_cities.append(city)
        print(f"   + {city['name']} ({city['population']:,} чел.)")

# Проверяем, все ли города найдены
found_cities = {c['name'] for c in new_cities}
missing = cities_of_oblast_value - found_cities
if missing:
    print(f"   ⚠ Отсутствуют города: {sorted(missing)}")
    # Попробуем найти их в районах
    for district in region['urban_districts']:
        for settlement in district['settlements']:
            if settlement['name'] in missing and settlement['type'].lower() == 'город':
                new_cities.append(settlement)
                print(f"   + Найден в районе {district['name']}: {settlement['name']} ({settlement['population']:,} чел.)")
                found_cities.add(settlement['name'])

region['cities'] = new_cities
print(f"   Итого: {len(region['cities'])} городов (было {original_cities_count})")

# 2. Убираем из urban_districts районы, которые являются городами областного значения
print("\n2. Удаление городов из списка районов...")
new_districts = []
removed_districts = []

for district in region['urban_districts']:
    name_lower = district['name'].lower()
    district_name = district['name']
    
    # Проверяем, является ли район городом областного значения
    is_city_district = (
        name_lower.startswith('город ') or
        district_name in cities_of_oblast_value or
        name_lower in {c.lower() for c in cities_of_oblast_value}
    )
    
    if is_city_district:
        removed_districts.append(district_name)
        print(f"   - Удален: {district_name} (население: {district['population']:,} чел.)")
    else:
        new_districts.append(district)

region['urban_districts'] = new_districts
print(f"   Удалено районов: {len(removed_districts)}")
print(f"   Осталось районов: {len(region['urban_districts'])} (должно быть 16)")

# 3. Пересчитываем население региона
print("\n3. Пересчет населения региона...")
cities_pop = sum(c['population'] for c in region['cities'])
districts_pop = sum(d['population'] for d in region['urban_districts'])
new_population = cities_pop + districts_pop
old_population = region['population']
region['population'] = new_population
print(f"   Население городов: {cities_pop:,} чел.")
print(f"   Население районов: {districts_pop:,} чел.")
print(f"   Итого: {new_population:,} чел. (было {old_population:,} чел.)")

# Сохраняем изменения
print("\n4. Сохранение изменений...")
with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("+ Данные сохранены!")

# Итоговая статистика
print("\n=== ИТОГОВАЯ СТРУКТУРА ===")
print(f"Города областного значения: {len(region['cities'])}")
for city in sorted(region['cities'], key=lambda x: x['population'], reverse=True):
    print(f"  - {city['name']} ({city['population']:,} чел.)")

print(f"\nРайоны: {len(region['urban_districts'])}")
for i, district in enumerate(sorted(region['urban_districts'], key=lambda x: x['population'], reverse=True), 1):
    settlements_count = len(district['settlements'])
    print(f"  {i}. {district['name']} ({district['population']:,} чел., {settlements_count} населенных пунктов)")

