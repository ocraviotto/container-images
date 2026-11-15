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

FROM node:24.22.3-alpine AS builder
# renovate: packageName=assafelovic/gpt-researcher
ARG GPTR_VERSION=v3.8.0
RUN apk add --no-cache git
WORKDIR /app
RUN git clone --depth 1 --branch ${GPTR_VERSION} https://github.com/assafelovic/gpt-researcher.git .
WORKDIR /app/frontend/nextjs

# Next.js 14 is EOL and has unpatched image-optimizer RCEs. 15.5.28 is the
# first 15.5.x release that fixes both GHSA-2xp9 and GHSA-2464. Keep React on
# the app's existing 18 line: Next 15.5.28's peer range supports React 18.2+,
# so forcing React 19 would add unrelated type/runtime breakage.
#
# Overrides: undici is a runtime dependency; postcss is pinned by Next and is
# also a direct devDependency (so it is overridden under next).
# serialize-javascript comes in through workbox/PWA and must be >= 7.0.3.
#
# @ducanh2912/next-pwa moves to dependencies: next.config.mjs imports it at
# startup, so it must survive the production prune below.
RUN node -e ' \
    const fs = require("fs"); \
    const p = JSON.parse(fs.readFileSync("package.json", "utf8")); \
    p.dependencies.next = "15.5.28"; \
    p.dependencies["@ducanh2912/next-pwa"] = (p.devDependencies && p.devDependencies["@ducanh2912/next-pwa"]) || "^10.0.1"; \
    if (p.devDependencies) { \
      delete p.devDependencies["@ducanh2912/next-pwa"]; \
      p.devDependencies["eslint-config-next"] = "15.5.28"; \
    } \
    p.overrides = Object.assign({}, p.overrides, { \
      undici: "6.29.1", \
      "serialize-javascript": "7.0.3", \
    }); \
    p.overrides.next = Object.assign({}, p.overrides.next, { postcss: "8.5.18" }); \
    fs.writeFileSync("package.json", JSON.stringify(p, null, 2) + "\n"); \
  '

# Next 15 made params/searchParams async. The upstream source targets Next 14,
# so run the official migration codemod instead of turning off type checking.
# The codemod rewrites page/route entries and flags anything it cannot fix.
RUN npx --yes @next/codemod@latest next-async-request-api . --force

RUN npm config set fetch-retries 5 \
    && npm config set fetch-retry-mintimeout 20000 \
    && npm config set fetch-retry-maxtimeout 120000 \
    && npm config set fetch-timeout 600000 \
    && (npm install --legacy-peer-deps --no-audit --no-fund \
        || npm install --legacy-peer-deps --no-audit --no-fund \
        || npm install --legacy-peer-deps --no-audit --no-fund)
RUN npm run build

# Drop build-only dependencies (rollup, terser, linters). The PWA plugin is a
# production dependency now, so next.config.mjs still loads at startup.
RUN npm prune --omit=dev

FROM node:24.22.3-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/frontend/nextjs/package.json ./
COPY --from=builder /app/frontend/nextjs/next.config.mjs ./
COPY --from=builder /app/frontend/nextjs/public ./public
COPY --from=builder /app/frontend/nextjs/.next ./.next
COPY --from=builder /app/frontend/nextjs/node_modules ./node_modules

# npm/npx are only needed to install and build. The runtime starts Next
# directly, so remove the npm CLI and its bundled dependency tree instead of
# shipping and scanning it.
RUN rm -rf /usr/local/lib/node_modules/npm \
    /usr/local/bin/npm /usr/local/bin/npx \
    && chown -R node:node /app

# Next writes image-optimization/cache data under .next at runtime, so the
# app must own its tree. The node image already provides the uid-1000 user.
USER node

EXPOSE 3000
CMD ["node_modules/.bin/next", "start"]
