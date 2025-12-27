# Пересборка и развертывание после исправлений

## Исправления

1. ✅ Изменен порт с 8000 на 8080 (Serverless Containers ожидают порт 8080)
2. ✅ Заменен `regex` на `pattern` в FastAPI Query (исправлены предупреждения)
3. ✅ Исправлен `datetime.utcnow()` на `datetime.now(timezone.utc)`

## Шаги для пересборки и развертывания

### 1. Соберите новый Docker образ

```bash
cd backend
docker build -t happyrussia-api:latest .
```

### 2. Тегируйте образ

```bash
docker tag happyrussia-api:latest cr.yandex/crpq885b13hnrlel0bkc/happyrussia-api:latest
```

### 3. Загрузите образ в реестр

```bash
docker push cr.yandex/crpq885b13hnrlel0bkc/happyrussia-api:latest
```

### 4. Создайте новую ревизию контейнера

**Через веб-консоль:**
1. Откройте контейнер `happyrussia-api`
2. Перейдите на вкладку **"Ревизии"**
3. Нажмите **"Создать ревизию"**
4. Убедитесь, что:
   - **Образ:** `cr.yandex/crpq885b13hnrlel0bkc/happyrussia-api:latest`
   - **Порт:** 8080 (должен быть автоматически)
   - **Память:** 512 MB
   - **CPU:** 1 vCPU
   - **Таймаут выполнения:** 30 секунд
5. Нажмите **"Создать"**

### 5. Активируйте новую ревизию

После создания ревизии она должна автоматически стать активной. Если нет - нажмите **"Активировать"**.

## Проверка

После развертывания проверьте:

```bash
curl https://bbas207e8gbhlpbjb51u.containers.yandexcloud.net/api/health
```

Должен вернуть: `{"status":"ok"}`

## Ожидаемый результат

После исправлений:
- ✅ Контейнер должен успешно запускаться на порту 8080
- ✅ Не должно быть ошибок "connection refused"
- ✅ Не должно быть предупреждений FastAPI о deprecated `regex`

