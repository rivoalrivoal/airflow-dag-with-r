# Verifier la version utilisée par le Helm
# https://github.com/apache/airflow/blob/helm-chart/1.21.0/chart/Chart.yaml#L23
FROM apache/airflow:3.2.0

# https://github.com/r-lib/rig
ARG RIG_VERSION=0.8.0
# https://www.r-project.org/
ARG R_VERSION=4.6

USER root

# Neutralise le user-library de R (chemin absolu qui n'est pas un repertoire => R l'ignore).
# install.packages tombe alors par defaut dans .Library, accessible a tous les users.
ENV R_LIBS_USER=/dev/null

# rig (R Installation Manager, par r-lib/Posit) tire des binaires R prebuilt depuis Posit r-builds.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl \
        libcurl4 libssl3 libxml2 \
        libfontconfig1 libharfbuzz0b libfribidi0 \
        libfreetype6 libpng16-16 libtiff6 libjpeg62-turbo \
    && curl -fsSL "https://github.com/r-lib/rig/releases/download/v${RIG_VERSION}/rig-linux-${RIG_VERSION}.tar.gz" \
        | tar xz -C /usr/local \
    && rig add "${R_VERSION}" \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Installer tidyverse
RUN R -e "install.packages('tidyverse')" \
    && R -e "if (!requireNamespace('tidyverse', quietly = TRUE)) quit(status = 1)"

USER airflow
