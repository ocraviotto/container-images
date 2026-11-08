# ci-scanner

Preinstalled security scanner toolchain for CI/CD pipelines.

Published as `ghcr.io/ocraviotto/container-images/ci-scanner` for
`linux/amd64` and `linux/arm64`. Use it as the job image or container in
GitHub Actions, GitLab CI, Gitea/Forgejo Actions, Jenkins, Tekton, or any
container-based runner. Pin it by digest in production.

## Tools

| Tool | Purpose |
|---|---|
| `trivy` | repository and image scanning |
| `grype` | image vulnerability scanning |
| `syft` | SBOM generation |
| `opengrep` | SAST |
| `gitleaks` | secret scanning |
| `cosign` | image signing and verification |
| `scorecard` | upstream repository posture |
| `guarddog` | malicious package detection |
| `sarif` (`sarif-tools`) | SARIF summaries and reports |

All tools are on `PATH` under `/opt/ci-actions/bin`.

The image also includes Node.js 24 for JavaScript-based CI actions such as
`actions/checkout` and the artifact actions. npm is deliberately not included.

## Usage

GitHub Actions:

```yaml
jobs:
  scan:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/ocraviotto/container-images/ci-scanner@sha256:<digest>
    steps:
      - uses: actions/checkout@<commit-sha>
      - run: trivy fs .
```

GitLab CI:

```yaml
scan:
  image: ghcr.io/ocraviotto/container-images/ci-scanner@sha256:<digest>
  script:
    - trivy fs .
```

Locally:

```sh
docker run --rm -v "$PWD:/workspace" \
  ghcr.io/ocraviotto/container-images/ci-scanner@sha256:<digest> \
  trivy fs .
```

The image runs as UID/GID `10001`; `/workspace` and `/home/scanner` are
writable. Mount source code under `/workspace`, or create another writable
directory and pass it to the scanner.

## Build notes

- Release versions are pinned in the `Dockerfile` ARGs and updated by
  Renovate.
- The Go tools (Trivy, Gitleaks, Cosign, Grype, Syft, Scorecard) are rebuilt
  from source with Go 1.27.3 and patched Go modules. The upstream release
  binaries at the same versions carry known fixable CVEs, so the release
  assets are not used for those tools.
- Opengrep is installed from its pinned release asset. It publishes no
  checksums file, so that binary is fetched over TLS.
- GuardDog and `sarif-tools` are installed from pinned PyPI versions in
  `/opt/ci-actions/venv`. `pip`, `setuptools` and `wheel` are removed after
  the install so their vendored copies are not shipped; `guarddog` and
  `sarif` are symlinked into `/opt/ci-actions/bin`.
- Node.js is copied from the official `node:24-bookworm-slim` image. Only the
  `node` binary is included, so npm's bundled dependency tree is not shipped.
- No `.trivyignore` or `.grype.yaml` is used; the image scan is clean.
