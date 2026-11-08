# Рабочее пространство

## Назначение

Репозиторий объединяет локальную разработку модулей Orglang через Go workspace. Исходный код модулей хранится в отдельных Git-репозиториях.

## Инициализация

```bash
git clone https://github.com/orglang/go-workspace.git orglang
cd orglang
git clone https://github.com/orglang/go-engine.git engine
git clone https://github.com/orglang/go-sdk.git sdk
```

Корневой `go.work` подключает `./engine` и `./sdk`.

## Проверка

```bash
go env GOWORK
go work sync
(cd engine && go test ./...)
(cd sdk && go test ./...)
```

## Архитектура

Описание границ workspace, ответственности модулей, структуры engine, правил зависимостей и плана миграции находится в [docs/architecture.md](docs/architecture.md).
