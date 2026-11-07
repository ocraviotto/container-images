# Security scanner toolchain for CI/CD pipelines.
#
# The image ships the common open-source scanners used by repository and image
# security jobs, so a pipeline can run them without downloading release assets
# on every job. It is generic: use it with GitHub Actions, GitLab CI,
# Gitea/Forgejo Actions, Jenkins, Tekton, or any container-based runner.
#
# Published as ghcr.io/ocraviotto/container-images/ci-scanner for linux/amd64
# and linux/arm64. Versions are pinned below; Renovate updates the release
# ARGs through the repository's Dockerfile manager.

# The Go tools are rebuilt from source with a current Go toolchain and patched
# Go modules. The upstream release binaries at the same versions are built
# with older dependencies and fail image scanning with fixable CVEs, so the
# release assets are not used here.
FROM --platform=$BUILDPLATFORM golang:1.27.3-bookworm AS go-tools

ARG TARGETOS=linux
ARG TARGETARCH

# renovate: depName=gitleaks/gitleaks
ARG GITLEAKS_VERSION=8.30.1
# renovate: depName=sigstore/cosign
ARG COSIGN_VERSION=3.1.4
# renovate: depName=anchore/grype
ARG GRYPE_VERSION=0.121.2
# renovate: depName=anchore/syft
ARG SYFT_VERSION=1.57.0
# renovate: depName=ossf/scorecard
ARG SCORECARD_VERSION=5.6.0

# Patched module versions. Keep these at or above the fixed versions reported
# by the image scan. They are not Renovate-managed because the Go datasource
# emits a leading "v", which does not fit the bare versions used below.
ARG X_NET_VERSION=0.62.0
ARG X_CRYPTO_VERSION=0.55.0
ARG X_TEXT_VERSION=0.41.0
ARG BROTLI_VERSION=1.2.7
ARG COMPRESS_VERSION=1.20.2
ARG XZ_VERSION=0.5.15
ARG CHI_VERSION=5.4.0
ARG GO_JOSE_VERSION=4.1.6

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates git; \
    rm -rf /var/lib/apt/lists/*; \
    mkdir -p /out /src; \
    export CGO_ENABLED=0 GOOS="${TARGETOS}" GOARCH="${TARGETARCH}" \
           GOTOOLCHAIN=local GOFLAGS=-mod=mod; \
    \
    git clone --depth 1 --branch "v${GITLEAKS_VERSION}" https://github.com/gitleaks/gitleaks /src/gitleaks; \
    cd /src/gitleaks; \
    go get \
      "golang.org/x/crypto@v${X_CRYPTO_VERSION}" \
      "golang.org/x/text@v${X_TEXT_VERSION}" \
      "github.com/andybalholm/brotli@v${BROTLI_VERSION}" \
      "github.com/klauspost/compress@v${COMPRESS_VERSION}" \
      "github.com/ulikunitz/xz@v${XZ_VERSION}" \
      "github.com/go-chi/chi/v5@v${CHI_VERSION}"; \
    go build -trimpath -buildvcs=false -ldflags="-s -w" -o /out/gitleaks .; \
    \
    git clone --depth 1 --branch "v${COSIGN_VERSION}" https://github.com/sigstore/cosign /src/cosign; \
    cd /src/cosign; \
    go get \
      "golang.org/x/net@v${X_NET_VERSION}" \
      "github.com/andybalholm/brotli@v${BROTLI_VERSION}" \
      "github.com/klauspost/compress@v${COMPRESS_VERSION}" \
      "github.com/ulikunitz/xz@v${XZ_VERSION}" \
      "github.com/go-chi/chi/v5@v${CHI_VERSION}"; \
    go build -trimpath -buildvcs=false -ldflags="-s -w" -o /out/cosign ./cmd/cosign; \
    \
    git clone --depth 1 --branch "v${GRYPE_VERSION}" https://github.com/anchore/grype /src/grype; \
    cd /src/grype; \
    go get \
      "golang.org/x/net@v${X_NET_VERSION}" \
      "github.com/andybalholm/brotli@v${BROTLI_VERSION}" \
      "github.com/klauspost/compress@v${COMPRESS_VERSION}" \
      "github.com/ulikunitz/xz@v${XZ_VERSION}" \
      "github.com/go-chi/chi/v5@v${CHI_VERSION}"; \
    go build -trimpath -buildvcs=false -ldflags="-s -w" -o /out/grype ./cmd/grype; \
    \
    git clone --depth 1 --branch "v${SYFT_VERSION}" https://github.com/anchore/syft /src/syft; \
    cd /src/syft; \
    go get \
      "golang.org/x/net@v${X_NET_VERSION}" \
      "github.com/andybalholm/brotli@v${BROTLI_VERSION}" \
      "github.com/klauspost/compress@v${COMPRESS_VERSION}" \
      "github.com/ulikunitz/xz@v${XZ_VERSION}" \
      "github.com/go-chi/chi/v5@v${CHI_VERSION}"; \
    go build -trimpath -buildvcs=false -ldflags="-s -w" -o /out/syft ./cmd/syft; \
    \
    git clone --depth 1 --branch "v${SCORECARD_VERSION}" https://github.com/ossf/scorecard /src/scorecard; \
    cd /src/scorecard; \
    go get \
      "golang.org/x/net@v${X_NET_VERSION}" \
      "github.com/go-jose/go-jose/v4@v${GO_JOSE_VERSION}" \
      "github.com/andybalholm/brotli@v${BROTLI_VERSION}" \
      "github.com/klauspost/compress@v${COMPRESS_VERSION}" \
      "github.com/ulikunitz/xz@v${XZ_VERSION}" \
      "github.com/go-chi/chi/v5@v${CHI_VERSION}"; \
    go build -trimpath -buildvcs=false -ldflags="-s -w" -o /out/scorecard .

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PATH=/opt/ci-actions/bin:${PATH} \
    HOME=/home/scanner

# renovate: depName=aquasecurity/trivy
ARG TRIVY_VERSION=0.76.2
# renovate: depName=opengrep/opengrep
ARG OPENGREP_VERSION=1.33.1
# renovate: depName=guarddog datasource=pypi
ARG GUARDDOG_VERSION=3.2.0
# renovate: depName=sarif-tools datasource=pypi
ARG SARIF_TOOLS_VERSION=3.0.5
ARG PIP_VERSION=26.2.0

ARG TARGETARCH

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
      bash ca-certificates curl git gzip jq python3 python3-venv tar \
    && rm -rf /var/lib/apt/lists/*

COPY --from=go-tools /out/ /opt/ci-actions/bin/
COPY install-tools.sh /usr/local/bin/install-tools
RUN chmod 0755 /usr/local/bin/install-tools \
    && install-tools

# Run unprivileged. The workspace and home directory are the only writable
# locations the scanner tools need; /tmp is writable from the base image.
RUN groupadd --gid 10001 scanner \
    && useradd --uid 10001 --gid 10001 --create-home \
      --home-dir /home/scanner --shell /bin/bash scanner \
    && mkdir -p /workspace \
    && chown -R scanner:scanner /workspace /home/scanner

USER 10001:10001
WORKDIR /workspace
CMD ["/bin/bash"]
