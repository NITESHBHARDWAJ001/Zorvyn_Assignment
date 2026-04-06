# Admin Bootstrap Endpoint Guide

## Overview

The `/admin/bootstrap` endpoint provides a manual way to create the initial admin account. This is useful when:
- Automatic bootstrap is disabled (`BOOTSTRAP_ADMIN=false`)
- Initial startup failed before creating admin
- You need to recreate admin account after deletion
- You're setting up in a new environment

---

## Endpoint Details

**URL**: `POST /admin/bootstrap`  
**Authentication**: Not required (public endpoint)  
**Rate Limit**: Yes (200 requests/15 minutes applies)

---

## Configuration Requirements

Before calling this endpoint, ensure these environment variables are set in `.env`:

```env
BOOTSTRAP_ADMIN_NAME="System Admin"
BOOTSTRAP_ADMIN_EMAIL="admin@example.com"
BOOTSTRAP_ADMIN_PASSWORD="StrongPassword123!"
```

**Validation Rules**:
- `BOOTSTRAP_ADMIN_NAME`: Required, 2-80 characters
- `BOOTSTRAP_ADMIN_EMAIL`: Required, valid email format
- `BOOTSTRAP_ADMIN_PASSWORD`: Required, minimum 8 characters

---

## Usage Examples

### Success: Creating Admin (201)

**Request**:
```bash
curl -X POST http://localhost:4000/admin/bootstrap \
  -H "Content-Type: application/json"
```

**Response** (201 Created):
```json
{
  "success": true,
  "message": "Bootstrap admin account created.",
  "data": {
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "System Admin",
      "email": "admin@example.com",
      "role": "ADMIN",
      "isActive": true,
      "createdAt": "2026-04-04T09:33:25.230Z",
      "updatedAt": "2026-04-04T09:33:25.230Z"
    }
  }
}
```

**Next Step**: Use the email/password to login and receive JWT token

### Error: Missing Environment Variables (400)

**Scenario**: One or more env vars missing in `.env`

**Response** (400 Bad Request):
```json
{
  "success": false,
  "message": "BOOTSTRAP_ADMIN is enabled, but BOOTSTRAP_ADMIN_NAME, BOOTSTRAP_ADMIN_EMAIL, and BOOTSTRAP_ADMIN_PASSWORD are required.",
  "code": "BOOTSTRAP_CONFIG_ERROR"
}
```

**Solution**:
```bash
# Update .env with all three values
BOOTSTRAP_ADMIN_NAME="System Admin"
BOOTSTRAP_ADMIN_EMAIL="admin@example.com"
BOOTSTRAP_ADMIN_PASSWORD="StrongPassword123!"

# Retry endpoint
curl -X POST http://localhost:4000/admin/bootstrap
```

### Error: Invalid Password (400)

**Scenario**: Password < 8 characters

**Response** (400 Bad Request):
```json
{
  "success": false,
  "message": "Bootstrap admin password must be at least 8 characters",
  "code": "INVALID_PASSWORD"
}
```

**Solution**: Update `.env` with password ≥ 8 characters

```env
BOOTSTRAP_ADMIN_PASSWORD="StrongPassword123!"  # >= 8 chars
```

### Error: Admin Already Exists (409)

**Scenario**: Admin account already created

**Response** (409 Conflict):
```json
{
  "success": false,
  "message": "An admin account already exists.",
  "code": "ADMIN_EXISTS"
}
```

**Solution**: This is normal and safe. Endpoint is idempotent - calling multiple times doesn't duplicate admin. If you need a different admin:
```bash
# Login as current admin
curl -X POST http://localhost:4000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "StrongPassword123!"
  }'

# Then use ADMIN role to create/manage other admins
```

### Error: Email Conflict (409)

**Scenario**: Bootstrap email used as non-admin account

**Response** (409 Conflict):
```json
{
  "success": false,
  "message": "Bootstrap admin email already exists with a non-admin account. Resolve manually to prevent unsafe privilege changes.",
  "code": "EMAIL_CONFLICT"
}
```

**Solution**: Choose different bootstrap email or delete conflicting user

```bash
# Option 1: Update .env with different email
BOOTSTRAP_ADMIN_EMAIL="admin-new@example.com"

# Option 2: Manual cleanup (as existing admin)
curl -X PATCH http://localhost:4000/users/{conflicting-user-id} \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "isActive": false }'
```

---

## Swagger UI Testing

### Step 1: Navigate to Swagger UI
Open browser: `http://localhost:4000/api-docs`

### Step 2: Find Admin Operations
Scroll to **"Admin Operations"** section, expand **POST /admin/bootstrap**

### Step 3: Click "Try it out"
Button location: Right side of endpoint description

