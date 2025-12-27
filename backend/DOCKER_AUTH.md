# Настройка аутентификации Docker для Yandex Cloud

## Ваш Registry ID
```
crpq885b13hnrlel0bkc
```

## Способ 1: Через веб-консоль (рекомендуется)

1. Перейдите в [Container Registry](https://console.cloud.yandex.ru/folders)
2. Откройте реестр `happyrussia-registry`
3. Перейдите на вкладку **"Права доступа"**
4. Нажмите **"Настроить Docker"** или **"Получить команду для аутентификации"**
5. Скопируйте и выполните команду в терминале

Обычно команда выглядит так:
```bash
echo '<ваш-токен>' | docker login --username json_key --password-stdin cr.yandex
```

## Способ 2: Через OAuth токен

1. Получите OAuth токен в [веб-консоли](https://oauth.yandex.ru/authorize?response_type=token&client_id=1a6990aa636648f9b2ef85559d85257f)
2. Выполните:
```bash
echo '<ваш-oauth-токен>' | docker login --username oauth --password-stdin cr.yandex
```

## Способ 3: Через IAM токен (если используете CLI)

Если `yc` настроен в WSL:
```bash
# В WSL выполните:
export PATH=$PATH:$HOME/yandex-cloud/bin
yc container registry configure-docker
```

## После аутентификации

Проверьте подключение:
```bash
docker login cr.yandex
```

Затем загрузите образ:
```bash
docker push cr.yandex/crpq885b13hnrlel0bkc/happyrussia-api:latest
```

## Если возникли проблемы

### Ошибка: "unauthorized: authentication required"

**Решение:** Выполните `docker login cr.yandex` с правильными учетными данными.

### Ошибка: "denied: access denied"

**Решение:** Убедитесь, что сервисный аккаунт имеет роль `container-registry.images.pusher`.

