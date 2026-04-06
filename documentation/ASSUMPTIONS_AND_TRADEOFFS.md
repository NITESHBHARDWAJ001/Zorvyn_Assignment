# Assumptions and Tradeoffs

## Assumptions

- This project is evaluated as a backend assignment with API consumers (frontend or API clients).
- JWT bearer authentication is acceptable for assignment scope.
- The role model is intentionally fixed to three roles: VIEWER, ANALYST, ADMIN.
- Financial records are represented as transactions with income/expense types.
- Transaction delete operations are soft deletes for safer recovery and auditing.
- PostgreSQL is the persistence layer for both local and hosted deployments.

## Key Tradeoffs

- Chose RBAC middleware over a policy engine to keep authorization behavior explicit and easy to review.
- Chose Prisma ORM for schema safety and maintainability over raw SQL-centric implementation.
- Chose JWT stateless auth for portability and simpler deployment over session/cookie auth.
- Chose service-layer structure and strong validation over adding broader optional features.
- Added `PRISMA_DB_SYNC_STRATEGY` startup control (`migrate`, `push`, `migrate-then-push`) to improve deployment reliability in hosted environments where migration history issues can block startup.

## Why These Tradeoffs Fit This Assignment

- They prioritize correctness, clarity, and maintainability.
- They keep business logic and access control easy to inspect.
- They reduce setup friction for reviewers while preserving realistic backend behavior.
