#!/bin/bash
# Скрипт для автоматического развертывания на Yandex Cloud

set -e

echo "🚀 Начало развертывания HappyRussia API на Yandex Cloud"

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Проверка наличия необходимых инструментов
check_dependencies() {
    echo -e "${YELLOW}Проверка зависимостей...${NC}"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker не установлен${NC}"
        exit 1
    fi
    
    if ! command -v yc &> /dev/null; then
        echo -e "${RED}❌ Yandex Cloud CLI не установлен${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Все зависимости установлены${NC}"
}

# Получение ID реестра
get_registry_id() {
    echo -e "${YELLOW}Получение ID Container Registry...${NC}"
    REGISTRY_ID=$(yc container registry get --name happyrussia-registry --format json 2>/dev/null | jq -r '.id' || echo "")
    
    if [ -z "$REGISTRY_ID" ]; then
        echo -e "${RED}❌ Container Registry 'happyrussia-registry' не найден${NC}"
        echo "Создайте реестр командой: yc container registry create --name happyrussia-registry"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Registry ID: $REGISTRY_ID${NC}"
}

# Сборка Docker образа
build_image() {
    echo -e "${YELLOW}Сборка Docker образа...${NC}"
    docker build -t happyrussia-api:latest .
    echo -e "${GREEN}✅ Образ собран${NC}"
}

# Тегирование образа
tag_image() {
    echo -e "${YELLOW}Тегирование образа...${NC}"
    docker tag happyrussia-api:latest cr.yandex/$REGISTRY_ID/happyrussia-api:latest
    echo -e "${GREEN}✅ Образ помечен${NC}"
}

# Загрузка образа в реестр
push_image() {
    echo -e "${YELLOW}Загрузка образа в Container Registry...${NC}"
    docker push cr.yandex/$REGISTRY_ID/happyrussia-api:latest
    echo -e "${GREEN}✅ Образ загружен${NC}"
}

# Развертывание контейнера
deploy_container() {
    echo -e "${YELLOW}Развертывание контейнера...${NC}"
    
    # Проверка существования контейнера
    CONTAINER_EXISTS=$(yc serverless container get --name happyrussia-api 2>/dev/null || echo "")
    
    if [ -z "$CONTAINER_EXISTS" ]; then
        echo "Создание нового контейнера..."
        yc serverless container create --name happyrussia-api
    fi
    
    # Развертывание новой ревизии
    yc serverless container revision deploy \
        --container-name happyrussia-api \
        --image cr.yandex/$REGISTRY_ID/happyrussia-api:latest \
        --memory 512MB \
        --cores 1 \
        --execution-timeout 30s \
        --concurrency 10
    
    echo -e "${GREEN}✅ Контейнер развернут${NC}"
}

# Получение URL контейнера
get_url() {
    echo -e "${YELLOW}Получение URL контейнера...${NC}"
    URL=$(yc serverless container get --name happyrussia-api --format json | jq -r '.url' || echo "")
    
    if [ ! -z "$URL" ]; then
        echo -e "${GREEN}✅ API доступен по адресу: $URL${NC}"
        echo -e "${GREEN}   Health check: $URL/api/health${NC}"
    fi
}

# Основная функция
main() {
    check_dependencies
    get_registry_id
    build_image
    tag_image
    push_image
    deploy_container
    get_url
    
    echo -e "${GREEN}🎉 Развертывание завершено успешно!${NC}"
}

# Запуск
main

