# Torium imports mcp.server.fastmcp, which mcp 2.x removed (FastMCP was
# renamed to MCPServer). Pin mcp<2 until upstream migrates.
# Upstream: https://github.com/ahnl/torium
FROM python:3.12-slim AS build

ARG TORIUM_COMMIT=9a0c0478aceb01bfe0165eb9928f4787140334b5

RUN apt-get update \
 && apt-get install -y --no-install-recommends git \
 && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/ahnl/torium /src \
 && git -C /src checkout "${TORIUM_COMMIT}"

WORKDIR /src
RUN pip install --no-cache-dir --prefix=/install "mcp<2" .

FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1
COPY --from=build /install /usr/local
