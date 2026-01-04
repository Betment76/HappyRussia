#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Исправление данных Майкопского района"""

import json
from pathlib import Path

parsed_file = Path(__file__).parent / 'adygea_parsed_full.json'
south_file = Path(__file__).parent.parent / 'app' / 'data' / 'districts' / 'south.json'

with open(parsed_file, 'r', encoding='utf-8') as f:
    parsed_data = json.load(f)

with open(south_file, 'r', encoding='utf-8') as f:
    data = json.load(f)

region = None
for r in data['regions']:
    if r['id'] == '01':
        region = r
        break

print("=== ИСПРАВЛЕНИЕ МАЙКОПСКОГО РАЙОНА ===\n")

# Ищем Майкопский район в списке
maikop_district = None
for district in region['urban_districts']:
    if district['name'] == 'Майкопский район':
        maikop_district = district
        break

if not maikop_district:
    print("Майкопский район не найден!")
    exit(1)

# В распарсенных данных "Майкопский район" может быть под другим названием
# Проверяем все ключи
print("Доступные данные в распарсенных:")
for key in parsed_data.keys():
    print(f"  - {key}: {len(parsed_data[key])} населенных пунктов")

# Согласно структуре RuWiki, данные Майкопского района должны быть в разделе "Майкопский"
# Но парсер мог их неправильно определить. Проверяем, есть ли данные с похожим названием
maikop_settlements = None
for key, settlements in parsed_data.items():
    # Ищем "Майкопский район" (без "городской округ")
    if 'Майкопский' in key and 'район' in key and 'городской округ' not in key:
        maikop_settlements = settlements
        print(f"\nНайдены данные для Майкопского района: {len(settlements)} населенных пунктов")
        break
    # Если не найдено, проверяем просто "Майкопский" без уточнения
    elif key == 'Майкопский район':
        maikop_settlements = settlements
        print(f"\nНайдены данные для Майкопского района: {len(settlements)} населенных пунктов")
        break

# Если все еще не найдено, проверяем все ключи, содержащие "Майкоп"
if not maikop_settlements:
    for key, settlements in parsed_data.items():
        if 'Майкоп' in key and 'городской округ' not in key and 'район' in key:
            maikop_settlements = settlements
            print(f"\nНайдены данные для Майкопского района (по ключу '{key}'): {len(settlements)} населенных пунктов")
            break

# Если не найдено, проверяем напрямую по ключу "Майкопский район"
if not maikop_settlements and 'Майкопский район' in parsed_data:
    maikop_settlements = parsed_data['Майкопский район']
    print(f"\nНайдены данные для Майкопского района (прямой ключ): {len(maikop_settlements)} населенных пунктов")

# Если все еще не найдено, возможно данные находятся в "Майкопский городской округ"
# но это неправильно - нужно проверить структуру страницы
# Временно используем данные из "Майкопский городской округ" для "Майкопский район"
if not maikop_settlements and 'Майкопский городской округ' in parsed_data:
    # Проверяем, может быть это и есть данные для района
    # Но это неправильно - нужно перепарсить страницу правильно
    print("\nВНИМАНИЕ: Данные для Майкопского района не найдены отдельно.")
    print("В распарсенных данных есть только 'Майкопский городской округ'.")
    print("Нужно проверить структуру страницы RuWiki и перепарсить данные.")
    print("\nТекущее состояние Майкопского района:")
    print(f"  Населенных пунктов: {len(maikop_district['settlements'])}")
    print(f"  Население: {maikop_district['population']:,} чел.")
    print("\nДанные из 'Майкопский городской округ' (57 населенных пунктов) не используются,")
    print("так как это городской округ, а не район.")

# Если все еще не найдено
if not maikop_settlements:
    print("\nВНИМАНИЕ: Данные для Майкопского района не найдены в распарсенных!")
    print("Возможно, нужно перепарсить страницу или данные находятся в другом разделе.")
    print("\nТекущее состояние Майкопского района:")
    print(f"  Населенных пунктов: {len(maikop_district['settlements'])}")
    print(f"  Население: {maikop_district['population']:,} чел.")
else:
    # Обновляем данные
    maikop_district['settlements'] = [
        {
            'name': s['name'],
            'type': s['type'],
            'population': s['population'],
            'id': f'01-{i+401:03d}'  # Начинаем с 401, чтобы не пересекаться с другими
        }
        for i, s in enumerate(maikop_settlements)
    ]
    maikop_district['population'] = sum(s['population'] for s in maikop_settlements)
    
    print(f"\n+ Майкопский район обновлен:")
    print(f"  Населенных пунктов: {len(maikop_settlements)}")
    print(f"  Население: {maikop_district['population']:,} чел.")
    
    # Сохраняем
    with open(south_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\n+ Данные сохранены!")

