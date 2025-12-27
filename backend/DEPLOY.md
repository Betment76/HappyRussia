# Развертывание на Yandex Cloud

Пошаговая инструкция по развертыванию бекенда HappyRussia на Yandex Cloud.

## Подготовка Yandex Cloud

### 1. Регистрация и создание проекта

1. Зарегистрируйтесь на [Yandex Cloud](https://cloud.yandex.ru/)
2. Создайте новый проект или выберите существующий
3. Убедитесь, что у вас есть доступ к платежному аккаунту

### 2. Установка Yandex Cloud CLI

Установите Yandex Cloud CLI для работы с облаком из командной строки:

**Windows:**
```powershell
# Скачайте установщик с https://cloud.yandex.ru/docs/cli/quickstart
# Или используйте Chocolatey:
choco install yandex-cloud-cli
```

**Linux/macOS:**
```bash
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
```

### 3. Инициализация Yandex Cloud CLI

```bash
yc init
```

Следуйте инструкциям:
- Выберите облако
- Выберите каталог
- Выберите зону доступности (например, `ru-central1-a`)

### 4. Создание сервисного аккаунта

Создайте сервисный аккаунт для работы с Container Registry:

```bash
# Создать сервисный аккаунт
yc iam service-account create --name happyrussia-sa

# Получить ID сервисного аккаунта
SA_ID=$(yc iam service-account get --name happyrussia-sa --format json | jq -r '.id')

# Назначить роли
yc resource-manager folder add-access-binding <FOLDER_ID> \
  --role container-registry.images.pusher \
  --subject serviceAccount:$SA_ID

yc resource-manager folder add-access-binding <FOLDER_ID> \
  --role serverless.containers.deployer \
  --subject serviceAccount:$SA_ID
```

### 5. Создание Container Registry

```bash
# Создать реестр
yc container registry create --name happyrussia-registry

# Получить ID реестра
REGISTRY_ID=$(yc container registry get --name happyrussia-registry --format json | jq -r '.id')
```

## Подготовка Docker образа

### 1. Сборка образа локально

```bash
cd backend
docker build -t happyrussia-api:latest .
```

### 2. Тестирование образа локально

```bash
docker run -p 8000:8000 happyrussia-api:latest
```

Проверьте работу: `http://localhost:8000/api/health`

## Загрузка образа в Container Registry

### 1. Аутентификация в Container Registry

```bash
# Получить OAuth токен
yc config set token <YOUR_TOKEN>

# Аутентифицироваться в Docker
yc container registry configure-docker
```

### 2. Тегирование образа

```bash
# Получить ID реестра
REGISTRY_ID=$(yc container registry get --name happyrussia-registry --format json | jq -r '.id')

# Тегировать образ
docker tag happyrussia-api:latest cr.yandex/$REGISTRY_ID/happyrussia-api:latest
```

### 3. Загрузка образа

```bash
docker push cr.yandex/$REGISTRY_ID/happyrussia-api:latest
```

## Развертывание

### Вариант 1: Serverless Containers (рекомендуется)

Serverless Containers - это управляемый сервис для запуска контейнеров без управления инфраструктурой.

#### 1. Создание контейнера

```bash
# Создать контейнер
yc serverless container create --name happyrussia-api

# Получить ID контейнера
CONTAINER_ID=$(yc serverless container get --name happyrussia-api --format json | jq -r '.id')
```

#### 2. Развертывание образа

```bash
yc serverless container deploy \
  --name happyrussia-api \
  --image cr.yandex/$REGISTRY_ID/happyrussia-api:latest \
  --service-account-id $SA_ID \
  --memory 512MB \
  --cores 1 \
  --execution-timeout 30s \
  --concurrency 10 \
  --environment DATABASE_URL=sqlite:///./data/happy_russia.db
```

#### 3. Публикация версии

```bash
yc serverless container revision deploy \
  --container-name happyrussia-api \
  --image cr.yandex/$REGISTRY_ID/happyrussia-api:latest \
  --memory 512MB \
  --cores 1
```

#### 4. Получение URL

```bash
yc serverless container get --name happyrussia-api
```

URL будет в формате: `https://<container-id>.containers.yandexcloud.net`

### Вариант 2: Compute Cloud (VM с Docker)

Если нужен полный контроль над инфраструктурой:

#### 1. Создание виртуальной машины

```bash
yc compute instance create \
  --name happyrussia-vm \
  --zone ru-central1-a \
  --network-interface subnet-name=default,nat-ip-version=ipv4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=20 \
  --ssh-key ~/.ssh/id_rsa.pub
```

#### 2. Подключение к VM

```bash
# Получить внешний IP
VM_IP=$(yc compute instance get --name happyrussia-vm --format json | jq -r '.network_interfaces[0].primary_v4_address.one_to_one_nat.address')

# Подключиться
ssh ubuntu@$VM_IP
```

#### 3. Установка Docker на VM

```bash
# На VM выполнить:
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu
```

#### 4. Запуск контейнера на VM

```bash
# Аутентификация в Container Registry
yc container registry configure-docker

# Запуск контейнера
docker run -d \
  --name happyrussia-api \
  -p 80:8000 \
  --restart unless-stopped \
  -v /opt/happyrussia/data:/app/data \
  cr.yandex/$REGISTRY_ID/happyrussia-api:latest
```

## Настройка базы данных

### Вариант 1: SQLite (для начала)

SQLite уже настроен и будет работать в контейнере. Данные сохраняются в volume `/app/data`.

### Вариант 2: PostgreSQL (для продакшена)

#### 1. Создание Managed PostgreSQL

```bash
yc managed-postgresql cluster create \
  --name happyrussia-db \
  --network-name default \
  --host zone-id=ru-central1-a,subnet-name=default \
  --resource-preset s2.micro \
  --disk-size 10 \
  --user name=app,password=<STRONG_PASSWORD> \
  --database name=happyrussia
```

#### 2. Обновление database.py

Измените `SQLALCHEMY_DATABASE_URL` в `app/database.py`:

```python
import os
SQLALCHEMY_DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://app:<PASSWORD>@<HOST>:6432/happyrussia"
)
```

#### 3. Обновление requirements.txt

Добавьте:
```
psycopg2-binary>=2.9.0
```

## Настройка домена и SSL

### 1. Создание Application Load Balancer

```bash
yc application-load-balancer load-balancer create \
  --name happyrussia-lb \
  --listener name=listener1,external-ipv4-endpoint=port=80
```

### 2. Настройка группы бэкендов

```bash
yc application-load-balancer backend-group create \
  --name happyrussia-backend-group \
  --target name=container,container-id=$CONTAINER_ID
```

## Обновление Flutter приложения

После развертывания обновите `baseUrl` в `lib/services/api_service.dart`:

```dart
static String get baseUrl {
  // Для продакшена
  return 'https://<your-container-url>/api';
}
```

## Мониторинг и логи

### Просмотр логов

```bash
# Serverless Containers
yc serverless container logs --name happyrussia-api

# Compute Cloud
docker logs happyrussia-api
```

### Мониторинг метрик

Используйте Yandex Cloud Monitoring для отслеживания:
- Количество запросов
- Время ответа
- Ошибки
- Использование ресурсов

## Автоматизация развертывания

Создайте скрипт `deploy.sh`:

```bash
#!/bin/bash
set -e

REGISTRY_ID=$(yc container registry get --name happyrussia-registry --format json | jq -r '.id')

# Сборка
docker build -t happyrussia-api:latest .

# Тегирование
docker tag happyrussia-api:latest cr.yandex/$REGISTRY_ID/happyrussia-api:latest

# Загрузка
docker push cr.yandex/$REGISTRY_ID/happyrussia-api:latest

# Развертывание
yc serverless container revision deploy \
  --container-name happyrussia-api \
  --image cr.yandex/$REGISTRY_ID/happyrussia-api:latest \
  --memory 512MB \
  --cores 1
```

## Стоимость

Примерная стоимость на Yandex Cloud:
- Serverless Containers: ~500-1000₽/месяц (зависит от нагрузки)
- Compute Cloud VM: ~1000-2000₽/месяц
- Container Registry: бесплатно до 10GB
- Managed PostgreSQL: ~2000-3000₽/месяц (опционально)

## Полезные ссылки

- [Документация Yandex Cloud](https://cloud.yandex.ru/docs/)
- [Serverless Containers](https://cloud.yandex.ru/docs/serverless-containers/)
- [Container Registry](https://cloud.yandex.ru/docs/container-registry/)
- [Compute Cloud](https://cloud.yandex.ru/docs/compute/)

