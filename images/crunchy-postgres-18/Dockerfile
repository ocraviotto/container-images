ARG BASE_POSTGRES_VERSION=18
FROM docker.io/library/postgres:${BASE_POSTGRES_VERSION} as builder

RUN apt-get update && apt-get install -y make git postgresql-server-dev-18 \
    && git clone https://github.com/michelp/pgjwt.git \
    && cd pgjwt \
    && make && make install

ARG PGO_IMAGE_VERSION=ubi9-18.6-2633
ARG REGISTRY=registry.developers.crunchydata.com/crunchydata/crunchy-postgres
FROM ${REGISTRY}:${PGO_IMAGE_VERSION}

USER root

COPY --from=builder /usr/share/postgresql/18/extension/pgjwt* /usr/pgsql-18/share/extension/

USER 26
