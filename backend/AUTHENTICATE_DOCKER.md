# Аутентификация Docker для Container Registry

## Ваш Registry ID
```
crpq885b13hnrlel0bkc
```

## Способ 1: Через веб-консоль (самый простой)

1. В левом меню Container Registry нажмите на ссылку **"Аутентифицироваться в Container Registry"**
2. Выберите способ аутентификации:
   - **OAuth токен** (для личного аккаунта)
   - **IAM токен** (если используете CLI)
   - **JSON ключ сервисного аккаунта** (для автоматизации)
3. Скопируйте команду, которая будет показана
4. Выполните команду в терминале

## Способ 2: Через OAuth токен (быстрый способ)

### Шаг 1: Получите OAuth токен

1. Перейдите по ссылке: https://oauth.yandex.ru/authorize?response_type=token&client_id=1a6990aa636648f9b2ef85559d85257f
2. Разрешите доступ
3. Скопируйте токен из адресной строки (параметр `access_token`)

### Шаг 2: Выполните команду

```bash
echo '<ваш-oauth-токен>' | docker login --username oauth --password-stdin cr.yandex
```

Замените `<ваш-oauth-токен>` на реальный токен.

## Способ 3: Через IAM токен (если используете yc CLI)

Если у вас настроен `yc`:

```bash
# Получить IAM токен
IAM_TOKEN=$(yc iam create-token)

# Аутентифицироваться
echo $IAM_TOKEN | docker login --username iam --password-stdin cr.yandex
```

## Проверка аутентификации

После выполнения команды проверьте:

```bash
docker login cr.yandex
```

Если вы уже аутентифицированы, увидите сообщение "Login Succeeded" или "Already logged in".

## Загрузка образа

После успешной аутентификации загрузите образ:

```bash
docker push cr.yandex/crpq885b13hnrlel0bkc/happyrussia-api:latest
```

## Если возникли проблемы

### Ошибка: "unauthorized: authentication required"

**Решение:** 
1. Убедитесь, что выполнили `docker login cr.yandex`
2. Проверьте, что токен не истек (OAuth токены действуют 1 год, IAM токены - 12 часов)

### Ошибка: "denied: access denied"

**Решение:** 
1. Убедитесь, что ваш пользователь или сервисный аккаунт имеет роль `container-registry.images.pusher`
2. Проверьте, что вы используете правильный Registry ID

### Ошибка: "repository name must be lowercase"

**Решение:** Имя образа должно быть в нижнем регистре. Убедитесь, что используете:
```
cr.yandex/crpq885b13hnrlel0bkc/happyrussia-api:latest
```

## Следующий шаг

После успешной загрузки образа перейдите к созданию Serverless Container.

