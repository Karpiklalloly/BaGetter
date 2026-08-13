# Сборка BaGetter с помощью PowerShell

PowerShell-скрипты из каталога `scripts` публикуют BaGetter для Windows и Linux. Поддерживаются архитектуры x64 и ARM64, а также два варианта поставки .NET:

- **Self-contained** — .NET Runtime включён в сборку. На целевом сервере устанавливать .NET не требуется.
- **Framework-dependent** — .NET Runtime не включён. На целевой машине должен быть установлен ASP.NET Core Runtime версии, соответствующей `TargetFramework` проекта.

Для запуска скриптов на машине сборки требуется .NET SDK, указанный в `global.json`.

## Быстрый выбор

| Целевая система | .NET включён | Требуется .NET на сервере | Скрипт |
| --- | --- | --- | --- |
| Windows | Да | Нет | `Publish-Windows-SelfContained.ps1` |
| Windows | Нет | Да | `Publish-Windows-FrameworkDependent.ps1` |
| Linux | Да | Нет | `Publish-Linux-SelfContained.ps1` |
| Linux | Нет | Да | `Publish-Linux-FrameworkDependent.ps1` |

Для обычного Linux-сервера без установленного .NET используйте:

```powershell
.\scripts\Publish-Linux-SelfContained.ps1 -Clean
```

## Windows

Сборка x64 со встроенным .NET Runtime:

```powershell
.\scripts\Publish-Windows-SelfContained.ps1 -Clean
```

Сборка x64, требующая установленный ASP.NET Core Runtime:

```powershell
.\scripts\Publish-Windows-FrameworkDependent.ps1 -Clean
```

Добавьте `-Arm`, чтобы собрать ARM64 вместо x64:

```powershell
.\scripts\Publish-Windows-SelfContained.ps1 -Arm -Clean
```

## Linux

Сборка x64 со встроенным .NET Runtime:

```powershell
.\scripts\Publish-Linux-SelfContained.ps1 -Clean
```

Сборка x64, требующая установленный ASP.NET Core Runtime:

```powershell
.\scripts\Publish-Linux-FrameworkDependent.ps1 -Clean
```

Сборка ARM64 со встроенным .NET Runtime, например для ARM-сервера или Raspberry Pi:

```powershell
.\scripts\Publish-Linux-SelfContained.ps1 -Arm -Clean
```

## Параметры

Все четыре скрипта-обёртки принимают параметры:

- `-Arm` — использовать ARM64 вместо x64;
- `-Clean` — удалить только каталог результата выбранной сборки перед публикацией.

Без `-Clean` команда `dotnet publish` обновляет существующий каталог результата.

## Универсальный скрипт

Вместо обёрток можно напрямую вызвать `Publish.ps1`:

```powershell
.\scripts\Publish.ps1 -Platform Linux -SelfContained -Arm -Clean
```

Параметры универсального скрипта:

- `-Platform Windows|Linux` — целевая операционная система;
- `-SelfContained` — включить .NET Runtime в сборку;
- `-Arm` — собрать ARM64 вместо x64;
- `-Clean` — очистить каталог выбранного результата.

## Каталоги результатов

Готовые файлы записываются в `artifacts/publish`:

```text
artifacts/publish/windows-x64-self-contained/
artifacts/publish/windows-x64-framework-dependent/
artifacts/publish/windows-arm64-self-contained/
artifacts/publish/windows-arm64-framework-dependent/
artifacts/publish/linux-x64-self-contained/
artifacts/publish/linux-x64-framework-dependent/
artifacts/publish/linux-arm64-self-contained/
artifacts/publish/linux-arm64-framework-dependent/
```

Создаётся только каталог запрошенной сборки.

## Запуск на Linux

Скопируйте содержимое соответствующего каталога публикации на сервер. Для self-contained сборки:

```bash
chmod +x BaGetter
mkdir -p data

ASPNETCORE_URLS=http://0.0.0.0:5000 \
Storage__Path="$(pwd)/data" \
Database__ConnectionString="Data Source=$(pwd)/data/bagetter.db" \
./BaGetter
```

Для framework-dependent сборки сначала установите подходящий ASP.NET Core Runtime, затем запустите:

```bash
dotnet BaGetter.dll
```

## Типичные ошибки

### Команда `dotnet` не найдена

Установите .NET SDK версии из `global.json` и убедитесь, что команда доступна в `PATH`:

```powershell
dotnet --info
```

### Ошибка NuGet при первой сборке платформы

При первой публикации для нового Runtime Identifier, например `linux-arm64`, .NET SDK может загружать дополнительные runtime-пакеты из NuGet. Проверьте доступ к `https://api.nuget.org` и настройки прокси.

### Сборка запускается не на той архитектуре

Соберите результат повторно с правильным значением `-Arm`. Скрипты создают разные каталоги для x64 и ARM64, поэтому результаты не перезаписывают друг друга.
