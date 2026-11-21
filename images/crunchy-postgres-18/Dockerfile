ARG BASE_POSTGRES_VERSION=18
# renovate: packageName=image-crunchy-postgres-18 datasource=custom.crunchyPostgres
ARG PGO_IMAGE_VERSION=ubi9-18.6-2633
ARG REGISTRY=registry.developers.crunchydata.com/crunchydata/crunchy-postgres

FROM docker.io/library/postgres:${BASE_POSTGRES_VERSION} AS builder

RUN apt-get update && apt-get install -y make git postgresql-server-dev-18 \
    && git clone https://github.com/michelp/pgjwt.git \
    && cd pgjwt \
    && make && make install

FROM ${REGISTRY}:${PGO_IMAGE_VERSION}

USER root

# The stable Crunchy image is built on a UBI 9 base whose packages lag the
# published Red Hat errata. Apply the updates here so the runtime does not
# ship the fixable HIGH/CRITICAL findings reported by the image scan. The
# Crunchy and PGDG repositories are excluded so the Postgres packages stay
# at the versions the operator was tested with.
RUN dnf -y update \
        --disablerepo='crunchypg*' \
        --disablerepo='pgdg*' \
    && dnf clean all

# Patroni and its dependencies are pip-installed under /usr/local and are
# not covered by the RPM update above.
RUN pip3 install --no-cache-dir --upgrade \
        'certifi==2026.10.18' \
        'urllib3==2.8.0'

COPY --from=builder /usr/share/postgresql/18/extension/pgjwt* /usr/pgsql-18/share/extension/

USER 26
