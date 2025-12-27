# Подготовка Yandex Cloud для развертывания

Пошаговая инструкция по подготовке Yandex Cloud перед развертыванием бекенда.

## Шаг 1: Регистрация и создание проекта

1. Перейдите на [Yandex Cloud](https://cloud.yandex.ru/)
2. Зарегистрируйтесь или войдите в аккаунт
3. Создайте новый проект:
   - Нажмите "Создать проект"
   - Введите название: `HappyRussia`
   - Выберите организацию (если есть)
   - Нажмите "Создать"

## Шаг 2: Установка Yandex Cloud CLI

### Windows

**Вариант 1: Установщик**
1. Скачайте установщик с [официального сайта](https://cloud.yandex.ru/docs/cli/quickstart)
2. Запустите установщик
3. Следуйте инструкциям

**Вариант 2: Chocolatey**
```powershell
choco install yandex-cloud-cli
```

**Вариант 3: Scoop**
```powershell
scoop bucket add yandex-cloud https://github.com/yandex-cloud/scoop-bucket
scoop install yandex-cloud-cli
```

### Linux/macOS

```bash
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
```

### Проверка установки

```c
```

## Шаг 3: Инициализация Yandex Cloud CLI

```bash
yc init
```

Следуйте инструкциям:

1. **Выберите облако:**
   ```
   ? Please select cloud:
     [1] cloud-b1g...
   ```

2. **Выберите каталог:**
   ```
   ? Please select folder:
     [1] default (id: b1g...)
   ```

3. **Выберите зону доступности:**
   ```
   ? Please select availability zone:
     [1] ru-central1-a
     [2] ru-central1-b
     [3] ru-central1-c
   ```
   Рекомендуется: `ru-central1-a`

4. **Создайте профиль по умолчанию:**
   ```
   ? Do you want to configure a default profile? (Y/n):
   ```

## Шаг 4: Создание сервисного аккаунта

Сервисный аккаунт нужен для автоматического развертывания и управления ресурсами.

```bash
# Создать сервисный аккаунт
yc iam service-account create --name happyrussia-sa --description "Service account for HappyRussia API"

# Получить ID сервисного аккаунта
SA_ID=$(yc iam service-account get --name happyrussia-sa --format json | jq -r '.id')
echo "Service Account ID: $SA_ID"
```

**Для Windows PowerShell:**
```powershell
$sa = yc iam service-account get --name happyrussia-sa --format json | ConvertFrom-Json
$SA_ID = $sa.id
Write-Host "Service Account ID: $SA_ID"
```

## Шаг 5: Назначение ролей сервисному аккаунту

```bash
# Получить ID каталога
FOLDER_ID=$(yc config get folder-id)
echo "Folder ID: $FOLDER_ID"

# Назначить роли
yc resource-manager folder add-access-binding $FOLDER_ID \
  --role container-registry.images.pusher \
  --subject serviceAccount:$SA_ID

yc resource-manager folder add-access-binding $FOLDER_ID \
  --role serverless.containers.deployer \
  --subject serviceAccount:$SA_ID

yc resource-manager folder add-access-binding $FOLDER_ID \
  --role serverless.containers.invoker \
  --subject serviceAccount:$SA_ID
```

**Для Windows PowerShell:**
```powershell
$FOLDER_ID = yc config get folder-id
Write-Host "Folder ID: $FOLDER_ID"

yc resource-manager folder add-access-binding $FOLDER_ID `
  --role container-registry.images.pusher `
  --subject serviceAccount:$SA_ID

yc resource-manager folder add-access-binding $FOLDER_ID `
  --role serverless.containers.deployer `
  --subject serviceAccount:$SA_ID

yc resource-manager folder add-access-binding $FOLDER_ID `
  --role serverless.containers.invoker `
  --subject serviceAccount:$SA_ID
```

## Шаг 6: Создание Container Registry

Container Registry используется для хранения Docker образов.

```bash
# Создать реестр
yc container registry create --name happyrussia-registry

# Получить ID реестра
REGISTRY_ID=$(yc container registry get --name happyrussia-registry --format json | jq -r '.id')
echo "Registry ID: $REGISTRY_ID"
```

**Для Windows PowerShell:**
```powershell
yc container registry create --name happyrussia-registry

$registry = yc container registry get --name happyrussia-registry --format json | ConvertFrom-Json
$REGISTRY_ID = $registry.id
Write-Host "Registry ID: $REGISTRY_ID"
```

## Шаг 7: Настройка аутентификации Docker

```bash
# Настроить Docker для работы с Container Registry
yc container registry configure-docker
```

Эта команда добавит настройки в `~/.docker/config.json` (или `%USERPROFILE%\.docker\config.json` на Windows).

## Шаг 8: Создание Serverless Container (опционально)

Если хотите использовать Serverless Containers:

```bash
# Создать контейнер
yc serverless container create --name happyrussia-api

# Получить ID контейнера
CONTAINER_ID=$(yc serverless container get --name happyrussia-api --format json | jq -r '.id')
echo "Container ID: $CONTAINER_ID"
```

## Шаг 9: Проверка настройки

Создайте скрипт проверки `check_setup.sh`:

```bash
#!/bin/bash

echo "Проверка настройки Yandex Cloud..."
echo ""

# Проверка CLI
echo "✅ Yandex Cloud CLI:"
yc version
echo ""

# Проверка сервисного аккаунта
echo "✅ Сервисный аккаунт:"
yc iam service-account get --name happyrussia-sa
echo ""

# Проверка Container Registry
echo "✅ Container Registry:"
yc container registry get --name happyrussia-registry
echo ""

# Проверка Serverless Container (если создан)
echo "✅ Serverless Container:"
yc serverless container get --name happyrussia-api 2>/dev/null || echo "Контейнер еще не создан"
echo ""

echo "✅ Настройка завершена!"
```

## Шаг 10: Сохранение конфигурации

Сохраните важные ID в файл `.env.local` (не коммитьте в Git!):

```bash
# Создать файл с конфигурацией
cat > .env.local << EOF
FOLDER_ID=$(yc config get folder-id)
SA_ID=$(yc iam service-account get --name happyrussia-sa --format json | jq -r '.id')
REGISTRY_ID=$(yc container registry get --name happyrussia-registry --format json | jq -r '.id')
EOF

echo "Конфигурация сохранена в .env.local"
```

## Полезные команды

### Просмотр всех ресурсов

```bash
# Список сервисных аккаунтов
yc iam service-account list

# Список реестров
yc container registry list

# Список контейнеров
yc serverless container list
```

### Удаление ресурсов (если нужно начать заново)

```bash
# Удалить контейнер
yc serverless container delete --name happyrussia-api

# Удалить реестр (осторожно!)
yc container registry delete --name happyrussia-registry

# Удалить сервисный аккаунт
yc iam service-account delete --name happyrussia-sa
```

## Следующие шаги

После завершения подготовки:

1. ✅ Перейдите к [DEPLOY.md](DEPLOY.md) для развертывания приложения
2. ✅ Используйте [deploy.sh](deploy.sh) для автоматического развертывания
3. ✅ Обновите `baseUrl` в Flutter приложении

## Проблемы и решения

### Ошибка: "Permission denied"

**Решение:** Проверьте, что сервисному аккаунту назначены правильные роли.

### Ошибка: "Resource not found"

**Решение:** Убедитесь, что вы находитесь в правильном каталоге:
```bash
yc config get folder-id
```

### Ошибка: "Authentication failed"

**Решение:** Переинициализируйте CLI:
```bash
yc init
```

## Дополнительные ресурсы

- [Документация Yandex Cloud CLI](https://cloud.yandex.ru/docs/cli/)
- [Container Registry](https://cloud.yandex.ru/docs/container-registry/)
- [Serverless Containers](https://cloud.yandex.ru/docs/serverless-containers/)
- [IAM и доступ](https://cloud.yandex.ru/docs/iam/)

