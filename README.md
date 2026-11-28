# Рабочее пространство

## Назначение

Репозиторий координирует разработку Orglang и содержит документацию и инструменты для работы с основным Go-приложением. Исходный код приложения хранится в отдельном Git-репозитории.

## Инициализация

```bash
git clone https://github.com/orglang/go-workspace.git orglang
cd orglang
git clone https://github.com/orglang/go-engine.git engine
```

## Проверка

```bash
(cd engine && go test ./...)
```

## Архитектура

Описание границ репозитория, ответственности приложения, структуры engine, правил зависимостей и плана миграции находится в [docs/architecture.md](docs/architecture.md).

## Разработка

Соглашения по именованию Go-файлов, организации пакетов, экспортируемости и структуре core/adapter описаны в [Coding Standards](docs/development/coding-standards.md).
