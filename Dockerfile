# Verifier la version utilisée par le Helm
# https://github.com/apache/airflow/blob/helm-chart/1.21.0/chart/Chart.yaml#L23
FROM apache/airflow:3.2.0

# https://www.r-project.org/
ARG R_VERSION=4.6

# https://github.com/r-lib/rig
ARG RIG_VERSION=latest

USER root

ENV R_LIBS_USER=~/.R/library

# rig (R Installation Manager, par r-lib/Posit) tire des binaires R prebuilt depuis Posit r-builds.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl \
        libcurl4 libssl3 libxml2 \
        libfontconfig1 libharfbuzz0b libfribidi0 \
        libfreetype6 libpng16-16 libtiff6 libjpeg62-turbo \
    && if [ "${RIG_VERSION}" = "latest" ]; then RIG_TAG="latest"; else RIG_TAG="v${RIG_VERSION}"; fi \
    && curl -fsSL "https://github.com/r-lib/rig/releases/download/${RIG_TAG}/rig-linux-${RIG_VERSION}.tar.gz" \
        | tar xz -C /usr/local \
    && rig add "${R_VERSION}" \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configurer Posit Public Package Manager (binaires Linux precompiles) comme repo CRAN par defaut.
# Les packages R seront installes au runtime dans le script R, mais profiteront ainsi des binaires (pas de compilation gcc).
RUN . /etc/os-release \
    && echo "options(repos = c(CRAN = \"https://packagemanager.posit.co/cran/__linux__/${VERSION_CODENAME}/latest\"))" \
        > "$(R RHOME)/etc/Rprofile.site"

USER airflow
