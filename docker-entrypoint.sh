#!/bin/sh
set -eu

echo "Generating Prisma client..."
npx prisma generate

SYNC_STRATEGY="${PRISMA_DB_SYNC_STRATEGY:-migrate-then-push}"

echo "Applying database sync strategy: ${SYNC_STRATEGY}"

if [ "${SYNC_STRATEGY}" = "migrate" ]; then
	npx prisma migrate deploy
elif [ "${SYNC_STRATEGY}" = "push" ]; then
	npx prisma db push --accept-data-loss
else
	if ! npx prisma migrate deploy; then
		echo "Migration deploy failed. Falling back to schema push (--accept-data-loss)."
		npx prisma db push --accept-data-loss
	fi
fi

echo "Starting application..."
exec "$@"