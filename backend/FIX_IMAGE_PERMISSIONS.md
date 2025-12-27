# Исправление прав доступа к образу

## Проблема
Ошибка: "Недостаточно прав для использования образа: cr.yandex/crpq885b13hnrlel0bkc/happyrussia-api:latest"

## Решение: Назначить права на образ

Сервисному аккаунту `happyrussia-sa` нужно назначить роль на уровне **образа** в Container Registry.

### Способ 1: Через веб-консоль (рекомендуется)

1. Перейдите в [Container Registry](https://console.cloud.yandex.ru/folders)
2. Откройте реестр `happyrussia-registry`
3. Перейдите на вкладку **"Образы"** (Images)
4. Найдите образ `happyrussia-api`
5. Нажмите на образ
6. Перейдите на вкладку **"Права доступа"**
7. Нажмите **"Назначить роли"**
8. Выберите сервисный аккаунт `happyrussia-sa`
9. Назначьте роль: **`container-registry.images.puller`**
10. Нажмите **"Сохранить"**

### Способ 2: На уровне реестра

1. В реестре `happyrussia-registry` перейдите на вкладку **"Права доступа"**
2. Нажмите **"Назначить роли"**
3. Выберите сервисный аккаунт `happyrussia-sa`
4. Назначьте роль: **`container-registry.images.puller`**
5. Нажмите **"Сохранить"**

### Способ 3: Через CLI (если yc настроен)

```bash
# Получить ID сервисного аккаунта
SA_ID=$(yc iam service-account get --name happyrussia-sa --format json | jq -r '.id')

# Назначить роль на уровне реестра
yc container registry add-access-binding happyrussia-registry \
  --role container-registry.images.puller \
  --subject serviceAccount:$SA_ID
```

## Проверка

После назначения ролей попробуйте снова создать ревизию контейнера.

## Альтернативное решение

Если проблема сохраняется, можно также назначить роль `editor` на уровне каталога для сервисного аккаунта (но это дает больше прав, чем нужно).

