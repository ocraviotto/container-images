#!/usr/bin/env bash
set -euxo pipefail

: "${TARGETARCH:?}"
case "$TARGETARCH" in
  amd64)
    opengrep_asset=opengrep_manylinux_x86
    ;;
  arm64)
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
  curl --fail --silent --show-error --location \
    --retry 5 --retry-all-errors --retry-delay 5 --retry-max-time 300 \
    --connect-timeout 20 --output "$dest" "$url"
}

# Opengrep publishes per-asset SHA-256 metadata in the GitHub API but no
# checksums file; the binary is fetched over TLS from the pinned release.
fetch \
  "https://github.com/opengrep/opengrep/releases/download/v${OPENGREP_VERSION}/${opengrep_asset}" \
  "${work}/${opengrep_asset}"
install -m 0755 "${work}/${opengrep_asset}" /opt/ci-actions/bin/opengrep

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

# pip, setuptools and wheel are install-time tools. Their vendored copies are
# still reported as vulnerable packages by image scanners, and the runtime
# only needs the console scripts and their libraries, so drop them.
/opt/ci-actions/venv/bin/pip uninstall -y pip setuptools wheel || true
rm -rf /opt/ci-actions/venv/lib/python*/site-packages/pip \
       /opt/ci-actions/venv/lib/python*/site-packages/pip-*.dist-info \
       /opt/ci-actions/venv/lib/python*/site-packages/setuptools \
       /opt/ci-actions/venv/lib/python*/site-packages/setuptools-*.dist-info \
       /opt/ci-actions/venv/lib/python*/site-packages/wheel \
       /opt/ci-actions/venv/lib/python*/site-packages/wheel-*.dist-info \
       /opt/ci-actions/venv/lib/python*/site-packages/pkg_resources \
       /opt/ci-actions/venv/lib/python*/site-packages/pkg_resources-*.dist-info
rm -f /opt/ci-actions/venv/bin/pip /opt/ci-actions/venv/bin/pip3 /opt/ci-actions/venv/bin/pip3.*

ln -sf /opt/ci-actions/venv/bin/guarddog /opt/ci-actions/bin/guarddog
ln -sf /opt/ci-actions/venv/bin/sarif /opt/ci-actions/bin/sarif

guarddog --version >/dev/null
sarif --version >/dev/null
