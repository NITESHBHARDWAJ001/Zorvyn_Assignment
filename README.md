# Finance Dashboard Backend

Production-grade backend API for a Finance Dashboard built with Node.js, Express, PostgreSQL, and Prisma.

## Stack

- Node.js + Express
- PostgreSQL + Prisma ORM
- JWT authentication
- RBAC authorization (VIEWER, ANALYST, ADMIN)
- Zod validation
- bcrypt password hashing
- Jest + Supertest unit tests

## Project Structure

src/
controllers/
routes/
services/
middleware/
utils/
config/
prisma/
tests/
app.js
server.js

## Features

- Auth: register/login with JWT and bcrypt
- RBAC: role-based guards and role escalation prevention
- User management: admin create/list/update users, activate/deactivate support
- Transactions: create/read/update/soft-delete with strict validation and filters
- Dashboard analytics: summary and trends APIs with safe empty-data behavior
- Security: helmet, rate limiting, CORS, request sanitization
- Error handling: centralized middleware and consistent responses

## API Routes

### Auth

- POST /auth/register
- POST /auth/login

### Users

- GET /users (ADMIN)
- POST /users (ADMIN)
- PATCH /users/:id (self update allowed, role/status changes ADMIN only)

### Transactions

- POST /transactions (ADMIN)
- GET /transactions (VIEWER, ANALYST, ADMIN)
- PUT /transactions/:id (ADMIN)
- DELETE /transactions/:id (ADMIN, soft delete)

### Dashboard

- GET /dashboard/summary (ANALYST, ADMIN)
- GET /dashboard/trends (ANALYST, ADMIN)

## Setup

**Prerequisites:**
- Node.js 16+
- PostgreSQL 12+ (running locally or via Docker)
- Account/credentials for PostgreSQL

### Step-by-Step

1. Install dependencies:

```bash
npm install
```

2. Create `.env` from template:

```bash
copy .env.example .env
```

3. **IMPORTANT: Update DATABASE_URL in `.env`**

Edit `.env` and set your PostgreSQL credentials:

```env
DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@localhost:5432/finance?schema=public"
```

Replace:
- `YOUR_PASSWORD`: Your PostgreSQL password
- `postgres`: Your PostgreSQL user (if different)

**Don't have PostgreSQL?** See [DATABASE_SETUP.md](DATABASE_SETUP.md) for installation & creation steps.

4. Generate Prisma client:

```bash
npm run prisma:generate
```

5. **Create database schema** (creates User & Transaction tables):

```bash
npm run prisma:migrate -- --name init
```

This applies migrations from `prisma/migrations/0_init/migration.sql`

6. Start server:

```bash
npm run dev
```

Server runs on http://localhost:4000

**✓ Now you're ready!** See next section for testing.

## Setup Modes

### Local (Node + external PostgreSQL)

1. Configure `.env` with your database URL and secrets.
2. Run `npm run prisma:generate`.
3. Run `npm run prisma:migrate -- --name init`.
4. Start the server with `npm run dev`.

### Docker (single container)

1. Build image: `docker build -t finance-dashboard:latest .`
2. Run with env file: `docker run --rm -p 4000:4000 --env-file .env finance-dashboard:latest`

### Docker Compose (app + database)

1. Ensure `.env` is populated.
2. Run: `docker compose up --build`
3. The container startup script handles Prisma sync based on `PRISMA_DB_SYNC_STRATEGY`.

## Interactive API Documentation (Swagger UI)

Once the server is running, access interactive API docs:

```
http://localhost:4000/api-docs
```

Features:
- **Try it out**: Test all endpoints directly in browser
- **Schema validation**: See request/response formats
- **Authentication**: Paste JWT token to test protected endpoints
- **Live examples**: Pre-filled request bodies with sample data
- **Full endpoint reference**: All 13 endpoints documented

See [SWAGGER_UI_GUIDE.md](SWAGGER_UI_GUIDE.md) for detailed usage instructions.

## Quick Verification

After setup, verify everything works:

**Step 1: Register a test user**
```bash
curl -X POST http://localhost:4000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "Password123!"
  }'
```

Expected response (201 Created):
```json
{
  "success": true,
  "data": {
    "user": { "id": "...", "email": "test@example.com", "role": "VIEWER" },
    "token": "eyJhbG..."
  }
}
```

**Step 2: Use token in subsequent requests**

Copy the token from above, then test transactions:
```bash
curl http://localhost:4000/transactions \
  -H "Authorization: Bearer <your_token_here>"
```

**Step 3: Visit Swagger UI**

Open browser: `http://localhost:4000/api-docs`

Paste token in **Authorize** dialog and test endpoints interactively.

**✓ If all above works, your backend is fully functional!**

See [API_REFERENCE.md](API_REFERENCE.md) for complete curl examples.

## Testing

Run comprehensive unit tests:

```bash
npm test
```

**Full test coverage: 7 test suites, 38 tests**

Tests include:
- **Auth**: Register/login success/failure, password validation
- **RBAC**: Permission checks, role-based access control
- **Transactions**: CRUD operations, filtering (date/category/type), validation, soft delete
- **Dashboard**: Summary calculations, multi-month trends, empty data handling
- **User Management**: Create, list, update, deactivate, role escalation prevention
- **Transaction Filtering**: Date ranges, pagination, ownership validation
- **Analytics Edge Cases**: Multiple categories, monthly trends, data safety

All tests mock Prisma and require no database connection.

## Migrations

Database migrations are stored in `prisma/migrations/`:

- **Location**: `prisma/migrations/0_init/migration.sql`
- **Status**: Initial schema with User and Transaction tables
- **Indexes**: UserId, date, category for query performance
- **Relationships**: Foreign key from Transaction to User with cascading delete

To create new migrations:
```bash
npm run prisma:migrate -- --name name_of_migration
```

## Notes

- Transactions are soft-deleted via `isDeleted`.
- Prisma protects against SQL injection by parameterized queries.
- Tokens expire based on `JWT_EXPIRES_IN`.
- Bootstrap seeding is safe-by-default and disabled unless `BOOTSTRAP_ADMIN="true"`.

## Assumptions

- Backend is API-first and consumed by a separate frontend.
- JWT bearer authentication is sufficient for assignment scope.
- Role model is fixed to `VIEWER`, `ANALYST`, `ADMIN`.
- Currency is represented as decimal numbers in the database.
- Soft-delete behavior is preferred over hard delete for transactions.
- PostgreSQL is available in local, Docker, or managed-hosted mode.

## Tradeoffs

- Used stateless JWT auth instead of session storage for simpler deployment.
- Used role-based guards (RBAC) instead of fine-grained policy engine to keep logic clear.
- Used Prisma ORM for reliability and maintainability over raw SQL-heavy code.
- Added `migrate-then-push` startup fallback to improve deployment resilience; this trades stricter migration history enforcement for uptime in constrained environments.
- Prioritized clear service-layer structure and deterministic validations over adding advanced features like refresh tokens and full-text search.

## Documentation Map

- Architecture: `ARCHITECTURE.md`
- Deployment and Docker: `documentation/DOCKER_DEPLOYMENT.md`
- API endpoint examples: `API_REFERENCE.md`
- Swagger usage: `SWAGGER_UI_GUIDE.md`
- Error behavior and fallbacks: `ERROR_HANDLING.md`
- Database setup and migrations: `DATABASE_SETUP.md`
