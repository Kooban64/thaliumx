# Multi-stage Dockerfile for ThaliumX Frontend (Next.js)
# Build context should be the docker directory
FROM node:20-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat
RUN npm install -g pnpm@9.14.4
WORKDIR /app

# Copy package files from frontend directory
COPY frontend/package*.json ./
# Copy shared package
COPY shared ./shared

# Install shared package dependencies first
WORKDIR /app/shared
RUN pnpm install --ignore-workspace

# Install frontend dependencies
WORKDIR /app
RUN pnpm install --ignore-workspace && pnpm store prune

# Rebuild the source code only when needed
FROM base AS builder
RUN apk add --no-cache libc6-compat
RUN npm install -g pnpm@9.14.4 typescript
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/shared ./shared
COPY frontend ./

# Build shared package first (dependencies already installed)
WORKDIR /app/shared
RUN pnpm run build

# Build the application
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1

# Build arguments for environment variables
ARG NEXT_PUBLIC_API_URL
ARG NEXT_PUBLIC_KEYCLOAK_URL
ARG NEXT_PUBLIC_KEYCLOAK_REALM
ARG NEXT_PUBLIC_KEYCLOAK_CLIENT_ID

# Set environment variables for build
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL:-http://localhost:3002}
ENV NEXT_PUBLIC_KEYCLOAK_URL=${NEXT_PUBLIC_KEYCLOAK_URL:-http://localhost:8080}
ENV NEXT_PUBLIC_KEYCLOAK_REALM=${NEXT_PUBLIC_KEYCLOAK_REALM:-thaliumx}
ENV NEXT_PUBLIC_KEYCLOAK_CLIENT_ID=${NEXT_PUBLIC_KEYCLOAK_CLIENT_ID:-thaliumx-frontend}

RUN pnpm run build

# Production image, copy all the files and run the app
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy built application
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Set ownership
RUN chown -R nextjs:nodejs /app

# Expose port
EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/api/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })" || \
  wget --spider --timeout=5 http://localhost:3000 || exit 1

# Switch to non-root user
USER nextjs

# Start the application
CMD ["node", "server.js"]
