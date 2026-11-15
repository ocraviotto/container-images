# gpt-researcher backend built from upstream source.
#
# Why a local image instead of the external spec:
#   - pin Python to the 3.13 line so unstructured >= 0.24.1 can be installed
#     (0.24.x requires Python <3.14). The URL-partitioning SSRF is then fixed
#     rather than waived;
#   - force setuptools >= 78.1.1 for CVE-2025-47273;
#   - keep the upstream browser tooling and runtime layout unchanged.
#
# Renovate updates GPTR_VERSION below and in .version.

ARG GPTR_VERSION=v3.8.0

FROM python:3.13-slim-bookworm AS source
ARG GPTR_VERSION
RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch "${GPTR_VERSION}" https://github.com/assafelovic/gpt-researcher.git /src

# Stage 1: Browser and build tools installation
FROM python:3.13-slim-bookworm AS install-browser

RUN apt-get update \
    && apt-get install -y gnupg wget ca-certificates --no-install-recommends \
    && ARCH=$(dpkg --print-architecture) \
    && wget -qO - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=${ARCH}] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y chromium chromium-driver \
    && chromium --version && chromedriver --version \
    && apt-get install -y --no-install-recommends firefox-esr build-essential \
    && GECKO_ARCH=$(case ${ARCH} in amd64) echo "linux64" ;; arm64) echo "linux-aarch64" ;; *) echo "linux64" ;; esac) \
    && wget https://github.com/mozilla/geckodriver/releases/download/v0.36.0/geckodriver-v0.36.0-${GECKO_ARCH}.tar.gz \
    && tar -xvzf geckodriver-v0.36.0-${GECKO_ARCH}.tar.gz \
    && chmod +x geckodriver \
    && mv geckodriver /usr/local/bin/ \
    && rm geckodriver-v0.36.0-${GECKO_ARCH}.tar.gz \
    && rm -rf /var/lib/apt/lists/*

# Stage 2: Python dependencies installation
FROM install-browser AS gpt-researcher-install

ENV PIP_ROOT_USER_ACTION=ignore
WORKDIR /usr/src/app

COPY --from=source /src/requirements.txt ./requirements.txt
COPY --from=source /src/multi_agents/requirements.txt ./multi_agents/requirements.txt

# Install the upstream requirements, then force the security floor so a
# transitive pin cannot silently downgrade these again.
RUN pip install --upgrade pip 'setuptools>=78.1.1' \
    && pip install --no-cache-dir -r requirements.txt --upgrade --prefer-binary \
    && pip install --no-cache-dir -r multi_agents/requirements.txt --upgrade --prefer-binary \
    && pip install --no-cache-dir --upgrade 'unstructured>=0.24.1' 'setuptools>=78.1.1'

# Stage 3: Final stage with non-root user and app
FROM gpt-researcher-install AS gpt-researcher

ARG HOST=0.0.0.0
ENV HOST=${HOST}
ARG PORT=8000
ENV PORT=${PORT}
EXPOSE ${PORT}

ARG WORKERS=1
ENV WORKERS=${WORKERS}

RUN useradd -ms /bin/bash gpt-researcher \
    && chown -R gpt-researcher:gpt-researcher /usr/src/app \
    && mkdir -p /usr/src/app/outputs \
    && chown -R gpt-researcher:gpt-researcher /usr/src/app/outputs \
    && chmod 777 /usr/src/app/outputs
USER gpt-researcher
WORKDIR /usr/src/app

COPY --chown=gpt-researcher:gpt-researcher --from=source /src/ ./
CMD uvicorn main:app --host ${HOST} --port ${PORT} --workers ${WORKERS}
