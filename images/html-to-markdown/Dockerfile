# Live demo for html-to-markdown, served as a static site by nginx.
#
# The published demo pulls two things from third parties at runtime:
#   - Sora / Exo 2 / JetBrains Mono from Google Fonts
#   - the WebAssembly module from jsDelivr (@latest)
#
# Both are pinned and served from this image instead, so the page works
# without third-party requests and cannot change underneath us. The demo
# markup itself comes from an upstream release; prepare-demo.mjs rewrites
# the two external references.
#
# The wasm-bindgen artifacts committed under docs-site/public/demo are stale
# (they do not export convert()), so the same npm package the live demo loads
# is installed at a pinned version instead.

# renovate: packageName=xberg-io/html-to-markdown datasource=github-releases
ARG HTML_TO_MARKDOWN_VERSION=v3.18.6

FROM alpine:3.24.3 AS source
ARG HTML_TO_MARKDOWN_VERSION
RUN apk add --no-cache git
WORKDIR /src
RUN git init -q \
    && git remote add origin https://github.com/xberg-io/html-to-markdown.git \
    && git fetch -q --depth 1 origin "${HTML_TO_MARKDOWN_VERSION}" \
    && git checkout -q FETCH_HEAD

FROM node:24.22.1-alpine3.23 AS assets
WORKDIR /assets
COPY package.json prepare-demo.mjs ./
COPY --from=source /src/docs-site/public/demo/index.html /src/docs-site/public/demo/script.js ./
RUN node prepare-demo.mjs . \
    && npm install --omit=dev --ignore-scripts --no-audit --no-fund

FROM nginx/nginx-unprivileged:1.31.8-alpine-slim
COPY --from=assets /assets/index.html /usr/share/nginx/html/index.html
COPY --from=assets /assets/script.js /usr/share/nginx/html/script.js
COPY --from=assets /assets/node_modules/@xberg-io/html-to-markdown-wasm/pkg/web/html_to_markdown_wasm.js /usr/share/nginx/html/
COPY --from=assets /assets/node_modules/@xberg-io/html-to-markdown-wasm/pkg/web/html_to_markdown_wasm_bg.wasm /usr/share/nginx/html/
COPY --from=assets /assets/node_modules/@xberg-io/html-to-markdown-wasm/LICENSE /usr/share/nginx/html/html-to-markdown-wasm-LICENSE.txt
COPY fonts.css /usr/share/nginx/html/fonts.css
COPY --from=assets /assets/node_modules/@fontsource-variable/sora/files/sora-latin-wght-normal.woff2 /usr/share/nginx/html/fonts/
COPY --from=assets /assets/node_modules/@fontsource-variable/exo-2/files/exo-2-latin-wght-normal.woff2 /usr/share/nginx/html/fonts/
COPY --from=assets /assets/node_modules/@fontsource-variable/exo-2/files/exo-2-latin-wght-italic.woff2 /usr/share/nginx/html/fonts/
COPY --from=assets /assets/node_modules/@fontsource/jetbrains-mono/files/jetbrains-mono-latin-400-normal.woff2 /usr/share/nginx/html/fonts/
COPY --from=assets /assets/node_modules/@fontsource/jetbrains-mono/files/jetbrains-mono-latin-500-normal.woff2 /usr/share/nginx/html/fonts/
COPY --from=assets /assets/node_modules/@fontsource-variable/sora/LICENSE /usr/share/nginx/html/fonts/OFL-Sora.txt
COPY --from=assets /assets/node_modules/@fontsource-variable/exo-2/LICENSE /usr/share/nginx/html/fonts/OFL-Exo-2.txt
COPY --from=assets /assets/node_modules/@fontsource/jetbrains-mono/LICENSE /usr/share/nginx/html/fonts/OFL-JetBrains-Mono.txt
