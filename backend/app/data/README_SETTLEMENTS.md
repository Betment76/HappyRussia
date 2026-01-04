# Данные о населенных пунктах России

## Структура данных

Иерархическая структура населенных пунктов:

```
Федеральный округ (население)
  └── Регион (население)
      ├── Города региона (население)
      └── Городские округа (население)
          ├── Город (население)
          ├── Поселок (население)
          ├── Село (население)
          ├── Деревня (население)
          └── Заимка (население)
```

## Файлы

- `models.py` - Модели данных (Pydantic/dataclass)
- `russia_settlements.py` - Загрузка и работа с данными
- `settlements_data.json` - Старый JSON файл со всеми данными (13 MB, не рекомендуется)
- `districts/*.json` - Файлы данных по федеральным округам (рекомендуется)

### Структура файлов по округам

Данные разбиты на 8 файлов для оптимизации производительности (используются безопасные имена на латинице):
- `districts/central.json` (Центральный, 2.17 MB)
- `districts/northwest.json` (Северо-Западный, 2.54 MB)
- `districts/south.json` (Южный, 996 KB)
- `districts/north_caucasus.json` (Северо-Кавказский, 624 KB)
- `districts/volga.json` (Приволжский, 3.41 MB)
- `districts/ural.json` (Уральский, 40 KB)
- `districts/siberian.json` (Сибирский, 1.02 MB)
- `districts/far_east.json` (Дальневосточный, 717 KB)

Подробнее см. `districts/README.md`

## Источник данных

Данные берутся с RuWiki:
https://ru.ruwiki.ru/wiki/Населённые_пункты_субъектов_Российской_Федерации

## Использование

### 1. Парсинг данных с RuWiki

```bash
cd backend
pip install requests beautifulsoup4 lxml
python scripts/parse_ruwiki_settlements.py
```

### 2. Использование в коде

```python
from app.data.russia_settlements import (
    get_russia_data,
    get_settlement_population,
    get_region_population_from_settlements
)

# Получить данные
data = get_russia_data()

# Найти население населенного пункта
population = get_settlement_population("01", "Майкоп")

# Получить население региона
region_pop = get_region_population_from_settlements("01")
```

## Структура моделей

### Settlement (Населенный пункт)
- `name`: Название
- `type`: Тип (город, поселок, село и т.д.)
- `population`: Население
- `id`: Уникальный ID (опционально)

### UrbanDistrict (Городской округ)
- `name`: Название округа
- `population`: Население округа
- `settlements`: Список населенных пунктов

### Region (Регион)
- `id`: Код региона (01-99)
- `name`: Название региона
- `population`: Население региона
- `federal_district`: Федеральный округ
- `cities`: Список городов
- `urban_districts`: Список городских округов

### FederalDistrict (Федеральный округ)
- `name`: Название округа
- `population`: Население округа
- `regions`: Список регионов

## TODO

1. ✅ Создать модели данных
2. ✅ Создать структуру загрузки данных
3. ⏳ Парсить данные с RuWiki
4. ⏳ Заполнить реальными данными
5. ⏳ Интегрировать с API
6. ⏳ Добавить кэширование

## Примечания

- Данные нужно регулярно обновлять
- Население может меняться
- Структура административного деления может изменяться
- Некоторые регионы имеют сложную структуру (округа, районы)

