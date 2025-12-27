# Установка Yandex Cloud CLI в WSL

## Установка

Выполните в терминале WSL:

```bash
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
```

## Активация

После установки выполните одну из команд:

```bash
# Вариант 1: Перезагрузить shell
exec -l $SHELL

# Вариант 2: Загрузить настройки в текущий shell
source ~/.bashrc
```

## Проверка

```bash
yc version
```

Должно вывести версию CLI, например: `Yandex Cloud CLI 0.185.0 linux/amd64`

## Если команда все еще не найдена

Если после `source ~/.bashrc` команда `yc` все еще не работает:

1. Проверьте, что путь добавлен:
   ```bash
   echo $PATH | grep yandex-cloud
   ```

2. Добавьте путь вручную:
   ```bash
   export PATH=$PATH:$HOME/yandex-cloud/bin
   ```

3. Или добавьте в `~/.bashrc`:
   ```bash
   echo 'export PATH=$PATH:$HOME/yandex-cloud/bin' >> ~/.bashrc
   source ~/.bashrc
   ```

## Следующий шаг

После успешной установки перейдите к [SETUP_YANDEX_CLOUD.md](SETUP_YANDEX_CLOUD.md) и выполните `yc init`.

