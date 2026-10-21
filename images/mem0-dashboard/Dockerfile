# syntax=docker/dockerfile:1
#
# Mem0 dashboard (Next.js).
#
# The upstream dashboard Dockerfile is close to production-ready (standalone
# output, non-root uid 1001, runtime NEXT_PUBLIC_* substitution), but:
#   - its deps stage copies package.json and pnpm-lock.yaml without
#     pnpm-workspace.yaml, so the security overrides in that file are not
#     applied;
#   - it runs `pnpm i` instead of a frozen-lockfile install.
#
# This build copies the workspace file and uses --frozen-lockfile.
# Node 24 is the current LTS line; Node 20 is EOL.
#
# renovate: packageName=mem0ai/mem0 depName=mem0 datasource=github-tags versioning=semver
ARG MEM0_VERSION=v2.2.1

FROM node:24-alpine AS source
RUN apk add --no-cache git
WORKDIR /src
RUN git clone --depth 1 --branch "${MEM0_VERSION}" \
    https://github.com/mem0ai/mem0.git .

FROM node:24-alpine AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY --from=source /src/server/dashboard/package.json \
    /src/server/dashboard/pnpm-lock.yaml \
    /src/server/dashboard/pnpm-workspace.yaml ./
RUN corepack enable pnpm \
    && pnpm install --frozen-lockfile

FROM node:24-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY --from=source /src/server/dashboard/ ./
ENV NEXT_TELEMETRY_DISABLED=1
# Placeholder values replaced at runtime by entrypoint.sh.
ENV NEXT_PUBLIC_API_URL=NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_INSTANCE_NAME=NEXT_PUBLIC_INSTANCE_NAME
RUN corepack enable pnpm \
    && pnpm run build

FROM node:24-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1
RUN addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 nextjs
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --chown=nextjs:nodejs entrypoint.sh /home/nextjs/entrypoint.sh
RUN chmod +x /home/nextjs/entrypoint.sh
USER nextjs
EXPOSE 3000
ENV PORT=3000 \
    HOSTNAME=0.0.0.0
ENTRYPOINT ["/home/nextjs/entrypoint.sh"]
CMD ["node", "server.js"]
