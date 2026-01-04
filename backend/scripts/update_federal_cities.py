#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Скрипт для обновления данных о городах федерального значения
Согласно: https://ru.ruwiki.ru/wiki/Город_федерального_значения
"""

import json
import sys
import os

# Настройка кодировки для Windows
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# Добавляем путь к корню проекта
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

def update_federal_cities():
    """Обновить данные о городах федерального значения"""
    
    # Данные о городах федерального значения согласно RuWiki
    federal_cities = {
        '77': {
            'name': 'Город федерального значения Москва',
            'population': 13_149_803,  # Данные на 2024 год
            'file': 'central.json',
            'federal_district': 'Центральный'
        },
        '78': {
            'name': 'Город федерального значения Санкт-Петербург',
            'population': 5_597_763,  # Данные на 2024 год
            'file': 'northwest.json',
            'federal_district': 'Северо-Западный'
        },
        '92': {
            'name': 'Город федерального значения Севастополь',
            'population': 561_374,  # Данные на 2024 год
            'file': 'south.json',
            'federal_district': 'Южный'
        }
    }
    
    base_path = os.path.join(os.path.dirname(__file__), '..', 'app', 'data', 'districts')
    
    for region_id, data in federal_cities.items():
        file_path = os.path.join(base_path, data['file'])
        
        print(f"Обновляю {data['name']} (ID: {region_id})...")
        
        # Читаем файл
        with open(file_path, 'r', encoding='utf-8') as f:
            district_data = json.load(f)
        
        # Ищем регион по ID
        found = False
        for region in district_data.get('regions', []):
            if region.get('id') == region_id:
                # Обновляем название и население
                old_name = region.get('name', '')
                region['name'] = data['name']
                region['population'] = data['population']
                region['federal_district'] = data['federal_district']
                
                print(f"  Название: '{old_name}' -> '{data['name']}'")
                print(f"  Население: {region.get('population', 0):,} -> {data['population']:,}")
                
                found = True
                break
        
        if not found:
            print(f"  ⚠️  Регион с ID {region_id} не найден в файле {data['file']}")
            continue
        
        # Сохраняем обновленный файл
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(district_data, f, ensure_ascii=False, indent=2)
        
        print(f"  [OK] Файл {data['file']} обновлен\n")
    
    print("Готово! Данные о городах федерального значения обновлены.")

if __name__ == '__main__':
    update_federal_cities()

