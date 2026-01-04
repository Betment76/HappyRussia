"""
Данные о населенных пунктах России

Иерархическая структура:
- Федеральный округ (население)
  - Регионы (население)
    - Города региона (население)
    - Городские округа (население)
      - Город (население)
      - Поселок (население)
      - Село (население)
      - Деревня (население)
      - Заимка (население)

Данные заполняются из RuWiki: https://ru.ruwiki.ru/wiki/Населённые_пункты_субъектов_Российской_Федерации

ВНИМАНИЕ: Это шаблон структуры. Реальные данные нужно заполнить из RuWiki.
"""

from typing import Dict, Any
from .models import (
    RussiaData, FederalDistrict, Region, UrbanDistrict, 
    Settlement, SettlementType
)


def create_empty_structure() -> RussiaData:
    """
    Создать пустую структуру данных России
    
    Структура соответствует административному делению РФ
    """
    data = RussiaData()
    
    # Список федеральных округов
    federal_districts = [
        "Центральный",
        "Северо-Западный",
        "Южный",
        "Северо-Кавказский",
        "Приволжский",
        "Уральский",
        "Сибирский",
        "Дальневосточный"
    ]
    
    # Создаем структуру федеральных округов
    for district_name in federal_districts:
        district = FederalDistrict(
            name=district_name,
            population=0,
            regions=[]
        )
        data.federal_districts.append(district)
    
    return data


def _load_district_from_json(district_data: Dict[str, Any]) -> FederalDistrict:
    """
    Загрузить данные одного федерального округа из JSON
    
    Args:
        district_data: Словарь с данными округа
        
    Returns:
        Объект FederalDistrict
    """
    district = FederalDistrict(
        name=district_data['name'],
        population=district_data.get('population', 0),
        regions=[]
    )
    
    # Добавляем регионы
    for region_data in district_data.get('regions', []):
        region = Region(
            id=region_data['id'],
            name=region_data['name'],
            population=region_data.get('population', 0),
            federal_district=region_data.get('federal_district', district_data['name']),
            cities=[],
            urban_districts=[]
        )
        
        # Добавляем города
        for city_data in region_data.get('cities', []):
            # Определяем тип населенного пункта
            settlement_type_str = city_data.get('type', 'город')
            try:
                settlement_type = SettlementType(settlement_type_str)
            except ValueError:
                # Если тип не найден, используем город по умолчанию
                settlement_type = SettlementType.CITY
            
            city = Settlement(
                name=city_data['name'],
                type=settlement_type,
                population=city_data.get('population', 0),
                id=city_data.get('id')
            )
            region.cities.append(city)
        
        # Добавляем городские округа
        for district_data_item in region_data.get('urban_districts', []):
            urban_district = UrbanDistrict(
                name=district_data_item['name'],
                population=district_data_item.get('population', 0),
                settlements=[]
            )
            
            # Добавляем населенные пункты в округ
            for settlement_data in district_data_item.get('settlements', []):
                try:
                    settlement = Settlement(
                        name=settlement_data['name'],
                        type=SettlementType(settlement_data['type']),
                        population=settlement_data.get('population', 0),
                        id=settlement_data.get('id')
                    )
                    urban_district.settlements.append(settlement)
                except (ValueError, KeyError) as e:
                    # Пропускаем некорректные данные
                    continue
            
            region.urban_districts.append(urban_district)
        
        district.regions.append(region)
    
    return district


