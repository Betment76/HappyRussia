# Развертывание с ID реестра

## Ваш Registry ID
```
crpq885b13hnrlel0bkc
```

## Шаги развертывания

### 1. Убедитесь, что Docker запущен

**Windows:**
- Запустите Docker Desktop
- Дождитесь полной загрузки (иконка в трее должна быть зеленая)

**WSL:**
```bash
# Проверка
docker ps
```

### 2. Настройте Docker для работы с Yandex Cloud

```bash
yc container registry configure-docker
```

### 3. Соберите Docker образ

```bash
cd backend
docker build -t happyrussia-api:latest .
```

### 4. Тегируйте образ для вашего реестра

```bash
docker tag happyrussia-api:latest cr.yandex/crpq885b13hnrlel0bkc/happyrussia-api:latest
```

### 5. Загрузите образ в реестр

```bash
docker push cr.yandex/crpq885b13hnrlel0bkc/happyrussia-api:latest
```

### 6. Создайте Serverless Container (через веб-консоль)

1. Перейдите в [Serverless Containers](https://console.cloud.yandex.ru/folders)
2. Нажмите "Создать контейнер"
3. Имя: `happyrussia-api`
4. Нажмите "Создать"

### 7. Разверните контейнер (через веб-консоль)

1. Откройте контейнер `happyrussia-api`
2. Перейдите на вкладку "Ревизии"
3. Нажмите "Создать ревизию"
4. Заполните:
   - **Образ:** `cr.yandex/crpq885b13hnrlel0bkc/happyrussia-api:latest`
   - **Память:** 512 MB
   - **CPU:** 1 vCPU
   - **Таймаут выполнения:** 30 секунд
   - **Параллелизм:** 10
   - **Сервисный аккаунт:** `happyrussia-sa`
5. Нажмите "Создать"

### 8. Получите URL контейнера

После создания ревизии URL будет показан в карточке контейнера.

Формат: `https://<container-id>.containers.yandexcloud.net`

### 9. Обновите Flutter приложение

В файле `lib/services/api_service.dart` измените:

```dart
static String get baseUrl {
  // Замените на ваш URL контейнера
  return 'https://<ваш-container-url>/api';
}
```

## Быстрая команда (если используете CLI)

```bash
# После сборки и загрузки образа
yc serverless container revision deploy \
  --container-name happyrussia-api \
  --image cr.yandex/crpq885b13hnrlel0bkc/happyrussia-api:latest \
  --memory 512MB \
  --cores 1 \
  --execution-timeout 30s \
  --concurrency 10 \
  --service-account-id <SA_ID>
```

## Проверка работы

После развертывания проверьте:

```bash
curl https://<container-url>/api/health
```

Должен вернуть: `{"status":"ok"}`

