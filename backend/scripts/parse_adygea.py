#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Парсинг данных республики Адыгея с RuWiki"""

import requests
from bs4 import BeautifulSoup
import json
from pathlib import Path
import re

url = 'https://ru.ruwiki.ru/wiki/Населённые_пункты_Адыгеи'

print("=== ПАРСИНГ ДАННЫХ РЕСПУБЛИКИ АДЫГЕЯ ===\n")
print(f"URL: {url}\n")

try:
    response = requests.get(url, timeout=30)
    response.raise_for_status()
    response.encoding = 'utf-8'
    
    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Находим все таблицы с населенными пунктами
    tables = soup.find_all('table', class_='wikitable')
    
    print(f"Найдено таблиц: {len(tables)}\n")
    
    # Структура данных
    districts_data = {
        'Гиагинский район': [],
        'Кошехабльский район': [],
        'Красногвардейский район': [],
        'Майкопский район': [],
        'Тахтамукайский район': [],
        'Теучежский район': [],
        'Шовгеновский район': [],
    }
    
    # Также нужно обработать городские округа
    city_districts = {
        'Майкопский городской округ': [],
        'Адыгейский городской округ': [],
    }
    
    current_district = None
    current_city_district = None
    
    # Ищем заголовки районов и таблицы
    for element in soup.find_all(['h2', 'h3', 'table']):
        if element.name in ['h2', 'h3']:
            text = element.get_text(strip=True)
            # Проверяем, является ли это заголовком района
            for district_name in districts_data.keys():
                if district_name.replace(' район', '') in text or text.startswith(district_name.replace(' район', '')):
                    current_district = district_name
                    print(f"Найден район: {current_district}")
                    break
            
            # Проверяем городские округа
            if 'Майкопский' in text and 'Майкоп' in text:
                current_city_district = 'Майкопский городской округ'
                print(f"Найден городской округ: {current_city_district}")
            elif 'Адыгейский' in text and 'Адыгейск' in text:
                current_city_district = 'Адыгейский городской округ'
                print(f"Найден городской округ: {current_city_district}")
        
        elif element.name == 'table' and 'wikitable' in element.get('class', []):
            # Парсим таблицу
            rows = element.find_all('tr')
            for row in rows[1:]:  # Пропускаем заголовок
                cells = row.find_all(['td', 'th'])
                if len(cells) >= 3:
                    try:
                        # Номер (может быть пропущен)
                        num_cell = cells[0].get_text(strip=True)
                        if not num_cell or num_cell == '№':
                            continue
                        
                        # Название населенного пункта
                        name_cell = cells[1] if len(cells) >= 2 else cells[0]
                        name_link = name_cell.find('a')
                        if name_link:
                            name = name_link.get_text(strip=True)
                        else:
                            name = name_cell.get_text(strip=True)
                        
                        if not name or name in ['Населённый пункт', 'Тип', 'Население']:
                            continue
                        
                        # Тип
                        type_cell = cells[2] if len(cells) >= 3 else cells[1]
                        settlement_type = type_cell.get_text(strip=True)
                        
                        # Население
                        pop_cell = cells[3] if len(cells) >= 4 else cells[2]
                        pop_text = pop_cell.get_text(strip=True).replace(' ', '').replace('\u202f', '')
                        population = 0
                        if pop_text and pop_text != '—' and pop_text != '-':
                            try:
                                population = int(pop_text)
                            except:
                                pass
                        
                        if name and settlement_type:
                            settlement = {
                                'name': name,
                                'type': settlement_type,
                                'population': population,
                                'id': f'01-{len(districts_data.get(current_district, []) + city_districts.get(current_city_district, [])) + 1:03d}'
                            }
                            
                            if current_district and current_district in districts_data:
                                districts_data[current_district].append(settlement)
                            elif current_city_district and current_city_district in city_districts:
                                city_districts[current_city_district].append(settlement)
                    
                    except Exception as e:
                        continue
    
    # Выводим результаты
    print("\n=== РЕЗУЛЬТАТЫ ПАРСИНГА ===\n")
    
    total_settlements = 0
    for district_name, settlements in districts_data.items():
        if settlements:
            pop_sum = sum(s['population'] for s in settlements)
            print(f"{district_name}: {len(settlements)} населенных пунктов, население: {pop_sum:,} чел.")
            total_settlements += len(settlements)
    
    for city_name, settlements in city_districts.items():
        if settlements:
            pop_sum = sum(s['population'] for s in settlements)
            print(f"{city_name}: {len(settlements)} населенных пунктов, население: {pop_sum:,} чел.")
            total_settlements += len(settlements)
    
    print(f"\nВсего распарсено: {total_settlements} населенных пунктов")
    
    # Сохраняем результаты в файл для дальнейшего использования
    output_file = Path(__file__).parent / 'adygea_parsed_data.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump({
            'districts': districts_data,
            'city_districts': city_districts
        }, f, ensure_ascii=False, indent=2)
    
    print(f"\nДанные сохранены в: {output_file}")
    
except Exception as e:
    print(f"Ошибка при парсинге: {e}")
    import traceback
    traceback.print_exc()

