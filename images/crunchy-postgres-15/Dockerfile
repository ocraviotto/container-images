ARG BASE_POSTGRES_VERSION=15
# renovate: packageName=image-crunchy-postgres-15 datasource=custom.crunchyPostgres
ARG PGO_IMAGE_VERSION=ubi9-15.19-2633
ARG REGISTRY=registry.developers.crunchydata.com/crunchydata/crunchy-postgres

FROM docker.io/library/postgres:${BASE_POSTGRES_VERSION} AS builder

RUN apt-get update && apt-get install -y make git postgresql-server-dev-15 \
    && git clone https://github.com/michelp/pgjwt.git \
    && cd pgjwt \
    && make && make install

FROM ${REGISTRY}:${PGO_IMAGE_VERSION}

USER root

# The runtime is a UBI 9 minimal image with microdnf, not dnf. Apply the
# published errata for the packages reported by the image scan. Only the
# affected base packages are named so the Crunchy Postgres packages stay at
# the versions the operator was tested with.
RUN microdnf -y update \
        bind-libs bind-license bind-utils ca-certificates curl-minimal expat \
        krb5-libs krb5-pkinit krb5-workstation libblkid libcurl-minimal \
        libevent libfdisk libkadm5 libmount libsmartcols libuuid libxml2 \
        openssl openssl-libs pcre2 pcre2-syntax perl-DBI python3 python3-libs \
        python3.12 python3.12-libs sqlite-libs util-linux util-linux-core \
    && microdnf clean all

# Patroni's dependencies are pip-installed under /usr/local and are not
# covered by the RPM update above.
RUN pip3 install --no-cache-dir --upgrade \
        'certifi==2026.10.18' \
        'urllib3==2.8.0'

COPY --from=builder /usr/share/postgresql/15/extension/pgjwt* /usr/pgsql-15/share/extension/

USER 26
