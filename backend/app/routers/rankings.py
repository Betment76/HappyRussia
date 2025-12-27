"""
Роутер для получения рейтингов
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.schemas import (
    RegionMoodResponse,
    CityMoodResponse,
    FederalDistrictMoodResponse
)
from app.services.statistics import (
    calculate_region_ranking,
    calculate_city_ranking,
    calculate_federal_district_ranking,
    calculate_region_stats
)

router = APIRouter(prefix="/regions", tags=["rankings"])


@router.get("/ranking", response_model=List[RegionMoodResponse])
async def get_regions_ranking(
    period: str = Query("day", pattern="^(day|week|month)$"),
    db: Session = Depends(get_db)
):
    """
    Получить рейтинг всех регионов
    """
    rankings = calculate_region_ranking(db, period)
    return rankings


@router.get("/{region_id}/stats", response_model=RegionMoodResponse)
async def get_region_stats(
    region_id: str,
    period: str = Query("day", pattern="^(day|week|month)$"),
    db: Session = Depends(get_db)
):
    """
    Получить статистику конкретного региона
    """
    stats = calculate_region_stats(db, region_id, period)
    if not stats:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Регион не найден или нет данных")
    return stats


@router.get("/{region_id}/cities/ranking", response_model=List[CityMoodResponse])
async def get_cities_ranking(
    region_id: str,
    period: str = Query("day", pattern="^(day|week|month)$"),
    db: Session = Depends(get_db)
):
    """
    Получить рейтинг городов в регионе
    """
    rankings = calculate_city_ranking(db, region_id, period)
    return rankings


@router.get("/federal-districts/ranking", response_model=List[FederalDistrictMoodResponse])
async def get_federal_districts_ranking(
    period: str = Query("day", pattern="^(day|week|month)$"),
    db: Session = Depends(get_db)
):
    """
    Получить рейтинг федеральных округов
    """
    rankings = calculate_federal_district_ranking(db, period)
    return rankings


# Роутер для всех городов
cities_router = APIRouter(prefix="/cities", tags=["rankings"])


@cities_router.get("/ranking", response_model=List[CityMoodResponse])
async def get_all_cities_ranking(
    period: str = Query("day", pattern="^(day|week|month)$"),
    db: Session = Depends(get_db)
):
    """
    Получить рейтинг всех городов России
    """
    rankings = calculate_city_ranking(db, None, period)
    return rankings


# Роутер для районов (используем тот же cities_router)
@cities_router.get("/{city_id}/districts/ranking")
async def get_districts_ranking(
    city_id: str,
    period: str = Query("day", pattern="^(day|week|month)$"),
    db: Session = Depends(get_db)
):
    """
    Получить рейтинг районов города
    TODO: Реализовать когда будет достаточно данных
    """
    # Пока возвращаем пустой список
    # В будущем можно группировать по district для конкретного city_id
    return []

