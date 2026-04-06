FROM node:20-alpine

WORKDIR /app

RUN apk add --no-cache libc6-compat openssl

# Install production dependencies in a clean layer
COPY package*.json ./
RUN npm ci --omit=dev

# Copy Prisma schema first so client generation can be cached
COPY prisma ./prisma
RUN npx prisma generate

# Copy application source
COPY . .

# Install a small entrypoint that applies pending migrations before launch
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENV NODE_ENV=production
EXPOSE 4000

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["npm", "start"]