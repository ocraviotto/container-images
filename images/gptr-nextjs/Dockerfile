# Custom production build of the gpt-researcher NextJS frontend.
#
# Why this Dockerfile lives here instead of using an external spec:
#   - The published `gptresearcher/gptr-nextjs` image runs `next dev`
#     (development mode), which compiles on-demand and is unsuitable for
#     production (fails readiness probes, slow, telemetry).
#   - The upstream production Dockerfile (`frontend/nextjs/Dockerfile`) has a
#     latent bug: `@ducanh2912/next-pwa` is a devDependency, but
#     `next.config.mjs` imports it at the top level, so the upstream
#     `npm prune --production` step removes it and `next start` fails to load
#     the config.
#
# This Dockerfile clones the upstream repo at a pinned tag and builds a proper
# production image (`next build` + `next start`) without pruning the PWA
# plugin. See images/gptr-nextjs/README.md for details.

FROM node:18.17.0-alpine AS builder
# renovate: packageName=assafelovic/gpt-researcher
ARG GPTR_VERSION=v3.6.1
RUN apk add --no-cache git
WORKDIR /app
RUN git clone --depth 1 --branch ${GPTR_VERSION} https://github.com/assafelovic/gpt-researcher.git .
WORKDIR /app/frontend/nextjs
RUN npm install --legacy-peer-deps
RUN npm run build

FROM node:18.17.0-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/frontend/nextjs/package.json ./
COPY --from=builder /app/frontend/nextjs/next.config.mjs ./
COPY --from=builder /app/frontend/nextjs/public ./public
COPY --from=builder /app/frontend/nextjs/.next ./.next
COPY --from=builder /app/frontend/nextjs/node_modules ./node_modules
EXPOSE 3000
CMD ["npm", "run", "start"]
