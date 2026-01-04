#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Проверка количества районов Владимирской области"""

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

print("=== СПИСОК РАЙОНОВ ===")
print(f"Всего районов: {len(region['urban_districts'])}\n")

# Сортируем по названию
districts = sorted(region['urban_districts'], key=lambda x: x['name'])

for i, district in enumerate(districts, 1):
    settlements_count = len(district['settlements'])
    cities_count = len([s for s in district['settlements'] if s['type'].lower() == 'город'])
    print(f"{i}. {district['name']}")
    print(f"   Население: {district['population']:,} чел.")
    print(f"   Населенных пунктов: {settlements_count} (городов: {cities_count})")
    print()

# Проверяем, есть ли лишние районы
# Согласно RuWiki, должно быть 16 районов, но пользователь говорит 19
# Возможно, есть какие-то специальные районы, которые нужно удалить

# Ищем возможные лишние районы
print("=== ВОЗМОЖНЫЕ ЛИШНИЕ РАЙОНЫ ===")
suspicious_districts = []
for district in districts:
    name_lower = district['name'].lower()
    # Проверяем на подозрительные названия
    if ('города области' in name_lower or
        'микрорайоны' in name_lower or
        'других городов' in name_lower or
        district['population'] == 0):
        suspicious_districts.append(district)
        print(f"- {district['name']} (население: {district['population']:,} чел.)")

if suspicious_districts:
    print(f"\nНайдено подозрительных районов: {len(suspicious_districts)}")
    print("Эти районы можно удалить, чтобы получить 19 районов.")
else:
    print("Подозрительных районов не найдено.")
    print("Нужно вручную определить, какой район лишний.")

