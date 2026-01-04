#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Проверка данных республики Адыгея"""

import json
from pathlib import Path

# Ищем в южном федеральном округе
file_path = Path(__file__).parent.parent / 'app' / 'data' / 'districts' / 'south.json'

with open(file_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Найти республику Адыгея (ID: 01)
region = None
for r in data['regions']:
    if r['id'] == '01':
        region = r
        break

if not region:
    print("Республика Адыгея не найдена!")
    exit(1)

print("=== ДАННЫЕ РЕСПУБЛИКИ АДЫГЕЯ ===\n")
print(f"ID: {region['id']}")
print(f"Название: {region['name']}")
print(f"Население: {region['population']:,} чел.")
print(f"\nКоличество городов в списке cities: {len(region['cities'])}")
print(f"Количество районов в списке urban_districts: {len(region['urban_districts'])}")

print("\n=== ГОРОДА ===")
if region['cities']:
    for i, city in enumerate(region['cities'], 1):
        print(f"{i}. {city['name']} ({city['type']}) - {city['population']:,} чел.")
else:
    print("Города отсутствуют в списке cities")

print("\n=== РАЙОНЫ ===")
if region['urban_districts']:
    for i, district in enumerate(region['urban_districts'], 1):
        settlements_count = len(district['settlements'])
        cities_in_district = [s for s in district['settlements'] if s['type'].lower() == 'город']
        print(f"{i}. {district['name']}")
        print(f"   Население: {district['population']:,} чел.")
        print(f"   Населенных пунктов: {settlements_count} (городов: {len(cities_in_district)})")
        if cities_in_district:
            print(f"   Города в районе: {', '.join([c['name'] for c in cities_in_district])}")
else:
    print("Районы отсутствуют")

# Проверяем, есть ли города в районах, которые должны быть в списке cities
print("\n=== ГОРОДА В РАЙОНАХ ===")
cities_in_districts = {}
for district in region['urban_districts']:
    for settlement in district['settlements']:
        if settlement['type'].lower() == 'город':
            city_name = settlement['name']
            if city_name not in cities_in_districts:
                cities_in_districts[city_name] = []
            cities_in_districts[city_name].append(district['name'])

if cities_in_districts:
    for city_name, districts_list in cities_in_districts.items():
        print(f"{city_name} - находится в районах: {', '.join(districts_list)}")
else:
    print("Города в районах не найдены")

