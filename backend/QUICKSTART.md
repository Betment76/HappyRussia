# Быстрый старт развертывания

Краткая инструкция по развертыванию на Yandex Cloud.

## Подготовка (один раз)

1. **Установите Yandex Cloud CLI:**
   ```bash
   # Windows (Chocolatey)
   choco install yandex-cloud-cli
   
   # Linux/macOS
   curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
   ```

2. **Инициализируйте CLI:**
   ```bash
   yc init
   ```

3. **Следуйте инструкциям в [SETUP_YANDEX_CLOUD.md](SETUP_YANDEX_CLOUD.md)**

## Развертывание

### Вариант 1: Автоматический (рекомендуется)

```bash
# Linux/macOS
chmod +x deploy.sh
./deploy.sh

# Windows (PowerShell)
# Используйте команды из deploy.sh вручную
```

### Вариант 2: Ручной

```bash
# 1. Получить ID реестра
REGISTRY_ID=$(yc container registry get --name happyrussia-registry --format json | jq -r '.id')

# 2. Собрать образ
docker build -t happyrussia-api:latest .

# 3. Тегировать
docker tag happyrussia-api:latest cr.yandex/$REGISTRY_ID/happyrussia-api:latest

# 4. Загрузить
docker push cr.yandex/$REGISTRY_ID/happyrussia-api:latest

# 5. Развернуть
yc serverless container revision deploy \
  --container-name happyrussia-api \
  --image cr.yandex/$REGISTRY_ID/happyrussia-api:latest \
  --memory 512MB \
  --cores 1
```

## Получение URL

```bash
yc serverless container get --name happyrussia-api
```

URL будет в формате: `https://<container-id>.containers.yandexcloud.net`

## Обновление Flutter приложения

Измените `baseUrl` в `lib/services/api_service.dart`:

```dart
static String get baseUrl {
  return 'https://<your-container-url>/api';
}
```

## Полезные команды

```bash
# Просмотр логов
yc serverless container logs --name happyrussia-api

# Список ревизий
yc serverless container revision list --container-name happyrussia-api

# Удаление контейнера
yc serverless container delete --name happyrussia-api
```

## Подробная документация

- [SETUP_YANDEX_CLOUD.md](SETUP_YANDEX_CLOUD.md) - Подготовка Yandex Cloud
- [DEPLOY.md](DEPLOY.md) - Детальное руководство по развертыванию

