#!/usr/bin/env bash
set -euxo pipefail

: "${TARGETARCH:?}"
case "$TARGETARCH" in
  amd64)
    trivy_arch=64bit
    grype_arch=amd64
    syft_arch=amd64
    gitleaks_arch=x64
    cosign_arch=amd64
    scorecard_arch=amd64
    opengrep_asset=opengrep_manylinux_x86
    ;;
  arm64)
    trivy_arch=ARM64
    grype_arch=arm64
    syft_arch=arm64
    gitleaks_arch=arm64
    cosign_arch=arm64
    scorecard_arch=arm64
    opengrep_asset=opengrep_manylinux_aarch64
    ;;
  *)
    echo "unsupported TARGETARCH: $TARGETARCH" >&2
    exit 1
    ;;
esac

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p /opt/ci-actions/bin

fetch() {
  local url="$1" dest="$2"
  curl --fail --silent --show-error --location --retry 3 --output "$dest" "$url"
}

verify_checksum() {
  local checksums="$1" asset="$2" file="$3"
  local expected
  expected="$(awk -v asset="$asset" '$2 == asset || $2 == "*" asset {print $1; exit}' "$checksums")"
  if [ -z "$expected" ]; then
    echo "no checksum for ${asset} in ${checksums}" >&2
    exit 1
  fi
  printf '%s  %s\n' "$expected" "$file" | sha256sum --check --status -
}

install_bin() {
  local name="$1" url="$2" checksums_url="$3" asset="$4"
  local file="${work}/${asset}"
  fetch "$url" "$file"
  if [ -n "$checksums_url" ]; then
    local sums="${work}/${name}.checksums"
    fetch "$checksums_url" "$sums"
    verify_checksum "$sums" "$asset" "$file"
  fi
  install -m 0755 "$file" "/opt/ci-actions/bin/${name}"
}

install_tar() {
  local name="$1" url="$2" checksums_url="$3" asset="$4" member="$5"
  local file="${work}/${asset}"
  fetch "$url" "$file"
  if [ -n "$checksums_url" ]; then
    local sums="${work}/${name}.checksums"
    fetch "$checksums_url" "$sums"
    verify_checksum "$sums" "$asset" "$file"
  fi
  mkdir -p "${work}/${name}"
  tar -xzf "$file" -C "${work}/${name}"
  install -m 0755 "${work}/${name}/${member}" "/opt/ci-actions/bin/${name}"
}

install_tar trivy \
  "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-${trivy_arch}.tar.gz" \
  "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_checksums.txt" \
  "trivy_${TRIVY_VERSION}_Linux-${trivy_arch}.tar.gz" trivy

install_tar grype \
  "https://github.com/anchore/grype/releases/download/v${GRYPE_VERSION}/grype_${GRYPE_VERSION}_linux_${grype_arch}.tar.gz" \
  "https://github.com/anchore/grype/releases/download/v${GRYPE_VERSION}/grype_${GRYPE_VERSION}_checksums.txt" \
  "grype_${GRYPE_VERSION}_linux_${grype_arch}.tar.gz" grype

install_tar syft \
  "https://github.com/anchore/syft/releases/download/v${SYFT_VERSION}/syft_${SYFT_VERSION}_linux_${syft_arch}.tar.gz" \
  "https://github.com/anchore/syft/releases/download/v${SYFT_VERSION}/syft_${SYFT_VERSION}_checksums.txt" \
  "syft_${SYFT_VERSION}_linux_${syft_arch}.tar.gz" syft

# Opengrep publishes per-asset SHA-256 metadata in the GitHub API but no
# checksums file; the binary is fetched over TLS from the pinned release.
install_bin opengrep \
  "https://github.com/opengrep/opengrep/releases/download/v${OPENGREP_VERSION}/${opengrep_asset}" \
  "" "${opengrep_asset}"

install_tar gitleaks \
  "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_${gitleaks_arch}.tar.gz" \
  "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_checksums.txt" \
  "gitleaks_${GITLEAKS_VERSION}_linux_${gitleaks_arch}.tar.gz" gitleaks

install_bin cosign \
  "https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-linux-${cosign_arch}" \
  "https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign_checksums.txt" \
  "cosign-linux-${cosign_arch}"

install_tar scorecard \
  "https://github.com/ossf/scorecard/releases/download/v${SCORECARD_VERSION}/scorecard_${SCORECARD_VERSION}_linux_${scorecard_arch}.tar.gz" \
  "https://github.com/ossf/scorecard/releases/download/v${SCORECARD_VERSION}/scorecard_checksums.txt" \
  "scorecard_${SCORECARD_VERSION}_linux_${scorecard_arch}.tar.gz" scorecard

python3 -m venv /opt/ci-actions/venv
/opt/ci-actions/venv/bin/pip install --no-cache-dir \
  "guarddog==${GUARDDOG_VERSION}" \
  "sarif-tools==${SARIF_TOOLS_VERSION}"
ln -sf /opt/ci-actions/venv/bin/guarddog /opt/ci-actions/bin/guarddog
ln -sf /opt/ci-actions/venv/bin/sarif /opt/ci-actions/bin/sarif
