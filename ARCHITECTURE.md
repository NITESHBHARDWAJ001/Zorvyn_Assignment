# Backend System Documentation

## Overview

This document covers the complete Finance Dashboard backend system, including architecture, testing, migrations, and deployment.

## Architecture

### Clean Architecture Layers

1. **Routes** (`src/routes/`) - Express route handlers
2. **Controllers** (`src/controllers/`) - Request/response orchestration
3. **Services** (`src/services/`) - Business logic and data access
4. **Middleware** (`src/middleware/`) - Auth, validation, error handling
5. **Utils** (`src/utils/`) - Helpers, error classes, JWT
6. **Config** (`src/config/`) - Environment and Prisma setup

### Database Models

- **User**: Authentication and RBAC (id, name, email, passwordHash, role, isActive)
- **Transaction**: Financial records (id, userId, amount, type, category, date, notes, isDeleted)

Indexes on `userId`, `date`, `category` for query performance.

## Database Migrations

### Location

`prisma/migrations/0_init/migration.sql` - Initial schema with:
- User and Transaction tables
- Role and TransactionType enums
- Foreign key relationships (cascading delete)
- Timestamps and soft-delete support

### Running Migrations

```bash
# Generate Prisma client
npm run prisma:generate

# Create and apply migration (development)
npm run prisma:migrate -- --name init

# Verify schema is applied
npx prisma db push
```

### Schema Definition

See [prisma/schema.prisma](prisma/schema.prisma) for the Prisma ORM model definitions.

## Testing Strategy

### Test Structure (7 test suites, 38 tests)

#### 1. **auth.test.js** (4 tests)
- Register success
- Register failure (duplicate email)
- Login success
- Login failure (invalid credentials, inactive user)
- Password validation edge cases

#### 2. **rbac.test.js** (3 tests)
- Unauthorized access blocked without token
- Role-based permissions enforced
- VIEWER cannot access ANALYST/ADMIN routes

#### 3. **transactions.test.js** (4 tests)
- Create transaction
- Validation error for negative amount
- Filtering works with category, type, pagination

#### 4. **dashboard.test.js** (2 tests)
- Summary calculations correct
- Empty dataset handling

#### 5. **userManagement.test.js** (9 tests)
- Admin can create user with role assignment
- Non-admin cannot create user
- Admin can list all users
- User cannot update other users
- User can self-update name
- User cannot escalate own role
- Admin cannot deactivate self
- Admin can deactivate other users
- Duplicate email rejected

#### 6. **transactionFiltering.test.js** (8 tests)
- Create transaction with all fields
- Update transaction
- Delete transaction (soft delete)
- Cannot update deleted transaction
- Filter by date range
- Viewer cannot create/update transactions
- Transactions inaccessible without auth
- Invalid UUID validation

#### 7. **analyticsEdgeCases.test.js** (8 tests)
- Summary with multiple categories
- Trends with multiple months
- Trends handles empty data
- Viewer cannot access analytics
- Recent transactions included in summary

### Mocking Strategy

- **Prisma mocking**: All database calls mocked with Jest
- **No database required** for tests
- **Post requests** include POST, PATCH, PUT, DELETE, GET validation

### Running Tests

```bash
# Run all tests
npm test

# Watch mode (development)
npx jest --watch

# Coverage report
npx jest --coverage
```

### Test Results

All tests use Supertest for HTTP assertions:

```
Test Suites: 7 passed, 7 total
Tests:       38 passed, 38 total
Time:        ~4s
```

## API Validation

### Validation Layers

1. **Middleware**: `validate()` applies Zod schemas to `body`, `query`, `params`
2. **Schemas**: Located in `src/utils/validationSchemas.js`
3. **Error Response**: 400 with detailed error messages

### Common Validation Rules

- Email: valid format, unique constraints
- Password: 8-72 characters
- Amount: positive numbers only
- UUID: valid v4 format
- Date: ISO 8601 format
- Enums: strict type checking (INCOME/EXPENSE, VIEWER/ANALYST/ADMIN)

## Security Features

1. **JWT Authentication**: Token-based auth with expiry
2. **RBAC**: Role-based access control
3. **Password Hashing**: bcrypt with salt 12
4. **Rate Limiting**: 200 requests per 15 minutes
5. **Helmet**: Security headers (CSP, XSS protection, etc.)
6. **CORS**: Configurable origin allowlist
7. **Input Sanitization**: Removes `<>` characters
8. **SQL Injection Prevention**: Prisma parameterized queries
9. **Soft Deletes**: Non-destructive record removal
10. **Role Escalation Prevention**: Non-admins cannot assign roles or change status
11. **Self-deactivation Block**: Admin cannot deactivate themselves

## API Endpoints

### Authentication

```
POST /auth/register
POST /auth/login
```

### User Management (RBAC)

```
GET /users                 (ADMIN)
POST /users                (ADMIN)
PATCH /users/:id           (self-update allowed, role/status ADMIN only)
```

### Transactions

```
GET /transactions          (VIEWER, ANALYST, ADMIN)
POST /transactions         (ADMIN)
PUT /transactions/:id      (ADMIN)
DELETE /transactions/:id   (ADMIN, soft delete)
```

Query filters: `dateFrom`, `dateTo`, `category`, `type`, `limit`, `offset`

### Dashboard Analytics

```
GET /dashboard/summary     (ANALYST, ADMIN)
GET /dashboard/trends      (ANALYST, ADMIN)
```

## Environment Configuration

### Required Variables

```env
NODE_ENV=development
PORT=4000
DATABASE_URL="postgresql://user:password@host:5432/database"
JWT_SECRET="min-16-character-secret"
JWT_EXPIRES_IN="1h"
CORS_ORIGIN="http://localhost:3000"
```

### Bootstrap Admin (Optional)

```env
BOOTSTRAP_ADMIN="true"
BOOTSTRAP_ADMIN_NAME="System Admin"
BOOTSTRAP_ADMIN_EMAIL="admin@example.com"
BOOTSTRAP_ADMIN_PASSWORD="StrongPassword123!"
```

When `BOOTSTRAP_ADMIN=true` and no ADMIN exists, one is created on startup.

## Deployment Checklist

- [ ] Database created and accessible
- [ ] `.env` configured with valid credentials
- [ ] `npm install` completed
- [ ] `npm run prisma:generate` executed
- [ ] `npm run prisma:migrate` applied
- [ ] `npm test` passes (all 38 tests)
- [ ] `npm start` launches without errors
- [ ] Admin user created via bootstrap or manual registration
- [ ] Test login to verify auth flow

## Error Handling

All errors follow this standardized format:

```json
{
  "success": false,
  "message": "Human-readable error message",
  "code": "ERROR_CODE",
  "errors": [
    { "path": "field.name", "message": "validation message" }
  ]
}
```

Common HTTP status codes:
- 200: Success
- 201: Created
- 400: Validation error
- 401: Authentication required
- 403: Authorization failed (role check)
- 404: Resource not found
- 409: Conflict (duplicate email)
- 500: Server error

## Development Workflow

```bash
# 1. Setup
npm install
cp .env.example .env
# Edit .env with actual values

# 2. Database
npm run prisma:generate
npm run prisma:migrate -- --name init

# 3. Development server
npm run dev
# Server runs on http://localhost:4000

# 4. Testing
npm test
npx jest --watch

# 5. Production build
npm start
```

## Notes

- Transactions are soft-deleted (never truly removed)
- Bootstrap seeding is safe and disabled by default
- All timestamps use UTC
- Pagination uses limit/offset pattern
- Analytics uses SQL aggregation for performance
- Database connection pooling handled by Prisma
