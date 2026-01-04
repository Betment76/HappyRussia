#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Скрипт для обновления населения городов федерального значения
и добавления недостающих городов
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

def update_federal_cities_population():
    """Обновить население городов федерального значения"""
    
    # Данные о городах федерального значения с актуальным населением
    federal_cities_data = {
        '77': {  # Москва
            'cities': {
                'Москва': 13_149_803,  # Основной город (2024)
                'Троицк': 73_421,
                'Зеленоград': 250_000,  # Приблизительно
                'Щербинка': 50_000,  # Приблизительно
            }
        },
        '78': {  # Санкт-Петербург
            'cities': {
                'Санкт-Петербург': 5_597_763,  # Основной город
                'Колпино': 20_748,
                'Кронштадт': 28_167,
                'Петергоф': 14_979,
                'Сестрорецк': 14_000,
                'Пушкин': 100_000,  # Приблизительно (включая Царское Село)
            }
        },
        '92': {  # Севастополь
            'cities': {
                'Севастополь': 561_374,  # Основной город
                'Инкерман': 10_196,
            }
        }
    }
    
    base_path = os.path.join(os.path.dirname(__file__), '..', 'app', 'data', 'districts')
    
    files_map = {
        '77': 'central.json',
        '78': 'northwest.json',
        '92': 'south.json'
    }
    
    for region_id, data in federal_cities_data.items():
        file_path = os.path.join(base_path, files_map[region_id])
        
        print(f"Обновляю города для региона {region_id}...")
        
        # Читаем файл
        with open(file_path, 'r', encoding='utf-8') as f:
            district_data = json.load(f)
        
        # Ищем регион по ID
        found = False
        for region in district_data.get('regions', []):
            if region.get('id') == region_id:
                # Обновляем население городов
                updated_count = 0
                for city in region.get('cities', []):
                    city_name = city.get('name', '')
                    if city_name in data['cities']:
                        old_pop = city.get('population', 0)
                        new_pop = data['cities'][city_name]
                        if old_pop != new_pop:
                            city['population'] = new_pop
                            print(f"  {city_name}: {old_pop:,} -> {new_pop:,}")
                            updated_count += 1
                
                # Обновляем население в городских округах
                for district in region.get('urban_districts', []):
                    for settlement in district.get('settlements', []):
                        settlement_name = settlement.get('name', '')
                        if settlement_name in data['cities']:
                            old_pop = settlement.get('population', 0)
                            new_pop = data['cities'][settlement_name]
                            if old_pop != new_pop:
                                settlement['population'] = new_pop
                                if settlement_name not in [c.get('name') for c in region.get('cities', [])]:
                                    print(f"  {settlement_name} (в округе): {old_pop:,} -> {new_pop:,}")
                
                # Для городов федерального значения население региона = население основного города
                # Москва, Санкт-Петербург, Севастополь
                main_city_names = {
                    '77': 'Москва',
                    '78': 'Санкт-Петербург',
                    '92': 'Севастополь'
                }
                main_city_pop = data['cities'].get(main_city_names[region_id], 0)
                region['population'] = main_city_pop
                print(f"  Население региона (основной город): {main_city_pop:,}")
                print(f"  Обновлено городов: {updated_count}\n")
                
                found = True
                break
        
        if not found:
            print(f"  ⚠️  Регион с ID {region_id} не найден в файле {files_map[region_id]}")
            continue
        
        # Сохраняем обновленный файл
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(district_data, f, ensure_ascii=False, indent=2)
        
        print(f"  [OK] Файл {files_map[region_id]} обновлен\n")
    
    print("Готово! Население городов федерального значения обновлено.")

if __name__ == '__main__':
    update_federal_cities_population()

