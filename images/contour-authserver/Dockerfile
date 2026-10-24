# contour-authserver built from upstream source.
#
# Why a local image instead of an external spec:
#   - upstream's Dockerfile pins golang:1.24.1 while go.mod requires Go >= 1.25,
#     so `go mod download` fails before compilation can start;
#   - upstream has no release newer than v4 (2023-08), so a spec would have to
#     track either a broken main or an old tag;
#   - building the pinned commit here lets us use a current Go toolchain and
#     produce correct multi-arch images (upstream hardcodes GOARCH=amd64).
#
# Renovate updates CONTOUR_AUTHSERVER_VERSION below (and in .version) to the
# latest projectcontour/contour-authserver main commit.

# renovate: contour-authserver-commit
ARG CONTOUR_AUTHSERVER_VERSION=5ea919dd5cea8539865915f59c8d7b0e0dbe3684

FROM golang:1.26 AS builder

ARG CONTOUR_AUTHSERVER_VERSION
ARG TARGETARCH

RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone https://github.com/projectcontour/contour-authserver.git . \
    && git checkout --detach "${CONTOUR_AUTHSERVER_VERSION}" \
    && CGO_ENABLED=0 GOOS=linux GOARCH="${TARGETARCH}" make build

FROM gcr.io/distroless/static:nonroot
WORKDIR /
COPY --from=builder /src/bin/contour-authserver .
USER nonroot:nonroot
ENTRYPOINT ["/contour-authserver"]