### Step 4: Execute Request
- No request body needed
- Click blue **"Execute"** button
- Response shown below

### Step 5: Verify Success
Look for **201 Created** response with admin user data

---

## Workflow: Using Bootstrap to Setup System

### Scenario: Fresh Database, No Admin

**Steps**:

1. **Ensure .env configured**
```env
NODE_ENV=development
PORT=4000
DATABASE_URL="postgresql://postgres:password@localhost:5432/finance_dashboard?schema=public"
JWT_SECRET="your-secret-key-min-16-chars"
BOOTSTRAP_ADMIN_NAME="System Admin"
BOOTSTRAP_ADMIN_EMAIL="admin@localhost.com"
BOOTSTRAP_ADMIN_PASSWORD="AdminPass123!"
```

2. **Database ready** (schema applied)
```bash
npm run prisma:migrate
```

3. **Start server** (skips automatic bootstrap if disabled)
```bash
npm run dev
```

4. **Call bootstrap endpoint**
```bash
curl -X POST http://localhost:4000/admin/bootstrap
```

5. **Verify response** (should get 201 with admin data)

6. **Login as admin**
```bash
curl -X POST http://localhost:4000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@localhost.com",
    "password": "AdminPass123!"
  }'
```

7. **Copy JWT token** from response
```
{
  "data": {
    "token": "eyJhbGc..."
  }
}
```

8. **Create other users** as admin
```bash
curl -X POST http://localhost:4000/users \
  -H "Authorization: Bearer eyJhbGc..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Analyst User",
    "email": "analyst@example.com",
    "password": "AnalystPass123!",
    "role": "ANALYST"
  }'
```

9. **Application ready** - Users can register and login

---

## Bootstrap Modes

### Mode 1: Automatic Bootstrap (On Server Startup)

**When**: `BOOTSTRAP_ADMIN=true` in `.env`

**Behavior**:
- Server calls bootstrap during startup
- Creates admin if none exists
- Silently skips if admin already exists
- Fails startup with error if misconfigured

**Logs**:
```
Bootstrap admin account created.
Finance backend running on port 4000
```

### Mode 2: Disabled Bootstrap (Manual Only)

**When**: `BOOTSTRAP_ADMIN=false` in `.env`

**Behavior**:
- Server startup doesn't create admin
- Must manually call `/admin/bootstrap` endpoint
- Env vars still required for endpoint

**Use Case**: Production systems where admin created via separate process

### Mode 3: Already Exists (Idempotent)

**Behavior**:
- Calling `/admin/bootstrap` multiple times always safe
- Returns 409 after first creation
- Never overwrites or duplicates admin

---

## Security Considerations

### Public Endpoint
The `/admin/bootstrap` endpoint is intentionally **not authenticated** to allow initial system setup. In production:

**Option 1: Restrict Network Access**
```bash
# Only allow from localhost or internal network
firewall allow port 4000 from 10.0.0.0/8
```

**Option 2: Remove Endpoint After Setup**
Comment out in `src/routes/adminRoutes.js`:
```javascript
// Uncomment only during initial setup
// router.post('/bootstrap', bootstrapAdminAccount);
```

**Option 3: Add Request Signature Validation**
```javascript
// Verify request comes from trusted source (production enhancement)
router.post('/bootstrap', validateSetupKey, bootstrapAdminAccount);
```

---

## Troubleshooting

### Issue: 404 "Route not found"
- Verify server running: `curl http://localhost:4000/health`
- Check app.js mounts admin routes: `app.use('/admin', adminRoutes)`
- Restart server after code changes

### Issue: Still getting 409 but want new admin
- Admin account is idempotent (security feature)
- If you need different admin, delete current admin as system admin (requires DB access)
- Or create additional admin via `/users` endpoint

### Issue: 500 Error on Bootstrap
- Check server logs for detailed error
- Verify PostgreSQL running and DATABASE_URL correct
- Ensure migrations applied: `npm run prisma:migrate`
- Check .env variables for typos

### Issue: Endpoint Works in Swagger but not with curl
- Verify Content-Type header: `-H "Content-Type: application/json"`
- Check URL matches: `POST /admin/bootstrap` not `POST /api/admin/bootstrap`
- Verify rate limit not exceeded (200 req/15 min)

---

## Related Documentation

- **Database Setup**: See [DATABASE_SETUP.md](DATABASE_SETUP.md)
- **Error Handling**: See [ERROR_HANDLING.md](ERROR_HANDLING.md)
- **API Reference**: See [API_REFERENCE.md](API_REFERENCE.md)
- **Architecture**: See [ARCHITECTURE.md](ARCHITECTURE.md)

---

**Last Updated**: April 4, 2026
