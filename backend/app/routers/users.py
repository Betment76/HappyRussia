"""
Роутер для работы с пользователями
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db, UserDB
from app.models.schemas import UserCreate, UserResponse
from datetime import datetime, timezone

router = APIRouter(prefix="/users", tags=["users"])


@router.post("", response_model=UserResponse, status_code=201)
async def create_user(
    user: UserCreate,
    db: Session = Depends(get_db)
):
    """
    Создать или обновить пользователя (регистрация)
    """
    # Проверяем, существует ли уже пользователь с таким user_id
    existing = db.query(UserDB).filter(UserDB.user_id == user.user_id).first()
    
    if existing:
        # Обновляем существующего пользователя
        existing.name = user.name
        existing.registration_city_id = user.registration_city_id
        existing.registration_city_name = user.registration_city_name
        existing.registration_region_id = user.registration_region_id
        existing.registration_region_name = user.registration_region_name
        existing.registration_federal_district = user.registration_federal_district
        db.commit()
        db.refresh(existing)
        return UserResponse(
            user_id=existing.user_id,
            name=existing.name,
            registration_city_id=existing.registration_city_id,
            registration_city_name=existing.registration_city_name,
            registration_region_id=existing.registration_region_id,
            registration_region_name=existing.registration_region_name,
            registration_federal_district=existing.registration_federal_district,
            created_at=existing.created_at
        )
    
    # Создаем нового пользователя
    db_user = UserDB(
        user_id=user.user_id,
        name=user.name,
        registration_city_id=user.registration_city_id,
        registration_city_name=user.registration_city_name,
        registration_region_id=user.registration_region_id,
        registration_region_name=user.registration_region_name,
        registration_federal_district=user.registration_federal_district,
        created_at=datetime.now(timezone.utc)
    )
    
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    return UserResponse(
        user_id=db_user.user_id,
        name=db_user.name,
        registration_city_id=db_user.registration_city_id,
        registration_city_name=db_user.registration_city_name,
        registration_region_id=db_user.registration_region_id,
        registration_region_name=db_user.registration_region_name,
        registration_federal_district=db_user.registration_federal_district,
        created_at=db_user.created_at
    )


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: str,
    db: Session = Depends(get_db)
):
    """
    Получить информацию о пользователе по user_id
    """
    user = db.query(UserDB).filter(UserDB.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")
    
    return UserResponse(
        user_id=user.user_id,
        name=user.name,
        registration_city_id=user.registration_city_id,
        registration_city_name=user.registration_city_name,
        registration_region_id=user.registration_region_id,
        registration_region_name=user.registration_region_name,
        registration_federal_district=user.registration_federal_district,
        created_at=user.created_at
    )

