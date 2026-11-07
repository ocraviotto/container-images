# CI scanner image for avellaneda/ci-actions.
#
# The image carries the same pinned tools that ci-actions/setup installs, so a
# dedicated Forgejo runner class can start scan jobs without downloading
# several hundred megabytes of release assets on every run.
#
# Published as ghcr.io/ocraviotto/container-images/ci-scanner for linux/amd64
# and linux/arm64. Versions are kept in sync with
# avellaneda/ci-actions/versions.env; Renovate updates the ARG lines below.

FROM ubuntu:24.04

# renovate: depName=aquasecurity/trivy
ARG TRIVY_VERSION=0.76.2
# renovate: depName=anchore/grype
ARG GRYPE_VERSION=0.121.2
# renovate: depName=anchore/syft
ARG SYFT_VERSION=1.57.0
# renovate: depName=opengrep/opengrep
ARG OPENGREP_VERSION=1.33.1
# renovate: depName=gitleaks/gitleaks
ARG GITLEAKS_VERSION=8.30.1
# renovate: depName=sigstore/cosign
ARG COSIGN_VERSION=3.1.4
# renovate: depName=ossf/scorecard
ARG SCORECARD_VERSION=5.6.0
# renovate: depName=guarddog datasource=pypi
ARG GUARDDOG_VERSION=3.2.0
# renovate: depName=sarif-tools datasource=pypi
ARG SARIF_TOOLS_VERSION=3.0.5

ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PATH=/opt/ci-actions/bin:${PATH}

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
      bash ca-certificates curl git gzip jq python3 python3-venv tar \
    && rm -rf /var/lib/apt/lists/*

COPY install-tools.sh /usr/local/bin/install-tools
RUN chmod 0755 /usr/local/bin/install-tools \
    && install-tools

# Fail the build early if a tool is missing from PATH.
RUN set -eux; \
    for tool in trivy grype syft opengrep gitleaks cosign scorecard guarddog sarif; do \
      command -v "$tool" >/dev/null; \
    done

WORKDIR /workspace
CMD ["/bin/bash"]
