# =============================================================================
# ThaliumX Frontend Dockerfile
# Security-hardened multi-stage build for Next.js application
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Base image with security updates
# -----------------------------------------------------------------------------
FROM node:20-alpine AS base

# Security: Update base packages and add security tools
RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache \
      libc6-compat \
      dumb-init \
    && rm -rf /var/cache/apk/*

# Security: Install pnpm with specific version for reproducibility
RUN corepack enable && corepack prepare pnpm@9.14.4 --activate

# -----------------------------------------------------------------------------
# Stage 2: Dependencies installation
# -----------------------------------------------------------------------------
FROM base AS deps
WORKDIR /app

# Security: Copy only package files first for better layer caching
COPY frontend/package.json ./
COPY shared/package.json ./shared/

# Security: Install dependencies with frozen lockfile when available
# Using --ignore-workspace to avoid workspace resolution issues in Docker
WORKDIR /app/shared
RUN pnpm install --ignore-workspace --frozen-lockfile 2>/dev/null || pnpm install --ignore-workspace

WORKDIR /app
RUN pnpm install --ignore-workspace --frozen-lockfile 2>/dev/null || pnpm install --ignore-workspace

# Security: Prune store to reduce image size
RUN pnpm store prune

# -----------------------------------------------------------------------------
# Stage 3: Build shared package in isolation
# -----------------------------------------------------------------------------
FROM base AS shared-builder
WORKDIR /app/shared

# Copy shared package files
COPY shared/package.json ./
COPY shared/tsconfig.json ./
COPY shared/src ./src

# Install dependencies and build
RUN pnpm install --ignore-workspace --frozen-lockfile 2>/dev/null || pnpm install --ignore-workspace
RUN pnpm run build

# -----------------------------------------------------------------------------
# Stage 4: Build the application
# -----------------------------------------------------------------------------
FROM base AS builder
WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy pre-built shared package
COPY --from=shared-builder /app/shared ./shared

# Copy source code (all frontend files except node_modules and .next)
COPY frontend/src ./src
COPY frontend/public ./public
COPY frontend/package.json ./
COPY frontend/tsconfig.json ./
COPY frontend/next.config.ts ./
COPY frontend/postcss.config.mjs ./
COPY frontend/components.json ./
COPY frontend/eslint.config.mjs ./

# Build the Next.js application

# Security: Disable telemetry during build
ENV NEXT_TELEMETRY_DISABLED=1

# Build arguments for environment variables (compile-time)
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

# -----------------------------------------------------------------------------
# Stage 4: Production runtime (minimal, security-hardened)
# -----------------------------------------------------------------------------
FROM node:20-alpine AS runner
WORKDIR /app

# Security: Update packages and install only runtime dependencies
RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache \
      dumb-init \
      curl \
    && rm -rf /var/cache/apk/*

# Security: Set production environment
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Security: Create non-root user with specific UID/GID
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 --ingroup nodejs nextjs

# Security: Create necessary directories with proper permissions
RUN mkdir -p /app/.next/cache && \
    chown -R nextjs:nodejs /app

# Copy built application with proper ownership
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Security: Set restrictive file permissions
RUN chmod -R 550 /app && \
    chmod -R 770 /app/.next/cache

# Security: Remove unnecessary files
RUN rm -rf /app/.next/cache/* 2>/dev/null || true

# Expose port (non-privileged)
EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:3000/api/health || exit 1

# Security: Switch to non-root user
USER nextjs

# Security: Use dumb-init to handle signals properly
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Start the application
CMD ["node", "server.js"]

# =============================================================================
# Security Labels
# =============================================================================
LABEL org.opencontainers.image.title="ThaliumX Frontend"
LABEL org.opencontainers.image.description="Security-hardened Next.js frontend for ThaliumX platform"
LABEL org.opencontainers.image.vendor="ThaliumX"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.source="https://github.com/thaliumx/thaliumx"
LABEL security.hardened="true"
LABEL security.non-root="true"
LABEL security.read-only-root="recommended"
