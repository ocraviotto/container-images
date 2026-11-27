# renovate: ente-commit
ARG ENTE_SERVER_COMMIT=03e9a7b7f54f6b24f5db3696f161d2a528f6b44c

FROM golang:1.26.11-alpine3.23 AS builder
ARG ENTE_SERVER_COMMIT
ENV CGO_ENABLED=0
RUN apk add --no-cache git
WORKDIR /etc/ente
RUN git init -q \
    && git remote add origin https://github.com/ente-io/ente.git \
    && git fetch -q --depth 1 origin "${ENTE_SERVER_COMMIT}" \
    && git checkout -q FETCH_HEAD
WORKDIR /etc/ente/server
# Upstream pins golang.org/x/net v0.60.0; CVE-2026-78661 is fixed in v0.62.0.
RUN go get golang.org/x/net@v0.62.0
RUN go mod download
RUN --mount=type=cache,target=/root/.cache/go-build \
    go build -trimpath -o museum cmd/museum/main.go

FROM alpine:3.22
ARG ENTE_SERVER_COMMIT
ENV GIT_COMMIT=$ENTE_SERVER_COMMIT
USER root
# The runtime base lags Alpine's package errata (OpenSSL, zlib, ...). Apply
# the updates at build time so the image does not ship stale libraries.
RUN apk upgrade --no-cache
COPY --from=builder /etc/ente/server/museum /museum
COPY --from=builder /etc/ente/server/configurations /configurations
COPY --from=builder /etc/ente/server/migrations /migrations
COPY --from=builder /etc/ente/server/mail-templates /mail-templates
COPY --from=builder /etc/ente/server/web-templates /web-templates
CMD ["./museum"]
