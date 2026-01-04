#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Восстановление данных республики Адыгея"""

import json
from pathlib import Path

# Проверяем assets файл - возможно там есть старые данные
assets_file = Path(__file__).parent.parent.parent / 'assets' / 'districts' / 'south.json'
backend_file = Path(__file__).parent.parent / 'app' / 'data' / 'districts' / 'south.json'

# Сначала проверяем, есть ли в assets старые данные
print("=== ПРОВЕРКА ДАННЫХ ===")

# Проверяем backend файл
with open(backend_file, 'r', encoding='utf-8') as f:
    backend_data = json.load(f)

region_backend = None
for r in backend_data['regions']:
    if r['id'] == '01':
        region_backend = r
        break

print(f"Backend файл:")
print(f"  Районов: {len(region_backend['urban_districts'])}")
for district in region_backend['urban_districts']:
    print(f"    - {district['name']}: {len(district['settlements'])} населенных пунктов")

# Проверяем assets файл
if assets_file.exists():
    with open(assets_file, 'r', encoding='utf-8') as f:
        assets_data = json.load(f)
    
    region_assets = None
    for r in assets_data['regions']:
        if r['id'] == '01':
            region_assets = r
            break
    
    if region_assets:
        print(f"\nAssets файл:")
        print(f"  Районов: {len(region_assets['urban_districts'])}")
        for district in region_assets['urban_districts']:
            print(f"    - {district['name']}: {len(district['settlements'])} населенных пунктов")
        
        # Ищем район "Районы" в assets
        all_settlements_district = None
        for district in region_assets['urban_districts']:
            if district['name'] == 'Районы' or district['name'].lower() == 'районы':
                all_settlements_district = district
                break
        
        if all_settlements_district:
            print(f"\nНайден район 'Районы' в assets с {len(all_settlements_district['settlements'])} населенными пунктами!")
            print("Нужно распределить эти данные по 7 районам.")

