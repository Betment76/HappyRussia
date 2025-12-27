"""
Роутер для работы с чек-инами
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.schemas import CheckInCreate, CheckInResponse
from app.database import CheckInDB
from datetime import datetime

router = APIRouter(prefix="/checkins", tags=["checkins"])


@router.post("", response_model=CheckInResponse, status_code=201)
async def create_checkin(
    checkin: CheckInCreate,
    db: Session = Depends(get_db)
):
    """
    Создать новый чек-ин
    """
    # Проверяем, не существует ли уже чек-ин с таким ID
    existing = db.query(CheckInDB).filter(CheckInDB.id == checkin.id).first()
    if existing:
        # Если существует, обновляем его
        existing.region_id = checkin.region_id
        existing.region_name = checkin.region_name
        existing.mood = checkin.mood
        existing.date = checkin.date
        existing.user_id = checkin.user_id
        existing.city_id = checkin.city_id
        existing.city_name = checkin.city_name
        existing.federal_district = checkin.federal_district
        existing.district = checkin.district
        db.commit()
        db.refresh(existing)
        return CheckInResponse(
            id=existing.id,
            regionId=existing.region_id,
            regionName=existing.region_name,
            mood=existing.mood,
            date=existing.date,
            userId=existing.user_id,
            cityId=existing.city_id,
            cityName=existing.city_name,
            federalDistrict=existing.federal_district,
            district=existing.district
        )
    
    # Создаем новый чек-ин
    db_checkin = CheckInDB(
        id=checkin.id,
        region_id=checkin.region_id,
        region_name=checkin.region_name,
        mood=checkin.mood,
        date=checkin.date,
        user_id=checkin.user_id,
        city_id=checkin.city_id,
        city_name=checkin.city_name,
        federal_district=checkin.federal_district,
        district=checkin.district
    )
    
    db.add(db_checkin)
    db.commit()
    db.refresh(db_checkin)
    
    return CheckInResponse(
        id=db_checkin.id,
        regionId=db_checkin.region_id,
        regionName=db_checkin.region_name,
        mood=db_checkin.mood,
        date=db_checkin.date,
        userId=db_checkin.user_id,
        cityId=db_checkin.city_id,
        cityName=db_checkin.city_name,
        federalDistrict=db_checkin.federal_district,
        district=db_checkin.district
    )


@router.post("/sync", status_code=200)
async def sync_checkins(
    checkins: List[CheckInCreate],
    db: Session = Depends(get_db)
):
    """
    Синхронизировать несколько чек-инов
    """
    synced_count = 0
    for checkin in checkins:
        existing = db.query(CheckInDB).filter(CheckInDB.id == checkin.id).first()
        if existing:
            # Обновляем существующий
            existing.region_id = checkin.region_id
            existing.region_name = checkin.region_name
            existing.mood = checkin.mood
            existing.date = checkin.date
            existing.user_id = checkin.user_id
            existing.city_id = checkin.city_id
            existing.city_name = checkin.city_name
            existing.federal_district = checkin.federal_district
            existing.district = checkin.district
        else:
            # Создаем новый
            db_checkin = CheckInDB(
                id=checkin.id,
                region_id=checkin.region_id,
                region_name=checkin.region_name,
                mood=checkin.mood,
                date=checkin.date,
                user_id=checkin.user_id,
                city_id=checkin.city_id,
                city_name=checkin.city_name,
                federal_district=checkin.federal_district,
                district=checkin.district
            )
            db.add(db_checkin)
        synced_count += 1
    
    db.commit()
    return {"message": f"Синхронизировано {synced_count} чек-инов", "count": synced_count}

