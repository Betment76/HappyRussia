"""
Pydantic схемы для API запросов и ответов
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class CheckInCreate(BaseModel):
    """Схема для создания чек-ина"""
    id: str
    region_id: str = Field(..., alias="regionId")
    region_name: str = Field(..., alias="regionName")
    mood: int = Field(..., ge=1, le=5)  # 1-5
    date: datetime
    user_id: Optional[str] = Field(None, alias="userId")
    city_id: Optional[str] = Field(None, alias="cityId")
    city_name: Optional[str] = Field(None, alias="cityName")
    federal_district: Optional[str] = Field(None, alias="federalDistrict")
    district: Optional[str] = None

    class Config:
        populate_by_name = True


class CheckInResponse(BaseModel):
    """Схема ответа для чек-ина"""
    id: str
    region_id: str = Field(..., alias="regionId")
    region_name: str = Field(..., alias="regionName")
    mood: int
    date: datetime
    user_id: Optional[str] = Field(None, alias="userId")
    city_id: Optional[str] = Field(None, alias="cityId")
    city_name: Optional[str] = Field(None, alias="cityName")
    federal_district: Optional[str] = Field(None, alias="federalDistrict")
    district: Optional[str] = None

    class Config:
        populate_by_name = True


class RegionMoodResponse(BaseModel):
    """Схема ответа для рейтинга региона"""
    id: str
    name: str
    average_mood: float = Field(..., alias="averageMood")
    total_check_ins: int = Field(..., alias="totalCheckIns")
    population: int
    last_update: datetime = Field(..., alias="lastUpdate")

    class Config:
        populate_by_name = True


class CityMoodResponse(BaseModel):
    """Схема ответа для рейтинга города"""
    id: str
    name: str
    region_id: str = Field(..., alias="regionId")
    average_mood: float = Field(..., alias="averageMood")
    total_check_ins: int = Field(..., alias="totalCheckIns")
    population: int
    last_update: datetime = Field(..., alias="lastUpdate")

    class Config:
        populate_by_name = True


class DistrictMoodResponse(BaseModel):
    """Схема ответа для рейтинга района"""
    id: str
    name: str
    city_id: str = Field(..., alias="cityId")
    average_mood: float = Field(..., alias="averageMood")
    total_check_ins: int = Field(..., alias="totalCheckIns")
    population: int
    last_update: datetime = Field(..., alias="lastUpdate")

    class Config:
        populate_by_name = True


class FederalDistrictMoodResponse(BaseModel):
    """Схема ответа для рейтинга федерального округа"""
    id: str
    name: str
    average_mood: float = Field(..., alias="averageMood")
    total_check_ins: int = Field(..., alias="totalCheckIns")
    population: int
    last_update: datetime = Field(..., alias="lastUpdate")

    class Config:
        populate_by_name = True

