#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Исправление названий районов Владимирской области"""

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

print("=== ИСПРАВЛЕНИЕ НАЗВАНИЙ РАЙОНОВ ===\n")

# Словарь для переименования районов
district_renames = {
    'Ковровский': 'Ковровский район',
    'Муромский': 'Муромский район',
}

# Ищем и переименовываем районы
renamed_count = 0
for district in region['urban_districts']:
    name = district['name']
    name_lower = name.lower()
    
    # Ковровский район
    if 'ковровский' in name_lower and 'район' not in name_lower:
        old_name = district['name']
        district['name'] = 'Ковровский район'
        print(f"Переименован: {old_name} -> {district['name']}")
        renamed_count += 1
    
    # Муромский район
    elif 'муромский' in name_lower and 'район' not in name_lower:
        old_name = district['name']
        district['name'] = 'Муромский район'
        print(f"Переименован: {old_name} -> {district['name']}")
        renamed_count += 1
    
    # Владимирский район - ищем его
    elif 'владимирский' in name_lower and 'район' not in name_lower:
        old_name = district['name']
        district['name'] = 'Владимирский район'
        print(f"Переименован: {old_name} -> {district['name']}")
        renamed_count += 1

# Проверяем, есть ли Владимирский район
vladimir_district = None
for district in region['urban_districts']:
    if 'владимирский' in district['name'].lower() and 'район' in district['name'].lower():
        vladimir_district = district
        break

if not vladimir_district:
    print("\nВНИМАНИЕ: Владимирский район не найден!")
    print("Возможно, он был удален как 'город Владимир'.")
    print("Нужно восстановить его из исходных данных или создать заново.")
    
    # Проверяем, может быть есть район с другим названием
    print("\nПоиск возможных вариантов:")
    for district in region['urban_districts']:
        name_lower = district['name'].lower()
        if 'владимир' in name_lower:
            print(f"  Найден: {district['name']} ({district['population']:,} чел.)")

# Сохраняем изменения
if renamed_count > 0:
    print(f"\nПереименовано районов: {renamed_count}")
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print("Данные сохранены!")
else:
    print("\nИзменений не требуется.")

# Итоговый список районов
print("\n=== ИТОГОВЫЙ СПИСОК РАЙОНОВ ===")
for i, district in enumerate(sorted(region['urban_districts'], key=lambda x: x['name']), 1):
    print(f"{i}. {district['name']} ({district['population']:,} чел.)")

