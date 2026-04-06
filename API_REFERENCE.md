# API Quick Reference

## Base URL
```
http://localhost:4000
```

## Authentication
All endpoints except `/auth/*` require JWT token in header:
```
Authorization: Bearer <token>
```

Copy the token from `/auth/login` or `/auth/register` response.

---

## 📋 Common Operations

### Register & Login

**Register**
```bash
curl -X POST http://localhost:4000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "Password123!"
  }'
```

Response:
```json
{
  "success": true,
  "data": {
    "user": { "id": "uuid", "name": "John Doe", "email": "john@example.com", "role": "VIEWER" },
    "token": "eyJhbG..."
  }
}
```

**Login**
```bash
curl -X POST http://localhost:4000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "Password123!"
  }'
```

---

### Transactions

**Create Transaction** (ADMIN)
```bash
curl -X POST http://localhost:4000/transactions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "amount": 1500,
    "type": "income",
    "category": "Salary",
    "date": "2026-04-04T10:00:00Z",
    "notes": "Monthly salary"
  }'
```

**Get Transactions** (with filters)
```bash
# All transactions
curl http://localhost:4000/transactions \
  -H "Authorization: Bearer <token>"

# Filter by category
curl "http://localhost:4000/transactions?category=Groceries" \
  -H "Authorization: Bearer <token>"

# Filter by date range
curl "http://localhost:4000/transactions?dateFrom=2026-04-01&dateTo=2026-04-30" \
  -H "Authorization: Bearer <token>"

# Pagination
curl "http://localhost:4000/transactions?limit=10&offset=20" \
  -H "Authorization: Bearer <token>"
```

**Update Transaction** (ADMIN)
```bash
curl -X PUT http://localhost:4000/transactions/{id} \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "amount": 1600,
    "notes": "Salary increased"
  }'
```

**Delete Transaction** (ADMIN, soft delete)
```bash
curl -X DELETE http://localhost:4000/transactions/{id} \
  -H "Authorization: Bearer <token>"
```

---

### Dashboard Analytics (ANALYST, ADMIN)

**Summary**
```bash
curl http://localhost:4000/dashboard/summary \
  -H "Authorization: Bearer <token>"
```

Response:
```json
{
  "success": true,
  "data": {
    "totalIncome": 5000,
    "totalExpenses": 1200,
    "netBalance": 3800,
    "categoryTotals": [
      { "category": "Salary", "total": 5000 },
      { "category": "Groceries", "total": 500 }
    ],
    "recentTransactions": [...]
  }
}
```

**Trends** (monthly)
```bash
curl http://localhost:4000/dashboard/trends \
  -H "Authorization: Bearer <token>"
```

Response:
```json
{
  "success": true,
  "data": {
    "monthly": [
      { "month": "2026-01", "income": 3000, "expenses": 1000, "net": 2000 },
      { "month": "2026-02", "income": 3500, "expenses": 1200, "net": 2300 }
    ]
  }
}
```

---

### User Management (ADMIN)

**Create User**
```bash
curl -X POST http://localhost:4000/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <admin-token>" \
  -d '{
    "name": "Jane Analyst",
    "email": "jane@example.com",
    "password": "Password123!",
    "role": "ANALYST"
  }'
```

**List Users**
```bash
curl http://localhost:4000/users \
  -H "Authorization: Bearer <admin-token>"
```

**Update User**
```bash
# Admin updates another user
curl -X PATCH http://localhost:4000/users/{id} \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <admin-token>" \
  -d '{
    "role": "ANALYST",
    "isActive": true
  }'

# User updates self (name/email/password only)
curl -X PATCH http://localhost:4000/users/{id} \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <user-token>" \
  -d '{
    "name": "Updated Name",
    "email": "newemail@example.com"
  }'
```

---

## 📊 Status Codes

| Code | Meaning | Example |
|------|---------|---------|
| 200 | Success | GET request succeeded |
| 201 | Created | POST created resource |
| 400 | Bad Request | Validation failed |
| 401 | Unauthorized | Missing/invalid token |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Email already exists |
| 500 | Server Error | Unexpected error |

---

## 🛡️ Role Permissions

| Endpoint | VIEWER | ANALYST | ADMIN |
|----------|--------|---------|-------|
| GET /transactions | ❌ | ✓ | ✓ |
| POST /transactions | ❌ | ❌ | ✓ |
| PUT /transactions/:id | ❌ | ❌ | ✓ |
| DELETE /transactions/:id | ❌ | ❌ | ✓ |
| GET /dashboard/summary | ❌ | ✓ | ✓ |
| GET /dashboard/trends | ❌ | ✓ | ✓ |
| GET /users | ❌ | ❌ | ✓ |
| POST /users | ❌ | ❌ | ✓ |
| PATCH /users/:id (self) | ✓* | ✓* | ✓* |
| PATCH /users/:id (others) | ❌ | ❌ | ✓ |

*Can only update name, email, password. Cannot change role or isActive.

---

## 🔗 Test with Swagger UI

**Easiest way to test all endpoints interactively:**

```
http://localhost:4000/api-docs
```

- Click **Authorize** → paste token
- Select endpoint → **Try it out** → see response
- Pre-filled example requests ready to use

---

## 🔐 Common Errors & Solutions

### 401 Unauthorized
**Problem**: Missing or invalid token
```json
{ "success": false, "message": "Missing authentication token", "code": "AUTH_REQUIRED" }
```
**Solution**: 
1. Login first: `POST /auth/login`
2. Copy token from response
3. Add header: `Authorization: Bearer <token>`

### 403 Forbidden
**Problem**: User doesn't have permission for endpoint
```json
{ "success": false, "message": "Insufficient permissions", "code": "FORBIDDEN" }
```
**Solution**: Only ADMIN can create/update transactions. Other roles can only view.

### 409 Conflict
**Problem**: Email already registered
```json
{ "success": false, "message": "Email already registered", "code": "DUPLICATE_EMAIL" }
```
**Solution**: Use a different email or login with existing account.

### 400 Validation Error
**Problem**: Invalid request body
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    { "path": "amount", "message": "Number must be greater than 0" }
  ]
}
```
**Solution**: Check field types and constraints. See Swagger UI for schema.

---

## 💡 Pro Tips

1. **Use Swagger UI for learning**: Better than curl for seeing all endpoints
2. **Test with different roles**: Create TEST_VIEWER, TEST_ANALYST, TEST_ADMIN users
3. **Date filtering**: Use ISO 8601 format: `2026-04-04T10:00:00Z`
4. **Pagination**: Default `limit=20`, use `offset` for next page
5. **Soft deletes**: Deleted transactions not shown in GET requests, but can verify with DB

---

## 📚 Documentation Files

- [README.md](README.md) - Quick start guide
- [ARCHITECTURE.md](ARCHITECTURE.md) - System design & testing
- [SWAGGER_UI_GUIDE.md](SWAGGER_UI_GUIDE.md) - Interactive API docs guide
- [DEPLOYMENT.md](DEPLOYMENT.md) - Deployment checklist

---

**Last Updated**: April 4, 2026
