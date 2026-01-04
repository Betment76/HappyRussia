#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Финальное исправление данных республики Адыгея"""

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

if not region:
    print("Республика Адыгея не найдена!")
    exit(1)

print("=== ФИНАЛЬНОЕ ИСПРАВЛЕНИЕ ДАННЫХ ===\n")

# Правильный маппинг
district_mapping = {
    'Гиагинский район': 'Гиагинский район',
    'Кошехабльский район': 'Кошехабльский район',
    'Красногвардейский район': 'Красногвардейский район',
    'Майкопский район': 'Майкопский район',
    'Тахтамукайский район': 'Тахтамукайский район',
    'Теучежский район': 'Теучежский район',
    'Шовгеновский район': 'Шовгеновский район',
}

# Обновляем только районы (не городские округа)
new_districts = []
for district in region['urban_districts']:
    district_name = district['name']
    
    # Пропускаем городские округа - они не должны быть в списке районов
    if 'городской округ' in district_name.lower():
        print(f"Пропущен (городской округ): {district_name}")
        continue
    
    # Ищем данные для этого района
    found_settlements = None
    for parsed_name, settlements in parsed_data.items():
        if district_name in parsed_name or parsed_name.replace(' район', '') in district_name:
            found_settlements = settlements
            break
    
    if found_settlements:
        district['settlements'] = [
            {
                'name': s['name'],
                'type': s['type'],
                'population': s['population'],
                'id': f'01-{len(new_districts) * 100 + i + 1:03d}'
            }
            for i, s in enumerate(found_settlements)
        ]
        district['population'] = sum(s['population'] for s in found_settlements)
        print(f"+ {district_name}: {len(found_settlements)} населенных пунктов, население: {district['population']:,} чел.")
    else:
        print(f"- {district_name}: данные не найдены")
    
    new_districts.append(district)

region['urban_districts'] = new_districts

# Пересчитываем население
cities_pop = sum(c['population'] for c in region['cities'])
districts_pop = sum(d['population'] for d in region['urban_districts'])
region['population'] = cities_pop + districts_pop

# Сохраняем
with open(south_file, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"\n+ Районов в списке: {len(region['urban_districts'])} (должно быть 7)")
print(f"+ Население региона: {region['population']:,} чел.")
print("+ Данные сохранены!")

