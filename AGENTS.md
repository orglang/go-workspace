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
- `taskfile.yaml`: Корневой taskfile проекта

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

- `core.go`: Pure domain logic
    - Domain models (core models)
    - API interfaces (primary ports)
    - Service structs (core behaviors)
- `me.go`: Pure message exchange (ME) logic
    - Message related DTO's (edge models)
- `vp.go`: Pure view presentation (VP) logic
    - View related DTO's (edge models)
- `ds.go`: Pure data storage (DS) logic
    - Data related DTO's (edge models)
    - Repository interfaces (secondary ports)
- `iv.go`: Pure input validation (IV) logic
    - Message related validation
    - Config related validation
- `cs.go`: Pure config storage (CS) logic
    - Config related DTO's (edge models)
- `tc.go`: Pure type conversion (TC) logic
    - Domain to domain conversions
    - Domain to message conversions and vice versa
    - Domain to data conversions and vice versa

### Toolkit specific

- `di_fx.go`: Fx (dependency injection library) specific component definitions
- `me_echo.go`: Echo (web framework) specific controller definitions (primary adapters)
- `vp_echo.go`: Echo (web framework) specific presenter definitions (primary adapters)
- `me_resty.go`: Resty (HTTP library) specific client definitions (secondary adapters for external use)
- `ds_pgx.go`: pgx (PostgreSQL driver and toolkit) specific DAO definitions (secondary adapters for internal use)
- `iv_ozzo.go`: Ozzo (validation library) specific validation definitions
- `tc_goverter.go`: Goverter (type conversion tool) specific conversion definitions
- `vp/bs5/*.html`: Go's built-in `html/template` and Bootstrap 5 (frontend toolkit) specific presentation definitions

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

- `app`: Всё, что касается приложения
- `gear`: Всё, что касается конвейера

### Виды артефактов

- `sources`: Исходники (в т.ч. сгенерированные) на языке программирования, языке разметки и т.п.
- `binaries`: Бинарники, которые формируются в результате компиляции и линковки. Присуще языкам со статической типизацией.
- `distros`: Пакеты в формате, пригодном для распространения (архивы, образы, и т.п.)

`sources` ⟶ `binaries` ⟶ `distros`

### CI job types

- `app/sources`
- `app/binaries`
- `app/distros`
- `gear/sources`
- `gear/distros`

## Процесс разработки

### Этапы задачи

1. `modification`: Этап активной модификации кода
1. `stabilization`: Этап стабилизации работы компонентов системы и компонентов окружения
1. `verification`: Этап согласования работы системы как единого целого
1. `finalization`: Этап принятия кода

### Переходы между этапами

1. [*] ⟶ `modification` - pull request отсутствует или переведен в `closed(unmerged)`
1. [*] ⟶ `stabilization` - pull request создан или переведен в `draft`
1. [*] ⟶ `verification` - pull request создан или переведен в `ready_for_review`
1. [*] ⟶ `finalization` - pull request переведен в `closed(merged)`

`modification` ⟶ `stabilization` ⟶ `verification` ⟶ `finalization`
