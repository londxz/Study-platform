# Learny

Личная платформа `londxz` для подготовки к iOS-собеседованиям и системного изучения Go. Frontend сохраняет монохромный liquid-glass интерфейс, а каталог, вопросы, задачи, мок-интервью, попытки и прогресс обслуживает Go API с PostgreSQL.

## Архитектура

```text
Browser -> Vinext /api/backend/* -> Go API -> PostgreSQL
                                      |
                                      -> sandbox runner Swift / Go
```

- browser не получает адрес Go API и секрет подписи;
- same-origin BFF подписывает идентичность пользователя;
- публичное API не возвращает эталонные решения и скрытые тесты;
- `/admin` позволяет управлять деревом разделов и тем, уроками, вопросами, задачами и скрытыми тестами;
- пользовательский код не выполняется в процессе API.

## Локальный запуск

Требуются Node.js `>=22.13.0`, Go `1.25+` и Docker.

1. Запустите PostgreSQL:

```bash
docker compose up -d postgres
```

2. Настройте и запустите Go API:

```bash
cp backend/.env.example backend/.env
cd backend
set -a && source .env && set +a
go run ./cmd/api
```

3. В другом терминале настройте BFF и запустите frontend:

```bash
cp .env.example .env.local
npm install
npm run dev
```

Frontend доступен на `http://localhost:3000`, админ-панель — на `http://localhost:3000/admin`, readiness API — на `http://localhost:8080/readyz`.

## Проверки

```bash
npm test
npm run lint
npm run typecheck
npm run backend:test
```

OpenAPI-контракт находится в `backend/openapi/openapi.yaml`, миграции — в `backend/migrations`, подробности backend — в `backend/README.md`.

## Бесплатный production deploy

Production-схема использует текущий Sites frontend, Go API на Render и PostgreSQL в Neon:

```text
Sites frontend -> /api/backend/* -> Render Go API -> Neon PostgreSQL
```

1. Создайте проект `learny` в Neon и скопируйте pooled connection string.
2. В Render создайте Blueprint из `render.yaml` и укажите секретные значения:
   - `DATABASE_URL` — pooled connection string Neon;
   - `LEARNY_BFF_SECRET` — один случайный секрет длиной не менее 32 символов;
   - `LEARNY_ADMIN_EMAILS` — email владельца Learny.
3. После первого успешного deploy скопируйте HTTPS URL Render.
4. В production environment Sites задайте `LEARNY_API_URL` и тот же `LEARNY_BFF_SECRET`, затем выполните новый deploy frontend.

`LEARNY_MIGRATE_ON_START=true` нужен для первого бесплатного deploy и безопасно повторно применяет только ещё не выполненные goose-миграции. После появления отдельного release step переменную следует переключить на `false`.
