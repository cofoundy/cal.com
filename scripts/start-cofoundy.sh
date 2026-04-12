#!/bin/bash
set -x

# Cofoundy Cal.com combined start script
# Starts both the Next.js web app (port 3000) and NestJS API v2 (port 5555)
# Uses bash (not sh) — required for wait -n support

# Replace baked-in NEXT_PUBLIC_WEBAPP_URL with runtime value
scripts/replace-placeholder.sh "$BUILT_NEXT_PUBLIC_WEBAPP_URL" "$NEXT_PUBLIC_WEBAPP_URL"

# Wait for database to be ready
scripts/wait-for-it.sh ${DATABASE_HOST} -- echo "database is up"

# Run prisma migrations
npx prisma migrate deploy --schema /calcom/packages/prisma/schema.prisma

# Seed app store
npx ts-node --transpile-only /calcom/scripts/seed-app-store.ts

# Start API v2 (NestJS) on port 5555 in background
echo "Starting Cal.com API v2 on port 5555..."
node /calcom/apps/api/v2/dist/apps/api/v2/src/main.js &
API_PID=$!

# Start web app (Next.js) on port 3000 in background
echo "Starting Cal.com Web App on port 3000..."
yarn start &
WEB_PID=$!

# Monitor both processes — if either exits, kill the other and exit
wait $API_PID
API_EXIT=$?
echo "API process exited with code $API_EXIT"
kill $WEB_PID 2>/dev/null
exit $API_EXIT
