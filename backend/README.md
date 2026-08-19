# Learny Go API

Go backend хранит дерево разделов и тем, уроки, вопросы, задачи, прогресс и мок-интервью iOS/Go в PostgreSQL. Browser обращается к нему через same-origin BFF Learny, поэтому секрет подписи не попадает в клиентский JavaScript.

## Локальный запуск

Из корня проекта:

```bash
docker compose up -d postgres
```

В отдельном терминале:

```bash
cd backend
cp .env.example .env
set -a && source .env && set +a
go run ./cmd/api
```

При `LEARNY_MIGRATE_ON_START=true` API применит миграции и загрузит базовый каталог. Проверка готовности: `GET http://localhost:8080/readyz`.

OpenAPI-контракт: `openapi/openapi.yaml`. Публичный каталог доступен через `GET /v1/catalog`. Защищённые endpoint прогресса, интервью, submissions и `/v1/admin/*` принимают только HMAC-подписанную идентичность от BFF.

## Безопасность

- production требует `LEARNY_BFF_SECRET` длиной не менее 32 символов;
- admin email задаётся через `LEARNY_ADMIN_EMAILS`;
- эталонные решения и скрытые тесты доступны только admin API;
- публичный каталог отдаёт только опубликованные материалы с опубликованными родителями;
- пользовательский код выполняется внешним sandbox runner, а не процессом API;
- `LEARNY_SUBMISSION_CONCURRENCY` ограничивает количество одновременных запусков на экземпляр API;
- production-миграции должны выполняться отдельным release step.

## Render + Neon

Корневой `render.yaml` создаёт бесплатный Docker Web Service в регионе Frankfurt. Для первого запуска в Render необходимо вручную задать `DATABASE_URL`, `LEARNY_BFF_SECRET` и `LEARNY_ADMIN_EMAILS`; значения не хранятся в Git.

Для Neon используйте pooled connection string с обязательным TLS (`sslmode=require`). Readiness probe Render настроен на `/readyz`. Render автоматически задаёт `PORT`, поэтому отдельная production-настройка порта не требуется.
