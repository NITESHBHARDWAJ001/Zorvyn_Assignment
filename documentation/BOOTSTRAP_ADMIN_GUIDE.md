# Bootstrap Admin Guide

## Current Behavior

The application supports two bootstrap modes:

- Automatic bootstrap at server startup when `BOOTSTRAP_ADMIN=true`.
- Manual bootstrap from Swagger UI or API call to `POST /admin/bootstrap`.

## Manual Bootstrap Request

Send a JSON body like this:

```json
{
  "confirmCreate": true,
  "name": "System Admin",
  "email": "admin@example.com",
  "password": "ChangeMe123!"
}
```

## Expected Response

- `201 Created` if the admin is created.
- `409 Conflict` if an admin already exists.
- `400 Bad Request` if required fields are missing.

## Security Notes

- `confirmCreate` is required to prevent accidental creation.
- Keep the endpoint limited to initial setup or trusted internal use.
- After bootstrap, use the admin credentials to log in and manage the system.

## Existing Admin

If the response says `ADMIN_EXISTS`, the current admin account is already present in the database. In that case, use the login endpoint with the existing credentials rather than trying to bootstrap again.
