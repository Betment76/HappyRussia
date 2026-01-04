#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Исправление структуры данных Владимирской области согласно административному делению"""

import json
from pathlib import Path

# Путь к файлу
file_path = Path(__file__).parent.parent / 'app' / 'data' / 'districts' / 'central.json'

with open(file_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Найти Владимирскую область
region = None
for r in data['regions']:
    if r['id'] == '33':
        region = r
        break

if not region:
    print("Владимирская область не найдена!")
    exit(1)

print("=== ТЕКУЩАЯ СТРУКТУРА ===")
print(f"Города в списке cities: {len(region['cities'])}")
print(f"Районы в списке urban_districts: {len(region['urban_districts'])}")

# Города областного значения согласно RuWiki
cities_of_oblast_value = {
    'Владимир',
    'Ковров', 
    'Муром',
    'Гусь-Хрустальный',
    'Радужный'  # ЗАТО
}

print("\n=== ГОРОДА ОБЛАСТНОГО ЗНАЧЕНИЯ (должны быть в cities) ===")
current_cities = {c['name'] for c in region['cities']}
print(f"Текущие города в cities: {sorted(current_cities)}")
print(f"Города областного значения: {sorted(cities_of_oblast_value)}")

# Проверим, какие города областного значения уже в cities
cities_in_cities = cities_of_oblast_value & current_cities
print(f"\nГорода областного значения уже в cities: {sorted(cities_in_cities)}")
missing_cities = cities_of_oblast_value - current_cities
if missing_cities:
    print(f"Отсутствуют в cities: {sorted(missing_cities)}")

# Проверим районы, которые являются городами
print("\n=== РАЙОНЫ, КОТОРЫЕ ЯВЛЯЮТСЯ ГОРОДАМИ ===")
city_districts = []
for district in region['urban_districts']:
    name_lower = district['name'].lower()
    if (name_lower.startswith('город ') or 
        name_lower in cities_of_oblast_value or
        district['name'] in cities_of_oblast_value):
        city_districts.append(district['name'])
        print(f"  - {district['name']} (население: {district['population']:,} чел.)")

# Проверим, какие города есть в районах
print("\n=== ГОРОДА В РАЙОНАХ ===")
cities_in_districts = {}
for district in region['urban_districts']:
    for settlement in district['settlements']:
        if settlement['type'].lower() == 'город':
            city_name = settlement['name']
            if city_name in cities_of_oblast_value:
                if district['name'] not in cities_in_districts:
                    cities_in_districts[district['name']] = []
                cities_in_districts[district['name']].append(city_name)

for district_name, cities in cities_in_districts.items():
    print(f"  {district_name}: {', '.join(cities)}")

print("\n=== РЕКОМЕНДАЦИИ ===")
print("1. В списке cities должны быть только 5 городов областного значения:")
print("   - Владимир, Ковров, Муром, Гусь-Хрустальный, Радужный")
print("2. Из urban_districts нужно убрать районы, которые являются городами")
print("3. В urban_districts должно остаться 16 районов")

