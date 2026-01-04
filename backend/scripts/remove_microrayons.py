#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Удаление района 'Микрорайоны других городов'"""

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

print("=== УДАЛЕНИЕ РАЙОНА 'Микрорайоны других городов' ===\n")
print(f"Текущее количество районов: {len(region['urban_districts'])}")

# Удаляем "Микрорайоны других городов"
district_to_remove = "Микрорайоны других городов"

new_districts = []
removed = None
for district in region['urban_districts']:
    if district['name'] == district_to_remove:
        removed = district
        print(f"Удален район: {district['name']} (население: {district['population']:,} чел.)")
    else:
        new_districts.append(district)

if removed:
    region['urban_districts'] = new_districts
    
    # Пересчитываем население региона
    cities_pop = sum(c['population'] for c in region['cities'])
    districts_pop = sum(d['population'] for d in region['urban_districts'])
    region['population'] = cities_pop + districts_pop
    
    # Сохраняем
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"\n+ Удален 1 район")
    print(f"+ Осталось районов: {len(region['urban_districts'])}")
    print(f"+ Население региона: {region['population']:,} чел.")
else:
    print(f"Район '{district_to_remove}' не найден!")
    print("\nТекущие районы:")
    for district in region['urban_districts']:
        print(f"  - {district['name']}")

