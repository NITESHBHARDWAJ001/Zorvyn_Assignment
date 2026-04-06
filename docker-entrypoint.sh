#!/bin/sh
set -eu

echo "Generating Prisma client..."
npx prisma generate

echo "Applying pending database migrations..."
npx prisma migrate deploy

echo "Starting application..."
exec "$@"