FROM node:20-alpine

# Install runtime dependencies
RUN apk add --no-cache dumb-init curl

# Create app user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# Set working directory
WORKDIR /app

# Copy standalone build from Next.js
COPY .next/standalone ./
COPY .next/static ./.next/static
COPY public ./public

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:3000/api/health || exit 1

# Start the application
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "docker/frontend/server.js"]
