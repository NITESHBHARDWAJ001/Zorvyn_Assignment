# Error Handling & Fallback Scenarios

This document covers all error cases, fallback strategies, and recovery paths across the Finance Dashboard backend.

---

## Authentication Module

### Registration Errors

#### 1. Duplicate Email

**Scenario**: User tries to register with email that already exists

**Error Response** (409):
```json
{
  "success": false,
  "message": "Email already registered",
  "code": "DUPLICATE_EMAIL"
}
```

**Fallback Actions**:
- Suggest user to login instead
- Offer "Forgot password" option
- Allow retry with different email

**Service Code**:
```javascript
if (existing) {
  throw new AppError('Email already registered', 409, 'DUPLICATE_EMAIL');
}
```

#### 2. Invalid Password Format

**Scenario**: Password < 8 characters or > 72 characters

**Error Response** (400):
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    { "path": "password", "message": "String must contain at least 8 character(s)" }
  ]
}
```

**Fallback**:
- Show password requirements to user
- Real-time validation on frontend

#### 3. Invalid Email Format

**Scenario**: Email doesn't match format

**Error Response** (400):
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    { "path": "email", "message": "Invalid email" }
  ]
}
```

### Login Errors

#### 1. User Not Found

**Scenario**: Email doesn't exist in database

**Error Response** (401):
```json
{
  "success": false,
  "message": "Invalid email or password",
  "code": "INVALID_CREDENTIALS"
}
```

**Fallback**:
- Don't reveal whether email exists (security)
- Suggest registration
- Show generic error message

#### 2. Incorrect Password

**Scenario**: Password doesn't match hash

**Error Response** (401):
```json
{
  "success": false,
  "message": "Invalid email or password",
  "code": "INVALID_CREDENTIALS"
}
```

**Fallback**:
- Generic message (don't reveal email exists)
- Offer "Forgot password"
- Limit login attempts (rate limiting)

#### 3. User Inactive

**Scenario**: User account deactivated by admin

**Error Response** (403):
```json
{
  "success": false,
  "message": "User account is deactivated",
  "code": "USER_INACTIVE"
}
```

**Fallback**:
- Contact admin to reactivate
- Show support contact

### Token Errors

#### 1. Missing Token

**Scenario**: No Authorization header provided

**Error Response** (401):
```json
{
  "success": false,
  "message": "Missing authentication token",
  "code": "AUTH_REQUIRED"
}
```

**Fallback**:
- Frontend redirects to login
- Store attempted URL for post-login redirect

#### 2. Expired Token

**Scenario**: Token past expiration time

**Error Response** (401):
```json
{
  "success": false,
  "message": "Token has expired",
  "code": "TOKEN_EXPIRED"
}
```

**Fallback**:
- Refresh token endpoint (implement if needed)
- Or require re-login

#### 3. Invalid Signature

**Scenario**: Token tampered with

**Error Response** (401):
```json
{
  "success": false,
  "message": "Invalid authentication token",
  "code": "INVALID_TOKEN"
}
```

**Fallback**:
- Security event: log attempt
- Redirect to login
- Optional: notify user of suspicious activity

---

## RBAC (Role-Based Access Control)

### Permission Denied

**Scenario**: User role insufficient for endpoint

**Error Response** (403):
```json
{
  "success": false,
  "message": "Insufficient permissions",
  "code": "FORBIDDEN"
}
```

**Scenarios**:
- VIEWER trying to create transaction → 403
- ANALYST trying to create user → 403
- Any role trying to access without token → 401

**Fallback**:
- Show appropriate UI based on role
- Hide/disable actions user can't perform
- Log authorization failures

### Role Escalation Blocked

**Scenario**: Non-admin user tries to change own role

**Error Response** (403):
```json
{
  "success": false,
  "message": "Only admins can assign roles",
  "code": "ROLE_ESCALATION_BLOCKED"
}
```

**Fallback**:
- Request from admin user only
- Prevent frontend from sending this request

---

## User Management

### Duplicate Email on Update

**Scenario**: User updates email to one that already exists

**Error Response** (409):
```json
{
  "success": false,
  "message": "Email already registered",
  "code": "DUPLICATE_EMAIL"
}
```

**Fallback**:
- Suggest different email
- Show existing email owner (for admins)

### User Not Found

**Scenario**: Trying to update non-existent user

**Error Response** (404):
```json
{
  "success": false,
  "message": "User not found",
  "code": "USER_NOT_FOUND"
}
```

**Fallback**:
- Redirect to user list
- User may have been deleted by admin

### Admin Self-Deactivation Blocked

**Scenario**: Admin tries to deactivate themselves

**Error Response** (400):
```json
{
  "success": false,
  "message": "Admin cannot deactivate themselves",
  "code": "SELF_DEACTIVATION_BLOCKED"
}
```

**Fallback**:
- Show warning message
- Suggest admin contact another admin
- Prevent self-lockout

### Cannot Update Other Users (Non-Admin)

**Scenario**: Regular user tries to update another user

**Error Response** (403):
```json
{
  "success": false,
  "message": "Cannot update other users",
  "code": "FORBIDDEN"
}
```

**Fallback**:
- Only show user's own profile edit
- Disable edit buttons for other users

---

## Transaction Management

### Invalid Amount

**Scenario**: Amount <= 0

**Error Response** (400):
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    { "path": "amount", "message": "Number must be greater than 0" }
  ]
}
```

**Fallback**:
- Real-time validation on frontend
- Min value input: `min="0.01"`
- Show error before submission

### Invalid Date Format

**Scenario**: Date not ISO 8601 format

**Error Response** (400):
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    { "path": "date", "message": "Invalid date format" }
  ]
}
```

