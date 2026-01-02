# --- Build stage ---
FROM node:20-alpine AS deps
WORKDIR /app

# Install dependencies (use package-lock.json if present in repo for reproducible installs)
COPY package*.json ./
RUN npm ci --silent || npm install --silent

FROM node:20-alpine AS builder
WORKDIR /app
COPY . .
COPY --from=deps /app/node_modules ./node_modules

# Build the Next.js app
RUN npm run build

# --- Production image ---
FROM node:20-alpine AS runner
ENV NODE_ENV=production \
    PORT=8083
WORKDIR /app

# Copy built output and necessary files from the builder
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

# Default exposed port for the container
EXPOSE 8083

# Start Next.js on port 8083
CMD ["npm", "run", "start", "--", "-p", "8083"]
