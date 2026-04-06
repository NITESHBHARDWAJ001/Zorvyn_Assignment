# Swagger Notes

## Admin Bootstrap

The `POST /admin/bootstrap` endpoint now exposes a request body in Swagger UI:

- `confirmCreate`: must be `true`
- `name`: admin display name
- `email`: admin email
- `password`: admin password

## Example

```json
{
  "confirmCreate": true,
  "name": "System Admin",
  "email": "admin@example.com",
  "password": "ChangeMe123!"
}
```

## Common Outcomes

- `201`: bootstrap succeeded
- `409`: admin already exists
- `400`: request body missing or invalid

## Usage Tip

Use the Swagger `Authorize` button after login to test protected endpoints with the JWT token.
