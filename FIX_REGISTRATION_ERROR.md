# FIX: Database Setup - Registration Error

## The Problem
```
The table `public.User` does not exist in the current database.
```

You're trying to register but the database schema hasn't been created.

## Quick Fix (5 Minutes)

### 1. Check PostgreSQL is Running

Open Command Prompt and test:
```bash
psql -U postgres -h localhost -c "SELECT version();"
```

If you get an error, PostgreSQL isn't running. Start it:
- **Windows Service**: Services → PostgreSQL → Start
- **pgAdmin**: Open and start server
- **Docker**: `docker run --name postgres -e POSTGRES_PASSWORD=password -p 5432:5432 -d postgres`

### 2. Create the Database

```bash
psql -U postgres -h localhost -c "CREATE DATABASE finance;"
```

### 3. Update `.env` File

Open `e:\finanace_assn\.env` and update:

```env
DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@localhost:5432/finance?schema=public"
```

Replace `YOUR_PASSWORD` with your actual PostgreSQL password.

**Example:**
```env
DATABASE_URL="postgresql://postgres:password123@localhost:5432/finance?schema=public"
```

### 4. Run the Magic Commands

```bash
cd e:\finanace_assn

# Generate Prisma client
npm run prisma:generate

# Create all tables in database
npm run prisma:migrate -- --name init
```

You should see:
```
✅ migrations/0_init migration applied
✅ Generated Prisma Client
```

### 5. Start the Server

```bash
npm run dev
```

### 6. Test Registration

Open new Command Prompt and run:

```bash
curl -X POST http://localhost:4000/auth/register ^
  -H "Content-Type: application/json" ^
  -d "{\"name\":\"Test\",\"email\":\"test@example.com\",\"password\":\"Password123!\"}"
```

**If you see 201 Created with user data → SUCCESS! ✅**

---

## Still Getting the Error?

### Issue: "database finance does not exist"
```bash
# Create it
psql -U postgres -h localhost -c "CREATE DATABASE finance;"
```

### Issue: "password authentication failed"
Your PostgreSQL password is wrong. Check:
1. What password you set during PostgreSQL install
2. Update `.env` with correct password
3. Test connection: `psql -U postgres -h localhost`

### Issue: "Connection refused"
PostgreSQL isn't running:
- Windows: Start PostgreSQL service
- Mac/Linux: `brew services start postgresql`
- Docker: `docker start postgres`

### Issue: Migrations fail with "already applied"
Someone ran migrations before. That's fine - verify tables exist:
```bash
# See schema status
npx prisma db push

# Or open Prisma Studio
npx prisma studio
```

---

## Verify Everything Worked

```bash
# Check database exists
psql -U postgres -h localhost -c "\l" | grep finance

# Check tables exist
psql -U postgres -h localhost -d finance -c "\dt"

# Should show:
#  public | User        | table
#  public | Transaction | table
```

---

## Complete Setup Checklist

- [ ] PostgreSQL installed and running
- [ ] Database `finance` created
- [ ] `.env` file exists with correct DATABASE_URL
- [ ] JWT_SECRET is set to something strong
- [ ] Ran `npm run prisma:generate`
- [ ] Ran `npm run prisma:migrate -- --name init`
- [ ] Server starts: `npm run dev`
- [ ] Registration works: `curl -X POST http://localhost:4000/auth/register ...`
- [ ] ✅ All done! Open `http://localhost:4000/api-docs`

---

## Next: Use the API

### Via Swagger UI (Easiest)
```
http://localhost:4000/api-docs
```
- Authorize with token
- Click "Try it out" on any endpoint
- Test interactively

### Via curl
```bash
# Register
curl -X POST http://localhost:4000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"User","email":"user@example.com","password":"Pass123!"}'

# Login (copy token from response)
curl -X POST http://localhost:4000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"Pass123!"}'

# Use token in requests
curl http://localhost:4000/transactions \
  -H "Authorization: Bearer <token_from_above>"
```

See [API_REFERENCE.md](API_REFERENCE.md) for all curl examples.

---

**Once you fix the database, everything else just works!** 🚀
