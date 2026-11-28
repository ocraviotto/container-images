# renovate: ente-commit
ARG ENTE_WEB_REF=03e9a7b7f54f6b24f5db3696f161d2a528f6b44c

FROM node:24 AS builder
ARG ENTE_WEB_REF
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl build-essential git \
    && rm -rf /var/lib/apt/lists/* \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --target wasm32-unknown-unknown
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /build
RUN git init -q \
    && git remote add origin https://github.com/ente-io/ente.git \
    && git fetch -q --depth 1 origin "${ENTE_WEB_REF}" \
    && git checkout -q FETCH_HEAD

WORKDIR /build/web

ENV NEXT_PUBLIC_ENTE_ENDPOINT=ENTE_API_ORIGIN_PLACEHOLDER

RUN npm ci
RUN npm run build:photos
RUN npm run build:albums
RUN npm run build:accounts
RUN npm run build:auth
RUN npm run build:cast
RUN npm run build:share
RUN npm run build:embed
RUN npm run build:paste
RUN npm run build:locker
RUN npm run build:memories

FROM nginx/nginx-unprivileged:1.31.9-alpine-slim
USER root
# The runtime base lags Alpine's package errata; apply the updates at build
# time, then drop to the unprivileged nginx user.
RUN apk upgrade --no-cache

WORKDIR /out
COPY --from=builder /build/web/apps/photos/out /out/photos
COPY --from=builder /build/web/apps/albums/out /out/albums
COPY --from=builder /build/web/apps/accounts/out /out/accounts
COPY --from=builder /build/web/apps/auth/out /out/auth
COPY --from=builder /build/web/apps/cast/out /out/cast
COPY --from=builder /build/web/apps/share/out /out/share
COPY --from=builder /build/web/apps/embed/out /out/embed
COPY --from=builder /build/web/apps/paste/out /out/paste
COPY --from=builder /build/web/apps/locker/out /out/locker
COPY --from=builder /build/web/apps/memories/out /out/memories

# 40-enable-ipv6.sh activates the commented listeners when IPv6 is available.
COPY <<'EOF' /etc/nginx/conf.d/default.conf
server {
    listen 3000;
    #listen [::]:3000;
    root /out/photos;
    location / { try_files $uri $uri.html /index.html; }
}
server {
    listen 3001;
    #listen [::]:3001;
    root /out/accounts;
    location / { try_files $uri $uri.html /index.html; }
}
server {
    listen 3002;
    #listen [::]:3002;
    root /out/albums;
    location / { try_files $uri $uri.html /index.html; }
}
server {
    listen 3003;
    #listen [::]:3003;
    root /out/auth;
    location / { try_files $uri $uri.html /index.html; }
}
server {
    listen 3004;
    #listen [::]:3004;
    root /out/cast;
    location / { try_files $uri $uri.html /index.html; }
}
server {
    listen 3005;
    #listen [::]:3005;
    root /out/share;
    location / { try_files $uri $uri.html /index.html; }
}
server {
    listen 3006;
    #listen [::]:3006;
    root /out/embed;
    location / { try_files $uri $uri.html /index.html; }
}
server {
    listen 3008;
    #listen [::]:3008;
    root /out/paste;
    location / { try_files $uri $uri.html /index.html; }
}
server {
    listen 3009;
    #listen [::]:3009;
    root /out/locker;
    location / { try_files $uri $uri.html /index.html; }
}
server {
    listen 3010;
    #listen [::]:3010;
    root /out/memories;
    location / { try_files $uri $uri.html /index.html; }
}
EOF

EXPOSE 3000
EXPOSE 3001
EXPOSE 3002
EXPOSE 3003
EXPOSE 3004
EXPOSE 3005
EXPOSE 3006
EXPOSE 3008
EXPOSE 3009
EXPOSE 3010

ENV ENTE_API_ORIGIN=http://localhost:8080

COPY <<EOF /docker-entrypoint.d/90-replace-ente-env.sh
#!/bin/sh
find /out -name '*.js' | while IFS= read -r f; do
    sed -i "s#ENTE_API_ORIGIN_PLACEHOLDER#\$ENTE_API_ORIGIN#g" "\$f"
done
EOF
RUN chmod +x /docker-entrypoint.d/90-replace-ente-env.sh

COPY <<'EOF' /docker-entrypoint.d/40-enable-ipv6.sh
#!/bin/sh
if [ -f /proc/net/if_inet6 ]; then
    sed -i 's/#listen \[::\]:/listen [::]:/g' /etc/nginx/conf.d/default.conf
fi
EOF
RUN chmod +x /docker-entrypoint.d/40-enable-ipv6.sh

# The env substitution rewrites files in /out at container start, and the
# ipv6 script edits the nginx config, so the unprivileged user needs to own
# both.
RUN chown -R nginx:nginx /out /etc/nginx/conf.d
USER nginx
