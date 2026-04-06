# Database Setup Guide

## Problem
You're seeing this error:
```
The table `public.User` does not exist in the current database.
```

This means PostgreSQL is running, but the database schema (tables) hasn't been created yet.

## Solution

### Step 1: Verify PostgreSQL is Running

**Windows Command Prompt:**
```bash
pg_isready -h localhost -p 5432
```

Expected output:
```
accepting connections
```

If PostgreSQL isn't running:
- Start PostgreSQL service or use pgAdmin
- Or use Docker: `docker run --name postgres -e POSTGRES_PASSWORD=password -p 5432:5432 -d postgres`

### Step 2: Create the Database

**Using psql (command line):**
```bash
psql -U postgres -h localhost -c "CREATE DATABASE finance;"
```

**Or using pgAdmin (GUI):**
1. Open pgAdmin
2. Right-click **Databases** → Create → Database
3. Name: `finance`
4. Click Save

### Step 3: Copy Environment File

```bash
copy .env.example .env
```

### Step 4: Update .env with Your PostgreSQL Credentials

Edit `e:\finanace_assn\.env`:

```env
DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@localhost:5432/finance?schema=public"
```

Replace `YOUR_PASSWORD` with your PostgreSQL password.

**Common credentials:**
- User: `postgres` (default)
- Password: What you set during PostgreSQL installation
- Host: `localhost`
- Port: `5432`
- Database: `finance` (created above)

### Step 5: Generate Prisma Client

```bash
npm run prisma:generate
```

### Step 6: Apply Migrations (Create Tables)

**Option A: Interactive migration:**
```bash
npm run prisma:migrate -- --name init
```

This will:
- Create User and Transaction tables
- Add indexes
- Set up enums
- Establish foreign keys

**Option B: Push schema directly (development only):**
```bash
npx prisma db push
```

### Step 7: Verify Success

```bash
npx prisma studio
```

This opens Prisma Studio where you can see:
- User table (empty)
- Transaction table (empty)

### Step 8: Restart Server & Test

```bash
npm run dev
```

Now test registration:
```bash
curl -X POST http://localhost:4000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "Password123!"
  }'
```

Should return 201 Created with user data.

---

## Quick Setup Command Sequence

```bash
# 1. Copy environment file
copy .env.example .env

# 2. Update .env with your PostgreSQL password

# 3. Generate Prisma client
npm run prisma:generate

# 4. Apply migrations (creates tables)
npm run prisma:migrate -- --name init

# 5. Start server
npm run dev

# 6. Test in another terminal
curl -X POST http://localhost:4000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com","password":"Password123!"}'
```

---

## Troubleshooting

### "Connection refused" Error
**Problem**: PostgreSQL isn't running
```
Error: connect ECONNREFUSED 127.0.0.1:5432
```
**Solution**: Start PostgreSQL service

### "Database does not exist" Error
```
Error: database "finance" does not exist
```
**Solution**: Create database:
```bash
psql -U postgres -h localhost -c "CREATE DATABASE finance;"
```

### "Authentication failed" Error
```
Error: password authentication failed for user "postgres"
```
**Solution**: Check DATABASE_URL in .env - verify password is correct

### "Permission denied" Error
```
Error: permission denied for schema public
```
**Solution**: 
```bash
psql -U postgres -d finance -c "GRANT ALL ON SCHEMA public TO postgres;"
```

### Still Getting "Table does not exist"
```bash
# Reset everything
npx prisma migrate reset

# Or manually apply schema
npx prisma db push --force-reset
```

---

## After Setup: Using Swagger UI

Once database is ready and server is running:

1. Open browser: `http://localhost:4000/api-docs`
2. Test endpoints interactively
3. See responses in real-time

See [SWAGGER_UI_GUIDE.md](../SWAGGER_UI_GUIDE.md) for testing instructions.

---

## Database Connection Info

**From .env in project:**
- **Host**: localhost
- **Port**: 5432
- **User**: postgres
- **Password**: [your password]
- **Database**: finance
- **Schema**: public

**Verify connection:**
```bash
psql -U postgres -h localhost -d finance -c "\dt"
```

Should show output like:
```
                List of relations
 Schema |    Name     | Type  |  Owner
--------+-------------+-------+----------
 public | Transaction | table | postgres
 public | User        | table | postgres
```

---

## Next Steps

✅ Database running
✅ Schema created
✅ Environment configured
→ Run `npm run dev` to start server
→ Visit `http://localhost:4000/api-docs` for Swagger UI
→ Test endpoints interactively
