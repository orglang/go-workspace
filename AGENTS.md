# Язык программирования огранизаций и его рантайм исполнения

## Репозитории проекта

- `github.com/orglang/.agents`: контекст для агентов
- `github.com/orglang/rationale`: теоретические и практические обоснования
- `github.com/orglang/go-workspace`: рабочее пространство разработки на go
- `github.com/orglang/go-engine`: реализация рантайма на go
- `github.com/orglang/go-sdk`: реализация SDK на go

## Структура проекта

- `.agents`: Контекст для агентов (сюда клонируется `github.com/orglang/.agents`)
- `.github`: Обвязка github actions
- `.opencode`: Обвязка opencode
- `rationale`: Теоретические и практические обоснования (сюда клонируется `github.com/orglang/rationale`)
- `sdk`: Компонент, реализующий SDK (сюда клонируется `github.com/orglang/go-sdk`)
- `engine`: Компонент, реализующий рантайм (сюда клонируется `github.com/orglang/go-engine`)
- `stack`: System level definition
- `docs/adr`: Архитектурные решения (architecture decision records)
- `docs/agents`: Контекст для агентов, не вошедший в этот файл
- `GLOSSARY.md`: Контролируемый словарь терминов
- `taskfile.yaml`: Корневой taskfile проекта

## Когда и куда смотреть

- `docs/adr/`: читать **перед** тем как пересечь границу пакета — создать
  `core/`/`adapter/`, завести зависимость на SDK или конкретный toolkit, вынести
  имя таблицы SQL в agnostic код, перенести вызов в порт. Решение уже принятое не
  переигрывать молча: либо следуешь ему, либо пишешь новое ADR сюда же, superseding
  старое. ADR 0010 — это шаблон такой миграции, а не теория.
