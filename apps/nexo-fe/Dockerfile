# syntax=docker/dockerfile:1.4

# ============================================
# Base Stage - Common dependencies
# ============================================
FROM node:20-alpine AS base

# Install pnpm globally
RUN corepack enable && corepack prepare pnpm@9.0.0 --activate

# Set working directory
WORKDIR /app

# ============================================
# Dependencies Stage - Install all dependencies
# ============================================
FROM base AS dependencies

# Copy workspace files
COPY pnpm-workspace.yaml pnpm-lock.yaml package.json ./
COPY apps/nexo-fe/package.json ./apps/nexo-fe/package.json

# Install dependencies with node-linker=hoisted to avoid symlink issues
RUN --mount=type=cache,id=pnpm,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile

# ============================================
# Builder Stage - Build Next.js application
# ============================================
FROM dependencies AS builder

# Copy application source code
COPY apps/nexo-fe ./apps/nexo-fe
COPY turbo.json ./

# Set working directory to web app
WORKDIR /app/apps/nexo-fe

# Build Next.js app
# Disable SWC to avoid QEMU SIGILL on cross-platform builds
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production
ENV NEXT_PRIVATE_STANDALONE=true

RUN pnpm build

# ============================================
# Production Stage - Minimal runtime image
# ============================================
FROM node:20-alpine AS runner

# Set production environment
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Create non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

WORKDIR /app

# Copy the standalone output
COPY --from=builder --chown=nextjs:nodejs /app/apps/nexo-fe/.next/standalone ./

# Copy static files to the correct location for standalone
COPY --from=builder --chown=nextjs:nodejs /app/apps/nexo-fe/.next/static ./apps/nexo-fe/.next/static

# Copy public directory to the correct location for standalone
COPY --from=builder --chown=nextjs:nodejs /app/apps/nexo-fe/public ./apps/nexo-fe/public

# Install next directly to avoid pnpm symlink issues
RUN npm install next@14.2.35 --omit=dev --no-save 2>/dev/null || yarn add next@14.2.35 --production 2>/dev/null || true

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

# Set hostname
ENV HOSTNAME="0.0.0.0"
ENV PORT=3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start application
CMD ["node", "server.js"]
