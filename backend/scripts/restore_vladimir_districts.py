#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Восстановление районов Владимирской области"""

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

print("=== ВОССТАНОВЛЕНИЕ РАЙОНОВ ===")

# Проверяем, какие районы уже есть
current_districts = {d['name'] for d in region['urban_districts']}
print(f"\nТекущее количество районов: {len(region['urban_districts'])}")

# Ищем районы, которые должны быть
target_districts = {
    'Владимирский': None,
    'Ковровский': None,
    'Муромский': None
}

# Проверяем, какие уже есть
for district in region['urban_districts']:
    name = district['name']
    if 'Владимирский' in name and 'район' in name.lower():
        target_districts['Владимирский'] = district
    elif 'Ковровский' in name and 'район' in name.lower():
        target_districts['Ковровский'] = district
    elif 'Муромский' in name and 'район' in name.lower():
        target_districts['Муромский'] = district

print("\nСтатус районов:")
for name, district in target_districts.items():
    if district:
        print(f"  + {district['name']} - есть ({district['population']:,} чел.)")
    else:
        print(f"  - {name} - отсутствует")

# Если Владимирский район отсутствует, нужно его найти или создать
# Проверяем, может быть он был удален как "город Владимир"
# Но по логике, если был "город Владимир" как район, то это не Владимирский район
# Владимирский район - это отдельный район с административным центром в городе Владимире

# Согласно RuWiki:
# - Владимирский район (админцентр - город Владимир)
# - Ковровский район (админцентр - город Ковров)  
# - Муромский район (админцентр - город Муром)

# Проверяем названия районов более точно
print("\n=== ДЕТАЛЬНАЯ ПРОВЕРКА ===")
for district in region['urban_districts']:
    name = district['name']
    name_lower = name.lower()
    if 'владимир' in name_lower:
        print(f"Найден район с 'Владимир': {name} ({district['population']:,} чел.)")
    if 'ковров' in name_lower:
        print(f"Найден район с 'Ковров': {name} ({district['population']:,} чел.)")
    if 'муром' in name_lower:
        print(f"Найден район с 'Муром': {name} ({district['population']:,} чел.)")

