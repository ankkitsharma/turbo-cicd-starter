# Use Node.js 18 Alpine as base image
FROM node:18-alpine AS base

# Install pnpm
RUN npm install -g pnpm

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY turbo.json ./

# Copy workspace packages
COPY packages/ ./packages/

# Copy API app package.json
COPY apps/api/package.json ./apps/api/

ENV HUSKY=0

# Install dependencies
RUN pnpm install --frozen-lockfile

# Build stage
FROM base AS builder

# Copy API source code
COPY apps/api/ ./apps/api/

# Build the API
WORKDIR /app/apps/api
RUN pnpm build

# Production stage
FROM node:18-alpine AS production

# Install pnpm
RUN npm install -g pnpm

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY turbo.json ./

# Copy workspace packages
COPY packages/ ./packages/

# Copy API app package.json
COPY apps/api/package.json ./apps/api/

# Install production dependencies only
RUN pnpm install --frozen-lockfile --prod

# Copy built application from builder stage
COPY --from=builder /app/apps/api/dist ./apps/api/dist

# Expose port
EXPOSE 3001

# Set working directory to API app
WORKDIR /app/apps/api

# Start the application
CMD ["node", "dist/index.js"]