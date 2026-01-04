#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Восстановление районов: Владимирский, Ковровский, Муромский"""

import json
from pathlib import Path
import shutil

# Создаем резервную копию
file_path = Path(__file__).parent.parent / 'app' / 'data' / 'districts' / 'central.json'
backup_path = file_path.with_suffix('.json.backup')

# Если резервной копии нет, создаем её из текущего файла
if not backup_path.exists():
    # Пытаемся найти исходные данные в git или другом месте
    # Но для начала попробуем восстановить логически

    # Согласно RuWiki и структуре данных:
    # "город Владимир" в urban_districts - это Владимирский район
    # "город Ковров" в urban_districts - это Ковровский район  
    # "город Муром" в urban_districts - это Муромский район
    
    # Эти районы были удалены скриптом update_vladimir_data.py
    # Нужно их восстановить
    
    print("Резервной копии нет. Пытаемся восстановить из логики...")
    
    # Загружаем текущие данные
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
    
    # Города областного значения
    cities_data = {
        'Владимир': {'population': 349951, 'id': None},
        'Ковров': {'population': 132417, 'id': None},
        'Муром': {'population': 57053, 'id': None}
    }
    
    # Находим ID городов из списка cities
    for city in region['cities']:
        if city['name'] in cities_data:
            cities_data[city['name']]['id'] = city.get('id')
    
    print("=== ВОССТАНОВЛЕНИЕ РАЙОНОВ ===\n")
    
    # Создаем районы на основе городов
    # Для этого нужно найти данные о населенных пунктах этих районов
    # Но у нас нет исходных данных...
    
    # Попробуем найти в других источниках или создать базовую структуру
    # Согласно RuWiki, у каждого района есть административный центр (город)
    # и населенные пункты
    
    # Восстанавливаем районы с базовой структурой
    districts_to_add = []
    
    # Владимирский район
    vladimir_district = {
        'name': 'Владимирский район',
        'population': 0,  # Нужно будет пересчитать
        'settlements': [
            {
                'id': cities_data['Владимир']['id'] or 'vladimir_city',
                'name': 'Владимир',
                'type': 'город',
                'population': cities_data['Владимир']['population']
            }
        ]
    }
    
    # Ковровский район  
    kovrov_district = {
        'name': 'Ковровский район',
        'population': 0,
        'settlements': [
            {
                'id': cities_data['Ковров']['id'] or 'kovrov_city',
                'name': 'Ковров',
                'type': 'город',
                'population': cities_data['Ковров']['population']
            }
        ]
    }
    
    # Муромский район
    murom_district = {
        'name': 'Муромский район',
        'population': 0,
        'settlements': [
            {
                'id': cities_data['Муром']['id'] or 'murom_city',
                'name': 'Муром',
                'type': 'город',
                'population': cities_data['Муром']['population']
            }
        ]
    }
    
    # Проверяем, есть ли уже эти районы
    existing_districts = {d['name'] for d in region['urban_districts']}
    
    if 'Владимирский район' not in existing_districts:
        # Нужно найти полные данные о районе
        # Пока добавляем базовую структуру
        print("ВНИМАНИЕ: Нужны исходные данные для восстановления районов!")
        print("Районы были удалены и нужно их восстановить из резервной копии")
        print("или из исходных данных парсинга.")
        
        print("\nДля восстановления нужны:")
        print("1. Резервная копия файла до удаления районов")
        print("2. Или исходные данные парсинга с RuWiki")
        
        exit(1)
    
    print("Районы уже существуют или нужно восстановить из резервной копии")

