"""
Настройка базы данных
Поддерживает SQLite (для разработки) и PostgreSQL (для продакшена)
"""
import os
from sqlalchemy import create_engine, Column, String, Integer, Float, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime, timezone

# База данных - используем переменную окружения или SQLite по умолчанию
# Для продакшена используйте PostgreSQL:
# DATABASE_URL=postgresql://user:password@host:6432/dbname
# Для Yandex Cloud Managed PostgreSQL обычно используется порт 6432
SQLALCHEMY_DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "sqlite:///./data/happy_russia.db"  # Используем папку data для персистентности
)

# Настройка engine в зависимости от типа БД
if SQLALCHEMY_DATABASE_URL.startswith("sqlite"):
    # Для SQLite нужны специальные параметры
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL, 
        connect_args={"check_same_thread": False}
    )
else:
    # Для PostgreSQL и других БД
    # Используем pool_pre_ping для проверки соединения перед использованием
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL,
        pool_pre_ping=True,  # Проверка соединения перед использованием
        pool_size=5,  # Размер пула соединений
        max_overflow=10  # Максимальное количество дополнительных соединений
    )

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


class CheckInDB(Base):
    """Модель чек-ина в базе данных"""
    __tablename__ = "checkins"

    id = Column(String, primary_key=True, index=True)
    region_id = Column(String, index=True, nullable=False)
    region_name = Column(String, nullable=False)
    mood = Column(Integer, nullable=False)  # 1-5
    date = Column(DateTime, nullable=False, index=True)
    user_id = Column(String, nullable=True, index=True)
    city_id = Column(String, index=True, nullable=True)
    city_name = Column(String, nullable=True)
    federal_district = Column(String, nullable=True)
    district = Column(String, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class UserDB(Base):
    """Модель пользователя в базе данных"""
    __tablename__ = "users"

    user_id = Column(String, primary_key=True)  # Номер телефона
    name = Column(String, nullable=False)
    registration_city_id = Column(String, nullable=True)
    registration_city_name = Column(String, nullable=True)
    registration_region_id = Column(String, nullable=True)
    registration_region_name = Column(String, nullable=True)
    registration_federal_district = Column(String, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


# Создать таблицы
def init_db():
    """Инициализировать базу данных"""
    # Создаем директорию для SQLite если нужно
    if SQLALCHEMY_DATABASE_URL.startswith("sqlite"):
        db_path = SQLALCHEMY_DATABASE_URL.replace("sqlite:///", "")
        if "/" in db_path or "\\" in db_path:
            os.makedirs(os.path.dirname(db_path), exist_ok=True)
    
    Base.metadata.create_all(bind=engine)


# Dependency для получения сессии БД
def get_db():
    """Получить сессию базы данных"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

