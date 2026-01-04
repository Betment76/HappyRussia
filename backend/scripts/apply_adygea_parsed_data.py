#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Применение распарсенных данных республики Адыгея"""

import json
from pathlib import Path

# Загружаем распарсенные данные
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

if not region:
    print("Республика Адыгея не найдена!")
    exit(1)

print("=== ПРИМЕНЕНИЕ РАСПАРСЕННЫХ ДАННЫХ ===\n")

# Маппинг названий
name_mapping = {
    'Майкопский городской округ': 'Майкопский городской округ',
    'Адыгейский городской округ': 'Адыгейский городской округ',
    'Гиагинский район': 'Гиагинский район',
    'Кошехабльский район': 'Кошехабльский район',
    'Красногвардейский район': 'Красногвардейский район',
    'Майкопский район': 'Майкопский район',
    'Тахтамукайский район': 'Тахтамукайский район',
    'Теучежский район': 'Теучежский район',
    'Шовгеновский район': 'Шовгеновский район',
}

# Обновляем районы
updated_districts = []
for district in region['urban_districts']:
    district_name = district['name']
    
    # Ищем соответствующие данные в распарсенных
    found_data = None
    for parsed_name, settlements in parsed_data.items():
        # Проверяем различные варианты названий
        if (district_name in parsed_name or 
            parsed_name.replace(' район', '') in district_name or
            district_name.replace(' район', '') in parsed_name):
            found_data = settlements
            break
    
    if found_data:
        # Обновляем данные
        district['settlements'] = [
            {
                'name': s['name'],
                'type': s['type'],
                'population': s['population'],
                'id': f'01-{i+1:03d}'
            }
            for i, s in enumerate(found_data)
        ]
        district['population'] = sum(s['population'] for s in found_data)
        print(f"+ {district_name}: {len(found_data)} населенных пунктов, население: {district['population']:,} чел.")
        updated_districts.append(district_name)
    else:
        print(f"- {district_name}: данные не найдены в распарсенных")

# Удаляем "Майкопский городской округ" из списка районов, если он там есть
# (это городской округ, не район)
region['urban_districts'] = [
    d for d in region['urban_districts'] 
    if 'городской округ' not in d['name'].lower() or d['name'] == 'Майкопский городской округ'
]

# Пересчитываем население региона
cities_pop = sum(c['population'] for c in region['cities'])
districts_pop = sum(d['population'] for d in region['urban_districts'])
region['population'] = cities_pop + districts_pop

# Сохраняем
with open(south_file, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"\n+ Обновлено районов: {len(updated_districts)}")
print(f"+ Население региона: {region['population']:,} чел.")
print(f"+ Районов в списке: {len(region['urban_districts'])}")
print("\n+ Данные сохранены!")

