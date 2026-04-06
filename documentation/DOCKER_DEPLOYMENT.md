# Docker Deployment Guide

## Docker Compose (Recommended for Local Deployment)

Start the app and PostgreSQL together:

```bash
docker compose up --build
```

This starts:

- PostgreSQL on port `5432`
- The app on port `4000`
- Automatic Prisma migration deployment on app startup

The compose file reads the initial admin values from `.env` using these bootstrap keys:

- `BOOTSTRAP_ADMIN_NAME`
- `BOOTSTRAP_ADMIN_EMAIL`
- `BOOTSTRAP_ADMIN_PASSWORD`

If an admin already exists, bootstrap is skipped safely.

## Build

```bash
docker build -t finance-dashboard:latest .
```

## Run

The container expects the following environment variables:

- `DATABASE_URL`
- `JWT_SECRET`
- `PORT` (optional, defaults to `4000` in the app)
- `BOOTSTRAP_ADMIN` (optional)
- `BOOTSTRAP_ADMIN_NAME` (optional)
- `BOOTSTRAP_ADMIN_EMAIL` (optional)
- `BOOTSTRAP_ADMIN_PASSWORD` (optional)

Example:

```bash
docker run --rm -p 4000:4000 \
  -e DATABASE_URL="postgresql://postgres:password@host.docker.internal:5432/finance?schema=public" \
  -e JWT_SECRET="replace-with-a-strong-secret" \
  -e BOOTSTRAP_ADMIN=false \
  finance-dashboard:latest
```

## Startup Flow

The container entrypoint runs these steps before the app starts:

1. `prisma generate`
2. Prisma schema sync using `PRISMA_DB_SYNC_STRATEGY`
3. `npm start`

Supported `PRISMA_DB_SYNC_STRATEGY` values:

- `migrate`: run only `prisma migrate deploy`
- `push`: run only `prisma db push --accept-data-loss`
- `migrate-then-push`: try migrate first, fallback to push on failure (default)

This allows deployment to recover automatically from migration history issues while still preferring migration-based updates.

## Verification

- Open `/health` to verify the app is up.
- Open `/api-docs` to use Swagger UI.
- Call `POST /auth/login` with the bootstrap admin credentials to verify authentication.

## Notes

- The app container runs `prisma generate` and `prisma migrate deploy` on every startup.
- If you change the database schema, rebuild and restart the stack with `docker compose up --build`.
- Set `SWAGGER_SERVER_URLS` in `.env` to control which URLs appear in Swagger UI.
- Set `DATABASE_URL` in `.env` for both local Docker and production deployments.
- Keep `POSTGRES_USER`, `POSTGRES_PASSWORD`, and `POSTGRES_DB` in `.env` so Docker Compose can build the database connection string from environment values.
- Set `PRISMA_DB_SYNC_STRATEGY` in `.env` to choose migration mode during startup.
