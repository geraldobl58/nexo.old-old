# syntax=docker/dockerfile:1.4

# ============================================
# Base Stage - Common dependencies
# ============================================
FROM node:20-alpine AS base

# Install pnpm globally
RUN corepack enable && corepack prepare pnpm@9.0.0 --activate

# Set working directory
WORKDIR /app

# Copy workspace files
COPY pnpm-workspace.yaml package.json pnpm-lock.yaml ./

# ============================================
# Dependencies Stage - Install all dependencies
# ============================================
FROM base AS dependencies

# Copy package.json from root and apps/nexo-be
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/nexo-be/package.json ./apps/nexo-be/package.json

# Install all dependencies (including dev dependencies for build)
RUN --mount=type=cache,id=pnpm,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile

# ============================================
# Builder Stage - Build the application
# ============================================
FROM dependencies AS builder

# Copy application source code
COPY apps/nexo-be ./apps/nexo-be
COPY turbo.json ./

# Build the application
WORKDIR /app/apps/nexo-be
RUN pnpm build

# ============================================
# Production Dependencies Stage - Install only prod dependencies
# ============================================
FROM base AS prod-dependencies

# Copy pnpm config for hoisting
COPY .npmrc.docker .npmrc

# Copy ALL package.json files to maintain workspace structure
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/nexo-be/package.json ./apps/nexo-be/

# Install workspace dependencies (production only) with hoisting enabled
WORKDIR /app
RUN --mount=type=cache,id=pnpm,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile --prod

# ============================================
# Production Stage - Final runtime image
# ============================================
FROM node:20-alpine AS production

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nestjs -u 1001

# Set working directory
WORKDIR /app

# Copy built application from builder
COPY --from=builder --chown=nestjs:nodejs /app/apps/nexo-be/dist ./dist
COPY --from=builder --chown=nestjs:nodejs /app/apps/nexo-be/package.json ./

# Copy production dependencies from workspace (pnpm structure)
COPY --from=prod-dependencies --chown=nestjs:nodejs /app/node_modules ./node_modules

# Switch to non-root user
USER nestjs

# Expose application port
EXPOSE 3000

# Note: Healthcheck URL will be overridden by Kubernetes readiness/liveness probes
# Default healthcheck for local Docker usage only
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start application
CMD ["node", "dist/src/main.js"]
