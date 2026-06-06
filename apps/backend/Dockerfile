# ---------- Stage 1: build ----------
FROM node:20-alpine AS builder

WORKDIR /app

# argon2 needs build toolchain for its native bindings during install.
RUN apk add --no-cache python3 make g++

# Install dependencies first to leverage Docker layer caching.
COPY package*.json ./
RUN npm ci

# Copy source and build.
COPY tsconfig*.json nest-cli.json ./
COPY src ./src
RUN npm run build

# Prune dev dependencies for a slim runtime node_modules.
RUN npm prune --omit=dev

# ---------- Stage 2: runtime ----------
FROM node:20-alpine AS runtime

ENV NODE_ENV=production
WORKDIR /app

# Run as the built-in non-root `node` user.
COPY --from=builder --chown=node:node /app/node_modules ./node_modules
COPY --from=builder --chown=node:node /app/dist ./dist
COPY --from=builder --chown=node:node /app/package.json ./package.json

USER node

EXPOSE 3000

# Lightweight container healthcheck hitting the health endpoint.
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:'+(process.env.PORT||3000)+'/api/v1/health',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"

CMD ["node", "dist/main.js"]
