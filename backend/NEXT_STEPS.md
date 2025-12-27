# Следующие шаги после назначения ролей

## ✅ Что уже сделано:
- Роли назначены сервисному аккаунту
- Сервисный аккаунт готов к работе

## 📋 Что нужно сделать дальше:

### Шаг 1: Создать Container Registry

Container Registry нужен для хранения Docker образов.

**Через веб-консоль:**
1. Перейдите в [Container Registry](https://console.cloud.yandex.ru/folders/<ваш-каталог>/cloud/container-registry)
2. Нажмите "Создать реестр"
3. Введите имя: `happyrussia-registry`
4. Нажмите "Создать"

**Или через CLI (если yc работает):**
```bash
yc container registry create --name happyrussia-registry
```

### Шаг 2: Настроить Docker для работы с Container Registry

```bash
yc container registry configure-docker
```

Эта команда настроит Docker для загрузки образов в ваш реестр.

### Шаг 3: Собрать Docker образ локально

```bash
cd backend
docker build -t happyrussia-api:latest .
```

### Шаг 4: Протестировать образ локально (опционально)

```bash
docker run -p 8000:8000 happyrussia-api:latest
```

Проверьте: `http://localhost:8000/api/health`

### Шаг 5: Получить ID реестра

```bash
# Через CLI
REGISTRY_ID=$(yc container registry get --name happyrussia-registry --format json | jq -r '.id')
echo $REGISTRY_ID

# Или через веб-консоль: скопируйте ID из карточки реестра
```

### Шаг 6: Тегировать и загрузить образ

```bash
# Замените <REGISTRY_ID> на реальный ID
docker tag happyrussia-api:latest cr.yandex/<REGISTRY_ID>/happyrussia-api:latest
docker push cr.yandex/<REGISTRY_ID>/happyrussia-api:latest
```

### Шаг 7: Создать Serverless Container

**Через веб-консоль:**
1. Перейдите в [Serverless Containers](https://console.cloud.yandex.ru/folders/<ваш-каталог>/serverless-containers)
2. Нажмите "Создать контейнер"
3. Введите имя: `happyrussia-api`
4. Нажмите "Создать"

**Или через CLI:**
```bash
yc serverless container create --name happyrussia-api
```

### Шаг 8: Развернуть контейнер

**Через веб-консоль:**
1. Откройте контейнер `happyrussia-api`
2. Перейдите на вкладку "Ревизии"
3. Нажмите "Создать ревизию"
4. Укажите:
   - **Образ:** `cr.yandex/<REGISTRY_ID>/happyrussia-api:latest`
   - **Память:** 512 MB
   - **CPU:** 1 vCPU
   - **Таймаут:** 30 секунд
   - **Сервисный аккаунт:** `happyrussia-sa`
5. Нажмите "Создать"

**Или через CLI:**
```bash
yc serverless container revision deploy \
  --container-name happyrussia-api \
  --image cr.yandex/<REGISTRY_ID>/happyrussia-api:latest \
  --memory 512MB \
  --cores 1 \
  --execution-timeout 30s \
  --concurrency 10 \
  --service-account-id <SA_ID>
```

### Шаг 9: Получить URL контейнера

**Через веб-консоль:**
- URL будет показан в карточке контейнера

**Через CLI:**
```bash
yc serverless container get --name happyrussia-api
```

URL будет в формате: `https://<container-id>.containers.yandexcloud.net`

### Шаг 10: Обновить Flutter приложение

Измените `baseUrl` в `lib/services/api_service.dart`:

```dart
static String get baseUrl {
  return 'https://<ваш-container-url>/api';
}
```

## 🚀 Быстрый вариант (если используете CLI)

Используйте скрипт автоматического развертывания:

```bash
cd backend
chmod +x deploy.sh
./deploy.sh
```

## 📝 Полезные команды

```bash
# Просмотр логов
yc serverless container logs --name happyrussia-api

# Список ревизий
yc serverless container revision list --container-name happyrussia-api

# Проверка работы API
curl https://<container-url>/api/health
```

## ❓ Нужна помощь?

Если возникли проблемы:
1. Проверьте логи контейнера
2. Убедитесь, что образ загружен в реестр
3. Проверьте, что сервисный аккаунт имеет все необходимые роли

