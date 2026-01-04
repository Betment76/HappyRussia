#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Проверка данных Владимирской области"""

import json
import sys
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
    sys.exit(1)

print(f"ID: {region['id']}")
print(f"Название: {region['name']}")
print(f"Население: {region['population']:,} чел.")
print(f"\nКоличество городов: {len(region['cities'])}")
print(f"Количество районов: {len(region['urban_districts'])}")

print("\n=== ГОРОДА ОБЛАСТНОГО ЗНАЧЕНИЯ ===")
for city in region['cities']:
    print(f"  - {city['name']} ({city['type']}) - {city['population']:,} чел.")

print("\n=== РАЙОНЫ (первые 20) ===")
for i, district in enumerate(region['urban_districts'][:20], 1):
    settlements_count = len(district['settlements'])
    cities_in_district = [s for s in district['settlements'] if s['type'].lower() == 'город']
    print(f"{i}. {district['name']} - {district['population']:,} чел. ({settlements_count} населенных пунктов, {len(cities_in_district)} городов)")

print(f"\nВсего районов: {len(region['urban_districts'])}")

