#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Проверка данных Республики Башкортостан"""

import json
from pathlib import Path

file_path = Path(__file__).parent.parent / 'app' / 'data' / 'districts' / 'volga.json'

with open(file_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

region = None
for r in data['regions']:
    if r['id'] == '02':
        region = r
        break

if not region:
    print("Республика Башкортостан не найдена!")
    exit(1)

print("=== ДАННЫЕ РЕСПУБЛИКИ БАШКОРТОСТАН ===\n")
print(f"ID: {region['id']}")
print(f"Название: {region['name']}")
print(f"Население: {region['population']:,} чел.")
print(f"\nКоличество городов: {len(region['cities'])}")
print(f"Количество районов: {len(region['urban_districts'])}")

districts_with_data = [d for d in region['urban_districts'] if len(d['settlements']) > 0]
districts_without_data = [d for d in region['urban_districts'] if len(d['settlements']) == 0]

print(f"\nРайонов с данными: {len(districts_with_data)}")
print(f"Районов без данных: {len(districts_without_data)}")

if districts_without_data:
    print("\nРайоны без данных:")
    for district in districts_without_data[:10]:  # Показываем первые 10
        print(f"  - {district['name']}")
    if len(districts_without_data) > 10:
        print(f"  ... и еще {len(districts_without_data) - 10}")

print("\nРайоны с данными (первые 10):")
for district in districts_with_data[:10]:
    pop_sum = sum(s['population'] for s in district['settlements'])
    print(f"  - {district['name']}: {len(district['settlements'])} населенных пунктов, население: {pop_sum:,} чел.")

