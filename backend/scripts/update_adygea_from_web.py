#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Обновление данных республики Адыгея на основе данных с RuWiki"""

import json
from pathlib import Path

file_path = Path(__file__).parent.parent / 'app' / 'data' / 'districts' / 'south.json'

with open(file_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

region = None
for r in data['regions']:
    if r['id'] == '01':
        region = r
        break

if not region:
    print("Республика Адыгея не найдена!")
    exit(1)

print("=== ОБНОВЛЕНИЕ ДАННЫХ РЕСПУБЛИКИ АДЫГЕЯ ===\n")

# Данные из RuWiki: https://ru.ruwiki.ru/wiki/Населённые_пункты_Адыгеи
# Структура: 2 городских округа + 7 районов

# Данные по районам (из веб-поиска и структуры страницы)
districts_settlements = {
    'Гиагинский район': [
        {'name': 'Владимировское', 'type': 'село', 'population': 78},
        {'name': 'Вольно-Весёлый', 'type': 'хутор', 'population': 84},
        {'name': 'Георгиевское', 'type': 'село', 'population': 215},
        {'name': 'Гиагинская', 'type': 'станица', 'population': 14121},
        {'name': 'Гончарка', 'type': 'посёлок', 'population': 1537},
        {'name': 'Днепровский', 'type': 'хутор', 'population': 174},
        {'name': 'Дондуковская', 'type': 'станица', 'population': 6603},
        {'name': 'Екатериновский', 'type': 'хутор', 'population': 157},
        {'name': 'Карцев', 'type': 'хутор', 'population': 70},
        {'name': 'Келермесская', 'type': 'станица', 'population': 2749},
        {'name': 'Козополянский', 'type': 'хутор', 'population': 77},
        {'name': 'Колхозный', 'type': 'хутор', 'population': 76},
        {'name': 'Красный Пахарь', 'type': 'хутор', 'population': 0},  # Нужно уточнить
    ],
    # Остальные районы нужно заполнить из источника
}

# Обновляем районы
updated_count = 0
for district in region['urban_districts']:
    district_name = district['name']
    
    # Если это один из 7 районов и он пустой
    if district_name in districts_settlements and len(district['settlements']) == 0:
        settlements = districts_settlements[district_name]
        district['settlements'] = [
            {
                'name': s['name'],
                'type': s['type'],
                'population': s['population'],
                'id': f'01-{i+1:03d}'
            }
            for i, s in enumerate(settlements)
        ]
        district['population'] = sum(s['population'] for s in settlements)
        print(f"Обновлен {district_name}: {len(settlements)} населенных пунктов, население: {district['population']:,} чел.")
        updated_count += 1

if updated_count == 0:
    print("ВНИМАНИЕ: Данные не обновлены!")
    print("Нужно заполнить данные для всех 7 районов вручную или использовать парсер с правильными заголовками.")
    print("\nТекущие районы:")
    for district in region['urban_districts']:
        print(f"  - {district['name']}: {len(district['settlements'])} населенных пунктов")

# Сохраняем
with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"\n+ Обновлено районов: {updated_count}")
print("+ Данные сохранены!")