def load_russia_data() -> RussiaData:
    """
    Загрузить данные о населенных пунктах России
    
    Сначала пытается загрузить из файлов по округам (districts/*.json),
    если не найдено - загружает из старого файла settlements_data.json
    """
    import json
    from pathlib import Path
    
    # Маппинг русских названий на безопасные имена файлов
    DISTRICT_FILENAMES = {
        'Центральный': 'central.json',
        'Северо-Западный': 'northwest.json',
        'Южный': 'south.json',
        'Северо-Кавказский': 'north_caucasus.json',
        'Приволжский': 'volga.json',
        'Уральский': 'ural.json',
        'Сибирский': 'siberian.json',
        'Дальневосточный': 'far_east.json'
    }
    
    data = RussiaData()
    data_dir = Path(__file__).parent
    districts_dir = data_dir / 'districts'
    
    # Список федеральных округов
    federal_districts = [
        "Центральный",
        "Северо-Западный",
        "Южный",
        "Северо-Кавказский",
        "Приволжский",
        "Уральский",
        "Сибирский",
        "Дальневосточный"
    ]
    
    # Пытаемся загрузить из файлов по округам
    if districts_dir.exists() and districts_dir.is_dir():
        loaded_count = 0
        for district_name in federal_districts:
            # Используем безопасное имя файла
            safe_filename = DISTRICT_FILENAMES.get(district_name, f"{district_name}.json")
            district_file = districts_dir / safe_filename
            
            # Пробуем сначала безопасное имя, потом русское (для обратной совместимости)
            if not district_file.exists():
                district_file = districts_dir / f"{district_name}.json"
            
            if district_file.exists():
                try:
                    with open(district_file, 'r', encoding='utf-8') as f:
                        district_data = json.load(f)
                    
                    district = _load_district_from_json(district_data)
                    data.federal_districts.append(district)
                    loaded_count += 1
                except Exception as e:
                    print(f"[WARNING] Ошибка при загрузке {district_file}: {e}")
                    continue
        
        if loaded_count > 0:
            # Пересчитываем население
            data.calculate_all_populations()
            return data
    
    # Если файлы по округам не найдены, пытаемся загрузить из старого файла
    json_file = data_dir / 'settlements_data.json'
    
    if json_file.exists():
        try:
            with open(json_file, 'r', encoding='utf-8') as f:
                json_data = json.load(f)
            
            # Создаем структуру из JSON данных
            for district_data in json_data.get('federal_districts', []):
                district = _load_district_from_json(district_data)
                data.federal_districts.append(district)
            
            # Пересчитываем население
            data.calculate_all_populations()
            return data
        except Exception as e:
            print(f"[ERROR] Ошибка при загрузке данных из {json_file}: {e}")
    
    # Если ничего не загрузилось, возвращаем пустую структуру
    print(f"[WARNING] Файлы с данными не найдены, возвращаем пустую структуру")
    return create_empty_structure()


# Глобальный экземпляр данных (ленивая загрузка)
_russia_data: RussiaData | None = None


def get_russia_data() -> RussiaData:
    """Получить данные о населенных пунктах России (с кэшированием)"""
    global _russia_data
    if _russia_data is None:
        _russia_data = load_russia_data()
    return _russia_data


def get_settlement_population(region_id: str, settlement_name: str) -> int:
    """
    Получить население населенного пункта
    
    Args:
        region_id: ID региона (код субъекта РФ)
        settlement_name: Название населенного пункта
    
    Returns:
        Население или 0, если не найдено
    """
    data = get_russia_data()
    settlement = data.get_settlement_by_name(region_id, settlement_name)
    return settlement.population if settlement else 0


def get_region_population_from_settlements(region_id: str) -> int:
    """
    Получить население региона на основе населенных пунктов
    
    Args:
        region_id: ID региона
    
    Returns:
        Население региона или 0, если не найден
    """
    data = get_russia_data()
    region = data.get_region_by_id(region_id)
    if region:
        region.calculate_population()
        return region.population
    return 0


def get_federal_district_population(district_name: str) -> int:
    """
    Получить население федерального округа
    
    Args:
        district_name: Название федерального округа
    
    Returns:
        Население округа или 0, если не найден
    """
    data = get_russia_data()
    for district in data.federal_districts:
        if district.name == district_name:
            district.calculate_population()
            return district.population
    return 0

