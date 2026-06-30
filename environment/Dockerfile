# hash:sha256:9e794d14df21cc1962ee2208c4435d9204f86b4ebffee9e54b157b672e37051d
ARG REGISTRY_HOST
FROM $REGISTRY_HOST/codeocean/mosuite:v0.3.2

ARG DEBIAN_FRONTEND=noninteractive
ARG GIT_ASKPASS
COPY git-ask-pass /

ARG RCACHE_OPTIONS
RUN echo $RCACHE_OPTIONS >> $(Rscript -e 'cat(R.home())')/etc/Rprofile.site
# Force rebuild: Install RCurl and optparse
RUN Rscript -e 'remotes::install_version("RCurl")' \
    && Rscript -e 'remotes::install_version("optparse", "1.8.2")'

COPY postInstall /
RUN --mount=type=secret,id=secrets . /run/secrets/secrets \
    && /postInstall
