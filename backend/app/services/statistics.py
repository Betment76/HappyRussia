"""
Сервис для расчета статистики и рейтингов
"""
from datetime import datetime, timedelta, timezone
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from app.database import CheckInDB
from app.data.region_population import get_region_population, get_city_population, get_federal_district_population


def get_period_filter(period: str):
    """Получить фильтр по периоду"""
    now = datetime.now(timezone.utc)
    if period == "day":
        return CheckInDB.date >= (now - timedelta(days=1))
    elif period == "week":
        return CheckInDB.date >= (now - timedelta(days=7))
    elif period == "month":
        return CheckInDB.date >= (now - timedelta(days=30))
    else:
        return True  # Все время


def calculate_region_ranking(db: Session, period: str = "day"):
    """Рассчитать рейтинг регионов
    
    Логика:
    - Один пользователь может голосовать много раз за день
    - В статистике считается как ОДИН проголосовавший
    - Берется последний чек-ин каждого пользователя за период
    """
    period_filter = get_period_filter(period)
    
    # Получаем все чек-ины за период с userId (обязательное поле)
    all_checkins = db.query(CheckInDB).filter(
        and_(
            period_filter,
            CheckInDB.user_id.isnot(None),
            CheckInDB.user_id != ""
        )
    ).all()
    
    # Группируем по региону и пользователю, берем последний чек-ин каждого пользователя
    region_user_last = {}  # {(region_id, user_id): (mood, date)}
    
    for checkin in all_checkins:
        key = (checkin.region_id, checkin.user_id)
        if key not in region_user_last:
            region_user_last[key] = (checkin.mood, checkin.date)
        else:
            # Берем последний чек-ин (по дате)
            if checkin.date > region_user_last[key][1]:
                region_user_last[key] = (checkin.mood, checkin.date)
    
    # Группируем по региону и считаем статистику
    region_stats = {}  # {region_id: {'name': str, 'moods': [int], 'users': set}}
    
    for (region_id, user_id), (mood, date) in region_user_last.items():
        if region_id not in region_stats:
            region_stats[region_id] = {
                'name': None,
                'moods': [],
                'users': set()
            }
        region_stats[region_id]['moods'].append(mood)
        region_stats[region_id]['users'].add(user_id)
        # Сохраняем название региона из первого чек-ина
        if region_stats[region_id]['name'] is None:
            checkin = db.query(CheckInDB).filter(
                CheckInDB.region_id == region_id
            ).first()
            if checkin:
                region_stats[region_id]['name'] = checkin.region_name
    
    # Формируем результат
    rankings = []
    for region_id, stats in region_stats.items():
        if stats['name'] is None:
            continue
        total_users = len(stats['users'])  # Количество уникальных пользователей
        avg_mood = sum(stats['moods']) / len(stats['moods']) if stats['moods'] else 0
        
        # Получаем население региона
        population = get_region_population(region_id)
        rankings.append({
            "id": region_id,
            "name": stats['name'],
            "averageMood": round(avg_mood, 2),
            "totalCheckIns": total_users,  # Количество уникальных пользователей
            "population": population,
            "lastUpdate": datetime.now(timezone.utc).isoformat()
        })
    
    # Сортируем по среднему настроению
    rankings.sort(key=lambda x: x["averageMood"], reverse=True)
    return rankings


def calculate_city_ranking(db: Session, region_id: str = None, period: str = "day"):
    """Рассчитать рейтинг городов
    
    Логика:
    - Один пользователь может голосовать много раз за день
    - В статистике считается как ОДИН проголосовавший
    - Берется последний чек-ин каждого пользователя за период
    """
    period_filter = get_period_filter(period)
    
    # Получаем все чек-ины за период с userId (обязательное поле) и cityName
    query = db.query(CheckInDB).filter(
        and_(
            period_filter,
            CheckInDB.user_id.isnot(None),
            CheckInDB.user_id != "",
            CheckInDB.city_name.isnot(None),
            CheckInDB.city_name != ""
        )
    )
    
    if region_id:
        query = query.filter(CheckInDB.region_id == region_id)
    
    all_checkins = query.all()
    
    # Группируем по городу и пользователю, берем последний чек-ин каждого пользователя
    city_user_last = {}  # {(city_id, city_name, region_id, user_id): (mood, date)}
    
    for checkin in all_checkins:
        city_id_key = checkin.city_id or f"{checkin.region_id}_{checkin.city_name}"
        key = (city_id_key, checkin.city_name, checkin.region_id, checkin.user_id)
        if key not in city_user_last:
            city_user_last[key] = (checkin.mood, checkin.date)
        else:
            # Берем последний чек-ин (по дате)
            if checkin.date > city_user_last[key][1]:
                city_user_last[key] = (checkin.mood, checkin.date)
    
    # Группируем по городу и считаем статистику
    city_stats = {}  # {city_id: {'name': str, 'region_id': str, 'moods': [int], 'users': set}}
    
    for (city_id, city_name, region_id, user_id), (mood, date) in city_user_last.items():
        if city_id not in city_stats:
            city_stats[city_id] = {
                'name': city_name,
                'region_id': region_id,
                'moods': [],
                'users': set()
            }
        city_stats[city_id]['moods'].append(mood)
        city_stats[city_id]['users'].add(user_id)
    
    # Формируем результат
    rankings = []
    for city_id, stats in city_stats.items():
        total_users = len(stats['users'])  # Количество уникальных пользователей
        avg_mood = sum(stats['moods']) / len(stats['moods']) if stats['moods'] else 0
        
        # Получаем население города из базы данных
        population = get_city_population(stats['region_id'], stats['name'])
        rankings.append({
            "id": city_id,
            "name": stats['name'],
            "regionId": stats['region_id'],
            "averageMood": round(avg_mood, 2),
            "totalCheckIns": total_users,  # Количество уникальных пользователей
            "population": population,
            "lastUpdate": datetime.now(timezone.utc).isoformat()
        })
    
    # Сортируем по среднему настроению
    rankings.sort(key=lambda x: x["averageMood"], reverse=True)
    return rankings


