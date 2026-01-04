#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Полный парсинг данных республики Адыгея с RuWiki"""

import requests
from bs4 import BeautifulSoup
import json
from pathlib import Path
import time

url = 'https://ru.ruwiki.ru/wiki/Населённые_пункты_Адыгеи'

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
}

print("=== ПАРСИНГ ДАННЫХ РЕСПУБЛИКИ АДЫГЕЯ ===\n")

try:
    response = requests.get(url, headers=headers, timeout=30)
    response.raise_for_status()
    response.encoding = 'utf-8'
    
    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Структура данных
    districts_data = {}
    current_section = None
    
    # Ищем все заголовки и таблицы
    for element in soup.find_all(['h2', 'h3', 'h4', 'table']):
        if element.name in ['h2', 'h3', 'h4']:
            text = element.get_text(strip=True)
            
            # Определяем текущий раздел
            if 'Гиагинский' in text:
                current_section = 'Гиагинский район'
                districts_data[current_section] = []
            elif 'Кошехабльский' in text:
                current_section = 'Кошехабльский район'
                districts_data[current_section] = []
            elif 'Красногвардейский' in text:
                current_section = 'Красногвардейский район'
                districts_data[current_section] = []
            elif 'Майкопский' in text and 'район' in text.lower():
                current_section = 'Майкопский район'
                districts_data[current_section] = []
            elif 'Тахтамукайский' in text:
                current_section = 'Тахтамукайский район'
                districts_data[current_section] = []
            elif 'Теучежский' in text:
                current_section = 'Теучежский район'
                districts_data[current_section] = []
            elif 'Шовгеновский' in text:
                current_section = 'Шовгеновский район'
                districts_data[current_section] = []
            elif 'Майкопский' in text and 'Майкоп' in text:
                current_section = 'Майкопский городской округ'
                districts_data[current_section] = []
            elif 'Адыгейский' in text and 'Адыгейск' in text:
                current_section = 'Адыгейский городской округ'
                districts_data[current_section] = []
        
        elif element.name == 'table' and current_section:
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
                    
                    if not name or name in ['Населённый пункт', '№', 'Тип', 'Население']:
                        continue
                    
                    # Тип
                    type_text = cells[2].get_text(strip=True)
                    if not type_text or type_text in ['Тип', 'Население']:
                        continue
                    
                    # Население
                    pop_text = cells[3].get_text(strip=True) if len(cells) > 3 else cells[2].get_text(strip=True)
                    pop_text = pop_text.replace(' ', '').replace('\u202f', '').replace('\xa0', '')
                    population = 0
                    if pop_text and pop_text not in ['—', '-', '']:
                        try:
                            population = int(pop_text)
                        except:
                            pass
                    
                    if name:
                        districts_data[current_section].append({
                            'name': name,
                            'type': type_text,
                            'population': population
                        })
                
                except Exception as e:
                    continue
    
    # Выводим результаты
    print("=== РЕЗУЛЬТАТЫ ПАРСИНГА ===\n")
    total = 0
    for district_name, settlements in districts_data.items():
        if settlements:
            pop_sum = sum(s['population'] for s in settlements)
            print(f"{district_name}: {len(settlements)} населенных пунктов, население: {pop_sum:,} чел.")
            total += len(settlements)
    
    print(f"\nВсего распарсено: {total} населенных пунктов")
    
    # Сохраняем
    output_file = Path(__file__).parent / 'adygea_parsed_full.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(districts_data, f, ensure_ascii=False, indent=2)
    
    print(f"\nДанные сохранены в: {output_file}")
    
except Exception as e:
    print(f"Ошибка: {e}")
    import traceback
    traceback.print_exc()

