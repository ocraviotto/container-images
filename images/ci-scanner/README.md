# ci-scanner

Preinstalled toolchain for `avellaneda/ci-actions` scan jobs.

Published as `ghcr.io/ocraviotto/container-images/ci-scanner` for
`linux/amd64` and `linux/arm64`.

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

Versions are pinned in the `Dockerfile` ARGs and updated by Renovate. They
mirror `avellaneda/ci-actions/versions.env`; keep the two in sync when either
side moves.

## Use

Use the image as the main container of a dedicated Forgejo runner class (for
example `gvisor-scanner`) and point scan jobs at that label. The tools are on
`PATH` under `/opt/ci-actions/bin`, so `ci-actions/setup` can be skipped
entirely. This removes the per-job downloads of Trivy, Grype, Syft, Opengrep,
Gitleaks, Cosign, Scorecard and the GuardDog Python dependencies.

GuardDog and `sarif-tools` live in `/opt/ci-actions/venv`; `guarddog` and
`sarif` are symlinked into `/opt/ci-actions/bin`.