def calculate_federal_district_ranking(db: Session, period: str = "day"):
    """Рассчитать рейтинг федеральных округов
    
    Логика:
    - Один пользователь может голосовать много раз за день
    - В статистике считается как ОДИН проголосовавший
    - Берется последний чек-ин каждого пользователя за период
    """
    period_filter = get_period_filter(period)
    
    # Получаем все чек-ины за период с userId (обязательное поле) и federalDistrict
    all_checkins = db.query(CheckInDB).filter(
        and_(
            period_filter,
            CheckInDB.user_id.isnot(None),
            CheckInDB.user_id != "",
            CheckInDB.federal_district.isnot(None),
            CheckInDB.federal_district != ""
        )
    ).all()
    
    # Группируем по округу и пользователю, берем последний чек-ин каждого пользователя
    district_user_last = {}  # {(federal_district, user_id): (mood, date)}
    
    for checkin in all_checkins:
        key = (checkin.federal_district, checkin.user_id)
        if key not in district_user_last:
            district_user_last[key] = (checkin.mood, checkin.date)
        else:
            # Берем последний чек-ин (по дате)
            if checkin.date > district_user_last[key][1]:
                district_user_last[key] = (checkin.mood, checkin.date)
    
    # Группируем по округу и считаем статистику
    district_stats = {}  # {federal_district: {'moods': [int], 'users': set}}
    
    for (federal_district, user_id), (mood, date) in district_user_last.items():
        if federal_district not in district_stats:
            district_stats[federal_district] = {
                'moods': [],
                'users': set()
            }
        district_stats[federal_district]['moods'].append(mood)
        district_stats[federal_district]['users'].add(user_id)
    
    # Формируем результат
    rankings = []
    for federal_district, stats in district_stats.items():
        total_users = len(stats['users'])  # Количество уникальных пользователей
        avg_mood = sum(stats['moods']) / len(stats['moods']) if stats['moods'] else 0
        
        district_id = str(hash(federal_district))
        # Получаем население федерального округа из базы данных
        population = get_federal_district_population(federal_district)
        rankings.append({
            "id": district_id,
            "name": federal_district,
            "averageMood": round(avg_mood, 2),
            "totalCheckIns": total_users,  # Количество уникальных пользователей
            "population": population,
            "lastUpdate": datetime.now(timezone.utc).isoformat()
        })
    
    rankings.sort(key=lambda x: x["averageMood"], reverse=True)
    return rankings


def calculate_region_stats(db: Session, region_id: str, period: str = "day"):
    """Рассчитать статистику конкретного региона
    
    Логика:
    - Один пользователь может голосовать много раз за день
    - В статистике считается как ОДИН проголосовавший
    - Берется последний чек-ин каждого пользователя за период
    """
    period_filter = get_period_filter(period)
    
    # Получаем все чек-ины за период с userId (обязательное поле) для данного региона
    all_checkins = db.query(CheckInDB).filter(
        and_(
            period_filter,
            CheckInDB.region_id == region_id,
            CheckInDB.user_id.isnot(None),
            CheckInDB.user_id != ""
        )
    ).all()
    
    if not all_checkins:
        return None
    
    # Группируем по пользователю, берем последний чек-ин каждого пользователя
    user_last = {}  # {user_id: (mood, date)}
    
    for checkin in all_checkins:
        user_id = checkin.user_id
        if user_id not in user_last:
            user_last[user_id] = (checkin.mood, checkin.date)
        else:
            # Берем последний чек-ин (по дате)
            if checkin.date > user_last[user_id][1]:
                user_last[user_id] = (checkin.mood, checkin.date)
    
    # Считаем статистику
    total_users = len(user_last)  # Количество уникальных пользователей
    moods = [mood for mood, date in user_last.values()]
    avg_mood = sum(moods) / len(moods) if moods else 0
    
    # Получаем название региона
    region = db.query(CheckInDB.region_name).filter(
        CheckInDB.region_id == region_id
    ).first()
    
    # Получаем население региона
    population = get_region_population(region_id)
    return {
        "id": region_id,
        "name": region.region_name if region else region_id,
        "averageMood": round(avg_mood, 2),
        "totalCheckIns": total_users,  # Количество уникальных пользователей
        "population": population,
        "lastUpdate": datetime.now(timezone.utc).isoformat()
    }