- `GLOSSARY.md`: читать **перед** тем как назвать что-либо — идентификатор, тест,
  текст коммита. Имя берётся отсюда, а не от соседнего кода. Общепринятый термин,
  понятный агенту без lookup'а, побеждает домашний: `primary port`, `secondary
  adapter`, `DTO`, `DAO`, `controller`. Словарь держит то, чего знакомый термин не
  покрывает — `core`/`adapter` как имена каталогов и `value key` как имя `valkey`.
- Где что лежит: решения и словарь — **здесь**, в рабочем пространстве
  (`go-workspace`), код, который они описывают, — в `engine/`. Агент, работающий
  только в `engine/`, не найдёт их сам, а этот файл — единственная точка входа.
  Раскладку «что в каком репозитории» держит раздел «Структура проекта» выше.

## Структура компонента

Это самая полная общая структура пакетов компонента. Конкретный компонент может содержать только часть пакетов.

- `app`: Runnable program
  - `web`: Web application
- `adt`: Reusable abstract data types
  - `commsem`: Communication semantics
  - `compsem`: Computation semantics
  - `compvar`: Computation variable
  - `identity`: Identification value
  - `option`: Optional value
  - `polarity`: Polarization value
  - `seqnum`: Sequential number
  - `symbol`: Atomic symbol
  - `uniqsym`: Unique (namespaced) symbol
  - `valkey`: Content-based key (aka hashcode or digest)
- `pool`: Pool abstract data types
  - `commexch`: Communication exchange
  - `commturn`: Communication turn
  - `compexec`: Computation execution
  - `compstep`: Computation step
  - `compvar`: Computation variable
  - `termdef`: Term definition
  - `termexp`: Term expression
  - `typedef`: Type definition
  - `typeexp`: Type expression
- `proc`: Process abstract data types
  - `commexch`: Communication exchange
  - `commturn`: Communication turn
  - `compexec`: Computation execution
  - `compstep`: Computation step
  - `termdec`: Term declaration
  - `termdef`: Term definition
  - `termexp`: Term expression
  - `typedef`: Type definition
  - `typeexp`: Type expression
- `lib`: Reusable abstract behavior types
  - `db`: Relational database drivers
  - `kv`: Key-value store drivers
  - `lf`: Logging framework harness
  - `te`: Template engine harness
  - `wp`: Worker pool harness
  - `ws`: Web server harness
- `db`: Storage schema
  - `postgres`: PostgreSQL schema
- `proto`: Prototype endeavors
- `test`: Test harness
  - `e2e`: End-to-end tests

## Структура пакета

### Toolkit agnostic

Файл agnostic тогда и только тогда, когда он не импортирует ни SDK
(`github.com/orglang/go-sdk`), ни конкретный toolkit. Имя файла ничего не решает:
`tc.go` в `adt/identity` agnostic, а `tc.go` в `pool/typeexp` — нет.

- `core.go`: Pure domain logic
    - Domain models (core models)
    - API interfaces (primary ports)
    - Service structs (core behaviors)
- `me.go`: Pure message exchange (ME) logic
    - Message related DTO's
- `ds.go`: Pure data storage (DS) logic
    - Data related records
    - Repository interfaces (secondary ports)
- `iv.go`: Pure input validation (IV) logic
    - Message related validation
    - Config related validation
- `cs.go`: Pure config storage (CS) logic
    - Config related DTO's
- `tc.go`: Pure type conversion (TC) logic
    - Domain to domain conversions

`vp.go` в этот список не входит: view models несут теги `form:`/`json:`, то есть
это DTO, а они принадлежат toolkit specific. У `tc.go` доменные конверсии
agnostic, а конверсии в DTO SDK и обратно — нет.

### Toolkit specific

- `di_fx.go`: Fx (dependency injection library) specific component definitions
- `me_echo.go`: Echo (web framework) specific controller definitions (primary adapters)
- `vp.go`: View presentation (VP) logic — view models с тегами `form:`/`json:`
- `vp_echo.go`: Echo (web framework) specific presenter definitions (primary adapters)
- `me_resty.go`: Resty (HTTP library) specific client definitions (secondary adapters for external use)
- `ds_pgx.go`: pgx (PostgreSQL driver and toolkit) specific DAO definitions (secondary adapters for internal use)
- `iv_ozzo.go`: Ozzo (validation library) specific validation definitions
- `tc.go`: Type conversion (TC) logic для моделей, которые конвертируются в DTO SDK и обратно
- `tc_goverter.go`: Goverter (type conversion tool) specific conversion definitions
- `vp/bs5/*.html`: Go's built-in `html/template` and Bootstrap 5 (frontend toolkit) specific presentation definitions

Проверяемое доказательство: все семь файлов ниже импортируют
`github.com/orglang/go-sdk`, поэтому лежат на toolkit specific стороне границы.

```
pool/typeexp/tc.go    proc/typeexp/tc.go    pool/termexp/tc.go
proc/termexp/tc.go    prog/tc.go            proc/typedef/vp.go
proc/termdec/vp.go
```

При разделении пакета на `core/` и `adapter/` `vp.go` и такой `tc.go` уезжают в
`adapter/` — см. ADR 0005 `docs/adr/0005-ports-cross-boundaries.md`.

## Структура моделей

- `<model>Ref`: Machine-readable pointer to an abstraction
- `<model>Spec`: Specification to create an abstraction
- `<model>Rec`: Record for abstraction retrieval (excluding sub abstractions)
- `<model>Mod`: Modification to change an abstraction (including sub abstractions)
- `<model>Snap`: Snapshot for abstraction retrieval (including sub abstractions)

## Структура артефактов

Артефакты подготавливаются в локальном (local) репозитории и затем публикуются в удаленный (remote) репозиторий.

`check1` ⟶ `prepare` ⟶ `check2` ⟶ `publish`

### Группы артефактов

- `app`: Всё, что касается приложения (application)
- `gear`: Всё, что касается конвейера (pipeline), включая обвязку (harness) по накату

### Виды артефактов

- `sources`: Исходники (в т.ч. сгенерированные) на языке программирования, языке разметки и т.п.
- `binaries`: Бинарники, которые формируются в результате компиляции и линковки. Присуще языкам со статической типизацией.
- `distros`: Пакеты в формате, пригодном для распространения (архивы, образы, и т.п.)

`sources` ⟶ `binaries` ⟶ `distros`

### Тесты

- `unit`: Модульные
- `integration`: Интеграционные
- `e2e`: Сквозные

### Итого

| CI job | `check1` (быстро) | `prepare` | `check2` (медленно) |
|-----|-------------------|-----------|---------------------|
| `app/sources` | линтинг, статический анализ | кодогенерация, форматирование | модульные тесты |
| `gear/sources` | линтинг, валидация | форматирование | модульные тесты (при наличии) |
| `app/binaries` | интеграционные тесты против моков, заглушек и т.п.  | компиляция, линковка | интеграционные тесты против реальных сервисов |
| `gear/binaries` | — | — | — |
| `app/distros` | легковесные сквозные тесты | упаковка | 1. тяжеловесные сквозные тесты<br>2. проверка обратной совместимости против `gear:latest` |
| `gear/distros` | dry-run накат | упаковка | 1. полноценный накат<br>2. проверка обратной совместимости против `app:latest` |

## Процесс разработки

### Этапы задачи

1. `modification`: Этап активной модификации кода. В рамках CI гоняем только `sources`.
1. `stabilization`: Этап стабилизации работы компонентов системы и компонентов окружения. В рамках CI гоняем только `binaries`.
1. `verification`: Этап согласования работы системы как единого целого. В рамках CI гоняем только `distros`.
1. `finalization`: Этап принятия кода. В рамках CI гоняем все jobs, затем помечаем тегом `latest`.

### Переходы между этапами

1. [*] ⟶ `modification` - pull request отсутствует или переведен в `closed(unmerged)`
1. [*] ⟶ `stabilization` - pull request создан или переведен в `draft`
1. [*] ⟶ `verification` - pull request создан или переведен в `ready_for_review`
1. [*] ⟶ `finalization` - pull request переведен в `closed(merged)`

`modification` ⟶ `stabilization` ⟶ `verification` ⟶ `finalization`