**Fallback**:
- Use date picker on frontend
- Automatic ISO format conversion

### Invalid Enum (Type/Category)

**Scenario**: Type not "income" or "expense"

**Error Response** (400):
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    { "path": "type", "message": "Invalid enum value" }
  ]
}
```

**Fallback**:
- Dropdown selection (not free text)
- Validate before sending

### Transaction Not Found

**Scenario**: Updating/deleting non-existent transaction

**Error Response** (404):
```json
{
  "success": false,
  "message": "Transaction not found",
  "code": "TRANSACTION_NOT_FOUND"
}
```

**Fallback**:
- Transaction may have been deleted
- Refresh list
- Show "Not found" message

### Cannot Update Deleted Transaction

**Scenario**: Trying to update soft-deleted transaction

**Error Response** (400):
```json
{
  "success": false,
  "message": "Deleted transactions cannot be updated",
  "code": "TRANSACTION_DELETED"
}
```

**Fallback**:
- Don't show deleted transactions in UI
- Use filter: `isDeleted = false`

### Cannot Delete Already Deleted Transaction

**Scenario**: Soft-delete already deleted transaction

**Error Response** (400):
```json
{
  "success": false,
  "message": "Transaction already deleted",
  "code": "TRANSACTION_DELETED"
}
```

**Fallback**:
- Hide delete button if already deleted
- Check isDeleted flag before showing action

### Ownership Violation

**Scenario**: User tries to access other user's transaction

**Error Response** (404):
```json
{
  "success": false,
  "message": "Transaction not found",
  "code": "TRANSACTION_NOT_FOUND"
}
```

**Note**: Returns 404, not 403, to hide existence

**Fallback**:
- Backend enforces ownership checks
- User only sees their own transactions

---

## Analytics/Dashboard

### Empty Data Handling

**Scenario**: User has no transactions

**Response** (200, Safe):
```json
{
  "success": true,
  "data": {
    "totalIncome": 0,
    "totalExpenses": 0,
    "netBalance": 0,
    "categoryTotals": [],
    "recentTransactions": []
  }
}
```

**Fallback**:
- No error, graceful degradation
- Show empty state UI
- Prompt to create first transaction
- Don't show error messages

### No Monthly Trends

**Scenario**: Analytics requested but no data in date range

**Response** (200, Safe):
```json
{
  "success": true,
  "data": {
    "monthly": []
  }
}
```

**Fallback**:
- Empty chart with message "No data available"
- Show date range selector to filter

### Restricted Role (VIEWER)

**Scenario**: VIEWER trying to access analytics

**Error Response** (403):
```json
{
  "success": false,
  "message": "Insufficient permissions",
  "code": "FORBIDDEN"
}
```

**Fallback**:
- Don't show analytics UI for viewers
- Hide dashboard tab/menu

---

## Input Validation

### Missing Required Fields

**Scenario**: POST body missing required field

**Error Response** (400):
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    { "path": "email", "message": "Required" }
  ]
}
```

**Fallback**:
- Form validation shows which fields required
- Disable submit button until fields filled

### Invalid UUID Format

**Scenario**: Path parameter `:id` not UUID

**Error Response** (400):
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    { "path": "id", "message": "Invalid uuid" }
  ]
}
```

**Fallback**:
- Program shouldn't generate bad UUIDs
- If triggered, likely API misuse

### String Too Long

**Scenario**: Notes field > 500 characters

**Error Response** (400):
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    { "path": "notes", "message": "String must contain at most 500 character(s)" }
  ]
}
```

**Fallback**:
- Textarea with character counter
- Truncate or show error when limit reached

### Date Range Invalid

**Scenario**: `dateFrom` > `dateTo`

