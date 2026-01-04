"""
Модели данных для иерархической структуры населенных пунктов России

Структура:
- Федеральный округ (население)
  - Регионы (население)
    - Города региона (население)
    - Городские округа (население)
      - Город (население)
      - Поселок (население)
      - Село (население)
      - Деревня (население)
      - Заимка (население)
"""

from typing import List, Optional, Dict, Any
from dataclasses import dataclass, field
from enum import Enum


class SettlementType(str, Enum):
    """Типы населенных пунктов"""
    CITY = "город"  # Город
    TOWN = "поселок"  # Поселок городского типа
    VILLAGE = "село"  # Село
    HAMLET = "деревня"  # Деревня
    SETTLEMENT = "заимка"  # Заимка
    URBAN_SETTLEMENT = "поселок городского типа"  # Поселок городского типа
    WORKING_SETTLEMENT = "рабочий поселок"  # Рабочий поселок


@dataclass
class Settlement:
    """Населенный пункт"""
    name: str  # Название
    type: SettlementType  # Тип населенного пункта
    population: int  # Население
    id: Optional[str] = None  # Уникальный ID (опционально)
    
    def to_dict(self) -> Dict[str, Any]:
        """Преобразовать в словарь"""
        return {
            "name": self.name,
            "type": self.type.value,
            "population": self.population,
            "id": self.id
        }


@dataclass
class UrbanDistrict:
    """Городской округ"""
    name: str  # Название округа
    population: int  # Население округа (сумма всех населенных пунктов)
    settlements: List[Settlement] = field(default_factory=list)  # Населенные пункты в округе
    
    def to_dict(self) -> Dict[str, Any]:
        """Преобразовать в словарь"""
        return {
            "name": self.name,
            "population": self.population,
            "settlements": [s.to_dict() for s in self.settlements]
        }
    
    def calculate_population(self) -> int:
        """Пересчитать население на основе населенных пунктов"""
        self.population = sum(s.population for s in self.settlements)
        return self.population


@dataclass
class Region:
    """Регион (субъект РФ)"""
    id: str  # Код региона (01-99)
    name: str  # Название региона
    population: int  # Население региона
    federal_district: str  # Федеральный округ
    cities: List[Settlement] = field(default_factory=list)  # Города региона
    urban_districts: List[UrbanDistrict] = field(default_factory=list)  # Городские округа
    
    def to_dict(self) -> Dict[str, Any]:
        """Преобразовать в словарь"""
        return {
            "id": self.id,
            "name": self.name,
            "population": self.population,
            "federal_district": self.federal_district,
            "cities": [c.to_dict() for c in self.cities],
            "urban_districts": [ud.to_dict() for ud in self.urban_districts]
        }
    
    def calculate_population(self) -> int:
        """Пересчитать население на основе городов и округов"""
        cities_pop = sum(c.population for c in self.cities)
        districts_pop = sum(ud.calculate_population() for ud in self.urban_districts)
        self.population = cities_pop + districts_pop
        return self.population


@dataclass
class FederalDistrict:
    """Федеральный округ"""
    name: str  # Название округа
    population: int  # Население округа
    regions: List[Region] = field(default_factory=list)  # Регионы в округе
    
    def to_dict(self) -> Dict[str, Any]:
        """Преобразовать в словарь"""
        return {
            "name": self.name,
            "population": self.population,
            "regions": [r.to_dict() for r in self.regions]
        }
    
    def calculate_population(self) -> int:
        """Пересчитать население на основе регионов"""
        self.population = sum(r.calculate_population() for r in self.regions)
        return self.population


@dataclass
class RussiaData:
    """Полная структура данных России"""
    federal_districts: List[FederalDistrict] = field(default_factory=list)
    
    def to_dict(self) -> Dict[str, Any]:
        """Преобразовать в словарь"""
        return {
            "federal_districts": [fd.to_dict() for fd in self.federal_districts]
        }
    
    def get_region_by_id(self, region_id: str) -> Optional[Region]:
        """Найти регион по ID"""
        for district in self.federal_districts:
            for region in district.regions:
                if region.id == region_id:
                    return region
        return None
    
    def get_settlement_by_name(self, region_id: str, settlement_name: str) -> Optional[Settlement]:
        """Найти населенный пункт по имени в регионе"""
        region = self.get_region_by_id(region_id)
        if not region:
            return None
        
        # Ищем в городах
        for city in region.cities:
            if city.name.lower() == settlement_name.lower():
                return city
        
        # Ищем в городских округах
        for district in region.urban_districts:
            for settlement in district.settlements:
                if settlement.name.lower() == settlement_name.lower():
                    return settlement
        
        return None
    
    def calculate_all_populations(self):
        """Пересчитать все население"""
        for district in self.federal_districts:
            district.calculate_population()

