# syntax=docker/dockerfile:1
#
# Mem0 OSS REST API.
#
# Why a local image instead of an external spec:
#   - upstream server/Dockerfile installs `mem0ai>=0.1.48` unpinned, so a
#     rebuild can silently change the SDK version;
#   - it runs uvicorn with --reload and as root;
#   - it copies the dashboard source into the API image.
#
# Installing the package from the pinned checkout (`pip install /src`) makes the
# SDK version match the server code exactly. Python 3.13 is the current stable
# release line (security support through October 2029); 3.12 remains supported,
# but 3.13 is the forward-looking choice.
#
# renovate: packageName=mem0ai/mem0 depName=mem0 datasource=github-tags versioning=semver
ARG MEM0_VERSION=v2.2.1

FROM python:3.15-slim AS builder
# A global ARG is only visible to FROM lines; it must be redeclared inside the
# stage to be available to RUN.
ARG MEM0_VERSION
ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1
RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN git clone --depth 1 --branch "${MEM0_VERSION}" \
    https://github.com/mem0ai/mem0.git .
# Install the pinned checkout first. `pip install --prefix` does not add the
# prefix to sys.path, so PYTHONPATH exposes the installed mem0ai 2.2.1 to the
# second pip run; the `mem0ai>=0.1.48` line in requirements.txt is then already
# satisfied and the SDK is not re-resolved from PyPI.
RUN pip install --prefix=/install /src \
    && PYTHONPATH=/install/lib/python3.13/site-packages \
       pip install --prefix=/install -r /src/server/requirements.txt


FROM python:3.15-slim
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1
RUN groupadd --gid 1000 mem0 \
    && useradd --uid 1000 --gid 1000 --no-create-home \
    --home-dir /app --shell /usr/sbin/nologin mem0
WORKDIR /app
COPY --from=builder /install /usr/local
COPY --from=builder /src/server/ /app/
RUN rm -rf /app/dashboard \
    && mkdir -p /app/history \
    && chown -R 1000:1000 /app
USER 1000:1000
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]