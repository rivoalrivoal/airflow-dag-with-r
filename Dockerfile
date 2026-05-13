FROM apache/airflow:3.2.0

USER root

# R 4.6 (depot CRAN officiel pour Bookworm) + libs de base pour les paquets
# tidyverse compiles via binaires Posit PPM (curl/ssl/xml2/fonts/...).
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates gnupg dirmngr \
        libcurl4 libssl3 libxml2 \
        libfontconfig1 libharfbuzz0b libfribidi0 \
        libfreetype6 libpng16-16 libtiff6 libjpeg62-turbo \
    && install -d -m 0755 /etc/apt/keyrings \
    && gpg --keyserver keyserver.ubuntu.com \
        --recv-key '95C0FAF38DB3CCAD0C080A7BDC78B2DDEABC47B7' \
    && gpg --armor --export '95C0FAF38DB3CCAD0C080A7BDC78B2DDEABC47B7' \
        > /etc/apt/keyrings/cran.asc \
    && printf 'Types: deb\nURIs: https://cloud.r-project.org/bin/linux/debian/\nSuites: bookworm-cran46/\nComponents:\nSigned-By: /etc/apt/keyrings/cran.asc\n' \
        > /etc/apt/sources.list.d/cran.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends r-base \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Pointer R sur Posit Public Package Manager pour servir des paquets binaires
# Bookworm (sinon install.packages tombe sur du source -> tres long).
RUN printf '%s\n' \
        'options(' \
        '  HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version$platform, R.version$arch, R.version$os)),' \
        '  repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/bookworm/latest")' \
        ')' \
        > /usr/lib/R/etc/Rprofile.site

# Installer tidyverse dans la site-library partagee.
RUN R -e "install.packages('tidyverse')" \
    && R -e "if (!requireNamespace('tidyverse', quietly = TRUE)) quit(status = 1)"

USER airflow
