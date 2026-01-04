#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Восстановление районов Владимирской области: Владимирский, Ковровский, Муромский"""

import json
from pathlib import Path

file_path = Path(__file__).parent.parent / 'app' / 'data' / 'districts' / 'central.json'

with open(file_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

region = None
for r in data['regions']:
    if r['id'] == '33':
        region = r
        break

if not region:
    print("Владимирская область не найдена!")
    exit(1)

print("=== ВОССТАНОВЛЕНИЕ РАЙОНОВ ===\n")

# Находим города областного значения
cities_map = {}
for city in region['cities']:
    cities_map[city['name']] = city

print("Города областного значения:")
for name, city in cities_map.items():
    print(f"  - {name}: {city['population']:,} чел. (ID: {city.get('id', 'нет')})")

# Создаем районы на основе городов
# Согласно структуре, "город Владимир" в urban_districts был Владимирским районом
# Нужно создать эти районы с правильными названиями

districts_to_add = []

# 1. Владимирский район
if 'Владимир' in cities_map:
    vladimir_city = cities_map['Владимир']
    vladimir_district = {
        'name': 'Владимирский район',
        'population': vladimir_city['population'],  # Временно, нужно будет пересчитать
        'settlements': [
            {
                'id': vladimir_city.get('id', 'vladimir_city'),
                'name': 'Владимир',
                'type': 'город',
                'population': vladimir_city['population']
            }
        ]
    }
    districts_to_add.append(('Владимирский район', vladimir_district))

# 2. Ковровский район
if 'Ковров' in cities_map:
    kovrov_city = cities_map['Ковров']
    kovrov_district = {
        'name': 'Ковровский район',
        'population': kovrov_city['population'],
        'settlements': [
            {
                'id': kovrov_city.get('id', 'kovrov_city'),
                'name': 'Ковров',
                'type': 'город',
                'population': kovrov_city['population']
            }
        ]
    }
    districts_to_add.append(('Ковровский район', kovrov_district))

# 3. Муромский район
if 'Муром' in cities_map:
    murom_city = cities_map['Муром']
    murom_district = {
        'name': 'Муромский район',
        'population': murom_city['population'],
        'settlements': [
            {
                'id': murom_city.get('id', 'murom_city'),
                'name': 'Муром',
                'type': 'город',
                'population': murom_city['population']
            }
        ]
    }
    districts_to_add.append(('Муромский район', murom_district))

# Проверяем, какие районы уже есть
existing_districts = {d['name'] for d in region['urban_districts']}
print(f"\nСуществующие районы: {len(existing_districts)}")

# Добавляем недостающие районы
added_count = 0
for district_name, district_data in districts_to_add:
    if district_name not in existing_districts:
        # Проверяем, может быть есть с другим названием
        found = False
        for existing in region['urban_districts']:
            if district_name.replace(' район', '').lower() in existing['name'].lower():
                # Переименовываем
                print(f"Переименовываем: {existing['name']} -> {district_name}")
                existing['name'] = district_name
                found = True
                added_count += 1
                break
        
        if not found:
            # Добавляем новый район
            print(f"Добавляем: {district_name}")
            region['urban_districts'].append(district_data)
            added_count += 1
    else:
        print(f"Уже существует: {district_name}")

if added_count > 0:
    # Пересчитываем население региона
    cities_pop = sum(c['population'] for c in region['cities'])
    districts_pop = sum(d['population'] for d in region['urban_districts'])
    region['population'] = cities_pop + districts_pop
    
    # Сохраняем
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"\n+ Добавлено/переименовано районов: {added_count}")
    print(f"+ Население региона: {region['population']:,} чел.")
else:
    print("\nИзменений не требуется.")

# Итоговый список
print("\n=== ИТОГОВЫЙ СПИСОК РАЙОНОВ ===")
for i, district in enumerate(sorted(region['urban_districts'], key=lambda x: x['name']), 1):
    settlements_count = len(district['settlements'])
    print(f"{i}. {district['name']} ({district['population']:,} чел., {settlements_count} населенных пунктов)")

