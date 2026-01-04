#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Парсинг данных Республики Башкортостан с RuWiki"""

import requests
from bs4 import BeautifulSoup
import json
from pathlib import Path
import time

url = 'https://ru.ruwiki.ru/wiki/Населённые_пункты_Башкортостана'

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
}

print("=== ПАРСИНГ ДАННЫХ РЕСПУБЛИКИ БАШКОРТОСТАН ===\n")
print(f"URL: {url}\n")

try:
    response = requests.get(url, headers=headers, timeout=60)
    response.raise_for_status()
    response.encoding = 'utf-8'
    
    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Структура данных
    districts_data = {}
    city_districts_data = {}
    current_section = None
    current_type = None  # 'district' или 'city_district'
    
    # Ищем все заголовки и таблицы
    for element in soup.find_all(['h2', 'h3', 'h4', 'table']):
        if element.name in ['h2', 'h3', 'h4']:
            text = element.get_text(strip=True)
            
            # Определяем тип раздела
            if 'Города республиканского значения' in text or 'Не входящие в состав районов' in text:
                current_type = 'city_district'
                print(f"Раздел: {text}")
            elif 'Районы' in text and 'Города' not in text:
                current_type = 'district'
                print(f"Раздел: {text}")
            elif current_type:
                # Определяем конкретный район или городской округ
                # Убираем лишние символы и определяем название
                section_name = text.strip()
                
                if current_type == 'city_district':
                    # Городские округа
                    if section_name and section_name not in ['Уфа', 'Агидель', 'Кумертау', 'Нефтекамск', 'Октябрьский', 'Салават', 'Сибай', 'Стерлитамак', 'Межгорье']:
                        # Проверяем, не является ли это подзаголовком
                        if 'ЗАТО' not in section_name and 'городской округ' not in section_name.lower():
                            current_section = section_name
                            city_districts_data[current_section] = []
                            print(f"  Городской округ: {current_section}")
                elif current_type == 'district':
                    # Районы
                    if section_name and len(section_name) > 2:
                        # Проверяем, что это не общий заголовок
                        if 'район' in section_name.lower() or 'Район' in section_name:
                            current_section = section_name
                            districts_data[current_section] = []
                            print(f"  Район: {current_section}")
        
        elif element.name == 'table' and current_section and current_type:
            rows = element.find_all('tr')
            for row in rows[1:]:  # Пропускаем заголовок
                cells = row.find_all(['td', 'th'])
                if len(cells) < 3:
                    continue
                
                try:
                    # Название
                    name_cell = cells[1]
                    name_link = name_cell.find('a')
                    name = name_link.get_text(strip=True) if name_link else name_cell.get_text(strip=True)
                    
                    if not name or name in ['Населённый пункт', '№', 'Тип', 'Население', 'Город', 'Посёлок']:
                        continue
                    
                    # Тип
                    type_text = cells[2].get_text(strip=True) if len(cells) > 2 else ''
                    if not type_text or type_text in ['Тип', 'Население']:
                        # Может быть тип в другой ячейке
                        if len(cells) > 3:
                            type_text = cells[3].get_text(strip=True)
                    
                    if not type_text:
                        continue
                    
                    # Население
                    pop_cell = cells[3] if len(cells) > 3 else cells[2]
                    pop_text = pop_cell.get_text(strip=True).replace(' ', '').replace('\u202f', '').replace('\xa0', '')
                    population = 0
                    if pop_text and pop_text not in ['—', '-', '']:
                        try:
                            population = int(pop_text)
                        except:
                            pass
                    
                    if name:
                        settlement = {
                            'name': name,
                            'type': type_text,
                            'population': population
                        }
                        
                        if current_type == 'city_district':
                            city_districts_data[current_section].append(settlement)
                        elif current_type == 'district':
                            districts_data[current_section].append(settlement)
                
                except Exception as e:
                    continue
    
    # Выводим результаты
    print("\n=== РЕЗУЛЬТАТЫ ПАРСИНГА ===\n")
    
    total_cities = 0
    print("Городские округа:")
    for city_name, settlements in city_districts_data.items():
        if settlements:
            pop_sum = sum(s['population'] for s in settlements)
            print(f"  {city_name}: {len(settlements)} населенных пунктов, население: {pop_sum:,} чел.")
            total_cities += len(settlements)
    
    total_districts = 0
    print("\nРайоны:")
    for district_name, settlements in districts_data.items():
        if settlements:
            pop_sum = sum(s['population'] for s in settlements)
            print(f"  {district_name}: {len(settlements)} населенных пунктов, население: {pop_sum:,} чел.")
            total_districts += len(settlements)
    
    print(f"\nВсего распарсено:")
    print(f"  Городские округа: {len(city_districts_data)} ({total_cities} населенных пунктов)")
    print(f"  Районы: {len(districts_data)} ({total_districts} населенных пунктов)")
    
    # Сохраняем
    output_file = Path(__file__).parent / 'bashkortostan_parsed.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump({
            'city_districts': city_districts_data,
            'districts': districts_data
        }, f, ensure_ascii=False, indent=2)
    
    print(f"\nДанные сохранены в: {output_file}")
    
except Exception as e:
    print(f"Ошибка: {e}")
    import traceback
    traceback.print_exc()

