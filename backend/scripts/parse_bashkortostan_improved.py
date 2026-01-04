#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Улучшенный парсинг данных Республики Башкортостан с RuWiki"""

import requests
from bs4 import BeautifulSoup
import json
from pathlib import Path
import re

url = 'https://ru.ruwiki.ru/wiki/Населённые_пункты_Башкортостана'

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
}

print("=== ПАРСИНГ ДАННЫХ РЕСПУБЛИКИ БАШКОРТОСТАН ===\n")

try:
    response = requests.get(url, headers=headers, timeout=60)
    response.raise_for_status()
    response.encoding = 'utf-8'
    
    soup = BeautifulSoup(response.text, 'html.parser')
    
    districts_data = {}
    city_districts_data = {}
    current_section = None
    in_city_section = False
    in_district_section = False
    
    # Ищем все элементы страницы
    for element in soup.find_all(['h2', 'h3', 'h4', 'table']):
        if element.name in ['h2', 'h3', 'h4']:
            text = element.get_text(strip=True)
            
            # Определяем разделы
            if 'Города республиканского значения' in text:
                in_city_section = True
                in_district_section = False
                print(f"Раздел: {text}")
            elif 'Не входящие в состав районов' in text or 'городские округа' in text.lower():
                in_city_section = True
                in_district_section = False
            elif 'Входящие в состав' in text:
                in_city_section = True
                in_district_section = False
            elif text == 'Районы' or (text.startswith('Районы') and 'Города' not in text):
                in_city_section = False
                in_district_section = True
                print(f"Раздел: {text}")
            elif in_city_section or in_district_section:
                # Это название конкретного города или района
                section_name = text.strip()
                
                # Пропускаем служебные заголовки
                if section_name in ['См. также', 'Примечания', 'Литература']:
                    continue
                
                # Определяем, городской округ или район
                if in_city_section:
                    # Городские округа (Уфа, Агидель, Кумертау и т.д.)
                    if section_name and len(section_name) > 1:
                        # Проверяем, что это не подзаголовок таблицы
                        if not section_name.startswith('№') and 'Населённый пункт' not in section_name:
                            current_section = section_name
                            city_districts_data[current_section] = []
                            print(f"  Городской округ: {current_section}")
                            current_section = None  # Сбрасываем после определения
                elif in_district_section:
                    # Районы
                    if section_name and len(section_name) > 2:
                        # Проверяем, что это название района
                        if 'район' in section_name.lower() or any(word in section_name for word in ['ский', 'ский район', 'ой район']):
                            current_section = section_name
                            districts_data[current_section] = []
                            print(f"  Район: {current_section}")
        
        elif element.name == 'table' and 'wikitable' in element.get('class', []):
            # Парсим таблицу
            rows = element.find_all('tr')
            if len(rows) < 2:
                continue
            
            # Определяем текущий раздел по предыдущему контексту
            # Ищем заголовок перед таблицей
            prev_element = element.find_previous(['h2', 'h3', 'h4'])
            if prev_element:
                section_name = prev_element.get_text(strip=True)
                
                # Определяем тип раздела
                if in_city_section and section_name not in ['Города республиканского значения', 'Не входящие в состав районов', 'Входящие в состав']:
                    current_section = section_name
                    if current_section not in city_districts_data:
                        city_districts_data[current_section] = []
                elif in_district_section and ('район' in section_name.lower() or 'ский' in section_name):
                    current_section = section_name
                    if current_section not in districts_data:
                        districts_data[current_section] = []
            
            # Парсим строки таблицы
            for row in rows[1:]:  # Пропускаем заголовок
                cells = row.find_all(['td', 'th'])
                if len(cells) < 3:
                    continue
                
                try:
                    # Название (обычно во второй колонке)
                    name_cell = cells[1]
                    name_link = name_cell.find('a')
                    name = name_link.get_text(strip=True) if name_link else name_cell.get_text(strip=True)
                    
                    if not name or name in ['Населённый пункт', '№', 'Тип', 'Население', 'Город', 'Посёлок', 'Село']:
                        continue
                    
                    # Тип (обычно в третьей колонке)
                    type_text = ''
                    if len(cells) > 2:
                        type_text = cells[2].get_text(strip=True)
                    
                    if not type_text or type_text in ['Тип', 'Население']:
                        continue
                    
                    # Население (обычно в четвертой колонке)
                    pop_text = ''
                    if len(cells) > 3:
                        pop_text = cells[3].get_text(strip=True)
                    elif len(cells) > 2:
                        pop_text = cells[2].get_text(strip=True)
                    
                    pop_text = pop_text.replace(' ', '').replace('\u202f', '').replace('\xa0', '').replace(',', '')
                    population = 0
                    if pop_text and pop_text not in ['—', '-', '']:
                        try:
                            population = int(pop_text)
                        except:
                            pass
                    
                    if name and type_text and current_section:
                        settlement = {
                            'name': name,
                            'type': type_text,
                            'population': population
                        }
                        
                        if in_city_section and current_section in city_districts_data:
                            city_districts_data[current_section].append(settlement)
                        elif in_district_section and current_section in districts_data:
                            districts_data[current_section].append(settlement)
                
                except Exception as e:
                    continue
    
    # Выводим результаты
    print("\n=== РЕЗУЛЬТАТЫ ПАРСИНГА ===\n")
    
    total_cities = 0
    print(f"Городские округа ({len(city_districts_data)}):")
    for city_name, settlements in sorted(city_districts_data.items()):
        if settlements:
            pop_sum = sum(s['population'] for s in settlements)
            print(f"  {city_name}: {len(settlements)} населенных пунктов, население: {pop_sum:,} чел.")
            total_cities += len(settlements)
    
    total_districts = 0
    print(f"\nРайоны ({len(districts_data)}):")
    for district_name, settlements in sorted(districts_data.items()):
        if settlements:
            pop_sum = sum(s['population'] for s in settlements)
            print(f"  {district_name}: {len(settlements)} населенных пунктов, население: {pop_sum:,} чел.")
            total_districts += len(settlements)
    
    print(f"\nВсего распарсено:")
    print(f"  Городские округа: {len(city_districts_data)} ({total_cities} населенных пунктов)")
    print(f"  Районы: {len(districts_data)} ({total_districts} населенных пунктов)")
    
    # Сохраняем
    output_file = Path(__file__).parent / 'bashkortostan_parsed_improved.json'
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

