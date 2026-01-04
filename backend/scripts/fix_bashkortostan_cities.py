#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Исправление списка городов Республики Башкортостан"""

import json
from pathlib import Path

file_path = Path(__file__).parent.parent / 'app' / 'data' / 'districts' / 'volga.json'

with open(file_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

region = None
for r in data['regions']:
    if r['id'] == '02':
        region = r
        break

if not region:
    print("Республика Башкортостан не найдена!")
    exit(1)

print("=== ИСПРАВЛЕНИЕ СПИСКА ГОРОДОВ РЕСПУБЛИКИ БАШКОРТОСТАН ===\n")

# Согласно RuWiki, города республиканского значения, не входящие в состав районов (городские округа):
# 1. Уфа
# 2. Агидель
# 3. Кумертау
# 4. Нефтекамск
# 5. Октябрьский
# 6. Салават
# 7. Сибай
# 8. Стерлитамак
# 9. Межгорье (ЗАТО)

cities_republican_value = {
    'Уфа',
    'Агидель',
    'Кумертау',
    'Нефтекамск',
    'Октябрьский',
    'Салават',
    'Сибай',
    'Стерлитамак',
    'Межгорье'
}

print(f"Текущее количество городов: {len(region['cities'])}")
print("\nТекущие города:")
for i, city in enumerate(region['cities'], 1):
    print(f"  {i}. {city['name']} ({city['population']:,} чел.)")

# Оставляем только города республиканского значения (не входящие в состав районов)
new_cities = []
for city in region['cities']:
    if city['name'] in cities_republican_value:
        new_cities.append(city)
        print(f"\n+ Оставлен: {city['name']} ({city['population']:,} чел.)")
    else:
        print(f"- Удален из списка cities: {city['name']} (должен быть в составе района)")

region['cities'] = new_cities

# Проверяем, все ли города найдены
found_cities = {c['name'] for c in new_cities}
missing = cities_republican_value - found_cities
if missing:
    print(f"\n⚠ Отсутствуют города: {', '.join(sorted(missing))}")

# Пересчитываем население региона
cities_pop = sum(c['population'] for c in region['cities'])
districts_pop = sum(d['population'] for d in region['urban_districts'])
region['population'] = cities_pop + districts_pop

# Сохраняем
with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"\n=== ИТОГОВАЯ ПРОВЕРКА ===")
print(f"Количество городов республиканского значения: {len(region['cities'])}")
for city in region['cities']:
    print(f"  - {city['name']} ({city['population']:,} чел.)")

print(f"\nНаселение городов: {cities_pop:,} чел.")
print(f"Население районов: {districts_pop:,} чел.")
print(f"Общее население: {region['population']:,} чел.")

print("\n+ Данные сохранены!")

