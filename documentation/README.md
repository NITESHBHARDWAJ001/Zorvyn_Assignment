# Documentation

This folder contains deployment, bootstrap, and API verification guidance for the Finance Dashboard backend.

## Files

- [Bootstrap Guide](BOOTSTRAP_ADMIN_GUIDE.md)
- [Docker Deployment Guide](DOCKER_DEPLOYMENT.md)
- [API Curl Verification Script](API_CURL_VERIFICATION.ps1)
- [Swagger Usage Notes](SWAGGER_NOTES.md)
- [Assumptions and Tradeoffs](ASSUMPTIONS_AND_TRADEOFFS.md)

## Recommended Order

1. Apply Prisma migrations to the database.
2. Seed or bootstrap the admin account.
3. Start the app locally or in Docker.
4. Run the curl verification script.
5. Use Swagger UI for manual validation.
6. Review assumptions and tradeoffs for evaluation context.
