# ---- Builder ----
FROM node:20-alpine AS builder
WORKDIR /app
 
# Install ALL deps (including dev) using the lockfile
COPY package.json package-lock.json ./
RUN npm ci

# Build TS
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# ---- Runner ----
FROM node:20-alpine AS runner
RUN apk add --no-cache tini curl
ENV NODE_ENV=production
WORKDIR /app

# Install only production deps
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Copy compiled app
COPY --from=builder /app/dist ./dist

USER node
EXPOSE 8080
#HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD curl -f http://localhost:8080/healthz || exit 1
ENTRYPOINT ["/sbin/tini","--"]
CMD ["node","dist/index.js"]
