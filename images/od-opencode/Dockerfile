# Open Design runtime with the OpenCode CLI bundled.
#
# Why this image exists:
#   - ghcr.io/nexu-io/od intentionally ships no agent CLIs: deploy/Dockerfile.local
#     only adds libc6-compat, and deploy/docker-compose.linux.yml mounts host CLIs.
#   - Open Design's API/BYOK mode runs through the `byok-opencode` agent runtime,
#     which needs the `opencode` binary. Without it the web UI refuses every run
#     ("BYOK API runs require OpenCode") and no provider call is ever made.
#   - Installing the `opencode-ai` npm package is the verified headless fix
#     (nexu-io/open-design#8227). VELA_OPENCODE_BIN points the daemon at it, so
#     no Vela/AMR login is required.
#
# Consumed by clusters/casa/apps/open-design in casa-gitops, which mounts a
# writable emptyDir at /home/open-design for OpenCode state.

# renovate: packageName=ghcr.io/nexu-io/od datasource=docker
ARG OD_VERSION=0.23.0
FROM ghcr.io/nexu-io/od:${OD_VERSION}

USER root

# renovate: packageName=opencode-ai datasource=npm
ARG OPENCODE_VERSION=1.18.31

RUN apk add --no-cache libc6-compat bash \
    && npm install --global --omit=dev "opencode-ai@${OPENCODE_VERSION}" \
    && test -x /usr/local/bin/opencode \
    && /usr/local/bin/opencode --version

# The daemon resolves the byok-opencode runtime from VELA_OPENCODE_BIN first
# (apps/daemon/src/runtimes/executables.ts -> resolveAmrOpenCodeExecutable).
ENV VELA_OPENCODE_BIN=/usr/local/bin/opencode

USER open-design
