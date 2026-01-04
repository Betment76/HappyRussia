#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Поиск районов Владимирской области"""

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

print("=== ПОИСК РАЙОНОВ ===")
print("\nТекущие районы:")
for i, district in enumerate(region['urban_districts'], 1):
    print(f"{i}. {district['name']} ({district['population']:,} чел.)")

# Ищем районы, связанные с городами
print("\n=== ПОИСК РАЙОНОВ С ГОРОДАМИ ===")
target_districts = ['Владимирский', 'Ковровский', 'Муромский']

for district in region['urban_districts']:
    name = district['name']
    for target in target_districts:
        if target.lower() in name.lower():
            settlements_count = len(district['settlements'])
            cities_count = len([s for s in district['settlements'] if s['type'].lower() == 'город'])
            print(f"Найден: {name}")
            print(f"  Население: {district['population']:,} чел.")
            print(f"  Населенных пунктов: {settlements_count}")
            print(f"  Городов: {cities_count}")
            print()

