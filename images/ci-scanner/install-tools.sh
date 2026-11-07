#!/usr/bin/env bash
set -euxo pipefail

: "${TARGETARCH:?}"
case "$TARGETARCH" in
  amd64)
    trivy_arch=64bit
    opengrep_asset=opengrep_manylinux_x86
    ;;
  arm64)
    trivy_arch=ARM64
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
  local name="$1" url="$2" asset="$3"
  local file="${work}/${asset}"
  fetch "$url" "$file"
  install -m 0755 "$file" "/opt/ci-actions/bin/${name}"
}

install_tar() {
  local name="$1" url="$2" checksums_url="$3" asset="$4" member="$5"
  local file="${work}/${asset}"
  fetch "$url" "$file"
  local sums="${work}/${name}.checksums"
  fetch "$checksums_url" "$sums"
  verify_checksum "$sums" "$asset" "$file"
  mkdir -p "${work}/${name}"
  tar -xzf "$file" -C "${work}/${name}"
  install -m 0755 "${work}/${name}/${member}" "/opt/ci-actions/bin/${name}"
}

install_tar trivy \
  "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-${trivy_arch}.tar.gz" \
  "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_checksums.txt" \
  "trivy_${TRIVY_VERSION}_Linux-${trivy_arch}.tar.gz" trivy

# Opengrep publishes per-asset SHA-256 metadata in the GitHub API but no
# checksums file; the binary is fetched over TLS from the pinned release.
install_bin opengrep \
  "https://github.com/opengrep/opengrep/releases/download/v${OPENGREP_VERSION}/${opengrep_asset}" \
  "${opengrep_asset}"

python3 -m venv /opt/ci-actions/venv
/opt/ci-actions/venv/bin/pip install --no-cache-dir --upgrade "pip==${PIP_VERSION}"
/opt/ci-actions/venv/bin/pip install --no-cache-dir \
  "guarddog==${GUARDDOG_VERSION}" \
  "sarif-tools==${SARIF_TOOLS_VERSION}"
# GuardDog's dependency tree still resolves older versions of these packages;
# upgrade them to the fixed releases after the install.
/opt/ci-actions/venv/bin/pip install --no-cache-dir --upgrade \
  "certifi==${CERTIFI_VERSION}" \
  "msgpack==${MSGPACK_VERSION}" \
  "setuptools==${SETUPTOOLS_VERSION}" \
  "urllib3==${URLLIB3_VERSION}"
ln -sf /opt/ci-actions/venv/bin/guarddog /opt/ci-actions/bin/guarddog
ln -sf /opt/ci-actions/venv/bin/sarif /opt/ci-actions/bin/sarif
