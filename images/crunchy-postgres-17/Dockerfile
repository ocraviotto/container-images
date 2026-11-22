ARG BASE_POSTGRES_VERSION=17
# renovate: packageName=image-crunchy-postgres-17 datasource=custom.crunchyPostgres
ARG PGO_IMAGE_VERSION=ubi9-17.11-2633
ARG REGISTRY=registry.developers.crunchydata.com/crunchydata/crunchy-postgres

FROM docker.io/library/postgres:${BASE_POSTGRES_VERSION} AS builder

# ca-certificates is explicit because --no-install-recommends drops git's
# recommendation of it, which breaks the HTTPS clone below.
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates make git postgresql-server-dev-17 \
    && git clone https://github.com/michelp/pgjwt.git \
    && cd pgjwt \
    && make && make install

FROM ${REGISTRY}:${PGO_IMAGE_VERSION}

USER root

# The runtime is a UBI 9 minimal image with microdnf, not dnf. Apply the
# published errata for the packages reported by the scanners. Only the
# affected base packages are named so the Crunchy Postgres packages stay at
# the versions the operator was tested with.
RUN microdnf -y update \
        bind-libs bind-license bind-utils ca-certificates curl-minimal expat \
        krb5-libs krb5-pkinit krb5-workstation libblkid libcurl-minimal \
        libevent libfdisk libkadm5 libmount libsmartcols libuuid libxml2 \
        openssl openssl-libs pcre2 pcre2-syntax perl-DBI python3 python3-libs \
        python3.12 python3.12-libs sqlite-libs util-linux util-linux-core \
        vim-minimal \
    && microdnf clean all

# Patroni's modules live in /usr/local/lib/python3.12 and are loaded by the
# RPM python3.12; the image ships no pip there. Install the RPM pip
# temporarily and target that site-packages directory, then remove it.
RUN set -eux; \
    microdnf -y install python3.12-pip; \
    rm -rf /usr/local/lib/python3.12/site-packages/certifi \
           /usr/local/lib/python3.12/site-packages/certifi-*.dist-info \
           /usr/local/lib/python3.12/site-packages/urllib3 \
           /usr/local/lib/python3.12/site-packages/urllib3-*.dist-info; \
    python3.12 -m pip install --no-cache-dir \
        --target /usr/local/lib/python3.12/site-packages \
        'certifi==2026.10.18' \
        'urllib3==2.8.0'; \
    microdnf -y remove python3.12-pip; \
    microdnf clean all

COPY --from=builder /usr/share/postgresql/17/extension/pgjwt* /usr/pgsql-17/share/extension/

USER 26
