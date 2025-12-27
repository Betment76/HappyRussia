# HappyRussia Backend API

Backend API для приложения "Моё Настроение" на FastAPI.

## Технологии

- **FastAPI** - современный веб-фреймворк для Python
- **SQLAlchemy** - ORM для работы с базой данных
- **SQLite** - база данных (можно заменить на PostgreSQL)
- **Pydantic** - валидация данных

## Установка

1. Установите Python 3.8+ если еще не установлен

2. Установите зависимости:
```bash
pip install -r requirements.txt
```

## Запуск

### Локальный запуск

```bash
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API будет доступен по адресу: `http://localhost:8000`

### Документация API

После запуска доступна автоматическая документация:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## API Endpoints

### Чек-ины

- `POST /api/checkins` - Создать чек-ин
- `POST /api/checkins/sync` - Синхронизировать несколько чек-инов

### Рейтинги

- `GET /api/regions/ranking?period=day` - Рейтинг регионов
- `GET /api/regions/{region_id}/stats?period=day` - Статистика региона
- `GET /api/regions/{region_id}/cities/ranking?period=day` - Рейтинг городов региона
- `GET /api/cities/ranking?period=day` - Рейтинг всех городов
- `GET /api/regions/federal-districts/ranking?period=day` - Рейтинг федеральных округов

### Параметры

- `period` - период для статистики: `day`, `week`, `month`

## База данных

База данных SQLite создается автоматически в файле `happy_russia.db` при первом запуске.

### Миграция на PostgreSQL

Для продакшена рекомендуется использовать PostgreSQL. Для этого:

1. Измените `SQLALCHEMY_DATABASE_URL` в `app/database.py`:
```python
SQLALCHEMY_DATABASE_URL = "postgresql://user:password@localhost/happyrussia"
```

2. Установите драйвер PostgreSQL:
```bash
pip install psycopg2-binary
```

## Настройка для Flutter приложения

В `lib/services/api_service.dart` измените `baseUrl`:

```dart
static const String baseUrl = 'http://localhost:8000/api';
```

Для Android эмулятора используйте `10.0.2.2` вместо `localhost`:
```dart
static const String baseUrl = 'http://10.0.2.2:8000/api';
```

## TODO

- [ ] Добавить данные о населении регионов и городов
- [ ] Реализовать рейтинг районов
- [ ] Добавить аутентификацию пользователей
- [ ] Добавить кэширование для рейтингов
- [ ] Настроить логирование
- [ ] Добавить тесты

## Развертывание

### Yandex Cloud

Для развертывания на Yandex Cloud можно использовать:
- Yandex Cloud Functions
- Yandex Cloud Run
- Yandex Compute Cloud с Docker

### Docker

Создайте `Dockerfile`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

