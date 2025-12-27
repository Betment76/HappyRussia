"""
Сервис для расчета статистики и рейтингов
"""
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from app.database import CheckInDB


def get_period_filter(period: str):
    """Получить фильтр по периоду"""
    now = datetime.utcnow()
    if period == "day":
        return CheckInDB.date >= (now - timedelta(days=1))
    elif period == "week":
        return CheckInDB.date >= (now - timedelta(days=7))
    elif period == "month":
        return CheckInDB.date >= (now - timedelta(days=30))
    else:
        return True  # Все время


def calculate_region_ranking(db: Session, period: str = "day"):
    """Рассчитать рейтинг регионов"""
    period_filter = get_period_filter(period)
    
    # Группируем по региону и считаем статистику
    results = db.query(
        CheckInDB.region_id,
        CheckInDB.region_name,
        func.avg(CheckInDB.mood).label('avg_mood'),
        func.count(CheckInDB.id).label('total_checkins')
    ).filter(period_filter).group_by(
        CheckInDB.region_id,
        CheckInDB.region_name
    ).all()
    
    # TODO: Добавить население из внешнего источника
    # Пока используем 0, нужно будет добавить данные о населении
    rankings = []
    for result in results:
        rankings.append({
            "id": result.region_id,
            "name": result.region_name,
            "averageMood": round(result.avg_mood, 2),
            "totalCheckIns": result.total_checkins,
            "population": 0,  # TODO: Получить из данных регионов
            "lastUpdate": datetime.utcnow().isoformat() + "Z"
        })
    
    # Сортируем по среднему настроению
    rankings.sort(key=lambda x: x["averageMood"], reverse=True)
    return rankings


def calculate_city_ranking(db: Session, region_id: str = None, period: str = "day"):
    """Рассчитать рейтинг городов"""
    period_filter = get_period_filter(period)
    query = db.query(
        CheckInDB.city_id,
        CheckInDB.city_name,
        CheckInDB.region_id,
        func.avg(CheckInDB.mood).label('avg_mood'),
        func.count(CheckInDB.id).label('total_checkins')
    ).filter(
        and_(
            period_filter,
            CheckInDB.city_name.isnot(None),
            CheckInDB.city_name != ""
        )
    )
    
    if region_id:
        query = query.filter(CheckInDB.region_id == region_id)
    
    results = query.group_by(
        CheckInDB.city_id,
        CheckInDB.city_name,
        CheckInDB.region_id
    ).all()
    
    rankings = []
    for result in results:
        # Генерируем ID если его нет
        city_id = result.city_id or f"{result.region_id}_{result.city_name}"
        rankings.append({
            "id": city_id,
            "name": result.city_name,
            "regionId": result.region_id,
            "averageMood": round(result.avg_mood, 2),
            "totalCheckIns": result.total_checkins,
            "population": 0,  # TODO: Получить из данных городов
            "lastUpdate": datetime.utcnow().isoformat() + "Z"
        })
    
    # Сортируем по среднему настроению
    rankings.sort(key=lambda x: x["averageMood"], reverse=True)
    return rankings


def calculate_federal_district_ranking(db: Session, period: str = "day"):
    """Рассчитать рейтинг федеральных округов"""
    period_filter = get_period_filter(period)
    
    results = db.query(
        CheckInDB.federal_district,
        func.avg(CheckInDB.mood).label('avg_mood'),
        func.count(CheckInDB.id).label('total_checkins')
    ).filter(
        and_(
            period_filter,
            CheckInDB.federal_district.isnot(None),
            CheckInDB.federal_district != ""
        )
    ).group_by(CheckInDB.federal_district).all()
    
    rankings = []
    for result in results:
        district_id = str(hash(result.federal_district))
        rankings.append({
            "id": district_id,
            "name": result.federal_district,
            "averageMood": round(result.avg_mood, 2),
            "totalCheckIns": result.total_checkins,
            "population": 0,  # TODO: Получить из данных округов
            "lastUpdate": datetime.utcnow().isoformat() + "Z"
        })
    
    rankings.sort(key=lambda x: x["averageMood"], reverse=True)
    return rankings


def calculate_region_stats(db: Session, region_id: str, period: str = "day"):
    """Рассчитать статистику конкретного региона"""
    period_filter = get_period_filter(period)
    
    result = db.query(
        func.avg(CheckInDB.mood).label('avg_mood'),
        func.count(CheckInDB.id).label('total_checkins')
    ).filter(
        and_(
            period_filter,
            CheckInDB.region_id == region_id
        )
    ).first()
    
    if not result or result.total_checkins == 0:
        return None
    
    # Получаем название региона
    region = db.query(CheckInDB.region_name).filter(
        CheckInDB.region_id == region_id
    ).first()
    
    return {
        "id": region_id,
        "name": region.region_name if region else region_id,
        "averageMood": round(result.avg_mood, 2),
        "totalCheckIns": result.total_checkins,
        "population": 0,  # TODO: Получить из данных регионов
        "lastUpdate": datetime.utcnow().isoformat() + "Z"
    }

