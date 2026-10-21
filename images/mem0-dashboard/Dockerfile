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
# A global ARG is only visible to FROM lines; it must be redeclared inside the
# stage to be available to RUN.
ARG MEM0_VERSION
RUN apk add --no-cache git
WORKDIR /src
RUN git clone --depth 1 --branch "${MEM0_VERSION}" \
    https://github.com/mem0ai/mem0.git .

FROM node:24-alpine AS base
RUN apk add --no-cache libc6-compat

FROM base AS deps
WORKDIR /app
COPY --from=source /src/server/dashboard/package.json \
    /src/server/dashboard/pnpm-lock.yaml \
    /src/server/dashboard/pnpm-workspace.yaml ./
# corepack cannot be relied on to honour the pinned pnpm version on Node 24,
# so install it directly.
RUN npm install -g pnpm@10.34.2 \
    && pnpm install --frozen-lockfile

FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY --from=source /src/server/dashboard/ ./
ENV NEXT_TELEMETRY_DISABLED=1
# Placeholder values replaced at runtime by entrypoint.sh.
ENV NEXT_PUBLIC_API_URL=NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_INSTANCE_NAME=NEXT_PUBLIC_INSTANCE_NAME
RUN npm install -g pnpm@10.34.2 \
    && pnpm run build

FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1
RUN addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 nextjs
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
# entrypoint.sh lives in the cloned dashboard source, not in the image build
# context.
COPY --from=builder --chown=nextjs:nodejs /app/entrypoint.sh /home/nextjs/entrypoint.sh
RUN chmod +x /home/nextjs/entrypoint.sh
USER nextjs
EXPOSE 3000
ENV PORT=3000 \
    HOSTNAME=0.0.0.0
ENTRYPOINT ["/home/nextjs/entrypoint.sh"]
CMD ["node", "server.js"]