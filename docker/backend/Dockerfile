# Multi-stage Dockerfile for ThaliumX Backend
# Build context should be the docker directory
FROM node:20-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat python3 make g++
RUN npm install -g pnpm@9.14.4
WORKDIR /app

# Copy package files from backend directory
COPY backend/package*.json ./
# Copy shared directory
COPY shared ./shared/

# Install dependencies
RUN npm config set ignore-scripts true && pnpm install --ignore-workspace && pnpm store prune

# Rebuild the source code only when needed
FROM base AS builder
RUN apk add --no-cache libc6-compat python3 make g++
RUN npm install -g pnpm@9.14.4
WORKDIR /app

# Copy package files
COPY backend/package*.json ./
COPY shared ./shared

# Build shared package first
WORKDIR /app/shared
RUN npm config set ignore-scripts true && pnpm install --ignore-workspace && pnpm run build

# Build the application
WORKDIR /app
RUN npm config set ignore-scripts true && pnpm install --ignore-workspace
COPY backend/tsconfig.json ./
COPY backend/src ./src

# Build TypeScript
RUN pnpm run build

# Production image, copy all the files and run the app
FROM base AS runner
WORKDIR /app

# Install production dependencies only
RUN apk add --no-cache libc6-compat
RUN npm install -g pnpm@9.14.4

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 thaliumx

# Copy built application
COPY --from=builder --chown=thaliumx:nodejs /app/dist ./dist
COPY --from=builder --chown=thaliumx:nodejs /app/shared ./shared
COPY --from=builder --chown=thaliumx:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=thaliumx:nodejs /app/package*.json ./

# Create directories for runtime
RUN mkdir -p /app/.secrets /app/logs && chown -R thaliumx:nodejs /app/.secrets /app/logs

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3002

# Expose port
EXPOSE 3002

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3002/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# Switch to non-root user
USER thaliumx

# Start the application
CMD ["node", "dist/index.js"]
