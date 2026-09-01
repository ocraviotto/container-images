ARG BASE_POSTGRES_VERSION=18
ARG PGO_IMAGE_VERSION=ubi9-15.19-2633
ARG REGISTRY=registry.developers.crunchydata.com/crunchydata/crunchy-postgres

FROM docker.io/library/postgres:${BASE_POSTGRES_VERSION} AS builder

RUN apt-get update && apt-get install -y make git postgresql-server-dev-15 \
    && git clone https://github.com/michelp/pgjwt.git \
    && cd pgjwt \
    && make && make install

FROM ${REGISTRY}:${PGO_IMAGE_VERSION}

USER root

COPY --from=builder /usr/share/postgresql/15/extension/pgjwt* /usr/pgsql-15/share/extension/

USER 26