**Error Response** (400):
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    { "path": "dateFrom", "message": "dateFrom must be earlier than or equal to dateTo" }
  ]
}
```

**Fallback**:
- Date picker ensures valid order
- Swap dates automatically
- Show warning

---

## Database Fallbacks

### Connection Failed

**Error**: `Connection refused / connect ECONNREFUSED`

**Status**: 500 Internal Server Error

**Fallback**:
- Health check endpoint: `/health`
- Retry logic with exponential backoff
- Error logging for debugging
- Generic error to user (don't expose internals)

### Database Timeout

**Error**: `Client-initiated abrupt shutdown`

**Status**: 500 Internal Server Error

**Fallback**:
- Connection pool retries
- Request timeout handling
- Graceful queue during recovery

### Transaction Constraint Violation

**Error**: Foreign key, unique constraint violation

**Status**: 409 Conflict or 400 Bad Request

**Fallback**:
- Validate related resources exist first
- Check uniqueness before write

---

## Rate Limiting

### Rate Limit Exceeded

**Scenario**: > 200 requests in 15 minutes

**Error Response** (429):
```
HTTP/1.1 429 Too Many Requests
RateLimit-Limit: 200
RateLimit-Remaining: 0
RateLimit-Reset: 840 (seconds)

{
  "message": "Too many requests, please try again later"
}
```

**Fallback**:
- Exponential backoff on client
- Show friendly message
- Retry after header respects RateLimit-Reset

---

## Security Vulnerabilities Handled

### SQL Injection
**Handled by**: Prisma parameterized queries  
**Fallback**: Input validation + prepared statements

### XSS (Cross-Site Scripting)
**Handled by**: Input sanitization middleware removes `<>`  
**Fallback**: Helmet CSP headers

### CSRF (Cross-Site Request Forgery)
**Handled by**: No cookies, JWT Bearer tokens required  
**Fallback**: CORS controls origin

### Password Attacks
**Handled by**: bcrypt with salt 12, no plaintext  
**Fallback**: Rate limiting on login endpoint

---

## Bootstrap Admin Fallbacks

### Bootstrap Fails: Missing Env Variables

**Scenario**: `BOOTSTRAP_ADMIN=true` but env vars not set

**Error on Startup**:
```
BOOTSTRAP_ADMIN is enabled, but BOOTSTRAP_ADMIN_NAME, 
BOOTSTRAP_ADMIN_EMAIL, and BOOTSTRAP_ADMIN_PASSWORD are required.
```

**Fallback**:
- Server exits with error code 1
- Fix .env and restart
- Admin can register manually after

### Bootstrap Fails: Email Already Exists

**Scenario**: Bootstrap email used as non-admin user

**Error on Startup**:
```
Bootstrap admin email already exists with a non-admin account. 
Resolve manually to prevent unsafe privilege changes.
```

**Fallback**:
- Server exits with error to prevent escalation
- Admin must delete/change existing user first
- Or use different bootstrap email

### Bootstrap: Admin Already Exists

**Scenario**: ADMIN user already in database

**Behavior**: Silently skips (no error)

**Fallback**:
- Safe operation, idempotent
- Repeated startups don't recreate

---

## Error Response Format

All errors follow standardized format:

```json
{
  "success": false,
  "message": "Human-readable error message",
  "code": "ERROR_CODE",
  "errors": [
    {
      "path": "field.name",
      "message": "Field-specific validation message"
    }
  ]
}
```

**Error Codes Used**:
- `AUTH_REQUIRED` (401): Token missing
- `INVALID_TOKEN` (401): Token invalid/expired
- `TOKEN_EXPIRED` (401): Token past expiry
- `INVALID_CREDENTIALS` (401): Login failed
- `USER_INACTIVE` (403): Account deactivated
- `FORBIDDEN` (403): Insufficient permissions
- `ROLE_ESCALATION_BLOCKED` (403): Role/status change blocked
- `SELF_DEACTIVATION_BLOCKED` (400): Admin self-deactivate
- `DUPLICATE_EMAIL` (409): Email exists
- `USER_NOT_FOUND` (404): User missing
- `TRANSACTION_NOT_FOUND` (404): Transaction missing
- `TRANSACTION_DELETED` (400): Transaction soft-deleted

---

## Testing Error Scenarios

All error cases covered in Jest tests:

```bash
npm test
```

Test file coverage:
- `auth.test.js`: Auth errors (registration, login, password)
- `rbac.test.js`: Permission errors
- `userManagement.test.js`: User management errors
- `transactionFiltering.test.js`: Transaction errors
- `analyticsEdgeCases.test.js`: Empty data handling

---

## Production Readiness Checklist

- ✅ All error paths tested
- ✅ Centralized error middleware
- ✅ No internal error leakage
- ✅ Rate limiting enabled
- ✅ Security headers (Helmet)
- ✅ CORS whitelist configured
- ✅ Input validation on all endpoints
- ✅ Role escalation prevention
- ✅ Soft deletes (non-destructive)
- ✅ Graceful empty data handling
- ✅ Database connection pooling
- ✅ Bootstrap safety mechanisms

---

**Last Updated**: April 4, 2026
