"""
Главный файл FastAPI приложения
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import init_db
from app.routers import checkins, rankings, users


# Инициализация базы данных при старте
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    init_db()
    yield
    # Shutdown (если нужно)


# Создаем приложение
app = FastAPI(
    title="HappyRussia API",
    description="API для приложения Моё Настроение",
    version="1.0.0",
    lifespan=lifespan
)

# Настройка CORS для Flutter приложения
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # В продакшене указать конкретные домены
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Подключаем роутеры
app.include_router(checkins.router, prefix="/api")
app.include_router(rankings.router, prefix="/api")
app.include_router(rankings.cities_router, prefix="/api")
app.include_router(users.router, prefix="/api")


@app.get("/")
async def root():
    """Корневой endpoint"""
    return {
        "message": "HappyRussia API",
        "version": "1.0.0",
        "docs": "/docs"
    }


@app.get("/api/health")
async def health_check():
    """Проверка здоровья API"""
    return {"status": "ok"}

