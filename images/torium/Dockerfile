# Torium imports mcp.server.fastmcp, which mcp 2.x removed (FastMCP was
# renamed to MCPServer). Pin mcp<2 until upstream migrates.
# Upstream: https://github.com/ahnl/torium
FROM python:3.15-slim AS build

ARG TORIUM_COMMIT=9a0c0478aceb01bfe0165eb9928f4787140334b5

RUN apt-get update \
 && apt-get install -y --no-install-recommends git \
 && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/ahnl/torium /src \
 && git -C /src checkout "${TORIUM_COMMIT}"

WORKDIR /src
RUN pip install --no-cache-dir --prefix=/install \
      "mcp<2" \
      "msgpack>=1.2.3" \
      "urllib3>=2.8.0" \
      "setuptools>=78.1.1" \
      .

FROM python:3.15-slim
ENV PYTHONDONTWRITEBYTECODE=1
COPY --from=build /install /usr/local

# TODO(security): Drop these explicit pins and the uninstall/reinstall once
# torium/mcp resolve msgpack>=1.2.3, urllib3>=2.8.0, and setuptools>=78.1.1
# themselves. The uninstall also clears metadata copied from the build stage.
RUN pip uninstall -y msgpack urllib3 setuptools || true \
 && pip install --no-cache-dir \
      "msgpack>=1.2.3" \
      "urllib3>=2.8.0" \
      "setuptools>=78.1.1" \
 && rm -rf /root/.cache/pip

RUN adduser --disabled-password --gecos "" --uid 1001 torium
ENV HOME=/home/torium
USER torium
