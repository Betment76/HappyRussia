# Используем официальный образ Python
FROM python:3.11-slim

# Устанавливаем рабочую директорию
WORKDIR /app

# Устанавливаем системные зависимости (для сборки некоторых пакетов)
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Копируем файл зависимостей
COPY requirements.txt .

# Устанавливаем Python зависимости
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Копируем весь код приложения
COPY . .

# Создаем директорию для базы данных
RUN mkdir -p /app/data && chmod 777 /app/data

# Открываем порт (Serverless Containers ожидают порт 8080)
EXPOSE 8080

# Переменные окружения
ENV DATABASE_URL=sqlite:///./data/happy_russia.db
ENV PYTHONUNBUFFERED=1
ENV PORT=8080

# Запускаем приложение (используем переменную окружения PORT для совместимости)
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8080}"]

